#!/bin/bash

# This script is invoked by xcodegen for running post commands

# Move file header template in project shared data folder
cp IDETemplateMacros.plist ../../ElementX.xcodeproj/xcshareddata/

# Rewrite schemes the way Xcode saves them
swift normalizeSchemes.swift ../../ElementX.xcodeproj/xcshareddata/xcschemes
