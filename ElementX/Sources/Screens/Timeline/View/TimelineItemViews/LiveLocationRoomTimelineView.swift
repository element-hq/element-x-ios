//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct LiveLocationRoomTimelineView: View {
    @Environment(\.timelineContext) private var context: TimelineViewModel.Context!
    @State private var hasExpired: Bool
    let timelineItem: LiveLocationRoomTimelineItem
    private let currentDate: Date
    
    init(currentDate: Date = .now, timelineItem: LiveLocationRoomTimelineItem) {
        self.currentDate = currentDate
        self.timelineItem = timelineItem
        _hasExpired = State(initialValue: currentDate >= timelineItem.content.timeoutDate)
    }
    
    /// A publisher that fires once when the timeoutDate is reached, setting `hasExpired` to true.
    private var timeoutPublisher: AnyPublisher<Void, Never> {
        guard timelineItem.content.isLive else {
            return Empty().eraseToAnyPublisher()
        }
        
        let delay = timelineItem.content.timeoutDate.timeIntervalSinceNow
        guard delay > 0 else {
            return Empty().eraseToAnyPublisher()
        }
        
        return Just(())
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private var isLive: Bool {
        timelineItem.content.isLive && !hasExpired
    }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            mainContent
        }
    }
    
    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            mapView
                .clipped()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.commonSharedLiveLocation)
            
            liveLocationInfoView
        }
        .frame(maxHeight: mapMaxHeight)
        .aspectRatio(mapAspectRatio, contentMode: .fit)
        .overlay {
            if !isLive {
                RoundedRectangle(cornerRadius: 12)
                    .inset(by: 0.5)
                    .stroke(Color.compound.borderDisabled)
            }
        }
        .onTapGesture {
            guard context.viewState.mapTilerConfiguration.isEnabled,
                  timelineItem.content.lastGeoURI != nil,
                  isLive else {
                return
            }
            context.send(viewAction: .mediaTapped(itemID: timelineItem.id))
        }
    }
    
    @ViewBuilder
    private var mapView: some View {
        if isLive {
            liveContent
                .onReceive(timeoutPublisher) { _ in
                    hasExpired = true
                }
        } else {
            ZStack {
                Image(asset: Asset.Images.placeholderMap)
                    .resizable()
                LocationMarkerView(kind: .placeholder)
            }
        }
    }
    
    @ViewBuilder
    private var liveContent: some View {
        if let geoURI = timelineItem.content.lastGeoURI {
            MapLibreStaticMapView(geoURI: geoURI,
                                  mapURLBuilder: context.viewState.mapTilerConfiguration,
                                  attributionPlacement: .topLeft,
                                  mapSize: .init(width: mapAspectRatio * mapMaxHeight, height: mapMaxHeight)) {
                LocationMarkerView(kind: .liveUser(.init(sender: timelineItem.sender)),
                                   mediaProvider: context.mediaProvider)
            }
        } else {
            Image(asset: Asset.Images.mapBlurred)
                .resizable()
        }
    }
    
    private var liveLocationStateString: String {
        isLive ? L10n.commonLiveLocation : L10n.commonLiveLocationEnded
    }
    
    private var liveLocationStateColor: Color {
        isLive ? .compound.textPrimary : .compound.textSecondary
    }
    
    private var liveLocationIconColor: Color {
        if isLive {
            timelineItem.content.lastGeoURI != nil ? .compound.iconAccentPrimary : .compound.iconSecondary
        } else {
            .compound.iconDisabled
        }
    }
    
    private var liveLocationBackgroundColor: Color {
        isLive ? .compound.bgCanvasDefault : .compound.bgSubtleSecondary
    }
    
    private var blurBackground: some View {
        Color.compound.bgCanvasDefault
            .opacity(0.8)
            .background(.ultraThinMaterial)
    }
    
    private var infoIcon: KeyPath<CompoundIcons, Image> {
        if timelineItem.content.lastGeoURI != nil || !isLive {
            \.locationPinSolid
        } else {
            \.spinner
        }
    }
    
    private var liveLocationInfoView: some View {
        HStack(spacing: 8) {
            CompoundIcon(infoIcon, size: .medium, relativeTo: .compound.bodySMSemibold)
                .foregroundStyle(liveLocationIconColor)
                .padding(4)
                .background(liveLocationBackgroundColor)
                .cornerRadius(8)
                .overlay {
                    if isLive {
                        RoundedRectangle(cornerRadius: 8)
                            .inset(by: 0.5)
                            .stroke(Color.compound.iconQuaternaryAlpha)
                    }
                }
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(liveLocationStateString)
                    .foregroundStyle(liveLocationStateColor)
                    .font(.compound.bodySMSemibold)
                
                if isLive {
                    Text(L10n.commonEndsAt(timelineItem.content.timeoutDate.formattedExpiration()))
                        .foregroundStyle(.compound.textPrimary)
                        .font(.compound.bodySM)
                }
            }
            .accessibilityElement(children: .combine)
            
            Spacer()
            
            if isLive, timelineItem.isOutgoing {
                Button {
                    context?.send(viewAction: .stopLiveLocationSharing)
                } label: {
                    CompoundIcon(\.stop, size: .small, relativeTo: .compound.bodySMSemibold)
                        .foregroundStyle(.compound.iconOnSolidPrimary)
                        .padding(5)
                        .background(Color.compound.bgCriticalPrimary, in: Circle())
                        .accessibilityLabel(L10n.actionStop)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(blurBackground)
    }
    
    // MARK: - Private
    
    private let mapAspectRatio: Double = 3 / 2
    private let mapMaxHeight: Double = 300
}

private extension Date {
    /// A fixed date representing today at 4:10 AM, used for mocks and previews.
    static var mockToday410: Date {
        // swiftlint:disable:next force_unwrapping
        Calendar.current.date(bySettingHour: 4, minute: 10, second: 0, of: .now)!
    }
    
    /// A fixed date representing today at 4:20 AM, used for mocks and previews.
    static var mockToday420: Date {
        // swiftlint:disable:next force_unwrapping
        Calendar.current.date(bySettingHour: 4, minute: 20, second: 0, of: .now)!
    }
    
    /// A fixed date representing today at 4:30 AM, used for mocks and previews.
    static var mockToday430: Date {
        // swiftlint:disable:next force_unwrapping
        Calendar.current.date(bySettingHour: 4, minute: 30, second: 0, of: .now)!
    }
}

struct LiveLocationRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        PreviewScrollView {
            VStack(spacing: 8) {
                states
            }
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Bubbles")
    }
    
    @ViewBuilder
    static var states: some View {
        // No location yet (beacon not yet received)
        LiveLocationRoomTimelineView(currentDate: .mockToday410,
                                     timelineItem: .init(id: .randomEvent,
                                                         timestamp: .mock,
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         sender: .init(id: "@bob:matrix.org", displayName: "Bob"),
                                                         content: .init(isLive: true,
                                                                        timeoutDate: .mockToday420,
                                                                        lastGeoURI: nil)))
        
        // With a known location
        LiveLocationRoomTimelineView(currentDate: .mockToday410,
                                     timelineItem: .init(id: .randomEvent,
                                                         timestamp: .mock,
                                                         isOutgoing: true,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         sender: .init(id: "@bob:matrix.org", displayName: "Bob", avatarURL: .mockMXCUserAvatar),
                                                         content: .init(isLive: true,
                                                                        timeoutDate: .mockToday420,
                                                                        lastGeoURI: .init(latitude: 41.902782, longitude: 12.496366))))
        // Stopped live location
        LiveLocationRoomTimelineView(currentDate: .mockToday410,
                                     timelineItem: .init(id: .randomEvent,
                                                         timestamp: .mock,
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         sender: .init(id: "@bob:matrix.org", displayName: "Bob", avatarURL: .mockMXCUserAvatar),
                                                         content: .init(isLive: false,
                                                                        timeoutDate: .mockToday420,
                                                                        lastGeoURI: .init(latitude: 41.902782, longitude: 12.496366))))
        
        // Expired live location
        LiveLocationRoomTimelineView(currentDate: .mockToday430,
                                     timelineItem: .init(id: .randomEvent,
                                                         timestamp: .mock,
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         sender: .init(id: "@bob:matrix.org", displayName: "Bob", avatarURL: .mockMXCUserAvatar),
                                                         content: .init(isLive: true,
                                                                        timeoutDate: .mockToday420,
                                                                        lastGeoURI: .init(latitude: 41.902782, longitude: 12.496366))))
        
        // Replying to a live location
        LiveLocationRoomTimelineView(currentDate: .mockToday410,
                                     timelineItem: .init(id: .randomEvent,
                                                         timestamp: .mock,
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         sender: .init(id: "@bob:matrix.org", displayName: "Bob", avatarURL: .mockMXCUserAvatar),
                                                         content: .init(isLive: true,
                                                                        timeoutDate: .mockToday420,
                                                                        lastGeoURI: .init(latitude: 41.902782, longitude: 12.496366)),
                                                         properties: .init(replyDetails: .loaded(sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                                                                 eventID: "123",
                                                                                                 eventContent: .liveLocation))))
        
        // Replying to a live location when the content is not live
        LiveLocationRoomTimelineView(currentDate: .mockToday410,
                                     timelineItem: .init(id: .randomEvent,
                                                         timestamp: .mock,
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         sender: .init(id: "@bob:matrix.org", displayName: "Bob", avatarURL: .mockMXCUserAvatar),
                                                         content: .init(isLive: false,
                                                                        timeoutDate: .mockToday420,
                                                                        lastGeoURI: .init(latitude: 41.902782, longitude: 12.496366)),
                                                         properties: .init(replyDetails: .loaded(sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                                                                 eventID: "123",
                                                                                                 eventContent: .liveLocation))))
    }
}
