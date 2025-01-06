//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import Kingfisher
import SwiftUI

/// Used to configure animations
enum LoadableImageMediaType: Equatable {
    /// An avatar (can be displayed anywhere within the app).
    case avatar
    /// An image displayed in the timeline.
    case timelineItem(uniqueID: String)
    /// Any other media (can be displayed anywhere within the app).
    case generic
}

struct LoadableImage<TransformerView: View, PlaceholderView: View>: View {
    private let mediaSource: MediaSourceProxy?
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
        mediaSource = try? MediaSourceProxy(url: url, mimeType: nil)
        self.mediaType = mediaType
        self.blurhash = blurhash
        self.size = size
        self.mediaProvider = mediaProvider
        self.transformer = transformer
        self.placeholder = placeholder
    }
    
    var body: some View {
        if let mediaSource {
            LoadableImageContent(mediaSource: mediaSource,
                                 mediaType: mediaType,
                                 blurhash: blurhash,
                                 size: size,
                                 mediaProvider: mediaProvider,
                                 transformer: transformer,
                                 placeholder: placeholder)
                .id(stableMediaIdentifier)
        } else {
            placeholder()
        }
    }
    
    private var stableMediaIdentifier: String? {
        switch mediaType {
        case .timelineItem(let uniqueID):
            // Consider media for the same item to be the same view
            uniqueID
        default:
            // Binds the lifecycle of the LoadableImage to the associated URL.
            // This fixes the problem of the cache returning old values after a change in the URL.
            mediaSource?.url.absoluteString
        }
    }
}

private struct LoadableImageContent<TransformerView: View, PlaceholderView: View>: View, ImageDataProvider {
    @Environment(\.shouldAutomaticallyLoadImages) private var loadAutomatically
    
    private let mediaSource: MediaSourceProxy
    private let mediaType: LoadableImageMediaType
    private let blurhash: String?
    private let transformer: (AnyView) -> TransformerView
    private let placeholder: () -> PlaceholderView
    
    @StateObject private var contentLoader: ContentLoader
    @State private var loadManually = false
    
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
    
    var shouldRender: Bool {
        loadAutomatically || loadManually
    }
    
    var body: some View {
        ZStack {
            switch (contentLoader.content, shouldRender) {
            case (.image(let image), true):
                transformer(
                    AnyView(Image(uiImage: image).resizable())
                )
            case (.gifData, true):
                transformer(AnyView(KFAnimatedImage(source: .provider(self))))
            case (.none, _), (_, false):
                if let blurHashView {
                    if shouldRender {
                        transformer(blurHashView)
                    } else {
                        blurHashView
                    }
                } else {
                    placeholder().overlay { placeholderOverlay }
                }
            }
        }
        .animation(mediaType == .avatar ? .noAnimation : .elementDefault, value: contentLoader.content)
        .animation(.elementDefault, value: loadManually)
        .task(id: mediaSource.url.absoluteString + "\(shouldRender)") {
            guard shouldRender, contentLoader.content == nil else {
                return
            }
            
            await contentLoader.load()
        }
        .onDisappear {
            guard contentLoader.content == nil else {
                return
            }
            
            contentLoader.cancel()
        }
    }
    
    // Note: Returns `AnyView` as this is what `transformer` expects.
    var blurHashView: AnyView? {
        if let blurhash,
           // Build a small blurhash image so that it's fast
           let image = UIImage(blurHash: blurhash, size: .init(width: 10.0, height: 10.0)) {
            return AnyView(Image(uiImage: image).resizable().overlay { blurHashOverlay })
        } else {
            return nil
        }
    }
    
    // MARK: - Overlays
    
    @ViewBuilder
    var placeholderOverlay: some View {
        switch mediaType {
        case .avatar, .generic:
            EmptyView()
        case .timelineItem:
            if shouldRender {
                ProgressView(L10n.commonLoading)
                    .frame(maxWidth: .infinity)
            } else {
                loadManuallyButton
            }
        }
    }
    
    @ViewBuilder
    var blurHashOverlay: some View {
        if !shouldRender {
            loadManuallyButton
        }
    }
    
