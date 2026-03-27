//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
    
    @MainActor
    @Observable class TabDetails {
        /// A unique tab that identifies the tab for selection.
        let tag: Tag
        let title: String
        let icon: KeyPath<CompoundIcons, Image>
        let selectedIcon: KeyPath<CompoundIcons, Image>
        var badgeCount = 0
        var actionItems = [NavigationTabCoordinator.TabActionItem]()
        /// Called when the tab is directly selected, including when re-selecting it while an action item is active.
        var onSelect: (() -> Void)?
        
        /// Provide the tab's split coordinator in here to have the tab bar automatically hidden
        /// when pushing a child into the split view's details on iPhone/compact iPad.
        weak var navigationSplitCoordinator: NavigationSplitCoordinator?
        
        init(tag: Tag, title: String, icon: KeyPath<CompoundIcons, Image>, selectedIcon: KeyPath<CompoundIcons, Image>) {
            self.tag = tag
            self.title = title
            self.icon = icon
            self.selectedIcon = selectedIcon
        }
        
        func barVisibility(in horizontalSizeClass: UserInterfaceSizeClass?) -> Visibility {
            if horizontalSizeClass == .compact, navigationSplitCoordinator?.detailCoordinator != nil {
                // Whilst we support pushing screens on the stack in the sidebarCoordinator, in practice
                // we never do that, so simply checking that the detailCoordinator exists is enough.
                .hidden
            } else {
                .automatic
            }
        }
    }
    
    struct TabActionItem: Identifiable {
        /// A unique identifier for this action item.
        let tag: Tag
        let title: String
        let avatar: RoomAvatar
        let level: UInt
        let action: () -> Void
        
        var id: Tag {
            tag
        }
    }
    
    // MARK: Tabs
    
    fileprivate struct TabModule: Identifiable {
        let module: NavigationModule
        let details: TabDetails
        
        var id: ObjectIdentifier {
            module.id
        }

        @MainActor var coordinator: CoordinatorProtocol? {
            module.coordinator
        }
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
    
    /// The currently selected tab or action item tag.
    var selectedTab: Tag?
    
    /// The tag of the tab whose content should be displayed. If an action item is selected,
    /// this returns the tag of the tab that owns it; otherwise it matches `selectedTab` directly.
    var effectiveContentTab: Tag? {
        for module in tabModules where module.details.actionItems.contains(where: { $0.tag == selectedTab }) {
            return module.details.tag
        }
        return selectedTab
    }
    
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
    
    // MARK: - Overlay
    
    fileprivate var overlayModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove overlay", oldValue)
                oldValue.tearDown()
            }
            
            if let overlayModule {
                logPresentationChange("Set overlay", overlayModule)
                overlayModule.coordinator?.start()
            }
        }
    }
    
    /// The currently displayed overlay coordinator
    var overlayCoordinator: (any CoordinatorProtocol)? {
        overlayModule?.coordinator
    }
    
    enum OverlayPresentationMode { case fullScreen, minimized }
    fileprivate var overlayPresentationMode: OverlayPresentationMode = .minimized
    
    /// Present an overlay on top of the tab view
    /// - Parameters:
    ///   - coordinator: the coordinator to display
    ///   - presentationMode: how the coordinator should be presented
    ///   - animated: whether the transition should be animated
    ///   - dismissalCallback: called when the overlay has been dismissed, programatically or otherwise
    func setOverlayCoordinator(_ coordinator: (any CoordinatorProtocol)?,
                               presentationMode: OverlayPresentationMode = .fullScreen,
                               animated: Bool = true,
                               dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            overlayModule = nil
            return
        }
        
        if overlayModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            overlayPresentationMode = presentationMode
            overlayModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    /// Updates the presentation of the overlay coordinator.
    /// - Parameters:
    ///   - mode: The type of presentation to use.
    ///   - animated: whether the transition should be animated
    func setOverlayPresentationMode(_ mode: OverlayPresentationMode, animated: Bool = true) {
        var transaction = Transaction()
        transaction.disablesAnimations = !animated
        
        withTransaction(transaction) {
            overlayPresentationMode = mode
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
    
    // MARK: - General
    
    let mediaProvider: MediaProviderProtocol
    
    var description: String {
        guard !tabModules.isEmpty else { return "NavigationTabCoordinator(Empty)" }
        return "NavigationTabCoordinator(\(tabCoordinators)"
    }
    
    init(mediaProvider: MediaProviderProtocol) {
        self.mediaProvider = mediaProvider
    }
    
    // MARK: - Private
    
    private func logPresentationChange(_ change: String, _ module: NavigationModule) {
        if let coordinator = module.coordinator {
            MXLog.info("\(self) \(change): \(coordinator)")
        }
    }
}

extension EnvironmentValues {
    // TODO: Maybe this should live on the NavigationSplitView instead 🤔
    /// The horizontal size class of the tab coordinator's container, unaffected by NavigationSplitView overrides.
    @Entry var tabCoordinatorHorizontalSizeClass: UserInterfaceSizeClass?
}

private struct NavigationTabCoordinatorView<Tag: Hashable>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Bindable var navigationTabCoordinator: NavigationTabCoordinator<Tag>
    
    @State private var standardAppearance = UITabBarAppearance()
    
    var body: some View {
        tabView
            .environment(\.tabCoordinatorHorizontalSizeClass, horizontalSizeClass)
            .sheet(item: $navigationTabCoordinator.sheetModule) { module in
                module.coordinator?.toPresentable()
                    .id(module.id)
            }
            .fullScreenCover(item: $navigationTabCoordinator.fullScreenCoverModule) { module in
                module.coordinator?.toPresentable()
                    .id(module.id)
            }
            .accessibilityHidden(navigationTabCoordinator.overlayModule?.coordinator != nil && navigationTabCoordinator.overlayPresentationMode == .fullScreen)
            .overlay {
                Group {
                    if let coordinator = navigationTabCoordinator.overlayModule?.coordinator {
                        coordinator.toPresentable()
                            .opacity(navigationTabCoordinator.overlayPresentationMode == .minimized ? 0 : 1)
                            .transition(.opacity)
                    }
                }
                .animation(.elementDefault, value: navigationTabCoordinator.overlayPresentationMode)
                .animation(.elementDefault, value: navigationTabCoordinator.overlayModule)
            }
    }
    
    @ViewBuilder
    var tabView: some View {
        if horizontalSizeClass == .regular {
            regularLayout
        } else {
            compactLayout
        }
    }
    
    /// The column visibility of the split coordinator for the currently selected tab, if any.
    private var selectedTabSplitColumnVisibility: NavigationSplitViewVisibility {
        let selectedTabDetails = navigationTabCoordinator.tabModules
            .first { $0.details.tag == navigationTabCoordinator.effectiveContentTab }?.details
        return selectedTabDetails?.navigationSplitCoordinator?.columnVisibility ?? .all
    }
    
    private var isRailVisible: Bool {
        selectedTabSplitColumnVisibility != .detailOnly
    }
    
    var regularLayout: some View {
        HStack(spacing: 0) {
            if isRailVisible {
                TabRailView(navigationTabCoordinator: navigationTabCoordinator)
                    .background {
                        Color.compound.bgCanvasDefault
                            .overlay(alignment: .trailing) {
                                Divider()
                            }
                            .ignoresSafeArea()
                    }
                    .zIndex(1)
            }
            
            if let module = navigationTabCoordinator.tabModules.first(where: { $0.details.tag == navigationTabCoordinator.effectiveContentTab }) {
                module.coordinator?.toPresentable()
                    .id(module.id)
            }
        }
    }
    
    var compactLayout: some View {
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
                    .toolbar(module.details.barVisibility(in: horizontalSizeClass), for: .tabBar) // TODO: Remove this?!
            }
        }
        .onChange(of: navigationTabCoordinator.selectedTab) { _, newTab in
            if let module = navigationTabCoordinator.tabModules.first(where: { $0.details.tag == newTab }) {
                module.details.onSelect?()
            }
        }
        .backportTabBarMinimizeBehaviorOnScrollDown()
        .introspect(.tabView, on: .supportedVersions, customize: configureAppearance)
    }
    
    private func configureAppearance(_ tabBarController: UITabBarController) {
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.stackedLayoutAppearance.normal.badgeBackgroundColor = .compound.iconAccentPrimary // iPhone Portrait
        standardAppearance.compactInlineLayoutAppearance.normal.badgeBackgroundColor = .compound.iconAccentPrimary // iPhone Landscape
        standardAppearance.inlineLayoutAppearance.normal.badgeBackgroundColor = .compound.iconAccentPrimary // iPadOS 17 (doesn't work for 18+)
        tabBarController.tabBar.standardAppearance = standardAppearance
    }
}

