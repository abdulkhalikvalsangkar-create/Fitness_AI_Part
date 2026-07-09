"""
AI Chatbot + OCR Backend API — single-file, single-endpoint build.

Everything (config, OCR engine, chunking, chat service, and Flask routes) lives
in this one module so it can be dropped onto cPanel "Setup Python App" hosting.
The whole API is one endpoint, "/":
  - GET                       -> status / health check
  - POST with a JSON body     -> chat (optional "model": "openai" | "deepseek")
  - POST multipart with "file"-> OCR (image -> text or chunks)

cPanel deployment (Passenger):
  - Application root:        this folder (contains app.py)
  - Application startup file: app.py
  - Application Entry point:  application     (the WSGI callable defined below)
  - Set environment variables in the cPanel UI:
        OPENAI_API_KEY   (required for the chat endpoint when using OpenAI)
        OPENAI_MODEL     (optional, default gpt-4o-mini)
        DEEPSEEK_API_KEY (required for the chat endpoint when using DeepSeek)
        DEEPSEEK_MODEL   (optional, default deepseek-v4-flash)
        DEEPSEEK_BASE_URL(optional, default https://api.deepseek.com)
        GRANITE_MODEL    (optional, default ibm-granite/granite-docling-258M)
        HF_HOME          (optional, Hugging Face cache dir; default <app>/.hf_cache)
        OCR_OUTPUT_FORMAT(optional, "markdown" | "text" | "doctags")

OCR is performed by the ibm-granite/granite-docling-258M vision-language model
(via transformers + torch), so no system tesseract binary is required. The model
weights (~0.5-1 GB) download on first use into HF_HOME -- pre-download them from
the shell before serving (see the deployment notes below). PDF support still
needs `poppler-utils` available for pdf2image.

Requires Python 3.10+.
"""

from __future__ import annotations

import json
import logging
import multiprocessing
import os
import tempfile
from collections.abc import Callable, Iterable, Generator
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Literal

from flask import Flask, request, jsonify
from openai import OpenAI, OpenAIError

# =============================================================================
# Configuration
# =============================================================================

BASE_DIR = Path(__file__).parent.resolve()

# --- Chat model providers -----------------------------------------------------
# The chat endpoint accepts a "model" field in the request body. Anything that
# mentions "deepseek" routes to the DeepSeek provider; everything else (or no
# "model" at all) routes to OpenAI. Each provider pins its own concrete model.
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
DEEPSEEK_MODEL = os.getenv("DEEPSEEK_MODEL", "deepseek-v4-flash")
DEEPSEEK_BASE_URL = os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com")
MAX_TOOL_ROUNDS = int(os.getenv("MAX_TOOL_ROUNDS", "5"))

# --- OCR (Granite Docling vision-language model) -----------------------------
# ibm-granite/granite-docling-258M converts a page image into "DocTags", which
# we render to Markdown / plain text. Runs locally via transformers + torch, so
# no system tesseract binary is needed.
GRANITE_MODEL = os.getenv("GRANITE_MODEL", "ibm-granite/granite-docling-258M")
GRANITE_PROMPT = os.getenv("GRANITE_PROMPT", "Convert this page to docling.")
GRANITE_MAX_NEW_TOKENS = int(os.getenv("GRANITE_MAX_NEW_TOKENS", "4096"))
# OCR result format: "markdown" (default), "text", or "doctags" (raw model output).
OCR_OUTPUT_FORMAT = os.getenv("OCR_OUTPUT_FORMAT", "markdown")
# Cap CPU threads so we stay within cPanel/CloudLinux (LVE) memory limits.
TORCH_NUM_THREADS = int(os.getenv("TORCH_NUM_THREADS", "1"))
PDF_DPI = int(os.getenv("PDF_DPI", "200"))
MAX_WORKERS = min(multiprocessing.cpu_count(), 8)

# Keep the Hugging Face model cache inside the app dir unless overridden, so it
# lands somewhere writable and inside the account's disk quota on cPanel.
os.environ.setdefault("HF_HOME", str(BASE_DIR / ".hf_cache"))

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".tif", ".webp"}
DOCUMENT_EXTENSIONS = {".pdf", ".doc", ".docx", ".txt", ".md", ".pptx"}
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".tiff", ".tif", ".bmp", ".webp"}

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# =============================================================================
# File classification
# =============================================================================

def classify_file(file_name: str | Path) -> Literal["image", "document", "unknown"]:
    """Classify a file as image, document, or unknown based on its extension."""
    suffix = Path(file_name).suffix.lower()
    if suffix in IMAGE_EXTENSIONS:
        return "image"
    if suffix in DOCUMENT_EXTENSIONS:
        return "document"
    return "unknown"


def is_supported(file_name: str | Path) -> bool:
    """Check if file type is supported (image or document)."""
    return classify_file(file_name) != "unknown"


# =============================================================================
# OCR data models
# =============================================================================

