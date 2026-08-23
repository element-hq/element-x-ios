//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

class WindowManager: SecureWindowManagerProtocol {
    private let appDelegate: AppDelegate
    weak var mainScene: UIWindowScene?
    weak var delegate: SecureWindowManagerDelegate?
    
    private(set) var mainWindow: UIWindow!
    private(set) var overlayWindow: UIWindow!
    private(set) var alternateWindow: UIWindow!
    
    private(set) var openWindowAction: OpenWindowAction!
    private(set) var dismissWindowAction: DismissWindowAction!
    
    var secondaryWindowsEnabled = true {
        didSet {
            if secondaryWindowsEnabled == false {
                closeAllSecondaryWindows()
            }
        }
    }
    
    var windows: [UIWindow] {
        [mainWindow, overlayWindow, alternateWindow]
    }
    
    /// The task used to switch windows, so that we don't get stuck in the wrong state with a quick switch.
    @CancellableTask private var switchTask: Task<Void, Error>?
    /// A duration that allows window switching to wait a couple of frames to avoid a transition through black.
    private let windowHideDelay = Duration.milliseconds(33)
    
    private var coordinators: [SecondaryWindowType: (coordinator: CoordinatorProtocol, flowCoordinator: FlowCoordinatorProtocol?)] = [:]
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    func configure(withScene scene: UIWindowScene, session: UISceneSession) {
        // This gets called for all opened windows, we're only interested in the main window.
        guard let userInfo = session.userInfo, userInfo[SceneDelegate.sceneIDKey] as? String == SceneDelegate.mainSceneID else {
            scene.windows.forEach { $0.tintColor = .compound.textActionPrimary } // SecondaryWindow tinting.
            return
        }
        
        // Don't allow more than 1 main window to be presented.
        if mainScene != nil {
            // The window will be presented momentarily, so lets leave it blank.
            scene.keyWindow?.rootViewController = UIHostingController(rootView: Color.clear)
            UIApplication.shared.requestSceneSessionDestruction(session, options: nil)
            return
        }
        
        mainScene = scene
        
        // Restore the previous window size on macOS as this isn't automatic.
        if let previousSize = mainWindow?.frame.size {
            scene.resizeWindowOnMac(to: previousSize)
        }
        
        // `keyWindow` can be nil on iOS 26 until the scene becomes active, but the
        // SwiftUI WindowGroup's window is already attached to the scene by then.
        mainWindow = scene.keyWindow ?? scene.windows.first
        mainWindow.tintColor = .compound.textActionPrimary

        overlayWindow = PassthroughWindow(windowScene: scene)
        overlayWindow.tintColor = .compound.textActionPrimary
        overlayWindow.backgroundColor = .clear
        overlayWindow.isHidden = false

        alternateWindow = UIWindow(windowScene: scene)
        alternateWindow.tintColor = .compound.textActionPrimary

        // Dogfood diagnostics for swallowed taps: log which window received each
        // touch and what it hit-tested to. Strip before upstreaming.
        for (label, window) in [("main", mainWindow), ("overlay", overlayWindow), ("alternate", alternateWindow)] {
            let recognizer = TouchLoggingGestureRecognizer(label: label)
            recognizer.cancelsTouchesInView = false
            recognizer.delaysTouchesBegan = false
            recognizer.delaysTouchesEnded = false
            window?.addGestureRecognizer(recognizer)
        }
        
        // Dogfood diagnostics for the blank-after-background-launch screen (2026-08-23: the
        // room list was hit-testable but not drawn until a background/foreground cycle): name
        // every window's visibility whenever the app comes to the front. Strip before upstreaming.
        for name in [UIApplication.willEnterForegroundNotification, UIApplication.didBecomeActiveNotification] {
            let trigger = name.rawValue
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.logWindowState(trigger: trigger) }
            }
        }
        
        delegate?.windowManagerDidConfigureWindows(self)
    }
    
    private func logWindowState(trigger: String) {
        let sceneState = mainScene.map { String(describing: $0.activationState) } ?? "no scene"
        let sceneWindows = mainScene?.windows.count ?? -1
        let descriptions = zip(["main", "overlay", "alternate"], windows).map { label, window in
            let root = window.rootViewController.map { String(describing: type(of: $0)) } ?? "nil"
            return "\(label)[hidden=\(window.isHidden) alpha=\(window.alpha) key=\(window.isKeyWindow) level=\(window.windowLevel.rawValue) root=\(root) bounds=\(Int(window.bounds.width))x\(Int(window.bounds.height))]"
        }
        MXLog.info("WindowDebug (\(trigger)): scene=\(sceneState) windows=\(sceneWindows) \(descriptions.joined(separator: " "))")
    }
    
    func configure(withOpenWindowAction openWindowAction: OpenWindowAction,
                   dismissWindowAction: DismissWindowAction) {
        self.openWindowAction = openWindowAction
        self.dismissWindowAction = dismissWindowAction
    }
    
    func handleSceneDisconnection(_ scene: UIWindowScene) {
        if scene == mainScene {
            mainScene = nil
            // Leave the mainWindow so we can reapply it's size on macOS.
        }
    }
    
    func handleRoute(_ appRoute: AppRoute, windowType: SecondaryWindowType) {
        MXLog.info("Handling app route: \(appRoute) for window type: \(windowType)")
        
        guard let flowCoordinator = coordinators[windowType]?.flowCoordinator else {
            MXLog.error("Invalid flow coordinator")
            return
        }
        
        flowCoordinator.handleAppRoute(appRoute, animated: true)
    }
    
    func switchToMain() {
        mainWindow.isHidden = false
        overlayWindow.isHidden = false
        
        mainWindow.makeKey()
        
        switchTask = Task {
            // Delay hiding to make sure the main windows are visible.
            try await Task.sleep(for: windowHideDelay)
            
            alternateWindow.isHidden = true
        }
    }
    
    func switchToAlternate() {
        alternateWindow.isHidden = false
        
        // We don't know what route the app will use when returning back
        // to the main window, so end any editing operation now to avoid
        // e.g. the keyboard being displayed on top of a call sheet.
        mainWindow.endEditing(true)
        
        // alternateWindow.isHidden = false cannot got inside the Task otherwise the timing
        // is poor when you lock the phone - you briefly see the main window for a few
        // frames after you've unlocked the phone and then the placeholder animates in.
        switchTask = Task {
            // Delay hiding to make sure the alternate window is visible.
            try await Task.sleep(for: windowHideDelay)
            
            mainWindow.isHidden = true
            overlayWindow.isHidden = true
        }
    }
    
    // MARK: - OrientationManager
    
    func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        mainScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
    }
    
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        appDelegate.orientationLock = orientation
    }
    
    // MARK: - Secondary window support
    
    func windowForType(_ type: SecondaryWindowType) -> AnyView {
        MXLog.info("Requesting window for type: \(type)")
        
        guard let coordinator = coordinators[type]?.coordinator else {
            MXLog.error("Invalid coordinator for window type: \(type)")
            return AnyView(InstantlyDismissingWindow())
        }
        
        // This behaves strangely and gets called late but cleans up enough
        // and is self contained enough to be just good .. enough
        return AnyView(coordinator.toPresentable().onDisappear { [weak self] in
            self?.coordinators[type] = nil
        })
    }
    
    func registerCoordinator(_ coordinator: CoordinatorProtocol, flowCoordinator: FlowCoordinatorProtocol?, forWindowType type: SecondaryWindowType) {
        if secondaryWindowsEnabled == false {
            MXLog.error("Cannot register coordinator, secondary windows are disabled.")
            return
        }
        
        coordinators[type] = (coordinator, flowCoordinator)
        openWindowAction(value: type)
    }
    
    func closeSecondaryWindow(forType type: SecondaryWindowType) {
        dismissWindowAction(value: type)
    }
    
    func closeAllSecondaryWindows() {
        for key in coordinators.keys {
            dismissWindowAction(value: key)
        }
        
        coordinators.removeAll()
    }
}

