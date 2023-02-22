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

import SwiftUI

protocol AlertItem {
    var title: String { get }
}

extension View {
    func alert<I, V>(item: Binding<I?>, actions: (I) -> V, message: (I) -> V) -> some View where I: AlertItem, V: View {
        let binding = Binding<Bool>(get: {
            item.wrappedValue != nil
        }, set: { newValue in
            if !newValue {
                item.wrappedValue = nil
            }
        })
        return alert(item.wrappedValue?.title ?? "", isPresented: binding, presenting: item.wrappedValue, actions: actions, message: message)
    }

    func alert<I, V>(item: Binding<I?>, actions: (I) -> V) -> some View where I: AlertItem, V: View {
        let binding = Binding<Bool>(get: {
            item.wrappedValue != nil
        }, set: { newValue in
            if !newValue {
                item.wrappedValue = nil
            }
        })
        return alert(item.wrappedValue?.title ?? "", isPresented: binding, presenting: item.wrappedValue, actions: actions)
    }
}
