from collections.abc import Iterable

from .models import OCRDocument, OCRPage


def normalize_text(text: str) -> str:
    lines = [line.strip() for line in text.splitlines()]
    compact = "\n".join(line for line in lines if line)
    while "\n\n\n" in compact:
        compact = compact.replace("\n\n\n", "\n\n")
    return compact.strip()


def build_ocr_document_text(pages: Iterable[OCRPage], include_page_markers: bool = False) -> str:
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
            ocr_document.pages,
            include_page_markers=include_page_markers,
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
