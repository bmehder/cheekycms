#!/bin/sh
# Generate the Gleam reference and stage the files served at /reference/.
set -eu
cd "$(dirname "$0")/.."
gleam docs build
mkdir -p reference
cp -R build/dev/docs/cheekycms/. reference/
cp docs/docs_config.js reference/docs_config.js
