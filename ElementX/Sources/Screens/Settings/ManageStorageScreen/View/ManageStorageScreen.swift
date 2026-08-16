//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ManageStorageScreen: View {
    @Bindable var context: ManageStorageScreenViewModel.Context

    var body: some View {
        Form {
            usageSection
            clearAllSection
            roomsSection
        }
        .compoundList()
        .navigationTitle(UntranslatedL10n.screenManageStorageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
        .alert(item: $context.clearRequest) { request in
            if request.cache == .logs {
                Button(UntranslatedL10n.screenManageStorageViewLogs) {
                    context.send(viewAction: .viewLogs)
                }
            }
            Button(L10n.actionClear, role: .destructive) {
                context.send(viewAction: .confirmClear)
            }
            Button(L10n.actionCancel, role: .cancel) { }
        } message: { request in
            Text(request.message)
        }
        .refreshable { context.send(viewAction: .reload) }
    }

    // MARK: - Usage

    private var usageSection: some View {
        Section {
            ListRow(kind: .custom {
                StorageUsageChart(caches: context.viewState.visibleCaches,
                                  bytes: { context.viewState.bytes(for: $0) },
                                  isLoading: context.viewState.isLoading) { cache in
                    context.send(viewAction: .requestClear(cache))
                }
                .padding(.horizontal, ListRowPadding.horizontal)
                .padding(.vertical, ListRowPadding.vertical)
            })
        } header: {
            Text(context.viewState.scopeTitle)
                .compoundListSectionHeader()
        }
    }

    private var clearAllSection: some View {
        Section {
            ListRow(label: .action(title: context.viewState.clearAllTitle, icon: \.delete, role: .destructive),
                    kind: .button { context.send(viewAction: .requestClear(nil)) })
                .disabled(context.viewState.isLoading)
        }
    }

    // MARK: - Rooms

    @ViewBuilder
    private var roomsSection: some View {
        if !context.viewState.listedRooms.isEmpty || context.viewState.isLoadingRooms {
            Section {
                ForEach(context.viewState.listedRooms) { room in
                    ListRow(label: .plain(title: room.displayName,
                                          description: room.totalBytes.formatted(.byteCount(style: .file))),
                            kind: .multiSelection(isSelected: context.viewState.selectedRoomIDs.contains(room.id)) {
                                context.send(viewAction: .toggleRoom(room.id))
                            })
                }
            } header: {
                HStack(spacing: 8) {
                    Text(UntranslatedL10n.screenManageStorageRoomsSectionTitle)
                    if context.viewState.isLoadingRooms {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
                .compoundListSectionHeader()
            } footer: {
                Text(UntranslatedL10n.screenManageStorageRoomsSectionFooter)
                    .compoundListSectionFooter()
            }
        }
    }
}

/// A horizontal bar chart of the caches' sizes, one colour-coded bar per cache with its size in
/// MB and a clear button; the bars are proportional to the largest one (no scale).
struct StorageUsageChart: View {
    let caches: [StorageCacheKind]
    let bytes: (StorageCacheKind) -> UInt64
    let isLoading: Bool
    let clearAction: (StorageCacheKind) -> Void

    private var maxBytes: UInt64 { caches.map(bytes).max() ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(caches) { cache in
                bar(for: cache)
            }
        }
        .animation(.elementDefault, value: caches)
        .opacity(isLoading ? 0.5 : 1)
    }

    private func bar(for cache: StorageCacheKind) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(cache.title)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textPrimary)
                    Spacer()
                    Text(Self.megabytes(bytes(cache)))
                        .font(.compound.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                        .monospacedDigit()
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.compound.bgSubtleSecondary)
                        Capsule()
                            .fill(cache.color)
                            .frame(width: barWidth(for: cache, in: geometry.size.width))
                    }
                }
                .frame(height: 10)
                .animation(.elementDefault, value: bytes(cache))
            }

            Button {
                clearAction(cache)
            } label: {
                CompoundIcon(\.delete, size: .small, relativeTo: .compound.bodyMD)
                    .foregroundStyle(.compound.iconCriticalPrimary)
            }
            .disabled(isLoading || bytes(cache) == 0)
            .accessibilityLabel(UntranslatedL10n.screenManageStorageA11yClear(cache.title))
        }
    }

    private func barWidth(for cache: StorageCacheKind, in width: CGFloat) -> CGFloat {
        guard maxBytes > 0 else { return 0 }
        let fraction = CGFloat(bytes(cache)) / CGFloat(maxBytes)
        // A non-empty cache always shows a sliver.
        return bytes(cache) == 0 ? 0 : max(6, width * fraction)
    }

    static func megabytes(_ bytes: UInt64) -> String {
        let megabytes = Double(bytes) / 1_000_000
        return "\(megabytes.formatted(.number.precision(.fractionLength(1)))) MB"
    }
}

// MARK: - Previews

struct ManageStorageScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let emptyViewModel = makeViewModel(rooms: [])

    static var previews: some View {
        NavigationStack {
            ManageStorageScreen(context: viewModel.context)
        }
        .previewDisplayName("Rooms")

        NavigationStack {
            ManageStorageScreen(context: emptyViewModel.context)
        }
        .previewDisplayName("Empty")
    }

    static func makeViewModel(rooms: [StorageUsageRoom] = .mock) -> ManageStorageScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.storeSizesReturnValue = .success(.mock)
        clientProxy.storageUsageByRoomReturnValue = AsyncStream { continuation in
            continuation.yield(rooms)
            continuation.finish()
        }
        return ManageStorageScreenViewModel(clientProxy: clientProxy,
                                            userIndicatorController: UserIndicatorControllerMock(),
                                            logsDirectory: URL(filePath: "/dev/null"))
    }
}

extension [StorageUsageRoom] {
    static var mock: [StorageUsageRoom] {
        [
            StorageUsageRoom(id: "!big:example.org", name: "Element X iOS", lastActivity: .now,
                             bytes: [.messageKeys: 12_000_000, .roomState: 30_000_000, .messages: 80_000_000, .media: 250_000_000]),
            StorageUsageRoom(id: "!medium:example.org", name: "Matrix HQ", lastActivity: .now.addingTimeInterval(-100 * 24 * 3600),
                             bytes: [.messageKeys: 5_000_000, .roomState: 60_000_000, .messages: 20_000_000, .media: 10_000_000]),
            StorageUsageRoom(id: "!small:example.org", name: nil, lastActivity: nil,
                             bytes: [.messageKeys: 100_000, .roomState: 500_000, .messages: 900_000, .media: 0])
        ]
    }
}

