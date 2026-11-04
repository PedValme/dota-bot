// dota-bot: where does the own Sniper lose last hits against OHA's? Reads the observed smokes (bench/observaciones),
// no new matches (DECISIONES 2026-11-04). For each match: last hits per minute of both arms; for the own bot, by
// intent: seconds spent per intent ("[bench] prop estado" every 2 s), last-hit attempts and how each ended.
//   node tools/analisis/diag-linea.mjs fase1 fase1c fase1d
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const dir = join(root, "bench", "observaciones");
const tags = process.argv.slice(2);
const kv = (line) => Object.fromEntries([...line.matchAll(/(\w+)=(\S+)/g)].map((m) => [m[1], m[2]]));
const LIMIT = 600;

for (const tag of tags) {
  const files = readdirSync(dir).filter((f) => f.startsWith(tag + "-") && f.endsWith(".log")).sort();
  console.log(`\n===== ${tag}`);
  const curves = {};
  for (const f of files) {
    const all = readFileSync(join(dir, f), "latin1").split(/\r?\n/);
    const linea = all.filter((l) => l.includes("[bench] linea ")).map(kv).filter((x) => Number(x.t) <= LIMIT + 5);
    if (!linea.length) continue;
    const control = linea[0].control === "true";
    const key = `${control ? "propio" : "OHA"} team=${linea[0].team}`;
    curves[key] = linea.map((x) => Number(x.lh));
    console.log(`${key}  LH por minuto: ${linea.map((x) => x.lh).join(" ")}  · DN min10: ${linea.at(-1).dn} · NW: ${linea.at(-1).nw}`);
    if (!control) {
      // OHA's mode of the Sniper every 2 s, from its observer lines.
      const pid = linea[0].pid;
      const modes = {};
      for (const l of all.filter((x) => x.includes("[bench] mode ") && x.includes(`pid=${pid} `))) {
        const m = l.match(/\[bench\] mode t=(-?\d+) pid=\d+ \S+ (\S+) /);
        if (m && Number(m[1]) >= 0 && Number(m[1]) <= LIMIT) modes[m[2]] = (modes[m[2]] ?? 0) + 2;
      }
      console.log(`  OHA, segundos por modo: ${Object.entries(modes).sort((a, b) => b[1] - a[1]).map(([k, n]) => `${k} ${n}`).join(", ")}`);
      continue;
    }
    const inTime = (l) => { const t = Number(kv(l).t); return t >= 0 && t <= LIMIT; };
    const intents = {};
    for (const l of all.filter((x) => x.includes("[bench] prop estado ") && inTime(x))) {
      const i = kv(l).intencion; intents[i] = (intents[i] ?? 0) + 2;
    }
    console.log(`  propio, segundos por intención: ${Object.entries(intents).sort((a, b) => b[1] - a[1]).map(([k, n]) => `${k} ${n}`).join(", ")}`);
    const res = all.filter((x) => x.includes("[bench] prop golpe_res ") && inTime(x));
    const lh = res.filter((x) => x.includes(" ultimo_golpe "));
    const ok = lh.filter((x) => x.includes(" acierto "));
    const dead = lh.filter((x) => x.includes(" fallo ") && x.includes("creep_vivo=false"));
    const alive = lh.filter((x) => x.includes(" fallo ") && x.includes("creep_vivo=true"));
    const repl = lh.filter((x) => x.includes(" reemplazado"));
    console.log(`  intentos de LH: ${lh.length}: aciertos ${ok.length}, se lo llevó otro antes ${dead.length}, quedó vivo ${alive.length}, reemplazados ${repl.length}`);
    const dres = res.filter((x) => x.includes(" denegar "));
    console.log(`  intentos de denegar: ${dres.length}, aciertos ${dres.filter((x) => x.includes(" acierto ")).length}`);
    // How many last-hit attempts per minute, to see the gap against the curve.
    const perMin = new Array(11).fill(0);
    for (const l of all.filter((x) => x.includes("[bench] prop golpe ") && !x.includes("golpe_res") && inTime(x) && x.includes("creep_badguys") === (linea[0].team === "2"))) {
      perMin[Math.min(10, Math.floor(Number(kv(l).t) / 60))]++;
    }
    console.log(`  intentos contra creeps enemigos por minuto: ${perMin.join(" ")}`);
    // Enemy creeps within 1500 while the bot is not in lane intents: farm passing by.
    let away = 0, awayCreeps = 0;
    for (const l of all.filter((x) => x.includes("[bench] prop estado ") && inTime(x))) {
      const k = kv(l);
      if (!["linea", "preparar_golpe", "ultimo_golpe", "denegar"].includes(k.intencion)) {
        away += 2;
        if (Number(k.creeps_e) > 0) awayCreeps += 2;
      }
    }
    console.log(`  fuera de creepear ${away} s, con creeps enemigos a 1500 en ${awayCreeps} s`);
  }
}
