# MT7927 Upstream Driver

Standalone upstream-based mt76 WiFi driver tree for MediaTek MT7927 /
Filogic 380 PCIe devices.

This repository is intentionally not a DKMS patch-packaging tree and not an
MT7925 device-support branch. It carries a clean `mt7927/` driver directory
derived from the upstream mt76 MT792x code path, with MT7927 PCI IDs, firmware
paths, DMA/IRQ layout, 320 MHz EHT support, and monitor-mode plumbing kept in
one MT7927-focused source tree.

## Supported WiFi Devices

MediaTek PCI vendor ID is `14c3`.

| Device ID | Notes |
| --- | --- |
| `7927` | MT7927 / Filogic 380 PCIe WiFi |
| `6639` | MT6639/MT7927 combo module WiFi side |
| `0738` | AMD RZ738 / MT7927 variant |

Bluetooth for the combo module is handled by the kernel Bluetooth stack
(`btusb`/`btmtk`) and is outside this mt76 WiFi repository.

## Focus

The current maintenance focus is MT7927 WiFi operation for:

- monitor mode on 2.4 GHz, 5 GHz, and 6 GHz
- packet injection through mac80211 injected TX paths
- 6 GHz EHT operation, including 320 MHz channel width handling
- stable band selection for 5 GHz and 6 GHz
- correct MT7927 DMA, IRQ, firmware, and power-management behavior

The validation workflow uses current tooling: `iw`, `hcxdumptool`,
`hcxpcapngtool`, `tshark`, and `hashcat` where appropriate. It does not use
aircrack-ng.

## Build

Install kernel headers for the target kernel first.

```sh
make
```

To build for a non-running kernel:

```sh
make KVER=7.0.10+deb13-amd64
```

Install the out-of-tree modules:

```sh
sudo make install
sudo depmod -a
```

Install bundled MT7927 firmware:

```sh
sudo make install_fw
```

The module names use a `_git` suffix so they can coexist with in-kernel mt76
modules during maintainer testing:

- `mt76_git`
- `mt76_connac_lib_git`
- `mt792x_lib_git`
- `mt7927_common_git`
- `mt7927e_git`

## Quick Hardware Check

```sh
lspci -nn | grep -iE '14c3:(7927|6639|0738)'
sudo dmesg | grep -iE 'mt7927|mt76|mediatek'
```

After loading the driver, `iw dev` should show the created wireless interface.

## Monitor And Injection Validation

See [docs/monitor-injection.md](docs/monitor-injection.md).

For a quick environment snapshot:

```sh
./scripts/mt7927-validate.sh
```

## Source Notes

Important MT7927-specific code lives in:

- `mt7927/pci.c`: PCI IDs, MT7927 IRQ map, MT7927 DMA selection
- `mt7927/main.c`: monitor/sniffer handling, band context handling
- `mt7927/mac.c`: RX/TX status parsing, injected TX handling
- `mt7927/mcu.c`: BSS/channel/EHT/320 MHz MCU TLVs
- `mt792x_dma.c`: MT7927 WFDMA and CBInfra reset handling
- `mt792x_regs.h`: MT7927 CBInfra and IRQ definitions

## License

Driver source is licensed under `BSD-3-Clause-Clear`, matching upstream mt76.
Firmware blobs retain the MediaTek firmware license in `firmware/LICENSE.mediatek`.
