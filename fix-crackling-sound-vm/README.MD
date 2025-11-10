# VMware Audio Fix Scripts

Fix audio crackling/stuttering in Linux VMs running on VMware Workstation.

## Problem
Audio works fine with ALSA but stutters in browsers (Firefox, Chrome) due to PipeWire issues in virtualized environments.

## Solutions

### Option 1: PulseAudio (Recommended)
**File:** `vm_sound_fix.sh`

Bypasses PipeWire and uses PulseAudio directly with ALSA.

```bash
chmod +x vm_sound_fix.sh
./vm_sound_fix.sh
```

**Distro:** openSUSE (uses `zypper`)

### Option 2: PipeWire Optimization
**File:** `vm_sound_also_fix.sh`

Optimizes PipeWire settings for VMware.

```bash
chmod +x vm_sound_also_fix.sh
./vm_sound_also_fix.sh
```

**Distro:** Universal (any distro with PipeWire)

---

## Additional Setup Scripts

### ASUS Laptop Control (asusctl)
**File:** `setup-asusctl.sh`

Installs asusctl for ASUS laptop features on openSUSE Tumbleweed.

```bash
chmod +x setup-asusctl.sh
./setup-asusctl.sh
```

Features: Performance profiles, keyboard backlight, battery management

### NVIDIA Wayland Support
**File:** `setup-nvidia-wayland.sh`

Configures NVIDIA proprietary drivers for Wayland with dual monitor support.

```bash
chmod +x setup-nvidia-wayland.sh
sudo ./setup-nvidia-wayland.sh
```

Enables kernel modesetting and early module loading for NVIDIA on openSUSE Tumbleweed.

---

## VMware Host Settings (Windows 11)

Run in PowerShell as Administrator:

```powershell
powercfg /powerthrottling disable /path "C:\Program Files (x86)\VMware\VMware Workstation\x64\vmware-vmx.exe"
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
```

## VMX File Tweak

Add to your `.vmx` file:
```
sound.virtualDev = "es1371"
```

## Test Audio
```bash
paplay /usr/share/sounds/alsa/Front_Center.wav
```