@dataclass(slots=True)
class OCRPage:
    page_number: int
    text: str
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class OCRDocument:
    source_path: Path
    pages: list[OCRPage]
    metadata: dict[str, Any] = field(default_factory=dict)

    @property
    def text(self) -> str:
        page_texts = [page.text.strip() for page in self.pages if page.text.strip()]
        return "\n\n".join(page_texts)


@dataclass(slots=True)
class DocumentChunk:
    text: str
    source: str
    chunk_id: int
    char_start: int
    char_end: int
    metadata: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "text": self.text,
            "source": self.source,
            "chunk_id": self.chunk_id,
            "char_start": self.char_start,
            "char_end": self.char_end,
            **self.metadata,
        }


# =============================================================================
# Text merge / normalization
# =============================================================================

def normalize_text(text: str) -> str:
    lines = [line.strip() for line in text.splitlines()]
    compact = "\n".join(line for line in lines if line)
    while "\n\n\n" in compact:
        compact = compact.replace("\n\n\n", "\n\n")
    return compact.strip()


def build_ocr_document_text(
    pages: Iterable[OCRPage], include_page_markers: bool = False
) -> str:
    rendered_pages: list[str] = []
    for page in pages:
        cleaned = normalize_text(page.text)
        if not cleaned:
            continue
        if include_page_markers:
            rendered_pages.append(f"[Page {page.page_number}]\n{cleaned}")
        else:
            rendered_pages.append(cleaned)
    return "\n\n".join(rendered_pages).strip()


def merge_native_and_ocr(
    native_text: str,
    ocr_document: OCRDocument | None,
    include_page_markers: bool = True,
) -> tuple[str, dict[str, object]]:
    native_clean = normalize_text(native_text)
    ocr_text = ""
    if ocr_document is not None:
        ocr_text = build_ocr_document_text(
            ocr_document.pages, include_page_markers=include_page_markers
        )

    if native_clean and ocr_text:
        if ocr_text in native_clean:
            merged = native_clean
        elif native_clean in ocr_text:
            merged = ocr_text
        else:
            merged = f"{native_clean}\n\n[OCR Supplement]\n{ocr_text}"
        origin = "native+ocr"
    elif native_clean:
        merged = native_clean
        origin = "native"
    else:
        merged = ocr_text
        origin = "ocr"

    return merged.strip(), {
        "content_origin": origin,
        "has_ocr": bool(ocr_text),
        "has_native_text": bool(native_clean),
    }


# =============================================================================
# Chunking
# =============================================================================

Chunker = Callable[
    [str, str, "int | None", "int | None", "dict[str, Any] | None"],
    list[dict[str, Any]],
]


def chunk_text(
    text: str,
    source: str = "",
    chunk_size: int = 1200,
    overlap: int = 150,
    metadata: dict[str, Any] | None = None,
) -> list[dict[str, Any]]:
    if overlap >= chunk_size:
        raise ValueError("overlap must be smaller than chunk_size")

    metadata = metadata or {}
    cleaned = normalize_text(text)
    if not cleaned:
        return []

    if len(cleaned) <= chunk_size:
        return [
            DocumentChunk(
                text=cleaned,
                source=source,
                chunk_id=0,
                char_start=0,
                char_end=len(cleaned),
                metadata=metadata,
            ).to_dict()
        ]

    chunks: list[dict[str, Any]] = []
    start = 0
    chunk_id = 0
    while start < len(cleaned):
        end = min(start + chunk_size, len(cleaned))
        if end < len(cleaned):
            for separator in [". ", ".\n", "\n\n", "\n", " "]:
                pos = cleaned.rfind(separator, start, end)
                if pos > start + chunk_size // 2:
                    end = pos + len(separator)
                    break

        chunk = cleaned[start:end].strip()
        if chunk:
            chunks.append(
                DocumentChunk(
                    text=chunk,
                    source=source,
                    chunk_id=chunk_id,
                    char_start=start,
                    char_end=min(end, len(cleaned)),
                    metadata=metadata,
                ).to_dict()
            )
            chunk_id += 1

        if end >= len(cleaned):
            break
        start = end - overlap

    return chunks


def default_metadata_for_path(path: str | Path) -> dict[str, Any]:
    source_path = Path(path)
    return {
        "file_type": source_path.suffix.lower().lstrip("."),
        "is_ocr": True,
        "ocr_engine": "granite-docling",
    }


# =============================================================================
# Document loader (images + PDFs)
# =============================================================================

