// Study of the 2 against 2 lanes (trabajo/plan-mejora-equipo.md; Pedro, 2026-11-13: «Estudiar a OHA y reescribir la línea de dos»).
// Descriptive: reads the fine lane record of the observer (tools/bench/addon, lines fino, frente, lanza, golpe, kill) and OHA's mode
// lines, and says how a lane of two is played: where each role stands, who opens a fight and with what, how the pair chains its
// abilities, how kills and deaths happen and when each hero goes home. It decides nothing by itself: its numbers are data for the
// rewrite of the lane layer, never a measurement of a package (that is tools/bench/equipo.mjs).
//
//   node tools/analisis/linea-dos.mjs <tag-regex> [--lado nuestro|rival|ambos] [--hasta 720] [--detalle]
//
// "nuestro" is the side of the `dotabot` column of bench/series.csv (variant a); "rival" the other team. Lanes: safe = that side's
// positions 1+5 against the other's 3+4; hard = its 3+4 against the other's 1+5 (positions in the group order of `heroes`).
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../..", import.meta.url));
const args = process.argv.slice(2);
const opt = { lado: "nuestro", hasta: 720, detalle: false };
const rest = [];
for (let i = 0; i < args.length; i++) {
  if (args[i] === "--lado") opt.lado = args[++i];
  else if (args[i] === "--hasta") opt.hasta = Number(args[++i]);
  else if (args[i] === "--detalle") opt.detalle = true;
  else rest.push(args[i]);
}
if (rest.length !== 1 || !["nuestro", "rival", "ambos"].includes(opt.lado)) {
  throw new Error("Uso: node tools/analisis/linea-dos.mjs <regex-etiqueta> [--lado nuestro|rival|ambos] [--hasta 720] [--detalle]");
}
const tagRe = new RegExp(`^(${rest[0]})$`);

const [header, ...rows] = readFileSync(join(root, "bench", "series.csv"), "utf8").trim().split(/\r?\n/);
const cols = header.split(",");
const matches = rows.map((r) => Object.fromEntries(r.split(",").map((v, i) => [cols[i], v])))
  .filter((r) => r.valida === "si" && tagRe.test(r.etiqueta));
const obsDir = join(root, "bench", "observaciones");
const obsFiles = new Set(readdirSync(obsDir));

// Items and actions that are not part of a fight's chain.
const NOT_COMBAT = /^(item_power_treads|courier_|item_quelling_blade|item_madstone|item_tpscroll|item_travel|ability_lamp_use|item_flask|item_clarity|item_enchanted_mango|item_faerie_fire|item_tango|item_ward|item_bottle|item_magic_stick|item_magic_wand|ability_capture|item_branches)/;
// A hero's name without the illusion (~) or summon (*) mark; creeps and towers are not heroes.
const bare = (n) => n.replace(/[~*]$/, "");
const byHero = (h) => h.att !== "creep" && h.att !== "torre";
const dist = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
const laneOf = (x, y) => (y - x > 3000 ? "top" : x - y > 3000 ? "bot" : "mid");
const median = (xs) => {
  if (!xs.length) return NaN;
  const s = [...xs].sort((a, b) => a - b);
  return s.length % 2 ? s[(s.length - 1) / 2] : (s[s.length / 2 - 1] + s[s.length / 2]) / 2;
};
const q = (xs, p) => {
  if (!xs.length) return NaN;
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.min(s.length - 1, Math.floor(p * s.length))];
};
const f1 = (x) => (Number.isFinite(x) ? x.toFixed(1) : "-");
const f0 = (x) => (Number.isFinite(x) ? String(Math.round(x)) : "-");
const pct = (a, b) => (b ? `${Math.round((100 * a) / b)} %` : "-");

