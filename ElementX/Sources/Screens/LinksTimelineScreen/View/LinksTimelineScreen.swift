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
    @State private var selectedSenderFilter: String? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        mainContent
            .background(.compound.bgCanvasDefault)
    }
    
    // Computed properties for filtering
    private var availableSenders: [String] {
        let senders = Set(context.viewState.allLinks.map(\.sender.id))
        return Array(senders).sorted()
    }
    
    private var filteredLinks: [LinkItem] {
        if let selectedFilter = selectedSenderFilter {
            return context.viewState.allLinks.filter { $0.sender.id == selectedFilter }
        } else {
            return context.viewState.allLinks
        }
    }
    
    private var shouldShowFilteredEmptyState: Bool {
        !context.viewState.isLoading && filteredLinks.isEmpty && context.viewState.errorMessage == nil && selectedSenderFilter != nil
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header - always show
            headerSection
            
            // Filter section
            if !availableSenders.isEmpty {
                filterSection
            }
            
            // Content based on state
            if shouldShowFilteredEmptyState {
                filteredEmptyState
            } else if context.viewState.shouldShowEmptyState {
                emptyState
            } else if context.viewState.shouldShowErrorState {
                errorState
            } else {
                // Links list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredLinks) { link in
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
    private var filterSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Lọc theo người gửi")
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
                
                Spacer()
                
                if selectedSenderFilter != nil {
                    Button("Xóa bộ lọc") {
                        selectedSenderFilter = nil
                    }
                    .font(.compound.bodyXS)
                    .foregroundColor(.compound.textLinkExternal)
                }
            }
            .padding(.horizontal, 16)
            
            // Dropdown picker
            HStack {
                Menu {
                    Button("Tất cả") {
                        selectedSenderFilter = nil
                    }
                    
                    Divider()
                    
                    ForEach(availableSenders, id: \.self) { senderID in
                        let senderName = getSenderDisplayName(for: senderID)
                        Button(senderName) {
                            selectedSenderFilter = senderID
                        }
                    }
                } label: {
                    HStack {
                        Text(getSelectedFilterDisplayName())
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
                .menuStyle(BorderlessButtonMenuStyle())
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(.compound.bgCanvasDefault)
    }
    
    private func getSenderDisplayName(for senderID: String) -> String {
        // Find the sender in allLinks to get display name
        if let linkItem = context.viewState.allLinks.first(where: { $0.sender.id == senderID }) {
            return linkItem.sender.displayName ?? linkItem.sender.id
        }
        return senderID
    }
    
    private func getSelectedFilterDisplayName() -> String {
        if let selectedFilter = selectedSenderFilter {
            return getSenderDisplayName(for: selectedFilter)
        } else {
            return "Tất cả"
        }
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
    private var filteredEmptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.compound.iconSecondary)
            
            Text("Không tìm thấy link")
                .font(.compound.headingLG)
                .foregroundColor(.compound.textPrimary)
            
            if let selectedFilter = selectedSenderFilter {
                let senderName = getSenderDisplayName(for: selectedFilter)
                Text("Không có link nào được gửi bởi \(senderName)")
                    .font(.compound.bodyLG)
                    .foregroundColor(.compound.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Xem tất cả link") {
                selectedSenderFilter = nil
            }
            .buttonStyle(.compound(.primary))
            
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
                    
                    Text(link.timestamp.formatted(.dateTime.day().month().year().hour().minute().locale(Locale(identifier: "vi_VN"))))
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
