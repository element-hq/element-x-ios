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

struct RoomDetailsEditScreen: View {
    @ObservedObject var context: RoomDetailsEditScreenViewModel.Context
    
    var body: some View {
        Form {
            Text("Hello world")
        }
    }
}

// MARK: - Previews

struct RoomDetailsEditScreen_Previews: PreviewProvider {
    static let viewModel = RoomDetailsEditScreenViewModel()
    static var previews: some View {
        RoomDetailsEditScreen(context: viewModel.context)
    }
}
