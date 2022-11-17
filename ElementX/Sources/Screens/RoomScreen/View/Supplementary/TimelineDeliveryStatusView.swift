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
struct TimelineDeliveryStatusView: View {
    let deliveryStatus: MessageTimelineItemDeliveryStatus
    
    @State var showDeliveryStatus: Bool
    
    private var systemImageName: String {
        switch deliveryStatus {
        case .sending, .unknown:
            return "circle"
        case .sent:
            return "checkmark.circle"
        }
    }
    
    init(deliveryStatus: MessageTimelineItemDeliveryStatus) {
        self.deliveryStatus = deliveryStatus
        
        switch deliveryStatus {
        case .sending:
            showDeliveryStatus = true
        case let .sent(elapsedTime: elapsedTime):
            showDeliveryStatus = elapsedTime < 3
        case .unknown:
            showDeliveryStatus = false
        }
    }
    
    var body: some View {
        if showDeliveryStatus {
            Image(systemName: systemImageName)
                .task {
                    if case .sent = deliveryStatus {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        withAnimation {
                            showDeliveryStatus = false
                        }
                    }
                }
        }
    }
}

struct TimelineDeliveryStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TimelineDeliveryStatusView(deliveryStatus: .sending)
            TimelineDeliveryStatusView(deliveryStatus: .sent(elapsedTime: Date().timeIntervalSince1970))
        }
    }
}
