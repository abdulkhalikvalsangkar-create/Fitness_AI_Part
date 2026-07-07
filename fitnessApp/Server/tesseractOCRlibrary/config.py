"""
OCRMODEL Configuration
Central config file — edit paths and settings here.
"""

import os
import platform
import multiprocessing
from pathlib import Path

# --- OCR Language ------------------------------------------------------------
OCR_LANG = "eng+fra"

# --- Tesseract Path -----------------------------------------------------------
# Auto-detect OS; override manually if Tesseract is in a non-standard location.
_current_dir = Path(__file__).parent.resolve()

if platform.system() == "Windows":
    # Use relative path to Tesseract-OCR folder in the same directory as this config file
    TESSERACT_PATH = str(_current_dir / "Tesseract-OCR" / "tesseract.exe")
    # Set TESSDATA_PREFIX explicitly for reliability
    os.environ["TESSDATA_PREFIX"] = str(_current_dir / "Tesseract-OCR" / "tessdata")
    # Poppler path for PDF conversion (pdf2image) - fallback to system PATH on server
    POPPLER_PATH = None
else:
    # On Linux server, use system-installed tesseract
    TESSERACT_PATH = "/usr/bin/tesseract"   # standard on Ubuntu/Debian
    POPPLER_PATH = None

# --- OCR Engine Config --------------------------------------------------------
# --oem 3  -> LSTM + legacy engine (best accuracy)
# --psm 6  -> Assume a uniform block of text
OCR_CONFIG = "--oem 3 --psm 6"

# --- Supported Formats --------------------------------------------------------
SUPPORTED_FORMATS = {
    "image": [".png", ".jpg", ".jpeg", ".bmp", ".tiff", ".tif", ".webp"],
    "pdf":   [".pdf"],
    "ppt":   [".ppt", ".pptx"],
}

# --- Performance -------------------------------------------------------------
# Use all available CPU cores (max 8 as per system spec)
MAX_WORKERS = min(multiprocessing.cpu_count(), 8)

# DPI for PDF -> image conversion (higher = better quality but slower)
PDF_DPI = 200

# --- Preprocessing ------------------------------------------------------------
# Resize factor applied before OCR (1.5 = scale up by 50% for small images)
RESIZE_FACTOR = 1.5

# --- Logging -----------------------------------------------------------------
LOG_LEVEL = "INFO"   # DEBUG | INFO | WARNING | ERROR
