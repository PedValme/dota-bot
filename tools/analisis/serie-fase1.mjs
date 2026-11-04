// dota-bot: the fixed analysis of the phase 1 series (DECISIONES 2026-11-04; question written in MEDICIONES before
// launching). Fixed before seeing the data; nothing is cut by side or hero afterwards.
// Pairs: in each block the same heroes play both variants on both sides, so each (block, side) gives one pair
// control_sniper / base_sniper. Per pair: the Sniper's last hits (LH, primary) and net worth (NW, secondary) at
// minute 10, from the "[bench] linea" line whose t is the first >= 600 (the line can come late if the hero was dead).
// Result: mean of the per-pair differences (own − OHA), its 95 % interval (t distribution), and that mean as a share of
// OHA's mean. The bar (DECISIONES 2026-11-04, replaces the −10 % and the net worth rule): phase 1 passes when last hits
// are not inferior by −15 % of OHA's mean (the interval's lower end above it), the own mean reaches the floor of 45 and
// its deaths are not above OHA's; net worth is only informative. Stop for futility (same day): at 8 and 14 pairs, a mean
// below −8 last hits. Several labels are one series (its stages, a, b, c), played in that order.
//   node tools/analisis/serie-fase1.mjs <etiqueta> [<etiqueta>...]
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const tags = process.argv.slice(2);
const tag = tags.join("+");
if (!tags.length) { console.log("Uso: node tools/analisis/serie-fase1.mjs <etiqueta> [<etiqueta>...]"); process.exit(1); }
const dir = join(root, "bench", "observaciones");
const kv = (line) => Object.fromEntries([...line.matchAll(/(\w+)=(\S+)/g)].map((m) => [m[1], m[2]]));

// Valid matches and their block from series.csv (the last attempt of each match counts).
const csv = readFileSync(join(root, "bench", "series.csv"), "utf8").split(/\r?\n/);
const head = csv[0].split(",");
const col = (name) => head.indexOf(name);
const rows = new Map();
for (const line of csv.slice(1)) {
  const f = line.split(",");
  if (!tags.includes(f[col("etiqueta")])) continue;
  rows.set(`${f[col("etiqueta")]}|${f[col("partida")]}`, { etiqueta: f[col("etiqueta")], partida: Number(f[col("partida")]), bloque: Number(f[col("bloque")]), valida: f[col("valida")], variante: f[col("variante")],
    fijos: f[col("heroes_fijos")] ?? "", corte: f[col("corte")] ?? "", arboles: (f[col("codigo")] ?? "").split("@")[1] ?? "",
    version: f[col("dota_version")] ?? "", modo: f[col("modo")] ?? "", dificultad: f[col("dificultad")] ?? "", heroes: f[col("heroes")] ?? "" });
}
// What decides must be one draw-based run: fixed heroes (development only) give a single match-up, and a reused label
// would mix commits or cuts, which the orchestrator only checks within one run (review of 2026-11-04).
const series = [...rows.values()];
if (series.some((r) => r.fijos === "si")) throw new Error(`${tag}: tiene partidas con --heroes; una serie que decide mantiene el sorteo`);
// Dota can update between stages, and the orchestrator only watches its version within one run.
for (const [name, key] of [["código", "arboles"], ["corte", "corte"], ["versión de Dota", "version"], ["modo", "modo"], ["dificultad", "dificultad"]]) {
  const distinct = new Set(series.map((r) => r[key]));
  if (distinct.size > 1) throw new Error(`${tag}: mezcla más de un ${name}: ${[...distinct].join(", ")}`);
}

