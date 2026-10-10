#!/usr/bin/env bash
set -e

echo "==> [RouteMates] Setting up Flutter SDK in mobile directory..."

FLUTTER_CHANNEL="stable"
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "==> Cloning Flutter SDK ($FLUTTER_CHANNEL)..."
  git clone --depth 1 -b $FLUTTER_CHANNEL https://github.com/flutter/flutter.git $FLUTTER_DIR
else
  echo "==> Flutter SDK already cached."
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get

if [ -n "$BACKEND_URL" ]; then
  echo "==> Compiling with BACKEND_URL=$BACKEND_URL..."
  flutter build web --release --dart-define=BACKEND_URL="$BACKEND_URL"
else
  flutter build web --release
fi

echo "==> [RouteMates] Build complete! Output located at build/web"
