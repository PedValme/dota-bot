// dota-bot: what Pedro saw playing against the own Sniper (2026-11-05), read from the logs of a series, per arm, up to
// minute 10: does it answer when hit, do its last hits fall under harassment, does it push the rival back. Sources: the
// custom game's "obs dano" (every 10 s), "obs creepkill", "obs hero" (every 30 s). Descriptive; the rival is a Valve bot,
// not a human. Windows of 10 s; "under harassment" means the hero took 50 or more from enemy heroes in that window.
//   node tools/analisis/conducta-linea.mjs <etiqueta> [<etiqueta>...]
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const tags = process.argv.slice(2);
if (!tags.length) { console.log("Uso: node tools/analisis/conducta-linea.mjs <etiqueta> [<etiqueta>...]"); process.exit(1); }
const dir = join(root, "bench", "observaciones");
const csv = readFileSync(join(root, "bench", "series.csv"), "utf8").split(/\r?\n/);
const head = csv[0].split(",");
const rows = csv.slice(1).filter(Boolean).map((l) => Object.fromEntries(l.split(",").map((v, i) => [head[i], v])));
const HARASS = 50;
const END = 600;
// Damage from anywhere on the map is not harassment: there is nobody to answer (fase1i, 3 of 9 windows with no answer).
const GLOBAL = new Set(["zuus_thundergods_wrath"]);
const mean = (xs) => xs.reduce((a, b) => a + b, 0) / Math.max(xs.length, 1);

const arms = new Map();
for (const tag of tags) {
  const last = new Map();
  for (const r of rows.filter((x) => x.etiqueta === tag && x.valida === "si")) last.set(r.partida, r);
  for (const r of last.values()) {
    let lines;
    try { lines = readFileSync(join(dir, `${tag}-${r.fecha.replace(/[-:T]/g, "")}-${r.partida}.log`), "latin1").split(/\r?\n/); } catch { continue; }
    const hero = "sniper";
    const t = (l) => Number(l.match(/obs t=(-?\d+)/)?.[1]);
    const own = lines.find((l) => l.includes("[bench] linea "))?.match(/pid=(\d+)/)?.[1];
    if (own === undefined) continue;
    // The rival: the other "obs linea" pid.
    const rival = lines.filter((l) => / obs t=\d+ linea pid=/.test(l)).map((l) => l.match(/linea pid=(\d+)/)[1]).find((p) => p !== own);
    const windows = new Map(); // window start -> { dealt, taken, lh, near }
    const w = (at) => {
      const k = Math.floor((at - 1) / 10) * 10;
      if (!windows.has(k)) windows.set(k, { dealt: 0, taken: 0, lh: 0, creeps: 0 });
      return windows.get(k);
    };
    for (const l of lines) {
      const at = t(l);
      if (!Number.isFinite(at) || at < 0 || at > END) continue;
      const d = l.match(/obs t=\d+ dano (\S+)/);
      if (d) {
        for (const item of d[1].split(",")) {
          const m = item.match(/^(.+)>(.+):(.+):(\d+):(\d+)$/);
          if (!m) continue;
          if (m[1] === hero) w(at).dealt += Number(m[4]);
          // Only enemy heroes: creeps and towers are the lane's price, not harassment.
          else if (m[2] === hero && m[1] !== "creep" && m[1] !== "torre" && !GLOBAL.has(m[3])) w(at).taken += Number(m[4]);
        }
      }
      if (l.includes(" creepkill ")) {
        const row = w(at);
        row.creeps += 1;
        if (l.includes(`kpid=${own} `)) row.lh += 1;
      }
    }
    const list = [...windows.values()];
    const hit = list.filter((x) => x.taken >= HARASS);
    const calm = list.filter((x) => x.taken < HARASS);
    const shot = (p) => lines.filter((l) => new RegExp(`obs t=600 hero pid=${p} `).test(l)).map((l) => ({
      lh: Number(l.match(/ lh=(\d+)/)?.[1]), dn: Number(l.match(/ dn=(\d+)/)?.[1]), d: Number(l.match(/ d=(\d+)/)?.[1]) }))[0];
    const rivalAt10 = rival !== undefined ? shot(rival) : undefined;
    const arm = arms.get(r.variante) ?? [];
    arms.set(r.variante, arm);
    arm.push({
      dealt: list.reduce((a, x) => a + x.dealt, 0), taken: list.reduce((a, x) => a + x.taken, 0),
      hitWindows: hit.length, windows: list.length,
      noAnswer: hit.filter((x) => x.dealt === 0).length,
      lhHit: hit.reduce((a, x) => a + x.lh, 0), creepsHit: hit.reduce((a, x) => a + x.creeps, 0),
      lhCalm: calm.reduce((a, x) => a + x.lh, 0), creepsCalm: calm.reduce((a, x) => a + x.creeps, 0),
      rivalLh: rivalAt10?.lh, rivalDn: rivalAt10?.dn, rivalD: rivalAt10?.d,
    });
  }
}
for (const [name, g] of arms) {
  const sum = (f) => g.reduce((a, x) => a + (x[f] ?? 0), 0);
  const known = g.filter((x) => x.rivalLh !== undefined);
  console.log(`${name}: n=${g.length}`);
  console.log(`  daño a héroes ${mean(g.map((x) => x.dealt)).toFixed(0)} · recibido de héroes ${mean(g.map((x) => x.taken)).toFixed(0)} · razón ${(sum("dealt") / Math.max(sum("taken"), 1)).toFixed(2)}`);
  console.log(`  ventanas de 10 s acosado: ${sum("hitWindows")} de ${sum("windows")} (${(100 * sum("hitWindows") / Math.max(sum("windows"), 1)).toFixed(0)} %) · sin devolver nada: ${sum("noAnswer")} (${(100 * sum("noAnswer") / Math.max(sum("hitWindows"), 1)).toFixed(0)} %)`);
  console.log(`  últimos golpes por ventana: acosado ${(sum("lhHit") / Math.max(sum("hitWindows"), 1)).toFixed(2)} · tranquilo ${(sum("lhCalm") / Math.max(sum("windows") - sum("hitWindows"), 1)).toFixed(2)}`);
  console.log(`  parte de los creeps cercanos que remata: acosado ${(100 * sum("lhHit") / Math.max(sum("creepsHit"), 1)).toFixed(0)} % · tranquilo ${(100 * sum("lhCalm") / Math.max(sum("creepsCalm"), 1)).toFixed(0)} %`);
  console.log(`  rival de mid en el min 10 (n=${known.length}): LH ${mean(known.map((x) => x.rivalLh)).toFixed(1)} · DN ${mean(known.map((x) => x.rivalDn)).toFixed(1)} · muertes ${mean(known.map((x) => x.rivalD)).toFixed(2)}`);
}
