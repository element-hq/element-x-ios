//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LiveLocationRoomTimelineView: View {
    @Environment(\.timelineContext) private var context: TimelineViewModel.Context!
    let timelineItem: LiveLocationRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            mainContent
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if let geoURI = timelineItem.content.lastLocation?.geoURI {
            ZStack(alignment: .bottom) {
                mapView(geoURI: geoURI)
                    .clipped()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(L10n.commonSharedLiveLocation)
                
                liveLocationInfoView
            }
            .frame(maxHeight: mapMaxHeight)
            .aspectRatio(mapAspectRatio, contentMode: .fit)
            .overlay {
                if !timelineItem.content.isLive {
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(Color.compound.borderDisabled)
                }
            }
            .onTapGesture {
                guard context.viewState.mapTilerConfiguration.isEnabled,
                      timelineItem.content.isLive else {
                    return
                }
                context.send(viewAction: .mediaTapped(itemID: timelineItem.id))
            }
        } else {
            // The live location is loading
            Label(L10n.commonWaitingLiveLocation,
                  icon: \.time,
                  iconSize: .small,
                  relativeTo: .compound.bodyLG)
                .labelStyle(RoomTimelineViewPlaceholderLabelStyle())
                .font(.compound.bodyLG)
        }
    }
    
    @ViewBuilder
    private func mapView(geoURI: GeoURI) -> some View {
        if timelineItem.content.isLive {
            MapLibreStaticMapView(geoURI: geoURI,
                                  mapURLBuilder: context.viewState.mapTilerConfiguration,
                                  attributionPlacement: .topLeft,
                                  mapSize: .init(width: mapAspectRatio * mapMaxHeight, height: mapMaxHeight)) {
                LocationMarkerView(kind: .liveUser(.init(sender: timelineItem.sender)),
                                   mediaProvider: context.mediaProvider)
            }
        } else {
            ZStack {
                Image(asset: Asset.Images.placeholderMap)
                    .resizable()
                LocationMarkerView(kind: .placeholder)
            }
        }
    }
    
    private var liveLocationStateString: String {
        timelineItem.content.isLive ? L10n.commonLiveLocation : L10n.commonLiveLocationEnded
    }
    
    private var liveLocationStateColor: Color {
        timelineItem.content.isLive ? .compound.textPrimary : .compound.textSecondary
    }
    
    private var liveLocationIconColor: Color {
        timelineItem.content.isLive ? .compound.iconAccentPrimary : .compound.iconDisabled
    }
    
    private var liveLocationBackgroundColor: Color {
        timelineItem.content.isLive ? .compound.bgCanvasDefault : .compound.bgSubtleSecondary
    }
    
    private var blurBackground: some View {
        Color.compound.bgCanvasDefault
            .opacity(0.8)
            .background(.ultraThinMaterial)
    }
    
    private var liveLocationInfoView: some View {
        HStack(spacing: 8) {
            CompoundIcon(\.locationPinSolid, size: .medium, relativeTo: .compound.bodySMSemibold)
                .foregroundStyle(liveLocationIconColor)
                .padding(4)
                .background(liveLocationBackgroundColor)
                .cornerRadius(8)
                .overlay {
                    if timelineItem.content.isLive {
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
                
                if timelineItem.content.isLive {
                    Text(L10n.commonIosExpirationTime(timelineItem.content.timeoutDate.formatted(.relative(presentation: .numeric))))
                        .foregroundStyle(.compound.textPrimary)
                        .font(.compound.bodySM)
                }
            }
            .accessibilityElement(children: .combine)
            
            Spacer()
            
            if timelineItem.isOutgoing {
                Button { } label: {
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
        LiveLocationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                         timestamp: .mock,
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         sender: .init(id: "@bob:matrix.org", displayName: "Bob"),
                                                         content: .init(isLive: true,
                                                                        timeoutDate: .inOneMinute,
                                                                        lastLocation: nil)))
        
        // With a known location
        LiveLocationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                         timestamp: .mock,
                                                         isOutgoing: true,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         sender: .init(id: "@bob:matrix.org", displayName: "Bob", avatarURL: .mockMXCUserAvatar),
                                                         content: .init(isLive: true,
                                                                        timeoutDate: .inOneMinute,
                                                                        lastLocation: .init(timestamp: .mock,
                                                                                            geoURI: .init(latitude: 41.902782, longitude: 12.496366)))))
        // Expired live location
        LiveLocationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                         timestamp: .mock,
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         sender: .init(id: "@bob:matrix.org", displayName: "Bob", avatarURL: .mockMXCUserAvatar),
                                                         content: .init(isLive: false,
                                                                        timeoutDate: .inOneMinute,
                                                                        lastLocation: .init(timestamp: .mock,
                                                                                            geoURI: .init(latitude: 41.902782, longitude: 12.496366)))))
        
        // Replying to a live location
        LiveLocationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                         timestamp: .mock,
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         sender: .init(id: "@bob:matrix.org", displayName: "Bob", avatarURL: .mockMXCUserAvatar),
                                                         content: .init(isLive: true,
                                                                        timeoutDate: .inOneMinute,
                                                                        lastLocation: .init(timestamp: .mock,
                                                                                            geoURI: .init(latitude: 41.902782, longitude: 12.496366))),
                                                         properties: .init(replyDetails: .loaded(sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                                                                 eventID: "123",
                                                                                                 eventContent: .liveLocation))))
        
        // Replying to a live location when the content is not live
        LiveLocationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                         timestamp: .mock,
                                                         isOutgoing: false,
                                                         isEditable: false,
                                                         canBeRepliedTo: true,
                                                         sender: .init(id: "@bob:matrix.org", displayName: "Bob", avatarURL: .mockMXCUserAvatar),
                                                         content: .init(isLive: false,
                                                                        timeoutDate: .inOneMinute,
                                                                        lastLocation: .init(timestamp: .mock,
                                                                                            geoURI: .init(latitude: 41.902782, longitude: 12.496366))),
                                                         properties: .init(replyDetails: .loaded(sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                                                                                 eventID: "123",
                                                                                                 eventContent: .liveLocation))))
    }
}
