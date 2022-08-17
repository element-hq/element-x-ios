import Danger
import Foundation

SwiftLint.lint(inline: true, configFile: ".swiftlint.yml")

let danger = Danger()

// Warn when there is a big PR
if (danger.github.pullRequest.additions ?? 0) > 500 {
    warn("This pull request seems relatively large. Please consider splitting it into multiple smaller ones.")
}

// Check that the PR has a description
if danger.github.pullRequest.body?.isEmpty ?? true {
    warn("Please provide a description for this PR.")
}

// Request a changelog for each app change
let editedFiles = danger.git.modifiedFiles + danger.git.createdFiles
let changelogFiles = editedFiles.filter { $0.hasPrefix("changelog.d/") }

if editedFiles.count > 0, changelogFiles.isEmpty {
    warn("Please add a changelog.")
}

// Check for a ticket number
if let ticketNumberRegex = try? NSRegularExpression(pattern: "#\\d+") {
    let missingTicketNumber = !danger.git.commits.filter {
        !$0.message.contains("vector-im/element-x-ios/issues/") &&
            ticketNumberRegex.firstMatch(in: $0.message, options: [], range: .init(location: 0, length: $0.message.utf16.count)) == nil
    }.isEmpty
    
    if missingTicketNumber {
        warn("Some of the commits are missing ticket numbers. Please consinder using them for better tracking.")
    }
}

// Check for a sign-off
let signOff = "Signed-off-by:"

let allowList = ["stefanceriu",
                 "Johennes",
                 "yostyle",
                 "SBiOSoftWhare",
                 "ismailgulek",
                 "Anderas",
                 "pixlwave",
                 "langleyd",
                 "manuroe",
                 "gileluard",
                 "phlniji",
                 "MaximeEvrard42",
                 "aringenbach"]

let requiresSignOff = !allowList.contains(where: {
    $0.caseInsensitiveCompare(danger.github.pullRequest.user.login) == .orderedSame
})

if requiresSignOff {
    let hasPRBodySignOff = danger.github.pullRequest.body?.contains(signOff) ?? false

    let isMissingCommitsSignOff = !danger.git.commits.filter {
        !$0.message.contains(signOff)
    }.isEmpty

    if !hasPRBodySignOff, isMissingCommitsSignOff {
        fail("Please add a sign-off to either the PR description or to the commits themselves.")
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
