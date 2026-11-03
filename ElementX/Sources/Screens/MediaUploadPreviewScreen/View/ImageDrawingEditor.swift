//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import QuickLook
import SwiftUI

/// Draws on a copy of a picture with QuickLook's Markup. Save writes the drawing back into the picture, Cancel throws it away.
struct ImageDrawingEditor: UIViewControllerRepresentable {
    let imageURL: URL
    /// Called when the picture on disk has the saved drawing.
    let onDrawing: () -> Void
    /// Called when Save is tapped, which can be before the drawing lands: QuickLook may only write it once the editor is gone.
    let onSave: () -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        previewController.delegate = context.coordinator
        previewController.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { _ in onCancel() })
        previewController.navigationItem.rightBarButtonItem = Self.makeSaveButton(primaryAction: UIAction { [coordinator = context.coordinator] _ in
            coordinator.save()
            onSave()
        })
        return UINavigationController(rootViewController: previewController)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) { }
    
    /// Matches `ToolbarButton(role: .save)`: Compound's check on the accent colour, or the plain title before iOS 26.
    private static func makeSaveButton(primaryAction: UIAction) -> UIBarButtonItem {
        primaryAction.title = L10n.actionSave
        let button = UIBarButtonItem(primaryAction: primaryAction)
        guard #available(iOS 26, *) else {
            button.style = .done
            return button
        }
        // Compound's icons only come as SwiftUI images.
        let renderer = ImageRenderer(content: CompoundIcon(\.check))
        renderer.scale = 3
        primaryAction.image = renderer.uiImage?.withRenderingMode(.alwaysTemplate)
        button.primaryAction = primaryAction
        button.style = .prominent
        button.tintColor = .compound.bgAccentRest
        return button
    }
    
    static func dismantleUIViewController(_ uiViewController: UINavigationController, coordinator: Coordinator) {
        coordinator.finish()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(imageURL: imageURL, onDrawing: onDrawing)
    }
    
    final class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate, NSFilePresenter {
        private let imageURL: URL
        private let copyURL: URL?
        private let onDrawing: () -> Void
        private var copyModificationDate: Date?
        private var isSaving = false
        
        nonisolated let presentedItemURL: URL?
        nonisolated var presentedItemOperationQueue: OperationQueue {
            .main
        }
        
        init(imageURL: URL, onDrawing: @escaping () -> Void) {
            self.imageURL = imageURL
            self.onDrawing = onDrawing
            copyURL = Self.makeCopy(of: imageURL)
            presentedItemURL = copyURL
            copyModificationDate = copyURL.flatMap(Self.modificationDate(ofFileAt:))
            super.init()
            NSFileCoordinator.addFilePresenter(self)
        }
        
        func save() {
            isSaving = true
            saveDrawingIfCopyChanged()
        }
        
        /// Closing while still in Markup writes the drawing into the copy after the editor is gone, without calling the delegate,
        /// so keep watching the copy for a little while.
        func finish() {
            Task {
                try? await Task.sleep(for: .seconds(5))
                NSFileCoordinator.removeFilePresenter(self)
                if let copyURL {
                    try? FileManager.default.removeItem(at: copyURL.deletingLastPathComponent())
                }
            }
        }
        
        // MARK: QLPreviewControllerDataSource
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            (copyURL ?? imageURL) as NSURL
        }
        
        // MARK: QLPreviewControllerDelegate
        
        func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
            copyURL == nil ? .disabled : .updateContents
        }
        
        /// QuickLook calls this from a background queue.
        nonisolated func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: QLPreviewItem) {
            Task { @MainActor [weak self] in
                self?.saveDrawingIfCopyChanged()
            }
        }
        
        // MARK: NSFilePresenter
        
        nonisolated func presentedItemDidChange() {
            Task { @MainActor [weak self] in
                self?.saveDrawingIfCopyChanged()
            }
        }
        
        // MARK: Private
        
        private func saveDrawingIfCopyChanged() {
            guard isSaving, let copyURL else { return }
            let newModificationDate = Self.modificationDate(ofFileAt: copyURL)
            guard newModificationDate != copyModificationDate else { return }
            copyModificationDate = newModificationDate
            
            do {
                try Data(contentsOf: copyURL).write(to: imageURL, options: .atomic)
                onDrawing()
            } catch {
                MXLog.error("Failed saving the drawing with error: \(error)")
            }
        }
        
        private static func makeCopy(of url: URL) -> URL? {
            let directory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)
            let copyURL = directory.appending(component: url.lastPathComponent)
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: url, to: copyURL)
                return copyURL
            } catch {
                MXLog.error("Failed copying the picture to draw on with error: \(error)")
                return nil
            }
        }
        
        private static func modificationDate(ofFileAt url: URL) -> Date? {
            try? FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))[.modificationDate] as? Date
        }
    }
}
