// Summarizes one observer log of the benchmark (bench/observaciones/*.log, written with orquestador.mjs --observar):
// where each hero was every minute, how grouped each team played, farm and net worth, runes, wards, couriers,
// dota-bot's active modes by net worth lead, how many of its bots pushed together, and the engine's errors.
//   node tools/bench/analizar.mjs bench/observaciones/<file>.log [2|3]
// The team that dota-bot played (2 Radiant, 3 Dire) is read from its "[bench] mode" lines unless given.
import { readFileSync } from "node:fs";
const [file, botTeamArg] = process.argv.slice(2);
const lines = readFileSync(file, "utf8").split(/\r?\n/);
const kv = (s) => Object.fromEntries([...s.matchAll(/(\w+)=(\S+)/g)].map((m) => [m[1], m[2]]));
const name = { 2: "Radiant", 3: "Dire" };

function zone(x, y) {
  if (x < -4300 && y < -3800) return "baseR";
  if (x > 4000 && y > 3400) return "baseD";
  if (Math.abs(x - y) < 1400) return "mid";
  if (x < -5200 || y > 5200) return "top";
  if (x > 5200 || y < -5200) return "bot";
  if (Math.abs(x + y) < 900) return "rio";
  return x + y < 0 ? "jungR" : "jungD";
}

