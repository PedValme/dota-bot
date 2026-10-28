// dota-bot benchmark summary: reads the "[BENCH]" lines that bots/FunLib/bench.lua prints into Dota's console.log,
// splits them into matches and prints who won. With --guardar <label> it appends new matches to bench/resultados.csv
// (a match already saved is skipped by its id).
//   node tools/bench/resumen.mjs [console.log] [--guardar <label>]
import { createHash } from "node:crypto";
import { existsSync, readFileSync, appendFileSync, mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const DEFAULT_LOG = "C:/Program Files (x86)/Steam/steamapps/common/dota 2 beta/game/dota/console.log";
const RADIANT = 2;
const DIRE = 3;

export function parseLine(line) {
  const at = line.indexOf("[BENCH] ");
  if (at < 0) return null;
  const fields = {};
  for (const pair of line.slice(at + 8).trim().split(/\s+/)) {
    const eq = pair.indexOf("=");
    if (eq > 0) fields[pair.slice(0, eq)] = pair.slice(eq + 1);
  }
  for (const k of ["v", "me", "t", "real", "rk", "rd", "rt", "rhp", "dk", "dd", "dt", "dhp"]) {
    if (k in fields) fields[k] = Number(fields[k]);
  }
  return fields.event ? fields : null;
}

// A new match starts at a "start" line from a team we already saw, or when game time goes backwards.
export function splitMatches(records) {
  const matches = [];
  let current = null;
  for (const r of records) {
    const restart =
      !current ||
      (r.event === "start" && current.starts.has(r.me)) ||
      r.t + 60 < current.lastT;
    if (restart) {
      current = { records: [], starts: new Set(), lastT: -Infinity };
      matches.push(current);
    }
    if (r.event === "start") current.starts.add(r.me);
    current.records.push(r);
    current.lastT = Math.max(current.lastT, r.t);
  }
  return matches.map(summarize);
}

export function summarize(match) {
  const recs = match.records;
  const last = recs.reduce((a, b) => (b.t >= a.t ? b : a));
  const end = recs.find((r) => r.event === "end");
  const final = end ?? last;
  let winner = "?";
  let how = "sin final";
  if (final.rhp <= 0 && final.dhp > 0) winner = "dire";
  else if (final.dhp <= 0 && final.rhp > 0) winner = "radiant";
  if (winner !== "?") how = end ? "final" : "inferido";
  // The Ancient often dies between two lines: a last line with one Ancient almost dead and the other healthy.
  else if (final.rhp < 1500 && final.dhp >= 3000) [winner, how] = ["dire", "probable"];
  else if (final.dhp < 1500 && final.rhp >= 3000) [winner, how] = ["radiant", "probable"];
  const ours = new Set(recs.map((r) => r.me));
  const side = (team) => (ours.has(team) ? "dota-bot" : "valve");
  // From the first line only, so a match saved half-way keeps its id once it finishes.
  const id = createHash("sha1").update(JSON.stringify(recs[0])).digest("hex").slice(0, 12);
  return {
    id,
    radiant: side(RADIANT),
    dire: side(DIRE),
    winner,
    winnerScript: winner === "?" ? "?" : side(winner === "radiant" ? RADIANT : DIRE),
    how,
    minutes: Math.round(final.t / 60),
    kills: `${final.rk}-${final.dk}`,
    towers: `${final.rt}-${final.dt}`,
    radiantHeroes: final.rh ?? "",
    direHeroes: final.dh ?? "",
  };
}

const COLUMNS = ["id", "label", "radiant", "dire", "winner", "winnerScript", "how", "minutes", "kills", "towers",
  "radiantHeroes", "direHeroes"];

export function toCsvRow(m, label) {
  return COLUMNS.map((c) => String(c === "label" ? label : m[c]).replaceAll(",", ";")).join(",");
}

function main(argv) {
  const at = argv.indexOf("--guardar");
  const label = at >= 0 ? argv[at + 1] : null;
  if (at >= 0 && !label) throw new Error("--guardar necesita una etiqueta, p. ej. --guardar oha-vs-valve-unfair");
  const rest = argv.filter((_, i) => at < 0 || (i !== at && i !== at + 1));
  const log = rest[0] ?? DEFAULT_LOG;
  if (!existsSync(log)) {
    console.error(`No existe ${log}. ¿Dota se abrió con -condebug?`);
    process.exit(1);
  }
  const records = readFileSync(log, "utf8").split(/\r?\n/).map(parseLine).filter(Boolean);
  const matches = splitMatches(records);
  if (!matches.length) {
    console.log("No hay líneas [BENCH] en el log.");
    return;
  }
  console.table(matches.map(({ radiantHeroes, direHeroes, ...m }) => m));
  const decided = matches.filter((m) => m.winnerScript !== "?");
  const wins = decided.filter((m) => m.winnerScript === "dota-bot").length;
  const mixed = decided.filter((m) => m.radiant !== m.dire);
  if (mixed.length) {
    const ourWins = mixed.filter((m) => m.winnerScript === "dota-bot").length;
    console.log(`dota-bot contra valve: ${ourWins} de ${mixed.length} partidas decididas.`);
  } else {
    console.log(`${decided.length} partidas decididas (${wins} con dota-bot ganador).`);
  }
  if (label) {
    const root = fileURLToPath(new URL("../..", import.meta.url));
    const csv = join(root, "bench", "resultados.csv");
    mkdirSync(dirname(csv), { recursive: true });
    if (!existsSync(csv)) appendFileSync(csv, COLUMNS.join(",") + "\n");
    const saved = new Set(readFileSync(csv, "utf8").split(/\r?\n/).map((l) => l.split(",")[0]));
    const fresh = matches.filter((m) => !saved.has(m.id));
    for (const m of fresh) appendFileSync(csv, toCsvRow(m, label) + "\n");
    console.log(`${fresh.length} partidas nuevas guardadas en bench/resultados.csv (${matches.length - fresh.length} ya estaban).`);
  }
}

const self = fileURLToPath(import.meta.url).toLowerCase();
if (process.argv[1] && resolve(process.argv[1]).toLowerCase() === self) main(process.argv.slice(2));
