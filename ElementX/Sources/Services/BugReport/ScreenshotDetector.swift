//
//  ScreenshotObserver.swift
//  ElementX
//
//  Created by Ismail on 31.05.2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation
import UIKit
import Photos

enum ScreenshotDetectorError: Error {
    case loadFailed
    case notAuthorized
}

class ScreenshotDetector {

    private var screenshotObserver: Any?
    var callback: ((UIImage?, Error?) -> Void)?
    var autoRequestPHAuthorization = true

    init() {
        screenshotObserver = startObservingScreenshots()
    }

    private func startObservingScreenshots() -> Any {
        return NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification,
                                                      object: nil,
                                                      queue: .main) { [weak self] _ in
            self?.userDidTakeScreenshot()
        }
    }

    private func stopObservingScreenshots() {
        if let observer = screenshotObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        screenshotObserver = nil
    }

    private func userDidTakeScreenshot() {
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if authStatus == .authorized {
            findScreenshot()
        } else if authStatus == .notDetermined && autoRequestPHAuthorization {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                self?.handleAuthStatus(status)
            }
        } else {
            fail(withError: ScreenshotDetectorError.notAuthorized)
        }
    }

    private func handleAuthStatus(_ status: PHAuthorizationStatus) {
        if status == .authorized {
            findScreenshot()
        } else {
            fail(withError: ScreenshotDetectorError.notAuthorized)
        }
    }

    private func findScreenshot() {
        if let asset = PHAsset.fetchLastScreenshot() {
            let imageManager = PHImageManager()
            imageManager.requestImage(for: asset,
                                      targetSize: PHImageManagerMaximumSize,
                                      contentMode: .default,
                                      options: PHImageRequestOptions.highQualitySyncLocal) { [weak self] image, _ in
                guard let image = image else {
                    self?.fail(withError: ScreenshotDetectorError.loadFailed)
                    return
                }
                self?.succeed(withImage: image)
            }
        } else {
            fail(withError: ScreenshotDetectorError.loadFailed)
        }
    }

    deinit {
        stopObservingScreenshots()
    }

    func succeed(withImage image: UIImage) {
        DispatchQueue.main.async {
            self.callback?(image, nil)
        }
    }

    func fail(withError error: Error) {
        DispatchQueue.main.async {
            self.callback?(nil, error)
        }
    }

}

private extension PHAsset {

    static func fetchLastScreenshot() -> PHAsset? {
        let options = PHFetchOptions()

        options.fetchLimit = 1
        options.includeAssetSourceTypes = [.typeUserLibrary]
        options.wantsIncrementalChangeDetails = false
        options.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        return PHAsset.fetchAssets(with: .image, options: options).firstObject
    }
}

private extension PHImageRequestOptions {

    static var highQualitySyncLocal: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = false
        options.isSynchronous = true
        return options
    }
}
