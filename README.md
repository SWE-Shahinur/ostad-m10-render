# ostad-m10-render

Free GitHub Actions + FFmpeg renderer for a **silent, 30-second, vertical (1080×1920) YouTube Short**.
Part of the Ostad Module 10 YouTube Automation assignment.

## Important limitation

The video is **image-motion animation (Ken Burns effect)**: a slow zoom and pan over five still images, each shown for 6 seconds.
It is **not AI image-to-video generation**. No video model is used.

## What it does

1. n8n sends a `payload` (JSON string) to the `render-shorts` workflow.
2. `fetch_images.sh` downloads five images from `image.pollinations.ai` and checks each with ffprobe.
3. `render.sh` builds five silent 6-second clips with `zoompan`, adds readable text overlays, and concatenates them into one 30-second MP4.
4. `verify.sh` checks duration (about 30 s), resolution (1080×1920), and that there is no audio stream.
5. The MP4 is uploaded as a workflow artifact and published as a prerelease, which gives a direct download URL.

## Payload format

```json
{
  "job_id": "job-20261029-01",
  "images": [
    "https://image.pollinations.ai/prompt/...?width=1080&height=1920",
    "...four more..."
  ],
  "overlays": [
    "Scene one text",
    "Scene two text",
    "Scene three text",
    "Scene four text",
    "Scene five text"
  ]
}
```

- Exactly 5 images and 5 overlays.
- Images must come from `https://image.pollinations.ai/`.
- Keep each overlay short (about 40 characters) for readability.

## Triggering from n8n (no secrets in this repo)

`POST https://api.github.com/repos/SWE-Shahinur/ostad-m10-render/actions/workflows/render.yml/dispatches`

```json
{ "ref": "main", "inputs": { "payload": "<payload JSON as a string>" } }
```

Headers: `Accept: application/vnd.github+json`, `X-GitHub-Api-Version: 2022-11-28`, and a fine-grained token in the n8n credential.

**Minimum token permissions** (fine-grained, this repository only):
- Actions: Read and write (dispatch the workflow, read runs)
- Contents: Read (read the workflow file and releases)

The token must be stored only in an n8n credential. Never commit it to this repository.

## Free-tier notes

- GitHub-hosted runners for public repositories are free.
- Pollinations' anonymous tier allows about 1 image per 45 seconds per IP, so `fetch_images.sh` waits 50 seconds between downloads.
- Nothing in this pipeline uses a paid API.

## Output

- Workflow artifact `final-short-<run_id>` (14 days)
- Prerelease `short-<job_id>-<run_id>` with `final_<job_id>.mp4`

Public releases are visible to anyone with the link. Uploading to YouTube is a separate step and requires explicit approval.

## Local test

```bash
sudo apt-get install -y ffmpeg fonts-dejavu-core jq
bash scripts/fetch_images.sh payload.json work
bash scripts/render.sh payload.json work
bash scripts/verify.sh work/final.mp4
```
