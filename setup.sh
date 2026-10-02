#!/usr/bin/env bash
# Builds a runnable Flutter project in ./app from the sources in ./src
set -e

APP_DIR="app"

if [ ! -d "$APP_DIR" ]; then
  flutter create --org com.annexcode --project-name money_out --platforms=android "$APP_DIR"
fi

rm -rf "$APP_DIR/lib"
cp -r src/lib "$APP_DIR/lib"
cp src/pubspec.yaml "$APP_DIR/pubspec.yaml"
cp src/analysis_options.yaml "$APP_DIR/analysis_options.yaml"

if [ -f src/.env ]; then
  cp src/.env "$APP_DIR/.env"
else
  cp src/.env.example "$APP_DIR/.env"
fi

# App name shown under the icon on the phone
MANIFEST="$APP_DIR/android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  sed -i.bak 's/android:label="money_out"/android:label="Money Out"/' "$MANIFEST" && rm -f "$MANIFEST.bak"
fi

cd "$APP_DIR"
flutter pub get
echo
echo "Ready. Build the APK with:"
echo "  cd app && flutter build apk --release"
