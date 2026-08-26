#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build a self-contained offline HTML doc-site from OptionWorkstation docs/*.md.

Usage: python build.py
Output: docs-site/index.html  (single-page with left nav, no external requests)
"""
import os
import re
import html as html_mod
import markdown as md

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # repo root
DOCS_DIR = os.path.join(ROOT, "docs")  # source .md live here
OUT_DIR = os.path.dirname(os.path.abspath(__file__))  # docs-site/ where build.py lives
OUT_FILE = os.path.join(OUT_DIR, "index.html")

# Ordered, human-friendly nav entries. (filename, nav title)
NAV = [
    ("00-文档总览.md", "文档总览"),
    ("01-项目章程.md", "01 项目章程"),
    ("02-需求规格说明书.md", "02 需求规格说明书"),
    ("03-架构设计说明书.md", "03 架构设计说明书"),
    ("04-接口设计说明书.md", "04 接口设计说明书"),
    ("05-项目计划.md", "05 项目计划"),
    ("06-需求跟踪矩阵.md", "06 需求跟踪矩阵"),
    ("07-风险登记册.md", "07 风险登记册"),
    ("08-测试计划与测试用例.md", "08 测试计划与用例"),
    ("09-验收标准.md", "09 验收标准"),
    ("10-配置与版本管理计划.md", "10 配置与版本管理"),
    ("R4-交易API排查清单.md", "R4 交易API排查清单"),
    ("操作手册.md", "操作手册（根目录）"),
]

# Files that already exist elsewhere (operation manual lives at repo root)
EXTRA_RESOLVE = {
    "操作手册.md": os.path.join(ROOT, "操作手册.md"),
}
# Also auto-include any README*.md at docs root if present
for f in sorted(os.listdir(DOCS_DIR)):
    if f.lower().startswith("readme") and f.endswith(".md") and f not in [n for n, _ in NAV]:
        NAV.append((f, "README 索引"))

IGNORE = {"API.md", "ARCHITECTURE.md", "DATA_SOURCES.md", "DEVELOPMENT.md",
          "ENGINEERING_STANDARDS.md", "EXAMPLE_DATA.md", "MODEL_LIMITATIONS.md",
          "RELEASE_CHECKLIST.md", "THREAT_MODEL.md", "00-文档总览.md"}


def resolve_path(fname):
    if fname in EXTRA_RESOLVE:
        return EXTRA_RESOLVE[fname]
    return os.path.join(DOCS_DIR, fname)


def collect():
    pages = []
    for fname, title in NAV:
        path = resolve_path(fname)
        if not os.path.exists(path):
            # try lowercase-allowed fallback
            alt = os.path.join(DOCS_DIR, fname)
            if os.path.exists(alt):
                path = alt
            else:
                print(f"[skip] missing: {fname}")
                continue
        with open(path, encoding="utf-8") as fh:
            src = fh.read()
        # strip a leading H1 only if it duplicates the nav title? keep as-is.
        body = md.markdown(
            src,
            extensions=["tables", "fenced_code", "toc", "codehilite"],
        )
        pages.append({"file": fname, "title": title, "html": body})
    return pages


PAGE_TPL = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>OptionWorkstation 文档站</title>
<style>
  :root{{
    --bg:#f5f7fa; --panel:#ffffff; --ink:#1f2329; --muted:#646a73;
    --line:#e7e7e7; --brand:#0052d9; --brand-soft:#ecf2fe; --code-bg:#f3f3f3;
  }}
  *{{box-sizing:border-box}}
  body{{margin:0;font-family:"Segoe UI","Microsoft YaHei",system-ui,Arial,sans-serif;
       background:var(--bg);color:var(--ink);line-height:1.7;font-size:15px}}
  header{{background:var(--brand);color:#fff;padding:14px 22px;position:sticky;top:0;z-index:20;
         box-shadow:0 2px 8px rgba(0,0,0,.12)}}
  header h1{{margin:0;font-size:18px;font-weight:600;letter-spacing:.3px}}
  header small{{opacity:.85;font-weight:400}}
  .layout{{display:flex;min-height:calc(100vh - 52px)}}
  nav{{width:268px;flex:0 0 268px;background:var(--panel);border-right:1px solid var(--line);
       padding:14px 0;position:sticky;top:52px;height:calc(100vh - 52px);overflow:auto}}
  nav a{{display:block;padding:9px 20px;color:var(--muted);text-decoration:none;font-size:14px;
        border-left:3px solid transparent}}
  nav a:hover{{background:var(--brand-soft);color:var(--brand)}}
  nav a.active{{color:var(--brand);border-left-color:var(--brand);background:var(--brand-soft);font-weight:600}}
  nav .grp{{padding:10px 20px 4px;font-size:12px;text-transform:uppercase;color:#a6a6a6;letter-spacing:.5px}}
  main{{flex:1;padding:28px 40px 80px;max-width:980px;margin:0 auto}}
  main h1{{font-size:25px;margin:.2em 0 .6em;border-bottom:2px solid var(--brand);padding-bottom:.3em}}
  main h2{{font-size:20px;margin:1.6em 0 .6em;color:#0052d9;font-weight:600}}
  main h3{{font-size:16.5px;margin:1.3em 0 .4em}}
  main h4{{font-size:14.5px;margin:1.1em 0 .3em;color:#366ef4}}
  main p{{margin:.5em 0}}
  main table{{border-collapse:collapse;width:100%;margin:1em 0;font-size:14px}}
  main th,main td{{border:1px solid var(--line);padding:8px 10px;text-align:left;vertical-align:top}}
  main th{{background:var(--brand-soft);color:var(--brand);font-weight:600}}
  main tr:nth-child(even) td{{background:#fafbfc}}
  main code{{background:var(--code-bg);padding:2px 6px;border-radius:4px;font-size:13px;
            font-family:"Cascadia Code",Consolas,monospace;color:#c00}}
  main pre{{background:#1e1e1e;color:#e6e6e6;padding:16px 18px;border-radius:8px;overflow:auto;
            font-size:13px;line-height:1.55;font-family:"Cascadia Code",Consolas,monospace}}
  main pre code{{background:none;color:inherit;padding:0}}
  main blockquote{{border-left:4px solid var(--brand);margin:1em 0;padding:.4em 14px;background:var(--brand-soft);color:#333}}
  main ul,main ol{{padding-left:1.5em;margin:.5em 0}}
  main a{{color:var(--brand)}}
  .doc{{display:none}}
  .doc.active{{display:block}}
  .fx{{position:fixed;right:18px;bottom:18px;background:var(--brand);color:#fff;border:none;
       padding:10px 16px;border-radius:24px;font-size:13px;cursor:pointer;box-shadow:0 3px 10px rgba(0,0,0,.25)}}
  @media(max-width:760px){{nav{{display:none}}main{{padding:18px}}}}
</style>
</head>
<body>
<header>
  <h1>OptionWorkstation <small>· 项目配套文档站（离线版）</small></h1>
</header>
<div class="layout">
  <nav>
    <div class="grp">文档导航</div>
    {nav_items}
  </nav>
  <main>
    {pages}
  </main>
</div>
<button class="fx" onclick="window.scrollTo({{top:0,behavior:'smooth'}})">↑ 顶部</button>
<script>
var docs = Array.prototype.slice.call(document.querySelectorAll('.doc'));
var links = Array.prototype.slice.call(document.querySelectorAll('nav a'));
function show(i){{
  docs.forEach(function(d,j){{d.classList.toggle('active', j===i);}});
  links.forEach(function(l,j){{l.classList.toggle('active', j===i);}});
  document.querySelector('main').scrollTop = 0;
  window.scrollTo({{top:0,behavior:'instant'}});
  try{{location.hash = '#' + docs[i].id;}}catch(e){{}}
}}
links.forEach(function(l,i){{l.addEventListener('click', function(e){{e.preventDefault();show(i);}});}});
// deep-link
var idx = 0;
if(location.hash){{
  var h = location.hash.slice(1);
  docs.forEach(function(d,i){{ if(d.id===h) idx=i; }});
}}
show(idx);
</script>
</body>
</html>
"""


def slug(title, n):
    return "doc-" + str(n)


def build():
    pages = collect()
    if not pages:
        print("[error] no pages collected")
        return
    nav_items = []
    page_html = []
    for i, p in enumerate(pages):
        sid = slug(p["title"], i)
        nav_items.append(f'<a href="#{sid}" data-i="{i}">{html_mod.escape(p["title"])}</a>')
        page_html.append(f'<section class="doc" id="{sid}">{p["html"]}</section>')
    out = PAGE_TPL.format(nav_items="\n    ".join(nav_items),
                           pages="\n".join(page_html))
    with open(OUT_FILE, "w", encoding="utf-8") as fh:
        fh.write(out)
    print(f"[ok] wrote {OUT_FILE}  ({len(pages)} pages, {len(out)} bytes)")


if __name__ == "__main__":
    build()
