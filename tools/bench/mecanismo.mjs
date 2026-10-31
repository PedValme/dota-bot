// Mechanism check of a benchmark series (Pedro, 2026-10-31: judge a fix by what the bots do, not only by wins against
// Valve, where the base bot already wins ~91%). Per variant and side, from bench/series.csv and the observer logs
// (bench/observaciones, orquestador.mjs --observar): K/D, dota-bot deaths per 10 minutes and how they come (to towers,
// to Roshan, isolated: no other hero death within 15 s), the team brain's calls to defend on a single hero, the share
// of time its heroes spend in their own half while the plan says gather, push, close or take, and the engine's
// invalid orders per match.
//   node tools/bench/mecanismo.mjs <etiqueta> [<etiqueta> ...]
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../..", import.meta.url));
const tags = process.argv.slice(2);
if (!tags.length) throw new Error("Uso: node tools/bench/mecanismo.mjs <etiqueta> [<etiqueta> ...]");
const [header, ...rows] = readFileSync(join(root, "bench", "series.csv"), "utf8").trim().split(/\r?\n/);
const cols = header.split(",");
const matches = rows.map((r) => Object.fromEntries(r.split(",").map((v, i) => [cols[i], v])))
  .filter((r) => tags.includes(r.etiqueta) && r.valida === "si");
const obsDir = join(root, "bench", "observaciones");
const obsFiles = readdirSync(obsDir);

// Own half: Radiant is below the river diagonal (x + y < 0), Dire above.
const ownHalf = (team, x, y) => (team === "2" ? x + y < 0 : x + y > 0);

const agg = {};
for (const m of matches) {
  const file = obsFiles.find((f) => f.startsWith(`${m.etiqueta}-`) && f.endsWith(`-${m.partida}.log`));
  if (!file) continue;
  const lines = readFileSync(join(obsDir, file), "latin1").split(/\r?\n/);
  const team = m.dotabot === "radiant" ? "2" : "3";
  const key = `${m.variante || "base"} ${m.dotabot}`;
  const a = (agg[key] ??= { games: 0, wins: 0, minutes: 0, kills: 0, deaths: 0, tower: 0, roshan: 0, isolated: 0,
    defendOne: 0, groupSnaps: 0, groupOwn: 0, invalid: 0 });
  a.games++;
  if (m.ganador === m.dotabot) a.wins++;
  a.minutes += Number(m.minutos) || 0;
  const plans = [];
  const deaths = [];
  for (const l of lines) {
    let x = l.match(/\[bench\] plan t=(\d+) team=(\d) \S+ -> (\S+)/);
    if (x && x[2] === team) {
      plans.push([+x[1], x[3]]);
      if (x[3] === "DEFENDER" && / heroes=1 /.test(l)) a.defendOne++;
      continue;
    }
    x = l.match(/obs t=(\d+) kill victim=\S+ vteam=(\d) vpid=(-?\d+) killer=(\S+)/);
    if (x && +x[3] >= 0) {
      deaths.push({ t: +x[1], team: x[2] });
      if (x[2] === team) {
        a.deaths++;
        if (/tower|fort/.test(x[4])) a.tower++;
        else if (/roshan/.test(x[4])) a.roshan++;
      } else a.kills++;
      continue;
    }
    if (l.includes("invalid order")) { a.invalid++; continue; }
    x = l.match(/obs t=(\d+) hero pid=\d+ team=(\d) \S+ .* alive=1 x=(-?\d+) y=(-?\d+)/);
    if (x && x[2] === team && plans.length) {
      let state = "LINEA";
      for (const [t, s] of plans) if (t <= +x[1]) state = s;
      if (/AGRUPAR|EMPUJAR|CERRAR|TOMAR/.test(state)) {
        a.groupSnaps++;
        if (ownHalf(team, +x[3], +x[4])) a.groupOwn++;
      }
    }
  }
  for (const d of deaths) {
    if (d.team === team && !deaths.some((o) => o !== d && Math.abs(o.t - d.t) <= 15)) a.isolated++;
  }
}

console.log(`Mecanismo de ${tags.join(", ")} (solo partidas válidas)`);
for (const k of Object.keys(agg).sort()) {
  const a = agg[k];
  const per10 = (n) => (a.minutes ? (10 * n / a.minutes).toFixed(2) : "-");
  console.log(`  ${k.padEnd(22)} ganó ${a.wins}/${a.games} · K/D ${(a.kills / Math.max(1, a.deaths)).toFixed(2)} · muertes/10 min ${per10(a.deaths)}`
    + ` (torre ${per10(a.tower)}, Roshan ${per10(a.roshan)}, aisladas ${(100 * a.isolated / Math.max(1, a.deaths)).toFixed(0)}%)`
    + ` · defensas por 1 héroe/partida ${(a.defendOne / a.games).toFixed(1)}`
    + ` · en mitad propia al agrupar/empujar ${a.groupSnaps ? (100 * a.groupOwn / a.groupSnaps).toFixed(0) + "%" : "-"}`
    + ` · órdenes inválidas/partida ${Math.round(a.invalid / a.games)}`);
}
