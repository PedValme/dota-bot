// Fixed analysis of the final series n3-v3 (MEDICIONES.md, «n3-v3», written before it ran): cerebro_v3 against base.
// Outside tools/bench/ on purpose: that tree is part of every match's code check, and this file may be read or fixed
// while the series runs.
//   node tools/analisis/n3-v3.mjs [mirada]      mirada: 1 (8 blocks = 16 per arm), 2 (14), 3 (20); default: all blocks
// Rows: bench/series.csv with etiqueta n3-v3-*; per (etiqueta, partida) the last row counts (--repetir-invalidas).
// A block counts when its 4 matches (2 per arm, one per side) are valid. Primary: wins (a capped match is not a win),
// Cochran-Mantel-Haenszel over blocks, one-sided; Lan-DeMets O'Brien-Fleming bounds (z 2.81 / 2.04 / 1.70).
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../..", import.meta.url));
const BOUNDS = { 1: { blocks: 8, z: 2.812 }, 2: { blocks: 14, z: 2.044 }, 3: { blocks: 20, z: 1.702 } };
const V3 = "cerebro_v3";
const BASE = "base";

const [header, ...lines] = readFileSync(join(root, "bench", "series.csv"), "utf8").trim().split(/\r?\n/);
const cols = header.split(",");
const all = lines.map((l) => Object.fromEntries(l.split(",").map((v, i) => [cols[i], v])))
  .filter((r) => /^n3-v3-/.test(r.etiqueta));

// Invalid matches per arm, every attempt included (MEDICIONES: the stop rule).
const invalid = { [V3]: 0, [BASE]: 0 };
const sinFinal = { [V3]: 0, [BASE]: 0 };
for (const r of all) if (r.valida !== "si") { invalid[r.variante]++; if (r.motivo === "sin final") sinFinal[r.variante]++; }

// Same code trees and Dota version in every row of the series.
const tree = (c) => (c || "").split("@")[1] ?? "";
const trees = new Set(all.map((r) => tree(r.codigo)));
const versions = new Set(all.map((r) => r.dota_version));

const last = new Map();
for (const r of all) last.set(`${r.etiqueta}#${r.partida}`, r);
const byBlock = new Map();
for (const r of last.values()) {
  const k = `${r.etiqueta}#${r.bloque}`;
  if (!byBlock.has(k)) byBlock.set(k, []);
  byBlock.get(k).push(r);
}
const order = [...byBlock.keys()].sort((a, b) => {
  const [ea, ba] = a.split("#"), [eb, bb] = b.split("#");
  return ea === eb ? +ba - +bb : ea < eb ? -1 : 1;
});
let blocks = order.map((k) => byBlock.get(k)).filter((b) => b.length === 4 && b.every((r) => r.valida === "si"));
const look = Number(process.argv[2]);
if (BOUNDS[look]) blocks = blocks.slice(0, BOUNDS[look].blocks);

let sumDiff = 0, sumVar = 0, winsV3 = 0, winsBase = 0;
for (const b of blocks) {
  const won = (r) => r.ganador !== "" && r.ganador === r.dotabot;
  const a = b.filter((r) => r.variante === V3 && won(r)).length;
  const m = b.filter(won).length;
  winsV3 += a;
  winsBase += m - a;
  sumDiff += a - m / 2;
  sumVar += (m * (4 - m)) / 12;
}
const z = sumVar > 0 ? sumDiff / Math.sqrt(sumVar) : 0;

// Secondary (mechanism, fixed before): dota-bot's net worth per minute minus Valve's between minutes 18 and 26, from
// the per-minute timelines; paired by block (v3's mean minus base's), sign test.
function nwRate(r) {
  const file = join(root, "bench", "lineas", `${r.etiqueta}-${String(r.fecha).replace(/[-:T]/g, "")}-${r.partida}.csv`);
  if (!existsSync(file)) return null;
  const [h, ...rows] = readFileSync(file, "utf8").trim().split(/\r?\n/);
  const c = h.split(",");
  const at = (min) => rows.map((l) => Object.fromEntries(l.split(",").map((v, i) => [c[i], v]))).find((x) => +x.min === min && x.event === "minute");
  const a = at(18), b = at(26);
  if (!a || !b) return null;
  const own = r.dotabot === "radiant" ? "rnw" : "dnw", their = r.dotabot === "radiant" ? "dnw" : "rnw";
  return ((+b[own] - +a[own]) - (+b[their] - +a[their])) / 8;
}
let up = 0, down = 0;
for (const b of blocks) {
  const mean = (v) => { const xs = b.filter((r) => r.variante === v).map(nwRate).filter((x) => x !== null); return xs.length ? xs.reduce((s, x) => s + x, 0) / xs.length : null; };
  const d = mean(V3) !== null && mean(BASE) !== null ? mean(V3) - mean(BASE) : null;
  if (d > 0) up++; else if (d < 0) down++;
}

console.log(`n3-v3: ${all.length} filas, ${blocks.length} bloques completos y válidos${BOUNDS[look] ? ` (mirada ${look}: ${BOUNDS[look].blocks})` : ""}`);
console.log(`  victorias: ${V3} ${winsV3}/${blocks.length * 2}, ${BASE} ${winsBase}/${blocks.length * 2}; CMH z = ${z.toFixed(3)}`);
if (BOUNDS[look]) {
  const verdict = z >= BOUNDS[look].z ? "PARA: v3 gana más (frontera de eficacia)"
    : look === 2 && z <= 0 ? "PARA por inutilidad (no vinculante): v3 no gana más que base"
    : look === 3 ? "final: sin diferencia demostrada" : "sigue";
  console.log(`  frontera z ≥ ${BOUNDS[look].z}: ${verdict}`);
}
console.log(`  inválidas por brazo (todas las filas): ${V3} ${invalid[V3]} (sin final ${sinFinal[V3]}), ${BASE} ${invalid[BASE]} (sin final ${sinFinal[BASE]})`);
const stop = sinFinal[V3] > sinFinal[BASE] || Math.abs(invalid[V3] - invalid[BASE]) >= 3;
if (stop) console.log("  ALTO: asimetría de inválidas entre brazos (regla de MEDICIONES): parar e investigar");
if (trees.size > 1 || versions.size > 1) console.log(`  ALTO: código (${[...trees].join(" | ")}) o Dota (${[...versions].join(" | ")}) distintos en la serie`);
console.log(`  secundaria, patrimonio/min propio menos el de Valve, min 18-26, por bloque: v3 mejor en ${up}, peor en ${down}`);
