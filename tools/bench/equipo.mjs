// Fixed analysis of the own team against OHA's (trabajo/plan-mejora-equipo.md, signed by Pedro on 2026-11-13). A measurement control:
// a change here is reviewed before it is used (.fabrica.json, rojas).
//
//   node tools/bench/equipo.mjs <test-tag-regex> [<reference-tag-regex>] [--t 600]
//
// Reads bench/series.csv (valid rows only) and each match's observer log in bench/observaciones/. For each match, from dota-bot's side
// (the `dotabot` column): per hero at minute t (default 10) its level, net worth, last hits, denies, kills and deaths; per lane the
// difference against the enemy heroes it faces (safe: our 1+5 against their 3+4; mid: 2 against 2; hard: our 3+4 against their 1+5);
// and the team's kill and net worth difference. Positions are the order of each side's group in the `heroes` column.
//
// With one regex: mean, standard deviation and 95 % CI of each metric. With two (test and reference): the test minus the reference,
// paired by (lineup, side) stratum: each stratum's difference of means, then their mean with a t interval over the strata, and the
// smallest difference the design can detect (80 % power, alpha 0.05: 2.8 x SE). "-" when a stratum lacks one arm.
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../..", import.meta.url));
const args = process.argv.slice(2);
const tIdx = args.indexOf("--t");
const T = tIdx >= 0 ? Number(args[tIdx + 1]) : 600;
const regexes = args.filter((a, i) => tIdx < 0 || (i !== tIdx && i !== tIdx + 1)).map((r) => new RegExp(`^(${r})$`));
if (!regexes.length || !Number.isFinite(T)) throw new Error("Uso: node tools/bench/equipo.mjs <regex-prueba> [<regex-referencia>] [--t 600]");

// t quantile for a 95 % two-sided interval, by degrees of freedom (beyond 30, the normal).
const T95 = [NaN, 12.71, 4.30, 3.18, 2.78, 2.57, 2.45, 2.36, 2.31, 2.26, 2.23, 2.20, 2.18, 2.16, 2.14, 2.13, 2.12, 2.11, 2.10, 2.09,
  2.09, 2.08, 2.07, 2.07, 2.06, 2.06, 2.06, 2.05, 2.05, 2.05, 2.04];
const t95 = (df) => (df < 1 ? NaN : df <= 30 ? T95[df] : 1.96);

const [header, ...rows] = readFileSync(join(root, "bench", "series.csv"), "utf8").trim().split(/\r?\n/);
const cols = header.split(",");
const series = rows.map((r) => Object.fromEntries(r.split(",").map((v, i) => [cols[i], v]))).filter((r) => r.valida === "si");
const obsFiles = new Set(readdirSync(join(root, "bench", "observaciones")));

const HERO = /obs t=(\d+) hero pid=(\d+) team=(\d) (\S+) lvl=(\d+) gold=-?\d+ nw=(\d+) lh=(\d+) dn=(\d+) k=(\d+) d=(\d+)/;
const LANES = { segura: [[0, 4], [2, 3]], mid: [[1], [1]], dificil: [[2, 3], [0, 4]] }; // [our positions, their positions], 0-based

