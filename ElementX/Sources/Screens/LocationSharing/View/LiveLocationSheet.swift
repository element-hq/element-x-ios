//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LiveLocationSheet: View {
    @Bindable var context: LocationSharingScreenViewModel.Context
    @State private var currentDetent: PresentationDetent = supportedDetents[1]
    
    private static let supportedDetents: [PresentationDetent] = [.fraction(0.13), .fraction(0.3)]
    
    private var isCurrentDetentSmall: Bool {
        currentDetent == Self.supportedDetents[0]
    }
    
    var body: some View {
        mainContent
            .interactiveDismissDisabled()
            .presentationBackground(.compound.bgCanvasDefault)
            .presentationBackgroundInteraction(.enabled)
            .presentationDragIndicator(context.viewState.liveLocationShares.isEmpty ? .hidden : .visible)
            .presentationDetents(context.viewState.liveLocationShares.isEmpty ? .init([Self.supportedDetents[0]]) : .init(Self.supportedDetents),
                                 selection: $currentDetent)
            .animation(.elementDefault, value: currentDetent)
            .animation(.elementDefault, value: context.viewState.liveLocationShares.isEmpty)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            title
            if isCurrentDetentSmall {
                subtitle
            } else {
                locationSharesList
            }
        }
        .popover(item: $context.sharedAnnotation) { annotation in
            LocationShareSheet(annotation: annotation)
        }
    }
    
    private var title: some View {
        Text(context.viewState.liveLocationShares.isEmpty ? L10n.screenLiveLocationSheetNobodySharing : L10n.screenLiveLocationSheetTitle)
            .foregroundStyle(.compound.textPrimary)
            .font(.compound.bodyLGSemibold)
            .padding(.bottom, isCurrentDetentSmall ? 0 : 25)
            .padding(.top, isCurrentDetentSmall ? 0 : 29)
    }
    
    private var subtitle: some View {
        Text(L10n.screenLiveLocationSheetSubtitle(context.viewState.liveLocationShares.count))
            .font(.compound.bodySM)
            .foregroundStyle(.compound.textSecondary)
            .opacity(context.viewState.liveLocationShares.isEmpty ? 0 : 1)
            .allowsHitTesting(!context.viewState.liveLocationShares.isEmpty)
    }
    
    private var locationSharesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(context.viewState.liveLocationShares) { liveLocationShare in
                    if let profile = context.viewState.userProfiles[liveLocationShare.userID] {
                        Button {
                            guard let geoURI = liveLocationShare.geoURI else { return }
                            context.send(viewAction: .setMapCenter(.init(latitude: geoURI.latitude, longitude: geoURI.longitude)))
                        } label: {
                            UserLocationCell(profile: profile,
                                             isOwnUser: context.viewState.isOwnUser(liveLocationShare.userID),
                                             kind: .live,
                                             mediaProvider: context.mediaProvider,
                                             onShare: {
                                                 context.sharedAnnotation = context.viewState.annotations.first { $0.id == liveLocationShare.id }
                                             },
                                             onStop: { context.send(viewAction: .stopLiveLocation) })
                        }
                    }
                }
            }
        }
    }
}

struct LiveLocationSheet_Previews: PreviewProvider, TestablePreview {
    static let viewModel = LocationSharingScreenViewModel.mock(type: .viewLive, senderID: RoomMemberProxyMock.mockMe.userID)
    static let emptyViewModel = LocationSharingScreenViewModel.mock(type: .viewLiveEmpty, senderID: RoomMemberProxyMock.mockMe.userID)
    
    static var previews: some View {
        LiveLocationSheet(context: viewModel.context)
            .previewDisplayName("Live location")
        LiveLocationSheet(context: emptyViewModel.context)
            .previewDisplayName("Live locations are empty")
    }
}
