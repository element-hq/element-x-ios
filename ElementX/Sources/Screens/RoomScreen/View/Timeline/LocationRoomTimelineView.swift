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
                MapLibreStaticMapView(geoURI: geoURI) {
                    LocationMarkerView()
                }
                .frame(maxHeight: 300)
                .aspectRatio(3 / 2, contentMode: .fit)
            } else {
                FormattedBodyText(text: timelineItem.body)
            }
        }
    }
}

private extension MapLibreStaticMapView {
    init(geoURI: GeoURI, @ViewBuilder pinAnnotationView: () -> PinAnnotation) {
        self.init(coordinates: .init(latitude: geoURI.latitude, longitude: geoURI.longitude),
                  zoomLevel: 15,
                  attributionPlacement: .bottomLeft,
                  mapTilerStatic: MapTilerStaticMap(key: ServiceLocator.shared.settings.mapTilerApiKey,
                                                    lightURL: ServiceLocator.shared.settings.lightTileMapStyleURL,
                                                    darkURL: ServiceLocator.shared.settings.darkTileMapStyleURL),
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
        LocationRoomTimelineView(timelineItem: .init(id: UUID().uuidString,
                                                     timestamp: "Now",
                                                     isOutgoing: false,
                                                     isEditable: false,
                                                     sender: .init(id: "Bob"),
                                                     content: .init(body: "Fallback geo uri description")))

        LocationRoomTimelineView(timelineItem: .init(id: UUID().uuidString,
                                                     timestamp: "Now",
                                                     isOutgoing: false,
                                                     isEditable: false,
                                                     sender: .init(id: "Bob"),
                                                     content: .init(body: "Fallback geo uri description",
                                                                    geoURI: .init(latitude: 41.902782, longitude: 12.496366))))
    }
}