class DocumentLoader:
    def __init__(self, dpi: int = PDF_DPI, max_pages: int | None = None):
        self.dpi = dpi
        self.max_pages = max_pages

    def load(self, source: str | Path) -> Generator[tuple[int, "Image.Image"], None, None]:
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

    def _load_pdf(self, path: Path) -> Generator[tuple[int, "Image.Image"], None, None]:
        try:
            from pdf2image import convert_from_path
        except ImportError as exc:
            raise ImportError(
                "pdf2image is required for PDF support. Install it with "
                "`pip install pdf2image` and make sure poppler is available."
            ) from exc

        pages = convert_from_path(str(path), dpi=self.dpi)
        for index, image in enumerate(pages, start=1):
            if self.max_pages is not None and index > self.max_pages:
                break
            yield index, image.convert("RGB")

    def _load_image(self, path: Path) -> Generator[tuple[int, "Image.Image"], None, None]:
        from PIL import Image

        image = Image.open(path)
        frame_count = getattr(image, "n_frames", 1)
        for index in range(frame_count):
            page_number = index + 1
            if self.max_pages is not None and page_number > self.max_pages:
                break
            if frame_count > 1:
                image.seek(index)
            yield page_number, image.copy().convert("RGB")

    def _load_directory(self, directory: Path) -> Generator[tuple[int, "Image.Image"], None, None]:
        from PIL import Image

        files = sorted(
            path for path in directory.iterdir() if path.suffix.lower() in IMAGE_SUFFIXES
        )
        if not files:
            raise ValueError(f"No supported image files found in directory: {directory}")

        for index, path in enumerate(files, start=1):
            if self.max_pages is not None and index > self.max_pages:
                break
            yield index, Image.open(path).convert("RGB")


# =============================================================================
# Granite Docling OCR engine (vision-language model)
# =============================================================================

class GraniteDoclingBackend:
    """Runs ibm-granite/granite-docling-258M locally to turn page images into text.

    The processor/model are loaded once and cached at the class level so every
    request reuses the same in-memory instance (loading is expensive).
    """

    _processor = None
    _model = None

    def __init__(self, model_name: str = GRANITE_MODEL):
        self.model_name = model_name

    @classmethod
    def _ensure_loaded(cls, model_name: str) -> None:
        if cls._model is not None:
            return
        import torch

        # transformers renamed the vision->text auto class; support both.
        try:
            from transformers import AutoModelForImageTextToText as _AutoModel
        except ImportError:  # older transformers
            from transformers import AutoModelForVision2Seq as _AutoModel
        from transformers import AutoProcessor

        torch.set_num_threads(TORCH_NUM_THREADS)
        logger.info(
            "Loading Granite Docling model '%s' (first run downloads weights to %s)...",
            model_name,
            os.environ.get("HF_HOME"),
        )
        cls._processor = AutoProcessor.from_pretrained(model_name)
        # low_cpu_mem_usage keeps peak RAM during load down (helps stay under
        # cPanel/CloudLinux LVE limits). dtype replaces the deprecated
        # torch_dtype kwarg on recent transformers; fall back for older ones.
        try:
            cls._model = _AutoModel.from_pretrained(
                model_name, dtype=torch.float32, low_cpu_mem_usage=True
            )
        except TypeError:
            cls._model = _AutoModel.from_pretrained(
                model_name, torch_dtype=torch.float32, low_cpu_mem_usage=True
            )
        cls._model.eval()
        logger.info("Granite Docling model loaded.")

    def extract_text(
        self,
        image: "Image.Image | str | Path",
        prompt: str | None = None,
        extraction_schema: dict[str, Any] | None = None,
    ) -> str:
        """Convert a PIL image (or path) to text using Granite Docling."""
        import torch
        from PIL import Image

        if isinstance(image, (str, Path)):
            image = Image.open(image)
        image = image.convert("RGB")

        try:
            self._ensure_loaded(self.model_name)
        except Exception as exc:
            logger.error("Failed to load Granite Docling model: %s", exc)
            return ""

        cls = GraniteDoclingBackend
        messages = [
            {
                "role": "user",
                "content": [
                    {"type": "image"},
                    {"type": "text", "text": prompt or GRANITE_PROMPT},
                ],
            }
        ]
        try:
            chat_prompt = cls._processor.apply_chat_template(
                messages, add_generation_prompt=True
            )
            inputs = cls._processor(
                text=chat_prompt, images=[image], return_tensors="pt"
            )
            with torch.no_grad():
                generated = cls._model.generate(
                    **inputs, max_new_tokens=GRANITE_MAX_NEW_TOKENS
                )
            trimmed = generated[:, inputs["input_ids"].shape[1]:]
            doctags = cls._processor.batch_decode(
                trimmed, skip_special_tokens=False
            )[0]
            doctags = doctags.replace("<end_of_utterance>", "").strip()
            return self._render(doctags, image)
        except Exception as exc:
            logger.error("Granite Docling OCR failed: %s", exc)
            return ""

    def _render(self, doctags: str, image: "Image.Image") -> str:
        """Render raw DocTags to the configured OCR_OUTPUT_FORMAT."""
        if OCR_OUTPUT_FORMAT == "doctags":
            return doctags
        try:
            from docling_core.types.doc import DoclingDocument
            from docling_core.types.doc.document import DocTagsDocument

            doctags_doc = DocTagsDocument.from_doctags_and_image_pairs(
                [doctags], [image]
            )
            doc = DoclingDocument.load_from_doctags(
                doctags_doc, document_name="Document"
            )
            if OCR_OUTPUT_FORMAT == "text":
                return doc.export_to_text()
            return doc.export_to_markdown()
        except Exception as exc:
            logger.warning(
                "docling_core render failed (%s); returning raw DocTags.", exc
            )
            return doctags

    def is_loaded(self) -> bool:
        return GraniteDoclingBackend._model is not None


