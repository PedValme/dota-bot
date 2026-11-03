// dota-bot: turns the engine's own dump of the Bot API (FunLib/api_dump.lua, benchmark variant volcado_api) into the
// reference docs/api/volcado.md, so the own bot works from what Dota really offers scripts (DECISIONES 2026-11-03).
// Run after a match with --variantes volcado_api, before Dota is launched again (-condebug rewrites console.log):
//   node tools/datos/api_volcado.mjs ["<dota 2 beta>/game/dota/console.log"]
// It also saves the raw dump lines to docs/api/volcado-crudo.txt. A method or global that a script of this repo
// defines (OHA's FunLib/aba_global_overrides.lua replaces several of Valve's calls) is marked "OHA", because the team's
// Lua VM is shared with OHA's scripts and the sandbox has no debug library to tell engine and script functions apart.
import { readFileSync, writeFileSync, mkdirSync, readdirSync, statSync } from "node:fs";
import { join, dirname, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const logPath = process.argv[2] ?? "C:/Program Files (x86)/Steam/steamapps/common/dota 2 beta/game/dota/console.log";
const outDir = join(root, "docs", "api");

const lines = readFileSync(logPath, "latin1").split(/\r?\n/)
  .map((l) => { const i = l.indexOf("[bench] apidump "); return i < 0 ? null : l.slice(i + "[bench] apidump ".length); })
  .filter((l) => l !== null);
if (!lines.some((l) => l.startsWith("fin globales"))) throw new Error(`No hay volcado completo en ${logPath}`);

// Where this repo's Lua defines each global function or class method (file:line), to mark what is not the engine's.
function luaFiles(dir) {
  return readdirSync(dir).flatMap((n) => {
    const p = join(dir, n);
    return statSync(p).isDirectory() ? luaFiles(p) : p.endsWith(".lua") ? [p] : [];
  });
}
const defined = new Map();
for (const f of luaFiles(join(root, "bots"))) {
  readFileSync(f, "utf8").split(/\r?\n/).forEach((src, i) => {
    const m = src.match(/^\s*function\s+([A-Za-z_][\w]*)\s*[:.]\s*([A-Za-z_]\w*)\s*\(/) // function Class:Method(
      ?? src.match(/^\s*([A-Za-z_]\w*)\.([A-Za-z_]\w*)\s*=\s*function/)                // Class.Method = function
      ?? src.match(/^function\s+([A-Za-z_]\w*)\s*\(/)                                   // global function Name(
      ?? src.match(/^([A-Za-z_]\w*)\s*=\s*function/)                                    // Name = function
      ?? src.match(/^if\s+([A-Za-z_]\w*)\s*==\s*nil\s+then\s+\1\s*=/);                // if Name == nil then Name =
    if (!m) return;
    const key = m[2] ? `${m[1]}.${m[2]}` : m[1];
    // "if Name == nil then Name = ..." only fills a gap: the engine's own wins when it has one (GetScriptDirectory).
    const fallback = /^if\s/.test(src) ? " (solo si el motor no la trae)" : "";
    if (!defined.has(key)) defined.set(key, `${relative(root, f).replaceAll("\\", "/")}:${i + 1}${fallback}`);
  });
}
const mark = (key) => (defined.has(key) ? ` — **OHA** (\`${defined.get(key)}\`)` : "");

const globals = [], tables = new Map(), methods = new Map(), units = [];
for (const l of lines) {
  let m;
  if ((m = l.match(/^g (\S+) (\S+)(?: (.*))?$/))) globals.push({ name: m[1], type: m[2], value: m[3] ?? "" });
  else if ((m = l.match(/^t ([^.]+)\.(\S+) (\S+)(?: (.*))?$/))) {
    if (!tables.has(m[1])) tables.set(m[1], []);
    tables.get(m[1]).push({ name: m[2], type: m[3], value: m[4] ?? "" });
  } else if ((m = l.match(/^h (\S+) 0 (\S+) (\S+)/))) {
    if (!methods.has(m[1])) methods.set(m[1], []);
    methods.get(m[1]).push({ name: m[2], type: m[3] });
  } else if (l.startsWith("u ")) units.push(l.slice(2));
}
const classOf = {};
for (const l of lines) { const m = l.match(/^h (\S+) nivel=0 clase=(\S+)/); if (m) classOf[m[1]] = m[2]; }

const out = [];
out.push("# La API de bots que ofrece el motor (volcado de primera mano)", "");
out.push(`Generado por \`tools/datos/api_volcado.mjs\` desde el volcado de \`bots/FunLib/api_dump.lua\` (variante del banco`,
  "`volcado_api`). Es lo que el propio Dota pone a disposición de los scripts de bots, leído desde dentro: manda sobre",
  "la wiki de Valve (2016-2017, `docs/investigacion/2026-11-03-api-valve.md`) y sobre `docs/BOT_API_REFERENCE.md`.",
  "Lo marcado **OHA** lo define un script de este repositorio (casi siempre `FunLib/aba_global_overrides.lua`, que",
  "reemplaza llamadas de Valve): el bot propio no debe cargar esos reemplazos. Un método que existe no garantiza que",
  "responda bien: eso se comprueba en partida.", "");
const fns = globals.filter((g) => g.type === "function");
out.push(`## Funciones globales (${fns.length})`, "");
for (const g of fns) out.push(`- \`${g.name}\`${mark(g.name)}`);
out.push("");
for (const [kind, list] of methods) {
  const cls = classOf[kind] ?? "?";
  if (out.some((l) => l.startsWith(`## Métodos de \`${cls}\``))) { out.push(`(\`${kind}\` usa la misma clase \`${cls}\`.)`, ""); continue; }
  const fn = list.filter((x) => x.type === "function");
  out.push(`## Métodos de \`${cls}\` (${fn.length}; visto en: ${kind})`, "");
  for (const x of fn) out.push(`- \`${x.name}\`${mark(`${cls}.${x.name}`)}`);
  out.push("");
}
out.push("## Tablas globales", "");
for (const [t, list] of tables) out.push(`- \`${t}\`: ${list.map((x) => `\`${x.name}\``).join(", ")}`);
out.push("");
const consts = globals.filter((g) => g.type === "number");
out.push(`## Constantes (${consts.length})`, "", "| Nombre | Valor |", "|---|---|");
for (const c of consts) out.push(`| \`${c.name}\` | ${c.value} |`);
out.push("", `## Unidades vistas (${units.length}; tiempo de juego en segundos)`, "",
  "Valores leídos con los métodos de la unidad; `MaxHealth` y `MagicResist` pasan por reemplazos de OHA (arriba).", "");
for (const u of units) out.push(`- ${u}`);
out.push("");

mkdirSync(outDir, { recursive: true });
writeFileSync(join(outDir, "volcado.md"), out.join("\n"));
writeFileSync(join(outDir, "volcado-crudo.txt"), lines.join("\n") + "\n");
console.log(`docs/api/volcado.md: ${fns.length} funciones globales, ${[...methods.values()].reduce((a, l) => a + l.length, 0)} métodos, ${consts.length} constantes, ${units.length} unidades.`);