    var loadManuallyButton: some View {
        ZStack {
            Color.black.opacity(0.6)
                .contentShape(.rect)
                .onTapGesture { /* Empty gesture to block the `mediaTapped` action */ }
            
            // Don't use a real Button as it sometimes triggers simultaneously with the long press gesture.
            Text(L10n.actionShow)
                .font(.compound.bodyLGSemibold)
                .foregroundStyle(.compound.textOnSolidPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .overlay {
                    Capsule()
                        .stroke(lineWidth: 1)
                        .foregroundStyle(.compound.borderInteractiveSecondary)
                }
                .contentShape(.capsule)
                .onTapGesture {
                    loadManually = true
                }
                .environment(\.colorScheme, .light)
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

extension EnvironmentValues {
    /// Whether or not images should be loaded inside `LoadableImage` without a user interaction.
    @Entry var shouldAutomaticallyLoadImages = true
}

// MARK: - Previews

struct LoadableImage_Previews: PreviewProvider, TestablePreview {
    static let mediaProvider = makeMediaProvider()
    static let loadingMediaProvider = makeMediaProvider(isLoading: true)
    
    static var previews: some View {
        LazyVGrid(columns: [.init(.adaptive(minimum: 110, maximum: 110))], spacing: 24) {
            LoadableImage(url: "mxc://wherever/1234",
                          mediaType: .timelineItem(uniqueID: "id"),
                          mediaProvider: mediaProvider,
                          placeholder: placeholder)
                .layout(title: "Loaded")
            
            LoadableImage(url: "mxc://wherever/2345",
                          mediaType: .timelineItem(uniqueID: "id"),
                          blurhash: "KpE4oyayR5|GbHb];3j@of",
                          mediaProvider: mediaProvider,
                          placeholder: placeholder)
                .layout(title: "Hidden (blurhash)", hideTimelineMedia: true)
            
            LoadableImage(url: "mxc://wherever/3456",
                          mediaType: .timelineItem(uniqueID: "id"),
                          mediaProvider: mediaProvider,
                          placeholder: placeholder)
                .layout(title: "Hidden (placeholder)", hideTimelineMedia: true)
            
            LoadableImage(url: "mxc://wherever/4567",
                          mediaType: .timelineItem(uniqueID: "id"),
                          blurhash: "KbLM^j]q$jT|EfR-3rtjXk",
                          mediaProvider: loadingMediaProvider,
                          placeholder: placeholder)
                .layout(title: "Loading (blurhash)")
            
            LoadableImage(url: "mxc://wherever/5678",
                          mediaType: .timelineItem(uniqueID: "id"),
                          mediaProvider: loadingMediaProvider,
                          placeholder: placeholder)
                .layout(title: "Loading (placeholder)")
            
            LoadableImage(url: "mxc://wherever/6789",
                          mediaType: .avatar,
                          mediaProvider: loadingMediaProvider,
                          placeholder: placeholder)
                .layout(title: "Loading (avatar)")

            LoadableImage(url: "mxc://wherever/345",
                          mediaType: .timelineItem(uniqueID: "id"),
                          blurhash: "KbLM^j]q$jT|EfR-3rtjXk",
                          mediaProvider: mediaProvider,
                          transformer: transformer,
                          placeholder: placeholder)
                .layout(title: "Loaded (transformer)")
            
            LoadableImage(url: "mxc://wherever/345",
                          mediaType: .timelineItem(uniqueID: "id"),
                          blurhash: "KbLM^j]q$jT|EfR-3rtjXk",
                          mediaProvider: loadingMediaProvider,
                          transformer: transformer,
                          placeholder: placeholder)
                .layout(title: "Loading (transformer)")
            
            LoadableImage(url: "mxc://wherever/234",
                          mediaType: .timelineItem(uniqueID: "id"),
                          blurhash: "KbLM^j]q$jT|EfR-3rtjXk",
                          mediaProvider: mediaProvider,
                          transformer: transformer,
                          placeholder: placeholder)
                .layout(title: "Hidden (transformer)", hideTimelineMedia: true)
        }
    }
    
    static func placeholder() -> some View { Color.compound._bgBubbleIncoming }
    static func transformer(_ view: AnyView) -> some View {
        view.overlay {
            Image(systemSymbol: .playCircleFill)
                .font(.largeTitle)
                .foregroundStyle(.compound.iconAccentPrimary)
        }
    }
    
    static func makeMediaProvider(isLoading: Bool = false) -> MediaProviderProtocol {
        let mediaProvider = MediaProviderMock(configuration: .init())
        
        if isLoading {
            mediaProvider.imageFromSourceSizeClosure = { _, _ in nil }
            mediaProvider.loadFileFromSourceFilenameClosure = { _, _ in .failure(.failedRetrievingFile) }
            mediaProvider.loadImageDataFromSourceClosure = { _ in .failure(.failedRetrievingImage) }
            mediaProvider.loadImageFromSourceSizeClosure = { _, _ in .failure(.failedRetrievingImage) }
            mediaProvider.loadThumbnailForSourceSourceSizeClosure = { _, _ in .failure(.failedRetrievingThumbnail) }
            mediaProvider.loadImageRetryingOnReconnectionSizeClosure = { _, _ in
                Task { throw MediaProviderError.failedRetrievingImage }
            }
        }
        return mediaProvider
    }
}

private extension View {
    func layout(title: String, hideTimelineMedia: Bool = false) -> some View {
        aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(alignment: .bottom) {
                Text(title)
                    .font(.caption2)
                    .offset(y: 16)
                    .padding(.horizontal, -5)
            }
            .environment(\.shouldAutomaticallyLoadImages, !hideTimelineMedia)
    }
}
