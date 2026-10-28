#!/usr/bin/env bash
# Renders five silent 6-second Ken Burns (image-motion) clips and merges them.
# Usage: render.sh <payload.json> <work_dir>
#
# This is image-motion animation (slow zoom on a still image), NOT AI image-to-video.
set -euo pipefail

PAYLOAD="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
WORK="$2"
FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf

cd "$WORK"

for i in 1 2 3 4 5; do
  # Wrap overlay text so it stays readable on a vertical frame.
  jq -r ".overlays[$((i-1))]" "$PAYLOAD" | fold -s -w 22 > "overlay$i.txt"

  # 150 frames at 25 fps = 6 seconds.
  # Scale-and-crop to 9:16, zoom slowly, output 1080x1920, add text in a dark box, no audio.
  ffmpeg -y -loglevel error -i "scene$i.jpg" \
    -vf "scale=2160:3840:force_original_aspect_ratio=increase,crop=2160:3840,zoompan=z='min(zoom+0.0009,1.25)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=150:s=1080x1920:fps=25,drawtext=fontfile=$FONT:textfile=overlay$i.txt:fontcolor=white:fontsize=64:line_spacing=12:box=1:boxcolor=black@0.55:boxborderw=28:x=(w-text_w)/2:y=h*0.72,format=yuv420p" \
    -frames:v 150 -an -c:v libx264 -preset veryfast -crf 20 -movflags +faststart \
    "clip$i.mp4"
  echo "Clip $i rendered"
done

printf "file 'clip1.mp4'\nfile 'clip2.mp4'\nfile 'clip3.mp4'\nfile 'clip4.mp4'\nfile 'clip5.mp4'\n" > list.txt

ffmpeg -y -loglevel error -f concat -safe 0 -i list.txt -c copy -an -movflags +faststart final.mp4
echo "final.mp4 rendered"
