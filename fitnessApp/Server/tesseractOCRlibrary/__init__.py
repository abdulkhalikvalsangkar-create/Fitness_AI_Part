from .api import OCRExtractor, extract_ocr_chunks, extract_ocr_text
from .chunking import chunk_text
from .models import DocumentChunk, OCRDocument, OCRPage
from .ocr_engine import TesseractBackend
from .text_merge import merge_native_and_ocr

__all__ = [
    "DocumentChunk",
    "TesseractBackend",
    "OCRDocument",
    "OCRExtractor",
    "OCRPage",
    "chunk_text",
    "extract_ocr_chunks",
    "extract_ocr_text",
    "merge_native_and_ocr",
]

__version__ = "2.0.0"