private class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if #available(iOS 26, *) {
            // Passthrough UIWindow using SwiftUI in iOS 26
            // https://stackoverflow.com/a/79835964/730924
            guard let rootView = rootViewController?.view else {
                return nil
            }
            
            // Special handling for glass buttons
            // ".glass has a layer name of "@1" and and .glassProminent has a layer name of "@2""
            guard let name = rootView.layer.hitTest(point)?.name, !name.starts(with: "@") else {
                return rootView
            }
            
            return nil
        } else {
            guard let hitView = super.hitTest(point, with: event) else {
                return nil
            }
            
            guard let rootViewController else {
                return nil
            }
            
            guard hitView != self else {
                return nil
            }
            
            // If the returned view is the `UIHostingController`'s view, ignore.
            return rootViewController.view == hitView ? nil : hitView
        }
    }
}

/// Whenever restoring an app SwiftUI tries to restore its windows as well
/// which we're generally not prepared for so use this to just close them instead
private struct InstantlyDismissingWindow: View {
    @Environment(\.dismissWindow) var dismissWindow
    
    var body: some View {
        Rectangle()
            .task {
                dismissWindow()
            }
    }
}

private extension UIWindowScene {
    func resizeWindowOnMac(to size: CGSize) {
        // Hackity hack 🔨
        guard ProcessInfo.processInfo.isiOSAppOnMac, let sizeRestrictions else { return }
        
        self.sizeRestrictions?.minimumSize = size
        self.sizeRestrictions?.maximumSize = size
        
        Task {
            try await Task.sleep(for: .milliseconds(100))
            self.sizeRestrictions?.minimumSize = sizeRestrictions.minimumSize
            self.sizeRestrictions?.maximumSize = sizeRestrictions.maximumSize
        }
    }
}

