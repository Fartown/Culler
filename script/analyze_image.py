from PIL import Image
import sys

def analyze_image(path):
    try:
        img = Image.open(path)
        img = img.convert("RGBA")
        width, height = img.size
        print(f"Original size: {width}x{height}")

        # Get the bounding box of non-zero alpha pixels
        bbox = img.getbbox()
        if bbox:
            print(f"Content bbox (alpha > 0): {bbox}")
            print(f"Content width: {bbox[2] - bbox[0]}")
            print(f"Content height: {bbox[3] - bbox[1]}")

            # center of content
            cx = (bbox[0] + bbox[2]) / 2
            cy = (bbox[1] + bbox[3]) / 2
            print(f"Content center: ({cx}, {cy})")
        else:
            print("Image is fully transparent")

        # Check for non-white content if it is opaque
        # We can convert to grayscale or just check RGB
        # Create a mask where pixel is NOT white (tolerance?)

        # Let's assume white is (255, 255, 255)
        # We need to find the bbox of pixels that are NOT white.
        # If image has alpha, white means (255,255,255, *) but usually we care about visible white.
        # If alpha is 0, it's invisible, so effectively "background".

        bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
        diff = Image.new("1", img.size)

        # Iterate or use better numpy/PIL methods? PIL is safer without numpy dependency.
        # simpler: convert to RGB (dropping alpha, assuming alpha composited over white)
        # actually, let's just look at pixels.

        # optimized way with PIL:
        # Create a white image
        white_bg = Image.new("RGB", img.size, (255, 255, 255))
        # Composite image over white (to handle transparency)
        composite = Image.alpha_composite(Image.new("RGBA", img.size, (255, 255, 255, 255)), img).convert("RGB")

        # Difference from white
        from PIL import ImageChops
        diff = ImageChops.difference(composite, white_bg)
        diff = ImageChops.add(diff, diff, 2.0, -100) # Boost contrast
        bbox_non_white = diff.getbbox()

        if bbox_non_white:
            print(f"Content bbox (non-white): {bbox_non_white}")
            print(f"Non-white width: {bbox_non_white[2] - bbox_non_white[0]}")
            print(f"Non-white height: {bbox_non_white[3] - bbox_non_white[1]}")

            nwx = (bbox_non_white[0] + bbox_non_white[2]) / 2
            nwy = (bbox_non_white[1] + bbox_non_white[3]) / 2
            print(f"Non-white center: ({nwx}, {nwy})")
        else:
            print("Image is fully white")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    analyze_image("culler.png")