struct TabRailView<Tag: Hashable>: View {
    let navigationTabCoordinator: NavigationTabCoordinator<Tag>
    
    @State private var width: CGFloat = .zero
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(navigationTabCoordinator.tabModules) { module in
                    let isSelected = module.details.tag == navigationTabCoordinator.selectedTab
                    Button {
                        navigationTabCoordinator.selectedTab = module.details.tag
                        module.details.onSelect?()
                    } label: {
                        Label {
                            Text(module.details.title)
                        } icon: {
                            CompoundIcon(isSelected ? module.details.selectedIcon : module.details.icon)
                        }
                        .foregroundStyle(.compound.iconPrimary)
                        .padding(8)
                        .background {
                            ZStack {
                                let shape = RoundedRectangle(cornerRadius: 12)
                                shape.fill(.compound.bgSubtlePrimary)
                                shape.stroke(isSelected ? .compound.bgActionPrimaryRest : .clear, lineWidth: 2)
                            }
                        }
                    }
                    .labelStyle(.iconOnly)
                    .badge(10) // TODO: Check if this works.
                    
                    ForEach(module.details.actionItems) { item in
                        let isSelected = item.tag == navigationTabCoordinator.selectedTab
                        Button {
                            navigationTabCoordinator.selectedTab = item.tag
                            item.action()
                        } label: {
                            Label {
                                Text(item.title)
                            } icon: {
                                RoomAvatarImage(avatar: item.avatar,
                                                avatarSize: .custom(item.level == 0 ? 40 : 32),
                                                mediaProvider: navigationTabCoordinator.mediaProvider)
                            }
                            .foregroundStyle(.compound.iconPrimary)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? .compound.bgActionPrimaryRest : .clear, lineWidth: 2)
                            }
                        }
                        .labelStyle(.iconOnly)
                        .padding(.leading, item.level == 0 ? 0 : 8)
                        // TODO: .badge(item.badgeCount)
                    }
                }
            }
            .padding(.horizontal, ProcessInfo.processInfo.isiOSAppOnMac ? 16 : 12)
            .padding(.top, ProcessInfo.processInfo.isiOSAppOnMac ? 0 : 40) // FIXME: Properly avoid the traffic lights safe area?
            .padding(.bottom)
            .readWidth($width)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(width: width)
    }
}
