//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import GameController
import QuickLook
import SwiftUI

struct MediaUploadPreviewScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var context: MediaUploadPreviewScreenViewModel.Context
    
    @State private var captionWarningFrame: CGRect = .zero
    @FocusState private var isComposerFocussed
    
    private var title: String { ProcessInfo.processInfo.isiOSAppOnMac ? context.viewState.title ?? "" : "" }
    private var colorSchemeOverride: ColorScheme { ProcessInfo.processInfo.isiOSAppOnMac ? colorScheme : .dark }
    
    var body: some View {
        mainContent
            .id(context.viewState.url)
            .ignoresSafeArea(edges: [.horizontal])
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composer
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .background() // Don't use compound so we match the QLPreviewController.
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .disabled(context.viewState.shouldDisableInteraction)
            .interactiveDismissDisabled()
            .presentationBackground(.background) // Fix a bug introduced by the caption warning.
            .preferredColorScheme(colorSchemeOverride)
            .onAppear(perform: focusComposerIfHardwareKeyboardConnected)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            Text(title)
                .font(.compound.headingMD)
                .foregroundColor(.compound.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            PreviewView(fileURL: context.viewState.url,
                        title: context.viewState.title)
        }
    }
    
    private var composer: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                MessageComposerTextField(placeholder: L10n.richTextEditorComposerCaptionPlaceholder,
                                         text: $context.caption,
                                         presendCallback: $context.presendCallback,
                                         maxHeight: ComposerConstant.maxHeight,
                                         keyHandler: handleKeyPress) { _ in }
                    .focused($isComposerFocussed)
                
                if context.viewState.shouldShowCaptionWarning {
                    captionWarningButton
                }
            }
            .messageComposerStyle()
            
            SendButton {
                context.send(viewAction: .send)
            }
        }
    }
    
    private var captionWarningButton: some View {
        Button {
            context.isPresentingMediaCaptionWarning = true
        } label: {
            CompoundIcon(\.infoSolid, size: .xSmall, relativeTo: .compound.bodyLG)
        }
        .tint(.compound.iconCriticalPrimary)
        .popover(isPresented: $context.isPresentingMediaCaptionWarning, arrowEdge: .bottom) {
            captionWarningContent
                .presentationDetents([.height(captionWarningFrame.height)])
                .presentationDragIndicator(.visible)
                .padding(.top, 19) // For the drag indicator
                .presentationBackground(.compound.bgCanvasDefault)
                .preferredColorScheme(colorSchemeOverride)
        }
    }
    
    var captionWarningContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                BigIcon(icon: \.infoSolid, style: .alertSolid)
                
                Text(L10n.screenMediaUploadPreviewCaptionWarning)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .padding(.bottom, 8)
            
            Button(L10n.actionOk) {
                context.isPresentingMediaCaptionWarning = false
            }
            .buttonStyle(.compound(.secondary))
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .readFrame($captionWarningFrame)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { context.send(viewAction: .cancel) } label: {
                Text(L10n.actionCancel)
            }
            // Fix a bug with the preferredColorScheme on iOS 18 where the button doesn't
            // follow the dark colour scheme on devices running with dark mode disabled.
            .tint(.compound.textActionPrimary)
        }
    }
    
    private func handleKeyPress(_ key: UIKeyboardHIDUsage) {
        switch key {
        case .keyboardReturnOrEnter:
            context.send(viewAction: .send)
        case .keyboardEscape:
            context.send(viewAction: .cancel)
        default:
            break
        }
    }
    
    private func focusComposerIfHardwareKeyboardConnected() {
        // The simulator always detects the hardware keyboard as connected
        #if !targetEnvironment(simulator)
        if GCKeyboard.coalesced != nil {
            MXLog.info("Hardware keyboard is connected")
            isComposerFocussed = true
        }
        #endif
    }
}

private struct PreviewView: UIViewControllerRepresentable {
    let fileURL: URL
    let title: String?

    func makeUIViewController(context: Context) -> UIViewController {
        let previewController = PreviewViewController()
        previewController.dataSource = context.coordinator
        previewController.delegate = context.coordinator
        
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return previewController
        } else {
            return UINavigationController(rootViewController: previewController)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(view: self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let view: PreviewView

        init(view: PreviewView) {
            self.view = view
        }
        
        // MARK: - QLPreviewControllerDataSource
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            PreviewItem(previewItemURL: view.fileURL, previewItemTitle: view.title)
        }
        
        // MARK: - QLPreviewControllerDelegate
        
        func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
            .disabled
        }
    }
}

private class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?

    init(previewItemURL: URL?, previewItemTitle: String?) {
        self.previewItemURL = previewItemURL
        self.previewItemTitle = previewItemTitle
    }
}

private class PreviewViewController: QLPreviewController {
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Remove top file details bar
        navigationController?.navigationBar.isHidden = true
                
        // Hide toolbar share button
        toolbarItems?.first?.isHidden = true
    }
}

// MARK: - Previews

struct MediaUploadPreviewScreen_Previews: PreviewProvider, TestablePreview {
    static let snapshotURL = URL.picturesDirectory
    static let testURL = Bundle.main.url(forResource: "AppIcon60x60@2x", withExtension: "png")
    
    static let viewModel = MediaUploadPreviewScreenViewModel(userIndicatorController: UserIndicatorControllerMock.default,
                                                             roomProxy: JoinedRoomProxyMock(),
                                                             mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: ServiceLocator.shared.settings),
                                                             title: "App Icon.png",
                                                             url: snapshotURL,
                                                             shouldShowCaptionWarning: true)
    static var previews: some View {
        NavigationStack {
            MediaUploadPreviewScreen(context: viewModel.context)
        }
        
        MediaUploadPreviewScreen(context: viewModel.context)
            .captionWarningContent
            .previewDisplayName("Caption warning")
    }
}
