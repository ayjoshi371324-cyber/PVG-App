#!/usr/bin/env bash
set -e

echo "==> [RouteMates] Setting up Flutter SDK for Vercel deployment..."

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

echo "==> Enabling Flutter Web..."
flutter config --enable-web

cd mobile

echo "==> Fetching Flutter dependencies..."
flutter pub get

if [ -n "$BACKEND_URL" ]; then
  echo "==> Compiling Flutter Web with BACKEND_URL=$BACKEND_URL..."
  flutter build web --release --dart-define=BACKEND_URL="$BACKEND_URL"
else
  echo "==> Compiling Flutter Web (default configuration)..."
  flutter build web --release
fi

echo "==> [RouteMates] Build complete! Output located at mobile/build/web"
