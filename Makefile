APP := packages/offsignal_app
CORE := packages/offsignal_core
TOOLS := packages/offsignal_tools

DEVICE ?=
DEVICE_FLAG := $(if $(DEVICE),-d $(DEVICE),)

.DEFAULT_GOAL := help
.PHONY: help setup run run-web run-android devices test test-core test-app test-tools soak \
        analyze format format-fix comments verify apk web l10n icons goldens clean

help:
	@echo "OffSignal — run any of these from the repository root."
	@echo ""
	@echo "  make setup        Resolve dependencies for the whole workspace"
	@echo "  make run          Run the app (make run DEVICE=chrome to pick a device)"
	@echo "  make run-web      Run the app in Chrome"
	@echo "  make run-android  Run the app on an Android device or emulator"
	@echo "  make devices      List the devices Flutter can see"
	@echo ""
	@echo "  make test         Run every suite: codec, tooling, app"
	@echo "  make test-core    Codec only, headless, no Flutter"
	@echo "  make test-app     App widget, golden, and asset-guard tests"
	@echo "  make soak         1000-run randomized codec soak (PRD section 14)"
	@echo "  make goldens      Regenerate golden files"
	@echo ""
	@echo "  make verify       Everything CI runs: analyze, format, guards, tests"
	@echo "  make analyze      Static analysis across the workspace"
	@echo "  make format       Check formatting without writing"
	@echo "  make format-fix   Apply formatting"
	@echo "  make comments     Enforce the no-comments rule (PRD section 4.1)"
	@echo ""
	@echo "  make apk          Build the signed release APK"
	@echo "  make web          Build the release web bundle"
	@echo "  make l10n         Regenerate localizations from the ARB files"
	@echo "  make icons        Regenerate brand raster assets"
	@echo "  make clean        Clean build output"

setup:
	flutter pub get

run:
	cd $(APP) && flutter run $(DEVICE_FLAG)

run-web:
	cd $(APP) && flutter run -d chrome

run-android:
	cd $(APP) && flutter run -d android

devices:
	flutter devices

test: test-core test-tools test-app

test-core:
	cd $(CORE) && dart test

test-tools:
	cd $(TOOLS) && dart test

test-app:
	cd $(APP) && flutter test

soak:
	cd $(CORE) && dart test test/soak_test.dart

goldens:
	cd $(APP) && flutter test --update-goldens

analyze:
	flutter analyze

format:
	dart format --output=none --set-exit-if-changed packages

format-fix:
	dart format packages

comments:
	dart run $(TOOLS)/bin/check_comments.dart $(CORE)/lib $(CORE)/test $(APP)/lib

verify: analyze format comments test
	@echo "All checks passed."

apk:
	cd $(APP) && flutter build apk --release
	@mkdir -p dist
	@cp $(APP)/build/app/outputs/flutter-apk/app-release.apk dist/offsignal-release.apk
	@echo ""
	@echo "APK: $(CURDIR)/dist/offsignal-release.apk"
	@echo "     $$(du -h dist/offsignal-release.apk | cut -f1)"
	@echo "Signed with: $$(./tools/apk_signer.sh dist/offsignal-release.apk)"
	@echo "Permissions: $$(./tools/apk_permissions.sh dist/offsignal-release.apk)"

web:
	cd $(APP) && flutter build web --release
	@echo ""
	@echo "Web bundle: $(CURDIR)/$(APP)/build/web"

l10n:
	cd $(APP) && flutter gen-l10n

icons:
	python3 tools/generate_brand_assets.py

clean:
	flutter clean
	cd $(APP) && flutter clean
