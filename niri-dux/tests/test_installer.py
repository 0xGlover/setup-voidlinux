"""Offline behavior tests. No package manager writes or sudo calls are allowed."""
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
import tempfile
import time
import unittest

BASE = Path(__file__).resolve().parents[1]


class HardwareTests(unittest.TestCase):
    def detect(self, gpus=(), cpu="GenuineIntel", battery=False, bluetooth=False, ssd=False):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)

            def write(name, text):
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text)

            write("proc/cpuinfo", f"vendor_id : {cpu}\nmodel name : Fixture CPU\n")
            write("proc/meminfo", "MemTotal: 8388608 kB\n")
            for i, (vendor, device, kind) in enumerate(gpus):
                prefix = f"sys/bus/pci/devices/0000:00:{i:02x}.0"
                write(f"{prefix}/vendor", vendor)
                write(f"{prefix}/device", device)
                write(f"{prefix}/class", kind)
            if battery:
                write("sys/class/power_supply/BAT0/type", "Battery\n")
            if bluetooth:
                write("sys/bus/usb/devices/1-1:1.0/bInterfaceClass", "e0\n")
                write("sys/bus/usb/devices/1-1:1.0/bInterfaceSubClass", "01\n")
            if ssd:
                write("sys/block/sda/queue/rotational", "0\n")
            # zram must not be mistaken for an SSD.
            write("sys/block/zram0/queue/rotational", "0\n")
            result = subprocess.run(
                ["bash", "-euc", 'source "$1"; detect_hardware "$2/sys" "$2/proc"; '
                 'select_hardware_packages; '
                 'printf "%s %s %s %s %s %s\\n" "$GPU_INTEL" "$GPU_AMD" '
                 '"$GPU_NVIDIA" "$INTEL_LEGACY" "$BATTERY" "$SSD"; '
                 'printf "%s\\n" "${HARDWARE_PACKAGES[@]}"',
                 "test", str(BASE / "lib/hardware.sh"), tmp],
                text=True, capture_output=True, check=True,
            )
            lines = result.stdout.splitlines()
            return lines[0], lines[1:]

    def test_this_dell_sandy_bridge(self):
        flags, packages = self.detect(gpus=[("0x8086", "0x0116", "0x030000")], ssd=True)
        self.assertEqual(flags, "1 0 0 1 0 1")
        self.assertIn("libva-intel-driver", packages)
        self.assertNotIn("intel-media-driver", packages)
        self.assertFalse(any("vulkan" in p for p in packages))

    def test_modern_intel_and_unloaded_bluetooth(self):
        flags, packages = self.detect(gpus=[("0x8086", "0x9a49", "0x030000")], battery=True, bluetooth=True)
        self.assertEqual(flags, "1 0 0 0 1 0")
        self.assertIn("intel-media-driver", packages)
        self.assertIn("bluez", packages)
        self.assertIn("libspa-bluetooth", packages)

    def test_amd(self):
        flags, packages = self.detect(gpus=[("0x1002", "0x164e", "0x030000")], cpu="AuthenticAMD")
        self.assertEqual(flags, "0 1 0 0 0 0")
        self.assertIn("mesa-vaapi", packages)
        self.assertIn("linux-firmware-amd", packages)
        self.assertNotIn("intel-media-driver", packages)

    def test_hybrid_nvidia_detected_as_3d_controller(self):
        flags, packages = self.detect(gpus=[("0x8086", "0x9a49", "0x030000"), ("0x10de", "0x25a2", "0x030200")])
        self.assertEqual(flags, "1 0 1 0 0 0")
        self.assertIn("linux-firmware-nvidia", packages)

    def test_ethernet_vendor_is_not_a_gpu(self):
        flags, packages = self.detect(gpus=[("0x8086", "0x0116", "0x020000")])
        self.assertEqual(flags, "0 0 0 0 0 0")
        self.assertNotIn("libva-intel-driver", packages)


