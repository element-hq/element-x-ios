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

import MatrixRustSDK
import UIKit

struct ImageRoomMessage: RoomMessageProtocol {
    private let message: MatrixRustSDK.ImageMessage
    
    init(message: MatrixRustSDK.ImageMessage) {
        self.message = message
    }
    
    var id: String {
        message.baseMessage().id()
    }
    
    var body: String {
        message.baseMessage().body()
    }
    
    var sender: String {
        message.baseMessage().sender()
    }
    
    var originServerTs: Date {
        Date(timeIntervalSince1970: TimeInterval(message.baseMessage().originServerTs()))
    }
    
    var source: MediaSource? {
        MediaSource(source: message.source())
    }
    
    var width: CGFloat? {
        guard let width = message.width() else {
            return nil
        }
        
        return CGFloat(width)
    }
    
    var height: CGFloat? {
        guard let height = message.height() else {
            return nil
        }
        
        return CGFloat(height)
    }
    
    var blurhash: String? {
        message.blurhash()
    }
}
