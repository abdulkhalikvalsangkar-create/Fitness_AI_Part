"""
Tesseract OCR Engine
Thin, robust wrapper around pytesseract.
"""

import logging
import platform
from pathlib import Path
from typing import Any

import pytesseract
from PIL import Image

from .config import TESSERACT_PATH, OCR_LANG, OCR_CONFIG

# --- Logging Setup ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- Tesseract Command Path ---
pytesseract.pytesseract.tesseract_cmd = TESSERACT_PATH


class TesseractBackend:
    """
    Backend implementation using Tesseract OCR.
    """
    def __init__(self, config: str = OCR_CONFIG, lang: str = OCR_LANG):
        self.config = config
        self.lang = lang

    def extract_text(
        self,
        image: Image.Image | str | Path,
        prompt: str | None = None,
        extraction_schema: dict[str, Any] | None = None,
    ) -> str:
        """
        Run Tesseract OCR on a PIL Image or file path.
        """
        if isinstance(image, (str, Path)):
            img = Image.open(image)
        else:
            img = image

        try:
            text = pytesseract.image_to_string(
                img,
                lang=self.lang,
                config=self.config,
            )
            return text.strip()
        except pytesseract.TesseractNotFoundError:
            if platform.system() == "Windows":
                msg = (
                    "Tesseract not found. "
                    "Install it with: winget install UB-Mannheim.TesseractOCR "
                    "or set TESSERACT_PATH in config.py"
                )
            else:
                msg = (
                    "Tesseract not found. "
                    "Install it with: sudo apt install tesseract-ocr "
                    "or set TESSERACT_PATH in config.py"
                )
            logger.error(msg)
            return ""
        except Exception as e:
            logger.error(f"OCR failed: {e}")
            return ""

    def run_ocr_with_confidence(self, image: Image.Image) -> dict:
        """
        Run OCR and also return a mean confidence score (0–100).
        """
        text = self.extract_text(image)
        confidence = -1.0
        try:
            data = pytesseract.image_to_data(
                image,
                lang=self.lang,
                config=self.config,
                output_type=pytesseract.Output.DICT,
            )
            scores = [int(c) for c in data["conf"] if str(c).lstrip("-").isdigit() and int(c) >= 0]
            if scores:
                confidence = round(sum(scores) / len(scores), 2)
        except Exception:
            pass

        return {"text": text, "confidence": confidence}

    def is_loaded(self) -> bool:
        # Tesseract is always 'loaded' as it's an external binary call
        return True
