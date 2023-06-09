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

struct StaticLocationScreen: View {
    @ObservedObject var context: StaticLocationScreenViewModel.Context
    
    var body: some View {
        mapView
            .ignoresSafeArea(.all, edges: [.bottom])
            .navigationBarTitleDisplayMode(.inline)
            .alert(item: $context.alertInfo) { $0.alert }
    }
    
    var mapView: MapLibreMapView {
        MapLibreMapView(lightTileServerMapURL: MapTilerStyleBuilder.shared.dynamicMapURL(for: .light),
                        darkTileServerMapURL: MapTilerStyleBuilder.shared.dynamicMapURL(for: .dark),
                        showsUserLocationMode: .follow,
                        error: $context.mapError)
    }
}

// MARK: - Previews

struct StaticLocationScreenViewer_Previews: PreviewProvider {
    static let viewModel = {
        let viewModel = StaticLocationScreenViewModel()
        return viewModel
    }()
    
    static var previews: some View {
        NavigationView {
            StaticLocationScreen(context: viewModel.context)
        }
    }
}
