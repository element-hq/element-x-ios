//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

/// A view modifier that applies a shimmering effect to the view.
struct ShimmerModifier: ViewModifier {
    /// A boolean which is toggled to trigger the animation.
    @State private var animationTrigger = false
    
    /// The start and end points of a gradient.
    private struct GradientPoints {
        /// The start point of the gradient.
        let start: UnitPoint
        /// The end point of the gradient.
        let end: UnitPoint
    }
    
    /// The initial points used by the gradient before animation occurs.
    private let initialPoints = GradientPoints(start: UnitPoint(x: -5, y: 0), end: UnitPoint(x: 0, y: 0))
    /// The final points used by the gradient once the animation has completed.
    private let finalPoints = GradientPoints(start: UnitPoint(x: 1, y: 0), end: UnitPoint(x: 5, y: 0))
    
    /// The colour that causes a highlight to be shown.
    private let highlightColor = Color.white.opacity(0.5)
    /// The colour that causes the view to remain unchanged.
    private let regularColor = Color.white
    
    /// A slow linear animation which auto-repeats after a delay.
    private let animation: Animation = .linear(duration: 1.75)
        .delay(0.5)
        .repeatForever(autoreverses: false)
        .disabledDuringTests()
    
    func body(content: Content) -> some View {
        content
            .mask { gradient }
            .animation(animation, value: animationTrigger)
            .task {
                animationTrigger.toggle()
            }
    }
    
    /// The gradient used to create the shimmer.
    var gradient: LinearGradient {
        LinearGradient(stops: [.init(color: regularColor, location: 0),
                               .init(color: regularColor, location: 0.3),
                               .init(color: highlightColor, location: 0.45),
                               .init(color: highlightColor, location: 0.55),
                               .init(color: regularColor, location: 0.7),
                               .init(color: regularColor, location: 1)],
                       startPoint: animationTrigger ? finalPoints.start : initialPoints.start,
                       endPoint: animationTrigger ? finalPoints.end : initialPoints.end)
    }
}

extension View {
    /// Applies a shimmering effect to the view.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct ShimmerOverlay_Previews: PreviewProvider, TestablePreview {
    static let viewModel = HomeScreenViewModel(userSession: UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "")))),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               appSettings: ServiceLocator.shared.settings,
                                               selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController)
    
    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(0...8, id: \.self) { _ in
                HomeScreenRoomCell(room: .placeholder(), context: viewModel.context, isSelected: false)
            }
        }
        .redacted(reason: .placeholder)
        .shimmer()
    }
}
