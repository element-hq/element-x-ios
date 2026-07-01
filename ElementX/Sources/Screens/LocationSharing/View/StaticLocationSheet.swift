//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct StaticLocationSheet: View {
    @Bindable var context: LocationSharingScreenViewModel.Context
    @State private var height = CGFloat.zero
    
    /// Fixes an iOS 26 sheet issue
    /// if the content doesn't meet a certain size
    /// additional insets are added.
    private let additionalHeight: CGFloat = 14
    
    var body: some View {
        mainContent
            .readHeight($height)
            .interactiveDismissDisabled()
            .presentationBackground(.compound.bgCanvasDefault)
            .presentationBackgroundInteraction(.enabled)
            .presentationDragIndicator(.hidden)
            .presentationDetents([.height(height + additionalHeight)])
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            Text(L10n.screenStaticLocationSheetTitle)
                .foregroundStyle(.compound.textPrimary)
                .font(.compound.bodyLGSemibold)
                .padding(.bottom, 25)
                .padding(.top, 29)
            if case let .viewStatic(location) = context.viewState.interactionMode,
               let profile = context.viewState.userProfiles.values.first {
                Button {
                    context.send(viewAction: .setMapCenter(.init(latitude: location.geoURI.latitude,
                                                                 longitude: location.geoURI.longitude)))
                } label: {
                    UserLocationCell(profile: profile,
                                     isOwnUser: context.viewState.isOwnUser(profile.id),
                                     kind: .static(isUserLocation: location.kind == .sender,
                                                   timestamp: location.timestamp),
                                     mediaProvider: context.mediaProvider,
                                     onShare: {
                                         context.sharedAnnotation = context.viewState.annotations.first
                                     },
                                     onStop: nil)
                }
            }
        }
        .popover(item: $context.sharedAnnotation) { annotation in
            LocationShareSheet(annotation: annotation)
        }
    }
}

struct StaticLocationSheet_Previews: PreviewProvider, TestablePreview {
    static let viewModel = LocationSharingScreenViewModel.mock(type: .staticSenderLocation, senderID: RoomMemberProxyMock.mockMe.userID)
    
    static let pinViewModel = LocationSharingScreenViewModel.mock(type: .staticPinLocation)
    
    static var previews: some View {
        StaticLocationSheet(context: viewModel.context)
            .previewDisplayName("Static own location")
        StaticLocationSheet(context: pinViewModel.context)
            .previewDisplayName("Static pin location")
    }
}
