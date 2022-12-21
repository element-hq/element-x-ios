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

/// Class responsible for displaying 2 coordinators side by side and collapsing them
/// into a single navigation stack on compact layouts
class NavigationSplitCoordinator: CoordinatorProtocol, ObservableObject, CustomStringConvertible {
    fileprivate let placeholderModule: NavigationModule
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published fileprivate var sidebarModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove sidebar", oldValue)
                oldValue.coordinator.stop()
                oldValue.dismissalCallback?()
            }
            
            if let sidebarModule {
                logPresentationChange("Set sidebar", sidebarModule)
                sidebarModule.coordinator.start()
            }
            
            updateCompactLayoutComponents()
        }
    }
    
    /// The currently displayed sidebar coordinator
    var sidebarCoordinator: (any CoordinatorProtocol)? {
        sidebarModule?.coordinator
    }
    
    @Published fileprivate var detailModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove detail", oldValue)
                oldValue.coordinator.stop()
                oldValue.dismissalCallback?()
            }
            
            if let detailModule {
                logPresentationChange("Set detail", detailModule)
                detailModule.coordinator.start()
            }
            
            updateCompactLayoutComponents()
        }
    }
    
    /// The currently displayed detail coordinator
    var detailCoordinator: (any CoordinatorProtocol)? {
        detailModule?.coordinator
    }
    
    @Published fileprivate var sheetModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove sheet", oldValue)
                oldValue.coordinator.stop()
                oldValue.dismissalCallback?()
            }
            
            if let sheetModule {
                logPresentationChange("Set sheet", sheetModule)
                sheetModule.coordinator.start()
            }
            
            updateCompactLayoutComponents()
        }
    }
    
    /// The currently displayed sheet coordinator
    var sheetCoordinator: (any CoordinatorProtocol)? {
        sheetModule?.coordinator
    }
    
    @Published fileprivate var compactLayoutRootModule: NavigationModule?
    
    var compactLayoutRootCoordinator: (any CoordinatorProtocol)? {
        compactLayoutRootModule?.coordinator
    }
    
    /// This is set as internal so that we can manipulate the compact layout stack from the unit tests.
    /// Shouldn't be used otherwise.
    @Published internal var compactLayoutStackModules: [NavigationModule] = []
    
    var compactLayoutStackCoordinators: [any CoordinatorProtocol] {
        compactLayoutStackModules.map(\.coordinator)
    }
    
    /// Default NavigationSplitCoordinator initialiser
    /// - Parameter placeholderCoordinator: coordinator to use if no siderbar or detail is set
    init(placeholderCoordinator: CoordinatorProtocol) {
        placeholderModule = NavigationModule(placeholderCoordinator)
    }
    
    /// Set the coordinator to be used on the split's left pannel
    /// - Parameters:
    ///   - coordinator: the sidebar coordinator
    ///   - dismissalCallback: called when this particular sidebar coordinator has removed/replaced
    func setSidebarCoordinator(_ coordinator: (any CoordinatorProtocol)?, dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            sidebarModule = nil
            return
        }
        
        sidebarModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
    }
    
    /// Set the coordinator to be used on the split's right pannel
    /// - Parameters:
    ///   - coordinator: the detail coordinator
    ///   - dismissalCallback: called when this particular detail coordinator has removed/replaced
    func setDetailCoordinator(_ coordinator: (any CoordinatorProtocol)?, dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            detailModule = nil
            return
        }
        
        detailModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
    }
    
    /// Present a sheet on top of the split view
    /// - Parameters:
    ///   - coordinator: the coordinator to display
    ///   - dismissalCallback: called when the sheet has been dismissed, programatically or otherwise
    func setSheetCoordinator(_ coordinator: (any CoordinatorProtocol)?, dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            sheetModule = nil
            return
        }
        
        sheetModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
    }
        
    // MARK: - CoordinatorProtocol
    
    func toPresentable() -> AnyView {
        AnyView(NavigationSplitCoordinatorView(navigationSplitCoordinator: self))
    }
    
    // MARK: - CustomStringConvertible

    var description: String {
        switch (sidebarModule?.coordinator, detailModule?.coordinator) {
        case (.some(let sidebarCoordinator), .some(let detailCoordinator)):
            return "NavigationSplitCoordinator(\(sidebarCoordinator) | \(detailCoordinator))"
        case (.some(let sidebarCoordinator), .none):
            return "NavigationSplitCoordinator(\(sidebarCoordinator) | Empty)"
        case (.none, .some(let detailCoordinator)):
            return "NavigationSplitCoordinator(Empty | \(detailCoordinator))"
        case (.none, .none):
            return "NavigationSplitCoordinator(Empty | Empty)"
        }
    }
    
    // MARK: - Private
    
    private func logPresentationChange(_ change: String, _ module: NavigationModule) {
        MXLog.info("\(self) \(change): \(module.coordinator)")
    }
    
    /// We need to update the compact layout whenever anything changes within the split coordinator or
    /// the navigation coordinators embedded into it
    private func updateCompactLayoutComponents() {
        // First remove all observers
        cancellables.removeAll()
        
        // Start building the new compact layout navigation stack
        var stackModules: [NavigationModule] = []
        // If the sidebar is a stackCoordinator then use it's root as the compact layout root
        // and push its children to the compact layout stack
        if let sidebarNavigationStackCoordinator = sidebarModule?.coordinator as? NavigationStackCoordinator {
            // Observe changes on embedded stackCoordinators and reflect them in the compact layout components
            observe(navigationStackCoordinator: sidebarNavigationStackCoordinator)
            
            if let sidebarRootModule = sidebarNavigationStackCoordinator.rootModule {
                compactLayoutRootModule = sidebarRootModule
            }
            
            stackModules.append(contentsOf: sidebarNavigationStackCoordinator.stackModules)
        } else if let sidebarModule { // Otherwise just use it as a root directly
            compactLayoutRootModule = sidebarModule
        }
        
        // If the detail is a stackCoordinator then push its root and children to the compact layout stack
        if let detailNavigationStackCoordinator = detailModule?.coordinator as? NavigationStackCoordinator {
            // Observe changes on embedded stackCoordinators and reflect them in the compact layout components
            observe(navigationStackCoordinator: detailNavigationStackCoordinator)
            
            if let detailRootCoordinator = detailNavigationStackCoordinator.rootModule {
                stackModules.append(detailRootCoordinator)
            }
            
            stackModules.append(contentsOf: detailNavigationStackCoordinator.stackModules)
        } else if let detailModule { // Otherwise just push it entirely
            stackModules.append(detailModule)
        }
        compactLayoutStackModules = stackModules
        
        // Observe and process compact layout changes
        observeCompactLayoutStackChanges()
    }
        
    /// Changes to the navigation stack while in a compact layout should be
    /// reflected back onto the embedded components e.g. stackCoordinator pops
    private func observeCompactLayoutStackChanges() {
        $compactLayoutStackModules.sink { [weak self] stackModules in
            guard let self, self.compactLayoutStackModules != stackModules else { return }
            
            let diffs = stackModules.difference(from: self.compactLayoutStackModules)
            diffs.forEach { change in
                switch change {
                case .insert:
                    break
                case .remove(_, let module, _):
                    self.processCompactLayoutStackModuleRemoval(module)
                }
            }
        }
        .store(in: &cancellables)
    }
    
    /// Manually process changes to the compact layout navigation stack and update embedded components
    /// We need to either: pop from the detail, nil the detail or pop from the sidebar
    private func processCompactLayoutStackModuleRemoval(_ module: NavigationModule) {
        if let sidebarNavigationStackCoordinator = sidebarModule?.coordinator as? NavigationStackCoordinator {
            if sidebarNavigationStackCoordinator.stackModules.contains(module) {
                sidebarNavigationStackCoordinator.stackModules.removeAll { $0 == module }
            }
        }
        
        if module == detailModule {
            detailModule = nil
        }
        
        if let detailNavigationStackCoordinator = detailModule?.coordinator as? NavigationStackCoordinator {
            if detailNavigationStackCoordinator.stackModules.contains(module) {
                detailNavigationStackCoordinator.stackModules.removeAll { $0 == module }
            } else if module == detailNavigationStackCoordinator.rootModule {
                detailModule = nil
            }
        }
    }
    
    /// Any change to a NavigationStackCoordinator's internal state should be observed and reflected in the
    /// compact layout components
    private func observe(navigationStackCoordinator: NavigationStackCoordinator) {
        navigationStackCoordinator.$rootModule.sink { [weak self] rootModule in
            guard navigationStackCoordinator.rootModule != rootModule else { return }
            DispatchQueue.main.async { self?.updateCompactLayoutComponents() }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.$stackModules.sink { [weak self] stackModules in
            guard navigationStackCoordinator.stackModules != stackModules else { return }
            DispatchQueue.main.async { self?.updateCompactLayoutComponents() }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.$sheetModule.sink { [weak self] sheetModule in
            guard navigationStackCoordinator.sheetModule != sheetModule else { return }
            DispatchQueue.main.async { self?.updateCompactLayoutComponents() }
        }
        .store(in: &cancellables)
    }
}

private struct NavigationSplitCoordinatorView: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var navigationSplitCoordinator: NavigationSplitCoordinator
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                navigationStack
            } else {
                navigationSplitView
            }
        }
        // This needs to be handled on the top level otherwise sheets
        // will be automatically dismissed on hierarchy changes.
        // Embedded NavigationStackCoordinators will present their sheets
        // through the NavigationSplitCoordinator as well.
        .sheet(item: $navigationSplitCoordinator.sheetModule) { module in
            module.coordinator.toPresentable()
        }
    }
    
    /// The NavigationStack that will be used in compact layouts
    var navigationStack: some View {
        NavigationStack(path: $navigationSplitCoordinator.compactLayoutStackModules) {
            navigationSplitCoordinator.compactLayoutRootModule?.coordinator.toPresentable()
                .navigationDestination(for: NavigationModule.self) { module in
                    module.coordinator.toPresentable()
                }
        }
    }
    
    /// The NavigationSplitView that will be used in non-compact layouts
    var navigationSplitView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            if let sidebarModule = navigationSplitCoordinator.sidebarModule {
                sidebarModule.coordinator.toPresentable()
            } else {
                navigationSplitCoordinator.placeholderModule.coordinator.toPresentable()
            }
        } detail: {
            if let detailModule = navigationSplitCoordinator.detailModule {
                detailModule.coordinator.toPresentable()
            } else {
                navigationSplitCoordinator.placeholderModule.coordinator.toPresentable()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .navigationDestination(for: NavigationModule.self) { module in
            module.coordinator.toPresentable()
        }
    }
}

