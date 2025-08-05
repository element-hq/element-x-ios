//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// Class responsible for displaying an arbitrary number of coordinators within the tab bar.
@Observable class NavigationTabCoordinator<Tag: Hashable>: CoordinatorProtocol, CustomStringConvertible {
    struct Tab {
        let coordinator: CoordinatorProtocol
        let details: TabDetails
        var dismissalCallback: (() -> Void)?
    }
    
    @Observable class TabDetails {
        /// A unique tab that identifies the tab for selection.
        let tag: Tag
        let title: String
        let icon: KeyPath<CompoundIcons, Image>
        let selectedIcon: KeyPath<CompoundIcons, Image>
        var badgeCount = 0
        var barVisibility: Visibility = .automatic
        
        init(tag: Tag, title: String, icon: KeyPath<CompoundIcons, Image>, selectedIcon: KeyPath<CompoundIcons, Image>) {
            self.tag = tag
            self.title = title
            self.icon = icon
            self.selectedIcon = selectedIcon
        }
    }
    
    // MARK: Tabs
    
    fileprivate struct TabModule: Identifiable {
        let module: NavigationModule
        let details: TabDetails
        
        var id: ObjectIdentifier { module.id }
        @MainActor var coordinator: CoordinatorProtocol? { module.coordinator }
    }
    
    fileprivate var tabModules = [TabModule]() {
        didSet {
            let diffs = tabModules.map(\.module).difference(from: oldValue.map(\.module))
            diffs.forEach { change in
                switch change {
                case .insert(_, let module, _):
                    logPresentationChange("Set tab", module)
                    module.coordinator?.start()
                case .remove(_, let module, _):
                    logPresentationChange("Remove tab", module)
                    module.tearDown()
                }
            }
        }
    }
    
    /// The current set of coordinators displayed by the tabs.
    var tabCoordinators: [any CoordinatorProtocol] {
        tabModules.compactMap(\.module.coordinator)
    }
    
    /// Updates the displayed tabs with the provided array.
    func setTabs(_ tabs: [Tab], animated: Bool = true) {
        var transaction = Transaction()
        transaction.disablesAnimations = !animated
        
        withTransaction(transaction) {
            tabModules = tabs.map { TabModule(module: .init($0.coordinator, dismissalCallback: $0.dismissalCallback), details: $0.details) }
        }
        
        selectedTab = tabModules.first?.details.tag
    }
    
    /// The currently selected tab's tag.
    var selectedTab: Tag?
    
    // MARK: Sheets
    
    fileprivate var sheetModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove sheet", oldValue)
                oldValue.tearDown()
            }
            
            if let sheetModule {
                logPresentationChange("Set sheet", sheetModule)
                sheetModule.coordinator?.start()
            }
        }
    }
    
    var presentationDetents: Set<PresentationDetent> = []
    
    /// The currently presented sheet coordinator.
    var sheetCoordinator: (any CoordinatorProtocol)? {
        sheetModule?.coordinator
    }
    
    /// Present a sheet on top of the stack. If this NavigationStackCoordinator is embedded within a NavigationSplitCoordinator
    /// then the presentation will be proxied to the split
    /// - Parameters:
    ///   - coordinator: the coordinator to display
    ///   - animated: whether to animate the transition or not. Default is true

    ///   - dismissalCallback: called when the sheet has been dismissed, programatically or otherwise
    func setSheetCoordinator(_ coordinator: (any CoordinatorProtocol)?, animated: Bool = true, dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            sheetModule = nil
            return
        }
        
        if sheetModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            sheetModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    // MARK: Full Screen Cover
    
    fileprivate var fullScreenCoverModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove fullscreen cover", oldValue)
                oldValue.tearDown()
            }
            
            if let fullScreenCoverModule {
                logPresentationChange("Set fullscreen cover", fullScreenCoverModule)
                fullScreenCoverModule.coordinator?.start()
            }
        }
    }
    
    /// The currently presented fullscreen cover coordinator
    /// Fullscreen covers will be presented through the NavigationSplitCoordinator if provided
    var fullScreenCoverCoordinator: (any CoordinatorProtocol)? {
        fullScreenCoverModule?.coordinator
    }
    
    /// Present a fullscreen cover on top of the stack. If this NavigationStackCoordinator is embedded within a NavigationSplitCoordinator
    /// then the presentation will be proxied to the split
    /// - Parameters:
    ///   - coordinator: the coordinator to display
    ///   - animated: whether to animate the transition or not. Default is true
    ///   - dismissalCallback: called when the fullscreen cover has been dismissed, programatically or otherwise
    func setFullScreenCoverCoordinator(_ coordinator: (any CoordinatorProtocol)?, animated: Bool = true, dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            fullScreenCoverModule = nil
            return
        }
        
        if fullScreenCoverModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            fullScreenCoverModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    // MARK: - CoordinatorProtocol
    
    /// No idea if this is particuarly needed for the TabView but we do this for the NavigationStackCoordinator and NavigationSplitCoordinator so it
    /// doesn't seem to harm to also do it here.
    func stop() {
        tabModules.forEach { $0.module.tearDown() }
    }
    
    func toPresentable() -> AnyView {
        AnyView(NavigationTabCoordinatorView(navigationTabCoordinator: self))
    }
    
    // MARK: - CustomStringConvertible
    
    var description: String {
        guard !tabModules.isEmpty else { return "NavigationTabCoordinator(Empty)" }
        return "NavigationTabCoordinator(\(tabCoordinators)"
    }
    
    // MARK: - Private
    
    private func logPresentationChange(_ change: String, _ module: NavigationModule) {
        if let coordinator = module.coordinator {
            MXLog.info("\(self) \(change): \(coordinator)")
        }
    }
}

private struct NavigationTabCoordinatorView<Tag: Hashable>: View {
    @Bindable var navigationTabCoordinator: NavigationTabCoordinator<Tag>
    
    @State private var standardAppearance = UITabBarAppearance()
    
    var body: some View {
        TabView(selection: $navigationTabCoordinator.selectedTab) {
            ForEach(navigationTabCoordinator.tabModules) { module in
                module.coordinator?.toPresentable()
                    .id(module.id)
                    .tabItem {
                        Label {
                            Text(module.details.title)
                        } icon: {
                            CompoundIcon(module.details.tag == navigationTabCoordinator.selectedTab ? module.details.selectedIcon : module.details.icon)
                        }
                    }
                    .tag(module.details.tag)
                    .badge(module.details.badgeCount)
                    .toolbar(module.details.barVisibility, for: .tabBar)
            }
        }
        .introspect(.tabView, on: .supportedVersions, customize: configureAppearance)
        .sheet(item: $navigationTabCoordinator.sheetModule) { module in
            module.coordinator?.toPresentable()
                .id(module.id)
        }
        .fullScreenCover(item: $navigationTabCoordinator.fullScreenCoverModule) { module in
            module.coordinator?.toPresentable()
                .id(module.id)
        }
    }
    
    private func configureAppearance(_ tabBarController: UITabBarController) {
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.stackedLayoutAppearance.normal.badgeBackgroundColor = .compound.iconAccentPrimary
        tabBarController.tabBar.standardAppearance = standardAppearance
    }
}
