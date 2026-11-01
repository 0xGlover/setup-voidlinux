#!/usr/bin/env bash
# Read-only detection; alternate roots are used by the fixture tests.
detect_hardware() {
    local sys=${1:-/sys} proc=${2:-/proc} dev class vendor device type
    CPU_VENDOR=$(awk -F ': *' '/vendor_id/{print $2; exit}' "$proc/cpuinfo")
    CPU_MODEL=$(awk -F ': *' '/model name/{print $2; exit}' "$proc/cpuinfo")
    RAM_MIB=$(awk '/MemTotal/{printf "%d", $2/1024}' "$proc/meminfo")
    GPU_INTEL=0 GPU_AMD=0 GPU_NVIDIA=0 INTEL_LEGACY=0 BATTERY=0 BLUETOOTH=0 SSD=0
    GPU_IDS=()
    for dev in "$sys"/bus/pci/devices/*; do
        [[ -r $dev/class ]] || continue
        class=$(<"$dev/class")
        [[ $class == 0x03* ]] || continue
        vendor=$(<"$dev/vendor"); device=$(<"$dev/device")
        GPU_IDS+=("$vendor:$device")
        case $vendor in
            0x8086)
                GPU_INTEL=1
                # Sandy/Ivy Bridge, Haswell, Broadwell, Ironlake and older.
                case $device in
                    0x01[01256][26]|0x0[acde][0123][26]|0x16[0123][26]|0x004[26]|0x2a[024][23]|0x2e[01239]2|0x29[ac]2)
                        INTEL_LEGACY=1;;
                esac;;
            0x1002) GPU_AMD=1;;
            0x10de) GPU_NVIDIA=1;;
        esac
    done
    for dev in "$sys"/class/power_supply/*; do
        [[ -r $dev/type ]] || continue
        type=$(<"$dev/type")
        [[ $type != Battery ]] || BATTERY=1
    done
    for dev in "$sys"/class/bluetooth/hci*; do
        [[ ! -e $dev ]] || BLUETOOTH=1
    done
    # Bluetooth adapters may not have a loaded driver on a fresh installation.
    for dev in "$sys"/bus/usb/devices/*; do
        [[ -r $dev/bInterfaceClass && -r $dev/bInterfaceSubClass ]] || continue
        [[ $(<"$dev/bInterfaceClass") != e0 || $(<"$dev/bInterfaceSubClass") != 01 ]] || BLUETOOTH=1
    done
    for dev in "$sys"/block/*; do
        [[ -r $dev/queue/rotational ]] || continue
        case ${dev##*/} in loop*|ram*|zram*|sr*) continue;; esac
        [[ $(<"$dev/queue/rotational") != 0 ]] || SSD=1
    done
    return 0
}

select_hardware_packages() {
    HARDWARE_PACKAGES=(mesa-dri linux-firmware-network libva-utils)
    if (( GPU_INTEL )); then
        HARDWARE_PACKAGES+=(linux-firmware-intel)
        if (( INTEL_LEGACY )); then
            HARDWARE_PACKAGES+=(libva-intel-driver)
        else
            # Let libva select the backend; covers mixed-generation Intel GPUs.
            HARDWARE_PACKAGES+=(intel-media-driver libva-intel-driver)
        fi
    fi
    (( ! GPU_AMD )) || HARDWARE_PACKAGES+=(linux-firmware-amd mesa-vaapi)
    (( ! GPU_NVIDIA )) || HARDWARE_PACKAGES+=(linux-firmware-nvidia)
    (( ! BLUETOOTH )) || HARDWARE_PACKAGES+=(bluez libspa-bluetooth)
    [[ $CPU_VENDOR != AuthenticAMD ]] || HARDWARE_PACKAGES+=(linux-firmware-amd)
    return 0
}
