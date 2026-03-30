#!/usr/bin/env python3
"""
build.py - Convert DU Navigator Lua source files to DU JSON export format.

Usage: python build.py
Reads from src/, writes to dist/

Each .lua source file uses handler blocks delimited by:
    --[[@
    slot=<slot_key>
    event=<eventSignature()>
    args=<comma,separated,args or blank>
    ]]
    <lua code here>
"""

import json
import re
import os

# ── Slot configurations for each script ───────────────────────
CONFIGS = {
    "ship_screen": {
        "output": "Navigator_Ship_Screen_v1.0.txt",
        "slots": {
            "0":  {"name": "screen"},
            "1":  {"name": "databank"},
            "2":  {"name": "core"},
            "3":  {"name": "receiver"},
            "4":  {"name": "emitter"},
            "-1": {"name": "unit"},
            "-2": {"name": "construct"},
            "-3": {"name": "player"},
            "-4": {"name": "system"},
            "-5": {"name": "library"},
        }
    },
    "ship_noscreen": {
        "output": "Navigator_Ship_NoScreen_v1.0.txt",
        "slots": {
            "0":  {"name": "databank"},
            "1":  {"name": "core"},
            "2":  {"name": "receiver"},
            "3":  {"name": "emitter"},
            "-1": {"name": "unit"},
            "-2": {"name": "construct"},
            "-3": {"name": "player"},
            "-4": {"name": "system"},
            "-5": {"name": "library"},
        }
    },
    "base": {
        "output": "Navigator_Base_v1.0.txt",
        "slots": {
            "0":  {"name": "screen"},
            "1":  {"name": "databank"},
            "2":  {"name": "receiver"},
            "3":  {"name": "emitter"},
            "-1": {"name": "unit"},
            "-2": {"name": "construct"},
            "-3": {"name": "player"},
            "-4": {"name": "system"},
            "-5": {"name": "library"},
        }
    },
    "orgbase": {
        "output": "Navigator_OrgBase_v1.0.txt",
        "slots": {
            "0":  {"name": "screen"},
            "1":  {"name": "databank"},
            "2":  {"name": "receiver"},
            "3":  {"name": "emitter"},
            "-1": {"name": "unit"},
            "-2": {"name": "construct"},
            "-3": {"name": "player"},
            "-4": {"name": "system"},
            "-5": {"name": "library"},
        }
    },
}

def make_slot_entry(name):
    return {"name": name, "type": {"events": [], "methods": []}}

def parse_handlers(lua_content):
    """Extract handler blocks using --[[@...]] markers."""
    handlers = []
    pattern = re.compile(
        r'--\[\[@\n(.*?)\]\]\n(.*?)(?=--\[\[@|\Z)',
        re.DOTALL
    )
    key = 0
    for m in pattern.finditer(lua_content):
        meta_str = m.group(1)
        code     = m.group(2).strip()
        meta = {}
        for line in meta_str.strip().split('\n'):
            line = line.strip()
            if '=' in line:
                k, v = line.split('=', 1)
                meta[k.strip()] = v.strip()
        handlers.append({'meta': meta, 'code': code, 'key': str(key)})
        key += 1
    return handlers

def build_filter(meta):
    """Build DU handler filter object from metadata."""
    slot_key  = meta.get('slot', '-1')
    event_str = meta.get('event', 'onStart()')
    args_str  = meta.get('args', '').strip()

    args = []
    if args_str:
        for arg in args_str.split(','):
            arg = arg.strip().strip('"\'')
            if arg == '*':
                args.append({'variable': '*'})
            elif arg:
                args.append({'value': arg})

    return {
        'args':      args,
        'signature': event_str,
        'slotKey':   slot_key,
    }

def build_du_handler(handler, slot_name_map):
    meta     = handler['meta']
    code     = handler['code']
    slot_key = meta.get('slot', '-1')
    event    = meta.get('event', 'onStart()')
    slot_nm  = slot_name_map.get(slot_key, 'unit')
    full_code = f"--{slot_nm}.{event}\n{code}\n--"
    return {
        'code':   full_code,
        'filter': build_filter(meta),
        'key':    handler['key'],
    }

def build(source_name, config):
    src_path = os.path.join('src', source_name + '.lua')
    out_path = os.path.join('dist', config['output'])

    print(f"Building {src_path}  →  {out_path}")

    with open(src_path, 'r', encoding='utf-8') as f:
        lua_content = f.read()

    slot_name_map = {k: v['name'] for k, v in config['slots'].items()}
    slots_du      = {k: make_slot_entry(v['name']) for k, v in config['slots'].items()}

    raw_handlers = parse_handlers(lua_content)
    du_handlers  = [build_du_handler(h, slot_name_map) for h in raw_handlers]

    du_json = {
        'slots':    slots_du,
        'handlers': du_handlers,
        'methods':  [],
        'events':   [],
    }

    os.makedirs('dist', exist_ok=True)
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(du_json, f, separators=(',', ':'), ensure_ascii=False)

    print(f"  OK  ({len(du_handlers)} handlers, {len(slots_du)} slots)")

if __name__ == '__main__':
    print("=== DU Navigator Build ===")
    for name, cfg in CONFIGS.items():
        build(name, cfg)
    print("\nDone. Import .txt files from dist/ into DU programming boards.")
