#!/bin/bash

# Push-to-Talk script
# Listens for Right Alt (keyboard) and Mouse Extra button
# Unmutes mic on key/button press, mutes on release
# Auto-detects new devices when plugged in

# Key codes
KEY_RIGHTALT=100
BTN_EXTRA=276

# Mute/unmute functions
mute_mic() {
    pactl set-source-mute @DEFAULT_SOURCE@ 1
}

unmute_mic() {
    pactl set-source-mute @DEFAULT_SOURCE@ 0
}

# Ensure mic is muted on start
mute_mic

echo "Starting Push-to-Talk..."
echo "Listening for Right Alt (code $KEY_RIGHTALT) and Mouse Extra (code $BTN_EXTRA)"

cleanup() {
    mute_mic
    pkill -P $$
    exit 0
}

trap cleanup EXIT INT TERM

monitor_keyboard() {
    local dev="$1"
    stdbuf -oL evtest "$dev" 2>/dev/null | while read line; do
        case "$line" in
            *"code $KEY_RIGHTALT (KEY_RIGHTALT), value 1"*)
                unmute_mic
                ;;
            *"code $KEY_RIGHTALT (KEY_RIGHTALT), value 0"*)
                mute_mic
                ;;
        esac
    done
}

monitor_mouse() {
    local dev="$1"
    stdbuf -oL evtest "$dev" 2>/dev/null | while read line; do
        case "$line" in
            *"code $BTN_EXTRA (BTN_EXTRA), value 1"*)
                unmute_mic
                ;;
            *"code $BTN_EXTRA (BTN_EXTRA), value 0"*)
                mute_mic
                ;;
        esac
    done
}

start_all_monitors() {
    echo "Scanning for devices..."

    # Kill existing monitors
    pkill -P $$ evtest 2>/dev/null
    sleep 0.5

    # Monitor all keyboards
    for dev in /dev/input/by-path/*-kbd; do
        if [ -e "$dev" ]; then
            echo "Monitoring keyboard: $dev"
            monitor_keyboard "$dev" &
        fi
    done

    # Monitor all mice
    for dev in /dev/input/by-path/*-event-mouse; do
        if [ -e "$dev" ]; then
            echo "Monitoring mouse: $dev"
            monitor_mouse "$dev" &
        fi
    done
}

# Initial device scan
start_all_monitors

# Watch for new devices using udevadm monitor
while true; do
    udevadm monitor --subsystem-match=input --property 2>/dev/null | while read line; do
        if echo "$line" | grep -q "ACTION=add"; then
            echo "New device detected..."
            sleep 2
            start_all_monitors
            break
        fi
    done
done
