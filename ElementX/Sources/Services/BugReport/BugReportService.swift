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
import Foundation
import GZIP
import Sentry
import UIKit

class BugReportService: NSObject, BugReportServiceProtocol {
    private let baseURL: URL
    private let sentryURL: URL
    private let applicationId: String
    private let maxUploadSize: Int
    private let session: URLSession
    private var lastCrashEventId: String?
    private let progressSubject = PassthroughSubject<Double, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init(withBaseURL baseURL: URL,
         sentryURL: URL,
         applicationId: String = ServiceLocator.shared.settings.bugReportApplicationId,
         maxUploadSize: Int = ServiceLocator.shared.settings.bugReportMaxUploadSize,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.sentryURL = sentryURL
        self.applicationId = applicationId
        self.maxUploadSize = maxUploadSize
        self.session = session
        super.init()
        
        //  set build version for logger
        MXLogger.buildVersion = InfoPlistReader.main.bundleShortVersionString
    }

    // MARK: - BugReportServiceProtocol

    var isRunning: Bool {
        SentrySDK.isEnabled
    }
    
    var crashedLastRun: Bool {
        SentrySDK.crashedLastRun
    }
    
    func start() {
        guard !isRunning else { return }
        SentrySDK.start { options in
            #if DEBUG
            options.enabled = false
            #endif
            options.dsn = self.sentryURL.absoluteString

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            options.beforeSend = { event in
                MXLog.error("Sentry detected crash: \(event)")
                return event
            }

            options.onCrashedLastRun = { [weak self] event in
                MXLog.error("Sentry detected application was crashed: \(event)")
                self?.lastCrashEventId = event.eventId.sentryIdString
            }
        }
        MXLogger.logCrashes(true)
        MXLog.info("Started.")
    }
           
    func stop() {
        guard isRunning else { return }
        SentrySDK.close()
        MXLogger.logCrashes(false)
        MXLog.info("Stopped.")
    }
    
    func reset() {
        lastCrashEventId = nil
        MXLog.info("Reset.")
    }
    
    func crash() {
        SentrySDK.crash()
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func submitBugReport(_ bugReport: BugReport,
                         progressListener: ProgressListener?) async -> Result<SubmitBugReportResponse, BugReportServiceError> {
        var params = [
            MultipartFormData(key: "user_id", type: .text(value: bugReport.userID)),
            MultipartFormData(key: "text", type: .text(value: bugReport.text))
        ]
        
        if let deviceID = bugReport.deviceID {
            params.append(.init(key: "device_id", type: .text(value: deviceID)))
        }
        
        params.append(contentsOf: defaultParams)
        
        for label in bugReport.githubLabels {
            params.append(MultipartFormData(key: "label", type: .text(value: label)))
        }
        let logAttachments = await zipFiles(includeLogs: bugReport.includeLogs,
                                            includeCrashLog: bugReport.includeCrashLog)
        
        for url in logAttachments.files {
            params.append(MultipartFormData(key: "compressed-log", type: .file(url: url)))
        }
        
        if let crashEventId = lastCrashEventId {
            params.append(MultipartFormData(key: "crash_report", type: .text(value: "<https://sentry.tools.element.io/organizations/element/issues/?project=44&query=\(crashEventId)>")))
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

        var delegate: URLSessionTaskDelegate?
        if let progressListener {
            progressSubject
                .receive(on: DispatchQueue.main)
                .weakAssign(to: \.value, on: progressListener.progressSubject)
                .store(in: &cancellables)
            delegate = self
        }
        
        do {
            let (data, response) = try await session.dataWithRetry(for: request, delegate: delegate)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let errorDescription = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
                MXLog.error("Failed to submit bug report: \(errorDescription)")
                MXLog.error("Response: \(response)")
                return .failure(.serverError(response, errorDescription))
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorDescription = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
                MXLog.error("Failed to submit bug report: \(errorDescription) (\(httpResponse.statusCode))")
                MXLog.error("Response: \(httpResponse)")
                return .failure(.httpError(httpResponse, errorDescription))
            }
            
            // Parse the JSON data
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let uploadResponse = try decoder.decode(SubmitBugReportResponse.self, from: data)
            
            if !uploadResponse.reportUrl.isEmpty {
                MXLogger.deleteCrashLog()
                lastCrashEventId = nil
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
            MultipartFormData(key: "os", type: .text(value: os)),
            MultipartFormData(key: "resolved_languages", type: .text(value: Bundle.app.preferredLocalizations.joined(separator: ", "))),
            MultipartFormData(key: "user_languages", type: .text(value: Locale.preferredLanguages.joined(separator: ", "))),
            MultipartFormData(key: "fallback_language", type: .text(value: Bundle.app.developmentLocalization ?? "null")),
            MultipartFormData(key: "local_time", type: .text(value: localTime)),
            MultipartFormData(key: "utc_time", type: .text(value: utcTime)),
            MultipartFormData(key: "base_bundle_identifier", type: .text(value: InfoPlistReader.main.baseBundleIdentifier))
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

    private func zipFiles(includeLogs: Bool,
                          includeCrashLog: Bool) async -> Logs {
        MXLog.info("zipFiles: includeLogs: \(includeLogs), includeCrashLog: \(includeCrashLog)")

        var filesToCompress: [URL] = []
        if includeLogs {
            filesToCompress.append(contentsOf: MXLogger.logFiles)
        }
        if includeCrashLog, let crashLogFile = MXLogger.crashLog {
            filesToCompress.append(crashLogFile)
        }
        
        var compressedLogs = Logs(maxFileSize: maxUploadSize)
        
        for url in filesToCompress {
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
        
        var chunkIndex = -1
        while let data = try fileHandle.read(upToCount: 10 * 1024 * 1024) {
            do {
                chunkIndex += 1
                if let zippedData = (data as NSData).gzipped() {
                    let zippedFilename = url.deletingPathExtension().lastPathComponent + "_\(chunkIndex).log"
                    let chunkURL = URL.temporaryDirectory.appending(path: zippedFilename)
                    
                    // Remove old zipped file if exists
                    try? FileManager.default.removeItem(at: chunkURL)
                    
                    try zippedData.write(to: chunkURL)
                    zippedFiles.appendFile(at: chunkURL, zippedSize: zippedData.count, originalSize: data.count)
                }
            } catch {
                MXLog.error("Failed attaching log chunk \(chunkIndex) from (\(url.lastPathComponent)")
                continue
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

extension URLSession {
    /// The same as `data(for:delegate:)` but with an additional immediate retry if the first attempt fails.
    func dataWithRetry(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        if let firstTryResult = try? await data(for: request, delegate: delegate) {
            return firstTryResult
        }
        
        return try await data(for: request, delegate: delegate)
    }
}
