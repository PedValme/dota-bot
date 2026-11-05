// dota-bot: a hero's numbers in a smoke at one game minute, per variant (10 by default; the middle game reads 25, with the
// deaths and kills since minute 10 and the idle gold). Valid matches of each label, last attempt only. Different runs have
// different draws and load: descriptive, it decides no series.
//   node tools/analisis/humo-linea.mjs [--min 25] <etiqueta> [<etiqueta>...]
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const args = process.argv.slice(2);
const minuteAt = args.indexOf("--min");
const minute = minuteAt >= 0 ? Number(args.splice(minuteAt, 2)[1]) : 10;
const tags = args;
if (!tags.length || !Number.isFinite(minute)) { console.log("Uso: node tools/analisis/humo-linea.mjs [--min 25] <etiqueta> [<etiqueta>...]"); process.exit(1); }
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
    const lane = readFileSync(join(dir, file), "latin1").split(/\r?\n/).filter((l) => l.includes("[bench] linea ")).map(kv);
    const at = lane.find((x) => Number(x.t) >= minute * 60);
    if (!at) { arm.lost += 1; continue; }
    const at10 = lane.find((x) => Number(x.t) >= 600) ?? at;
    arm.games.push({ lh: +at.lh, dn: +at.dn, nw: +at.nw, k: +at.kills, m: +at.muertes, cpu: +r.cpu_media, lado: r.dotabot,
      oro: +at.oro, mDesde10: +at.muertes - +at10.muertes, kDesde10: +at.kills - +at10.kills });
  }
}
for (const [key, arm] of arms) {
  const g = arm.games;
  const avg = (f) => mean(g.map((x) => x[f])).toFixed(1);
  const later = minute > 10 ? ` · desde el min 10: muertes ${avg("mDesde10")}, kills ${avg("kDesde10")} · oro sin gastar ${avg("oro")}` : "";
  console.log(`${key}, min ${minute}: n=${g.length}${arm.lost ? ` (perdidas ${arm.lost})` : ""} · LH ${avg("lh")} [${g.map((x) => x.lh).join(" ")}] · DN ${avg("dn")} · muertes ${avg("m")} · kills ${avg("k")} · NW ${avg("nw")}${later} · CPU ${avg("cpu")} %`);
}
