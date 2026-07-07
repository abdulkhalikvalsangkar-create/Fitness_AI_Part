from pathlib import Path
from typing import Literal


# Define supported file types
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".tif", ".webp"}
DOCUMENT_EXTENSIONS = {".pdf", ".doc", ".docx", ".txt", ".md", ".pptx"}


def classify_file(file_name: str | Path) -> Literal["image", "document", "unknown"]:
    """
    Classify a file as image, document, or unknown based on its extension.
    """
    path = Path(file_name)
    suffix = path.suffix.lower()
    
    if suffix in IMAGE_EXTENSIONS:
        return "image"
    elif suffix in DOCUMENT_EXTENSIONS:
        return "document"
    else:
        return "unknown"


def is_supported(file_name: str | Path) -> bool:
    """Check if file type is supported (image or document)."""
    return classify_file(file_name) != "unknown"