function parse(file) {
  const fino = new Map(); // t -> hero -> state
  const front = []; // {t, team, top, mid, bot}
  const casts = [];
  const hits = [];
  const kills = [];
  const modes = [];
  for (const line of readFileSync(join(obsDir, file), "utf8").split(/\r?\n/)) {
    let m = line.match(/obs t=(-?\d+) (\w+) (.*)$/);
    if (m) {
      const t = Number(m[1]);
      const kind = m[2];
      const body = m[3];
      const kv = Object.fromEntries([...body.matchAll(/(\w+)=(\S+)/g)].map((x) => [x[1], x[2]]));
      if (kind === "fino") {
        const hero = body.split(" ")[2];
        if (!fino.has(t)) fino.set(t, new Map());
        fino.get(t).set(hero, { team: kv.team, alive: kv.alive === "1", x: +kv.x, y: +kv.y, hp: +kv.hp, maxhp: +kv.maxhp, mp: +kv.mp,
          obj: kv.obj, atk: kv.atk === "1", ctl: kv.ctl });
      } else if (kind === "frente") {
        const p = (s) => (s && s !== "-" ? { x: +s.split(",")[0], y: +s.split(",")[1] } : null);
        front.push({ t, team: kv.team, top: p(kv.top), mid: p(kv.mid), bot: p(kv.bot) });
      } else if (kind === "lanza") {
        const parts = body.split(" ");
        casts.push({ t, hero: parts[2], team: kv.team, ability: parts[3], x: +kv.x, y: +kv.y, obj: kv.obj, dist: kv.dist,
          aliados: +kv.aliados1200, rivales: +kv.rivales1200 });
      } else if (kind === "golpe") {
        for (const part of body.split(",")) {
          const g = part.match(/^([^>]+)>([^:]+):([^:]+):(\d+):(\d+)$/);
          if (g) hits.push({ t, att: g[1], vic: g[2], src: g[3], dmg: +g[4], n: +g[5] });
        }
      } else if (kind === "kill") {
        kills.push({ t, victim: kv.victim, killer: kv.killer, vteam: kv.vteam, kteam: kv.kteam });
      }
      continue;
    }
    m = line.match(/\[bench\] mode t=(-?\d+) pid=\d+ (\S+) (\S+) ([\d.]+)/);
    if (m) modes.push({ t: +m[1], hero: m[2], mode: m[3], desire: +m[4] });
  }
  return { fino, front, casts, hits, kills, modes };
}

const stateAt = (d, t, hero) => {
  for (let k = t; k >= t - 3; k--) {
    const s = d.fino.get(k)?.get(hero);
    if (s) return s;
  }
  return null;
};
const modeAt = (d, t, hero) => {
  let best = null;
  for (const m of d.modes) if (m.hero === hero && m.t <= t && m.t >= t - 3) best = m;
  return best ? best.mode : "?";
};
const frontAt = (d, t, team, lane) => {
  let best = null;
  for (const f of d.front) if (f.team === team && f.t <= t && f.t >= t - 3) best = f;
  return best ? best[lane] : null;
};