const pairs = new Map(); // "bloque|team" -> { control, base }
// Only the last attempt's log of each match (a repeated invalid match leaves earlier logs with the same number; the
// timestamp in the name orders them). Review of 2026-11-04: lost pairs are counted by arm and reason, never dropped
// silently, and the arm in the log must match the variant in series.csv.
const latest = new Map();
for (const t of tags) {
  for (const f of readdirSync(dir).filter((f) => f.startsWith(t + "-") && f.endsWith(".log")).sort()) {
    latest.set(`${t}|${Number(f.match(/-(\d+)\.log$/)?.[1])}`, f);
  }
}
const lost = [];
const inOrder = [...rows.entries()].sort((a, b) => tags.indexOf(a[1].etiqueta) - tags.indexOf(b[1].etiqueta) || a[1].partida - b[1].partida);
for (const [n, row] of inOrder) {
  const arm0 = row.variante === "control_sniper" ? "control" : row.variante === "base_sniper" ? "base" : row.variante;
  if (row.valida !== "si") { lost.push(`partida ${n} (${arm0}): no válida`); continue; }
  const f = latest.get(n);
  if (!f) { lost.push(`partida ${n} (${arm0}): sin log observado`); continue; }
  const all = readFileSync(join(dir, f), "latin1").split(/\r?\n/);
  const at10 = all.filter((l) => l.includes("[bench] linea ")).map(kv).find((x) => Number(x.t) >= 600);
  if (!at10) { lost.push(`partida ${n} (${arm0}): sin línea del min 10`); continue; }
  const arm = at10.control === "true" ? "control" : "base";
  if (arm !== arm0) throw new Error(`partida ${n}: series.csv dice ${row.variante} y el log dice control=${at10.control}`);
  // control=true comes from the variant, not from the own Think running: its lines are what prove it.
  const ownLines = all.filter((l) => l.includes("[bench] prop ")).length;
  if ((arm === "control") !== (ownLines > 0)) throw new Error(`partida ${n}: brazo ${arm} con ${ownLines} líneas del bot propio`);
  const key = `${row.etiqueta}|${row.bloque}|${at10.team}`;
  if (pairs.get(key)?.[arm]) throw new Error(`partida ${n}: la pareja ${key} ya tiene brazo ${arm} (duplicada)`);
  const other = pairs.get(key)?.[arm === "control" ? "base" : "control"];
  if (other && other.heroes !== row.heroes) throw new Error(`partida ${n}: la pareja ${key} no tiene los mismos héroes: ${other.heroes} frente a ${row.heroes}`);
  if (Number(at10.t) > 620) lost.push(`partida ${n} (${arm}): muestra tardía t=${at10.t} (contada)`);
  // The Sniper's thinks per second (same in both arms, or the arm that thinks less is handicapped) and runes by minute 10.
  const pid = at10.pid;
  const rates = all.filter((l) => (l.includes("[bench] prop think") || l.includes("[bench] think ")) && l.includes(`pid=${pid} `)).map((l) => Number(kv(l).por_s)).filter(Number.isFinite);
  const runes = all.filter((l) => l.includes(` rune pid=${pid} `) && Number(l.match(/obs t=(-?\d+)/)?.[1]) <= 600).length;
  pairs.set(key, { ...(pairs.get(key) ?? {}), [arm]: { lh: Number(at10.lh), nw: Number(at10.nw), muertes: Number(at10.muertes), kills: Number(at10.kills), t: Number(at10.t), heroes: row.heroes,
    minThink: rates.length ? Math.min(...rates) : NaN, runes } });
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
// The two pairs of a block share their heroes: the interval is over per-block means, not over pairs as if independent
// (review of the gate, 2026-11-04).
const blockKey = (k) => k.split("|").slice(0, -1).join("|");
const verdicts = {};
const shares = {};
for (const m of ["lh", "nw"]) {
  const byBlock = new Map();
  for (const [k, p] of complete) byBlock.set(blockKey(k), [...(byBlock.get(blockKey(k)) ?? []), p.control[m] - p.base[m]]);
  const d = [...byBlock.values()].map((xs) => xs.reduce((a, x) => a + x, 0) / xs.length);
  const n = d.length;
  if (n < 2) { console.log(`${m}: menos de 2 bloques`); continue; }
  const mean = d.reduce((a, x) => a + x, 0) / n;
  const sd = Math.sqrt(d.reduce((a, x) => a + (x - mean) ** 2, 0) / (n - 1));
  const half = T95[Math.min(n - 1, 30) - 1] * sd / Math.sqrt(n);
  const oha = complete.reduce((a, [, p]) => a + p.base[m], 0) / complete.length;
  // Three verdicts: not inferior (lower end above −15 % of OHA: this does not say "equal"), worse (upper end below 0),
  // else undetermined.
  const verdict = mean - half > -0.15 * oha ? "NO INFERIOR A −15 %" : mean + half < 0 ? "PEOR" : "INDETERMINADO";
  verdicts[m] = verdict;
  shares[m] = mean / oha;
  console.log(`${m.toUpperCase()} min 10: diferencia media ${mean.toFixed(1)} (IC95 ${(mean - half).toFixed(1)} a ${(mean + half).toFixed(1)}, ${n} bloques), OHA media ${oha.toFixed(0)} → ${(100 * mean / oha).toFixed(1)} %: ${m === "nw" ? `${verdict}, informativo` : verdict}`);
}
const avgOf = (arm, m) => complete.reduce((a, [, p]) => a + p[arm][m], 0) / Math.max(complete.length, 1);
const minOf = (arm, m) => Math.min(...complete.map(([, p]) => p[arm][m]));
if (verdicts.lh) {
  const ownLh = avgOf("control", "lh");
  const deaths = [avgOf("control", "muertes"), avgOf("base", "muertes")];
  const floor = ownLh >= 45;
  const fewDeaths = deaths[0] <= deaths[1];
  console.log(`Suelo: propio ${ownLh.toFixed(1)} LH frente a 45: ${floor ? "cumple" : "NO cumple"}. Muertes: propio ${deaths[0].toFixed(2)} frente a OHA ${deaths[1].toFixed(2)}: ${fewDeaths ? "cumple" : "NO cumple"}.`);
  // Last hits alone are blind to what each arm left undone: the own bot does not pay the trips to runes it cannot take.
  console.log(`Informativo: kills ${avgOf("control", "kills").toFixed(2)} frente a ${avgOf("base", "kills").toFixed(2)}; runas ${avgOf("control", "runes").toFixed(2)} frente a ${avgOf("base", "runes").toFixed(2)}; Think/s mínimo ${minOf("control", "minThink")} frente a ${minOf("base", "minThink")}.`);
  // Three stages decide; a look at one or two only says whether to go on (DECISIONES 2026-11-04: a stop only for futility).
  if (tags.length < 3) {
    const lhDiff = avgOf("control", "lh") - avgOf("base", "lh");
    console.log(lhDiff < -8
      ? `Parada por inutilidad: ${complete.length} parejas con media ${lhDiff.toFixed(1)} LH, por debajo de −8. No se sigue.`
      : `Parcial, no decide: ${complete.length} parejas con media ${lhDiff.toFixed(1)} LH, se sigue.`);
  } else {
    console.log(`Fase 1: ${verdicts.lh === "NO INFERIOR A −15 %" && floor && fewDeaths ? "PASA" : "NO PASA"} (regla: LH no inferior a −15 %, suelo de 45 y muertes ≤ OHA).`);
    if (shares.lh < -0.05 && shares.lh >= -0.15) console.log("Media entre −5 % y −15 %: pasar a la fase 2 pide a Pedro conforme y la brecha anotada como defecto (DECISIONES 2026-11-04).");
  }
}
