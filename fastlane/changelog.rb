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

end
