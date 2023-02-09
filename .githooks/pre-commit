#!/bin/bash
# Place this file in `.git/hooks/`

if which swiftlint >/dev/null; then
  swiftlint autocorrect
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi

git diff --diff-filter=d --staged --name-only | grep -e '\(.*\).swift$' | while read line; do
  swiftformat "${line}";
  git add "$line";
done