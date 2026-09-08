#!/usr/bin/env python3
"""Read-only thermal/graphics capture; JSON to stdout, no system changes."""

import argparse
import glob
import json
import os
from pathlib import Path
import time


def read(path):
    try:
        return Path(path).read_text().strip()
    except OSError as error:
        return {"error": str(error)}


def collect(patterns):
    return {p: read(p) for pattern in patterns for p in sorted(glob.glob(pattern))}


def blocked_threads():
    result = []
    for path in Path("/proc").glob("[0-9]*/task/[0-9]*/stat"):
        value = read(path)
        if not isinstance(value, str):
            continue
        fields = value[value.rfind(")") + 2:].split()
        if fields and fields[0] == "D":
            result.append({
                "task": str(path.parent),
                "comm": value[value.find("(") + 1:value.rfind(")")],
                "wchan": read(path.parent / "wchan"),
                "stack": read(path.parent / "stack"),
            })
    return result


def snapshot():
    return {
        "monotonic_seconds": time.monotonic(),
        "state": collect([
            "/proc/pressure/*", "/proc/stat", "/proc/diskstats", "/proc/meminfo",
            "/sys/class/thermal/thermal_zone*/temp",
            "/sys/class/thermal/cooling_device*/cur_state",
            "/sys/devices/system/cpu/cpu0/thermal_throttle/*",
            "/sys/class/powercap/intel-rapl:*/energy_uj",
            "/sys/class/powercap/intel-rapl:*/max_energy_range_uj",
            "/sys/class/powercap/intel-rapl:*/constraint_*",
            "/sys/firmware/acpi/platform_profile",
            "/sys/bus/platform/devices/VPC2004:*/fan_mode",
        ]),
        "blocked_threads": blocked_threads(),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seconds", type=int, default=30, choices=range(0, 121),
                        metavar="0..120")
    args = parser.parse_args()
    output = {
        "captured_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "root": os.geteuid() == 0,
        "metadata": collect([
            "/proc/cmdline", "/proc/version",
            "/sys/class/dmi/id/product_name", "/sys/class/dmi/id/product_version",
            "/sys/class/dmi/id/bios_version",
            "/sys/class/thermal/thermal_zone*/type",
            "/sys/class/thermal/thermal_zone*/policy",
            "/sys/class/thermal/thermal_zone*/trip_point_*",
            "/sys/class/thermal/cooling_device*/type",
            "/sys/class/thermal/cooling_device*/max_state",
            "/sys/class/platform-profile/*/name",
            "/sys/class/platform-profile/*/profile",
            "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference",
            "/sys/devices/system/cpu/intel_pstate/*",
            "/sys/module/i915/parameters/enable_psr",
        ]),
        "samples": [],
    }
    started = time.monotonic()
    while True:
        output["samples"].append(snapshot())
        remaining = args.seconds - (time.monotonic() - started)
        if remaining <= 0:
            break
        time.sleep(min(5, remaining))
    debug_root = Path("/sys/kernel/debug/dri")
    try:
        output["graphics_debug"] = collect([
            str(debug_root / "*" / name)
            for name in ["i915_edp_psr_status", "i915_display_info",
                         "i915_dmc_info", "i915_engine_info"]
        ])
        # glob can silently ignore permission errors; record access explicitly.
        list(debug_root.iterdir())
    except OSError as error:
        output["graphics_debug_error"] = str(error)
    json.dump(output, __import__("sys").stdout, indent=2)
    print()


if __name__ == "__main__":
    main()
