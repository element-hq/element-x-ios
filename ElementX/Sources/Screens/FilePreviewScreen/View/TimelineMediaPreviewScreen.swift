//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Compound
import QuickLook
import SwiftUI

struct TimelineMediaPreviewScreen: View {
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    
    private var currentItem: TimelineMediaPreviewItem { context.viewState.currentItem }
    
    var body: some View {
        NavigationStack {
            Color.clear
                .overlay { QuickLookView(viewModelContext: context).ignoresSafeArea() } // Overlay to stop QL hijacking the toolbar.
                .toolbar { toolbar }
                .toolbarBackground(.visible, for: .navigationBar) // The toolbar's scrollEdgeAppearance isn't aware of the quicklook view 🤷‍♂️
                .toolbarBackground(.visible, for: .bottomBar)
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom, spacing: 0) { caption }
        }
        .introspect(.navigationStack, on: .supportedVersions) {
            // Fixes a bug where the QuickLook view overrides the .toolbarBackground(.visible) after it loads the real item.
            $0.navigationBar.scrollEdgeAppearance = $0.navigationBar.standardAppearance
            $0.toolbar.scrollEdgeAppearance = $0.toolbar.standardAppearance
        }
        .sheet(item: $context.mediaDetailsItem) { item in
            TimelineMediaPreviewDetailsView(item: item, context: context)
        }
        .sheet(item: $context.fileToExport) { file in
            TimelineMediaPreviewFileExportPicker(file: file)
                .preferredColorScheme(.dark)
        }
        .alert(item: $context.alertInfo)
        .preferredColorScheme(.dark)
        .zoomTransition(sourceID: currentItem.id, in: context.viewState.transitionNamespace)
    }
    
    @ViewBuilder
    private var caption: some View {
        if let caption = currentItem.caption {
            Text(caption)
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textPrimary)
                .lineLimit(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .background {
                    BlurEffectView(style: .systemChromeMaterial) // Darkest material available, matches the bottom bar when content is beneath.
                }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { context.send(viewAction: .dismiss) } label: {
                Image(systemSymbol: .chevronBackward)
                    .fontWeight(.semibold)
            }
            .tint(.compound.textActionPrimary) // These fix a bug where the light tint is shown when foregrounding the app.
        }
        
        ToolbarItem(placement: .principal) {
            toolbarHeader
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button { context.send(viewAction: .showCurrentItemDetails) } label: {
                CompoundIcon(\.info)
            }
            .tint(.compound.textActionPrimary)
        }
        
        ToolbarItem(placement: .bottomBar) {
            bottomBarContent
                .tint(.compound.textActionPrimary)
        }
    }
    
    private var toolbarHeader: some View {
        VStack(spacing: 0) {
            Text(currentItem.sender.displayName ?? currentItem.sender.id)
                .font(.compound.bodySMSemibold)
                .foregroundStyle(.compound.textPrimary)
            Text(currentItem.timestamp.formatted(date: .abbreviated, time: .omitted))
                .font(.compound.bodyXS)
                .foregroundStyle(.compound.textPrimary)
                .textCase(.uppercase)
        }
    }
    
    private var bottomBarContent: some View {
        HStack(spacing: 8) {
            if let url = currentItem.fileHandle?.url {
                ShareLink(item: url, subject: nil, message: currentItem.caption.map(Text.init)) {
                    CompoundIcon(\.shareIos)
                }
                
                Spacer()
                
                Button { context.send(viewAction: .saveCurrentItem) } label: {
                    CompoundIcon(\.downloadIos)
                }
            }
        }
    }
}

private struct QuickLookView: UIViewControllerRepresentable {
    let viewModelContext: TimelineMediaPreviewViewModel.Context

    func makeUIViewController(context: Context) -> PreviewController {
        PreviewController(coordinator: context.coordinator,
                          fileLoadedPublisher: viewModelContext.viewState.fileLoadedPublisher.eraseToAnyPublisher())
    }

    func updateUIViewController(_ uiViewController: PreviewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModelContext: viewModelContext)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        private let viewModelContext: TimelineMediaPreviewViewModel.Context
        
        init(viewModelContext: TimelineMediaPreviewViewModel.Context) {
            self.viewModelContext = viewModelContext
        }
        
        func updateCurrentItem(_ item: TimelineMediaPreviewItem) {
            viewModelContext.send(viewAction: .updateCurrentItem(item))
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            viewModelContext.viewState.previewItems.count
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            viewModelContext.viewState.previewItems[index]
        }
    }
    
    class PreviewController: QLPreviewController {
        let coordinator: Coordinator
        
        private var cancellables: Set<AnyCancellable> = []
        
        init(coordinator: Coordinator, fileLoadedPublisher: AnyPublisher<TimelineItemIdentifier, Never>) {
            self.coordinator = coordinator
            
            super.init(nibName: nil, bundle: nil)
            
            dataSource = coordinator
            delegate = coordinator
            
            // Observation of currentPreviewItem doesn't work, so use the index instead.
            publisher(for: \.currentPreviewItemIndex)
                .sink { [weak self] _ in
                    guard let self, let currentPreviewItem = currentPreviewItem as? TimelineMediaPreviewItem else { return }
                    coordinator.updateCurrentItem(currentPreviewItem)
                }
                .store(in: &cancellables)
            
            fileLoadedPublisher
                .sink { [weak self] itemID in
                    guard let self, (currentPreviewItem as? TimelineMediaPreviewItem)?.id == itemID else { return }
                    refreshCurrentPreviewItem()
                }
                .store(in: &cancellables)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

// MARK: - Previews

struct TimelineMediaPreviewScreen_Previews: PreviewProvider {
    @Namespace private static var namespace
    
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        TimelineMediaPreviewScreen(context: viewModel.context)
    }
    
    static func makeViewModel() -> TimelineMediaPreviewViewModel {
        let item = FileRoomTimelineItem(id: .randomEvent,
                                        timestamp: .mock,
                                        isOutgoing: false,
                                        isEditable: false,
                                        canBeRepliedTo: true,
                                        isThreaded: false,
                                        sender: .init(id: "", displayName: "Sally Sanderson"),
                                        content: .init(filename: "Important document.pdf",
                                                       caption: "A caption goes right here.",
                                                       source: try? .init(url: .mockMXCFile, mimeType: nil),
                                                       fileSize: 3 * 1024 * 1024,
                                                       thumbnailSource: nil,
                                                       contentType: .pdf))
        
        return TimelineMediaPreviewViewModel(context: .init(item: item,
                                                            viewModel: TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen)),
                                                            namespace: namespace),
                                             mediaProvider: MediaProviderMock(configuration: .init()),
                                             photoLibraryManager: PhotoLibraryManagerMock(.init()),
                                             userIndicatorController: UserIndicatorControllerMock(),
                                             appMediator: AppMediatorMock())
    }
}
