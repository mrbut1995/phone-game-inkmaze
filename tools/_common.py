#!/usr/bin/env python3
"""Shared helpers for the project tools (Python 3.8+, stdlib only)."""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Never scanned by any tool (ai_helper is opt-in: copies of project files live there).
IGNORE_DIRS = {".godot", ".git", ".import", ".mono", ".vscode", ".idea", "__pycache__",
               "node_modules", "export", "ai_helper", ".logs"}
IGNORE_SUFFIXES = (".uid", ".import", ".tmp", ".translation")
HIDDEN_FILES = {".gitkeep", ".gdignore", ".DS_Store", "Thumbs.db"}
TEXT_EXTS = {".gd", ".tscn", ".tres", ".godot", ".cfg", ".json", ".md", ".txt", ".svg",
             ".gdshader", ".csv", ".py", ".yml", ".yaml", ".ini"}


def setup_stdout() -> None:
    try:
        import signal
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # quiet `| head`
    except Exception:
        pass
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
        except Exception:
            pass


def norm(path: str) -> str:
    """Normalise a user path: forward slashes, no res:// prefix, no leading ./"""
    p = path.replace("\\", "/")
    if p.startswith("res://"):
        p = p[6:]
    while p.startswith("./"):
        p = p[2:]
    return p


def read_text(path) -> str:
    return Path(path).read_text(encoding="utf-8", errors="replace")


def estimate_tokens(text: str) -> int:
    """Rough token estimate (about 3.6 chars/token for code). Good enough for budgeting."""
    return int(len(text) / 3.6) + 1


def iter_files(base: str = "", include_ai_helper: bool = False, exts=None, include_hidden: bool = False):
    """Yield project-relative posix paths, sorted, skipping noise (.godot, *.uid, *.import ...)."""
    start = ROOT / base if base else ROOT
    ignore = set(IGNORE_DIRS)
    if include_ai_helper:
        ignore.discard("ai_helper")
    if start.is_file():
        yield start.relative_to(ROOT).as_posix()
        return
    for dirpath, dirnames, filenames in os.walk(start):
        dirnames[:] = sorted(d for d in dirnames if d not in ignore)
        for name in sorted(filenames):
            if name.endswith(IGNORE_SUFFIXES):
                continue
            if not include_hidden and name in HIDDEN_FILES:
                continue
            if exts and Path(name).suffix.lower() not in exts:
                continue
            yield (Path(dirpath) / name).relative_to(ROOT).as_posix()


