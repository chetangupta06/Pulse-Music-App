#!/bin/bash

# Exit on error
set -e

echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

echo "Adding Flutter to PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "Building Flutter Web..."
flutter build web
