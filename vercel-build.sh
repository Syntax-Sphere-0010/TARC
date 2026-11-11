#!/bin/bash
set -e

echo "=== Vercel Build Script for Flutter Web ==="

# Check if Flutter SDK already exists, if not, clone the stable channel
if [ ! -d "$HOME/flutter" ]; then
  echo "Cloning Flutter SDK (stable channel)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
else
  echo "Flutter SDK already exists, pulling updates..."
  cd "$HOME/flutter" && git pull && cd -
fi

# Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"

echo "Checking Flutter version..."
flutter --version

echo "Configuring Flutter for Web..."
flutter config --enable-web

echo "Getting dependencies..."
flutter pub get

echo "Building Flutter Web release..."
flutter build web --release

echo "=== Build completed successfully! ==="
