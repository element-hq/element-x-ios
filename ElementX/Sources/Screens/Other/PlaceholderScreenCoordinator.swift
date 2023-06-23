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

class PlaceholderScreenCoordinator: CoordinatorProtocol {
    func toPresentable() -> AnyView {
        AnyView(PlaceholderScreen())
    }
}

/// The app's splash screen. This screen is shown after the LaunchScreen
/// until the app is ready to show the relevant coordinator. The design of
/// these 2 screens are matched.
struct PlaceholderScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let outerShape = RoundedRectangle(cornerRadius: 44)
    private var isLight: Bool { colorScheme == .light }
    
    var body: some View {
        image
            .accessibilityHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background()
            .environment(\.backgroundStyle, AnyShapeStyle(Color.compound.bgCanvasDefault))
            .toolbar(.hidden, for: .automatic)
    }
    
    @ViewBuilder
    var image: some View {
        if isLight {
            logo
        } else {
            darkLogo
        }
    }
    
    var logo: some View {
        Image(asset: Asset.Images.appLogo)
            .padding(24)
            .background(.white.opacity(0.4))
            .clipShape(outerShape)
            .background {
                outerShape.fill(Color.white)
                    .shadow(color: Color(red: 0.11, green: 0.11, blue: 0.13).opacity(0.08), radius: 16, y: 8)
                
                outerShape.fill(Color.white)
                    .shadow(color: Color(red: 0.11, green: 0.11, blue: 0.13).opacity(0.5), radius: 16, y: 8)
                    .blendMode(.overlay)
            }
            .overlay {
                outerShape
                    .inset(by: 0.25)
                    .stroke(.white, lineWidth: 0.5)
            }
    }
    
    var darkLogo: some View {
        Image(asset: Asset.Images.appLogo)
            .shadow(color: .black.opacity(0.2), radius: 0.5, y: 2)
            .shadow(color: Color(red: 0.05, green: 0.74, blue: 0.55).opacity(0.2), radius: 16)
            .padding(24)
            .background {
                LinearGradient(stops: [.init(color: .white.opacity(0.05), location: 0.00),
                                       .init(color: .white.opacity(0), location: 1.00)],
                               startPoint: UnitPoint(x: 0, y: 0),
                               endPoint: UnitPoint(x: 1, y: 1))
                    .blendMode(.multiply)
            }
            .clipShape(outerShape)
            .shadow(color: .black.opacity(0.9), radius: 80, x: 0, y: 1)
            .overlay {
                outerShape
                    .inset(by: 0.25)
                    .stroke(.white.opacity(0.9), lineWidth: 0.5)
                    .blendMode(.overlay)
            }
    }
}

struct PlaceholderScreen_Previews: PreviewProvider {
    static var previews: some View {
        PlaceholderScreen()
            .previewDisplayName("Screen")
        
        NavigationSplitView {
            List {
                ForEach("Nothing to see here".split(separator: " "), id: \.self) { word in
                    Text(word)
                }
            }
        } detail: {
            PlaceholderScreen()
        }
        .previewDisplayName("Split View")
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
