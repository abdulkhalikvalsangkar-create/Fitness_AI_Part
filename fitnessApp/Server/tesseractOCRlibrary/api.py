from pathlib import Path
from typing import Any

from .chunking import Chunker, chunk_text, default_metadata_for_path
from .loader import DocumentLoader
from .models import OCRDocument, OCRPage
from .ocr_engine import TesseractBackend
from .text_merge import build_ocr_document_text


class OCRExtractor:
    def __init__(
        self,
        backend: TesseractBackend | None = None,
        loader: DocumentLoader | None = None,
    ):
        self.backend = backend or TesseractBackend()
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
                "ocr_engine": "tesseract",
            },
        )

    def extract_text(self, source: str | Path, include_page_markers: bool = False) -> str:
        document = self.extract_document(source)
        return build_ocr_document_text(document.pages, include_page_markers=include_page_markers)

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
            text,
            resolved_source,
            chunk_size,
            overlap,
            merged_metadata,
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
