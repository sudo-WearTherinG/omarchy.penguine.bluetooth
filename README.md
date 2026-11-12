# Penguine Bluetooth

A Bluetooth panel for Omarchy that manages two Bluetooth adapters separately.
It was built to test whether a laptop's built-in Bluetooth hurts Wi-Fi, by
switching the internal adapter off and using an external USB one. On the
author's laptop Wi-Fi became stable afterwards, but that is one machine and
not a proven cause.

## What it does

- Lists each Bluetooth adapter in the panel with its own on/off switch.
- External adapter plugged in: the internal one switches off by itself.
- External adapter unplugged: the internal one switches back on, unless you
  switched it off by hand.
- A manual "off" for the internal adapter is saved as a flag file, so it should
  survive reboots.
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
