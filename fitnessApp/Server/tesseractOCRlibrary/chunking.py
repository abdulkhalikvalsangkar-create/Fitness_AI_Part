from collections.abc import Callable
from pathlib import Path
from typing import Any

from .models import DocumentChunk
from .text_merge import normalize_text


Chunker = Callable[[str, str, int | None, int | None, dict[str, Any] | None], list[dict[str, Any]]]


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
        "ocr_engine": "glm-ocr",
    }
