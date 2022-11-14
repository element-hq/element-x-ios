//
// Copyright 2022 New Vector Ltd
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

/// A type that describes an alert to be shown to the user.
///
/// The alert info can be added to the view state bindings and used as an alert's `item`:
/// ```
/// MyView
///     .alert(item: $viewModel.alertInfo) { $0.alert }
/// ```
struct AlertInfo<T: Hashable>: Identifiable {
    /// An identifier that can be used to distinguish one error from another.
    let id: T
    /// The alert's title.
    let title: String
    /// The alert's message (optional).
    var message: String?
    /// The alert's primary button title and action. Defaults to an Ok button with no action.
    var primaryButton = AlertButton(title: ElementL10n.ok, action: nil)
    /// The alert's secondary button title and action.
    var secondaryButton: AlertButton?
}

struct AlertButton {
    let title: String
    let action: (() -> Void)?
}

extension AlertInfo {
    /// Initialises the type with the title from an `Error`'s localised description along with the default Ok button.
    ///
    /// Currently this initialiser creates an alert for every error, however in the future it may be updated to filter
    /// out some specific errors such as cancellation and networking issues that create too much noise or are
    /// indicated to the user using other mechanisms.
    init(error: Error) where T == String {
        self.init(id: error.localizedDescription,
                  title: error.localizedDescription)
    }
    
    /// Initialises the type with a generic title and message for an unknown error along with the default Ok button.
    /// - Parameters:
    ///   - id: An ID that identifies the error.
    ///   - error: The Error that occurred.
    init(id: T) {
        self.id = id
        title = ElementL10n.dialogTitleError
        message = ElementL10n.unknownError
    }
}

extension AlertInfo {
    private var messageText: Text? {
        guard let message else { return nil }
        return Text(message)
    }
    
    /// Returns a SwiftUI `Alert` created from this alert info, using default button
    /// styles for both primary and (if set) secondary buttons.
    var alert: Alert {
        if let secondaryButton {
            return Alert(title: Text(title),
                         message: messageText,
                         primaryButton: alertButton(for: primaryButton),
                         secondaryButton: alertButton(for: secondaryButton))
        } else {
            return Alert(title: Text(title),
                         message: messageText,
                         dismissButton: alertButton(for: primaryButton))
        }
    }
    
    private func alertButton(for buttonParameters: AlertButton) -> Alert.Button {
        guard let action = buttonParameters.action else {
            return .default(Text(buttonParameters.title))
        }
        
        return .default(Text(buttonParameters.title), action: action)
    }
}
