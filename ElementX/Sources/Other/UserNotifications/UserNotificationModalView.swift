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

import Combine
import SwiftUI

struct UserNotificationModalView: View {
    let notification: UserNotification
    @State private var progressFraction: Double?

    var body: some View {
        ZStack {
            VStack(spacing: 12.0) {
                if let progressFraction = progressFraction {
                    ProgressView(value: progressFraction)
                } else {
                    ProgressView()
                }

                HStack {
                    if let iconName = notification.iconName {
                        Image(systemName: iconName)
                    }
                    Text(notification.title)
                        .font(.element.body)
                        .foregroundColor(.element.primaryContent)
                }
            }
            .padding()
            .frame(minWidth: 150.0)
            .background(Color.element.quinaryContent)
            .clipShape(RoundedCornerShape(radius: 12.0, corners: .allCorners))
            .shadow(color: .black.opacity(0.1), radius: 10.0, y: 4.0)
            .transition(.opacity)
            .onReceive(notification.progressTracker?.progressFractionPublisher ?? Empty().eraseToAnyPublisher()) { progress in
                progressFraction = progress
            }
        }
        .id(notification.id)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.1))
        .ignoresSafeArea()
    }
    
    private var toastTransition: AnyTransition {
        AnyTransition
            .asymmetric(insertion: .move(edge: .top),
                        removal: .move(edge: .bottom))
            .combined(with: .opacity)
    }
}

struct UserNotificationModalView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UserNotificationModalView(notification: UserNotification(type: .modal,
                                                                     title: "Successfully logged in",
                                                                     iconName: "checkmark"))
        }
    }
}
