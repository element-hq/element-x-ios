//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct MessageSearchScreen: View {
    @ObservedObject var context: MessageSearchViewModelType.Context
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                
                if context.viewState.isLoading {
                    loadingView
                } else if context.viewState.searchResults.isEmpty, context.viewState.hasSearched {
                    emptyResultsView
                } else if context.viewState.searchResults.isEmpty, !context.viewState.hasSearched {
                    placeholderView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Tìm kiếm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        context.send(viewAction: .dismiss)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.compound.textSecondary)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Tìm kiếm tin nhắn trong phòng này", text: Binding(get: { context.viewState.bindings.searchQuery },
                                                                         set: { newValue in
                                                                             context.send(viewAction: .searchQueryChanged(newValue))
                                                                         }))
                                                                         .textFieldStyle(.plain)
                                                                         .autocorrectionDisabled()
                                                                         .autocapitalization(.none)
                                                                         .font(.compound.bodyMD)
            
            if !context.viewState.bindings.searchQuery.isEmpty {
                Button {
                    context.send(viewAction: .clearSearch)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.compound.textSecondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.compound.bgSubtleSecondary)
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.compound.borderInteractiveSecondary, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.compound.textPrimary)
            Text("Đang tìm kiếm tin nhắn...")
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textSecondary)
                .padding(.top, 8)
            Spacer()
        }
    }
    
    @ViewBuilder
    private var emptyResultsView: some View {
        VStack {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.compound.textSecondary)
                .padding(.bottom, 16)
            
            Text("Không tìm thấy tin nhắn")
                .font(.compound.headingMDBold)
                .foregroundColor(.compound.textPrimary)
                .padding(.bottom, 8)
            
            Text("Thử tìm kiếm với từ khóa khác hoặc kiểm tra chính tả")
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        VStack {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.compound.textSecondary)
                .padding(.bottom, 16)
            
            Text("Tìm kiếm tin nhắn")
                .font(.compound.headingMDBold)
                .foregroundColor(.compound.textPrimary)
                .padding(.bottom, 8)
            
            Text("Nhập để tìm kiếm tin nhắn, đề cập hoặc nội dung cụ thể trong phòng này")
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
    
    @ViewBuilder
    private var searchResultsList: some View {
        VStack(spacing: 0) {
            if !context.viewState.searchResults.isEmpty {
                HStack {
                    Text("\(context.viewState.searchResults.count) kết quả")
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    Spacer()
                }
                .background(Color.compound.bgSubtleSecondary)
            }
            
            List(context.viewState.searchResults) { result in
                MessageSearchResultRow(result: result,
                                       searchQuery: context.viewState.bindings.searchQuery) {
                    context.send(viewAction: .selectMessage(eventID: result.eventID))
                }
            }
            .listStyle(.plain)
        }
    }
}

struct MessageSearchResultRow: View {
    let result: MessageSearchResult
    let searchQuery: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.sender)
                        .font(.compound.bodyMDSemibold)
                        .foregroundColor(.compound.textPrimary)
                    
                    Spacer()
                    
                    Text(formatTimestamp(result.timestamp))
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                }
                
                HighlightedText(text: result.content, highlight: searchQuery)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
                    .lineLimit(3)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .background(Color.compound.bgCanvasDefault)
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct HighlightedText: View {
    let text: String
    let highlight: String
    
    private var attributedText: AttributedString {
        if highlight.isEmpty {
            return AttributedString(text)
        }
        
        let attributedString = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: text.count)
        let pattern = NSRegularExpression.escapedPattern(for: highlight)
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches {
                attributedString.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.3), range: match.range)
                attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: match.range)
            }
        } catch {
            // Fallback to plain text if regex fails
        }
        
        return AttributedString(attributedString)
    }
    
    var body: some View {
        Text(attributedText)
    }
}

// MARK: - Previews

struct MessageSearchScreen_Previews: PreviewProvider {
    static var previews: some View {
        MessageSearchScreen(context: makeViewModel().context)
    }
    
    static func makeViewModel() -> MessageSearchViewModel {
        let roomProxy = JoinedRoomProxyMock(.init(id: "test_room"))
        return MessageSearchViewModel(roomProxy: roomProxy)
    }
}
