#!/usr/bin/env bash
# Downloads the five scene images listed in the payload.
# Usage: fetch_images.sh <payload.json> <output_dir>
#
# Pollinations' anonymous free tier allows about 1 image per 45 seconds per IP,
# so requests are spaced 50 seconds apart and failed downloads are retried.
set -euo pipefail

PAYLOAD="$1"
OUT="$2"
mkdir -p "$OUT"

for i in 1 2 3 4 5; do
  URL=$(jq -r ".images[$((i-1))]" "$PAYLOAD")

  # Only accept the free image host, so the workflow cannot be pointed at arbitrary URLs.
  case "$URL" in
    https://image.pollinations.ai/*) ;;
    *) echo "Image $i rejected: host not allowed" >&2; exit 1 ;;
  esac

  DEST="$OUT/scene$i.jpg"
  OK=0
  for attempt in 1 2 3 4; do
    if curl -fsSL --max-time 150 -o "$DEST" "$URL" && [ -s "$DEST" ]; then
      OK=1
      break
    fi
    echo "Image $i attempt $attempt failed; waiting 50s before retry (free tier limit)" >&2
    sleep 50
  done
  if [ "$OK" -ne 1 ]; then
    echo "Image $i could not be downloaded" >&2
    exit 1
  fi

  # Confirm the file is a real image with dimensions, not an error page.
  if ! ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$DEST" | grep -q .; then
    echo "Image $i is not a valid image" >&2
    exit 1
  fi
  echo "Image $i OK: $(stat -c %s "$DEST") bytes"

  if [ "$i" -lt 5 ]; then
    sleep 50
  fi
done
