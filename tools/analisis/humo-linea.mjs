// dota-bot: the lane numbers of a smoke at minute 10, per variant, for the phase 1 bar (DECISIONES 2026-11-04: floor of
// 45 last hits and deaths <= OHA; parity read at -15 %, net worth only informative). Valid matches of each label, last
// attempt only. Different runs have different draws and load: descriptive, it decides no series.
//   node tools/analisis/humo-linea.mjs <etiqueta> [<etiqueta>...]
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const tags = process.argv.slice(2);
if (!tags.length) { console.log("Uso: node tools/analisis/humo-linea.mjs <etiqueta> [<etiqueta>...]"); process.exit(1); }
const dir = join(root, "bench", "observaciones");
const kv = (line) => Object.fromEntries([...line.matchAll(/(\w+)=(\S+)/g)].map((m) => [m[1], m[2]]));
const csv = readFileSync(join(root, "bench", "series.csv"), "utf8").split(/\r?\n/);
const head = csv[0].split(",");
const row = (line) => Object.fromEntries(line.split(",").map((v, i) => [head[i], v]));
const rows = csv.slice(1).filter(Boolean).map(row);
const mean = (xs) => xs.reduce((a, b) => a + b, 0) / Math.max(xs.length, 1);

const arms = new Map();
for (const tag of tags) {
  const last = new Map();
  for (const r of rows.filter((x) => x.etiqueta === tag)) last.set(r.partida, r);
  const files = readdirSync(dir).filter((f) => f.startsWith(tag + "-") && f.endsWith(".log"));
  for (const r of last.values()) {
    const key = `${tag} ${r.variante}`;
    const arm = arms.get(key) ?? { games: [], lost: 0 };
    arms.set(key, arm);
    const file = files.find((f) => f === `${tag}-${r.fecha.replace(/[-:T]/g, "")}-${r.partida}.log`);
    if (r.valida !== "si" || !file) { arm.lost += 1; continue; }
    const at10 = readFileSync(join(dir, file), "latin1").split(/\r?\n/).filter((l) => l.includes("[bench] linea "))
      .map(kv).find((x) => Number(x.t) >= 600);
    if (!at10) { arm.lost += 1; continue; }
    arm.games.push({ lh: +at10.lh, dn: +at10.dn, nw: +at10.nw, k: +at10.kills, m: +at10.muertes, cpu: +r.cpu_media, lado: r.dotabot });
  }
}
for (const [key, arm] of arms) {
  const g = arm.games;
  const avg = (f) => mean(g.map((x) => x[f])).toFixed(1);
  console.log(`${key}: n=${g.length}${arm.lost ? ` (perdidas ${arm.lost})` : ""} · LH ${avg("lh")} [${g.map((x) => x.lh).join(" ")}] · DN ${avg("dn")} · muertes ${avg("m")} · kills ${avg("k")} · NW ${avg("nw")} · CPU ${avg("cpu")} %`);
}
