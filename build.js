#!/usr/bin/env node
/**
 * build.js - Convert DU Navigator Lua source files to DU JSON export format.
 * Usage: node build.js
 * Reads from src/, writes to dist/
 */

const fs   = require('fs');
const path = require('path');

const CONFIGS = {
  ship_screen: {
    output: 'Navigator_Ship_Screen_v2.0.txt',
    slots: {
       '0': 'screen',   '1': 'databank',
       '2': 'receiver', '3': 'emitter',
       '4': 'archbank',
      '-1': 'unit',    '-2': 'construct', '-3': 'player',
      '-4': 'system',  '-5': 'library',
    }
  },
  ship_noscreen: {
    output: 'Navigator_Ship_NoScreen_v2.0.txt',
    slots: {
       '0': 'databank',
       '1': 'receiver', '2': 'emitter',
       '3': 'screen',   '4': 'archbank',
      '-1': 'unit',    '-2': 'construct', '-3': 'player',
      '-4': 'system',  '-5': 'library',
    }
  },
  base: {
    output: 'Navigator_Base_v2.0.txt',
    slots: {
       '0': 'screen',   '1': 'databank',
       '2': 'receiver', '3': 'emitter',
      '-1': 'unit',    '-2': 'construct', '-3': 'player',
      '-4': 'system',  '-5': 'library',
    }
  },
  orgbase_admin: {
    output: 'Navigator_OrgBase_Admin_v2.0.txt',
    slots: {
       '0': 'screen',   '1': 'databank',
      '-1': 'unit',    '-2': 'construct', '-3': 'player',
      '-4': 'system',  '-5': 'library',
    }
  },
  orgbase_sync: {
    output: 'Navigator_OrgBase_Sync_v2.0.txt',
    slots: {
       '0': 'screen',   '1': 'databank',
       '2': 'receiver', '3': 'emitter',
      '-1': 'unit',    '-2': 'construct', '-3': 'player',
      '-4': 'system',  '-5': 'library',
    }
  },
};

function makeSlotEntry(name) {
  return { name, type: { events: [], methods: [] } };
}

