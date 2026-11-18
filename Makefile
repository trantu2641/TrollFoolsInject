# Makefile
ARCHS = arm64
TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = TrollFoolsInject

TrollFoolsInject_FILES = src/TrollFoolsInject.c
TrollFoolsInject_FRAMEWORKS = Foundation UIKit
TrollFoolsInject_LIBRARIES = substrate
TrollFoolsInject_INSTALL_PATH = /usr/lib

include $(THEOS_MAKE_PATH)/library.mk
