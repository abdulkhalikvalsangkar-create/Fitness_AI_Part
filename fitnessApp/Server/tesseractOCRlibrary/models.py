from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


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
