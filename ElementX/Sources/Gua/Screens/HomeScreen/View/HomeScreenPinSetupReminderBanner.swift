//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Compound
import SwiftUI

/// Encourages the user to configure their two-step verification PIN. Shown above the
/// room list when the identity-service reports `hasPin == false` and the reminder has
/// not been snoozed. Tapping the primary button opens Settings so the user can finish
/// setup via Settings → Account → Two-step verification; the dismiss button snoozes the
/// reminder for a week.
struct HomeScreenPinSetupReminderBanner: View {
    var context: HomeScreenViewModel.Context

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text(L10n.screenTwoStepVerificationReminderTitle)
                        .font(.compound.bodyLGSemibold)
                        .foregroundColor(.compound.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        context.send(viewAction: .dismissPinReminder)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.compound.iconSecondary)
                            .frame(width: 12, height: 12)
                    }
                }

                Text(L10n.screenTwoStepVerificationReminderMessage)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
            }

            Button {
                context.send(viewAction: .setUpPinReminder)
            } label: {
                Text(L10n.screenTwoStepVerificationReminderAction)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.compound(.primary, size: .medium))
        }
        .padding(16)
        .background(Color.compound.bgSubtleSecondary)
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
}
