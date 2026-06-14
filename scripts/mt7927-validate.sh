#!/bin/sh
set -eu

IW=${IW:-$(command -v iw 2>/dev/null || command -v /usr/sbin/iw 2>/dev/null || true)}

echo "== kernel =="
uname -a

echo
echo "== pci =="
lspci -nn | grep -iE '14c3:(7927|6639|0738)' || {
	echo "No MT7927-class PCI device found"
	exit 1
}

echo
echo "== modules =="
lsmod | awk '$1 ~ /^mt(76|792x|7927)/ { print }' || true

echo
echo "== firmware =="
for f in \
	/lib/firmware/mediatek/mt7927/WIFI_MT6639_PATCH_MCU_2_1_hdr.bin \
	/lib/firmware/mediatek/mt7927/WIFI_RAM_CODE_MT6639_2_1.bin
do
	if [ -f "$f" ]; then
		sha256sum "$f"
	else
		echo "missing: $f"
	fi
done

echo
echo "== iw dev =="
if [ -n "$IW" ]; then
	"$IW" dev || true
else
	echo "iw not found"
fi

echo
echo "== iw phy mt7927-related capabilities =="
if [ -n "$IW" ]; then
	"$IW" phy 2>/dev/null | grep -iE 'Wiphy|Band |MHz|EHT|monitor|AP|managed' | sed -n '1,180p' || true
else
	echo "iw not found"
fi

echo
echo "== recent dmesg =="
dmesg 2>/dev/null | grep -iE 'mt7927|mt76|mediatek|firmware|wfdma|mcu|fail|error' | tail -80 || true
