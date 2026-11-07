#!/bin/bash
set -e

echo "=== Installing Flutter on Vercel build container ==="
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi

export PATH="$PATH:$HOME/flutter/bin"

echo "=== Flutter Version ==="
flutter --version

echo "=== Building Flutter Web Release ==="
flutter config --no-analytics
flutter build web --release