// One match's metrics from dota-bot's side, or null when its log lacks the minute.
function matchMetrics(m) {
  const file = `${m.etiqueta}-${String(m.fecha).replace(/[-:T]/g, "")}-${m.partida}.log`;
  if (!obsFiles.has(file)) return null;
  const ourTeam = m.dotabot === "radiant" ? "2" : "3";
  const [radiant, dire] = m.heroes.split(" / ").map((g) => g.trim().split(/\s+/));
  const ours = ourTeam === "2" ? radiant : dire;
  const theirs = ourTeam === "2" ? dire : radiant;
  const at = {}; // hero -> its line at T
  for (const line of readFileSync(join(root, "bench", "observaciones", file), "latin1").split(/\r?\n/)) {
    const h = HERO.exec(line);
    if (h && Number(h[1]) === T) {
      at[h[4]] = { team: h[3], lvl: +h[5], nw: +h[6], lh: +h[7], dn: +h[8], k: +h[9], d: +h[10] };
    }
  }
  if (![...ours, ...theirs].every((h) => at[h])) return null;
  const out = {};
  ours.forEach((h, pos) => {
    for (const k of ["lvl", "nw", "lh", "dn", "k", "d"]) out[`${pos + 1}.${h}.${k}`] = at[h][k];
  });
  const sum = (heroes, k) => heroes.reduce((s, h) => s + at[h][k], 0);
  for (const [lane, [a, b]] of Object.entries(LANES)) {
    const us = a.map((i) => ours[i]);
    const them = b.map((i) => theirs[i]);
    out[`linea.${lane}.nw`] = sum(us, "nw") - sum(them, "nw");
    out[`linea.${lane}.nivel`] = (sum(us, "lvl") - sum(them, "lvl")) / us.length;
    out[`linea.${lane}.lh`] = sum(us, "lh") - sum(them, "lh");
    out[`linea.${lane}.muertes`] = sum(us, "d");
    out[`linea.${lane}.kills`] = sum(us, "k");
  }
  out["equipo.kills_dif"] = sum(ours, "k") - sum(theirs, "k");
  out["equipo.nw_dif"] = sum(ours, "nw") - sum(theirs, "nw");
  return { stratum: `${m.heroes} | ${m.dotabot}`, metrics: out };
}

const arms = regexes.map((re) => series.filter((r) => re.test(r.etiqueta)).map(matchMetrics).filter(Boolean));
const mean = (xs) => xs.reduce((s, x) => s + x, 0) / xs.length;
const sd = (xs) => (xs.length < 2 ? NaN : Math.sqrt(xs.reduce((s, x) => s + (x - mean(xs)) ** 2, 0) / (xs.length - 1)));
const fmt = (x) => (Number.isFinite(x) ? (Math.abs(x) >= 100 ? x.toFixed(0) : x.toFixed(2)) : "-");
const keys = [...new Set(arms.flatMap((a) => a.flatMap((m) => Object.keys(m.metrics))))];

console.log(`Minuto ${T / 60}. Partidas válidas con registro: ${arms.map((a) => a.length).join(" y ")}.`);
if (arms.length === 1) {
  console.log("métrica | media | DE | IC 95 %");
  for (const k of keys) {
    const xs = arms[0].map((m) => m.metrics[k]).filter((x) => x !== undefined);
    const half = t95(xs.length - 1) * sd(xs) / Math.sqrt(xs.length);
    console.log(`${k} | ${fmt(mean(xs))} | ${fmt(sd(xs))} | ${fmt(mean(xs) - half)} a ${fmt(mean(xs) + half)}`);
  }
} else {
  const strata = [...new Set(arms[0].map((m) => m.stratum))].filter((s) => arms[1].some((m) => m.stratum === s));
  console.log(`Estratos (alineación y lado) con los dos brazos: ${strata.length}. Prueba menos referencia:`);
  console.log("métrica | prueba | referencia | diferencia | IC 95 % | mínima detectable");
  for (const k of keys) {
    const diffs = strata.map((st) => {
      const a = arms[0].filter((m) => m.stratum === st).map((m) => m.metrics[k]);
      const b = arms[1].filter((m) => m.stratum === st).map((m) => m.metrics[k]);
      return a.length && b.length && a.every((x) => x !== undefined) && b.every((x) => x !== undefined) ? mean(a) - mean(b) : undefined;
    }).filter((x) => x !== undefined);
    const se = sd(diffs) / Math.sqrt(diffs.length);
    const half = t95(diffs.length - 1) * se;
    const all = (arm) => mean(arm.map((m) => m.metrics[k]).filter((x) => x !== undefined));
    console.log(`${k} | ${fmt(all(arms[0]))} | ${fmt(all(arms[1]))} | ${fmt(mean(diffs))} | ${fmt(mean(diffs) - half)} a ${fmt(mean(diffs) + half)} | ${fmt(2.8 * se)}`);
  }
}
