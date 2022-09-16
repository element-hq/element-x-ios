#!/bin/bash
set -e

rm -rf element-android

git clone \
  --depth 1 \
  --filter=blob:none \
  --no-checkout \
  https://github.com/vector-im/element-android \
;
cd element-android
git checkout develop
git sparse-checkout set library/ui-strings/src/main/res/values*
cd ..
