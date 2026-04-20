#!/usr/bin/env swift
//
// analyze-xcresult.swift
// Usage: swift analyze-xcresult.swift <path-to.xcresult> [--last N]
//
// Extracts failing tests, failure messages, file/line locations, and the
// XCUITest activity log from an xcresult bundle via xcresulttool.
//

import Foundation

// MARK: - xcresulttool wrapper

func runXcresulttool(xcresultPath: String, objectID: String? = nil) -> [String: Any]? {
    var arguments = ["xcrun", "xcresulttool", "get", "object", "--legacy",
                     "--path", xcresultPath, "--format", "json"]
    if let objectID {
        arguments += ["--id", objectID]
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = arguments

    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    try? process.run()

    // Read stderr concurrently to prevent the process deadlocking when its error
    // buffer fills up (which blocks stdout writes, causing readDataToEndOfFile to hang).
    let stderrQueue = DispatchQueue(label: "xcresulttool.stderr")
    stderrQueue.async { _ = errorPipe.fileHandleForReading.readDataToEndOfFile() }

    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else { return nil }
    return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
}

// MARK: - xcresult JSON navigation
//
// Every value in xcresult JSON is boxed: { "_type": {...}, "_value": "…" }
// Arrays use:                           { "_type": {...}, "_values": […] }

func xcString(_ node: [String: Any], _ key: String) -> String? {
    (node[key] as? [String: Any])?["_value"] as? String
}

func xcChildren(_ node: [String: Any], _ key: String) -> [[String: Any]] {
    (node[key] as? [String: Any])?["_values"] as? [[String: Any]] ?? []
}

func xcChild(_ node: [String: Any], _ key: String) -> [String: Any]? {
    node[key] as? [String: Any]
}

// MARK: - Activity log

struct ActivityStep {
    let title: String
    let depth: Int
}

// maxDepth=2 captures the high-level step (depth 0) and its immediate sub-steps (depth 1),
// which is where failures manifest. Depth 2+ is mostly repeated "Checking existence" polling
// noise that bloats the output without adding diagnostic value.
func flattenActivities(_ nodes: [[String: Any]], depth: Int = 0, maxDepth: Int = 2) -> [ActivityStep] {
    nodes.flatMap { node -> [ActivityStep] in
        let title = xcString(node, "title") ?? ""
        let step = ActivityStep(title: title, depth: depth)
        guard depth < maxDepth else { return [step] }
        let subs = xcChildren(node, "subactivities")
        return [step] + flattenActivities(subs, depth: depth + 1, maxDepth: maxDepth)
    }
}

// MARK: - Test failure

struct TestFailure {
    let testName: String
    let message: String
    let fileURL: String
    let lineNumber: String
    let activityLog: [ActivityStep]
}

func scanForFailures(node: [String: Any], xcresultPath: String) -> [TestFailure] {
    var failures: [TestFailure] = []
    let status = xcString(node, "testStatus") ?? ""

    if status == "Failure" || status == "Error",
       let summaryRefID = xcChild(node, "summaryRef").flatMap({ xcString($0, "id") }),
       let summary = runXcresulttool(xcresultPath: xcresultPath, objectID: summaryRefID) {

        let activityLog = flattenActivities(xcChildren(summary, "activitySummaries"))
        let name = xcString(node, "identifier") ?? xcString(node, "name") ?? "Unknown"

        for fs in xcChildren(summary, "failureSummaries") {
            let message = xcString(fs, "message") ?? "(no message)"
            let location = xcChild(fs, "sourceCodeContext").flatMap { xcChild($0, "location") }
            let fileURL = location.flatMap { xcString($0, "url") } ?? ""
            let lineNumber = location.flatMap { xcString($0, "lineNumber") } ?? ""

            failures.append(TestFailure(
                testName: name,
                message: message,
                fileURL: fileURL,
                lineNumber: lineNumber,
                activityLog: activityLog
            ))
        }
    }

    for child in xcChildren(node, "subtests") {
        failures += scanForFailures(node: child, xcresultPath: xcresultPath)
    }

    return failures
}

// MARK: - Summary printer (pass/fail overview)

func printSummary(_ node: [String: Any], depth: Int = 0) {
    let status = xcString(node, "testStatus") ?? ""
    guard !status.isEmpty else {
        for child in xcChildren(node, "subtests") {
            printSummary(child, depth: depth)
        }
        return
    }

    let indent = String(repeating: "  ", count: depth)
    let icon: String
    switch status {
    case "Success": icon = "✅"
    case "Failure", "Error": icon = "❌"
    default: icon = "·"
    }
    let name = xcString(node, "identifier") ?? xcString(node, "name") ?? ""
    let duration = xcString(node, "duration").flatMap { Double($0) }.map { String(format: " (%.1fs)", $0) } ?? ""
    print("\(indent)\(icon) \(name)\(duration)")

    for child in xcChildren(node, "subtests") {
        printSummary(child, depth: depth + 1)
    }
}

// MARK: - Main

let args = CommandLine.arguments
guard args.count > 1 else {
    fputs("Usage: swift analyze-xcresult.swift <path-to.xcresult> [--last N]\n", stderr)
    fputs("\n  --last N    Number of activity log steps to show per failure (default: 40)\n", stderr)
    exit(1)
}

let xcresultPath = args[1]

var lastN = 40
if let idx = args.firstIndex(of: "--last"), idx + 1 < args.count, let n = Int(args[idx + 1]) {
    lastN = n
}

guard let root = runXcresulttool(xcresultPath: xcresultPath) else {
    fputs("❌ Could not read xcresult at: \(xcresultPath)\n", stderr)
    exit(1)
}

guard let firstAction = xcChildren(root, "actions").first,
      let testsRefID = xcChild(firstAction, "actionResult")
          .flatMap({ xcChild($0, "testsRef") })
          .flatMap({ xcString($0, "id") }) else {
    fputs("❌ No test results reference found in xcresult.\n", stderr)
    exit(1)
}

guard let testsRoot = runXcresulttool(xcresultPath: xcresultPath, objectID: testsRefID) else {
    fputs("❌ Could not fetch test results object.\n", stderr)
    exit(1)
}

// Print pass/fail overview
print("📦 \(xcresultPath)\n")
for summary in xcChildren(testsRoot, "summaries") {
    for testableSummary in xcChildren(summary, "testableSummaries") {
        for test in xcChildren(testableSummary, "tests") {
            printSummary(test)
        }
    }
}

// Collect all failures
var allFailures: [TestFailure] = []
for summary in xcChildren(testsRoot, "summaries") {
    for testableSummary in xcChildren(summary, "testableSummaries") {
        for test in xcChildren(testableSummary, "tests") {
            allFailures += scanForFailures(node: test, xcresultPath: xcresultPath)
        }
    }
}

guard !allFailures.isEmpty else {
    print("\n✅ All tests passed.")
    exit(0)
}

print("\n❌ \(allFailures.count) failure(s):\n")

let thin = String(repeating: "─", count: 60)
let thick = String(repeating: "═", count: 60)

for (index, failure) in allFailures.enumerated() {
    print(thick)
    print("Failure \(index + 1): \(failure.testName)")

    if !failure.fileURL.isEmpty {
        let path = failure.fileURL.replacingOccurrences(of: "file://", with: "")
        print("Location: \(path):\(failure.lineNumber)")
    }

    print("Message:  \(failure.message)")

    if !failure.activityLog.isEmpty {
        let tail = failure.activityLog.suffix(lastN)
        print("\nActivity log — last \(tail.count) of \(failure.activityLog.count) steps:")
        print(thin)
        for step in tail {
            let indent = String(repeating: "  ", count: min(step.depth, 3))
            print("\(indent)• \(step.title)")
        }
    }

    print()
}
