//
//  ScreenshotObserver.swift
//  ElementX
//
//  Created by Ismail on 31.05.2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation
import Photos
import UIKit

enum ScreenshotDetectorError: String, Error {
    case loadFailed
    case notAuthorized
}

@MainActor
class ScreenshotDetector {
    var callback: (@MainActor (UIImage?, Error?) -> Void)?

    /// Flag to whether ask for photos authorization by default if needed.
    var autoRequestPHAuthorization = true

    init() {
        startObservingScreenshots()
    }

    private func startObservingScreenshots() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDidTakeScreenshot),
                                               name: UIApplication.userDidTakeScreenshotNotification,
                                               object: nil)
    }

    @objc private func userDidTakeScreenshot() {
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if authStatus == .authorized {
            findScreenshot()
        } else if authStatus == .notDetermined, autoRequestPHAuthorization {
            Task {
                self.handleAuthStatus(await PHPhotoLibrary.requestAuthorization(for: .readWrite))
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

    func succeed(withImage image: UIImage) {
        callback?(image, nil)
    }

    func fail(withError error: Error) {
        callback?(nil, error)
    }
}

extension PHAsset {

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