function parseHandlers(lua) {
  const handlers = [];
  // Match --[[\n@\n...meta...\n]]\n...code... blocks
  const re = /--\[\[@\n([\s\S]*?)\]\]\n([\s\S]*?)(?=--\[\[@|$)/g;
  let m, key = 0;
  while ((m = re.exec(lua)) !== null) {
    const metaStr = m[1];
    const code    = m[2].trimEnd();
    const meta    = {};
    for (const line of metaStr.split('\n')) {
      const eq = line.indexOf('=');
      if (eq !== -1) {
        meta[line.slice(0, eq).trim()] = line.slice(eq + 1).trim();
      }
    }
    handlers.push({ meta, code: code.trim(), key: String(key++) });
  }
  return handlers;
}

function buildFilter(meta) {
  const slotKey  = meta.slot  || '-1';
  const eventStr = meta.event || 'onStart()';
  const argsStr  = (meta.args || '').trim();

  const args = [];
  if (argsStr) {
    for (let arg of argsStr.split(',')) {
      arg = arg.trim().replace(/^["']|["']$/g, '');
      if (arg === '*') args.push({ variable: '*' });
      else if (arg)    args.push({ value: arg });
    }
  }
  return { args, signature: eventStr, slotKey };
}

function buildHandler(handler, slotNames) {
  const { meta, code, key } = handler;
  const slotKey  = meta.slot  || '-1';
  const event    = meta.event || 'onStart()';
  const slotName = slotNames[slotKey] || 'unit';
  const fullCode = `--${slotName}.${event}\n${code}\n--`;
  return { code: fullCode, filter: buildFilter(meta), key };
}

function build(sourceName, config) {
  const srcPath = path.join('src', sourceName + '.lua');
  const outPath = path.join('dist', config.output);
  console.log(`Building ${srcPath}  →  ${outPath}`);

  const lua = fs.readFileSync(srcPath, 'utf8').replace(/\r\n/g, '\n');

  fs.mkdirSync('dist', { recursive: true });

  if (config.rawLua) {
    fs.writeFileSync(outPath, lua, 'utf8');
    console.log(`  OK  (raw Lua screen script)`);
    return;
  }

  const rawHandlers = parseHandlers(lua);
  const duHandlers  = rawHandlers.map(h => buildHandler(h, config.slots));

  const slots = {};
  for (const [k, name] of Object.entries(config.slots)) {
    slots[k] = makeSlotEntry(name);
  }

  const duJson = { slots, handlers: duHandlers, methods: [], events: [] };

  fs.writeFileSync(outPath, JSON.stringify(duJson), 'utf8');
  console.log(`  OK  (${duHandlers.length} handlers, ${Object.keys(slots).length} slots)`);
}

const TOOLS = {
  databank_inspector: {
    src: 'tools/databank_inspector.lua',
    output: 'tools/Databank_Inspector.txt',
    slots: {
       '0': 'screen',   '1': 'databank',
      '-1': 'unit',    '-2': 'construct', '-3': 'player',
      '-4': 'system',  '-5': 'library',
    }
  },
  wipe_databanks: {
    src: 'tools/wipe_databanks.lua',
    output: 'tools/Wipe_Databanks.txt',
    slots: {
      '1': 'databank1', '2': 'databank2',
      '-1': 'unit', '-2': 'construct', '-3': 'player',
      '-4': 'system', '-5': 'library',
    }
  },
};

console.log('=== DU Navigator Build ===');
for (const [name, cfg] of Object.entries(CONFIGS)) {
  build(name, cfg);
}
console.log('\n=== Tools ===');
for (const [, cfg] of Object.entries(TOOLS)) {
  const srcPath = cfg.src;
  const outPath = path.join('dist', cfg.output);
  console.log(`Building ${srcPath}  →  ${outPath}`);
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  const lua = fs.readFileSync(srcPath, 'utf8').replace(/\r\n/g, '\n');
  const rawHandlers = parseHandlers(lua);
  const duHandlers  = rawHandlers.map(h => buildHandler(h, cfg.slots));
  const slots = {};
  for (const [k, n] of Object.entries(cfg.slots)) slots[k] = makeSlotEntry(n);
  const duJson = { slots, handlers: duHandlers, methods: [], events: [] };
  fs.writeFileSync(outPath, JSON.stringify(duJson), 'utf8');
  console.log(`  OK  (${duHandlers.length} handlers)`);
}
console.log('\nDone. Import .txt files from dist/ into DU programming boards.');

// ── Package ───────────────────────────────────────────────────────────────────
console.log('\n=== Package ===');

const { execSync } = require('child_process');
const os = require('os');

const VERSION    = 'v2.0';
const STAGE_DIR  = path.join(os.tmpdir(), 'nav_release');
const ZIP_OUT    = path.resolve(`dist/Navigator_${VERSION}.zip`);

// Clean and rebuild staging area
fs.rmSync(STAGE_DIR, { recursive: true, force: true });
fs.mkdirSync(STAGE_DIR, { recursive: true });

// PB files
for (const cfg of Object.values(CONFIGS)) {
  const src = path.join('dist', cfg.output);
  fs.copyFileSync(src, path.join(STAGE_DIR, cfg.output));
}

// Tools
const toolsOut = path.join(STAGE_DIR, 'tools');
fs.mkdirSync(toolsOut, { recursive: true });
fs.copyFileSync('dist/tools/Databank_Inspector.txt', path.join(toolsOut, 'Databank_Inspector.txt'));
fs.copyFileSync('dist/tools/Wipe_Databanks.txt',     path.join(toolsOut, 'Wipe_Databanks.txt'));

// Arch HUD userclass — placed at correct game path, original name preserved
const archOut = path.join(STAGE_DIR, 'autoconf', 'custom', 'archhud');
fs.mkdirSync(archOut, { recursive: true });
fs.copyFileSync('tools/archhud_userclass.lua', path.join(archOut, 'archhud_userclass.lua'));

// Docs
fs.copyFileSync('INSTRUCTIONS.md', path.join(STAGE_DIR, 'INSTRUCTIONS.md'));
fs.copyFileSync('THEME_GUIDE.md',  path.join(STAGE_DIR, 'THEME_GUIDE.md'));

// Zip
if (fs.existsSync(ZIP_OUT)) fs.rmSync(ZIP_OUT);
const stageGlob = path.join(STAGE_DIR, '*');
execSync(`powershell -Command "Compress-Archive -Path '${stageGlob}' -DestinationPath '${ZIP_OUT}'"`, { stdio: 'inherit' });

fs.rmSync(STAGE_DIR, { recursive: true, force: true });
console.log(`  Created: ${ZIP_OUT}`);
