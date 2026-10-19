#!/usr/bin/env bash
# Renders the loop and masters its audio to -14 LUFS / -2 dBTP.
# Output: out/mediku-loop.mp4
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p out

npx remotion render src/index.ts MedikuLoop out/_video.mp4 --muted --crf=18 "$@"
npx remotion render src/index.ts MedikuLoop out/_mix.wav --codec=wav

stats=$(ffmpeg -hide_banner -i out/_mix.wav -af loudnorm=I=-14:TP=-2:LRA=9:print_format=json -f null - 2>&1 | sed -n '/^{/,/^}/p')
measured=$(echo "$stats" | python3 -c "import json,sys;d=json.load(sys.stdin);print(f\"measured_I={d['input_i']}:measured_TP={d['input_tp']}:measured_LRA={d['input_lra']}:measured_thresh={d['input_thresh']}:offset={d['target_offset']}\")")
duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 out/_video.mp4)

ffmpeg -y -loglevel error -i out/_mix.wav \
  -af "loudnorm=I=-14:TP=-2:LRA=9:linear=true:${measured},aresample=192000,alimiter=limit=0.75:attack=2:release=50:level=false,aresample=48000" \
  -t "$duration" -c:a pcm_s16le out/_master.wav
ffmpeg -y -loglevel error -i out/_video.mp4 -i out/_master.wav -map 0:v -map 1:a -c:v copy -c:a aac -b:a 256k -t "$duration" out/mediku-loop.mp4
rm out/_video.mp4 out/_mix.wav out/_master.wav
echo "out/mediku-loop.mp4"
