//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SearchRecipientView: View {
    @ObservedObject var context: TransferTokenViewModel.Context
    let scrollViewAdapter: ScrollViewAdapter
    
    var body: some View {
        VStack(alignment: .leading) {
            RecipientSearchBar(onSearch: { query in
                context.searchRecipientQuery = query
            })
            
            Text("Results")
                .font(.compound.bodyMDSemibold)
                .foregroundStyle(.compound.textSecondary)
                .padding(.top, 8)
            
            recipientsList
        }
        .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
        .padding()
    }
    
    var recipientsList: some View {
        GeometryReader { geometry in
            ScrollView {
                switch context.viewState.recipientsListMode {
                case .skeletons:
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(context.viewState.placeholderRecipeints) { recipient in
                            RecipientInfoCell(recipient: recipient, mediaProvider: context.mediaProvider, onRecipientSelected: {
                                
                            })
                            .redacted(reason: .placeholder)
                            .shimmer()
                        }
                    }
                    .disabled(true)
                case .empty:
//                    HomeContentEmptyView(message: "No recipients found")
                    EmptyView()
                case .recipients(let recipients):
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(recipients, id: \.id) { recipient in
                            RecipientInfoCell(recipient: recipient, mediaProvider: context.mediaProvider, onRecipientSelected: {
                                context.send(viewAction: .onRecipientSelected(recipient))
                            })
                        }
                    }
                }
            }
            .introspect(.scrollView, on: .supportedVersions) { scrollView in
                guard scrollView != scrollViewAdapter.scrollView else { return }
                scrollViewAdapter.scrollView = scrollView
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}

struct RecipientSearchBar: View {
    let onSearch: (String) -> Void
    
    @State var text: String = ""
    
    var body: some View {
        HStack {
            Text("To: ")
                .font(.body)
                .foregroundStyle(.zero.bgAccentRest)
            
            TextField("Name, ZNS or Address", text: $text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                CompoundIcon(\.close)
                    .onTapGesture {
                        text = ""
                    }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onChange(of: text) { _, newValue in
            onSearch(newValue)
        }
    }
}

struct RecipientInfoCell: View {
    let recipient: WalletRecipient
    let mediaProvider: MediaProviderProtocol?
    let onRecipientSelected: () -> Void
    
    var body: some View {
        HStack {
            LoadableAvatarImage(url: URL(string: recipient.profileImage),
                                name: recipient.name,
                                contentID: recipient.id,
                                avatarSize: .user(on: .home),
                                mediaProvider: mediaProvider,
                                onTap: { _ in
            })
            
            VStack(alignment: .leading) {
                HStack {
                    Text(recipient.name)
                        .font(.zero.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                    
                    Text(recipient.primaryZid)
                        .font(.zero.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                if let address = displayFormattedAddress(recipient.publicAddress) {
                    Text(address)
                        .font(.zero.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 12)
        .onTapGesture {
            onRecipientSelected()
        }
    }
}