// One lane of one match: its fights, kills, deaths, positions and trips home.
function studyLane(d, ourTeam, ours, theirs, laneName) {
  const theirTeam = ourTeam === "2" ? "3" : "2";
  const lane = laneName === "segura" ? (ourTeam === "2" ? "bot" : "top") : (ourTeam === "2" ? "top" : "bot");
  const L = new Set([...ours, ...theirs]);
  const side = (h) => (ours.includes(bare(h)) ? "nos" : theirs.includes(bare(h)) ? "ellos" : "otro");
  const T = opt.hasta;

  // Fights: hero against hero damage touching a lane hero, gaps of at most 5 s.
  const hits = d.hits.filter((h) => byHero(h) && h.t >= 0 && h.t <= T && (L.has(bare(h.att)) || L.has(bare(h.vic))));
  const fights = [];
  for (const h of hits) {
    const last = fights[fights.length - 1];
    if (last && h.t - last.end <= 5) { last.end = h.t; last.hits.push(h); } else fights.push({ start: h.t, end: h.t, hits: [h] });
  }
  for (const f of fights) {
    const first = f.hits[0];
    // The first damage of a second is not ordered inside it: when both sides hit in the first second, "ambos".
    const firstSec = f.hits.filter((h) => h.t === f.start);
    const openers = new Set(firstSec.map((h) => side(h.att)));
    f.abre = openers.size > 1 ? "ambos" : side(first.att);
    f.abreCon = firstSec.filter((h) => side(h.att) === f.abre || f.abre === "ambos").map((h) => `${h.att}:${h.src === "ataque" ? "ataque" : h.src}`).join("+");
    f.dmgNos = f.hits.filter((h) => side(h.att) === "nos").reduce((a, h) => a + h.dmg, 0);
    f.dmgEllos = f.hits.filter((h) => side(h.att) === "ellos").reduce((a, h) => a + h.dmg, 0);
    f.nosPegan = new Set(f.hits.filter((h) => side(h.att) === "nos").map((h) => bare(h.att)));
    f.ellosPegan = new Set(f.hits.filter((h) => side(h.att) === "ellos").map((h) => bare(h.att)));
    f.otros = new Set(f.hits.filter((h) => side(h.att) === "otro").map((h) => bare(h.att)));
    f.casts = d.casts.filter((c) => c.t >= f.start - 1 && c.t <= f.end && L.has(c.hero) && !NOT_COMBAT.test(c.ability));
    f.killsNos = d.kills.filter((k) => k.t >= f.start && k.t <= f.end + 3 && theirs.includes(k.victim));
    f.muertesNos = d.kills.filter((k) => k.t >= f.start && k.t <= f.end + 3 && ours.includes(k.victim));
    f.hp = Object.fromEntries([...ours, ...theirs].map((h) => {
      const s = stateAt(d, f.start - 1, h);
      return [h, s && s.alive ? s.hp / s.maxhp : null];
    }));
    f.modes = Object.fromEntries(ours.map((h) => [h, modeAt(d, f.start, h)]));
    const a = stateAt(d, f.start, ours[0]);
    const b = stateAt(d, f.start, ours[1]);
    f.pareja = a && b && a.alive && b.alive ? dist(a, b) : NaN;
    // Chain: the first combat cast of each of our two heroes; the gap only when both cast.
    const firstCast = Object.fromEntries(ours.map((h) => [h, f.casts.find((c) => c.hero === h)]));
    f.cadena = ours.every((h) => firstCast[h]) ? Math.abs(firstCast[ours[0]].t - firstCast[ours[1]].t) : null;
    f.dur = f.end - f.start + 1;
    f.tipo = f.killsNos.length && !f.muertesNos.length ? "kill" : !f.killsNos.length && f.muertesNos.length ? "muerte"
      : f.killsNos.length && f.muertesNos.length ? "cambio" : "nada";
  }

  // Deaths of our lane heroes: the 10 s before.
  const deaths = d.kills.filter((k) => k.t >= 0 && k.t <= T && ours.includes(k.victim)).map((k) => {
    const before = stateAt(d, k.t - 10, k.victim);
    const at = stateAt(d, k.t - 1, k.victim);
    const enemiesNear = at ? [...(d.fino.get(k.t - 1) ?? new Map())].filter(([h, s]) => s.team === theirTeam && s.alive && dist(s, at) <= 1200).length : NaN;
    const allyNear = at ? [...(d.fino.get(k.t - 1) ?? new Map())].filter(([h, s]) => s.team === ourTeam && h !== k.victim && s.alive && dist(s, at) <= 1200).length : NaN;
    const dmgFrom = {};
    for (const h of d.hits) if (bare(h.vic) === k.victim && h.t >= k.t - 8 && h.t <= k.t) dmgFrom[h.att] = (dmgFrom[h.att] ?? 0) + h.dmg;
    // Did the victim hit an enemy hero in the 6 s before the damage began?
    const firstDmg = d.hits.filter((h) => bare(h.vic) === k.victim && h.t >= k.t - 8 && h.t <= k.t).map((h) => h.t)[0] ?? k.t;
    const atacoAntes = d.hits.some((h) => bare(h.att) === k.victim && h.t >= firstDmg - 6 && h.t <= firstDmg);
    return { t: k.t, hero: k.victim, killer: k.killer, hp10: before && before.alive ? before.hp / before.maxhp : NaN,
      enemigos: enemiesNear, aliados: allyNear, de: dmgFrom, modo: modeAt(d, k.t - 2, k.victim), atacoAntes };
  });
  const killsOf = d.kills.filter((k) => k.t >= 0 && k.t <= T && theirs.includes(k.victim)).map((k) => {
    const dmgFrom = {};
    for (const h of d.hits) if (bare(h.vic) === k.victim && h.t >= k.t - 8 && h.t <= k.t) dmgFrom[h.att] = (dmgFrom[h.att] ?? 0) + h.dmg;
    return { t: k.t, hero: k.victim, killer: k.killer, de: dmgFrom };
  });

  // Positions, per our hero, each second alive in its lane between t=60 and T.
  const pos = {};
  for (const h of ours) pos[h] = { enLinea: 0, vivo: 0, dFrente: [], dRival: [], dPareja: [], delante: [], base: [] };
  for (let t = 60; t <= T; t++) {
    const snap = d.fino.get(t);
    if (!snap) continue;
    const ownF = frontAt(d, t, ourTeam, lane);
    const foeF = frontAt(d, t, theirTeam, lane);
    for (const h of ours) {
      const s = snap.get(h);
      if (!s || !s.alive) continue;
      pos[h].vivo++;
      if (laneOf(s.x, s.y) !== lane) continue;
      pos[h].enLinea++;
      if (ownF) pos[h].dFrente.push(dist(s, ownF));
      // Ahead of the own wave (positive) or behind it: projection on the line from our front to theirs.
      if (ownF && foeF && dist(ownF, foeF) > 50) {
        const ux = (foeF.x - ownF.x) / dist(ownF, foeF), uy = (foeF.y - ownF.y) / dist(ownF, foeF);
        pos[h].delante.push((s.x - ownF.x) * ux + (s.y - ownF.y) * uy);
      }
      const foes = [...snap].filter(([n, o]) => o.team === theirTeam && o.alive && theirs.includes(n));
      if (foes.length) pos[h].dRival.push(Math.min(...foes.map(([, o]) => dist(o, s))));
      const mate = snap.get(ours.find((o) => o !== h));
      if (mate && mate.alive) pos[h].dPareja.push(dist(mate, s));
    }
  }
  // Trips home: alive, leaves the lane and reaches within 2000 of its fountain corner; health when it left the lane.
  const fountain = ourTeam === "2" ? { x: -7000, y: -6500 } : { x: 7000, y: 6400 };
  const trips = [];
  for (const h of ours) {
    let inLaneHp = null, home = false;
    for (let t = 30; t <= T; t++) {
      const s = d.fino.get(t)?.get(h);
      if (!s) continue;
      if (!s.alive) { inLaneHp = null; home = true; continue; } // dead: respawns home, not a trip
      if (laneOf(s.x, s.y) === lane && dist(s, fountain) > 4000) { inLaneHp = s.hp / s.maxhp; home = false; continue; }
      if (!home && inLaneHp !== null && dist(s, fountain) <= 2000) {
        const tp = d.casts.some((c) => c.hero === h && /tpscroll|travel/.test(c.ability) && c.t >= t - 15 && c.t <= t);
        trips.push({ t, hero: h, hp: inLaneHp, tp });
        home = true;
      }
    }
  }
  // Casts of our lane heroes in the window, by ability and target kind.
  const castsBy = {};
  for (const c of d.casts) {
    if (!ours.includes(c.hero) || c.t < 0 || c.t > T || NOT_COMBAT.test(c.ability)) continue;
    const k = `${c.hero} ${c.ability}`;
    castsBy[k] = castsBy[k] ?? { n: 0, heroe: 0, creep: 0, otro: 0, sinRival: 0 };
    castsBy[k].n++;
    const kind = c.obj === "-" ? "otro" : c.obj === "creep" ? "creep" : c.obj === "torre" ? "otro" : "heroe";
    castsBy[k][kind]++;
    if (c.rivales === 0) castsBy[k].sinRival++;
  }
  return { fights, deaths, kills: killsOf, pos, trips, castsBy };
}

