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
    
    /// Fixes an iOS 26 sheet issue
    /// if the content doesn't meet a certain size
    /// additional insets are added.
    private var additionalHeight: CGFloat {
        context.viewState.showLiveLocationSharingButton ? 0 : 28
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(L10n.screenSharingLocationOptionSheetTitle)
                .foregroundStyle(.compound.textPrimary)
                .font(.compound.bodyLGSemibold)
                .padding(.top, 29)
                .padding(.bottom, 25)
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
        .readHeight($height)
        .interactiveDismissDisabled()
        .presentationBackground(.compound.bgCanvasDefault)
        .presentationBackgroundInteraction(.enabled)
        .presentationDragIndicator(.hidden)
        .presentationDetents([.height(height + additionalHeight)])
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
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textPrimary)
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
