#!/bin/bash

# Install Flutter if not already installed
if ! command -v flutter &> /dev/null; then
    echo "Installing Flutter..."
    curl -sSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz -o flutter.tar.xz
    tar -xf flutter.tar.xz
    export PATH="$PATH:$(pwd)/flutter/bin"
    echo "Flutter installed successfully"
fi

# Clean and get dependencies
echo "Cleaning Flutter project..."
flutter clean

echo "Getting Flutter dependencies..."
flutter pub get

# Build the web app
echo "Building Flutter web app..."
flutter build web --web-renderer html

echo "Build completed successfully!"
