import os
from PIL import Image, ImageDraw

def create_rounded_icon(src_path, output_dir):
    # Load image
    img = Image.open(src_path).convert("RGBA")

    # 1. CROP
    # Crop to 1900x1900 to remove outer white space but keep comfortable margin
    crop_size = 1900
    cx, cy = 1024, 1024
    left = cx - (crop_size / 2)
    top = cy - (crop_size / 2)
    right = cx + (crop_size / 2)
    bottom = cy + (crop_size / 2)
    img = img.crop((left, top, right, bottom))

    # 2. RESIZE CONTENT (Scaled down to fit grid)
    # Standard macOS icon grid: main shape is approx 824x824 within 1024x1024 canvas.
    # This provides the necessary visual padding so it matches other apps.
    content_size = 824
    img = img.resize((content_size, content_size), Image.LANCZOS)

    # 3. CREATE CANVAS (Transparent 1024x1024)
    master_size = 1024
    canvas = Image.new('RGBA', (master_size, master_size), (0, 0, 0, 0))

    # Center the content
    offset = (master_size - content_size) // 2

    # 4. APPLY ROUNDED MASK TO CONTENT
    # We apply the mask to the 'img' (content) BEFORE pasting it onto the canvas,
    # or use a mask when pasting.

    # Create mask for the content size (824x824)
    # Radius ~22% of 824 is approx 180px
    radius = 180
    mask = Image.new('L', (content_size, content_size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (content_size, content_size)], radius=radius, fill=255)

    # Apply mask to the resized content image
    img.putalpha(mask)

    # Paste centered onto the transparent canvas
    canvas.paste(img, (offset, offset), img)

    # 5. GENERATE ALL SIZES
    sizes = {
        "icon_512x512@2x.png": 1024,
        "icon_512x512.png": 512,
        "icon_256x256@2x.png": 512,
        "icon_256x256.png": 256,
        "icon_128x128@2x.png": 256,
        "icon_128x128.png": 128,
        "icon_32x32@2x.png": 64,
        "icon_32x32.png": 32,
        "icon_16x16@2x.png": 32,
        "icon_16x16.png": 16
    }

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for filename, size in sizes.items():
        resized_img = canvas.resize((size, size), Image.LANCZOS)
        resized_img.save(os.path.join(output_dir, filename), "PNG")
        print(f"Generated {filename} ({size}x{size})")

if __name__ == "__main__":
    src = "./culler.png"
    dest = "../Culler/Culler/Assets.xcassets/AppIcon.appiconset"
    create_rounded_icon(src, dest)
