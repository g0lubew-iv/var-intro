import glob
import os

from PIL import Image

from rembg import remove


def batch_remove_background(input_folder: str, output_folder: str) -> None:
    os.makedirs(output_folder, exist_ok=True)

    extensions = ["*.jpg", "*.jpeg", "*.png", "*.JPG", "*.JPEG"]
    image_files = []

    for ext in extensions:
        image_files.extend(glob.glob(os.path.join(input_folder, ext)))

    for i, image_path in enumerate(image_files, 1):
        with open(image_path, "rb") as f:
            input_image = f.read()

        output_image = remove(input_image)

        filename = os.path.basename(image_path)
        name, ext = os.path.splitext(filename)
        output_path = os.path.join(output_folder, f"{name}_nobg.png")

        with open(output_path, "wb") as f:
            f.write(output_image)


if __name__ == "__main__":
    batch_remove_background("./src", "./img")
