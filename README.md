# Penguine Bluetooth

A Bluetooth panel for Omarchy that manages two Bluetooth adapters separately.

## Why this exists

On the author's HP 15-da0xxx laptop (Realtek RTL8723DE Wi-Fi/Bluetooth combo
card), Wi-Fi became slow and unstable roughly every 20 minutes whenever
Bluetooth earbuds were in use, and reconnecting to Wi-Fi fixed it for a while.
Changing the router channel (1, 6 and 11 were tried) did not help. The
suspected cause is that the Wi-Fi and Bluetooth parts of this chip interfere
with each other, possibly because they share an antenna. That is a suspicion,
not a confirmed diagnosis.

After switching Bluetooth to an external USB adapter and turning the internal
one off, Wi-Fi stayed stable for several days on that laptop, including after
a clean reinstall of Omarchy. That is one machine, so it is evidence, not
proof.

## If you don't need Bluetooth while working

You don't need this plugin. Turn Bluetooth off completely when you aren't
using it, with Omarchy's Bluetooth switch.

On Windows, open Device Manager, expand "Bluetooth", right-click the internal
adapter and choose "Disable device". Wi-Fi is listed under "Network adapters"
and is not affected. The author has not tested this on Windows.

## If you need Bluetooth while working

Use an external USB Bluetooth adapter and switch the internal one off. This
plugin automates that on Omarchy, with a switch for each adapter in the panel.

## What it does

- Lists each Bluetooth adapter in the panel with its own on/off switch.
- External adapter plugged in: the internal one switches off by itself.
- External adapter unplugged: the internal one switches back on, unless you
  switched it off by hand.
- A manual "off" for the internal adapter is saved as a flag file, so it should
  survive reboots. The reboot behavior has not been tested yet.
- Wi-Fi is never touched. The Wi-Fi driver and btusb stay as they are.

## Install

    git clone https://github.com/sudo-WearTherinG/omarchy.penguine.bluetooth.git
    cd omarchy.penguine.bluetooth
    chmod +x install.sh
    ./install.sh

Plug in the external adapter first. The installer lists the Bluetooth USB
adapters it finds and asks you which is internal and which is external. It
uses sudo for the system files.
To preview without changing anything: `./install.sh --dry-run`

## Uninstall

    ./install.sh --uninstall

This restores the original Omarchy Bluetooth widget and switches the
internal adapter back on.

## What the installer changes

- Three scripts in /usr/local/bin (bt-adapter, bt-internal, bt-policy)
- A udev rule and a sudo permission file for those scripts only
- The plugin itself, which replaces the original Omarchy Bluetooth widget
  (the original is disabled, not deleted), plus its bar position
- Super+Ctrl+B in ~/.config/hypr/bindings.lua, pointed at this panel

## Limits

- The internal Bluetooth must be a USB device. Many laptop Wi-Fi/Bluetooth
  combo cards are, but a Bluetooth chip on another bus will not be found.
- Exactly two adapters are supported.
- The panel only checks adapter status while it is open. If you unplug the
  USB adapter with the panel closed, the new state shows up the next time you
  open it.
- With only one adapter plugged in, the panel shows Omarchy's stock switch
  instead of the per-adapter rows.
- Tested on one laptop (HP 15-da0xxx, Realtek) on Omarchy 4.5.0-3. The
  install, uninstall and reinstall cycle was tested on that same machine only.
