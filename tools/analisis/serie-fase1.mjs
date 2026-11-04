// dota-bot: the fixed analysis of the phase 1 series (DECISIONES 2026-11-04; question written in MEDICIONES before
// launching). Fixed before seeing the data; nothing is cut by side or hero afterwards.
// Pairs: in each block the same heroes play both variants on both sides, so each (block, side) gives one pair
// control_sniper / base_sniper. Per pair: the Sniper's last hits (LH, primary) and net worth (NW, secondary) at
// minute 10, from the "[bench] linea" line whose t is the first >= 600 (the line can come late if the hero was dead).
// Result: mean of the per-pair differences (own − OHA), its 95 % interval (t distribution), and that mean as a share of
// OHA's mean. "Iguala" (non-inferior) when the interval's lower end is above −10 % of OHA's mean, for LH and for NW.
//   node tools/analisis/serie-fase1.mjs <etiqueta>
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const tag = process.argv[2];
if (!tag) { console.log("Uso: node tools/analisis/serie-fase1.mjs <etiqueta>"); process.exit(1); }
const dir = join(root, "bench", "observaciones");
const kv = (line) => Object.fromEntries([...line.matchAll(/(\w+)=(\S+)/g)].map((m) => [m[1], m[2]]));

// Valid matches and their block from series.csv (the last attempt of each match counts).
const csv = readFileSync(join(root, "bench", "series.csv"), "utf8").split(/\r?\n/);
const head = csv[0].split(",");
const col = (name) => head.indexOf(name);
const rows = new Map();
for (const line of csv.slice(1)) {
  const f = line.split(",");
  if (f[col("etiqueta")] !== tag) continue;
  rows.set(Number(f[col("partida")]), { bloque: Number(f[col("bloque")]), valida: f[col("valida")], variante: f[col("variante")] });
}

const pairs = new Map(); // "bloque|team" -> { control, base }
// Only the last attempt's log of each match (a repeated invalid match leaves earlier logs with the same number; the
// timestamp in the name orders them). Review of 2026-11-04: lost pairs are counted by arm and reason, never dropped
// silently, and the arm in the log must match the variant in series.csv.
const latest = new Map();
for (const f of readdirSync(dir).filter((f) => f.startsWith(tag + "-") && f.endsWith(".log")).sort()) {
  latest.set(Number(f.match(/-(\d+)\.log$/)?.[1]), f);
}
const lost = [];
for (const [n, row] of [...rows.entries()].sort((a, b) => a[0] - b[0])) {
  const arm0 = row.variante === "control_sniper" ? "control" : row.variante === "base_sniper" ? "base" : row.variante;
  if (row.valida !== "si") { lost.push(`partida ${n} (${arm0}): no válida`); continue; }
  const f = latest.get(n);
  if (!f) { lost.push(`partida ${n} (${arm0}): sin log observado`); continue; }
  const lines = readFileSync(join(dir, f), "latin1").split(/\r?\n/).filter((l) => l.includes("[bench] linea "));
  const at10 = lines.map(kv).find((x) => Number(x.t) >= 600);
  if (!at10) { lost.push(`partida ${n} (${arm0}): sin línea del min 10`); continue; }
  const arm = at10.control === "true" ? "control" : "base";
  if (arm !== arm0) throw new Error(`partida ${n}: series.csv dice ${row.variante} y el log dice control=${at10.control}`);
  const key = `${row.bloque}|${at10.team}`;
  if (pairs.get(key)?.[arm]) throw new Error(`partida ${n}: la pareja ${key} ya tiene brazo ${arm} (duplicada)`);
  if (Number(at10.t) > 620) lost.push(`partida ${n} (${arm}): muestra tardía t=${at10.t} (contada)`);
  pairs.set(key, { ...(pairs.get(key) ?? {}), [arm]: { lh: Number(at10.lh), nw: Number(at10.nw), muertes: Number(at10.muertes), kills: Number(at10.kills), t: Number(at10.t) } });
}

const complete = [...pairs.entries()].filter(([, p]) => p.control && p.base).sort();
console.log(`Serie ${tag}: ${complete.length} parejas completas (bloque|equipo).`);
const incomplete = [...pairs.entries()].filter(([, p]) => !(p.control && p.base)).map(([k, p]) => `${k} sin ${p.control ? "base" : "control"}`);
if (lost.length || incomplete.length) console.log(`  Perdidas: ${[...lost, ...incomplete].join("; ")}`);
for (const [k, p] of complete) {
  console.log(`  ${k}: propio lh=${p.control.lh} nw=${p.control.nw} k/m=${p.control.kills}/${p.control.muertes} · OHA lh=${p.base.lh} nw=${p.base.nw} k/m=${p.base.kills}/${p.base.muertes}`);
}
// Two-sided 95 % t quantiles by degrees of freedom (1-30).
const T95 = [12.706, 4.303, 3.182, 2.776, 2.571, 2.447, 2.365, 2.306, 2.262, 2.228, 2.201, 2.179, 2.160, 2.145, 2.131,
  2.120, 2.110, 2.101, 2.093, 2.086, 2.080, 2.074, 2.069, 2.064, 2.060, 2.056, 2.052, 2.048, 2.045, 2.042];
const verdicts = {};
for (const m of ["lh", "nw"]) {
  const d = complete.map(([, p]) => p.control[m] - p.base[m]);
  const n = d.length;
  if (n < 2) { console.log(`${m}: menos de 2 parejas`); continue; }
  const mean = d.reduce((a, x) => a + x, 0) / n;
  const sd = Math.sqrt(d.reduce((a, x) => a + (x - mean) ** 2, 0) / (n - 1));
  const half = T95[Math.min(n - 1, 30) - 1] * sd / Math.sqrt(n);
  const oha = complete.reduce((a, [, p]) => a + p.base[m], 0) / n;
  // Three verdicts, fixed before the data (MEDICIONES, the series' question): equal (lower end above −10 % of OHA),
  // worse (upper end below 0), else undetermined.
  const verdict = mean - half > -0.10 * oha ? "IGUALA" : mean + half < 0 ? "PEOR" : "INDETERMINADO";
  verdicts[m] = verdict;
  console.log(`${m.toUpperCase()} min 10: diferencia media ${mean.toFixed(1)} (IC95 ${(mean - half).toFixed(1)} a ${(mean + half).toFixed(1)}), OHA media ${oha.toFixed(0)} → ${(100 * mean / oha).toFixed(1)} %: ${verdict}`);
}
// The joint rule: phase 1 passes when last hits IGUALA and net worth is not PEOR.
if (verdicts.lh && verdicts.nw) {
  const pass = verdicts.lh === "IGUALA" && verdicts.nw !== "PEOR";
  console.log(`Fase 1: ${pass ? "PASA" : "NO PASA"} (regla: LH IGUALA y patrimonio no PEOR).`);
}
