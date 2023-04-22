//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Kingfisher
import SwiftUI

struct LoadableImage<TransformerView: View, PlaceholderView: View>: View, ImageDataProvider {
    private let mediaSource: MediaSourceProxy
    private let blurhash: String?
    private let size: CGSize?
    private let imageProvider: ImageProviderProtocol?
    
    private var transformer: (AnyView) -> TransformerView
    private let placeholder: () -> PlaceholderView
    
    @StateObject private var loadableContent: LoadableContent
    
    /// A SwiftUI view that automatically fetches images
    /// It will try fetching the image from in-memory cache and if that's not available
    /// it will fire a task to load it through the image provider
    /// - Parameters:
    ///   - mediaSource: the source of the image
    ///   - blurhash: an optional blurhash
    ///   - transformer: entry point for configuring the resulting image view
    ///   - placeholder: a view to show while the image or blurhash are not available
    init(mediaSource: MediaSourceProxy,
         blurhash: String? = nil,
         size: CGSize? = nil,
         imageProvider: ImageProviderProtocol?,
         transformer: @escaping (AnyView) -> TransformerView = { $0 },
         placeholder: @escaping () -> PlaceholderView) {
        self.mediaSource = mediaSource
        self.blurhash = blurhash
        self.size = size
        self.imageProvider = imageProvider
        
        self.transformer = transformer
        self.placeholder = placeholder
        
        _loadableContent = StateObject(wrappedValue: LoadableContent(imageProvider: imageProvider, mediaSource: mediaSource, size: size))
    }
    
    init(url: URL,
         blurhash: String? = nil,
         size: CGSize? = nil,
         imageProvider: ImageProviderProtocol?,
         transformer: @escaping (AnyView) -> TransformerView = { $0 },
         placeholder: @escaping () -> PlaceholderView) {
        self.init(mediaSource: MediaSourceProxy(url: url, mimeType: nil),
                  blurhash: blurhash,
                  size: size,
                  imageProvider: imageProvider,
                  transformer: transformer,
                  placeholder: placeholder)
    }
    
    var body: some View {
        let _ = Task {
            // Future improvement: Does guarding against a nil image prevent the image being updated when the URL changes?
            guard loadableContent.content == nil else {
                return
            }
            
            await loadableContent.load()
        }
        
        ZStack {
            switch loadableContent.content {
            case .image(let image):
                transformer(
                    AnyView(Image(uiImage: image).resizable())
                )
            case .gifData:
                transformer(AnyView(KFAnimatedImage(source: .provider(self))))
            case .none:
                if let blurhash,
                   // Build a small blurhash image so that it's fast
                   let image = UIImage(blurHash: blurhash, size: .init(width: 10.0, height: 10.0)) {
                    transformer(AnyView(Image(uiImage: image).resizable()))
                } else {
                    placeholder()
                }
            }
        }
        .animation(.elementDefault, value: loadableContent.content)
    }
    
    // MARK: - ImageDataProvider
    
    var cacheKey: String {
        mediaSource.url.absoluteString
    }
    
    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        guard case let .gifData(data) = loadableContent.content else {
            fatalError("Shouldn't reach this point without any gif data")
        }
        
        handler(.success(data))
    }
}

private class LoadableContent: ObservableObject {
    enum CachedContent: Equatable {
        case image(UIImage)
        case gifData(Data)
    }
    
    private let imageProvider: ImageProviderProtocol?
    private let mediaSource: MediaSourceProxy
    private let size: CGSize?
    
    @Published var cachedContent: CachedContent?
    var content: CachedContent? {
        if cachedContent != nil {
            return cachedContent
        }
        
        if let image = imageProvider?.imageFromSource(mediaSource) {
            let isGIF = mediaSource.mimeType == "image/gif"
            
            if isGIF {
                if let data = image.kf.data(format: .GIF) {
                    return .gifData(data)
                }
            } else {
                return .image(image)
            }
        }
        
        return cachedContent
    }
    
    init(imageProvider: ImageProviderProtocol?, mediaSource: MediaSourceProxy, size: CGSize?) {
        self.imageProvider = imageProvider
        self.mediaSource = mediaSource
        self.size = size
    }
    
    @MainActor
    func load() async {
        let isGIF = mediaSource.mimeType == "image/gif"
        
        if isGIF {
            if case let .success(data) = await imageProvider?.loadImageDataFromSource(mediaSource) {
                cachedContent = .gifData(data)
            }
        } else {
            if case let .success(image) = await imageProvider?.loadImageFromSource(mediaSource, size: size) {
                cachedContent = .image(image)
            }
        }
    }
}
