//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import SwiftUI

struct FindFriendsScreen: View {
    @Bindable var context: FindFriendsScreenViewModel.Context

    var body: some View {
        content
            .navigationTitle("Find friends")
            .navigationBarTitleDisplayMode(.inline)
            .alert(item: $context.alertInfo)
    }

    @ViewBuilder
    private var content: some View {
        switch context.viewState.phase {
        case .loading:
            messageState(systemImage: nil,
                         title: "Looking for your contacts on Gua…",
                         message: nil,
                         showsSpinner: true)
        case .needsPermission:
            messageState(systemImage: "person.crop.circle.badge.questionmark",
                         title: "Allow access to Contacts",
                         message: "Gua checks your contacts privately to find which of them are already here. Your contacts are never stored.",
                         actionTitle: "Open Settings") {
                context.send(viewAction: .openSystemSettings)
            }
        case .empty:
            messageState(systemImage: "person.2",
                         title: "No contacts on Gua yet",
                         message: "None of your contacts are on Gua yet. Invite them and they'll show up here.",
                         actionTitle: "Check again") {
                context.send(viewAction: .retry)
            }
        case .error:
            messageState(systemImage: "exclamationmark.triangle",
                         title: "Something went wrong",
                         message: context.viewState.errorMessage,
                         actionTitle: "Try again") {
                context.send(viewAction: .retry)
            }
        case .loaded:
            contactsList
        }
    }

    private var contactsList: some View {
        List {
            Section {
                ForEach(context.viewState.contacts) { contact in
                    contactRow(contact)
                }
            } header: {
                Text(headerText)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var headerText: String {
        let count = context.viewState.contacts.count
        return count == 1 ? "1 contact is on Gua" : "\(count) contacts are on Gua"
    }

    private func contactRow(_ contact: DiscoveredContact) -> some View {
        Button {
            context.send(viewAction: .selectContact(contact))
        } label: {
            HStack(spacing: 12) {
                avatar(for: contact)
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.localName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(contact.handle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if context.viewState.startingChatUserID == contact.userId {
                    ProgressView()
                } else {
                    Image(systemName: "message")
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(context.viewState.startingChatUserID != nil)
    }

    private func avatar(for contact: DiscoveredContact) -> some View {
        Circle()
            .fill(Color.accentColor.opacity(0.15))
            .frame(width: 40, height: 40)
            .overlay {
                Text(initial(for: contact.localName))
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
            }
    }

    private func initial(for name: String) -> String {
        guard let first = name.trimmingCharacters(in: .whitespaces).first else { return "?" }
        return String(first).uppercased()
    }

    @ViewBuilder
    private func messageState(systemImage: String?,
                              title: String,
                              message: String?,
                              showsSpinner: Bool = false,
                              actionTitle: String? = nil,
                              action: (() -> Void)? = nil) -> some View {
        VStack(spacing: 16) {
            if showsSpinner {
                ProgressView()
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
