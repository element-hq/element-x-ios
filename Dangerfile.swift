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

// Check for screenshots on view changes
let hasChangedViews = !editedFiles.filter { $0.lowercased().contains("/view") }.isEmpty
if hasChangedViews {
    if (danger.github.pullRequest.body?.contains("user-attachments") ?? false) == false {
        warn("You seem to have made changes to views. Please consider adding screenshots.")
    }
}

// Check for pngs on resources
let hasPngs = !editedFiles.filter { $0.lowercased().contains(".xcassets") && $0.lowercased().hasSuffix(".png") }.isEmpty
if hasPngs {
    warn("You seem to have made changes to some resource images. Please consider using an SVG or PDF.")
}

// Check for nice PR titles
let prTitle = danger.github.pullRequest.title
let fixesRegex = try! Regex("(Fixes|Fix) #\\d+")
let semanticRegex = try! Regex("\\w+\\(\\w+\\):")
if prTitle.hasSuffix("…") || prTitle.starts(with: fixesRegex) || prTitle.starts(with: semanticRegex) {
    fail("Please provide a complete title that can be used as a changelog entry.")
}

// Check for changelog tags
if danger.github.issue.labels.filter({ $0.name.hasPrefix("pr-") }).count != 1 {
    fail("Please add a `pr-` label to categorise the changelog entry.")
}
