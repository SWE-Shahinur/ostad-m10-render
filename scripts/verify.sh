#!/usr/bin/env bash
# Verifies duration (about 30 s), resolution (1080x1920), and that there is no audio stream.
# Usage: verify.sh <video.mp4>
set -euo pipefail

F="$1"
INFO=$(ffprobe -v error -show_entries format=duration:stream=codec_type,width,height -of json "$F")

DUR=$(echo "$INFO" | jq -r '.format.duration | tonumber')
W=$(echo "$INFO" | jq -r '[.streams[] | select(.codec_type == "video")][0].width')
H=$(echo "$INFO" | jq -r '[.streams[] | select(.codec_type == "video")][0].height')
AUDIO=$(echo "$INFO" | jq '[.streams[] | select(.codec_type == "audio")] | length')

echo "duration_seconds=$DUR"
echo "width=$W"
echo "height=$H"
echo "audio_streams=$AUDIO"

awk -v d="$DUR" 'BEGIN { exit !(d >= 29.5 && d <= 30.5) }' || { echo "FAIL: duration not about 30 s"; exit 1; }
[ "$W" = "1080" ] && [ "$H" = "1920" ] || { echo "FAIL: resolution is not 1080x1920"; exit 1; }
[ "$AUDIO" = "0" ] || { echo "FAIL: audio stream found"; exit 1; }
echo "VERIFIED: 30 s, 1080x1920, no audio"
