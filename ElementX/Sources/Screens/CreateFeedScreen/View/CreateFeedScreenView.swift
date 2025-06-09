//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import Kingfisher

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
        ToolbarItem(placement: .primaryAction) {
            Button {
                context.send(viewAction: .attachMedia)
            } label: {
                CompoundIcon(\.attachment)
            }
        }
        ToolbarItem(placement: .cancellationAction) {
            Button {
                context.send(viewAction: .dismissPost)
            } label : {
                CompoundIcon(\.close)
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
                                    name: nil,
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
            
            Spacer()
            
            if let mediaUrl = context.selectedFeedMediaUrl {
                ZStack(alignment: .topTrailing) {
                    KFImage(mediaUrl)
                        .placeholder {
                            CompoundIcon(\.playSolid)
                        }
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .background(.black)
                        .cornerRadius(6, corners: .allCorners)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                    Button {
                        context.send(viewAction: .deleteMedia)
                    } label: {
                        CompoundIcon(\.close)
                            .padding(2)
                            .background(.Grey22)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Small delay for smooth focus
                isTextEditorFocused = true  // Automatically focus when view appears
            }
        }
    }
}
