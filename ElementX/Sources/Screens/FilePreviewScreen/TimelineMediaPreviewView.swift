//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct TimelineMediaPreviewView: View {
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    
    private var currentItem: TimelineMediaPreviewItem { context.viewState.currentItem }
    
    var body: some View {
        NavigationStack {
            Color.clear
                .overlay { QuickLookView(viewModelContext: context) } // Overlay to stop QL hijacking the toolbar.
                .toolbar { toolbar }
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom, spacing: 0) { caption }
        }
        .sheet(item: $context.mediaDetailsItem) { item in
            TimelineMediaPreviewDetailsView(item: item, context: context)
        }
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
                    BlurView(style: .systemChromeMaterial) // Darkest material available, matches the bottom bar when content is beneath.
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
            }
            
            Spacer()
            
            Button { } label: {
                CompoundIcon(\.download)
            }
        }
    }
}

private struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

private struct QuickLookView: UIViewControllerRepresentable {
    let viewModelContext: TimelineMediaPreviewViewModel.Context

    func makeUIViewController(context: Context) -> TimelineMediaPreviewController {
        TimelineMediaPreviewController(viewModelContext: viewModelContext)
    }

    func updateUIViewController(_ uiViewController: TimelineMediaPreviewController, context: Context) { }
}

// MARK: - Previews

struct TimelineMediaPreviewView_Previews: PreviewProvider {
    @Namespace private static var namespace
    
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        QuickLookView(viewModelContext: viewModel.context)
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
                                             userIndicatorController: UserIndicatorControllerMock())
    }
}
