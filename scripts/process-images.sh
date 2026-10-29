#!/usr/bin/env bash
# Convert file names to lowercase:
# $ for f in *; do [ -e "$f" ] && mv -- "$f" "$(echo "$f" | tr '[:upper:]' '[:lower:]')"; done
#
# Normalise product images for the shop:
#   - remove the background (rembg)
#   - trim to the product, scale it to fit (no stretching) with padding
#   - centre it on a solid #f6f6f6 canvas of a fixed size
#   - compress and strip metadata
#   - Takes any mix of image files and folders, including subfolders (jpg, png, webp).
#   - Removes the background, trims to the product and scales it to fill 88% of the canvas so it isn't stretched or touching the edges. It then centres the product on #f6f6f6.
#   - Fixes sideways phone photos and strips metadata.
#   - Skips an image that's already the target size with a #f6f6f6 border. -F forces it to be processed again.
#   - Writes to ./processed/ with the same folder structure by default. -i overwrites the originals instead, so commit them to git first.
#   - Logs the file size before and after, and warns when a small source had to be enlarged and may look soft.
#
# #Use WebP for compression. Background-free photos saved 
# as PNG get bigger. For example, valet-kit-1.png went from 419 KB to 812 KB, 
# but as WebP it's 64 KB. The default keeps file names 
# so the HTML links don't break.
# Add -f webp (or -f jpg) to change the output format.
#
#
# Images that are already the target size with a #f6f6f6 border are skipped.
#
# Requirements: python3, Pillow, rembg
# $ python3 -m venv .venv
# $ source .venv/bin/activate
# $ pip3 install "rembg[cpu]" pillow
#
# Usage: $ scripts/process-images.sh [options] <image|directory>...
# Examples:
# $ scripts/process-images.sh -f webp images/products              # --> ./processed/
# $ scripts/process-images.sh images/products/photo.jpg            # --> ./processed/
# $ scripts/process-images.sh images/products/photo.jpg -r         # Remove background from image
# $ scripts/process-images.sh -s 1002x1013 path/to/photo.jpg       # set size

set -euo pipefail

SIZE="1000x1000"   # square matches the .thumb { aspect-ratio: 1 } cards
BG="f6f6f6"
PAD="0.88"         # product fills at most 88% of the canvas width/height
QUALITY="82"
FORMAT="keep"      # keep | jpg | webp
MODEL="isnet-general-use"
OUT_DIR="processed"
REMOVE_BG=0        # Remove background from image
IN_PLACE=0
FORCE=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] <image|directory>...

Options:
  -s WxH       Output size (default: $SIZE)
  -b HEX       Background colour without '#' (default: $BG)
  -p FRACTION  Max share of the canvas the product may fill (default: $PAD)
  -q 1-100     JPEG/WebP quality (default: $QUALITY)
  -f FORMAT    keep | jpg | webp (default: $FORMAT; keep preserves file names)
  -m MODEL     rembg model (default: $MODEL; also u2net, birefnet-general)
  -o DIR       Output directory, mirrors the input tree (default: ./$OUT_DIR)
  -r           Remove the photo's background (rembg) and keep only the product
  -i           Process in place (overwrites originals; commit them first)
  -F           Force: reprocess images that already look done
  -h           Show this help
EOF
}

while getopts ":s:b:p:q:f:m:o:riFh" opt; do
  case $opt in
    s) SIZE=$OPTARG ;;
    b) BG=${OPTARG#\#} ;;
    p) PAD=$OPTARG ;;
    q) QUALITY=$OPTARG ;;
    f) FORMAT=$OPTARG ;;
    m) MODEL=$OPTARG ;;
    o) OUT_DIR=$OPTARG ;;
    r) REMOVE_BG=1 ;;
    i) IN_PLACE=1 ;;
    F) FORCE=1 ;;
    h) usage; exit 0 ;;
    :) echo "Option -$OPTARG needs a value" >&2; usage >&2; exit 2 ;;
    *) echo "Unknown option -$OPTARG" >&2; usage >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
[[ $# -gt 0 ]] || { usage >&2; exit 2; }

[[ $SIZE =~ ^([0-9]+)x([0-9]+)$ ]] || { echo "Bad size: $SIZE (expected WxH)" >&2; exit 2; }
WIDTH=${BASH_REMATCH[1]} HEIGHT=${BASH_REMATCH[2]}
[[ $BG =~ ^[0-9a-fA-F]{6}$ ]] || { echo "Bad colour: $BG (expected RRGGBB)" >&2; exit 2; }
[[ $QUALITY =~ ^[0-9]+$ ]] && (( QUALITY >= 1 && QUALITY <= 100 )) || { echo "Bad quality: $QUALITY" >&2; exit 2; }
[[ $FORMAT =~ ^(keep|jpg|webp)$ ]] || { echo "Bad format: $FORMAT" >&2; exit 2; }

command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
deps="import PIL"
(( REMOVE_BG )) && deps="import PIL, rembg"
if ! python3 -c "$deps" 2>/dev/null; then
  if (( REMOVE_BG )); then
    echo "Missing Python packages. Install with:  pip install \"rembg[cpu]\" pillow" >&2
  else
    echo "Missing Python package. Install with:  pip install pillow" >&2
  fi
  exit 1
fi

out_abs=""
(( IN_PLACE )) || { mkdir -p "$OUT_DIR"; out_abs=$(realpath "$OUT_DIR"); }

# Map a source path to its destination, changing the extension if needed.
dest_for() {
  local src=$1 rel=$2 dst
  if (( IN_PLACE )); then dst=$src; else dst="$out_abs/$rel"; fi
  case $FORMAT in
    jpg)  dst="${dst%.*}.jpg" ;;
    webp) dst="${dst%.*}.webp" ;;
  esac
  printf '%s' "$dst"
}

