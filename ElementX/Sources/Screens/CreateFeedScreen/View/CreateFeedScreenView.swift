//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct CreateFeedScreen: View {
    @ObservedObject var context: CreateFeedScreenViewModel.Context
    
    var body: some View {
        CreateFeedContent(context: context)
            .zeroList()
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .alert(item: $context.alertInfo)
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        if !context.feedText.isEmpty {
            ToolbarItem(placement: .confirmationAction) {
                Button("Post") {
                    context.send(viewAction: .createPost)
                }
            }
        }
        ToolbarItem(placement: .cancellationAction) {
            Button {
                context.send(viewAction: .dismissPost)
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 12, height: 12)
                    .padding()
            }
        }
    }
}

private struct CreateFeedContent: View {
    @ObservedObject var context: CreateFeedScreenViewModel.Context
    
    @FocusState private var isTextEditorFocused: Bool  // Focus state
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                    name: context.viewState.userDisplayName,
                                    contentID: context.viewState.userID,
                                    avatarSize: .user(on: .home),
                                    mediaProvider: context.mediaProvider)
                .accessibilityIdentifier(A11yIdentifiers.homeScreen.userAvatar)
                
                ZStack(alignment: .topLeading) {
                    if context.feedText.isEmpty {
                        Text("What's happening?")
                            .font(.zero.bodyLG)
                            .foregroundStyle(.compound.textSecondary)
                            .frame(alignment: .topLeading)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    
                    TextEditor(text: $context.feedText)
                        .background(.clear)
                        .font(.zero.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                        .focused($isTextEditorFocused)
                        .frame(alignment: .topLeading)
                    // .lineSpacing(6)
                }
            }
            .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Small delay for smooth focus
                isTextEditorFocused = true  // Automatically focus when view appears
            }
        }
    }
}
