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

import Combine
import Kingfisher
import SwiftUI

/// Used to configure animations
enum LoadableImageMediaType {
    case avatar
    case generic
}

struct LoadableImage<TransformerView: View, PlaceholderView: View>: View {
    private let mediaSource: MediaSourceProxy
    private let mediaType: LoadableImageMediaType
    private let blurhash: String?
    private let size: CGSize?
    private let imageProvider: ImageProviderProtocol?
    private let networkMonitor: NetworkMonitorProtocol?
    private let transformer: (AnyView) -> TransformerView
    private let placeholder: () -> PlaceholderView
    
    /// A SwiftUI view that automatically fetches images
    /// It will try fetching the image from in-memory cache and if that's not available
    /// it will fire a task to load it through the image provider
    /// - Parameters:
    ///   - mediaSource: the source of the image
    ///   - blurhash: an optional blurhash
    ///   - transformer: entry point for configuring the resulting image view
    ///   - placeholder: a view to show while the image or blurhash are not available
    init(mediaSource: MediaSourceProxy,
         mediaType: LoadableImageMediaType = .generic,
         blurhash: String? = nil,
         size: CGSize? = nil,
         imageProvider: ImageProviderProtocol?,
         networkMonitor: NetworkMonitorProtocol?,
         transformer: @escaping (AnyView) -> TransformerView = { $0 },
         placeholder: @escaping () -> PlaceholderView) {
        self.mediaSource = mediaSource
        self.mediaType = mediaType
        self.blurhash = blurhash
        self.size = size
        self.imageProvider = imageProvider
        self.networkMonitor = networkMonitor
        self.transformer = transformer
        self.placeholder = placeholder
    }
    
    init(url: URL,
         mediaType: LoadableImageMediaType = .generic,
         blurhash: String? = nil,
         size: CGSize? = nil,
         imageProvider: ImageProviderProtocol?,
         networkMonitor: NetworkMonitorProtocol?,
         transformer: @escaping (AnyView) -> TransformerView = { $0 },
         placeholder: @escaping () -> PlaceholderView) {
        self.init(mediaSource: MediaSourceProxy(url: url, mimeType: nil),
                  mediaType: mediaType,
                  blurhash: blurhash,
                  size: size,
                  imageProvider: imageProvider,
                  networkMonitor: networkMonitor,
                  transformer: transformer,
                  placeholder: placeholder)
    }
    
    var body: some View {
        LoadableImageContent(mediaSource: mediaSource,
                             mediaType: mediaType,
                             blurhash: blurhash,
                             size: size,
                             imageProvider: imageProvider,
                             networkMonitor: networkMonitor,
                             transformer: transformer,
                             placeholder: placeholder)
            // Binds the lifecycle of the LoadableImage to the associated URL.
            // This fixes the problem of the cache returning old values after a change in the URL.
            .id(mediaSource.url)
    }
}

private struct LoadableImageContent<TransformerView: View, PlaceholderView: View>: View, ImageDataProvider {
    private let mediaSource: MediaSourceProxy
    private let mediaType: LoadableImageMediaType
    private let blurhash: String?
    private let transformer: (AnyView) -> TransformerView
    private let placeholder: () -> PlaceholderView
    
    @StateObject private var contentLoader: ContentLoader
    
    init(mediaSource: MediaSourceProxy,
         mediaType: LoadableImageMediaType,
         blurhash: String? = nil,
         size: CGSize? = nil,
         imageProvider: ImageProviderProtocol?,
         networkMonitor: NetworkMonitorProtocol?,
         transformer: @escaping (AnyView) -> TransformerView,
         placeholder: @escaping () -> PlaceholderView) {
        assert(imageProvider != nil, "Missing image provider, make sure one has been supplied to the view model.")
        
        self.mediaSource = mediaSource
        self.mediaType = mediaType
        self.blurhash = blurhash
        self.transformer = transformer
        self.placeholder = placeholder
        _contentLoader = StateObject(wrappedValue: ContentLoader(mediaSource: mediaSource,
                                                                 size: size,
                                                                 imageProvider: imageProvider,
                                                                 networkMonitor: networkMonitor))
    }
    
    var body: some View {
        let _ = Task {
            guard contentLoader.content == nil else {
                return
            }
            
            await contentLoader.load()
        }
        
        ZStack {
            switch contentLoader.content {
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
        .animation(mediaType == .avatar ? .noAnimation : .elementDefault, value: contentLoader.content)
    }
    
    // MARK: - ImageDataProvider
    
    var cacheKey: String {
        mediaSource.url.absoluteString
    }
    
    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        guard case let .gifData(data) = contentLoader.content else {
            fatalError("Shouldn't reach this point without any gif data")
        }
        
        handler(.success(data))
    }
}

private class ContentLoader: ObservableObject {
    enum Content: Equatable {
        case image(UIImage)
        case gifData(Data)
    }
    
    private let imageProvider: ImageProviderProtocol?
    private let networkMonitor: NetworkMonitorProtocol?
    private let mediaSource: MediaSourceProxy
    private let size: CGSize?
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published private var cachedContent: Content?
    
    var content: Content? {
        if cachedContent != nil {
            return cachedContent
        }
        
        if isGIF {
            if let image = imageProvider?.imageFromSource(mediaSource),
               let data = image.kf.data(format: .GIF) {
                return .gifData(data)
            }
        } else if let image = imageProvider?.imageFromSource(mediaSource, size: size) {
            return .image(image)
        }
        
        return cachedContent
    }
    
    init(mediaSource: MediaSourceProxy,
         size: CGSize?,
         imageProvider: ImageProviderProtocol?,
         networkMonitor: NetworkMonitorProtocol?) {
        self.mediaSource = mediaSource
        self.size = size
        self.imageProvider = imageProvider
        self.networkMonitor = networkMonitor
        
        // Try to reload images when the network comes back. If a request is
        // in flight the new one will get coalesced on the image provider level
        networkMonitor?.reachabilityPublisher
            .sink { [weak self] value in
                guard let self, cachedContent == nil, value == .reachable else {
                    return
                }
                
                Task {
                    await self.load()
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func load() async {
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
    
    private var isGIF: Bool {
        mediaSource.mimeType == "image/gif"
    }
}
