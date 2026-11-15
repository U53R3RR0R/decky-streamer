#!/usr/bin/env bash
# Diagnostic-only GStreamer probe. Does not modify the plugin or start a stream.
# Usage: bash gst-diagnostics.sh > gst-diagnostics.log 2>&1
set -u

section() { printf '\n===== %s =====\n' "$*"; }

section "Operating system"
if [[ -r /etc/os-release ]]; then
    cat /etc/os-release
else
    echo "/etc/os-release is unavailable"
fi
uname -a

section "GStreamer commands"
for bin in gst-launch-1.0 gst-inspect-1.0; do
    if command -v "$bin" >/dev/null 2>&1; then
        printf '%s: %s\n' "$bin" "$(command -v "$bin")"
    else
        printf '%s: NOT FOUND\n' "$bin"
    fi
done
if ! command -v gst-launch-1.0 >/dev/null 2>&1 || ! command -v gst-inspect-1.0 >/dev/null 2>&1; then
    echo "Install/provide the GStreamer command-line tools, then rerun this script."
    exit 1
fi

echo
gst-launch-1.0 --version 2>&1

section "Inherited runtime environment"
printf 'PATH=%s\n' "${PATH:-<unset>}"
printf 'GST_PLUGIN_PATH=%s\n' "${GST_PLUGIN_PATH:-<unset>}"
printf 'GST_PLUGIN_SYSTEM_PATH=%s\n' "${GST_PLUGIN_SYSTEM_PATH:-<unset>}"
printf 'LD_LIBRARY_PATH=%s\n' "${LD_LIBRARY_PATH:-<unset>}"
printf 'LD_PRELOAD=%s\n' "${LD_PRELOAD:-<unset>}"
printf 'GST_REGISTRY=%s\n' "${GST_REGISTRY:-<default>}"

section "Required and fallback pipeline elements"
elements=(
    pipewiresrc videoconvert videoscale videorate queue
    vaapih264enc x264enc h264parse h264timestamper flvmux
    rtmpsink rtmp2sink pulsesrc audioconvert audioresample audiorate
    avenc_aac fdkaacenc faac voaacenc aacparse
)
for element in "${elements[@]}"; do
    printf '\n--- gst-inspect-1.0 %s ---\n' "$element"
    # GST_DEBUG=2 reports GStreamer warnings/errors from plugin loading while
    # retaining the command's normal plugin/search-path configuration.
    if GST_DEBUG=2 GST_DEBUG_NO_COLOR=1 gst-inspect-1.0 "$element"; then
        echo "RESULT: available"
    else
        rc=$?
        printf 'RESULT: unavailable (exit %s)\n' "$rc"
    fi
done

section "End"
echo "This is a runtime inventory only; no capture pipeline was started."
echo "For a failed stream, attach this output and the complete Decky Streamer stderr log."
echo "Redact stream keys, tokens, private URLs, and personal details before sharing."
