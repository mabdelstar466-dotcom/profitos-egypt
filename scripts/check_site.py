#!/usr/bin/env python3
"""Static preflight checks for GlowSignal and the retained ProfitOS calculator."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PAGES = [
    ROOT / "index.html",
    ROOT / "glowsignal-demo.html",
    ROOT / "workspace.html",
    ROOT / "profitos.html",
    ROOT / "product.html",
    ROOT / "privacy.html",
    ROOT / "terms.html",
    ROOT / "glowsignal-privacy.html",
    ROOT / "glowsignal-terms.html",
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
        self.scripts = []
        self._in_inline_script = False
        self._script_parts = []

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
        if tag == "script" and not a.get("src"):
            self._in_inline_script = True
            self._script_parts = []

    def handle_data(self, data):
        if self._in_inline_script:
            self._script_parts.append(data)

    def handle_endtag(self, tag):
        if tag == "script" and self._in_inline_script:
            self.scripts.append("".join(self._script_parts))
            self._in_inline_script = False
            self._script_parts = []

errors = []
checked_scripts = []
for page in PAGES:
    if not page.is_file():
        errors.append(f"Missing page: {page.relative_to(ROOT)}")
        continue
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
    if page.name == "workspace.html":
        required = {
            "campaignFile", "leadFile", "campaignTemplate", "leadTemplate",
            "exportBtn", "clearBtn", "authEmail", "authPassword",
            "magicLinkBtn", "signupBtn", "loginBtn", "forgotBtn",
            "testConnectionBtn", "saveNewPasswordBtn", "backupBtn", "restoreBtn", "backupFile",
        }
        if required - parser.ids:
            errors.append(f"GlowSignal workspace missing controls: {sorted(required - parser.ids)}")
        source = page.read_text(encoding="utf-8")
        for feature in (
            "function aggregate()", "function testConnection()", "function resetPassword()",
            "function saveNewPassword()", "function exportBackup()", "function restoreBackup(file)", "replace_workspace_data", "costPerQualified",
        ):
            if feature not in source:
                errors.append(f"GlowSignal workspace missing feature: {feature}")
        if source.count("<th>") < 12:
            errors.append("GlowSignal campaign table is missing detailed performance columns")
    if page.name == "glowsignal-privacy.html":
        source = page.read_text(encoding="utf-8")
        if "Supabase" not in source or "localStorage" not in source:
            errors.append("GlowSignal privacy policy does not explain local and cloud storage")
        if "لا يتم إرسال ملفات CSV إلى خادم GlowSignal" in source:
            errors.append("GlowSignal privacy policy still contains the obsolete local-only statement")
    if page.name == "profitos.html":
        needed = {"price","cost","pack","ship","fees","spend","orders","delivered","returns","fixed","net","cpa","perorder","deliveryrate","margin","breakeven"}
        if needed - parser.ids:
            errors.append(f"ProfitOS calculator missing IDs: {sorted(needed - parser.ids)}")
    if shutil.which("node"):
        for number, script in enumerate(parser.scripts, 1):
            if not script.strip():
                continue
            with tempfile.NamedTemporaryFile("w", suffix=".js", encoding="utf-8", delete=False) as temp:
                temp.write(script)
                temp_path = temp.name
            result = subprocess.run(["node", "--check", temp_path], capture_output=True, text=True)
            Path(temp_path).unlink(missing_ok=True)
            if result.returncode:
                errors.append(f"{page.name}: JavaScript syntax error in inline script {number}: {result.stderr.strip()}")
            else:
                checked_scripts.append(f"{page.name}#{number}")

schema = ROOT / "supabase" / "schema.sql"
if not schema.is_file():
    errors.append("Missing supabase/schema.sql")
else:
    sql = schema.read_text(encoding="utf-8")
    for required_sql in (
        "public.workspaces", "public.workspace_members", "public.campaign_daily",
        "public.lead_records", "public.orders", "enable row level security",
        "public.create_workspace", "public.replace_workspace_data",
    ):
        if required_sql.lower() not in sql.lower():
            errors.append(f"Supabase schema missing: {required_sql}")

if not (ROOT / "sitemap.xml").is_file():
    errors.append("Missing sitemap.xml")
if not (ROOT / "robots.txt").is_file():
    errors.append("Missing robots.txt")
if list(ROOT.rglob("*.xlsx")):
    errors.append("Paid workbook must never be committed to public site")

if errors:
    print("FAILED preflight checks:")
    print("\\n".join(" - " + e for e in errors))
    raise SystemExit(1)

print(f"PASS: checked {len(PAGES)} HTML pages, inline JS syntax ({len(checked_scripts)} scripts), local links, GlowSignal auth/analytics controls, Supabase schema, SEO files, paid-file exclusion")
