//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LinksTimelineScreen: View {
    @State var context: LinksTimelineScreenViewModel.Context
    
    var body: some View {
        mainContent
            .navigationBarTitleDisplayMode(.inline)
            .background(.compound.bgCanvasDefault)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar { toolbar }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if context.viewState.shouldShowEmptyState {
            emptyState
        } else if context.viewState.shouldShowErrorState {
            errorState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if !context.viewState.bindings.availableSenders.isEmpty {
                        filterSection
                    }
                    
                    ForEach(context.viewState.links) { link in
                        LinkItemView(link: link) { action in
                            switch action {
                            case .openURL:
                                context.send(viewAction: .openURL(link.url))
                            default:
                                break
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .onAppear {
                            print("DEBUG: LinkItemView appeared for URL: \(link.url.absoluteString), EventID: \(link.eventID)")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Filter by sender")
                .font(.compound.bodyLG)
                .foregroundColor(.compound.textSecondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            Menu {
                Button("All") {
                    context.send(viewAction: .filterBySender(nil))
                }
                
                ForEach(context.viewState.bindings.availableSenders, id: \.self) { senderID in
                    Button(senderID) {
                        context.send(viewAction: .filterBySender(senderID))
                    }
                }
            } label: {
                HStack {
                    Text(context.viewState.bindings.selectedSenderFilter ?? "All")
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.compound.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.compound.bgSubtleSecondary)
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var emptyState: some View {
        FullscreenDialog(topPadding: UIConstants.iconTopPaddingToNavigationBar, background: .gradient) {
            VStack(spacing: 16) {
                Image(systemName: "link")
                    .font(.system(size: 48))
                    .foregroundColor(.compound.iconSecondary)
                
                Text("No links shared yet")
                    .font(.compound.headingLG)
                    .foregroundColor(.compound.textPrimary)
                
                Text("Links shared in this room will be shown here.")
                    .font(.compound.bodyLG)
                    .foregroundColor(.compound.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
        } bottomContent: { EmptyView() }
    }
    
    @ViewBuilder
    private var errorState: some View {
        FullscreenDialog(topPadding: UIConstants.iconTopPaddingToNavigationBar, background: .gradient) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.compound.iconCriticalPrimary)
                
                Text(L10n.commonError)
                    .font(.compound.headingLG)
                    .foregroundColor(.compound.textPrimary)
                
                if let errorMessage = context.viewState.errorMessage {
                    Text(errorMessage)
                        .font(.compound.bodyLG)
                        .foregroundColor(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(L10n.actionRetry) {
                    context.send(viewAction: .retry)
                }
                .buttonStyle(.compound(.primary))
            }
            .padding(16)
        } bottomContent: { EmptyView() }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(L10n.actionClose) {
                context.send(viewAction: .close)
            }
        }
        
        ToolbarItem(placement: .principal) {
            Text(context.viewState.roomTitle)
                .font(.compound.headingSM)
                .foregroundColor(.compound.textPrimary)
        }
    }
}

struct LinkItemView: View {
    let link: LinkItem
    let onAction: (LinkItemAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(link.sender.displayName ?? link.sender.id)
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                    
                    Text(link.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.compound.bodyXS)
                        .foregroundColor(.compound.textDisabled)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let title = link.title, !title.isEmpty {
                    Text(title)
                        .font(.compound.bodyLG)
                        .foregroundColor(.compound.textPrimary)
                        .lineLimit(2)
                }
                
                Button(action: {
                    print("DEBUG: URL button tapped")
                    onAction(.openURL)
                }) {
                    Text(link.url.absoluteString)
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textLinkExternal)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .underline()
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(.compound.bgSubtleSecondary)
        .cornerRadius(8)
    }
}

enum LinkItemAction {
    case openURL
}

 
