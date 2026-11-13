// Fixed analysis of the own team against OHA's (trabajo/plan-mejora-equipo.md, signed by Pedro on 2026-11-13). A measurement control:
// a change here is reviewed before it is used (.fabrica.json, rojas). Reviewed adversarially on 2026-11-13 before its first use.
//
//   node tools/bench/equipo.mjs <test-tag-regex> [<reference-tag-regex>] [--t 600]
//
// Reads bench/series.csv (valid rows only) and each match's observer log in bench/observaciones/. For each match, from dota-bot's side
// (the `dotabot` column is variant a's side; the `heroes` column is "radiant / dire", positions in group order): per hero at minute t
// (default 10) its level, net worth, last hits, denies, kills and deaths; per lane the difference against the enemy heroes it faces
// (safe: our 1+5 against their 3+4; mid: 2 against 2; hard: our 3+4 against their 1+5), and the kills and deaths of that lane's heroes
// anywhere on the map up to t (not only in the lane: OHA rotates before minute 10); the team's kill and net worth difference.
//
// Checks printed, never silent: each match left out and why; the lane each hero stood in between t=60 and 180 (from x,y) against the
// pairing assumed; the code, mode, cut and difficulty of the rows read (a warning when an arm mixes them); repeated (tag, match) rows;
// the real speed of each match (game seconds per real second between t=60 and t=720), per arm.
//
// With one regex: mean, SD and 95 % CI of each metric. With two (test and reference): test minus reference, paired by (lineup, side)
// stratum: each stratum's difference of means, then their mean with a t interval over the strata, and the smallest difference the
// design detects (80 % power, alpha 0.05 two-sided: (t.975 + t.80) x SE). Fewer than 3 strata: no interval ("-").
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../..", import.meta.url));
const args = process.argv.slice(2);
const tIdx = args.indexOf("--t");
const T = tIdx >= 0 ? Number(args[tIdx + 1]) : 600;
const regexes = args.filter((a, i) => tIdx < 0 || (i !== tIdx && i !== tIdx + 1)).map((r) => new RegExp(`^(${r})$`));
if (!regexes.length || regexes.length > 2 || !Number.isFinite(T)) {
  throw new Error("Uso: node tools/bench/equipo.mjs <regex-prueba> [<regex-referencia>] [--t 600]");
}

// t quantiles by degrees of freedom: two-sided 95 % (0.975) and one-sided 80 % (0.80); beyond 30, the normal.
const Q975 = [NaN, 12.71, 4.30, 3.18, 2.78, 2.57, 2.45, 2.36, 2.31, 2.26, 2.23, 2.20, 2.18, 2.16, 2.14, 2.13, 2.12, 2.11, 2.10, 2.09,
  2.09, 2.08, 2.07, 2.07, 2.06, 2.06, 2.06, 2.05, 2.05, 2.05, 2.04];
const Q80 = [NaN, 1.376, 1.061, 0.978, 0.941, 0.920, 0.906, 0.896, 0.889, 0.883, 0.879, 0.876, 0.873, 0.870, 0.868, 0.866, 0.865,
  0.863, 0.862, 0.861, 0.860, 0.859, 0.858, 0.858, 0.857, 0.856, 0.856, 0.855, 0.855, 0.854, 0.854];
const q = (table, inf, df) => (df < 1 ? NaN : df <= 30 ? table[df] : inf);

const [header, ...rows] = readFileSync(join(root, "bench", "series.csv"), "utf8").trim().split(/\r?\n/);
const cols = header.split(",");
const series = rows.map((r) => Object.fromEntries(r.split(",").map((v, i) => [cols[i], v]))).filter((r) => r.valida === "si");
const obsFiles = new Set(readdirSync(join(root, "bench", "observaciones")));

const HERO = /^(\d+)\/(\d+) (\d+):(\d+):(\d+) .*obs t=(\d+) hero pid=\d+ team=(\d) (\S+) lvl=(\d+) gold=-?\d+ nw=(\d+) lh=(\d+) dn=(\d+) k=(\d+) d=(\d+) a=\d+ alive=\d x=(-?\d+) y=(-?\d+)/;
const LANES = { segura: [[0, 4], [2, 3]], mid: [[1], [1]], dificil: [[2, 3], [0, 4]] }; // [our positions, their positions], 0-based
// The lane a point lies in: top along the left and top edges (y well above x), bottom along the bottom and right ones, else mid.
const laneOf = (x, y) => (y - x > 3000 ? "top" : x - y > 3000 ? "bot" : "mid");
const notes = [];

