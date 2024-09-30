import Danger
import Foundation

SwiftLint.lint(.modifiedAndCreatedFiles(directory: nil),
               inline: true,
               configFile: nil,
               strict: false,
               quiet: true,
               swiftlintPath: nil,
               markdownAction: { _ in })

let danger = Danger()

// All of the new and modified files together.
let editedFiles = danger.git.modifiedFiles + danger.git.createdFiles

// Warn when there is a big PR
if (danger.github.pullRequest.additions ?? 0) > 1000 {
    warn("This pull request seems relatively large. Please consider splitting it into multiple smaller ones.")
}

// Check that the PR has a description
if danger.github.pullRequest.body?.isEmpty ?? true {
    warn("Please provide a description for this PR.")
}

// Check for a ticket number
if let ticketNumberRegex = try? NSRegularExpression(pattern: "#\\d+") {
    let missingTicketNumber = !danger.git.commits.filter {
        !$0.message.contains("element-hq/element-x-ios/issues/") &&
            ticketNumberRegex.firstMatch(in: $0.message, options: [], range: .init(location: 0, length: $0.message.utf16.count)) == nil
    }.isEmpty
    
    if missingTicketNumber {
        warn("Some of the commits are missing ticket numbers. Please consider squashing all commits that don't have a tracking number.")
    }
}

// Check for a sign-off
let signOff = "Signed-off-by:"

let allowList = ["stefanceriu",
                 "pixlwave",
                 "langleyd",
                 "manuroe",
                 "Velin92"]

let requiresSignOff = !allowList.contains(where: {
    $0.caseInsensitiveCompare(danger.github.pullRequest.user.login) == .orderedSame
})

if requiresSignOff {
    let hasPRBodySignOff = danger.github.pullRequest.body?.contains(signOff) ?? false

    let isMissingCommitsSignOff = !danger.git.commits.filter {
        !$0.message.contains(signOff)
    }.isEmpty

    if !hasPRBodySignOff, isMissingCommitsSignOff {
        warn("Please add a sign-off to either the PR description or to the commits themselves.")
    }
}

// Check for screenshots on view changes
let hasChangedViews = !editedFiles.filter { $0.lowercased().contains("/view") }.isEmpty
if hasChangedViews {
    if (danger.github.pullRequest.body?.contains("user-images") ?? false) == false {
        warn("You seem to have made changes to views. Please consider adding screenshots.")
    }
}

// Check for pngs on resources
let hasPngs = !editedFiles.filter { $0.lowercased().contains(".xcassets") && $0.lowercased().hasSuffix(".png") }.isEmpty
if hasPngs {
    warn("You seem to have made changes to some resource images. Please consider using an SVG or PDF.")
}

let fixesRegex = try! Regex("(Fixes|Fix) #\\d+")
if danger.github.pullRequest.title.hasSuffix("…") || danger.github.pullRequest.title.starts(with: fixesRegex) {
    fail("Please provide a complete title that can be used as a changelog entry.")
}

if danger.github.issue.labels.filter({ $0.name.hasPrefix("pr-") }).count != 1 {
    fail("Please add a `pr-` label to categorise the changelog entry.")
}
