#
#  Makefile
#  Panic
#
#  Created by Aarnav Tale on 7/12/2021.
#

INSTALL_TARGET_PROCESSES = SpringBoard
export ADDITIONAL_CFLAGS = -DTHEOS_LEAN_AND_MEAN -fobjc-arc --include-directory ./Include
export TARGET = iphone:clang:14.5
export ARCHS = arm64 arm64e

TWEAK_NAME = Panic
BUNDLE_NAME = PanicPreferences

THEOS_PACKAGE_SCHEME=rootless
Panic_FILES = $(wildcard Sources/Tweak/*.m)
Panic_LIBRARIES = libsubstrate
PanicPreferences_FILES = $(wildcard Sources/Preferences/*.m)
PanicPreferences_RESOURCE_DIRS = Resources
PanicPreferences_INSTALL_PATH = /var/jb/Library/PreferenceBundles
PanicPreferences_PRIVATE_FRAMEWORKS = Preferences
PanicPreferences_LIBRARIES = libsubstrate

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/tweak.mk