const snaps = {};
const pidTeam = {};
const couriers = {};
for (const l of lines) {
  let m = l.match(/obs t=(-?\d+) hero pid=(\d+) team=(\d) (\S+) (.*)/);
  if (m) {
    const [, t, pid, team, hero, rest] = m;
    const d = kv(rest);
    pidTeam[pid] = team;
    (snaps[t] ??= []).push({ t: +t, pid, hero, team, z: d.alive === "1" ? zone(+d.x, +d.y) : "MUERTO", ...d });
    continue;
  }
  m = l.match(/obs t=(-?\d+) courier (.*)/);
  if (m) { const d = kv(m[2]); (couriers[m[1]] ??= []).push(d); }
}
const times = Object.keys(snaps).map(Number).sort((a, b) => a - b);
const modePid = lines.map((l) => l.match(/\[bench\] mode t=-?\d+ pid=(\d+)/)?.[1]).find(Boolean);
const botTeam = botTeamArg ?? pidTeam[modePid] ?? "?";
console.log(`dota-bot = ${name[botTeam] ?? "?"}`);
console.log("t(s)  | Radiant | Dire");
for (const t of times) {
  if (t % 60 !== 0) continue;
  const side = (team) => snaps[t].filter((s) => s.team === team).map((s) => `${s.hero.slice(0, 7)}:${s.z}`).join(" ");
  console.log(`${String(t).padStart(5)} | ${side("2")} | ${side("3")}`);
}
// Agrupación: héroes vivos fuera de base en la misma zona que el grupo mayor, media por snapshot desde el minuto 10.
for (const team of ["2", "3"]) {
  let sum = 0, n = 0, inBase = 0, dead = 0, total = 0;
  for (const t of times.filter((t) => t >= 600)) {
    const zs = snaps[t].filter((s) => s.team === team);
    const counts = {};
    for (const s of zs) {
      total++;
      if (s.z === "MUERTO") { dead++; continue; }
      if (s.z.startsWith("base")) inBase++;
      counts[s.z] = (counts[s.z] ?? 0) + 1;
    }
    sum += Math.max(0, ...Object.values(counts)); n++;
  }
  console.log(`${name[team]} desde min 10: grupo mayor medio ${(sum / n).toFixed(2)} héroes; en base ${(100 * inBase / total).toFixed(0)}%; muertos ${(100 * dead / total).toFixed(0)}%`);
}
console.log("\nÚltimos golpes y patrimonio por equipo cada 5 min:");
for (const t of times.filter((t) => t % 300 === 0)) {
  const agg = (team) => snaps[t].filter((s) => s.team === team).reduce((a, s) => ({ lh: a.lh + +s.lh, nw: a.nw + +s.nw, lvl: a.lvl + +s.lvl }), { lh: 0, nw: 0, lvl: 0 });
  const r = agg("2"), d = agg("3");
  console.log(`${String(t / 60).padStart(3)} min  R lh=${r.lh} nw=${r.nw} lvl=${r.lvl}  |  D lh=${d.lh} nw=${d.nw} lvl=${d.lvl}`);
}
const byTeam = (re) => { const c = { 2: 0, 3: 0 }; for (const l of lines) { const m = l.match(re); if (m && pidTeam[m[1]]) c[pidTeam[m[1]]]++; } return c; };
const count = (re) => lines.filter((l) => re.test(l)).length;
console.log("\nrunas", byTeam(/ rune pid=(\d+)/), "compras", byTeam(/ buy pid=(\d+)/), "casts", byTeam(/ cast pid=(\d+)/), "buyback", byTeam(/ buyback pid=(\d+)/));
console.log("wards", { 2: count(/ ward \S+ team=2/), 3: count(/ ward \S+ team=3/) }, "glyph", { 2: count(/glyph team=2/), 3: count(/glyph team=3/) });
const ct = Object.keys(couriers).map(Number).sort((a, b) => a - b);
if (ct.length) {
  console.log("\nCouriers (por equipo: vivos, a 1100, con objetos) cada 5 min:");
  for (const t of ct.filter((t) => t % 300 === 0)) {
    const s = (team) => { const cs = couriers[t].filter((c) => c.team === team); return `${cs.filter((c) => c.alive === "1").length}/${cs.length} vivos, ${cs.filter((c) => c.speed === "1100").length} a 1100, ${cs.filter((c) => c.items).length} con objetos`; };
    console.log(`${String(t / 60).padStart(3)} min  R ${s("2")}  |  D ${s("3")}`);
  }
  // Momentos sin ningún courier aliado vivo a 1100: ahí dota-bot cree que no es Turbo.
  for (const team of ["2", "3"]) {
    const off = ct.filter((t) => t >= 0 && !couriers[t].some((c) => c.team === team && c.alive === "1" && c.speed === "1100"));
    console.log(`${name[team]}: snapshots sin courier vivo a 1100: ${off.length} de ${ct.filter((t) => t >= 0).length}${off.length ? " (t=" + off.join(",") + ")" : ""}`);
  }
  console.log("muertes de courier", byTeam(/kill victim=npc_dota_courier vteam=\d vpid=(\d+)/));
}
// Modos de dota-bot ([bench] mode, cada 2 s por bot desde t>=30) según su ventaja de patrimonio (snapshot previo).
const leadAt = {};
for (const t of times) {
  const nw = (team) => snaps[t].filter((s) => s.team === team).reduce((a, s) => a + +s.nw, 0);
  if (botTeam !== "?") leadAt[t] = nw(botTeam) - nw(botTeam === "2" ? "3" : "2");
}
const buckets = { "atras<-3k": {}, "parejo": {}, "+3k..+6k": {}, ">=+6k": {} };
let modeLines = 0;
for (const l of lines) {
  const m = l.match(/\[bench\] mode t=(-?\d+) pid=\d+ \S+ (\S+) [\d.]+ alive=1/);
  if (!m || +m[1] < 30) continue;
  modeLines++;
  const snapT = times.filter((t) => t <= +m[1]).at(-1);
  const lead = leadAt[snapT] ?? 0;
  const b = lead < -3000 ? "atras<-3k" : lead < 3000 ? "parejo" : lead < 6000 ? "+3k..+6k" : ">=+6k";
  buckets[b][m[2]] = (buckets[b][m[2]] ?? 0) + 1;
}
if (modeLines) {
  console.log(`\nModos de dota-bot (vivo) por ventaja de patrimonio (${modeLines} muestras):`);
  for (const [b, c] of Object.entries(buckets)) {
    const n = Object.values(c).reduce((a, v) => a + v, 0);
    if (!n) continue;
    console.log(`  ${b.padEnd(10)} n=${String(n).padStart(4)}  ` + Object.entries(c).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k} ${(100 * v / n).toFixed(0)}%`).join(", "));
  }
}
// From minute 10, every 2 s: in how many lanes dota-bot's bots were pushing and how many in the busiest one.
const byT = {};
for (const l of lines) {
  const m = l.match(/\[bench\] mode t=(\d+) pid=(\d+) \S+ (\S+) [\d.]+ alive=(\d)/);
  if (!m || +m[1] < 600) continue;
  (byT[Math.floor(+m[1] / 2) * 2] ??= {})[m[2]] = m[4] === "1" ? m[3] : "DEAD";
}
const pushDist = {};
let pushN = 0;
for (const modes of Object.values(byT)) {
  const ms = Object.values(modes);
  if (ms.length < 5) continue;
  pushN++;
  const push = {};
  for (const m of ms) if (m.startsWith("PUSH")) push[m] = (push[m] ?? 0) + 1;
  const k = `${Object.keys(push).length} carril(es), ${Math.max(0, ...Object.values(push))} en el mayor`;
  pushDist[k] = (pushDist[k] ?? 0) + 1;
}
if (pushN) {
  console.log("\nEmpuje de dota-bot desde el minuto 10 (% del tiempo):");
  for (const [k, v] of Object.entries(pushDist).sort((a, b) => b[1] - a[1])) console.log(`  ${k.padEnd(28)} ${(100 * v / pushN).toFixed(0)}%`);
}
console.log("\nfinal:");
for (const s of snaps[times.at(-1)]) console.log(name[s.team], s.hero, "lvl", s.lvl, "nw", s.nw, "lh", s.lh, s.items);
const errs = {};
for (const l of lines) {
  const m = l.match(/(invalid order \(\d+\)\. [^.]*|Script Runtime Error: .*|obs error .*)/);
  if (m) errs[m[1]] = (errs[m[1]] ?? 0) + 1;
}
console.log("\nerrores:"); for (const [k, v] of Object.entries(errs).sort((a, b) => b[1] - a[1])) console.log(String(v).padStart(5), k);
