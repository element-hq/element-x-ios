//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LocationPickerSheet: View {
    @Bindable var context: LocationSharingScreenViewModel.Context
    @State private var height: CGFloat = .zero
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                context.send(viewAction: .selectLocation)
            } label: {
                if context.viewState.isSharingUserLocation {
                    LocationPickerLabel(text: L10n.screenShareMyLocationAction,
                                        icon: \.locationNavigatorCentred,
                                        iconColor: .compound.iconSecondary)
                } else {
                    LocationPickerLabel(text: L10n.screenShareThisLocationAction,
                                        icon: \.locationNavigator,
                                        iconColor: .compound.iconSecondary)
                }
            }
            if context.viewState.showLiveLocationSharingButton {
                Button { } label: {
                    LocationPickerLabel(text: L10n.actionShareLiveLocation,
                                        icon: \.locationPinSolid,
                                        iconColor: .compound.iconAccentPrimary)
                }
            }
        }
        .font(.compound.bodyLG)
        .foregroundStyle(.compound.textPrimary)
        .padding(.top, 38)
        .readHeight($height)
        .interactiveDismissDisabled()
        .presentationBackground(.compound.bgCanvasDefault)
        .presentationBackgroundInteraction(.enabled)
        .presentationDragIndicator(.hidden)
        .presentationDetents([.height(height)])
    }
}

private struct LocationPickerLabel: View {
    let text: String
    let icon: KeyPath<CompoundIcons, Image>
    let iconColor: Color
    
    var body: some View {
        Label {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .rowDivider(alignment: .top)
                .padding(.trailing, 16)
        } icon: {
            CompoundIcon(icon)
                .foregroundStyle(iconColor)
        }
        .padding(.leading, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LocationPickerSheet_Previews: PreviewProvider, TestablePreview {
    static let viewModel = LocationSharingScreenViewModel.mock(type: .picker)
    
    static var previews: some View {
        LocationPickerSheet(context: viewModel.context)
    }
}
