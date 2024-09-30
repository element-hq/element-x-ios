//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    private let mediaProvider: MediaProviderProtocol?
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
         mediaProvider: MediaProviderProtocol?,
         transformer: @escaping (AnyView) -> TransformerView = { $0 },
         placeholder: @escaping () -> PlaceholderView) {
        self.mediaSource = mediaSource
        self.mediaType = mediaType
        self.blurhash = blurhash
        self.size = size
        self.mediaProvider = mediaProvider
        self.transformer = transformer
        self.placeholder = placeholder
    }
    
    init(url: URL,
         mediaType: LoadableImageMediaType = .generic,
         blurhash: String? = nil,
         size: CGSize? = nil,
         mediaProvider: MediaProviderProtocol?,
         transformer: @escaping (AnyView) -> TransformerView = { $0 },
         placeholder: @escaping () -> PlaceholderView) {
        self.init(mediaSource: MediaSourceProxy(url: url, mimeType: nil),
                  mediaType: mediaType,
                  blurhash: blurhash,
                  size: size,
                  mediaProvider: mediaProvider,
                  transformer: transformer,
                  placeholder: placeholder)
    }
    
    var body: some View {
        LoadableImageContent(mediaSource: mediaSource,
                             mediaType: mediaType,
                             blurhash: blurhash,
                             size: size,
                             mediaProvider: mediaProvider,
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
         mediaProvider: MediaProviderProtocol?,
         transformer: @escaping (AnyView) -> TransformerView,
         placeholder: @escaping () -> PlaceholderView) {
        assert(mediaProvider != nil, "Missing image provider, make sure one has been supplied to the view model.")
        
        self.mediaSource = mediaSource
        self.mediaType = mediaType
        self.blurhash = blurhash
        self.transformer = transformer
        self.placeholder = placeholder
        _contentLoader = StateObject(wrappedValue: ContentLoader(mediaSource: mediaSource, size: size, mediaProvider: mediaProvider))
    }
    
    var body: some View {
        // Tried putting this in the body's .task but it randomly
        // decides to not execute the request
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
        .onDisappear {
            guard contentLoader.content == nil else {
                return
            }
            
            contentLoader.cancel()
        }
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
    
    private let mediaProvider: MediaProviderProtocol?
    private let mediaSource: MediaSourceProxy
    private let size: CGSize?
    private var imageLoadingCancellable: AnyCancellable?
    
    @Published private var cachedContent: Content?
    
    var content: Content? {
        if cachedContent != nil {
            return cachedContent
        }
        
        if isGIF {
            if let image = mediaProvider?.imageFromSource(mediaSource),
               let data = image.kf.data(format: .GIF) {
                return .gifData(data)
            }
        } else if let image = mediaProvider?.imageFromSource(mediaSource, size: size) {
            return .image(image)
        }
        
        return cachedContent
    }
    
    init(mediaSource: MediaSourceProxy, size: CGSize?, mediaProvider: MediaProviderProtocol?) {
        self.mediaSource = mediaSource
        self.size = size
        self.mediaProvider = mediaProvider
    }
    
    @MainActor
    func load() async {
        if isGIF {
            if case let .success(data) = await mediaProvider?.loadImageDataFromSource(mediaSource) {
                cachedContent = .gifData(data)
            }
        } else {
            guard let task = mediaProvider?.loadImageRetryingOnReconnection(mediaSource, size: size) else {
                MXLog.error("Failed loading image, invalid reconnection retry task.")
                return
            }
            
            imageLoadingCancellable = task.asCancellable()
            
            if let image = try? await task.value {
                cachedContent = .image(image)
            }
        }
    }
    
    func cancel() {
        imageLoadingCancellable?.cancel()
    }
    
    private var isGIF: Bool {
        mediaSource.mimeType == "image/gif"
    }
}
