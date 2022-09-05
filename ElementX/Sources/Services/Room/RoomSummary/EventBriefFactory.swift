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

import Foundation

struct EventBriefFactory: EventBriefFactoryProtocol {
    private let memberDetailProvider: MemberDetailProviderProtocol
    
    init(memberDetailProvider: MemberDetailProviderProtocol) {
        self.memberDetailProvider = memberDetailProvider
    }
    
    func buildEventBriefFor(message: RoomMessageProtocol?) async -> EventBrief? {
        guard let message = message else {
            return nil
        }
        
        #warning("Simplified whilst waiting for sliding sync.")
        return await buildEventBrief(message: message, htmlBody: nil)
    }
    
    // MARK: - Private
    
    private func buildEventBrief(message: RoomMessageProtocol, htmlBody: String?) async -> EventBrief? {
        switch await memberDetailProvider.loadDisplayNameForUserId(message.sender) {
        case .success(let displayName):
            return EventBrief(eventId: message.id,
                              senderId: message.sender,
                              senderDisplayName: displayName,
                              body: message.body,
                              htmlBody: htmlBody,
                              date: message.originServerTs)
        case .failure(let error):
            MXLog.error("Failed fetching sender display name with error: \(error)")
            
            return EventBrief(eventId: message.id,
                              senderId: message.sender,
                              senderDisplayName: nil,
                              body: message.body,
                              htmlBody: htmlBody,
                              date: message.originServerTs)
        }
    }
}
