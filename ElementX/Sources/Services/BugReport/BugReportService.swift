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
    private let session: URLSession
    private var lastCrashEventId: String?
    private let progressSubject = PassthroughSubject<Double, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init(withBaseURL baseURL: URL,
         sentryURL: URL,
         applicationId: String = ServiceLocator.shared.settings.bugReportApplicationId,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.sentryURL = sentryURL
        self.applicationId = applicationId
        self.session = session
        super.init()
        
        //  enable SentrySDK
        SentrySDK.start { options in
            #if DEBUG
            options.enabled = false
            #endif

            options.dsn = sentryURL.absoluteString

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

        //  also enable logging crashes, to send them with bug reports
        MXLogger.logCrashes(true)
        //  set build version for logger
        MXLogger.buildVersion = InfoPlistReader.main.bundleShortVersionString
    }

    // MARK: - BugReportServiceProtocol

    var crashedLastRun: Bool {
        SentrySDK.crashedLastRun
    }

    func crash() {
        SentrySDK.crash()
    }

    // swiftlint:disable:next function_body_length
    func submitBugReport(_ bugReport: BugReport, progressListener: ProgressListener?) async throws -> SubmitBugReportResponse {
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
        let zippedFiles = try await zipFiles(includeLogs: bugReport.includeLogs,
                                             includeCrashLog: bugReport.includeCrashLog)
        //  log or compressed-log
        if !zippedFiles.isEmpty {
            for url in zippedFiles {
                params.append(MultipartFormData(key: "compressed-log", type: .file(url: url)))
            }
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
            try body.appendParam(param, boundary: boundary)
        }
        body.appendString(string: "--\(boundary)--\r\n")

        var request = URLRequest(url: baseURL.appendingPathComponent("submit"))
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "POST"
        request.httpBody = body as Data

        let data: Data
        if let progressListener {
            progressSubject
                .receive(on: DispatchQueue.main)
                .weakAssign(to: \.value, on: progressListener.progressSubject)
                .store(in: &cancellables)
            (data, _) = try await session.data(for: request, delegate: self)
        } else {
            (data, _) = try await session.data(for: request)
        }

        // Parse the JSON data
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(SubmitBugReportResponse.self, from: data)

        if !result.reportUrl.isEmpty {
            MXLogger.deleteCrashLog()
            lastCrashEventId = nil
        }
        
        MXLog.info("Feedback submitted.")
        
        return result
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
            MultipartFormData(key: "resolved_language", type: .text(value: Bundle.preferredLanguages[0])),
            MultipartFormData(key: "user_language", type: .text(value: Bundle.elementLanguage ?? "null")),
            MultipartFormData(key: "fallback_language", type: .text(value: Bundle.elementFallbackLanguage ?? "null")),
            MultipartFormData(key: "local_time", type: .text(value: localTime)),
            MultipartFormData(key: "utc_time", type: .text(value: utcTime))
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
                          includeCrashLog: Bool) async throws -> [URL] {
        MXLog.info("zipFiles: includeLogs: \(includeLogs), includeCrashLog: \(includeCrashLog)")

        var filesToCompress: [URL] = []
        if includeLogs {
            filesToCompress.append(contentsOf: MXLogger.logFiles)
        }
        if includeCrashLog, let crashLogFile = MXLogger.crashLog {
            filesToCompress.append(crashLogFile)
        }

        var totalSize = 0
        var totalZippedSize = 0
        var zippedFiles: [URL] = []

        for url in filesToCompress {
            let zippedFileURL = URL.temporaryDirectory
                .appendingPathComponent(url.lastPathComponent)

            //  remove old zipped file if exists
            try? FileManager.default.removeItem(at: zippedFileURL)

            let rawData = try Data(contentsOf: url)
            if rawData.isEmpty {
                continue
            }
            guard let zippedData = (rawData as NSData).gzipped() else {
                continue
            }

            totalSize += rawData.count
            totalZippedSize += zippedData.count

            try zippedData.write(to: zippedFileURL)

            zippedFiles.append(zippedFileURL)
        }

        MXLog.info("zipFiles: totalSize: \(totalSize), totalZippedSize: \(totalZippedSize)")

        return zippedFiles
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
            append(try Data(contentsOf: url))
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
