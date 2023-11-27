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

import Foundation
import MatrixRustSDK

final class TimelineProxy: TimelineProxyProtocol {
    private var timeline: Timeline
    private var sendMessageBackgroundTask: BackgroundTaskProtocol?
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    #warning("AG: should we use a different task name for different TimelineProxies?")
    private let backgroundTaskName = "SendRoomEvent"
    private let lowPriorityDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.low_priority", qos: .utility)
    
    init(timeline: Timeline, backgroundTaskService: BackgroundTaskServiceProtocol) {
        self.timeline = timeline
        self.backgroundTaskService = backgroundTaskService
    }
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, TimelineProxyError> {
        do {
            try await Task.dispatch(on: .global()) {
                try self.timeline.paginateBackwards(opts: .untilNumItems(eventLimit: UInt16(requestSize), items: UInt16(untilNumberOfItems), waitForToken: true))
            }
            
            return .success(())
        } catch {
            return .failure(.failedPaginatingBackwards)
        }
    }
    
    func sendReadReceipt(for eventID: String) async -> Result<Void, TimelineProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        return await Task.dispatch(on: lowPriorityDispatchQueue) {
            do {
                try self.timeline.sendReadReceipt(eventId: eventID)
                return .success(())
            } catch {
                return .failure(.failedSendingReadReceipt)
            }
        }
    }
}
