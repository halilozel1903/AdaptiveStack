#!/usr/bin/env bash
# Captures the iPad README screenshots of the example app on an iPad Pro 13-inch simulator.
# Usage: scripts/screenshots-ipad.sh <Scheme> <bundle id> <scene>[:landscape] [<scene>[:landscape] ...]
# Writes docs/screenshots/ipad-<scene>.png, for example ipad-full.png and ipad-collapsed.png.
# Exits with an error instead of keeping a blank or stale capture.
#
# Rotation: simctl cannot rotate a simulator and the Simulator app's Rotate menu needs UI scripting,
# so the simulator always stays in its default portrait orientation (1032 x 1376 points).
# - A plain scene is captured as it is: a real portrait layout.
# - A `:landscape` scene is laid out by the app at the landscape size, 1376 x 1032 points, and
#   scaled to fit the screen width (see LandscapeCanvas in Example/Shared/Screenshots.swift). This
#   script then crops the centered 4:3 band out of the portrait capture.
set -euo pipefail

SCHEME="$1"; BUNDLE_ID="$2"; shift 2
SCENES=("$@")
if [ ${#SCENES[@]} -eq 0 ]; then
  echo "No scenes given" >&2
  exit 1
fi
PROJECT="Example/AdaptiveStackDemo.xcodeproj"
OUT="docs/screenshots"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
MIN_BYTES=100000
mkdir -p "$OUT"

# Newest iOS runtime, used only when a simulator has to be created.
RUNTIME=$(xcrun simctl list runtimes available -j | jq -r '
  [.runtimes[] | select(.identifier | test("iOS"))]
  | sort_by(.version | split(".") | map(tonumber)) | last | .identifier // empty')

# pick_device <family> <preferred name pattern> ...
# Prints the UDID of an available simulator of the family ("iPad") on the newest iOS runtime,
# preferring the first pattern that matches. Creates one when none exists.
pick_device() {
  local family="$1"; shift
  local devices udid pattern type
  devices=$(xcrun simctl list devices available -j | jq -c --arg family "^$family" '
    [.devices | to_entries | sort_by(.key) | reverse | .[]
     | select(.key | test("iOS")) | .value[] | select(.name | test($family))]')
  for pattern in "$@"; do
    udid=$(jq -r --arg pattern "$pattern" 'map(select(.name | test($pattern))) | .[0].udid // empty' <<< "$devices")
    if [ -n "$udid" ]; then echo "$udid"; return; fi
  done
  udid=$(jq -r '.[0].udid // empty' <<< "$devices")
  if [ -z "$udid" ]; then
    type=$(xcrun simctl list devicetypes -j | jq -r --arg family "^$family" '
      [.devicetypes[] | select(.name | test($family))] | last | .identifier // empty')
    if [ -z "$type" ] || [ -z "$RUNTIME" ]; then
      echo "No $family simulator, device type or iOS runtime available" >&2
      exit 1
    fi
    udid=$(xcrun simctl create "Screenshots $family" "$type" "$RUNTIME")
  fi
  echo "$udid"
}

IPAD=$(pick_device iPad "^iPad Pro 13" "^iPad Pro" "^iPad Air 13" "^iPad Air")
echo "Using iPad simulator $IPAD"

xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$IPAD" \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM= | tail -n 5

APP=$(find build/Build/Products -name "$SCHEME.app" -maxdepth 2 | head -n 1)
if [ -z "$APP" ]; then
  echo "Build product $SCHEME.app not found" >&2
  exit 1
fi

# pixel_size <file> <pixelWidth|pixelHeight>
pixel_size() {
  sips -g "$2" "$1" 2>/dev/null | awk -v key="$2" '$1 == key ":" { print $2 }'
}

# valid_capture <file> <previous capture or empty>
# A blank frame (app still launching) compresses to a tiny PNG, and a capture identical to the
# previous scene means the app never switched scenes.
valid_capture() {
  local file="$1" previous="$2"
  [ -s "$file" ] || return 1
  [ "$(wc -c < "$file")" -gt "$MIN_BYTES" ] || return 1
  sips -g pixelWidth "$file" > /dev/null 2>&1 || return 1
  if [ -n "$previous" ] && cmp -s "$file" "$previous"; then
    return 1
  fi
  return 0
}

# crop_landscape <file>: keeps the centered band with the landscape aspect ratio (1376:1032 = 4:3)
# of a portrait capture, and checks the result is landscape.
crop_landscape() {
  local file="$1" width height band
  width=$(pixel_size "$file" pixelWidth)
  height=$(pixel_size "$file" pixelHeight)
  if [ -z "$width" ] || [ -z "$height" ]; then
    echo "Could not read the size of $file" >&2
    return 1
  fi
  if [ "$width" -gt "$height" ]; then
    # The simulator came up in landscape after all: the canvas fills the screen already.
    echo "Capture is already landscape (${width}x${height}), not cropping"
    return 0
  fi
  band=$((width * 1032 / 1376))
  sips --cropToHeightWidth "$band" "$width" "$file" > /dev/null
  width=$(pixel_size "$file" pixelWidth)
  height=$(pixel_size "$file" pixelHeight)
  if [ "$height" -ne "$band" ] || [ "$width" -le "$height" ]; then
    echo "Cropping $file produced ${width}x${height}, expected ${width}x${band}" >&2
    return 1
  fi
  echo "Cropped $file to ${width}x${height}"
}

# capture <udid> <device label> <scene>[:landscape] ...: boots the simulator, captures every scene,
# shuts it down again, so the simulator is in a known state.
capture() {
  local udid="$1" device="$2" entry scene mode file raw previous="" attempt ok waited
  shift 2
  local scenes=("$@")
  xcrun simctl shutdown all > /dev/null 2>&1 || true
  xcrun simctl boot "$udid" || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
  xcrun simctl ui "$udid" appearance light
  xcrun simctl install "$udid" "$APP"
  local container home
  container=$(xcrun simctl get_app_container "$udid" "$BUNDLE_ID" data)
  # A first boot can still be setting up the home screen; give it time, then keep a capture of
  # it so a frame where the app never came to the front is rejected.
  sleep 10
  home="$TMP/home-$device.png"
  xcrun simctl io "$udid" screenshot "$home"

  for entry in "${scenes[@]}"; do
    scene="${entry%%:*}"
    mode=""
    if [ "$entry" != "$scene" ]; then mode="${entry#*:}"; fi
    file="$OUT/$device-$scene.png"
    raw="$TMP/$device-$scene.png"
    ok=""
    for attempt in 1 2 3; do
      xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
      sleep 1
      rm -f "$container/tmp/screenshot-ready"
      xcrun simctl launch "$udid" "$BUNDLE_ID" -screenshot "$scene"
      # The app writes this marker once the scene is on screen.
      waited=0
      while [ ! -f "$container/tmp/screenshot-ready" ] && [ "$waited" -lt 60 ]; do
        sleep 1
        waited=$((waited + 1))
      done
      if [ ! -f "$container/tmp/screenshot-ready" ]; then
        echo "The app did not show $scene on $device, retrying"
        continue
      fi
      sleep $((3 + attempt * 2))
      rm -f "$raw"
      xcrun simctl io "$udid" screenshot "$raw"
      if valid_capture "$raw" "$previous" && ! cmp -s "$raw" "$home"; then
        ok=1
        break
      fi
      echo "Blank or stale capture for $device-$scene, retrying"
    done
    if [ -z "$ok" ]; then
      echo "Capture for $device-$scene is still blank; refusing to commit a broken screenshot." >&2
      exit 1
    fi
    # Compare the next scene against this raw, uncropped capture.
    previous="$TMP/previous-$device.png"
    cp "$raw" "$previous"
    if [ "$mode" = "landscape" ]; then
      crop_landscape "$raw" || { echo "Refusing to commit a badly cropped $device-$scene." >&2; exit 1; }
    elif [ -n "$mode" ]; then
      echo "Unknown mode '$mode' for $scene" >&2
      exit 1
    fi
    mv "$raw" "$file"
    echo "Captured $file ($(wc -c < "$file") bytes)"
  done

  xcrun simctl shutdown "$udid" || true
}

capture "$IPAD" ipad "${SCENES[@]}"
