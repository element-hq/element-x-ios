//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct TimelineDeliveryStatusView: View {
    enum Status {
        case sending
        case sent
    }

    let deliveryStatus: Status

    private var icon: CompoundIcon {
        switch deliveryStatus {
        case .sending:
            return CompoundIcon(\.circle, size: .xSmall, relativeTo: .compound.bodyMD)
        case .sent:
            return CompoundIcon(\.checkCircle, size: .xSmall, relativeTo: .compound.bodyMD)
        }
    }
    
    var body: some View {
        icon
            .foregroundColor(.compound.iconSecondary)
            .accessibilityLabel(accessibilityLabel)
    }
    
    private var accessibilityLabel: String {
        switch deliveryStatus {
        case .sending:
            return L10n.commonSending
        case .sent:
            return L10n.commonSent
        }
    }
}

struct TimelineDeliveryStatusView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 8) {
            TimelineDeliveryStatusView(deliveryStatus: .sending)
            TimelineDeliveryStatusView(deliveryStatus: .sent)
        }
    }
}
