//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

struct LocationRoomTimelineView: View {
    let timelineItem: LocationRoomTimelineItem
    @Environment(\.timelineStyle) var timelineStyle
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            if let geoURI = timelineItem.content.geoURI {
                VStack(alignment: .leading, spacing: 0) {
                    descriptionView
                        .frame(maxWidth: mapAspectRatio * mapMaxHeight, alignment: .leading)

                    MapLibreStaticMapView(geoURI: geoURI) {
                        LocationMarkerView()
                    }
                    .frame(maxHeight: mapMaxHeight)
                    .aspectRatio(mapAspectRatio, contentMode: .fit)
                }
                .background(backgroundView)
            } else {
                FormattedBodyText(text: timelineItem.body)
            }
        }
    }

    // MARK: - Private

    @ViewBuilder
    private var descriptionView: some View {
        if let description = timelineItem.content.description, !description.isEmpty {
            FormattedBodyText(text: description)
                .padding(.vertical, 8)
                .padding(.horizontal, timelineStyle.isBubbles ? 8 : 0)
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch timelineStyle {
        case .bubbles:
            timelineItem.isOutgoing ? Color.compound._bgBubbleOutgoing : Color.compound._bgBubbleIncoming
        case .plain:
            EmptyView()
        }
    }

    private let mapAspectRatio: Double = 3 / 2
    private let mapMaxHeight: Double = 300
}

private extension MapLibreStaticMapView {
    init(geoURI: GeoURI, @ViewBuilder pinAnnotationView: () -> PinAnnotation) {
        self.init(coordinates: .init(latitude: geoURI.latitude, longitude: geoURI.longitude),
                  zoomLevel: 15,
                  attributionPlacement: .bottomLeft,
                  mapTilerStatic: MapTilerStaticMap(baseURL: ServiceLocator.shared.settings.mapTilerBaseURL,
                                                    key: ServiceLocator.shared.settings.mapTilerApiKey),
                  pinAnnotationView: pinAnnotationView)
    }
}

struct LocationRoomTimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock

    static var previews: some View {
        body
            .environmentObject(viewModel.context)

        body
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
    }

    @ViewBuilder
    static var body: some View {
        LocationRoomTimelineView(timelineItem: .init(id: .random,
                                                     timestamp: "Now",
                                                     isOutgoing: false,
                                                     isEditable: false,
                                                     sender: .init(id: "Bob"),
                                                     content: .init(body: "Fallback geo uri description")))

        LocationRoomTimelineView(timelineItem: .init(id: .random,
                                                     timestamp: "Now",
                                                     isOutgoing: false,
                                                     isEditable: false,
                                                     sender: .init(id: "Bob"),
                                                     content: .init(body: "Fallback geo uri description",
                                                                    geoURI: .init(latitude: 41.902782, longitude: 12.496366), description: "Location description description description description description description description description")))
    }
}
