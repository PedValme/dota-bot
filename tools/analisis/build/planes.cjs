// Runs build.lua's pure B.Choose, unchanged, over every enemy lineup the Sniper has met in the bench and in Pedro's lobbies.
// node planes.cjs <repo>
const fs = require("fs");
const path = require("path");
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require("fengari");
const repo = process.argv[2].replace(/\\/g, "/");
const csv = fs.readFileSync(path.join(repo, "bench", "series.csv"), "utf8").split(/\r?\n/);
const head = csv[0].split(",");
const hi = head.indexOf("heroes");
const lineups = new Map();
for (const l of csv.slice(1)) {
  const c = l.split(",");
  const h = c[hi];
  if (!h || !h.includes("sniper") || !h.includes(" / ")) continue;
  const [a, b] = h.split(" / ").map((g) => g.trim().split(/\s+/));
  const enemies = a.includes("sniper") ? b : a;
  lineups.set(enemies.slice().sort().join(" "), enemies);
}
// Pedro's lobbies (bench/observaciones/lobby-*.log): the Sniper's enemies there.
lineups.set("lobby-11-05", ["alchemist", "ursa", "centaur", "warlock", "crystal_maiden"]);
lineups.set("lobby-11-06", ["alchemist", "terrorblade", "nevermore", "jakiro", "bloodseeker"]);
lineups.set("lobby-11-07", ["alchemist", "riki", "lion", "viper", "witch_doctor"]);
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const list = [...lineups.entries()].map(([k, v]) => `{ key = ${JSON.stringify(k)}, ${v.map((h) => JSON.stringify(h)).join(", ")} }`).join(",\n");
const code = `
package.path = '${repo}/?.lua;' .. package.path
function GetScriptDirectory() return 'bots' end
local A = require('bots/FunLib/propio/amenazas')
local B = require('bots/FunLib/propio/build')
local P = require('bots/FunLib/propio/perfiles/sniper')
local lineups = { ${list} }
local out = {}
for _, l in ipairs(lineups) do
  local t = { evasion = 0, control = 0, magia = 0, salta = 0, invis = 0, ilusiones = 0, curacion = 0 }
  local unknown = {}
  for _, h in ipairs(l) do
    local tags = A.HEROES[h]
    if tags == nil then table.insert(unknown, h) else for tag, on in pairs(tags) do if on then t[tag] = t[tag] + 1 end end end
  end
  local items, reasons = B.Choose(P, t)
  table.insert(out, string.format('%s | %s | e%d c%d m%d s%d%s\\n   %s\\n   %s', l.key, table.concat(l, ' '), t.evasion, t.control, t.magia, t.salta,
    #unknown > 0 and (' | SIN ETIQUETAS: ' .. table.concat(unknown, ' ')) or '', table.concat(items, ' > '), table.concat(reasons, ' ; ')))
end
return table.concat(out, '\\n')
`;
if (lauxlib.luaL_dostring(L, to_luastring(code)) !== lua.LUA_OK) {
  console.error(to_jsstring(lua.lua_tostring(L, -1)));
  process.exit(1);
}
console.log(to_jsstring(lua.lua_tostring(L, -1)));
console.log(`\n${lineups.size} alineaciones`);