/// Dogfood diagnostics: observes (never recognises, never cancels) every touch
/// delivered to its window and logs where it landed, so a swallowed tap names
/// the window and view that consumed it. Strip before upstreaming.
private final class TouchLoggingGestureRecognizer: UIGestureRecognizer {
    private let label: String

    init(label: String) {
        self.label = label
        super.init(target: nil, action: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first, let window = view else { return }

        let point = touch.location(in: window)
        let hitView = window.hitTest(point, with: event)
        let hitDescription = hitView.map { String(describing: type(of: $0)) } ?? "nil"
        let responder = (touch.view).map { String(describing: type(of: $0)) } ?? "nil"
        MXLog.info("TouchDebug[\(label)]: began at \(Int(point.x)),\(Int(point.y)) hit=\(hitDescription) touchView=\(responder) interactive=\(window.isUserInteractionEnabled)")

        // Rageshake 7549: the timeline stopped responding to drags (programmatic
        // scrolls still worked) until a scroll-to-bottom tap; the log could only
        // show touches landing on cells with no drag ever beginning. Name the
        // likely culprits when it recurs: recognisers already mid-gesture
        // anywhere in the window (a stale one blocks every non-simultaneous
        // recogniser below it), the hit scroll view's own state, and ancestors
        // mid-animation (UIView animations eat touches without
        // .allowUserInteraction).
        var active = [String]()
        var stack: [UIView] = [window]
        while let view = stack.popLast() {
            for recognizer in view.gestureRecognizers ?? [] where recognizer !== self {
                switch recognizer.state {
                case .began, .changed:
                    active.append("\(type(of: recognizer))@\(type(of: view)):\(recognizer.state.rawValue)")
                default:
                    break
                }
            }
            stack.append(contentsOf: view.subviews)
        }
        var scroll = ""
        var animating = [String]()
        var ancestor = hitView
        while let current = ancestor {
            if scroll.isEmpty, let scrollView = current as? UIScrollView {
                scroll = "\(type(of: scrollView)) enabled=\(scrollView.isScrollEnabled) tracking=\(scrollView.isTracking) dragging=\(scrollView.isDragging) decelerating=\(scrollView.isDecelerating) pan=\(scrollView.panGestureRecognizer.state.rawValue)/\(scrollView.panGestureRecognizer.isEnabled) content=\(Int(scrollView.contentSize.height)) bounds=\(Int(scrollView.bounds.height)) offset=\(Int(scrollView.contentOffset.y))"
            }
            if let keys = current.layer.animationKeys(), !keys.isEmpty {
                animating.append("\(type(of: current)):\(keys.joined(separator: ","))")
            }
            ancestor = current.superview
        }
        if !active.isEmpty || !animating.isEmpty || scroll.contains("tracking=true") || scroll.contains("dragging=true") {
            MXLog.info("TouchDebug[\(label)]: active=\(active) scroll=[\(scroll)] animating=\(animating)")
        }
    }
}
