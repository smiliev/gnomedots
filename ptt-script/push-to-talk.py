#!/usr/bin/env python3

import asyncio
import subprocess
import os
import sys
from evdev import InputDevice, categorize, ecodes, list_devices

KEY_RIGHTALT = ecodes.KEY_RIGHTALT
BTN_EXTRA = ecodes.BTN_EXTRA

WATCHED_KEYS = {KEY_RIGHTALT, BTN_EXTRA}


def set_mute(muted: bool):
    subprocess.run(
        ["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "1" if muted else "0"],
        check=False,
    )


def device_has_watched_keys(dev: InputDevice) -> bool:
    caps = dev.capabilities()
    keys = caps.get(ecodes.EV_KEY, [])
    return any(k in WATCHED_KEYS for k in keys)


async def monitor_device(dev: InputDevice, tasks: dict):
    print(f"Monitoring: {dev.path} ({dev.name})", flush=True)
    try:
        async for event in dev.async_read_loop():
            if event.type == ecodes.EV_KEY and event.code in WATCHED_KEYS:
                if event.value == 1:
                    set_mute(False)
                elif event.value == 0:
                    set_mute(True)
    except OSError:
        print(f"Device disconnected: {dev.path}", flush=True)
    finally:
        tasks.pop(dev.path, None)


async def watch_for_new_devices(tasks: dict):
    proc = await asyncio.create_subprocess_exec(
        "udevadm", "monitor", "--subsystem-match=input", "--property",
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.DEVNULL,
    )
    async for line in proc.stdout:
        if b"ACTION=add" in line:
            await asyncio.sleep(0.5)
            for path in list_devices():
                if path in tasks:
                    continue
                try:
                    dev = InputDevice(path)
                    if device_has_watched_keys(dev):
                        task = asyncio.ensure_future(monitor_device(dev, tasks))
                        tasks[path] = task
                except (OSError, PermissionError):
                    pass


async def main():
    set_mute(True)
    print("Starting Push-to-Talk...", flush=True)

    tasks: dict[str, asyncio.Task] = {}

    for path in list_devices():
        try:
            dev = InputDevice(path)
            if device_has_watched_keys(dev):
                task = asyncio.ensure_future(monitor_device(dev, tasks))
                tasks[path] = task
        except (OSError, PermissionError):
            pass

    await watch_for_new_devices(tasks)


try:
    asyncio.run(main())
except KeyboardInterrupt:
    set_mute(True)
    sys.exit(0)
