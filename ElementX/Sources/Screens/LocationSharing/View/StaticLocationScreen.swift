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
    
    private let builder = MapTilerStyleBuilder(appSettings: ServiceLocator.shared.settings)
    
    var body: some View {
        mapView
            .ignoresSafeArea(.all, edges: .horizontal)
            .navigationTitle(L10n.screenShareLocationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .alert(item: $context.alertInfo)
    }
    
    private var mapView: some View {
        ZStack(alignment: .center) {
            MapLibreMapView(builder: builder,
                            showsUserLocationMode: .hide,
                            error: $context.mapError,
                            mapCenterCoordinate: $context.mapCenterLocation,
                            userDidPan: {
                                context.send(viewAction: .userDidPan)
                            })
            if context.viewState.isPinDropSharing {
                LocationMarkerView()
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            closeButton
        }
        
        ToolbarItemGroup(placement: .bottomBar) {
            shareLocationButton
            Spacer()
        }
    }
    
    @ScaledMetric private var shareMarkerSize: CGFloat = 28
    private var shareLocationButton: some View {
        Button {
            context.send(viewAction: .selectLocation)
        } label: {
            HStack(spacing: 8) {
                Image(asset: Asset.Images.locationMarker)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: shareMarkerSize, height: shareMarkerSize)
                Text(context.viewState.isPinDropSharing ? L10n.screenShareThisLocationAction : L10n.screenShareMyLocationAction)
            }
        }
    }
    
    private var closeButton: some View {
        Button(L10n.actionCancel, action: close)
    }
    
    private func close() {
        context.send(viewAction: .close)
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
