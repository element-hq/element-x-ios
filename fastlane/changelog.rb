# Copyright 2020 New Vector Ltd - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential

# frozen_string_literal: true

require "tempfile"
require "fileutils"
require "date"

# Helper methods to handle updates of the Changelog file
#
module Changelog
  CHANGES_SEPARATOR_REGEX = /^\#\#\ Changes/.freeze
  FILE = "CHANGES.md"

  # Update the topmost section of the changelog to put version+date in title + add entry for dependency updates
  #
  # @param [String] version The version that we are releasing to use in the new title of the first section
  # @param [Hash<String, Array<String>>] additional_entries
  #        List of lines/entries to add under the each subsection of the first section
  #        The keys of the hash are the name of the subsections, without trailing`:`, e.g. "Improvements".
  #        The values are the list of lines to add to that subsection
  #        (the ` * ` bullet point will be added automatically for each line)
  #
  def self.update_topmost_section(version:, additional_entries:)

    # Create temporary towncrier changelog entries for additional entries
    # Use a low index to make them appear first
    # Those additional entries are basically dependency updates
    entry_count = 0
    additional_entries.each do |subsection, entries|
      entries.each do |entry|
        file = "changelog.d/x-nolink-#{entry_count}.#{subsection}"
        File.write(file, "#{entry}")
        Git.add!(files: file)
        Git.commit!(message: "changelog.d: #{entry}", add_all: true)
        entry_count += 1
      end
    end

    # Let towncrier update the change
    system("towncrier", "build", "--version", "#{version}", "--yes")
  end

  # Returns the first section of the Changelog, corresponding to the changes in the latest version
  #
  def self.extract_first_section
    lines = []
    File.open(FILE, "r") do |file|
      section_index = 0
      file.each_line do |line|
        is_separator_line = (line.chomp =~ CHANGES_SEPARATOR_REGEX)
        section_index += 1 if is_separator_line
        break if section_index >= 2

        lines.append(line) if section_index == 1
      end
    end
    lines[0..-2].join # Remove last line (title of section 2)
  end

end
