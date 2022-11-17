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

class NavigationController: ObservableObject, CoordinatorProtocol {
    private var dismissalCallbacks = [UUID: () -> Void]()
    
    @Published fileprivate var internalRootCoordinator: AnyCoordinator? {
        didSet {
            if let oldValue {
                oldValue.coordinator.stop()
            }
            
            if let internalRootCoordinator {
                logPresentationChange("Set root", internalRootCoordinator)
                internalRootCoordinator.coordinator.start()
            }
        }
    }
    
    @Published fileprivate var internalSheetCoordinator: AnyCoordinator? {
        didSet {
            if let oldValue {
                logPresentationChange("Dismiss", oldValue)
                oldValue.coordinator.stop()
                dismissalCallbacks[oldValue.id]?()
                dismissalCallbacks.removeValue(forKey: oldValue.id)
            }
            
            if let internalSheetCoordinator {
                logPresentationChange("Present", internalSheetCoordinator)
                internalSheetCoordinator.coordinator.start()
            }
        }
    }
    
    @Published fileprivate var internalNavigationStack = [AnyCoordinator]() {
        didSet {
            let diffs = internalNavigationStack.difference(from: oldValue)
            diffs.forEach { change in
                switch change {
                case .insert(_, let anyCoordinator, _):
                    logPresentationChange("Push", anyCoordinator)
                    anyCoordinator.coordinator.start()
                case .remove(_, let anyCoordinator, _):
                    logPresentationChange("Pop", anyCoordinator)
                    anyCoordinator.coordinator.stop()
                    
                    dismissalCallbacks[anyCoordinator.id]?()
                    dismissalCallbacks.removeValue(forKey: anyCoordinator.id)
                }
            }
        }
    }
    
    var rootCoordinator: CoordinatorProtocol? {
        internalRootCoordinator?.coordinator
    }
    
    var coordinators: [CoordinatorProtocol] {
        internalNavigationStack.map(\.coordinator)
    }
    
    var sheetCoordinator: CoordinatorProtocol? {
        internalSheetCoordinator?.coordinator
    }
    
    func setRootCoordinator(_ coordinator: any CoordinatorProtocol) {
        popToRoot(animated: false)
        internalRootCoordinator = AnyCoordinator(coordinator)
    }
    
    func push(_ coordinator: any CoordinatorProtocol, dismissalCallback: (() -> Void)? = nil) {
        let anyCoordinator = AnyCoordinator(coordinator)
        
        if let dismissalCallback {
            dismissalCallbacks[anyCoordinator.id] = dismissalCallback
        }
        
        internalNavigationStack.append(anyCoordinator)
    }
    
    func popToRoot(animated: Bool = true) {
        dismissSheet()
        
        guard !internalNavigationStack.isEmpty else {
            return
        }
        
        if !animated {
            // Disabling animations doesn't work through normal Transactions
            // https://stackoverflow.com/questions/72832243
            UIView.setAnimationsEnabled(false)
        }
        
        internalNavigationStack.removeAll()
        
        if !animated {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                UIView.setAnimationsEnabled(true)
            }
        }
    }
    
    func pop() {
        dismissSheet()
        internalNavigationStack.removeLast()
    }
    
    func presentSheet(_ coordinator: any CoordinatorProtocol, dismissalCallback: (() -> Void)? = nil) {
        let anyCoordinator = AnyCoordinator(coordinator)
        
        if let dismissalCallback {
            dismissalCallbacks[anyCoordinator.id] = dismissalCallback
        }
        
        internalSheetCoordinator = anyCoordinator
    }
    
    func dismissSheet() {
        internalSheetCoordinator = nil
    }
    
    // MARK: - CoordinatorProtocol
    
    func toPresentable() -> AnyView {
        AnyView(NavigationControllerView(navigationController: self))
    }
    
    // MARK: - Private
    
    private func logPresentationChange(_ change: String, _ anyCoordinator: AnyCoordinator) {
        if let navigationCoordinator = anyCoordinator.coordinator as? NavigationController, let rootCoordinator = navigationCoordinator.rootCoordinator {
            MXLog.info("\(change): NavigationController(\(anyCoordinator.id)) - \(rootCoordinator)")
        } else {
            MXLog.info("\(change): \(anyCoordinator.coordinator)(\(anyCoordinator.id))")
        }
    }
}

private struct NavigationControllerView: View {
    @ObservedObject var navigationController: NavigationController
    
    var body: some View {
        NavigationStack(path: $navigationController.internalNavigationStack) {
            navigationController.internalRootCoordinator?.coordinator.toPresentable()
                .navigationDestination(for: AnyCoordinator.self) { anyCoordinator in
                    anyCoordinator.coordinator.toPresentable()
                }
        }
        .sheet(item: $navigationController.internalSheetCoordinator) { anyCoordinator in
            anyCoordinator.coordinator.toPresentable()
        }
    }
}

private struct AnyCoordinator: Identifiable, Hashable {
    let id = UUID()
    let coordinator: any CoordinatorProtocol
    
    init(_ coordinator: any CoordinatorProtocol) {
        self.coordinator = coordinator
    }
    
    static func == (lhs: AnyCoordinator, rhs: AnyCoordinator) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
