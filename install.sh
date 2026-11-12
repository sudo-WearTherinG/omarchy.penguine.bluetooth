#!/bin/bash
# Installer for penguine.bluetooth: a multi-adapter Bluetooth panel for Omarchy.
#   ./install.sh              install
#   ./install.sh --dry-run    show what would be installed, change nothing
#   ./install.sh --uninstall  remove everything and restore the original widget

set -u

HERE=$(cd "$(dirname "$0")" && pwd)
SYS="$HERE/system"

die() { echo "Error: $*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "run this as your normal user, not root (it asks for sudo when needed)"
for c in omarchy bluetoothctl busctl rfkill sudo visudo git; do
  command -v "$c" >/dev/null || die "'$c' not found"
done
[[ -d $SYS ]] || die "system folder not found next to install.sh"

if [[ ${1:-} == --uninstall ]]; then
  echo "Removing penguine.bluetooth..."
  sudo /usr/local/bin/bt-internal on 2>/dev/null
  omarchy plugin disable penguine.bluetooth
  omarchy plugin remove penguine.bluetooth
  omarchy plugin enable omarchy.bluetooth
  omarchy bar move omarchy.bluetooth --section right --after omarchy.network || true
  sudo rm -f /usr/local/bin/bt-adapter /usr/local/bin/bt-internal /usr/local/bin/bt-policy
  sudo rm -f /etc/sudoers.d/bt-internal /etc/udev/rules.d/99-bluetooth-adapters.rules /var/lib/bt-internal-manual-off
  sudo udevadm control --reload
  B="$HOME/.config/hypr/bindings.lua"
  if [[ -f $B ]]; then
    sed -i '/penguine\.bluetooth/d; /hl\.unbind("SUPER + CTRL + B")/d' "$B"
  fi
  hyprctl reload >/dev/null 2>&1
  omarchy restart shell
  echo "Done. The original Bluetooth widget is back and the internal adapter is switched on."
  exit 0
fi

DRY=0
[[ ${1:-} == --dry-run ]] && DRY=1

# ---- Find Bluetooth USB adapters ----
cands=()
for d in /sys/bus/usb/devices/*; do
  [[ -f $d/idVendor && -f $d/idProduct ]] || continue
  is_bt=0
  [[ $(cat "$d/bDeviceClass" 2>/dev/null) == e0 ]] && is_bt=1
  for i in "$d":*; do
    [[ -f $i/bInterfaceClass && $(cat "$i/bInterfaceClass" 2>/dev/null) == e0 ]] && is_bt=1
  done
  (( is_bt )) && cands+=("$d")
done

if (( ${#cands[@]} < 2 )); then
  die "found ${#cands[@]} Bluetooth USB adapter(s); this plugin needs two (plug in the external one first). Note: it only works when the internal Bluetooth is a USB device."
fi

echo "Bluetooth USB adapters found:"
for n in "${!cands[@]}"; do
  d=${cands[$n]}
  echo "  $((n+1))) $(cat "$d/idVendor"):$(cat "$d/idProduct")  $(cat "$d/product" 2>/dev/null)  (usb $(basename "$d"))"
done

ask() {
  local prompt=$1 n
  while :; do
    read -rp "$prompt" n
    if [[ $n =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#cands[@]} )); then
      echo $((n-1)); return
    fi
    echo "Enter a number from the list." >&2
  done
}

ii=$(ask "Number of the INTERNAL adapter (the one built into the laptop): ")
ei=$(ask "Number of the EXTERNAL adapter (the USB dongle you want to use): ")
[[ $ii != "$ei" ]] || die "internal and external must be different adapters"

idir=${cands[$ii]}; edir=${cands[$ei]}
ivid=$(cat "$idir/idVendor"); ipid=$(cat "$idir/idProduct")
evid=$(cat "$edir/idVendor"); epid=$(cat "$edir/idProduct")
short() { printf '%x' "$((16#$1))"; }
ivs=$(short "$ivid"); ips=$(short "$ipid"); evs=$(short "$evid"); eps=$(short "$epid")

echo
echo "Internal: $ivid:$ipid   External: $evid:$epid"

if (( DRY )); then
  echo "Dry run: nothing was changed."
  exit 0
fi

# ---- Read the internal adapter's Bluetooth address ----
echo "Reading the internal adapter's address (switching it on briefly)..."
usbname=$(basename "$idir")
sudo sh -c "echo 1 > '$idir/authorized'"
mac=""
for _ in $(seq 1 15); do
  for h in /sys/class/bluetooth/hci[0-9]*; do
    [[ -e $h ]] || continue
    n=${h##*/}
    [[ $n == *:* ]] && continue
    [[ $(readlink -f "$h/device") == */"$usbname"/* ]] || continue
    mac=$(busctl get-property org.bluez "/org/bluez/$n" org.bluez.Adapter1 Address 2>/dev/null | awk -F'"' '{print $2}')
    [[ -n $mac ]] && break 2
  done
  sleep 1
done
[[ -n $mac ]] || die "could not read the internal adapter's address"
echo "Internal address: $mac"

# ---- Fill in this machine's IDs and install ----
tmp=$(mktemp -d)
cp "$SYS"/* "$tmp"/
sed -i "s/^VID=0bda/VID=$ivid/; s/^PID=b009/PID=$ipid/" "$tmp/bt-internal"
sed -i "s/^EXT_VID=33fa/EXT_VID=$evid/; s/^EXT_PID=0001/EXT_PID=$epid/" "$tmp/bt-policy"
sed -i "s/^INTERNAL_MAC=.*/INTERNAL_MAC=\"$mac\"/" "$tmp/bt-adapter"
sed -i "s#33fa/1/#$evs/$eps/#; s#bda/b009/#$ivs/$ips/#" "$tmp/99-bluetooth-adapters.rules"
sed -i "s/^penguine /$USER /" "$tmp/bt-internal.sudoers"

sudo visudo -cf "$tmp/bt-internal.sudoers" >/dev/null || die "permission file failed its check; nothing installed"
sudo install -m 755 "$tmp/bt-adapter" "$tmp/bt-internal" "$tmp/bt-policy" /usr/local/bin/
sudo install -m 440 -o root -g root "$tmp/bt-internal.sudoers" /etc/sudoers.d/bt-internal
sudo install -m 644 "$tmp/99-bluetooth-adapters.rules" /etc/udev/rules.d/
sudo udevadm control --reload
rm -rf "$tmp"

# External adapter is plugged in right now, so the internal one goes off
sudo /usr/local/bin/bt-policy add-external

# ---- Plugin, bar spot, keybind ----
omarchy plugin add "$HERE" --enable --yes
omarchy plugin disable omarchy.bluetooth
omarchy bar move penguine.bluetooth --section right --after omarchy.network || true

B="$HOME/.config/hypr/bindings.lua"
if [[ -f $B ]] && ! grep -q 'penguine\.bluetooth' "$B"; then
  printf '\n' >> "$B"
  cat >> "$B" <<'LUA'
hl.unbind("SUPER + CTRL + B")
o.bind("SUPER + CTRL + B", "Bluetooth", { panel = "penguine.bluetooth" })
LUA
fi
hyprctl reload >/dev/null 2>&1 || true
omarchy restart shell || true

echo
echo "Done. If the bar looks wrong, run: omarchy restart shell"
