# MT7927 Monitor And Injection Validation

This checklist is for authorized lab validation of MT7927 monitor mode and
mac80211 injected TX behavior on 2.4 GHz, 5 GHz, and 6 GHz.

It intentionally uses current tooling:

- `iw`
- `hcxdumptool`
- `hcxpcapngtool`
- `tshark`
- `hashcat` for offline verification when you have authorization

It intentionally does not use aircrack-ng.

## 1. Confirm Driver Binding

```sh
lspci -nn | grep -iE '14c3:(7927|6639|0738)'
sudo dmesg | grep -iE 'mt7927|mt76|mediatek'
iw dev
```

If `iw dev` is empty while `lspci` shows `14c3:7927`, collect:

```sh
sudo dmesg | grep -iE 'mt7927|mt76|firmware|wfdma|mcu|error|fail'
modinfo mt7927e_git 2>/dev/null || modinfo mt7927e
```

## 2. Create A Monitor Interface

Replace `wlan0` with the managed interface from `iw dev`.

```sh
sudo ip link set wlan0 down
sudo iw dev wlan0 interface add mon0 type monitor
sudo ip link set mon0 up
iw dev mon0 info
```

The driver path toggles firmware sniffer mode through mac80211 monitor flags.
Runtime power management and deep sleep are disabled while monitor mode is
active.

## 3. Channel Coverage

Use channels permitted by your regulatory domain and lab environment.

2.4 GHz:

```sh
sudo iw dev mon0 set channel 6 HT20
```

5 GHz:

```sh
sudo iw dev mon0 set channel 36 HE80
```

6 GHz EHT, 320 MHz where allowed:

```sh
sudo iw dev mon0 set channel 37 320MHz
```

If the 6 GHz command fails, verify regulatory state and kernel/mac80211 support:

```sh
iw reg get
iw phy | grep -A40 -i 'band 4'
```

## 4. Passive Capture Sanity

```sh
sudo timeout 30s tshark -i mon0 -I -w mt7927-mon0.pcapng
tshark -r mt7927-mon0.pcapng -q -z io,phs
```

Expected result: management/control/data frames are visible for the configured
band when traffic exists in the lab.

## 5. hcxdumptool Capture

Run only against networks and devices you are authorized to test.

```sh
sudo timeout 60s hcxdumptool -i mon0 -w mt7927-hcx.pcapng --rds=1
hcxpcapngtool --all mt7927-hcx.pcapng
```

Use `tshark` to inspect radiotap and PHY metadata:

```sh
tshark -r mt7927-hcx.pcapng -T fields \
  -e frame.number \
  -e wlan_radio.channel \
  -e wlan_radio.frequency \
  -e wlan_radio.phy \
  -e radiotap.datarate | head
```

## 6. Injection Signals

The driver preserves injected TX handling in the MT7927 MAC path. Validate in a
shielded lab by checking that injected frames leave the monitor interface and
are observed by an independent receiver on the same channel.

Recommended evidence to collect:

```sh
sudo dmesg | grep -iE 'mt7927|tx|txs|wcid|fail|timeout'
tshark -r receiver-side-capture.pcapng -Y 'wlan.fc.type_subtype == 0x0d or wlan.fc.type == 0'
```

For maintainer reporting, include:

- kernel version
- firmware file hashes
- PCI ID and board model
- exact channel width and band
- `iw phy` capability excerpt
- short `tshark` summary from sender and receiver captures

## 7. Cleanup

```sh
sudo ip link set mon0 down
sudo iw dev mon0 del
sudo ip link set wlan0 up
```
