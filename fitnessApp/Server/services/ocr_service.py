import os
import sys
import tempfile
from pathlib import Path
from typing import Any

# Add Server directory to path to allow absolute imports
sys.path.insert(0, str(Path(__file__).parent.parent))

# Import the OCR library we have
from tesseractOCRlibrary.api import extract_ocr_chunks, extract_ocr_text


def process_image_to_text(image_bytes: bytes, file_name: str) -> str:
    """
    Process image bytes and return extracted text.
    """
    # Write bytes to a temporary file
    with tempfile.NamedTemporaryFile(
        suffix=Path(file_name).suffix, 
        delete=False
    ) as temp_file:
        temp_file.write(image_bytes)
        temp_path = temp_file.name
    
    try:
        # Extract text using our OCR library
        text = extract_ocr_text(temp_path, include_page_markers=True)
        return text
    finally:
        # Clean up temporary file
        if os.path.exists(temp_path):
            os.unlink(temp_path)


def process_image_to_chunks(
    image_bytes: bytes, 
    file_name: str,
    chunk_size: int = 1200,
    overlap: int = 150
) -> list[dict[str, Any]]:
    """
    Process image bytes and return chunks.
    """
    # Write bytes to a temporary file
    with tempfile.NamedTemporaryFile(
        suffix=Path(file_name).suffix, 
        delete=False
    ) as temp_file:
        temp_file.write(image_bytes)
        temp_path = temp_file.name
    
    try:
        # Extract chunks using our OCR library
        chunks = extract_ocr_chunks(
            temp_path, 
            source_name=file_name, 
            chunk_size=chunk_size, 
            overlap=overlap
        )
        return chunks
    finally:
        # Clean up temporary file
        if os.path.exists(temp_path):
            os.unlink(temp_path)