def load_json(path: Path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default


# ---------------------------------------------------------------- GDScript parsing
_RE_CLASS = re.compile(r"^class_name\s+(\w+)", re.M)
_RE_EXTENDS = re.compile(r"^extends\s+(.+?)\s*$", re.M)
_RE_SIGNAL = re.compile(r"^signal\s+(\w+)\s*(\([^)]*\))?", re.M)
_RE_EXPORT = re.compile(r"^@export\w*(?:\(.*?\))?\s+var\s+(\w+)(.*)$", re.M)
_RE_FUNC = re.compile(r"^(static\s+)?func\s+(\w+)\s*\(([^)]*)\)\s*(?:->\s*([\w.\[\]]+))?\s*:", re.M)
_RE_ENUM = re.compile(r"^enum\s+(\w+)?\s*\{([^}]*)\}", re.M)
_RE_CONST = re.compile(r"^const\s+(\w+)", re.M)
_RE_INNER = re.compile(r"^class\s+(\w+)(?:\s+extends\s+(\w+))?\s*:", re.M)


def parse_gd(text: str) -> dict:
    info = {
        "class_name": (_RE_CLASS.search(text).group(1) if _RE_CLASS.search(text) else ""),
        "extends": (_RE_EXTENDS.search(text).group(1).strip('"') if _RE_EXTENDS.search(text) else ""),
        "tool": bool(re.search(r"^@tool", text, re.M)),
        "signals": [f"{m.group(1)}{m.group(2) or ''}" for m in _RE_SIGNAL.finditer(text)],
        "enums": [f"{m.group(1) or '(anon)'}{{{','.join(x.strip().split('=')[0].strip() for x in m.group(2).split(',') if x.strip())}}}"
                  for m in _RE_ENUM.finditer(text)],
        "consts": [m.group(1) for m in _RE_CONST.finditer(text)],
        "inner": [m.group(1) for m in _RE_INNER.finditer(text)],
        "exports": [],
        "funcs": [],
        "doc": "",
        "has_contract": "## Scene contract" in text,
    }
    for m in _RE_EXPORT.finditer(text):
        rest = m.group(2)
        t = re.match(r"\s*:\s*([\w.\[\]]+)", rest)
        d = re.search(r"=\s*(.+?)\s*:?\s*$", rest)
        info["exports"].append((m.group(1), t.group(1) if t else "", d.group(1) if d else ""))
    for m in _RE_FUNC.finditer(text):
        args = re.sub(r"\s*=\s*[^,)]+", "", m.group(3)).strip()
        info["funcs"].append({"name": m.group(2), "args": args, "ret": m.group(4) or "",
                              "static": bool(m.group(1))})
    for line in text.splitlines():
        if line.startswith("##"):
            info["doc"] = line.lstrip("#").strip()
            break
    return info


def format_outline(path: str, show_private: bool = False) -> str:
    text = read_text(ROOT / path)
    g = parse_gd(text)
    head = f"{path}"
    if g["class_name"]:
        head += f"  class {g['class_name']}"
    if g["extends"]:
        head += f" extends {g['extends']}"
    if g["tool"]:
        head += "  @tool"
    out = [head]
    if g["doc"]:
        out.append(f"  doc: {g['doc']}")
    if g["signals"]:
        out.append("  signals: " + "; ".join(g["signals"]))
    if g["enums"]:
        out.append("  enums: " + "; ".join(g["enums"]))
    if g["consts"]:
        out.append("  consts: " + ", ".join(g["consts"]))
    if g["exports"]:
        out.append("  exports: " + "; ".join(f"{n}: {t}" + (f" = {d}" if d else "") for n, t, d in g["exports"]))
    funcs = [f for f in g["funcs"] if show_private or not f["name"].startswith("_")]
    if funcs:
        out.append("  funcs:")
        for f in funcs:
            out.append(f"    {'static ' if f['static'] else ''}{f['name']}({f['args']})" + (f" -> {f['ret']}" if f["ret"] else ""))
    if g["inner"]:
        out.append("  inner classes: " + ", ".join(g["inner"]))
    return "\n".join(out)


def class_index() -> dict:
    """class_name -> project-relative path."""
    result = {}
    for p in iter_files(exts={".gd"}):
        m = _RE_CLASS.search(read_text(ROOT / p))
        if m:
            result[m.group(1)] = p
    return result


# ---------------------------------------------------------------- tscn / tres parsing
_HEADER = re.compile(r"^\[(\w+)(.*)\]\s*$")
_ATTR = re.compile(r'(\w+)=(?:"((?:[^"\\]|\\.)*)"|ExtResource\("([^"]+)"\)|(\[[^\]]*\])|([^\s\]]+))')
_PROP = re.compile(r"^([\w/.:]+)\s*=\s*(.*)$")


def _depth(s: str) -> int:
    depth, in_str, i = 0, False, 0
    while i < len(s):
        c = s[i]
        if in_str:
            if c == "\\":
                i += 1
            elif c == '"':
                in_str = False
        elif c == '"':
            in_str = True
        elif c in "{[(":
            depth += 1
        elif c in "}])":
            depth -= 1
        i += 1
    return depth


def parse_tscn(text: str) -> dict:
    ext, subs, nodes, conns = {}, {}, [], []
    resource_props = {}
    section, cur = None, None
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        i += 1
        if not line.strip() or line.startswith(";"):
            continue
        h = _HEADER.match(line)
        if h:
            kind = h.group(1)
            attrs = {}
            for m in _ATTR.finditer(h.group(2)):
                key = m.group(1)
                attrs[key] = next((g for g in m.groups()[1:] if g is not None), "")
                if m.group(3) is not None:
                    attrs[key + "__ext"] = m.group(3)
            section = kind
            cur = None
            if kind == "ext_resource":
                ext[attrs.get("id", "")] = {"type": attrs.get("type", ""), "path": norm(attrs.get("path", ""))}
            elif kind == "sub_resource":
                subs[attrs.get("id", "")] = attrs.get("type", "")
            elif kind == "node":
                inst = attrs.get("instance__ext")
                cur = {"name": attrs.get("name", ""), "type": attrs.get("type", ""),
                       "parent": attrs.get("parent"), "instance": inst, "props": {}, "line": i}
                nodes.append(cur)
            elif kind == "connection":
                conns.append({"signal": attrs.get("signal", ""), "from": attrs.get("from", ""),
                              "to": attrs.get("to", ""), "method": attrs.get("method", ""), "line": i})
            continue
        p = _PROP.match(line)
        if p:
            value = p.group(2)
            depth = _depth(value)
            while depth > 0 and i < len(lines):
                value += "\n" + lines[i]
                i += 1
                depth = _depth(value)
            if section == "node" and cur is not None:
                cur["props"][p.group(1)] = value
            elif section == "resource":
                resource_props[p.group(1)] = value
    for n in nodes:
        n["instance_path"] = ext.get(n["instance"], {}).get("path", "") if n["instance"] else ""
        sm = re.match(r'ExtResource\("([^"]+)"\)', n["props"].get("script", ""))
        n["script"] = ext.get(sm.group(1), {}).get("path", "") if sm else ""
        n["unique"] = n["props"].get("unique_name_in_owner", "").strip() == "true"
    return {"ext": ext, "subs": subs, "nodes": nodes, "conns": conns, "resource": resource_props}


def resolve_scene(res_path: str, cache: dict = None, stack: tuple = ()) -> dict:
    """Merge inherited scenes. Returns {rel_path: node}, root has rel ''. Instanced sub-scenes are opaque."""
    cache = cache if cache is not None else {}
    if res_path in cache:
        return cache[res_path]
    data = parse_tscn(read_text(ROOT / res_path))
    nodes: dict = {}
    for n in data["nodes"]:
        parent = n["parent"]
        if parent is None:
            rel = ""
        elif parent == ".":
            rel = n["name"]
        else:
            rel = f"{parent}/{n['name']}"
        entry = None
        if parent is None and n["instance_path"] and n["instance_path"] not in stack and res_path not in stack:
            base = resolve_scene(n["instance_path"], cache, stack + (res_path,))
            for k, v in base.items():
                nodes[k] = dict(v)
            entry = nodes[""]
            entry["name"] = n["name"]
        if entry is None:
            entry = nodes.get(rel)
        if entry is None:
            entry = {"rel": rel, "name": n["name"], "type": n["type"], "script": "", "script_scene": "",
                     "instance_path": n["instance_path"] if parent is not None else "", "unique": False,
                     "props": {}, "scene": res_path, "line": n["line"]}
            nodes[rel] = entry
        if n["type"]:
            entry["type"] = n["type"]
        if n["script"]:
            entry["script"] = n["script"]
            entry["script_scene"] = res_path
        if n["unique"]:
            entry["unique"] = True
        if parent is not None and n["instance_path"]:
            entry["instance_path"] = n["instance_path"]
        entry["props"] = {**entry["props"], **n["props"]}
        entry["rel"] = rel
        entry["scene"] = res_path
    cache[res_path] = nodes
    return nodes
