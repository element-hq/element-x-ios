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
                StorageUsageChart(activeCaches: context.viewState.activeCaches,
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
        if !context.viewState.listedRooms.isEmpty || context.viewState.isLoadingRooms || context.viewState.isSearching {
            Section {
                // The filter sits above the rooms (a navigation-bar search field hung the app on
                // the first keystroke in this Form).
                ListRow(label: .plain(title: UntranslatedL10n.screenManageStorageSearchPrompt),
                        kind: .textField(text: $context.searchQuery, axis: .horizontal))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                ForEach(context.viewState.listedRooms) { room in
                    ListRow(kind: .custom {
                        StorageUsageRoomRow(room: room,
                                            largestBytes: context.viewState.largestListedRoomBytes,
                                            isSelected: context.viewState.selectedRoomIDs.contains(room.id)) {
                            context.send(viewAction: .toggleRoom(room.id))
                        }
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
                if !context.viewState.isSearching {
                    Text(UntranslatedL10n.screenManageStorageRoomsSectionFooter)
                        .compoundListSectionFooter()
                }
            }
        }
    }
}

/// A horizontal bar chart of the caches' sizes, one colour-coded bar per cache with its size in
/// MB and a clear button; the bars are proportional to the largest one (no scale).
/// A room in the list: its name and total, with its total drawn as a stacked bar (one segment per
/// cache) whose width is relative to the largest listed room's total, previewing the chart above.
struct StorageUsageRoomRow: View {
    let room: StorageUsageRoom
    let largestBytes: UInt64
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(room.displayName)
                            .font(.compound.bodyLG)
                            .foregroundStyle(.compound.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text(room.totalBytes.formatted(.byteCount(style: .file)))
                            .font(.compound.bodySM)
                            .foregroundStyle(.compound.textSecondary)
                            .monospacedDigit()
                    }

                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            ForEach(StorageCacheKind.allCases.filter(\.isPerRoom)) { cache in
                                cache.color
                                    .frame(width: segmentWidth(for: cache, in: geometry.size.width))
                            }
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 6)
                }

                ListRowAccessory.multiSelection(isSelected)
            }
            .padding(.horizontal, ListRowPadding.horizontal)
            .padding(.vertical, ListRowPadding.vertical)
        }
        .accessibilityAddTraits(.isToggle)
    }

    private func segmentWidth(for cache: StorageCacheKind, in width: CGFloat) -> CGFloat {
        guard largestBytes > 0 else { return 0 }
        return width * CGFloat(room.bytes[cache] ?? 0) / CGFloat(largestBytes)
    }
}

struct StorageUsageChart: View {
    /// The caches that can be cleared in the current scope; the others are greyed out.
    let activeCaches: [StorageCacheKind]
    let bytes: (StorageCacheKind) -> UInt64
    let isLoading: Bool
    let clearAction: (StorageCacheKind) -> Void

    private var caches: [StorageCacheKind] { StorageCacheKind.allCases }
    /// Below this a cache is labelled "0.0 MB": its bar stays empty rather than being scaled up
    /// (to a full bar when it happens to be the largest left, e.g. after clearing a room).
    private static let minimumDrawnBytes: UInt64 = 50_000
    private var maxBytes: UInt64 { caches.map(bytes).filter { $0 >= Self.minimumDrawnBytes }.max() ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(caches) { cache in
                bar(for: cache)
                    .opacity(activeCaches.contains(cache) ? 1 : 0.4)
            }
        }
        .animation(.elementDefault, value: activeCaches)
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
                            .opacity(activeCaches.contains(cache) ? 1 : 0)
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
            .disabled(isLoading || bytes(cache) == 0 || !activeCaches.contains(cache))
            .accessibilityLabel(UntranslatedL10n.screenManageStorageA11yClear(cache.title))
        }
    }

    private func barWidth(for cache: StorageCacheKind, in width: CGFloat) -> CGFloat {
        guard maxBytes > 0, bytes(cache) >= Self.minimumDrawnBytes else { return 0 }
        let fraction = CGFloat(bytes(cache)) / CGFloat(maxBytes)
        // A cache that's labelled non-empty always shows a sliver.
        return max(6, width * fraction)
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
        clientProxy.storageUsageByRoomReturnValue = .success(rooms)
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
                             bytes: [.messageKeys: 100_000, .roomState: 200_000, .messages: 400_000, .media: 0])
        ]
    }
}

