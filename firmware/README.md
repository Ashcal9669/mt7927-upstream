# MT7927 Firmware

Expected install location:

```text
/lib/firmware/mediatek/mt7927/WIFI_MT6639_PATCH_MCU_2_1_hdr.bin
/lib/firmware/mediatek/mt7927/WIFI_RAM_CODE_MT6639_2_1.bin
```

The repository also keeps `BT_RAM_CODE_MT6639_2_1_hdr.bin` for reference
because MT7927 is commonly deployed as a WiFi/Bluetooth combo module. Bluetooth
loading is handled by `btusb`/`btmtk`, not this mt76 WiFi driver.

Install WiFi firmware with:

```sh
sudo make install_fw
```
