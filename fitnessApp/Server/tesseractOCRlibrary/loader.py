from pathlib import Path
from typing import Generator

from PIL import Image

from .config import PDF_DPI

IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".tiff", ".tif", ".bmp", ".webp"}


class DocumentLoader:
    def __init__(self, dpi: int = PDF_DPI, max_pages: int | None = None):
        self.dpi = dpi
        self.max_pages = max_pages

    def load(self, source: str | Path) -> Generator[tuple[int, Image.Image], None, None]:
        path = Path(source)
        if not path.exists():
            raise FileNotFoundError(f"Document not found: {path}")

        if path.is_dir():
            yield from self._load_directory(path)
            return

        suffix = path.suffix.lower()
        if suffix == ".pdf":
            yield from self._load_pdf(path)
            return
        if suffix in IMAGE_SUFFIXES:
            yield from self._load_image(path)
            return

        supported = ", ".join(sorted(IMAGE_SUFFIXES | {".pdf"}))
        raise ValueError(f"Unsupported file type '{suffix}'. Supported: {supported}")

    def _load_pdf(self, path: Path) -> Generator[tuple[int, Image.Image], None, None]:
        try:
            from pdf2image import convert_from_path
        except ImportError as exc:
            raise ImportError(
                "pdf2image is required for PDF support. Install it with `pip install pdf2image` "
                "and make sure poppler is available on the system."
            ) from exc

        pages = convert_from_path(str(path), dpi=self.dpi)
        for index, image in enumerate(pages, start=1):
            if self.max_pages is not None and index > self.max_pages:
                break
            yield index, image.convert("RGB")

    def _load_image(self, path: Path) -> Generator[tuple[int, Image.Image], None, None]:
        image = Image.open(path)
        frame_count = getattr(image, "n_frames", 1)
        for index in range(frame_count):
            page_number = index + 1
            if self.max_pages is not None and page_number > self.max_pages:
                break
            if frame_count > 1:
                image.seek(index)
            yield page_number, image.copy().convert("RGB")

    def _load_directory(self, directory: Path) -> Generator[tuple[int, Image.Image], None, None]:
        files = sorted(
            path for path in directory.iterdir() if path.suffix.lower() in IMAGE_SUFFIXES
        )
        if not files:
            raise ValueError(f"No supported image files found in directory: {directory}")

        for index, path in enumerate(files, start=1):
            if self.max_pages is not None and index > self.max_pages:
                break
            yield index, Image.open(path).convert("RGB")
