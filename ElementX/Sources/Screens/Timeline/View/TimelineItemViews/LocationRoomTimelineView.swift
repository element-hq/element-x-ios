//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct LocationRoomTimelineView: View {
    @Environment(\.timelineContext) private var context: TimelineViewModel.Context!
    let timelineItem: LocationRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            mainContent
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel)
                .onTapGesture {
                    guard context.viewState.mapTilerConfiguration.isEnabled else { return }
                    context.send(viewAction: .mediaTapped(itemID: timelineItem.id))
                }
        }
    }
                                    
    @ViewBuilder
    private var mainContent: some View {
        if let geoURI = timelineItem.content.geoURI {
            VStack(alignment: .leading, spacing: 0) {
                descriptionView
                    .frame(maxWidth: mapAspectRatio * mapMaxHeight, alignment: .leading)
                
                MapLibreStaticMapView(geoURI: geoURI,
                                      mapURLBuilder: context.viewState.mapTilerConfiguration,
                                      mapSize: .init(width: mapAspectRatio * mapMaxHeight, height: mapMaxHeight)) {
                    LocationMarkerView()
                }
                .frame(maxHeight: mapMaxHeight)
                .aspectRatio(mapAspectRatio, contentMode: .fit)
                .clipped()
            }
        } else {
            FormattedBodyText(text: timelineItem.body, additionalWhitespacesCount: timelineItem.additionalWhitespaces())
        }
    }

    // MARK: - Private
    
    private var accessibilityLabel: String {
        if let description = timelineItem.content.description {
            return "\(L10n.commonSharedLocation), \(description)"
        }
        
        return L10n.commonSharedLocation
    }

    @ViewBuilder
    private var descriptionView: some View {
        if let description = timelineItem.content.description, !description.isEmpty {
            FormattedBodyText(text: description)
                .padding(8)
        }
    }

    private let mapAspectRatio: Double = 3 / 2
    private let mapMaxHeight: Double = 300
}

private extension MapLibreStaticMapView {
    init(geoURI: GeoURI, mapURLBuilder: MapTilerURLBuilderProtocol, mapSize: CGSize, @ViewBuilder pinAnnotationView: () -> PinAnnotation) {
        self.init(coordinates: .init(latitude: geoURI.latitude, longitude: geoURI.longitude),
                  zoomLevel: 15,
                  attributionPlacement: .bottomLeft,
                  mapURLBuilder: mapURLBuilder,
                  mapSize: mapSize,
                  pinAnnotationView: pinAnnotationView)
    }
}

struct LocationRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock

    static var previews: some View {
        ScrollView {
            VStack(spacing: 8) {
                states
            }
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
        .previewDisplayName("Bubbles")
    }

    @ViewBuilder
    static var states: some View {
        LocationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                     timestamp: .mock,
                                                     isOutgoing: false,
                                                     isEditable: false,
                                                     canBeRepliedTo: true,
                                                     sender: .init(id: "Bob"),
                                                     content: .init(body: "Fallback geo uri description")))

        LocationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                     timestamp: .mock,
                                                     isOutgoing: false,
                                                     isEditable: false,
                                                     canBeRepliedTo: true,
                                                     sender: .init(id: "Bob"),
                                                     content: .init(body: "Fallback geo uri description",
                                                                    geoURI: .init(latitude: 41.902782, longitude: 12.496366), description: "Location description description description description description description description description")))
        LocationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                     timestamp: .mock,
                                                     isOutgoing: false,
                                                     isEditable: false,
                                                     canBeRepliedTo: true,
                                                     sender: .init(id: "Bob"),
                                                     content: .init(body: "Fallback geo uri description",
                                                                    geoURI: .init(latitude: 41.902782, longitude: 12.496366), description: "Location description description description description description description description description"),
                                                     properties: .init(replyDetails: .loaded(sender: .init(id: "Someone"),
                                                                                             eventID: "123",
                                                                                             eventContent: .message(.text(.init(body: "The thread content goes 'ere.")))),
                                                                       isThreaded: true)))
    }
}
