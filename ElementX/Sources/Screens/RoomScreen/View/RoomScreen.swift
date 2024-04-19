//
// Copyright 2022 New Vector Ltd
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

import Compound
import SwiftUI
import WysiwygComposer

struct RoomScreen: View {
    @ObservedObject var context: RoomScreenViewModel.Context
    @ObservedObject private var composerToolbarContext: ComposerToolbarViewModel.Context
    @State private var dragOver = false
    let composerToolbar: ComposerToolbar

    init(context: RoomScreenViewModel.Context, composerToolbar: ComposerToolbar) {
        self.context = context
        self.composerToolbar = composerToolbar
        composerToolbarContext = composerToolbar.context
    }

    var body: some View {
        timeline
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composerToolbar
                    .padding(.bottom, composerToolbarContext.composerActionsEnabled ? 8 : 12)
                    .background {
                        if composerToolbarContext.composerActionsEnabled {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.compound.borderInteractiveSecondary, lineWidth: 0.5)
                                .ignoresSafeArea()
                        }
                    }
                    .padding(.top, 8)
                    .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
                    .environmentObject(context)
            }
            .navigationTitle(L10n.commonRoom) // Hidden but used for back button text.
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(isNavigationBarHidden)
            .toolbar { toolbar }
            .toolbarBackground(.visible, for: .navigationBar) // Fix the toolbar's background.
            .overlay { loadingIndicator }
            .alert(item: $context.alertInfo)
            .alert(item: $context.confirmationAlertInfo)
            .sheet(item: $context.debugInfo) { TimelineItemDebugView(info: $0) }
            .sheet(item: $context.actionMenuInfo) { info in
                context.viewState.timelineItemMenuActionProvider?(info.item.id).map { actions in
                    TimelineItemMenu(item: info.item, actions: actions)
                        .environmentObject(context)
                }
            }
            .sheet(item: $context.reactionSummaryInfo) {
                ReactionsSummaryView(reactions: $0.reactions, members: context.viewState.members, imageProvider: context.imageProvider, selectedReactionKey: $0.selectedKey)
                    .edgesIgnoringSafeArea([.bottom])
            }
            .sheet(item: $context.readReceiptsSummaryInfo) {
                ReadReceiptsSummaryView(orderedReadReceipts: $0.orderedReceipts)
                    .environmentObject(context)
            }
            .interactiveQuickLook(item: $context.mediaPreviewItem)
            .track(screen: .Room)
            .onDrop(of: ["public.item", "public.file-url"], isTargeted: $dragOver) { providers -> Bool in
                guard let provider = providers.first,
                      provider.isSupportedForPasteOrDrop else {
                    return false
                }
                
                context.send(viewAction: .handlePasteOrDrop(provider: provider))
                return true
            }
            .confirmationDialog(item: $context.sendFailedConfirmationDialogInfo, titleVisibility: .visible) { info in
                Button(L10n.screenRoomRetrySendMenuSendAgainAction) {
                    context.send(viewAction: .retrySend(itemID: info.itemID))
                }
                Button(L10n.actionRemove, role: .destructive) {
                    context.send(viewAction: .cancelSend(itemID: info.itemID))
                }
            }
    }

    private var timeline: some View {
        UITimelineView()
            .id(context.viewState.roomID)
            .environmentObject(context)
            .environment(\.timelineStyle, context.viewState.timelineStyle)
            .overlay(alignment: .bottomTrailing) {
                scrollToBottomButton
            }
    }
    
    private var scrollToBottomButton: some View {
        Button { context.viewState.timelineViewState.scrollToBottomPublisher.send(()) } label: {
            Image(systemName: "chevron.down")
                .font(.compound.bodyLG)
                .fontWeight(.semibold)
                .foregroundColor(.compound.iconSecondary)
                .padding(13)
                .offset(y: 1)
                .background {
                    Circle()
                        .fill(Color.compound.iconOnSolidPrimary)
                        // Intentionally using system primary colour to get white/black.
                        .shadow(color: .primary.opacity(0.33), radius: 2.0)
                }
                .padding()
        }
        .opacity(context.isScrolledToBottom ? 0.0 : 1.0)
        .accessibilityHidden(context.isScrolledToBottom)
        .animation(.elementDefault, value: context.isScrolledToBottom)
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        if context.viewState.showLoading {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.compound.textPrimary)
                .padding(16)
                .background(.ultraThickMaterial)
                .cornerRadius(8)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        // .principal + .primaryAction works better than .navigation leading + trailing
        // as the latter disables interaction in the action button for rooms with long names
        ToolbarItem(placement: .principal) {
            RoomHeaderView(roomID: context.viewState.roomID,
                           roomName: context.viewState.roomTitle,
                           avatarURL: context.viewState.roomAvatarURL,
                           imageProvider: context.imageProvider)
                // Using a button stops it from getting truncated in the navigation bar
                .onTapGesture {
                    context.send(viewAction: .displayRoomDetails)
                }
        }
        
        if !ProcessInfo.processInfo.isiOSAppOnMac {
            ToolbarItem(placement: .primaryAction) {
                callButton
                    .disabled(context.viewState.canJoinCall == false)
            }
        }
    }
    
    @ViewBuilder
    private var callButton: some View {
        if context.viewState.hasOngoingCall {
            Button {
                context.send(viewAction: .presentCall)
            } label: {
                Label(L10n.actionJoin, icon: \.videoCallSolid)
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(ElementCallButtonStyle())
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.joinCall)
        } else {
            Button {
                context.send(viewAction: .presentCall)
            } label: {
                CompoundIcon(\.videoCallSolid)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.joinCall)
        }
    }
    
    private var isNavigationBarHidden: Bool {
        composerToolbarContext.composerActionsEnabled && composerToolbarContext.composerExpanded && UIDevice.current.userInterfaceIdiom == .pad
    }
}

// MARK: - Previews

struct RoomScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomScreenViewModel(roomProxy: RoomProxyMock(with: .init(name: "Preview room", hasOngoingCall: true)),
                                               timelineController: MockRoomTimelineController(),
                                               mediaProvider: MockMediaProvider(),
                                               mediaPlayerProvider: MediaPlayerProviderMock(),
                                               voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings,
                                               analyticsService: ServiceLocator.shared.analytics,
                                               notificationCenter: NotificationCenterMock())

    static var previews: some View {
        NavigationStack {
            RoomScreen(context: viewModel.context, composerToolbar: ComposerToolbar.mock())
        }
    }
}
