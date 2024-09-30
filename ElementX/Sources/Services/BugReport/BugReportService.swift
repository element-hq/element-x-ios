//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import GZIP
import Sentry
import UIKit

class BugReportService: NSObject, BugReportServiceProtocol {
    private let baseURL: URL
    private let applicationId: String
    private let sdkGitSHA: String
    private let maxUploadSize: Int
    private let session: URLSession
    
    private let appHooks: AppHooks
    
    private let progressSubject = PassthroughSubject<Double, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    var lastCrashEventID: String?
    
    init(withBaseURL baseURL: URL,
         applicationId: String,
         sdkGitSHA: String,
         maxUploadSize: Int,
         session: URLSession = .shared,
         appHooks: AppHooks) {
        self.baseURL = baseURL
        self.applicationId = applicationId
        self.sdkGitSHA = sdkGitSHA
        self.maxUploadSize = maxUploadSize
        self.session = session
        self.appHooks = appHooks
        super.init()
    }

    // MARK: - BugReportServiceProtocol
    
    var crashedLastRun: Bool {
        SentrySDK.crashedLastRun
    }
        
    // swiftlint:disable:next cyclomatic_complexity
    func submitBugReport(_ bugReport: BugReport,
                         progressListener: CurrentValueSubject<Double, Never>) async -> Result<SubmitBugReportResponse, BugReportServiceError> {
        let bugReport = appHooks.bugReportHook.update(bugReport)
        
        var params = [
            MultipartFormData(key: "text", type: .text(value: bugReport.text)),
            MultipartFormData(key: "can_contact", type: .text(value: "\(bugReport.canContact)"))
        ]
        
        if let userID = bugReport.userID {
            params.append(.init(key: "user_id", type: .text(value: userID)))
        }
        
        if let deviceID = bugReport.deviceID {
            params.append(.init(key: "device_id", type: .text(value: deviceID)))
        }
        
        if let ed25519 = bugReport.ed25519, let curve25519 = bugReport.curve25519 {
            let compactKeys = "curve25519:\(curve25519), ed25519:\(ed25519)"
            params.append(.init(key: "device_keys", type: .text(value: compactKeys)))
        }
        
        params.append(contentsOf: defaultParams)
        
        for label in bugReport.githubLabels {
            params.append(MultipartFormData(key: "label", type: .text(value: label)))
        }
        
        if bugReport.includeLogs {
            let logAttachments = await zipFiles(RustTracing.logFiles)
            for url in logAttachments.files {
                params.append(MultipartFormData(key: "compressed-log", type: .file(url: url)))
            }
        }
        
        if let crashEventID = lastCrashEventID {
            params.append(MultipartFormData(key: "crash_report", type: .text(value: "<https://sentry.tools.element.io/organizations/element/issues/?project=44&query=\(crashEventID)>")))
        }
        
        for url in bugReport.files {
            params.append(MultipartFormData(key: "file", type: .file(url: url)))
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        for param in params {
            do {
                try body.appendParam(param, boundary: boundary)
            } catch {
                MXLog.error("Failed to attach parameter at \(param.key)")
                // Continue to the next parameter and try to submit something.
            }
        }
        body.appendString(string: "--\(boundary)--\r\n")

        var request = URLRequest(url: baseURL.appendingPathComponent("submit"))
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "POST"
        request.httpBody = body as Data

        progressSubject
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.value, on: progressListener)
            .store(in: &cancellables)
        
        do {
            let (data, response) = try await session.dataWithRetry(for: request, delegate: self)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let errorDescription = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
                MXLog.error("Failed to submit bug report: \(errorDescription)")
                MXLog.error("Response: \(response)")
                return .failure(.serverError(response, errorDescription))
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorDescription = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
                MXLog.error("Failed to submit bug report: \(errorDescription) (\(httpResponse.statusCode))")
                MXLog.error("Response: \(httpResponse)")
                return .failure(.httpError(httpResponse, errorDescription))
            }
            
            // Parse the JSON data
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let uploadResponse = try decoder.decode(SubmitBugReportResponse.self, from: data)
            
            if !uploadResponse.reportUrl.isEmpty {
                lastCrashEventID = nil
            }
            
            MXLog.info("Feedback submitted.")
            
            return .success(uploadResponse)
        } catch {
            return .failure(.uploadFailure(error))
        }
    }

    // MARK: - Private

    private var defaultParams: [MultipartFormData] {
        let (localTime, utcTime) = localAndUTCTime(for: Date())
        return [
            MultipartFormData(key: "user_agent", type: .text(value: "iOS")),
            MultipartFormData(key: "app", type: .text(value: applicationId)),
            MultipartFormData(key: "version", type: .text(value: InfoPlistReader.main.bundleShortVersionString)),
            MultipartFormData(key: "build", type: .text(value: InfoPlistReader.main.bundleVersion)),
            MultipartFormData(key: "sdk_sha", type: .text(value: sdkGitSHA)),
            MultipartFormData(key: "os", type: .text(value: os)),
            MultipartFormData(key: "resolved_languages", type: .text(value: Bundle.app.preferredLocalizations.joined(separator: ", "))),
            MultipartFormData(key: "user_languages", type: .text(value: Locale.preferredLanguages.joined(separator: ", "))),
            MultipartFormData(key: "fallback_language", type: .text(value: Bundle.app.developmentLocalization ?? "null")),
            MultipartFormData(key: "local_time", type: .text(value: localTime)),
            MultipartFormData(key: "utc_time", type: .text(value: utcTime)),
            MultipartFormData(key: "base_bundle_identifier", type: .text(value: InfoPlistReader.main.baseBundleIdentifier)),
            MultipartFormData(key: "rust_tracing_filter", type: .text(value: RustTracing.currentTracingConfiguration?.filter ?? "null"))
        ]
    }

    private func localAndUTCTime(for date: Date) -> (String, String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let localTime = dateFormatter.string(from: date)
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let utcTime = dateFormatter.string(from: date)
        return (localTime, utcTime)
    }

    private var os: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }

    private func zipFiles(_ logFiles: [URL]) async -> Logs {
        MXLog.info("zipFiles")
        
        var compressedLogs = Logs(maxFileSize: maxUploadSize)
        
        for url in logFiles {
            do {
                try attachFile(at: url, to: &compressedLogs)
            } catch {
                MXLog.error("Failed to compress log at \(url)")
                // Continue so that other logs can still be sent.
            }
        }
        
        MXLog.info("zipFiles: originalSize: \(compressedLogs.originalSize), zippedSize: \(compressedLogs.zippedSize)")

        return compressedLogs
    }
    
    /// Zips a file creating chunks based on 10MB inputs.
    private func attachFile(at url: URL, to zippedFiles: inout Logs) throws {
        let fileHandle = try FileHandle(forReadingFrom: url)
        
        while let data = try fileHandle.readToEnd() {
            if let zippedData = (data as NSData).gzipped() {
                let zippedURL = URL.temporaryDirectory.appending(path: url.lastPathComponent)
                
                // Remove old zipped file if exists
                try? FileManager.default.removeItem(at: zippedURL)
                
                try zippedData.write(to: zippedURL)
                zippedFiles.appendFile(at: zippedURL, zippedSize: zippedData.count, originalSize: data.count)
            }
        }
    }
    
    /// A collection of logs to be uploaded to the bug report service.
    struct Logs {
        /// The maximum total size of all the files.
        let maxFileSize: Int
        
        /// The files included.
        private(set) var files: [URL] = []
        /// The total size of the files after compression.
        private(set) var zippedSize = 0
        /// The original size of the files.
        private(set) var originalSize = 0
        
        mutating func appendFile(at url: URL, zippedSize: Int, originalSize: Int) {
            guard self.zippedSize + zippedSize < maxFileSize else {
                MXLog.error("Logs too large, skipping attachment: \(url.lastPathComponent)")
                return
            }
            files.append(url)
            self.originalSize += originalSize
            self.zippedSize += zippedSize
        }
    }
}

private extension Data {
    mutating func appendString(string: String, encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }

    mutating func appendParam(_ param: MultipartFormData, boundary: String) throws {
        appendString(string: "--\(boundary)\r\n")
        appendString(string: "Content-Disposition:form-data; name=\"\(param.key)\"")
        switch param.type {
        case .text(let value):
            appendString(string: "\r\n\r\n\(value)\r\n")
        case .file(let url):
            appendString(string: "; filename=\"\(url.lastPathComponent)\"\r\n")
            appendString(string: "Content-Type: \"content-type header\"\r\n\r\n")
            try append(Data(contentsOf: url))
            appendString(string: "\r\n")
        }
    }
}

private struct MultipartFormData {
    let key: String
    let type: MultipartFormDataType
}

private enum MultipartFormDataType {
    case text(value: String)
    case file(url: URL)
}

extension BugReportService: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        task.progress.publisher(for: \.fractionCompleted)
            .sink { [weak self] value in
                self?.progressSubject.send(value)
            }
            .store(in: &cancellables)
    }
}
