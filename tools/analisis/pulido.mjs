// dota-bot: the own Sniper against the bar of "polished" (DECISIONES 2026-11-06), from smokes with --rival dotabot --corte 25,
// against OHA's Sniper with the same kind of rival. Each label is one set of matches; several are added up. Different draws per
// run: descriptive, it decides no series. A window is 10 s; damage from minute 12 on; harassment up to minute 10.
//   node tools/analisis/pulido.mjs --referencia presion-oha <etiqueta> [<etiqueta>...]
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const args = process.argv.slice(2);
const at = args.indexOf("--referencia");
const ref = at >= 0 ? args.splice(at, 2)[1] : "presion-oha";
if (!args.length) { console.log("Uso: node tools/analisis/pulido.mjs [--referencia presion-oha] <etiqueta> [<etiqueta>...]"); process.exit(1); }
const dir = join(root, "bench", "observaciones");
const csv = readFileSync(join(root, "bench", "series.csv"), "utf8").split(/\r?\n/);
const head = csv[0].split(",");
const rows = csv.slice(1).filter(Boolean).map((l) => Object.fromEntries(l.split(",").map((v, i) => [head[i], v])));
const kv = (line) => Object.fromEntries([...line.matchAll(/(\w+)=(\S+)/g)].map((m) => [m[1], m[2]]));
const GLOBAL = new Set(["zuus_thundergods_wrath"]);
const mean = (xs) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : NaN);

function measure(tags) {
  const games = [];
  for (const tag of tags) {
    const last = new Map();
    for (const r of rows.filter((x) => x.etiqueta === tag && x.valida === "si")) last.set(r.partida, r);
    for (const r of last.values()) {
      let L;
      try { L = readFileSync(join(dir, `${tag}-${r.fecha.replace(/[-:T]/g, "")}-${r.partida}.log`), "latin1").split(/\r?\n/); } catch { continue; }
      const lane = L.filter((l) => l.includes("[bench] linea ")).map(kv);
      const at25 = lane.find((x) => +x.t >= 1500);
      if (!at25) continue; // the match ended before minute 25
      const own = lane[0].pid;
      const rival = L.filter((l) => / obs t=\d+ linea pid=/.test(l)).map((l) => l.match(/linea pid=(\d+)/)[1]).find((p) => p !== own);
      let hurt = 0, noAnswer = 0, active = 0, dealt = 0;
      for (const l of L) {
        const d = l.match(/obs t=(\d+) dano (\S+)/);
        if (!d) continue;
        const t = +d[1];
        if (t > 1500) continue;
        let out = 0, inn = 0;
        for (const it of d[2].split(",")) {
          const m = it.match(/^(.+)>(.+):(.+):(\d+):(\d+)$/);
          if (!m) continue;
          if (m[1] === "sniper") out += +m[4];
          else if (m[2] === "sniper" && m[1] !== "creep" && m[1] !== "torre" && !GLOBAL.has(m[3])) inn += +m[4];
        }
        if (t <= 600 && inn >= 50) { hurt += 1; if (out === 0) noAnswer += 1; }
        if (t >= 720 && out > 0) { active += 1; dealt += out; }
      }
      const rivalLine = rival === undefined ? "" : L.find((l) => new RegExp(`obs t=600 hero pid=${rival} `).test(l));
      games.push({ lh: +at25.lh, m: +at25.muertes, k: +at25.kills, nw: +at25.nw, oro: +at25.oro, dealt, active, hurt, noAnswer,
        rivalLh: rivalLine ? +rivalLine.match(/ lh=(\d+)/)[1] : NaN });
    }
  }
  return games;
}

const summary = (g) => ({ n: g.length, lh: mean(g.map((x) => x.lh)), m: mean(g.map((x) => x.m)), k: mean(g.map((x) => x.k)), nw: mean(g.map((x) => x.nw)),
  dano: mean(g.map((x) => x.dealt)), ventanas: 100 * g.reduce((a, x) => a + x.active, 0) / (78 * Math.max(g.length, 1)),
  sin: 100 * g.reduce((a, x) => a + x.noAnswer, 0) / Math.max(g.reduce((a, x) => a + x.hurt, 0), 1), acosos: g.reduce((a, x) => a + x.hurt, 0),
  rival: mean(g.map((x) => x.rivalLh).filter(Number.isFinite)), oro: mean(g.map((x) => x.oro)) });
const a = summary(measure(args));
const b = summary(measure([ref]));
const f = (x, d = 1) => x.toFixed(d);
const row = (name, own, oha, ok, d = 1) => console.log(`${ok ? "cumple   " : "NO cumple"} ${name.padEnd(30)} ${f(own, d).padStart(9)} frente a ${f(oha, d).padStart(9)}`);
console.log(`Propio: ${args.join("+")}, n=${a.n}. OHA: ${ref}, n=${b.n}. Partidas acabadas antes del min 25, fuera.`);
row("LH min 25 (>= 95 %)", a.lh, b.lh, a.lh >= 0.95 * b.lh);
row("Patrimonio min 25 (>= 95 %)", a.nw, b.nw, a.nw >= 0.95 * b.nw, 0);
row("Kills min 25 (>= 85 %)", a.k, b.k, a.k >= 0.85 * b.k);
row("Daño a héroes (>= 85 %)", a.dano, b.dano, a.dano >= 0.85 * b.dano, 0);
row("Muertes min 25 (<= OHA)", a.m, b.m, a.m <= b.m);
row(`Sin devolver, ${a.acosos} acosos (<= 17 %)`, a.sin, b.sin, a.sin <= 17);
row("LH del rival, min 10 (<= OHA)", a.rival, b.rival, a.rival <= b.rival);
console.log(`Informativo: ventanas con daño ${f(a.ventanas)} % frente a ${f(b.ventanas)} %; oro sin gastar ${f(a.oro, 0)} frente a ${f(b.oro, 0)}.`);
