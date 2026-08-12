#!/usr/bin/env python3
"""Print the UDID of an available iPhone simulator with the newest iOS runtime.

xcodebuild test requires a concrete simulator destination, and the device
lineup differs between GitHub-hosted runner images (and local machines).
Discovering the device at runtime avoids hardcoding a name such as
"iPhone 17" that may not exist on the runner.
"""

import json
import subprocess
import sys


def main() -> int:
    output = subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "available", "--json"],
        text=True,
    )
    devices = json.loads(output)["devices"]

    best = None
    for runtime, entries in devices.items():
        if ".SimRuntime.iOS-" not in runtime:
            continue
        version = tuple(
            int(part) for part in runtime.split(".SimRuntime.iOS-")[-1].split("-")
        )
        for device in entries:
            if not device.get("isAvailable"):
                continue
            if not device["name"].startswith("iPhone"):
                continue
            if best is None or version > best[0]:
                best = (version, device["udid"], device["name"])
            break

    if best is None:
        print("No available iPhone simulator found", file=sys.stderr)
        return 1

    version, udid, name = best
    print(
        "Selected {} (iOS {}) {}".format(name, ".".join(map(str, version)), udid),
        file=sys.stderr,
    )
    print(udid)
    return 0


if __name__ == "__main__":
    sys.exit(main())
