//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LinksTimelineScreen: View {
    @State var context: LinksTimelineScreenViewModelType.Context
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        mainContent
            .background(.compound.bgCanvasDefault)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header - always show
            headerSection
            
            // Content based on state
            if context.viewState.shouldShowEmptyState {
                emptyState
            } else if context.viewState.shouldShowErrorState {
                errorState
            } else {
                // Links list
                ScrollView {
                    LazyVStack(spacing: 0) {
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
    }
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            Button("Hủy") {
                print("DEBUG: Cancel button tapped")
                dismiss()
            }
            .font(.compound.bodyLG)
            .foregroundColor(.compound.textSecondary)
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Text("Link")
                .font(.compound.headingSM)
                .foregroundColor(.compound.textPrimary)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Invisible spacer to balance the layout
            Text("Hủy")
                .font(.compound.bodyLG)
                .foregroundColor(.clear)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.compound.bgCanvasDefault)
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "link")
                .font(.system(size: 48))
                .foregroundColor(.compound.iconSecondary)
            
            Text("Không có link nào được gửi")
                .font(.compound.headingLG)
                .foregroundColor(.compound.textPrimary)
            
            Text("Các link được gửi sẽ xuất hiện ở đây.")
                .font(.compound.bodyLG)
                .foregroundColor(.compound.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var errorState: some View {
        VStack(spacing: 16) {
            Spacer()
            
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
            
            Spacer()
        }
        .padding(16)
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
