//
// Copyright 2021 New Vector Ltd
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

import DesignKit
import SwiftUI

/// The splash screen shown at the beginning of the onboarding flow.
struct SplashScreen: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.layoutDirection) private var layoutDirection
    
    private var isLeftToRight: Bool { layoutDirection == .leftToRight }
    private var pageCount: Int { context.viewState.content.count }
    
    /// A timer to automatically animate the pages.
    @State private var pageTimer: Timer?
    /// The amount of offset to apply when a drag gesture is in progress.
    @State private var dragOffset: CGFloat = .zero
    
    // MARK: Public
    
    @ObservedObject var context: SplashScreenViewModel.Context
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                Spacer()
                    .frame(height: UIConstants.spacerHeight(in: geometry))
                
                // The main content of the carousel
                HStack(alignment: .top, spacing: 0) {
                    
                    // Add a hidden page at the start of the carousel duplicating the content of the last page
                    SplashScreenPageView(content: context.viewState.content[pageCount - 1])
                        .frame(width: geometry.size.width)
                        .accessibilityIdentifier("hiddenPage")
                    
                    ForEach(0..<pageCount, id: \.self) { index in
                        SplashScreenPageView(content: context.viewState.content[index])
                            .frame(width: geometry.size.width)
                    }
                    
                }
                .offset(x: pageOffset(in: geometry))
                
                Spacer()
                
                SplashScreenPageIndicator(pageCount: pageCount, pageIndex: context.pageIndex)
                    .frame(width: geometry.size.width)
                    .padding(.bottom)
                
                Spacer()
                
                buttons
                    .frame(width: geometry.size.width)
                    .padding(.bottom, UIConstants.actionButtonBottomPadding)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                
                Spacer()
                    .frame(height: UIConstants.spacerHeight(in: geometry))
            }
            .frame(maxHeight: .infinity)
            .background(background.ignoresSafeArea().offset(x: pageOffset(in: geometry)))
            .gesture(
                DragGesture()
                    .onChanged(handleDragGestureChange)
                    .onEnded { handleDragGestureEnded($0, viewSize: geometry.size) }
            )
        }
        .navigationBarHidden(true)
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
    }
    
    /// The main action buttons.
    var buttons: some View {
        VStack(spacing: 12) {
            Button { context.send(viewAction: .login) } label: {
                Text(ElementL10n.loginSplashSubmit)
            }
            .buttonStyle(.elementAction(.xLarge))
            .accessibilityIdentifier("getStartedButton")
        }
        .padding(.horizontal, 16)
        .readableFrame()
    }
    
    @ViewBuilder
    /// The view's background, showing a gradient in light mode and a solid colour in dark mode.
    var background: some View {
        if colorScheme == .light {
            LinearGradient(gradient: context.viewState.backgroundGradient,
                           startPoint: .leading,
                           endPoint: .trailing)
                .flipsForRightToLeftLayoutDirection(true)
        } else {
            Color.element.background
        }
    }
    
    // MARK: - Animation
    
    /// Starts the animation timer for an automatic carousel effect.
    private func startTimer() {
        guard pageTimer == nil else { return }
        
        pageTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            if context.pageIndex == pageCount - 1 {
                showHiddenPage()
                
                withAnimation(.easeInOut(duration: 0.7)) {
                    showNextPage()
                }
            } else {
                withAnimation(.easeInOut(duration: 0.7)) {
                    showNextPage()
                }
            }
        }
    }
    
    /// Stops the animation timer for manual interaction.
    private func stopTimer() {
        guard let pageTimer = pageTimer else { return }
        
        self.pageTimer = nil
        pageTimer.invalidate()
    }
    
    private func showNextPage() {
        // Wrap back round to the first page index when reaching the end.
        context.pageIndex = (context.pageIndex + 1) % context.viewState.content.count
    }
    
    private func showPreviousPage() {
        // Prevent the hidden page at index -1 from being shown.
        context.pageIndex = max(0, context.pageIndex - 1)
    }
    
    private func showHiddenPage() {
        // Hidden page for a nicer animation when looping back to the start.
        context.pageIndex = -1
    }
    
    /// The offset to apply to the `HStack` of pages.
    private func pageOffset(in geometry: GeometryProxy) -> CGFloat {
        (CGFloat(context.pageIndex + 1) * -geometry.size.width) + dragOffset
    }
    
    // MARK: - Gestures
    
    /// Whether or not a drag gesture is valid or not.
    /// - Parameter width: The gesture's translation width.
    /// - Returns: `true` if there is another page to drag to.
    private func shouldSwipeForTranslation(_ width: CGFloat) -> Bool {
        if context.pageIndex == 0 {
            return isLeftToRight ? width < 0 : width > 0
        } else if context.pageIndex == pageCount - 1 {
            return isLeftToRight ? width > 0 : width < 0
        }
        
        return true
    }
    
    /// Updates the `dragOffset` based on the gesture's value.
    /// - Parameter drag: The drag gesture value to handle.
    private func handleDragGestureChange(_ drag: DragGesture.Value) {
        guard shouldSwipeForTranslation(drag.translation.width) else { return }
        
        stopTimer()
        
        // Animate the change over a few frames to smooth out any stuttering.
        withAnimation(.linear(duration: 0.05)) {
            dragOffset = isLeftToRight ? drag.translation.width : -drag.translation.width
        }
    }
    
    /// Clears the drag offset and informs the view model to switch to another page if necessary.
    /// - Parameter viewSize: The size of the view in which the gesture took place.
    private func handleDragGestureEnded(_ drag: DragGesture.Value, viewSize: CGSize) {
        guard shouldSwipeForTranslation(drag.predictedEndTranslation.width) else {
            // Reset the offset just in case.
            withAnimation { dragOffset = 0 }
            return
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if drag.predictedEndTranslation.width < -viewSize.width / 2 {
                showNextPage()
            } else if drag.predictedEndTranslation.width > viewSize.width / 2 {
                showPreviousPage()
            }
            
            dragOffset = 0
        }
    }
}

// MARK: - Previews

struct SplashScreen_Previews: PreviewProvider {
    static let viewModel = SplashScreenViewModel()
    
    static var previews: some View {
        SplashScreen(context: viewModel.context)
            .tint(.element.accent)
    }
}
