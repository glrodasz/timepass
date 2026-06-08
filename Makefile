SCHEME      := Timepass
CONFIG      := Release
PROJECT     := Timepass.xcodeproj
DERIVED     := build/DerivedData
APP_NAME    := Timepass.app
PRODUCT     := $(DERIVED)/Build/Products/$(CONFIG)/$(APP_NAME)
INSTALL_DIR := /Applications

.DEFAULT_GOAL := help

.PHONY: help generate build install run catalog clean

help:
	@echo "FlagTimes targets:"
	@echo "  make generate  - regenerate $(PROJECT) from project.yml (xcodegen)"
	@echo "  make build     - $(CONFIG) build into $(DERIVED)"
	@echo "  make install   - build and copy $(APP_NAME) into $(INSTALL_DIR)"
	@echo "  make run       - launch the installed app"
	@echo "  make catalog   - regenerate the timezone catalog"
	@echo "  make clean     - remove build/ and $(PROJECT)"

generate:
	xcodegen generate

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-configuration $(CONFIG) -derivedDataPath $(DERIVED) build

install: build
	rm -rf "$(INSTALL_DIR)/$(APP_NAME)"
	cp -R "$(PRODUCT)" "$(INSTALL_DIR)/$(APP_NAME)"
	@echo "Installed $(APP_NAME) to $(INSTALL_DIR). First launch: right-click -> Open."

run:
	open "$(INSTALL_DIR)/$(APP_NAME)"

catalog:
	./Scripts/generate_catalog.sh

clean:
	rm -rf build $(PROJECT)