# =============================================================================
# OCR extractor (high-level API)
# =============================================================================

class OCRExtractor:
    def __init__(
        self,
        backend: GraniteDoclingBackend | None = None,
        loader: DocumentLoader | None = None,
    ):
        self.backend = backend or GraniteDoclingBackend()
        self.loader = loader or DocumentLoader()

    def extract_document(self, source: str | Path) -> OCRDocument:
        source_path = Path(source)
        pages: list[OCRPage] = []
        for page_number, image in self.loader.load(source_path):
            text = self.backend.extract_text(image)
            pages.append(
                OCRPage(
                    page_number=page_number,
                    text=text,
                    metadata={"page_number": page_number},
                )
            )
        return OCRDocument(
            source_path=source_path,
            pages=pages,
            metadata={
                "page_count": len(pages),
                "file_type": source_path.suffix.lower().lstrip("."),
                "ocr_engine": "granite-docling",
            },
        )

    def extract_text(self, source: str | Path, include_page_markers: bool = False) -> str:
        document = self.extract_document(source)
        return build_ocr_document_text(
            document.pages, include_page_markers=include_page_markers
        )

    def extract_chunks(
        self,
        source: str | Path,
        source_name: str | None = None,
        chunk_size: int = 1200,
        overlap: int = 150,
        metadata: dict[str, Any] | None = None,
        chunker: Chunker | None = None,
    ) -> list[dict[str, Any]]:
        document = self.extract_document(source)
        text = build_ocr_document_text(document.pages, include_page_markers=True)
        resolved_source = source_name or Path(source).name
        merged_metadata = {
            **default_metadata_for_path(source),
            **document.metadata,
            **(metadata or {}),
        }
        chunker_fn = chunker or chunk_text
        return chunker_fn(
            text, resolved_source, chunk_size, overlap, merged_metadata
        )


def extract_ocr_text(
    source: str | Path,
    *,
    extractor: OCRExtractor | None = None,
    include_page_markers: bool = False,
) -> str:
    extractor = extractor or OCRExtractor()
    return extractor.extract_text(source, include_page_markers=include_page_markers)


def extract_ocr_chunks(
    source: str | Path,
    *,
    extractor: OCRExtractor | None = None,
    source_name: str | None = None,
    chunk_size: int = 1200,
    overlap: int = 150,
    metadata: dict[str, Any] | None = None,
    chunker: Chunker | None = None,
) -> list[dict[str, Any]]:
    extractor = extractor or OCRExtractor()
    return extractor.extract_chunks(
        source=source,
        source_name=source_name,
        chunk_size=chunk_size,
        overlap=overlap,
        metadata=metadata,
        chunker=chunker,
    )


# =============================================================================
# OCR service (bytes in -> text / chunks out)
# =============================================================================

def process_image_to_text(image_bytes: bytes, file_name: str) -> str:
    """Process image bytes and return extracted text."""
    with tempfile.NamedTemporaryFile(
        suffix=Path(file_name).suffix, delete=False
    ) as temp_file:
        temp_file.write(image_bytes)
        temp_path = temp_file.name
    try:
        return extract_ocr_text(temp_path, include_page_markers=True)
    finally:
        if os.path.exists(temp_path):
            os.unlink(temp_path)


def process_image_to_chunks(
    image_bytes: bytes,
    file_name: str,
    chunk_size: int = 1200,
    overlap: int = 150,
) -> list[dict[str, Any]]:
    """Process image bytes and return chunks."""
    with tempfile.NamedTemporaryFile(
        suffix=Path(file_name).suffix, delete=False
    ) as temp_file:
        temp_file.write(image_bytes)
        temp_path = temp_file.name
    try:
        return extract_ocr_chunks(
            temp_path,
            source_name=file_name,
            chunk_size=chunk_size,
            overlap=overlap,
        )
    finally:
        if os.path.exists(temp_path):
            os.unlink(temp_path)


def preload_ocr_model() -> bool:
    """Eagerly load the Granite Docling model into memory (warm start).

    Call this once at process startup -- e.g. from passenger_wsgi.py -- so the
    first OCR request doesn't pay the model-load cost. Safe to call more than
    once (subsequent calls are no-ops). Never raises: on failure it logs and
    returns False so a load error can't stop the web app from booting.
    """
    try:
        GraniteDoclingBackend._ensure_loaded(GRANITE_MODEL)
        return True
    except Exception as exc:
        logger.error("OCR model preload failed: %s", exc)
        return False


