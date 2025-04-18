//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import SwiftUIIntrospect

extension View {
    // Note: The dependency on HomeScreenViewModel.Context will be removed in the next iteration.
    @ViewBuilder
    func bloom(context: HomeScreenViewModel.Context, scrollViewAdapter: ScrollViewAdapter, isNewBloomEnabled: Bool) -> some View {
        if isNewBloomEnabled {
            modifier(NewBloomModifier())
        } else {
            modifier(BloomModifier(context: context, scrollViewAdapter: scrollViewAdapter))
        }
    }
}

struct NewBloomModifier: ViewModifier {
    @State private var standardAppearance = UINavigationBarAppearance()
    @State private var scrollEdgeAppearance = UINavigationBarAppearance()
    
    @State private var bloomGradientImage: UIImage?
    
    func body(content: Content) -> some View {
        content
            .introspect(.viewController, on: .supportedVersions, customize: configureBloom)
    }
    
    private func configureBloom(controller: UIViewController) {
        guard controller.navigationItem.standardAppearance != standardAppearance,
              controller.navigationItem.scrollEdgeAppearance != scrollEdgeAppearance else {
            return
        }
        
        let image = makeBloomImage()
        
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundImage = image
        standardAppearance.backgroundImageContentMode = .scaleToFill
        controller.navigationItem.standardAppearance = standardAppearance
        
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.backgroundImage = image
        scrollEdgeAppearance.backgroundImageContentMode = .scaleToFill
        scrollEdgeAppearance.backgroundColor = .compound.bgCanvasDefault
        controller.navigationItem.scrollEdgeAppearance = scrollEdgeAppearance
    }
    
    private func makeBloomImage() -> UIImage? {
        if let bloomGradientImage {
            return bloomGradientImage
        }
        
        let newImage = ImageRenderer(content: bloomGradient).uiImage
        Task { bloomGradientImage = newImage }
        return newImage
    }
    
    private var bloomGradient: some View {
        LinearGradient(colors: [.compound._bgOwnPill, .clear], // This isn't the final gradient.
                       startPoint: .top,
                       endPoint: .init(x: 0.5, y: 0.7))
            .ignoresSafeArea(edges: .all)
            .frame(width: 256, height: 256)
    }
}

struct BloomModifier: ViewModifier {
    @ObservedObject var context: HomeScreenViewModel.Context
    
    let scrollViewAdapter: ScrollViewAdapter
    
    // Bloom components
    @State private var bloomView: UIView?
    @State private var leftBarButtonView: UIView?
    @State private var gradientView: UIView?
    @State private var navigationBarContainer: UIView?
    @State private var hairlineView: UIView?
    
    func body(content: Content) -> some View {
        content
            .introspect(.viewController, on: .supportedVersions) { controller in
                Task {
                    if bloomView == nil {
                        makeBloomView(controller: controller)
                    }
                }
                let isTopController = controller.navigationController?.topViewController != controller
                let isHidden = isTopController || context.isSearchFieldFocused
                if let bloomView {
                    bloomView.isHidden = isHidden
                    UIView.transition(with: bloomView, duration: 1.75, options: .curveEaseInOut) {
                        bloomView.alpha = isTopController ? 0 : 1
                    }
                }
                gradientView?.isHidden = isHidden
                navigationBarContainer?.clipsToBounds = !isHidden
                hairlineView?.isHidden = isHidden || !scrollViewAdapter.isAtTopEdge.value
                if !isHidden {
                    updateBloomCenter()
                }
            }
            .onReceive(scrollViewAdapter.isAtTopEdge.removeDuplicates()) { value in
                hairlineView?.isHidden = !value
                guard let gradientView else {
                    return
                }
                if value {
                    UIView.transition(with: gradientView, duration: 0.3, options: .curveEaseIn) {
                        gradientView.alpha = 0
                    }
                } else {
                    gradientView.alpha = 1
                }
            }
    }
    
    private var bloomGradient: some View {
        LinearGradient(colors: [.clear, .compound.bgCanvasDefault], startPoint: .top, endPoint: .bottom)
            .mask {
                LinearGradient(stops: [.init(color: .white, location: 0.75), .init(color: .clear, location: 1.0)],
                               startPoint: .leading,
                               endPoint: .trailing)
            }
            .ignoresSafeArea(edges: .all)
    }
            
    private func makeBloomView(controller: UIViewController) {
        guard let navigationBarContainer = controller.navigationController?.navigationBar.subviews.first,
              let leftBarButtonView = controller.navigationItem.leadingItemGroups.first?.barButtonItems.first?.customView else {
            return
        }
        
        let bloomController = UIHostingController(rootView: bloom)
        bloomController.view.translatesAutoresizingMaskIntoConstraints = true
        bloomController.view.backgroundColor = .clear
        navigationBarContainer.insertSubview(bloomController.view, at: 0)
        self.leftBarButtonView = leftBarButtonView
        bloomView = bloomController.view
        self.navigationBarContainer = navigationBarContainer
        updateBloomCenter()
        
        let gradientController = UIHostingController(rootView: bloomGradient)
        gradientController.view.backgroundColor = .clear
        gradientController.view.translatesAutoresizingMaskIntoConstraints = false
        navigationBarContainer.insertSubview(gradientController.view, aboveSubview: bloomController.view)
        
        let constraints = [gradientController.view.bottomAnchor.constraint(equalTo: navigationBarContainer.bottomAnchor),
                           gradientController.view.trailingAnchor.constraint(equalTo: navigationBarContainer.trailingAnchor),
                           gradientController.view.leadingAnchor.constraint(equalTo: navigationBarContainer.leadingAnchor),
                           gradientController.view.heightAnchor.constraint(equalToConstant: 40)]
        constraints.forEach { $0.isActive = true }
        gradientView = gradientController.view
        
        let dividerController = UIHostingController(rootView: Divider().ignoresSafeArea())
        dividerController.view.translatesAutoresizingMaskIntoConstraints = false
        navigationBarContainer.addSubview(dividerController.view)
        let dividerConstraints = [dividerController.view.bottomAnchor.constraint(equalTo: gradientController.view.bottomAnchor),
                                  dividerController.view.widthAnchor.constraint(equalTo: gradientController.view.widthAnchor),
                                  dividerController.view.leadingAnchor.constraint(equalTo: gradientController.view.leadingAnchor)]
        dividerConstraints.forEach { $0.isActive = true }
        hairlineView = dividerController.view
    }

    private func updateBloomCenter() {
        guard let leftBarButtonView,
              let bloomView,
              let navigationBarContainer = bloomView.superview else {
            return
        }
        
        let center = leftBarButtonView.convert(leftBarButtonView.center, to: navigationBarContainer.coordinateSpace)
        bloomView.center = center
    }
    
    private var bloom: some View {
        BloomView(context: context)
    }
}

private struct BloomView: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            avatar
                .blur(radius: 64)
                .blendMode(colorScheme == .dark ? .exclusion : .hardLight)
                .opacity(colorScheme == .dark ? 0.50 : 0.20)
            avatar
                .blur(radius: 64)
                .blendMode(.color)
                .opacity(colorScheme == .dark ? 0.20 : 0.80)
        }
    }
    
    private var avatar: some View {
        LoadableAvatarImage(url: context.viewState.userAvatarURL,
                            name: context.viewState.userDisplayName,
                            contentID: context.viewState.userID,
                            avatarSize: .custom(256),
                            mediaProvider: context.mediaProvider)
    }
}
