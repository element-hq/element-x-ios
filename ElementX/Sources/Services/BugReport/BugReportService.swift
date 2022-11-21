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

import Foundation
import GZIP
import Sentry
import UIKit

class BugReportService: BugReportServiceProtocol {
    private let baseURL: URL
    private let sentryURL: URL
    private let applicationId: String
    private let session: URLSession
    private var lastCrashEventId: String?
    
    init(withBaseURL baseURL: URL,
         sentryURL: URL,
         applicationId: String = BuildSettings.bugReportApplicationId,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.sentryURL = sentryURL
        self.applicationId = applicationId
        self.session = session
        
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
                MXLog.debug("Sentry detected application was crashed: \(event)")
                self?.lastCrashEventId = event.eventId.sentryIdString
            }
        }

        //  also enable logging crashes, to send them with bug reports
        MXLogger.logCrashes(true)
        //  set build version for logger
        MXLogger.buildVersion = InfoPlistReader.target.bundleShortVersionString
    }

    // MARK: - BugReportServiceProtocol

    var crashedLastRun: Bool {
        SentrySDK.crashedLastRun
    }

    func crash() {
        SentrySDK.crash()
    }

    // swiftlint: disable function_body_length
    func submitBugReport(text: String,
                         includeLogs: Bool,
                         includeCrashLog: Bool,
                         githubLabels: [String],
                         files: [URL]) async throws -> SubmitBugReportResponse {
        MXLog.debug("submitBugReport")

        var params = [
            MultipartFormData(key: "text", type: .text(value: text))
        ]
        params.append(contentsOf: defaultParams)
        for label in githubLabels {
            params.append(MultipartFormData(key: "label", type: .text(value: label)))
        }
        let zippedFiles = try await zipFiles(includeLogs: includeLogs,
                                             includeCrashLog: includeCrashLog)
        //  log or compressed-log
        if !zippedFiles.isEmpty {
            for url in zippedFiles {
                params.append(MultipartFormData(key: "compressed-log", type: .file(url: url)))
            }
        }
        
        if let crashEventId = lastCrashEventId {
            params.append(MultipartFormData(key: "crash_report", type: .text(value: "<https://sentry.tools.element.io/organizations/element/issues/?project=44&query=\(crashEventId)>")))
        }
        
        for url in files {
            params.append(MultipartFormData(key: "file", type: .file(url: url)))
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        for param in params {
            body.appendString(string: "--\(boundary)\r\n")
            body.appendString(string: "Content-Disposition:form-data; name=\"\(param.key)\"")
            switch param.type {
            case .text(let value):
                body.appendString(string: "\r\n\r\n\(value)\r\n")
            case .file(let url):
                body.appendString(string: "; filename=\"\(url.lastPathComponent)\"\r\n")
                body.appendString(string: "Content-Type: \"content-type header\"\r\n\r\n")
                body.append(try Data(contentsOf: url))
                body.appendString(string: "\r\n")
            }
        }
        body.appendString(string: "--\(boundary)--\r\n")

        var request = URLRequest(url: baseURL.appendingPathComponent("submit"))
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "POST"
        request.httpBody = body as Data

        let (data, _) = try await session.data(for: request)

        // Parse the JSON data
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(SubmitBugReportResponse.self, from: data)

        if !result.reportUrl.isEmpty {
            MXLogger.deleteCrashLog()
            lastCrashEventId = nil
        }
        
        return result
    } // swiftlint: enable function_body_length

    // MARK: - Private

    private var defaultParams: [MultipartFormData] {
        let (localTime, utcTime) = localAndUTCTime(for: Date())
        return [
            MultipartFormData(key: "user_agent", type: .text(value: "iOS")),
            MultipartFormData(key: "app", type: .text(value: applicationId)),
            MultipartFormData(key: "version", type: .text(value: InfoPlistReader.target.bundleShortVersionString)),
            MultipartFormData(key: "build", type: .text(value: InfoPlistReader.target.bundleVersion)),
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
        MXLog.debug("zipFiles: includeLogs: \(includeLogs), includeCrashLog: \(includeCrashLog)")

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
            let zippedFileURL = URL(fileURLWithPath: NSTemporaryDirectory())
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

        MXLog.debug("zipFiles: totalSize: \(totalSize), totalZippedSize: \(totalZippedSize)")

        return zippedFiles
    }
}

private extension Data {
    mutating func appendString(string: String, encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
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