// One match's metrics from dota-bot's side, or the reason it is left out.
function matchMetrics(m) {
  const file = `${m.etiqueta}-${String(m.fecha).replace(/[-:T]/g, "")}-${m.partida}.log`;
  if (!obsFiles.has(file)) return { out: "sin registro de observador" };
  const ourTeam = m.dotabot === "radiant" ? "2" : "3";
  const [radiant, dire] = m.heroes.split(" / ").map((g) => g.trim().split(/\s+/));
  const ours = ourTeam === "2" ? radiant : dire;
  const theirs = ourTeam === "2" ? dire : radiant;
  const at = {};
  const early = {}; // hero -> lane votes between t=60 and 180
  let wall60 = null, wall720 = null;
  for (const line of readFileSync(join(root, "bench", "observaciones", file), "latin1").split(/\r?\n/)) {
    const h = HERO.exec(line);
    if (!h) continue;
    const t = Number(h[6]);
    const wall = Number(h[3]) * 3600 + Number(h[4]) * 60 + Number(h[5]);
    if (t === 60 && wall60 === null) wall60 = wall;
    if (t === 720 && wall720 === null) wall720 = wall;
    const name = h[8];
    if (t === T) at[name] = { team: h[7], lvl: +h[9], nw: +h[10], lh: +h[11], dn: +h[12], k: +h[13], d: +h[14] };
    if (t >= 60 && t <= 180) (early[name] ??= []).push(laneOf(+h[15], +h[16]));
  }
  const missing = [...ours, ...theirs].filter((h) => !at[h]);
  if (missing.length) return { out: `sin foto en t=${T} de ${missing.join(", ")}` };
  const wrongTeam = ours.filter((h) => at[h].team !== ourTeam);
  if (wrongTeam.length) return { out: `héroes propios en el otro equipo: ${wrongTeam.join(", ")}` };
  // Lane check: the heroes paired in a lane must have stood in the same one.
  const lane = (h) => {
    const votes = early[h] ?? [];
    const count = (l) => votes.filter((v) => v === l).length;
    return ["top", "mid", "bot"].sort((a, b) => count(b) - count(a))[0];
  };
  for (const [name, [a, b]] of Object.entries(LANES)) {
    const where = new Set([...a.map((i) => lane(ours[i])), ...b.map((i) => lane(theirs[i]))]);
    if (where.size > 1) notes.push(`${file}: línea ${name} no emparejada como se supone (${[...a.map((i) => ours[i]), ...b.map((i) => theirs[i])].map((h) => `${h}=${lane(h)}`).join(" ")})`);
  }
  const out = {};
  ours.forEach((h, pos) => {
    for (const k of ["lvl", "nw", "lh", "dn", "k", "d"]) out[`${pos + 1}.${h}.${k}`] = at[h][k];
  });
  const sum = (heroes, k) => heroes.reduce((s, h) => s + at[h][k], 0);
  for (const [name, [a, b]] of Object.entries(LANES)) {
    const us = a.map((i) => ours[i]);
    const them = b.map((i) => theirs[i]);
    out[`linea.${name}.nw`] = sum(us, "nw") - sum(them, "nw");
    out[`linea.${name}.nivel`] = (sum(us, "lvl") - sum(them, "lvl")) / us.length;
    out[`linea.${name}.lh`] = sum(us, "lh") - sum(them, "lh");
    out[`linea.${name}.muertes_heroes`] = sum(us, "d");
    out[`linea.${name}.kills_heroes`] = sum(us, "k");
  }
  out["equipo.kills_dif"] = sum(ours, "k") - sum(theirs, "k");
  out["equipo.nw_dif"] = sum(ours, "nw") - sum(theirs, "nw");
  const speed = wall60 !== null && wall720 !== null && wall720 > wall60 ? 660 / (wall720 - wall60) : NaN;
  return { file, stratum: `${m.heroes} | ${m.dotabot}`, metrics: out, speed, row: m };
}