// ---- run over the matches ----
const lanes = { segura: [], dificil: [] };
const skipped = [];
for (const m of matches) {
  const file = `${m.etiqueta}-${String(m.fecha).replace(/[-:T]/g, "")}-${m.partida}.log`;
  if (!obsFiles.has(file)) { skipped.push(`${file}: sin registro`); continue; }
  const d = parse(file);
  if (d.fino.size === 0) { skipped.push(`${file}: sin líneas fino`); continue; }
  const [radiant, dire] = m.heroes.split(" / ").map((g) => g.trim().split(/\s+/));
  const sides = opt.lado === "ambos" ? ["nuestro", "rival"] : [opt.lado];
  for (const lado of sides) {
    const usRadiant = (m.dotabot === "radiant") === (lado === "nuestro");
    const ourTeam = usRadiant ? "2" : "3";
    const us = usRadiant ? radiant : dire;
    const them = usRadiant ? dire : radiant;
    const tag = `${m.etiqueta}#${m.partida}${lado === "rival" ? "r" : ""}`;
    lanes.segura.push({ tag, ours: [us[0], us[4]], theirs: [them[2], them[3]], ...studyLane(d, ourTeam, [us[0], us[4]], [them[2], them[3]], "segura") });
    lanes.dificil.push({ tag, ours: [us[2], us[3]], theirs: [them[0], them[4]], ...studyLane(d, ourTeam, [us[2], us[3]], [them[0], them[4]], "dificil") });
  }
}

