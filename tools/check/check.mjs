// dota-bot check: every Lua file under bots/ and game/ parses, and no bot code (Lua or its TS sources) reaches the
// network. Run from the repository root: npm --prefix tools/check ci && node tools/check/check.mjs
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import luaparse from "luaparse";

const root = fileURLToPath(new URL("../..", import.meta.url));

// The upstream HTTP helper stays on disk but nothing may load it (2026-10-28 review). Any mention of Valve's HTTP
// functions or of the helper, call or not, comment or not, is new network code and must be reviewed first.
const httpHelper = new Set([
  "bots/ts_libs/utils/http_utils/http_req.lua",
  "typescript/bots/ts_libs/utils/http_utils/http_req.ts",
]);
const network = /HTTPRequest|http_req|RawGetRequest|RawPostRequest|HttpPost/;

function filesUnder(dir, extensions) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) return filesUnder(path, extensions);
    return extensions.some((e) => name.endsWith(e)) ? [path] : [];
  });
}

const entryFile = /^bots\/(bot_generic|hero_selection|team_desires|ability_item_usage_\w+|item_purchase_\w+|mode_\w+_generic)\.lua$/;
const guard = "if dofile(GetScriptDirectory()..'/FunLib/bench_side') then return end";

const errors = [];
const lua =["bots", "game"].flatMap((d) => filesUnder(join(root, d), [".lua"]));
// Type declarations (.d.ts) only describe Valve's API; they never run.
const ts = filesUnder(join(root, "typescript"), [".ts"]).filter((f) => !f.endsWith(".d.ts"));
for (const file of [...lua, ...ts]) {
  const rel = relative(root, file).replaceAll("\\", "/");
  const source = readFileSync(file, "utf8").replace(/^﻿/, "");
  if (rel.endsWith(".lua")) {
    try {
      // Lua allows "break;" (laststat [';']) but luaparse 0.3.1 rejects it.
      luaparse.parse(source.replace(/\bbreak\s*;/g, "break"), { luaVersion: "LuaJIT", comments: false });
    } catch (e) {
      errors.push(`${rel}: syntax: ${e.message}`);
    }
  }
  // Every file Valve loads as a bot entry point must start with the benchmark guard (bots/FunLib/bench_side.lua),
  // or that file would keep running our code for the team that should play with Valve's bots.
  if (entryFile.test(rel) && !source.startsWith(guard)) errors.push(`${rel}:1: missing the bench_side guard`);
  if (httpHelper.has(rel)) continue;
  source.split(/\r?\n/).forEach((line, i) => {
    if (network.test(line)) errors.push(`${rel}:${i + 1}: network code`);
  });
}

if (errors.length) {
  console.error(errors.join("\n"));
  console.error(`check: ${errors.length} problem(s) in ${lua.length} Lua and ${ts.length} TS files`);
  process.exit(1);
}
console.log(`check: ${lua.length} Lua files parse; no network code in ${lua.length} Lua and ${ts.length} TS files`);