// MARK: - NavigationStackCoordinator

/// Class responsible for displaying a normal "NavigationController" style hierarchy
class NavigationStackCoordinator: ObservableObject, CoordinatorProtocol, CustomStringConvertible {
    private(set) weak var navigationSplitCoordinator: NavigationSplitCoordinator?
    
    @Published fileprivate var rootModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove root", oldValue)
                oldValue.coordinator.stop()
                oldValue.dismissalCallback?()
            }
            
            if let rootModule {
                logPresentationChange("Set root", rootModule)
                rootModule.coordinator.start()
            }
        }
    }
    
    // The stack's current root coordinator
    var rootCoordinator: (any CoordinatorProtocol)? {
        rootModule?.coordinator
    }
    
    @Published fileprivate var sheetModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove sheet", oldValue)
                oldValue.coordinator.stop()
                oldValue.dismissalCallback?()
            }
            
            if let sheetModule {
                logPresentationChange("Set sheet", sheetModule)
                sheetModule.coordinator.start()
            }
        }
    }
    
    var presentationDetents: Set<PresentationDetent> = []
    
    // The currently presented sheet coordinator
    // Sheets will be presented through the NavigationSplitCoordinator if provided
    var sheetCoordinator: (any CoordinatorProtocol)? {
        if let navigationSplitCoordinator {
            return navigationSplitCoordinator.sheetCoordinator
        }
        
        return sheetModule?.coordinator
    }
    
    @Published fileprivate var stackModules = [NavigationModule]() {
        didSet {
            let diffs = stackModules.difference(from: oldValue)
            diffs.forEach { change in
                switch change {
                case .insert(_, let module, _):
                    logPresentationChange("Push", module)
                    module.coordinator.start()
                case .remove(_, let module, _):
                    logPresentationChange("Pop", module)
                    module.coordinator.stop()
                    module.dismissalCallback?()
                }
            }
        }
    }
    
    // The current navigation stack. Excludes the rootCoordinator
    var stackCoordinators: [any CoordinatorProtocol] {
        stackModules.map(\.coordinator)
    }
    
    /// If this NavigationStackCoordinator will be embedded into a NavigationSplitCoordinator pass it here
    /// so that sheet presentations are done through it. Otherwise sheets will not be presented properly
    /// and dismissed automatically in compact layouts
    /// - Parameter navigationSplitCoordinator: The expected parent NavigationSplitCoordinator
    init(navigationSplitCoordinator: NavigationSplitCoordinator? = nil) {
        self.navigationSplitCoordinator = navigationSplitCoordinator
    }
    
    /// Set the coordinator to be used on the stack's root
    /// - Parameters:
    ///   - coordinator: the root coordinator
    ///   - dismissalCallback: called when this root coordinator has removed/replaced
    func setRootCoordinator(_ coordinator: (any CoordinatorProtocol)?, dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            rootModule = nil
            return
        }
        
        popToRoot(animated: false)
        
        rootModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
    }
    
    /// Pushes a new coordinator on the navigation stack
    /// - Parameters:
    ///   - coordinator: the coordinator to be displayed
    ///   - dismissalCallback: called when the coordinator has been popped, programatically or otherwise
    func push(_ coordinator: any CoordinatorProtocol, dismissalCallback: (() -> Void)? = nil) {
        stackModules.append(NavigationModule(coordinator, dismissalCallback: dismissalCallback))
    }
    
    /// Pop all the coordinators from the stack, returning to the root coordinator
    /// - Parameter animated: whether to animate the transition or not. Default is true
    func popToRoot(animated: Bool = true) {
        guard !stackModules.isEmpty else {
            return
        }
        
        if !animated {
            // Disabling animations doesn't work through normal Transactions
            // https://stackoverflow.com/questions/72832243
            UIView.setAnimationsEnabled(false)
        }
        
        stackModules.removeAll()
        
        if !animated {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                UIView.setAnimationsEnabled(true)
            }
        }
    }
    
    /// Removes the last coordinator from the navigation stack
    func pop() {
        stackModules.removeLast()
    }
    
    /// Present a sheet on top of the stack. If this NavigationStackCoordinator is embedded within a NavigationSplitCoordinator
    /// then the presentation will be proxied to the split
    /// - Parameters:
    ///   - coordinator: the coordinator to display
    ///   - dismissalCallback: called when the sheet has been dismissed, programatically or otherwise
    func setSheetCoordinator(_ coordinator: (any CoordinatorProtocol)?, dismissalCallback: (() -> Void)? = nil) {
        if let navigationSplitCoordinator {
            navigationSplitCoordinator.setSheetCoordinator(coordinator, dismissalCallback: dismissalCallback)
            return
        }
        
        guard let coordinator else {
            sheetModule = nil
            return
        }
        
        sheetModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
    }
    
    // MARK: - CoordinatorProtocol
    
    func toPresentable() -> AnyView {
        AnyView(NavigationStackCoordinatorView(navigationStackCoordinator: self)
            .presentationDetents(presentationDetents))
    }
    
    // MARK: - CustomStringConvertible
    
    var description: String {
        if let rootCoordinator = rootModule?.coordinator {
            return "NavigationStackCoordinator(\(rootCoordinator))"
        } else {
            return "NavigationStackCoordinator(Empty)"
        }
    }
    
    // MARK: - Private
    
    private func logPresentationChange(_ change: String, _ module: NavigationModule) {
        MXLog.info("\(self) \(change): \(module.coordinator)")
    }
}

private struct NavigationStackCoordinatorView: View {
    @ObservedObject var navigationStackCoordinator: NavigationStackCoordinator
    
    var body: some View {
        NavigationStack(path: $navigationStackCoordinator.stackModules) {
            navigationStackCoordinator.rootModule?.coordinator.toPresentable()
                .navigationDestination(for: NavigationModule.self) { module in
                    module.coordinator.toPresentable()
                }
        }
        .sheet(item: $navigationStackCoordinator.sheetModule) { module in
            module.coordinator.toPresentable()
        }
    }
}