console.log(`linea-dos · ${matches.length} partidas válidas con «${rest[0]}», lado ${opt.lado}, hasta t=${opt.hasta}`);
for (const s of skipped) console.log(`  fuera: ${s}`);

for (const [name, list] of Object.entries(lanes)) {
  if (!list.length) continue;
  const heroes = [...new Set(list.flatMap((l) => l.ours))];
  console.log(`\n=== Línea ${name} (${list.length} líneas; nuestros: ${[...new Set(list.map((l) => l.ours.join("+")))].join(", ")}) ===`);
  const fights = list.flatMap((l) => l.fights.map((f) => ({ ...f, tag: l.tag, ours: l.ours })));
  const real = fights.filter((f) => f.dmgNos + f.dmgEllos >= 150 || f.tipo !== "nada");
  const n = list.length;
  console.log(`Peleas (daño ≥150 o con muerte): ${real.length} (${f1(real.length / n)} por línea); de ellas con kill nuestra ${real.filter((f) => f.tipo === "kill").length}, con muerte nuestra ${real.filter((f) => f.tipo === "muerte").length}, cambio ${real.filter((f) => f.tipo === "cambio").length}`);
  for (const who of ["nos", "ellos", "ambos", "otro"]) {
    const g = real.filter((f) => f.abre === who);
    if (!g.length) continue;
    console.log(`  abre ${who.padEnd(5)} ${String(g.length).padStart(3)}: kill ${g.filter((f) => f.tipo === "kill").length}, muerte ${g.filter((f) => f.tipo === "muerte").length}, cambio ${g.filter((f) => f.tipo === "cambio").length}; daño hecho/recibido mediana ${f0(median(g.map((f) => f.dmgNos)))}/${f0(median(g.map((f) => f.dmgEllos)))}; con habilidad al abrir ${pct(g.filter((f) => !/:ataque/.test(f.abreCon) || f.abreCon.split("+").some((x) => !x.endsWith(":ataque"))).length, g.length)}`);
  }
  const both = real.filter((f) => f.nosPegan.size === 2);
  console.log(`  pegan los dos nuestros: ${pct(both.length, real.length)} de las peleas; en las de kill: ${pct(real.filter((f) => f.tipo === "kill" && f.nosPegan.size === 2).length, real.filter((f) => f.tipo === "kill").length)}`);
  const kf = real.filter((f) => f.tipo === "kill" || f.tipo === "cambio");
  if (kf.length) {
    console.log(`  peleas con kill nuestra: duración mediana ${f1(median(kf.map((f) => f.dur)))} s, distancia de la pareja al empezar ${f0(median(kf.map((f) => f.pareja).filter(Number.isFinite)))}, cadena (s entre la 1.ª habilidad de cada uno) ${f1(median(kf.map((f) => f.cadena).filter((x) => x !== null)))} (con los dos lanzando: ${kf.filter((f) => f.cadena !== null).length} de ${kf.length}), ayuda de fuera ${kf.filter((f) => f.otros.size).length}`);
    const hpUs = kf.flatMap((f) => f.ours.map((h) => f.hp[h]).filter((x) => x !== null));
    const hpThem = kf.flatMap((f) => Object.entries(f.hp).filter(([h]) => !f.ours.includes(h)).map(([, v]) => v).filter((x) => x !== null));
    console.log(`  vida al empezar (mediana): nuestros ${f1(100 * median(hpUs))} %, rivales ${f1(100 * median(hpThem))} %`);
    const modeCount = {};
    for (const f of kf) for (const h of f.ours) modeCount[f.modes[h]] = (modeCount[f.modes[h]] ?? 0) + 1;
    console.log(`  modo de OHA al empezar (nuestros): ${Object.entries(modeCount).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k} ${v}`).join(", ")}`);
    const seq = {};
    for (const f of kf) {
      const s = f.casts.filter((c) => f.ours.includes(c.hero)).slice(0, 4).map((c) => `${c.hero.slice(0, 4)}:${c.ability.replace(/^[a-z_]+?_(?=[a-z]+$)/, "")}`).join(" > ") || "(solo ataques)";
      seq[s] = (seq[s] ?? 0) + 1;
    }
    console.log("  secuencias de habilidades en las peleas con kill (las 6 más comunes):");
    for (const [s, c] of Object.entries(seq).sort((a, b) => b[1] - a[1]).slice(0, 6)) console.log(`    ${c} × ${s}`);
  }
  const deaths = list.flatMap((l) => l.deaths);
  console.log(`Muertes nuestras: ${deaths.length} (${f1(deaths.length / n)} por línea); kills sobre sus rivales: ${list.flatMap((l) => l.kills).length} (${f1(list.flatMap((l) => l.kills).length / n)})`);
  if (deaths.length) {
    console.log(`  vida 10 s antes (mediana) ${f1(100 * median(deaths.map((x) => x.hp10).filter(Number.isFinite)))} %; rivales a 1200 ${f1(median(deaths.map((x) => x.enemigos).filter(Number.isFinite)))}, aliados a 1200 ${f1(median(deaths.map((x) => x.aliados).filter(Number.isFinite)))}; había pegado a un héroe justo antes: ${pct(deaths.filter((x) => x.atacoAntes).length, deaths.length)}`);
    const dm = {};
    for (const x of deaths) dm[x.modo] = (dm[x.modo] ?? 0) + 1;
    console.log(`  modo 2 s antes: ${Object.entries(dm).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k} ${v}`).join(", ")}`);
  }
  console.log("Posición (segundos vivos en su línea, t=60 a hasta): mediana [p25-p75]");
  for (const h of heroes) {
    const ps = list.filter((l) => l.ours.includes(h)).map((l) => l.pos[h]);
    const all = (k) => ps.flatMap((p) => p[k]);
    const vivo = ps.reduce((a, p) => a + p.vivo, 0), en = ps.reduce((a, p) => a + p.enLinea, 0);
    console.log(`  ${h.padEnd(16)} en línea ${pct(en, vivo)} del tiempo vivo · a su frente ${f0(median(all("dFrente")))} [${f0(q(all("dFrente"), 0.25))}-${f0(q(all("dFrente"), 0.75))}] · delante de su ola ${f0(median(all("delante")))} [${f0(q(all("delante"), 0.25))}-${f0(q(all("delante"), 0.75))}] · al rival más cerca ${f0(median(all("dRival")))} [${f0(q(all("dRival"), 0.25))}-${f0(q(all("dRival"), 0.75))}] · a su pareja ${f0(median(all("dPareja")))}`);
  }
  const trips = list.flatMap((l) => l.trips);
  console.log(`Viajes a la base vivos: ${trips.length} (${f1(trips.length / n)} por línea); vida al dejar la línea (mediana) ${f1(100 * median(trips.map((x) => x.hp)))} %; con TP ${trips.filter((x) => x.tp).length}`);
  const cb = {};
  for (const l of list) for (const [k, v] of Object.entries(l.castsBy)) {
    cb[k] = cb[k] ?? { n: 0, heroe: 0, creep: 0, otro: 0, sinRival: 0 };
    for (const f of Object.keys(v)) cb[k][f] += v[f];
  }
  console.log("Lanzamientos por línea (a héroe / a creep / otro / sin rival a 1200):");
  for (const [k, v] of Object.entries(cb).sort((a, b) => b[1].n - a[1].n).slice(0, 14)) {
    console.log(`  ${k.padEnd(48)} ${f1(v.n / n)}  (${v.heroe}/${v.creep}/${v.otro}/${v.sinRival})`);
  }
  if (opt.detalle) {
    console.log("Detalle de peleas:");
    for (const f of real) {
      console.log(`  ${f.tag} t=${f.start}-${f.end} ${f.tipo} abre=${f.abre} [${f.abreCon}] daño ${f.dmgNos}/${f.dmgEllos} vida ${Object.entries(f.hp).map(([h, v]) => `${h.slice(0, 4)}:${v === null ? "x" : Math.round(100 * v)}`).join(" ")} modos ${Object.values(f.modes).join("/")} cadena=${f.cadena ?? "-"} lanza: ${f.casts.map((c) => `${c.t}:${c.hero.slice(0, 4)}:${c.ability}>${c.obj}`).join(" ")}`);
    }
  }
}
