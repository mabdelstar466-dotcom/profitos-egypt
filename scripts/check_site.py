#!/usr/bin/env python3
"""Static preflight checks for GlowSignal and the retained ProfitOS calculator."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]
PAGES = [
    ROOT / "index.html",
    ROOT / "glowsignal-demo.html",
    ROOT / "profitos.html",
    ROOT / "privacy.html",
    ROOT / "terms.html",
    *sorted((ROOT / "articles").glob("*.html")),
]

class PageParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.ids = set()
        self.has_title = False
        self.has_lang = False
        self.has_description = False

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "html" and a.get("lang") == "ar":
            self.has_lang = True
        if tag == "title":
            self.has_title = True
        if tag == "meta" and a.get("name") == "description":
            self.has_description = True
        if "id" in a:
            self.ids.add(a["id"])
        if tag in ("a", "script", "link") and (a.get("href") or a.get("src")):
            self.links.append(a.get("href") or a.get("src"))

errors = []
for page in PAGES:
    parser = PageParser()
    parser.feed(page.read_text(encoding="utf-8"))
    if not (parser.has_title and parser.has_lang and parser.has_description):
        errors.append(f"{page.name}: missing Arabic language, title, or description")
    for link in parser.links:
        parsed = urlsplit(link)
        if parsed.scheme or parsed.netloc or not parsed.path or link.startswith(("mailto:", "tel:")):
            continue
        target = (page.parent / parsed.path).resolve()
        if ROOT not in target.parents and target != ROOT:
            errors.append(f"{page.name}: link outside repository {link}")
        elif not target.is_file() and not (target.is_dir() and (target / "index.html").is_file()):
            errors.append(f"{page.name}: missing local link {link}")
    if page.name == "profitos.html":
        needed = {"price","cost","pack","ship","fees","spend","orders","delivered","returns","fixed","net","cpa","perorder","deliveryrate","margin","breakeven"}
        if needed - parser.ids:
            errors.append(f"ProfitOS calculator missing IDs: {sorted(needed - parser.ids)}")

if not (ROOT / "sitemap.xml").is_file():
    errors.append("Missing sitemap.xml")
if not (ROOT / "robots.txt").is_file():
    errors.append("Missing robots.txt")
if list(ROOT.rglob("*.xlsx")):
    errors.append("Paid workbook must never be committed to public site")

if errors:
    print("FAILED preflight checks:")
    print("\n".join(" - " + e for e in errors))
    raise SystemExit(1)

print(f"PASS: checked {len(PAGES)} HTML pages, local links, ProfitOS calculator IDs, SEO files, paid-file exclusion")
