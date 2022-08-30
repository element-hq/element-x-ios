//
// Copyright 2021 New Vector Ltd
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

import Foundation

enum AnalyticsServiceError: Error {
    /// The session supplied to the service does not have a state of `MXSessionStateRunning`.
    case sessionIsNotRunning
    /// The service failed to get or update the analytics settings event from the user's account data.
    case accountDataFailure
}

/// A service responsible for handling the `im.vector.analytics` event from the user's account data.
class AnalyticsService {
    let session: UserSessionProtocol
    
    /// Creates an analytics service with the supplied session.
    /// - Parameter session: The session to use when reading analytics settings from account data.
    init(session: UserSessionProtocol) {
        self.session = session
    }
    
    /// The analytics settings for the current user. Calling this method will check whether the settings already
    /// contain an `id` property and if not, will add one to the account data before calling the completion.
    /// - Parameter completion: A completion handler that will be called when the request completes.
    ///
    /// The request will fail if the service's session does not have the `MXSessionStateRunning` state.
    func settings() async -> Result<AnalyticsSettings, AnalyticsServiceError> {
        // Only use the session if it is running otherwise we could wipe out an existing analytics ID.
        fatalError("Missing running state detection.")
//        guard session.state == .running else {
//            MXLog.warning("Aborting attempt to read analytics settings. The session may not be up-to-date.")
//            return .failure(.sessionIsNotRunning)
//        }
        
        let result: Result<AnalyticsSettings?, ClientProxyError> = await session.clientProxy.accountDataEvent(type: AnalyticsSettings.eventType)
        switch result {
        case .failure:
            return .failure(.accountDataFailure)
        case .success(let settings):
            // The id has already be set so we are done here.
            if let settings = settings, settings.id != nil {
                return .success(settings)
            }
            
            let newSettings = AnalyticsSettings.new(currentEvent: settings)
            switch await session.clientProxy.setAccountData(content: newSettings, type: AnalyticsSettings.eventType) {
            case .failure:
                MXLog.warning("Failed to update analytics settings.")
                return .failure(.accountDataFailure)
            case .success:
                MXLog.debug("Successfully updated analytics settings in account data.")
                return .success(newSettings)
            }
        }
    }
}