# Build a NUL-separated list of "src dst" pairs for the Python worker.
pairs=$(mktemp)
trap 'rm -f "$pairs"' EXIT
count=0
for input in "$@"; do
  if [[ -d $input ]]; then
    root=$(realpath "$input")
    while IFS= read -r -d '' f; do
      f=$(realpath "$f")
      [[ -n $out_abs && $f == "$out_abs"/* ]] && continue   # Don't re-read the output
      printf '%s\0%s\0' "$f" "$(dest_for "$f" "${f#"$root"/}")" >>"$pairs"
      count=$((count + 1))
    done < <(find "$root" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 | sort -z)
  elif [[ -f $input ]]; then
    f=$(realpath "$input")
    printf '%s\0%s\0' "$f" "$(dest_for "$f" "$(basename "$f")")" >>"$pairs"
    count=$((count + 1))
  else
    echo "Not found: $input" >&2
  fi
done
(( count > 0 )) || { echo "No images found." >&2; exit 1; }
echo "Found $count image(s) -> ${SIZE}, background #${BG}, format ${FORMAT}, remove background: $( (( REMOVE_BG )) && echo yes || echo no )"

W=$WIDTH H=$HEIGHT BG=$BG PAD=$PAD QUALITY=$QUALITY MODEL=$MODEL REMOVE_BG=$REMOVE_BG FORCE=$FORCE \
python3 - "$pairs" <<'PY'
import os, sys, tempfile
from PIL import Image, ImageOps

W, H = int(os.environ["W"]), int(os.environ["H"])
BG = tuple(int(os.environ["BG"][i:i + 2], 16) for i in (0, 2, 4))
PAD = float(os.environ["PAD"])
QUALITY = int(os.environ["QUALITY"])
REMOVE_BG = os.environ["REMOVE_BG"] == "1"
FORCE = os.environ["FORCE"] == "1"
TOLERANCE = 6  # allow for JPEG noise when checking the background

with open(sys.argv[1], "rb") as fh:
    parts = fh.read().split(b"\0")[:-1]
jobs = [(parts[i].decode(), parts[i + 1].decode()) for i in range(0, len(parts), 2)]


def already_done(path):
    """Target size, opaque and the border is the background colour."""
    try:
        with Image.open(path) as im:
            if im.size != (W, H):
                return False
            if im.mode in ("RGBA", "LA", "PA") and im.getchannel("A").getextrema()[0] < 255:
                return False
            rgb = im.convert("RGB")
    except Exception:
        return False
    points = [(x, y) for x in (0, W // 4, W // 2, 3 * W // 4, W - 1) for y in (0, H - 1)]
    points += [(x, y) for x in (0, W - 1) for y in (H // 4, H // 2, 3 * H // 4)]
    return all(max(abs(a - b) for a, b in zip(rgb.getpixel(p), BG)) <= TOLERANCE for p in points)


def save(img, dst):
    ext = os.path.splitext(dst)[1].lower()
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(dst), suffix=ext)
    os.close(fd)
    try:
        if ext in (".jpg", ".jpeg"):
            img.save(tmp, "JPEG", quality=QUALITY, optimize=True, progressive=True)
        elif ext == ".webp":
            img.save(tmp, "WEBP", quality=QUALITY, method=6)
        else:
            img.save(tmp, "PNG", optimize=True)
        os.chmod(tmp, 0o644)
        os.replace(tmp, dst)  # Atomic: a crash never leaves a half-written image
    except BaseException:
        os.unlink(tmp)
        raise


session = None
done = skipped = failed = 0
for n, (src, dst) in enumerate(jobs, 1):
    label = f"[{n}/{len(jobs)}] {os.path.relpath(src)}"
    if not FORCE and (already_done(src) or already_done(dst)):
        print(f"{label}: skipped (already {W}x{H} on #{os.environ['BG']})")
        skipped += 1
        continue
    try:
        before = os.path.getsize(src)
        with Image.open(src) as im:
            im = ImageOps.exif_transpose(im)  # honour camera rotation
            im = im.convert("RGBA")

        # Determine whether to remove the image background
        if REMOVE_BG:
            if session is None:
                from rembg import new_session, remove
                print(f"Loading background-removal model '{os.environ['MODEL']}' (first run downloads it)...")
                session = new_session(os.environ["MODEL"])
            cut = remove(im, session=session, post_process_mask=True)
        else:
            cut = im   # Keep the original background of the image

        # Trim to the product, ignoring faint alpha haze left by the mask.
        bbox = cut.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
        if bbox is None:
            print(f"{label}: WARNING no foreground detected, using the whole image")
            cut, bbox = im, (0, 0, im.width, im.height)
        product = cut.crop(bbox)

        scale = min(W * PAD / product.width, H * PAD / product.height)
        note = ""
        if scale > 1.5:
            note = f" (WARNING upscaled {scale:.1f}x, may look soft; use a larger source)"
        new_size = (max(1, round(product.width * scale)), max(1, round(product.height * scale)))
        product = product.resize(new_size, Image.LANCZOS)

        canvas = Image.new("RGB", (W, H), BG)
        canvas.paste(product, ((W - new_size[0]) // 2, (H - new_size[1]) // 2), product)
        save(canvas, dst)

        after = os.path.getsize(dst)
        print(f"{label}: {before // 1024} KB -> {after // 1024} KB -> {dst}{note}")
        done += 1
    except Exception as e:
        print(f"{label}: FAILED {e}", file=sys.stderr)
        failed += 1

print(f"\nDone: {done} processed, {skipped} skipped, {failed} failed")
sys.exit(1 if failed else 0)
PY