const mean = (xs) => xs.reduce((s, x) => s + x, 0) / xs.length;
const sd = (xs) => (xs.length < 2 ? NaN : Math.sqrt(xs.reduce((s, x) => s + (x - mean(xs)) ** 2, 0) / (xs.length - 1)));
const fmt = (x) => (Number.isFinite(x) ? (Math.abs(x) >= 100 ? x.toFixed(0) : x.toFixed(2)) : "-");

const arms = regexes.map((re, i) => {
  const picked = series.filter((r) => re.test(r.etiqueta));
  const seen = new Set();
  for (const r of picked) {
    const key = `${r.etiqueta}#${r.partida}#${r.fecha}`;
    if (seen.has(key)) notes.push(`brazo ${i + 1}: fila repetida ${key}`);
    seen.add(key);
  }
  for (const field of ["codigo", "modo", "corte", "dificultad"]) {
    const values = [...new Set(picked.map((r) => r[field]))];
    if (values.length > 1) notes.push(`brazo ${i + 1}: mezcla ${field}: ${values.join(", ")}`);
  }
  const results = picked.map(matchMetrics);
  results.filter((r) => r.out).forEach((r, j) => notes.push(`brazo ${i + 1}: fuera ${picked[j]?.etiqueta ?? ""}: ${r.out}`));
  return results.filter((r) => !r.out);
});

console.log(`Minuto ${T / 60}. Partidas válidas con registro: ${arms.map((a) => a.length).join(" y ")}.`);
arms.forEach((a, i) => {
  const sp = a.map((m) => m.speed).filter(Number.isFinite);
  console.log(`Velocidad real, brazo ${i + 1}: media ×${fmt(mean(sp))} (${sp.map((x) => x.toFixed(2)).join(" ")})`);
});
for (const n of notes) console.log(`Aviso: ${n}`);
const keys = [...new Set(arms.flatMap((a) => a.flatMap((m) => Object.keys(m.metrics))))];
if (arms.length === 1) {
  console.log("métrica | media | DE | IC 95 %");
  for (const k of keys) {
    const xs = arms[0].map((m) => m.metrics[k]).filter((x) => x !== undefined);
    const half = q(Q975, 1.96, xs.length - 1) * sd(xs) / Math.sqrt(xs.length);
    console.log(`${k} | ${fmt(mean(xs))} | ${fmt(sd(xs))} | ${fmt(mean(xs) - half)} a ${fmt(mean(xs) + half)}`);
  }
} else {
  const strata = [...new Set(arms[0].map((m) => m.stratum))].filter((s) => arms[1].some((m) => m.stratum === s));
  console.log(`Estratos (alineación y lado) con los dos brazos: ${strata.length}${strata.length < 3 ? " (menos de 3: sin intervalo)" : ""}. Prueba menos referencia:`);
  console.log("métrica | prueba | referencia | diferencia | IC 95 % | mínima detectable");
  for (const k of keys) {
    const diffs = strata.map((st) => {
      const a = arms[0].filter((m) => m.stratum === st).map((m) => m.metrics[k]);
      const b = arms[1].filter((m) => m.stratum === st).map((m) => m.metrics[k]);
      return a.length && b.length && a.every((x) => x !== undefined) && b.every((x) => x !== undefined) ? mean(a) - mean(b) : undefined;
    }).filter((x) => x !== undefined);
    const df = diffs.length - 1;
    const se = diffs.length >= 3 ? sd(diffs) / Math.sqrt(diffs.length) : NaN;
    const half = q(Q975, 1.96, df) * se;
    const all = (arm) => mean(arm.map((m) => m.metrics[k]).filter((x) => x !== undefined));
    console.log(`${k} | ${fmt(all(arms[0]))} | ${fmt(all(arms[1]))} | ${fmt(mean(diffs))} | ${fmt(mean(diffs) - half)} a ${fmt(mean(diffs) + half)} | ${fmt((q(Q975, 1.96, df) + q(Q80, 0.842, df)) * se)}`);
  }
}