class InstallerTests(unittest.TestCase):
    def run_installer(self, *args):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            home.mkdir()
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"),
                       XDG_STATE_HOME=str(home / ".local/state"), XDG_DATA_HOME=str(home / ".local/share"))
            result = subprocess.run(["bash", str(BASE / "install.sh"), *args],
                                    env=env, text=True, capture_output=True)
            self.assertEqual(list(home.iterdir()), [], "Plan/preflight wrote to HOME")
            return result

    def test_plan_has_no_writes(self):
        result = self.run_installer("--plan")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("mesa-dri", result.stdout)
        self.assertIn("Modo: plan", result.stdout)

    def test_apply_refuses_noninteractive_context_before_writes(self):
        result = self.run_installer("--apply")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("TTY local", result.stderr)

    def test_reject_invalid_arguments_before_writes(self):
        for arg in ("--timezone=../../etc/passwd", '--keyboard=br";evil', "--locale=invalid", "--unknown"):
            with self.subTest(arg=arg):
                self.assertNotEqual(self.run_installer(arg).returncode, 0)


class SessionTests(unittest.TestCase):
    def test_no_duplicate_start_and_reaps_its_daemons_at_logout(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            fakebin = root / "bin"
            fakebin.mkdir()
            events = root / "events"

            def executable(name, body):
                path = fakebin / name
                path.write_text(body)
                path.chmod(0o700)

            executable("dbus-update-activation-environment", "#!/bin/sh\nexit 0\n")
            executable("pgrep", "#!/bin/sh\nexit 1\n")
            executable("niri", "#!/bin/sh\nexit 0\n")
            for name in ("pipewire", "dms"):
                executable(name, f"#!{sys.executable}\nimport os, signal\n"
                           "signal.signal(signal.SIGTERM, lambda *_: exit(0))\n"
                           f"with open({str(events)!r}, 'a') as f: f.write('{name} ' + str(os.getpid()) + '\\n')\n"
                           "while True: signal.pause()\n")
            sockpath = root / "niri.sock"
            ipc = socket.socket(socket.AF_UNIX)
            try:
                ipc.bind(str(sockpath))
            except PermissionError:
                # Restricted environments can forbid bind(). We only inspect
                # the socket's file type; fake niri never connects to this bus.
                ipc.close()
                ipc = None
                existing = Path("/run/dbus/system_bus_socket")
                if not existing.is_socket():
                    self.skipTest("AF_UNIX bind unavailable and no socket fixture")
                sockpath.symlink_to(existing)
            env = dict(os.environ, PATH=f"{fakebin}:{os.environ['PATH']}",
                       XDG_STATE_HOME=str(root / "state"), XDG_RUNTIME_DIR=tmp,
                       NIRI_SOCKET=str(sockpath))
            cmd = ["bash", str(BASE / "bin/niri-dux-autostart")]
            process = subprocess.Popen(cmd, env=env)
            daemon_pids = []
            try:
                deadline = time.monotonic() + 4
                while time.monotonic() < deadline:
                    lines = events.read_text().splitlines() if events.exists() else []
                    if len(lines) == 2:
                        break
                    time.sleep(0.02)
                self.assertEqual(len(lines), 2, "Session daemons did not start")
                daemon_pids = [int(line.split()[1]) for line in lines]
                second = subprocess.run(cmd, env=env, timeout=3)
                self.assertEqual(second.returncode, 0)
                self.assertEqual(events.read_text().splitlines(), lines)
                if ipc is not None:
                    ipc.close()
                sockpath.unlink()
                self.assertEqual(process.wait(timeout=4), 0)
                for pid in daemon_pids:
                    with self.assertRaises(ProcessLookupError):
                        os.kill(pid, 0)
            finally:
                if ipc is not None:
                    ipc.close()
                if process.poll() is None:
                    process.terminate()
                    process.wait(timeout=4)
                for pid in daemon_pids:
                    try:
                        os.kill(pid, signal.SIGTERM)
                    except ProcessLookupError:
                        pass


if __name__ == "__main__":
    unittest.main()
