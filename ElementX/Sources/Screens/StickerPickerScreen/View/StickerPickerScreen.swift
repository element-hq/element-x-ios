//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct StickerPickerScreen: View {
    @ObservedObject var context: StickerPickerScreenViewModelType.Context

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.commonStickers)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.actionCancel) {
                            context.send(viewAction: .dismiss)
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if context.viewState.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = context.viewState.errorMessage {
            errorView(message: errorMessage)
        } else if context.viewState.packs.isEmpty {
            emptyStateView
        } else {
            stickerPickerView
        }
    }

    private var stickerPickerView: some View {
        VStack(spacing: 0) {
            // Pack selector tabs
            if context.viewState.packs.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(context.viewState.packs.enumerated()), id: \.element.id) { index, pack in
                            packTabButton(pack: pack, index: index)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color.compound.bgCanvasDefault)

                Divider()
            }

            // Sticker grid
            if let currentPack = context.viewState.currentPack {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 16)], spacing: 16) {
                        ForEach(currentPack.stickers) { sticker in
                            StickerView(sticker: sticker)
                                .onTapGesture {
                                    context.send(viewAction: .selectSticker(sticker))
                                }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private func packTabButton(pack: StickerPack, index: Int) -> some View {
        Button {
            context.send(viewAction: .selectPack(index: index))
        } label: {
            Text(pack.title)
                .font(.compound.bodyMD)
                .foregroundColor(index == context.viewState.selectedPackIndex ? .compound.textPrimary : .compound.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(index == context.viewState.selectedPackIndex ? Color.compound.bgSubtlePrimary : Color.clear)
                )
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "face.smiling")
                .font(.system(size: 48))
                .foregroundColor(.compound.iconTertiary)

            Text(L10n.screenStickerPickerEmptyStateTitle)
                .font(.compound.headingMD)
                .foregroundColor(.compound.textPrimary)

            Text(L10n.screenStickerPickerEmptyStateMessage)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.compound.iconCriticalPrimary)

            Text(message)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(L10n.actionRetry) {
                context.send(viewAction: .retryLoading)
            }
            .buttonStyle(.compound(.primary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sticker View

struct StickerView: View {
    let sticker: Sticker

    var body: some View {
        // For now, we'll use AsyncImage to load from MXC URLs
        // In production, you'd want to use the MediaSourceProxy/LoadableImage pattern
        AsyncImage(url: URL(string: sticker.url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: 80, height: 80)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: 32))
                    .foregroundColor(.compound.iconTertiary)
                    .frame(width: 80, height: 80)
            @unknown default:
                EmptyView()
            }
        }
    }
}

// MARK: - Previews

struct StickerPickerScreen_Previews: PreviewProvider {
    static var previews: some View {
        StickerPickerScreen(context: .init(
            viewState: StickerPickerScreenViewState(
                packs: [
                    StickerPack(
                        id: "emotes",
                        title: "Emotes",
                        stickers: [
                            Sticker(
                                id: "1",
                                body: "happy",
                                url: "mxc://example.com/image",
                                msgtype: "m.sticker",
                                info: StickerInfo(
                                    w: 256,
                                    h: 256,
                                    size: 12345,
                                    mimetype: "image/png",
                                    thumbnailUrl: nil,
                                    thumbnailInfo: nil
                                )
                            )
                        ]
                    )
                ],
                selectedPackIndex: 0,
                isLoading: false
            ),
            send: { _ in }
        ))
    }
}
