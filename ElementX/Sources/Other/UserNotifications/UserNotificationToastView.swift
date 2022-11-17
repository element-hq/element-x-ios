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

struct UserNotificationToastView: View {
    let notification: UserNotification
    
    var body: some View {
        HStack {
            if let iconName = notification.iconName {
                Image(systemName: iconName)
            }
            Text(notification.title)
                .font(.element.footnote)
                .foregroundColor(.element.primaryContent)
        }
        .id(notification.id)
        .padding(.horizontal, 12.0)
        .padding(.vertical, 10.0)
        .frame(minWidth: 150.0)
        .background(Color.element.quaternaryContent)
        .clipShape(RoundedCornerShape(radius: 24.0, corners: .allCorners))
        .shadow(color: .black.opacity(0.1), radius: 10.0, y: 4.0)
        .transition(toastTransition)
    }
    
    private var toastTransition: AnyTransition {
        AnyTransition
            .asymmetric(insertion: .move(edge: .top),
                        removal: .move(edge: .bottom))
            .combined(with: .opacity)
    }
}

struct UserNotificationToastView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    private static var body: some View {
        VStack {
            UserNotificationToastView(notification: UserNotification(title: "Successfully logged in",
                                                                     iconName: "checkmark"))
            
            UserNotificationToastView(notification: UserNotification(title: "Toast without icon"))
        }
    }
}
