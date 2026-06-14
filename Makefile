# SPDX-License-Identifier: BSD-3-Clause-Clear
#
# Out-of-tree Makefile for MT7927 PCIe WiFi
#
# Based on: https://github.com/openwrt/mt76
# Trimmed to a standalone MT7927 PCIe driver tree.
#
# Usage:
#   make                       Build all modules for the running kernel
#   make KVER=6.12.0-generic   Build for a specific kernel version
#   make clean                 Clean build artifacts
#   sudo make install          Install modules and run depmod
#   sudo make uninstall        Remove installed modules

ifneq ($(KERNELRELEASE),)

# ============================================================
# Kbuild section -- processed inside the kernel build system
# ============================================================

# Bake the git commit into every module for traceability (visible via modinfo)
GIT_COMMIT := $(shell git --git-dir=$(src)/.git rev-parse --short HEAD 2>/dev/null || echo "unknown")
ccflags-y += -Werror -DCONFIG_MT76_LEDS -DCONFIG_MT76_DEBUGFS \
	-DGIT_COMMIT=\"$(GIT_COMMIT)\"

# --- Core ---
obj-m += mt76_git.o

mt76_git-y := \
	mmio.o util.o trace.o dma.o mac80211.o debugfs.o eeprom.o \
	tx.o agg-rx.o mcu.o scan.o channel.o

mt76_git-$(CONFIG_PCI) += pci.o
mt76_git-$(CONFIG_NL80211_TESTMODE) += testmode.o

# --- CONNAC shared library ---
obj-m += mt76_connac_lib_git.o
mt76_connac_lib_git-y := mt76_connac_mcu.o mt76_connac_mac.o mt76_connac3_mac.o

# --- MT792x shared library ---
obj-m += mt792x_lib_git.o
mt792x_lib_git-y := \
	mt792x_core.o mt792x_mac.o mt792x_trace.o \
	mt792x_debugfs.o mt792x_dma.o
mt792x_lib_git-$(CONFIG_ACPI) += mt792x_acpi_sar.o

# --- Trace include paths ---
CFLAGS_trace.o := -I$(src)
CFLAGS_mt792x_trace.o := -I$(src)

# --- MT7927 PCIe ---
obj-m += mt7927/

else

# ============================================================
# User section -- targets for building from the command line
# ============================================================

KVER ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVER)/build
MODDIR ?= /lib/modules/$(KVER)/extra/mt7927
FWDIR := /lib/firmware/mediatek
NPROC ?= $(shell nproc --ignore=1)

.PHONY: modules clean install install_fw uninstall

modules:
	$(MAKE) -j$(NPROC) -C $(KDIR) M=$$PWD modules

clean:
	$(MAKE) -C $(KDIR) M=$$PWD clean

install:
	@echo "Installing MT7927 modules to $(MODDIR)..."
	@find . -name "*_git.ko" -exec strip -g {} \;
	@install -dvm 755 $(MODDIR)
	@find . -name "*_git.ko" -exec install -vm 644 {} $(MODDIR) \;
	@# Match the distro's module compression scheme
	@if ls /lib/modules/$(KVER)/kernel/net/wireless/*.ko.zst >/dev/null 2>&1; then \
		echo "Compressing modules with zstd (matching distro scheme)..."; \
		zstd -fq --rm $(MODDIR)/*.ko 2>/dev/null || true; \
	elif ls /lib/modules/$(KVER)/kernel/net/wireless/*.ko.xz >/dev/null 2>&1; then \
		echo "Compressing modules with xz (matching distro scheme)..."; \
		xz -f $(MODDIR)/*.ko 2>/dev/null || true; \
	elif ls /lib/modules/$(KVER)/kernel/net/wireless/*.ko.gz >/dev/null 2>&1; then \
		echo "Compressing modules with gzip (matching distro scheme)..."; \
		gzip -f $(MODDIR)/*.ko 2>/dev/null || true; \
	fi
	depmod -a $(KVER)

install_fw:
	@install -dvm 755 $(FWDIR)/mt7927
	@install -vm 644 firmware/mt7927/*.bin $(FWDIR)/mt7927/
	@echo "Firmware install complete."

uninstall:
	@echo "Removing MT7927 modules from $(MODDIR)..."
	@rm -rvf $(MODDIR)
	@rmdir -v --ignore-fail-on-non-empty /lib/modules/$(KVER)/extra 2>/dev/null || true
	depmod -a $(KVER)

endif