# =============================================================================
# Chat service (OpenAI + fitness data tools)
# =============================================================================

_clients: dict[str, OpenAI] = {}


def resolve_provider(model_name: str | None) -> tuple[str, str]:
    """Map the request's "model" value to (provider, concrete model id).

    "deepseek", "deepseek-v4-flash", etc. -> DeepSeek; anything else
    (including "openai", "gpt-4o-mini", or missing) -> OpenAI.
    """
    name = (model_name or "").strip().lower()
    if "deepseek" in name:
        return "deepseek", DEEPSEEK_MODEL
    return "openai", OPENAI_MODEL


def get_client(provider: str = "openai") -> OpenAI:
    client = _clients.get(provider)
    if client is not None:
        return client
    if provider == "deepseek":
        api_key = os.getenv("DEEPSEEK_API_KEY")
        if not api_key:
            raise RuntimeError("DEEPSEEK_API_KEY is not set")
        client = OpenAI(api_key=api_key, base_url=DEEPSEEK_BASE_URL)
    else:
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise RuntimeError("OPENAI_API_KEY is not set")
        client = OpenAI(api_key=api_key)
    _clients[provider] = client
    return client


TOOL_DEFINITIONS = [
    {
        "type": "function",
        "function": {
            "name": "get_health_data_by_date",
            "description": "Return every recorded health metric for one specific date.",
            "parameters": {
                "type": "object",
                "properties": {
                    "date": {
                        "type": "string",
                        "description": "Date in ISO-8601 format, e.g. 2023-01-05.",
                    }
                },
                "required": ["date"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_metric_summary",
            "description": (
                "Aggregate one numeric metric (average, min, max, latest) over the "
                "user's history, optionally within a date range."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "metric": {
                        "type": "string",
                        "description": (
                            "Metric field name, e.g. recovery_score, strain, "
                            "sleep_hours, sleep_efficiency, calories_burned, "
                            "workout_minutes, heart_rate, resting_heart_rate, weight."
                        ),
                    },
                    "start_date": {"type": "string", "description": "Optional ISO start date."},
                    "end_date": {"type": "string", "description": "Optional ISO end date."},
                },
                "required": ["metric"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_recent_trend",
            "description": "Return the most recent N daily values of a metric, newest last.",
            "parameters": {
                "type": "object",
                "properties": {
                    "metric": {"type": "string", "description": "Metric field name."},
                    "days": {
                        "type": "integer",
                        "description": "How many recent days to return (default 7).",
                    },
                },
                "required": ["metric"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_activity_history",
            "description": "List workout sessions, optionally filtered by activity type.",
            "parameters": {
                "type": "object",
                "properties": {
                    "activity_type": {
                        "type": "string",
                        "description": "Optional activity filter, e.g. CrossFit, Running.",
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Max sessions to return (default 20).",
                    },
                },
            },
        },
    },
]

FIELD_ALIASES = {
    "day_strain": "strain",
    "avg_heart_rate": "heart_rate",
    "weight_kg": "weight",
    "height_cm": "height",
    "activity_duration_min": "workout_minutes",
}


def _normalize_record(record):
    if not isinstance(record, dict):
        return {}
    normalized = dict(record)
    for alias, canonical in FIELD_ALIASES.items():
        if canonical not in normalized and alias in record:
            normalized[canonical] = record[alias]
    return normalized


def _history(context):
    csv = context.get("csv_health_data")
    if isinstance(csv, dict):
        records = csv.get("user_history") or []
    elif isinstance(csv, list):
        records = csv
    else:
        records = []
    return [_normalize_record(r) for r in records]


def _records(context, key):
    """Read a list-of-records context section (e.g. food/medical datasets)."""
    value = context.get(key)
    if isinstance(value, dict):
        records = value.get("user_history") or []
    elif isinstance(value, list):
        records = value
    else:
        records = []
    return [r for r in records if isinstance(r, dict)]


def _to_float(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _avg(records, field):
    values = [v for v in (_to_float(r.get(field)) for r in records) if v is not None]
    if not values:
        return None
    return round(sum(values) / len(values), 2)


def _tool_get_health_data_by_date(args, context):
    target = args.get("date")
    for record in _history(context):
        if record.get("date") == target:
            return {"date": target, "record": record}
    return {"date": target, "record": None, "note": "No record found for that date."}


def _tool_get_metric_summary(args, context):
    metric = args.get("metric")
    start = args.get("start_date")
    end = args.get("end_date")
    values = []
    latest_value = None
    latest_date = None
    for record in _history(context):
        date = record.get("date")
        if start and date and date < start:
            continue
        if end and date and date > end:
            continue
        val = _to_float(record.get(metric))
        if val is None:
            continue
        values.append(val)
        if latest_date is None or (date and date > latest_date):
            latest_date, latest_value = date, val
    if not values:
        return {"metric": metric, "note": "No data available for this metric/range."}
    return {
        "metric": metric,
        "count": len(values),
        "average": round(sum(values) / len(values), 2),
        "min": min(values),
        "max": max(values),
        "latest": latest_value,
        "latest_date": latest_date,
    }


def _tool_get_recent_trend(args, context):
    metric = args.get("metric")
    days = int(args.get("days", 7))
    dated = [r for r in _history(context) if r.get("date") is not None]
    dated.sort(key=lambda r: r["date"])
    recent = dated[-days:]
    series = [
        {"date": r.get("date"), "value": _to_float(r.get(metric))}
        for r in recent
        if _to_float(r.get(metric)) is not None
    ]
    return {"metric": metric, "days": days, "series": series}


def _tool_get_activity_history(args, context):
    activity_type = args.get("activity_type")
    limit = int(args.get("limit", 20))
    sessions = []
    for record in _history(context):
        act = record.get("activity_type")
        if not act:
            continue
        if activity_type and act.lower() != activity_type.lower():
            continue
        sessions.append(
            {
                "date": record.get("date"),
                "activity_type": act,
                "workout_minutes": record.get("workout_minutes"),
                "calories_burned": record.get("calories_burned"),
                "strain": record.get("strain"),
            }
        )
    return {"activity_type": activity_type, "sessions": sessions[:limit]}


TOOL_EXECUTORS = {
    "get_health_data_by_date": _tool_get_health_data_by_date,
    "get_metric_summary": _tool_get_metric_summary,
    "get_recent_trend": _tool_get_recent_trend,
    "get_activity_history": _tool_get_activity_history,
}


def execute_tool(name, args, context):
    executor = TOOL_EXECUTORS.get(name)
    if executor is None:
        return {"error": "Unknown tool: " + str(name)}
    try:
        return executor(args, context)
    except Exception as e:
        return {"error": "Tool '" + str(name) + "' failed: " + str(e)}


def get_long_term_memory(context):
    return context.get("long_term_memory") or context.get("memory")


def _get_attached_docs(context):
    docs = context.get("attached_docs")
    if isinstance(docs, list):
        return [d for d in docs if isinstance(d, dict)]
    documents_text = context.get("documents")
    if isinstance(documents_text, str) and documents_text.strip():
        return [{"file_name": "Attached documents", "content_summary": documents_text}]
    return []


def _build_food_section(context):
    """Summarize the user's nutrition history (food_intake_dataset) for the prompt."""
    records = _records(context, "food_intake_data")
    if not records:
        return None
    dated = [r for r in records if r.get("date")]
    dated.sort(key=lambda r: r["date"])
    latest = dated[-1] if dated else records[-1]
    span = ""
    if dated:
        span = " (" + str(dated[0]["date"]) + " to " + str(dated[-1]["date"]) + ")"

    def num(field):
        val = _to_float(latest.get(field))
        return "n/a" if val is None else str(val)

    latest_bits = ", ".join([
        "calories: " + num("total_calories_kcal") + " kcal",
        "protein: " + num("protein_g") + " g",
        "carbs: " + num("carbohydrates_g") + " g",
        "fat: " + num("fat_g") + " g",
        "sugar: " + num("sugar_g") + " g",
        "fiber: " + num("fiber_g") + " g",
        "sodium: " + num("sodium_mg") + " mg",
        "water: " + num("water_intake_liters") + " L",
        "diet quality: " + num("diet_quality_score"),
    ])
    avg_bits = []
    for label, field in [
        ("calories", "total_calories_kcal"),
        ("protein", "protein_g"),
        ("carbs", "carbohydrates_g"),
        ("fat", "fat_g"),
        ("sugar", "sugar_g"),
        ("water (L)", "water_intake_liters"),
    ]:
        avg = _avg(records, field)
        if avg is not None:
            avg_bits.append(label + ": " + str(avg))
    section = (
        "NUTRITION DATA - " + str(len(records)) + " daily food-intake records" + span +
        ". Latest day (" + str(latest.get("date")) + ") - " + latest_bits + "."
    )
    if avg_bits:
        section += " Averages over this window - " + ", ".join(avg_bits) + "."
    return section


def _build_medical_section(context):
    """Summarize the user's medical reports (medical_report_dataset) for the prompt."""
    records = _records(context, "medical_report_data")
    if not records:
        return None
    dated = [r for r in records if r.get("date")]
    dated.sort(key=lambda r: r["date"])
    latest = dated[-1] if dated else records[-1]

    def val(field):
        v = latest.get(field)
        return "n/a" if v in (None, "") else str(v)

    measures = ", ".join([
        "blood group: " + val("blood_group"),
        "BMI: " + val("bmi"),
        "BP: " + val("blood_pressure_systolic") + "/" + val("blood_pressure_diastolic"),
        "fasting glucose: " + val("fasting_blood_glucose"),
        "HbA1c: " + val("hba1c"),
        "hemoglobin: " + val("hemoglobin"),
        "vitamin D: " + val("vitamin_d_level"),
        "vitamin B12: " + val("vitamin_b12_level"),
        "cholesterol: " + val("cholesterol_total"),
        "HDL: " + val("hdl"),
        "LDL: " + val("ldl"),
        "triglycerides: " + val("triglycerides"),
    ])
    flags = ", ".join([
        "liver: " + val("liver_function_status"),
        "kidney: " + val("kidney_function_status"),
        "thyroid: " + val("thyroid_status"),
        "inflammation: " + val("inflammation_marker"),
        "allergies: " + val("allergy_flag"),
        "chronic condition: " + val("chronic_condition"),
        "physician risk level: " + val("physician_risk_level"),
    ])
    section = (
        "MEDICAL REPORT - " + str(len(records)) + " report(s) on file. Most recent (" +
        str(latest.get("date")) + ") - " + measures + ". Status flags - " + flags + "."
    )
    summary = latest.get("report_summary")
    if summary:
        section += " Physician summary: " + str(summary)
    section += (
        " Use these clinical values to personalize advice, but do not diagnose; "
        "recommend consulting a doctor for medical concerns."
    )
    return section


def build_system_prompt(context):
    parts = [
        "You are a helpful, knowledgeable fitness and health assistant inside a "
        "mobile fitness app. Give clear, encouraging, personalized guidance based "
        "on the user's data. When a question needs specific numbers, call the "
        "available tools rather than guessing. Never fabricate health values."
    ]
    profile = context.get("user_profile") or {}
    if profile:
        details = []
        if profile.get("name"):
            details.append("name: " + str(profile["name"]))
        if profile.get("age") is not None:
            details.append("age: " + str(profile["age"]))
        if profile.get("gender"):
            details.append("gender: " + str(profile["gender"]))
        if profile.get("height") is not None:
            details.append("height: " + str(profile["height"]) + " cm")
        if profile.get("weight") is not None:
            details.append("weight: " + str(profile["weight"]) + " kg")
        if details:
            parts.append("USER PROFILE - " + ", ".join(details) + ".")
    history = _history(context)
    if history:
        total = len(history)
        dates = [r.get("date") for r in history if r.get("date")]
        span = ""
        if dates:
            span = " spanning " + str(min(dates)) + " to " + str(max(dates))
        csv = context.get("csv_health_data")
        filter_hint = ""
        if isinstance(csv, dict):
            filter_hint = (
                " Currently viewing filter '" + str(csv.get("selected_filter")) +
                "' around '" + str(csv.get("selected_date")) + "'."
            )
        parts.append(
            "HEALTH DATA - " + str(total) + " daily records" + span + "." +
            filter_hint +
            " Use the tools to query specific dates, trends, or metric summaries."
        )
    food_section = _build_food_section(context)
    if food_section:
        parts.append(food_section)
    medical_section = _build_medical_section(context)
    if medical_section:
        parts.append(medical_section)
    long_term_memory = get_long_term_memory(context)
    if long_term_memory:
        parts.append("LONG-TERM MEMORY - " + str(long_term_memory))
    for doc in _get_attached_docs(context):
        if not doc.get("file_name"):
            continue
        summary = doc.get("content_summary") or (doc.get("full_text") or "")[:1500]
        parts.append("ATTACHED DOCUMENT '" + str(doc["file_name"]) + "' - " + summary)
    return "\n\n".join(parts)


def build_openai_messages(messages, context):
    openai_messages = [
        {"role": "system", "content": build_system_prompt(context)}
    ]
    for msg in messages:
        role = msg.get("role")
        if role in ("user", "assistant", "system"):
            openai_messages.append({"role": role, "content": msg.get("content", "")})
    return openai_messages


def run_chat_completion(messages, context, provider="openai", model=OPENAI_MODEL):
    oa = get_client(provider)
    for _ in range(MAX_TOOL_ROUNDS):
        response = oa.chat.completions.create(
            model=model,
            messages=messages,
            tools=TOOL_DEFINITIONS,
            tool_choice="auto",
        )
        choice = response.choices[0].message
        if not choice.tool_calls:
            return choice.content or ""
        messages.append(
            {
                "role": "assistant",
                "content": choice.content or "",
                "tool_calls": [
                    {
                        "id": tc.id,
                        "type": "function",
                        "function": {
                            "name": tc.function.name,
                            "arguments": tc.function.arguments,
                        },
                    }
                    for tc in choice.tool_calls
                ],
            }
        )
        for tool_call in choice.tool_calls:
            try:
                args = json.loads(tool_call.function.arguments or "{}")
            except json.JSONDecodeError:
                args = {}
            result = execute_tool(tool_call.function.name, args, context)
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": json.dumps(result, default=str),
                }
            )
    final = oa.chat.completions.create(model=model, messages=messages)
    return final.choices[0].message.content or ""


def summarize_memory(messages, previous_summary, provider="openai", model=OPENAI_MODEL):
    oa = get_client(provider)
    transcript = "\n".join(
        str(m.get("role")) + ": " + str(m.get("content")) for m in messages
    )
    system = (
        "You maintain a concise long-term memory of a fitness app user. "
        "Merge the previous summary with the new conversation into an updated, "
        "compact summary. Keep durable facts (goals, preferences, constraints, "
        "recurring topics). Drop small talk. Respond with the summary text only."
    )
    user = ""
    if previous_summary:
        user += "PREVIOUS SUMMARY:\n" + str(previous_summary) + "\n\n"
    user += "NEW CONVERSATION:\n" + transcript
    response = oa.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
    )
    return (response.choices[0].message.content or "").strip()


# =============================================================================
# Flask app — single endpoint
# =============================================================================
# Everything goes through "/":
#   GET  /                      -> status
#   POST / (JSON body)          -> chat  (fields: messages, context, model,
#                                         update_memory)
#   POST / (multipart + "file") -> OCR   (form fields: return_type, chunk_size,
#                                         overlap)

app = Flask(__name__)


@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    return response


def _handle_chat():
    data = request.get_json(force=True, silent=True)
    if not data:
        return jsonify({"success": False, "error": "Invalid or missing JSON body"}), 400

    messages = data.get("messages") or []
    if not messages:
        return jsonify({"success": False, "error": '"messages" must not be empty'}), 400

    context = data.get("context") or {}
    update_memory = bool(data.get("update_memory", False))
    provider, model = resolve_provider(data.get("model"))

    openai_messages = build_openai_messages(messages, context)
    reply_text = run_chat_completion(openai_messages, context, provider, model)

    updated_summary = None
    if update_memory:
        updated_summary = summarize_memory(
            messages, get_long_term_memory(context), provider, model
        )

    return jsonify({
        "success": True,
        "mode": "chat",
        "assistant_message": {
            "role": "assistant",
            "content": reply_text,
            "type": "text",
        },
        "provider": provider,
        "model": model,
        "updated_memory_summary": updated_summary,
    })


def _handle_ocr():
    file = request.files["file"]
    if file.filename == "":
        return jsonify({"success": False, "error": "No selected file"}), 400

    file_type = classify_file(file.filename)
    if file_type != "image":
        return jsonify({"success": False, "error": f"Unsupported file type: {file_type}"}), 400

    chunk_size = request.form.get("chunk_size", 1200, type=int)
    overlap = request.form.get("overlap", 150, type=int)
    return_type = request.form.get("return_type", "text")  # 'text' or 'chunks'

    image_bytes = file.read()

    if return_type == "chunks":
        result = process_image_to_chunks(image_bytes, file.filename, chunk_size, overlap)
        return jsonify({"success": True, "mode": "ocr", "type": "chunks", "data": result})

    text = process_image_to_text(image_bytes, file.filename)
    return jsonify({"success": True, "mode": "ocr", "type": "text", "data": text})


@app.route("/", methods=["GET", "POST", "OPTIONS"])
def api():
    if request.method == "OPTIONS":
        return jsonify({"success": True})

    # Status check
    if request.method == "GET":
        return jsonify({
            "message": "AI Chatbot + OCR Backend API",
            "status": "Running",
            "openai_configured": bool(os.getenv("OPENAI_API_KEY")),
            "deepseek_configured": bool(os.getenv("DEEPSEEK_API_KEY")),
            "models": {"openai": OPENAI_MODEL, "deepseek": DEEPSEEK_MODEL},
            "usage": {
                "chat": (
                    'POST JSON with "messages", "context", and optional "model" '
                    '("openai" or "deepseek")'
                ),
                "ocr": (
                    'POST multipart/form-data with a "file" image; optional form '
                    'fields "return_type" ("text" or "chunks"), "chunk_size", '
                    '"overlap"'
                ),
            },
        })

    # POST: a multipart file upload means OCR, a JSON body means chat.
    try:
        if request.files and "file" in request.files:
            return _handle_ocr()
        return _handle_chat()
    except RuntimeError as e:
        return jsonify({"success": False, "error": str(e)}), 503
    except OpenAIError as e:
        return jsonify({"success": False, "error": f"Model provider error: {str(e)}"}), 502
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# WSGI entry point (cPanel / Passenger "Application Entry point": application)
# The OCR model is NOT loaded here -- it lazy-loads on the first /api/ocr
# request (see GraniteDoclingBackend). Loading it at import time can block or
# crash Passenger startup, so we avoid it deliberately.
application = app


if __name__ == "__main__":
    print("=" * 60)
    print("AI Chatbot + OCR Backend API")
    print("=" * 60)
    print("Server Starting...")
    print("Single Endpoint: POST /")
    print("  - JSON body               -> chat")
    print("  - multipart 'file' upload -> OCR")
    print("=" * 60)
    app.run(host="0.0.0.0", port=2000, debug=False, threaded=True)
