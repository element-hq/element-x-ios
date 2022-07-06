//
//  BugReportService.swift
//  ElementX
//
//  Created by Ismail on 16.05.2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation
import GZIP
import MatrixRustSDK
import Sentry
import UIKit

enum BugReportServiceError: Error {
    case invalidBaseUrlString
    case invalidSentryEndpoint
}

class BugReportService: BugReportServiceProtocol {
    private let baseURL: URL
    private let sentryEndpoint: String
    private let applicationId: String
    private let session: URLSession

    init(withBaseUrlString baseUrlString: String,
         sentryEndpoint: String,
         applicationId: String = BuildSettings.bugReportApplicationId,
         session: URLSession = .shared) throws {
        guard let url = URL(string: baseUrlString) else {
            throw BugReportServiceError.invalidBaseUrlString
        }
        guard !sentryEndpoint.isEmpty else {
            throw BugReportServiceError.invalidSentryEndpoint
        }
        baseURL = url
        self.sentryEndpoint = sentryEndpoint
        self.applicationId = applicationId
        self.session = session

        //  enable SentrySDK
        SentrySDK.start { options in
            #if DEBUG
            options.enabled = false
            #endif

            options.dsn = sentryEndpoint

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            options.beforeSend = { event in
                MXLog.error("Sentry detected crash: \(event)")
                return event
            }

            options.onCrashedLastRun = { event in
                MXLog.debug("Sentry detected application was crashed: \(event)")
            }
        }

        //  also enable logging crashes, to send them with bug reports
        MXLogger.logCrashes(true)
        //  set build version for logger
        MXLogger.setBuildVersion(ElementInfoPlist.cfBundleShortVersionString)
    }

    // MARK: - BugReportServiceProtocol

    var crashedLastRun: Bool {
        SentrySDK.crashedLastRun
    }

    func crash() {
        SentrySDK.crash()
    }

    func submitBugReport(text: String,
                         includeLogs: Bool,
                         includeCrashLog: Bool,
                         githubLabels: [String],
                         files: [URL]) async throws -> SubmitBugReportResponse {
        MXLog.debug("[BugReportService] submitBugReport")

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
        }
        return result
    }

    // MARK: - Private

    private var defaultParams: [MultipartFormData] {
        let (localTime, utcTime) = localAndUTCTime(for: Date())
        return [
            MultipartFormData(key: "user_agent", type: .text(value: "iOS")),
            MultipartFormData(key: "app", type: .text(value: applicationId)),
            MultipartFormData(key: "version", type: .text(value: ElementInfoPlist.cfBundleShortVersionString)),
            MultipartFormData(key: "build", type: .text(value: ElementInfoPlist.cfBundleVersion)),
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
        MXLog.debug("[BugReportService] zipFiles: includeLogs: \(includeLogs), includeCrashLog: \(includeCrashLog)")

        var filesToCompress: [URL] = []
        if includeLogs, let logFiles = MXLogger.logFiles() {
            let urls = logFiles.compactMap { URL(fileURLWithPath: $0) }
            filesToCompress.append(contentsOf: urls)
        }
        if includeCrashLog, let crashLogFile = MXLogger.crashLog() {
            filesToCompress.append(URL(fileURLWithPath: crashLogFile))
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

        MXLog.debug("[BugReportService] zipFiles: totalSize: \(totalSize), totalZippedSize: \(totalZippedSize)")

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
