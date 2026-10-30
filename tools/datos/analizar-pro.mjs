// Aggregate team-strategy metrics from cached OpenDota pro matches (see opendota.mjs).
// Output holds only aggregates: no player names, no account ids.
// Usage: node tools/datos/analizar-pro.mjs [--cache <dir>] [--out <file.md>]
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf('--' + k); return i >= 0 ? args[i + 1] : d; };
const SP = path.join(os.tmpdir(), 'dota-bot-datos');
const CACHE = opt('cache', path.join(SP, 'pro'));
const OUT = opt('out', path.join(SP, 'metricas-pro.md'));

const rd = f => JSON.parse(fs.readFileSync(path.join(CACHE, f)));
const heroes = Object.fromEntries(rd('heroes.json').map(h => [h.id, h]));
const abil = rd('abilities.json');
const items = rd('items.json');
const heroAb = rd('hero_abilities.json');

let all = fs.readdirSync(CACHE).filter(f => /^m\d+\.json$/.test(f)).map(f => rd(f));
const patches = {}, modes = {};
for (const m of all) { patches[m.patch] = (patches[m.patch] || 0) + 1; modes[m.game_mode] = (modes[m.game_mode] || 0) + 1; }
const maxPatch = Math.max(...all.map(m => m.patch ?? 0));
const matches = all.filter(m => m.patch === maxPatch && m.game_mode === 2 && m.teamfights && m.radiant_gold_adv?.length > 10);

// ---------- helpers ----------
const q = (a, p) => { if (!a.length) return NaN; const s = [...a].sort((x, y) => x - y); const i = (s.length - 1) * p; const lo = Math.floor(i), hi = Math.ceil(i); return s[lo] + (s[hi] - s[lo]) * (i - lo); };
const f1 = x => Number.isNaN(x) ? '-' : (Math.abs(x) >= 100 ? Math.round(x).toString() : x.toFixed(1));
const stat = a => `n=${a.length} · med ${f1(q(a, .5))} · p25 ${f1(q(a, .25))} · p75 ${f1(q(a, .75))}`;
const pct = (a, n) => n ? `${(100 * a / n).toFixed(0)}% (${a}/${n})` : '- (0/0)';
const out = [];
const P = s => out.push(s);
const row = (name, a) => P(`| ${name} | ${a.length} | ${f1(q(a, .5))} | ${f1(q(a, .25))} | ${f1(q(a, .75))} |`);
const head = () => { P('| Métrica | n | mediana | p25 | p75 |'); P('|---|---|---|---|---|'); };

// sign: +1 radiant perspective, -1 dire
const side = isR => isR ? 2 : 3;
const advAt = (m, t, isR) => { const a = m.radiant_gold_adv; const i = Math.min(a.length - 1, Math.max(0, Math.round(t / 60))); return (isR ? 1 : -1) * a[i]; };

// ultimates: ability with 3 levels (cd array of length 3) among a hero's non-innate abilities; fallback last active ability
const ultSet = new Set();
for (const [hn, h] of Object.entries(heroAb)) {
  const cand = (h.abilities || []).filter(n => abil[n] && !abil[n].is_innate && !/^special_bonus|generic_hidden/.test(n));
  let u = cand.filter(n => Array.isArray(abil[n].cd) && abil[n].cd.length === 3);
  if (!u.length) { const act = cand.filter(n => abil[n].behavior && !String(abil[n].behavior).includes('Passive')); if (act.length) u = [act[act.length - 1]]; }
  u.forEach(n => ultSet.add(n));
}

// per-match derived data
for (const m of matches) {
  m.dur = m.duration / 60;
  m.towers = []; m.rax = []; m.rosh = [];
  for (const o of m.objectives) {
    if (o.type === 'building_kill' && /npc_dota_(good|bad)guys_/.test(o.key || '')) {
      const victimR = o.key.includes('goodguys');
      const mt = o.key.match(/tower(\d)/);
      if (mt) m.towers.push({ t: o.time, tier: +mt[1], victimR, byHero: o.slot != null });
      else if (/rax/.test(o.key)) m.rax.push({ t: o.time, victimR });
    } else if (o.type === 'CHAT_MESSAGE_ROSHAN_KILL') m.rosh.push({ t: o.time, killerR: o.team === 2 });
  }
  m.towers.sort((a, b) => a.t - b.t); m.rax.sort((a, b) => a.t - b.t); m.rosh.sort((a, b) => a.t - b.t);
  // teamfights with team aggregates; tf.players aligned with m.players
  m.tf = m.teamfights.map(tf => {
    const r = { start: tf.start, end: tf.end, dR: 0, dD: 0, gR: 0, gD: 0, bb: 0, ults: { R: [], D: [] }, raw: tf };
    tf.players.forEach((p, i) => {
      const isR = m.players[i].isRadiant;
      if (isR) { r.dR += p.deaths; r.gR += p.gold_delta; } else { r.dD += p.deaths; r.gD += p.gold_delta; }
      r.bb += p.buybacks || 0;
    });
    r.gdR = r.gR; r.gdD = r.gD; // team gold_delta
    return r;
  }).filter(t => t.raw.players.length === m.players.length);
  // kill events
  m.kills = [];
  for (const p of m.players) for (const k of p.kills_log || []) {
    if (!/^npc_dota_hero_/.test(k.key)) continue;
    const v = m.players.find(x => heroes[x.hero_id]?.name === k.key);
    if (v) m.kills.push({ t: k.time, victimR: v.isRadiant });
  }
  m.kills.sort((a, b) => a.t - b.t);
}
const winR = m => m.radiant_win;

P('# Métricas de partidas profesionales (OpenDota)');
P('');
P(`Fuente: API pública de OpenDota, ${all.length} partidas en caché; análisis sobre ${matches.length} del parche ${maxPatch} (el más reciente en la caché), game_mode 2 (Captain's Mode, modo normal, NO Turbo). Parches en caché: ${JSON.stringify(patches)}.`);
P('Tiempos en minutos de juego (reloj de la partida, 0 = cuernos). Todo agregado: sin nombres ni IDs de cuenta. Partidas de torneo de nivel profesional; los equipos son de élite, el ritmo de bots y de públicos no tiene por qué parecerse.');
P('');
P('**Aviso general:** es modo normal. En Turbo (oro y XP x2 aprox., torres débiles, couriers, Roshan más pronto) los tiempos son aproximadamente la mitad, SIN verificar. Usar porcentajes y ventajas de oro relativas es más seguro que minutos absolutos.');
P('');

// ---------- a) closure ----------
P('## a) Cierre: ventaja de oro y final');
P('');
{
  const m10 = [], end10 = [], m5 = [], end5 = [];
  let reached10 = 0, loses10 = 0, reached5 = 0, loses5 = 0, winnerReached10 = 0;
  const ratio = [];
  for (const m of matches) {
    const a = m.radiant_gold_adv;
    for (const [thr, st] of [[10000, 10], [5000, 5]]) {
      const iR = a.findIndex(x => x >= thr), iD = a.findIndex(x => x <= -thr);
      const cand = [];
      if (iR >= 0) cand.push({ i: iR, R: true }); if (iD >= 0) cand.push({ i: iD, R: false });
      if (!cand.length) continue;
      cand.sort((x, y) => x.i - y.i);
      const first = cand[0];
      const lost = first.R !== winR(m);
      if (st === 10) { reached10++; if (lost) loses10++; } else { reached5++; if (lost) loses5++; }
    }
    const w = winR(m) ? 1 : -1;
    const iw = a.findIndex(x => w * x >= 10000);
    if (iw >= 0) { m10.push(iw); end10.push(m.dur - iw); winnerReached10++; }
    const iw5 = a.findIndex(x => w * x >= 5000);
    if (iw5 >= 0) { m5.push(iw5); end5.push(m.dur - iw5); }
    const mx = Math.max(...a.map(x => w * x)); ratio.push(mx);
  }
  head();
  row('Minuto en que el GANADOR llega a +10k', m10); row('Minutos desde +10k hasta el final', end10);
  row('Minuto en que el GANADOR llega a +5k', m5); row('Minutos desde +5k hasta el final', end5);
  row('Duración de la partida (min)', matches.map(m => m.dur));
  row('Máxima ventaja de oro del ganador', ratio);
  P('');
  P(`- Partidas donde el ganador llegó alguna vez a +10k: ${pct(winnerReached10, matches.length)}.`);
  P(`- Equipo que llegó primero a +10k (de las que alguien llegó): pierde ${pct(loses10, reached10)}.`);
  P(`- Equipo que llegó primero a +5k: pierde ${pct(loses5, reached5)}.`);
  P('- Limitación: la ventaja de oro es por minuto (radiant_gold_adv), resolución de 60 s; "llegó primero" compara minutos enteros.');
}
P('');

// ---------- b) towers & high ground ----------
P('## b) Torres y high ground');
P('');
{
  const first = { 1: [], 2: [], 3: [] }, firstAny = { 1: [], 2: [], 3: [] };
  const firstW = { 1: [], 2: [], 3: [] }, firstL = { 1: [], 2: [], 3: [] };
  const advT3 = [], advT3win = [], advT3lose = [];
  let t3 = 0, t3aegisOwn = 0, t3aegisEnemy = 0, t3first = 0;
  let t3any = 0, t3anyAegis = 0;
  for (const m of matches) {
    for (const tier of [1, 2, 3]) {
      for (const destR of [true, false]) {
        const x = m.towers.find(t => t.tier === tier && t.victimR !== destR);
        if (x) { first[tier].push(x.t / 60); (destR === winR(m) ? firstW : firstL)[tier].push(x.t / 60); }
      }
      const any = m.towers.find(t => t.tier === tier);
      if (any) firstAny[tier].push(any.t / 60);
    }
    for (const destR of [true, false]) {
      const x = m.towers.find(t => t.tier === 3 && t.victimR !== destR);
      if (!x) continue;
      t3++;
      const adv = advAt(m, x.t, destR);
      advT3.push(adv); (destR === winR(m) ? advT3win : advT3lose).push(adv);
      // aegis active: a Roshan kill in the previous 300 s
      const r = m.rosh.filter(r => r.t <= x.t && x.t - r.t <= 300).pop();
      if (r) { if (r.killerR === destR) t3aegisOwn++; else t3aegisEnemy++; }
    }
    // first T3 of the match, aegis active for the taker
    const any3 = m.towers.find(t => t.tier === 3);
    if (any3) {
      t3any++;
      const r = m.rosh.filter(r => r.t <= any3.t && any3.t - r.t <= 300).pop();
      if (r && r.killerR !== any3.victimR) t3anyAegis++;
    }
  }
  head();
  for (const tier of [1, 2, 3]) row(`Primera T${tier} enemiga derribada, por equipo (min)`, first[tier]);
  for (const tier of [1, 2, 3]) row(`  primera T${tier}: equipo GANADOR`, firstW[tier]);
  for (const tier of [1, 2, 3]) row(`  primera T${tier}: equipo PERDEDOR`, firstL[tier]);
  for (const tier of [1, 2, 3]) row(`Primera T${tier} de la partida (cualquier equipo)`, firstAny[tier]);
  row('Ventaja de oro (en k) del equipo en el momento de derribar SU primera T3 enemiga', advT3.map(x => x / 1000));
  row('  ... si el equipo acabó ganando', advT3win.map(x => x / 1000));
  row('  ... si el equipo acabó perdiendo', advT3lose.map(x => x / 1000));
  P('');
  P(`- Primeras T3 enemigas derribadas (una por equipo y partida) con Aegis activo del propio equipo (Roshan muerto <5 min antes): ${pct(t3aegisOwn, t3)}; con Aegis activo del rival: ${pct(t3aegisEnemy, t3)}.`);
  P(`- Primera T3 de la partida tomada por quien tenía el Aegis activo: ${pct(t3anyAegis, t3any)}.`);
  P('- Limitaciones: "Aegis activo" = ROSHAN_KILL del equipo en los 300 s previos; no sabemos si el Aegis ya se había gastado, ni si el portador murió. Las T3 se cuentan por equipo derribador. La ventaja de oro es la del minuto más cercano (±30 s).');
}
P('');

// ---------- c) Roshan ----------
P('## c) Roshan');
P('');
{
  const byN = { 1: [], 2: [], 3: [], 4: [] }, adv = [], advW = [], advL = [], towersAfter = [], towersAgainst = [], dAdv = [];
  let nR = 0, gotTower = 0, killerWon = 0, killerAhead = 0;
  for (const m of matches) {
    m.rosh.forEach((r, i) => {
      nR++;
      byN[Math.min(i + 1, 4)].push(r.t / 60);
      const a = advAt(m, r.t, r.killerR);
      adv.push(a / 1000); (r.killerR === winR(m) ? advW : advL).push(a / 1000);
      if (r.killerR === winR(m)) killerWon++;
      if (a > 0) killerAhead++;
      const win = m.towers.filter(t => t.t > r.t && t.t <= r.t + 300);
      const mine = win.filter(t => t.victimR !== r.killerR).length;
      towersAfter.push(mine); towersAgainst.push(win.length - mine);
      if (mine > 0) gotTower++;
      dAdv.push((advAt(m, r.t + 300, r.killerR) - a) / 1000);
    });
  }
  head();
  row('Minuto del 1er Roshan', byN[1]); row('Minuto del 2º Roshan', byN[2]); row('Minuto del 3er Roshan', byN[3]); row('Minuto del 4º o posterior', byN[4]);
  row('Ventaja de oro (k) de quien mata a Roshan en ese momento', adv);
  row('  ... el matador acaba ganando', advW); row('  ... el matador acaba perdiendo', advL);
  row('Torres derribadas por el matador en los 5 min siguientes', towersAfter);
  row('Torres perdidas por el matador en esos 5 min', towersAgainst);
  row('Cambio de ventaja de oro del matador en 5 min (k)', dAdv);
  P('');
  P(`- ${nR} Roshan en ${matches.length} partidas. El matador va por delante en oro en ${pct(killerAhead, nR)}; gana la partida ${pct(killerWon, nR)}; derriba al menos una torre en los 5 min siguientes ${pct(gotTower, nR)}.`);
  P('- Limitación: ROSHAN_KILL no distingue si el rival estaba muerto o desviado; las torres de los 5 min incluyen las caídas por creeps o por Roshan/Aegis, no solo por héroes.');
}
P('');

// ---------- d) objectives after won fights ----------
P('## d) Torres T2/T3 tras pelea ganada (ventana de 90 s)');
P('');
{
  const st = { 2: [0, 0], 3: [0, 0], all: [0, 0] };
  let covered = 0, total = 0;
  for (const m of matches) {
    const won = { R: [], D: [] };
    for (const t of m.tf) { if (t.gdR > t.gdD) won.R.push(t); else if (t.gdD > t.gdR) won.D.push(t); }
    const isAfter = (destR, ts) => (destR ? won.R : won.D).some(t => ts > t.end && ts <= t.end + 90);
    // coverage baseline: fraction of game time (after minute 10) in the 90 s after a won fight, per team
    for (const k of ['R', 'D']) {
      const ints = won[k].map(t => [Math.max(600, t.end), Math.min(m.duration, t.end + 90)]).filter(i => i[1] > i[0]).sort((a, b) => a[0] - b[0]);
      let cov = 0, cur = null;
      for (const i of ints) { if (!cur || i[0] > cur[1]) { if (cur) cov += cur[1] - cur[0]; cur = [...i]; } else cur[1] = Math.max(cur[1], i[1]); }
      if (cur) cov += cur[1] - cur[0];
      covered += cov; total += Math.max(0, m.duration - 600);
    }
    for (const t of m.towers) {
      if (t.tier < 2 || t.tier > 3) continue;
      const destR = !t.victimR;
      const a = isAfter(destR, t.t);
      st[t.tier][1]++; st.all[1]++; if (a) { st[t.tier][0]++; st.all[0]++; }
    }
  }
  P(`- T2 derribadas dentro de 90 s tras una pelea ganada por el equipo derribador: ${pct(...st[2])}.`);
  P(`- T3 derribadas dentro de 90 s tras una pelea ganada: ${pct(...st[3])}.`);
  P(`- T2+T3 en conjunto: ${pct(...st.all)}.`);
  P(`- Línea base: fracción del tiempo de partida (tras el min 10) que está dentro de 90 s de una pelea ganada del equipo: ${(100 * covered / total).toFixed(0)}% (si el % de torres es muy superior a esto, ganar la pelea y empujar va unido).`);
  P('- Limitaciones: pelea ganada = suma de gold_delta del equipo > suma del rival; el "fin" de la pelea es teamfights[].end de OpenDota; no distingue torres caídas por héroes y por creeps. No se mide agrupación real de héroes (no hay posiciones por segundo).');
}
P('');

// ---------- e) fights ----------
P('## e) Peleas');
P('');
{
  let n = 0, fewerDeathsWins = 0, moreDeathsWins = 0, even = 0, evenDecided = 0;
  const bySize = {};
  const nd = [], dur = [], gdAbs = [];
  let bb = 0;
  for (const m of matches) for (const t of m.tf) {
    n++;
    nd.push(t.dR + t.dD); dur.push((t.end - t.start)); gdAbs.push(Math.abs(t.gdR - t.gdD) / 1000);
    bb += t.bb > 0 ? 1 : 0;
    const wR = t.gdR > t.gdD ? 1 : t.gdR < t.gdD ? -1 : 0;
    const d = t.dD - t.dR; // >0: radiant lost fewer
    if (d === 0) { even++; continue; }
    const fewerR = d > 0;
    if (wR === 0) continue;
    if ((wR === 1) === fewerR) fewerDeathsWins++; else moreDeathsWins++;
    const key = Math.min(Math.abs(d), 3);
    bySize[key] = bySize[key] || [0, 0];
    bySize[key][1]++; if ((wR === 1) === fewerR) bySize[key][0]++;
  }
  head();
  row('Muertes totales por pelea', nd); row('Duración de la pelea (s)', dur); row('Diferencia absoluta de gold_delta entre equipos (k)', gdAbs);
  P('');
  P(`- ${n} peleas. El bando con menos muertes gana por oro en ${pct(fewerDeathsWins, fewerDeathsWins + moreDeathsWins)} de las no empatadas en muertes; ${even} (${(100 * even / n).toFixed(0)}%) empatan a muertes.`);
  for (const k of [1, 2, 3]) if (bySize[k]) P(`- Diferencia de muertes ${k}${k === 3 ? '+' : ''}: el bando con menos muertes gana ${pct(...bySize[k])}.`);
  P(`- Peleas con al menos un buyback: ${pct(bb, n)}.`);
  P('- Nota: gold_delta incluye el oro de las muertes, así que que gane el bando con menos muertes es en parte tautológico; lo útil es la diferencia de muertes ya observada.');
  P('- Limitación: la ventaja numérica real al inicio no se conoce (solo muertes finales); un 5v3 inicial que acaba 3 muertes cada lado no se ve.');
  P('');
  // isolated kills
  P('### Muerte aislada de un aliado y reacción');
  P('');
  let iso = 0, withFight30 = 0, victimWins = 0, killerWins = 0, ties = 0, noFight = 0;
  const lag = [];
  const isoW = { N: 0, A: 0 };
  for (const m of matches) {
    for (let i = 0; i < m.kills.length; i++) {
      const k = m.kills[i];
      if (m.tf.some(t => k.t >= t.start - 5 && k.t <= t.end)) continue; // inside a fight
      if (m.kills.some((o, j) => j !== i && o.t < k.t && k.t - o.t <= 15)) continue; // not isolated: another kill in previous 15 s
      if (m.kills.some((o, j) => j !== i && o.t > k.t && o.t - k.t <= 5 && !m.tf.some(t => o.t >= t.start - 5 && o.t <= t.end))) continue; // cluster
      iso++;
      const next = m.tf.filter(t => t.start > k.t && t.start - k.t <= 30)[0];
      if (!next) { noFight++; continue; }
      withFight30++; lag.push(next.start - k.t);
      const g = k.victimR ? next.gdR - next.gdD : next.gdD - next.gdR; // victim team's advantage
      if (g > 0) victimWins++; else if (g < 0) killerWins++; else ties++;
    }
  }
  P(`- Muertes de héroe aisladas (sin otra muerte en los 15 s previos ni fuera de pelea): ${iso}.`);
  P(`- Seguidas de una teamfight que empieza en los 30 s siguientes: ${pct(withFight30, iso)}; sin pelea en 30 s: ${pct(noFight, iso)}.`);
  P(`- De esas peleas, gana el equipo del muerto (por gold_delta): ${pct(victimWins, withFight30)}; gana el equipo del matador: ${pct(killerWins, withFight30)}; empate ${ties}. Retraso mediano muerte-pelea: ${f1(q(lag, .5))} s.`);
  P('- Limitaciones: la muerte aislada puede quedar fuera de teamfights[] por el umbral de OpenDota (3+ muertes); no se sabe quién inició la pelea ni si el equipo "entró" voluntariamente. kills_log da el momento de la muerte con resolución de 1 s.');
}
P('');

// ---------- f) after losing a fight ----------
P('## f) Tras perder una pelea (gold_delta del equipo < -1500 frente al rival, es decir, el rival gana por >1500)');
P('');
{
  const gap = [], rLose = [], rBefore = [], rWin = [], ratioL = [];
  let n = 0, noNext = 0, deltaOK = 0, deltaUp = 0;
  for (const m of matches) {
    const tfs = [...m.tf].sort((a, b) => a.start - b.start);
    tfs.forEach((t, i) => {
      for (const isR of [true, false]) {
        const mine = isR ? t.gdR : t.gdD, theirs = isR ? t.gdD : t.gdR;
        if (mine - theirs > -1500) continue;
        n++;
        const next = tfs[i + 1];
        if (!next) { noNext++; continue; }
        const g = (next.start - t.end) / 60;
        gap.push(g);
        const a = Math.ceil(t.end / 60), b = Math.floor(next.start / 60);
        const lh = (pl, x, y) => pl.filter(p => p.isRadiant === isR).reduce((s, p) => s + ((p.lh_t?.[y] ?? 0) - (p.lh_t?.[x] ?? 0)), 0);
        if (b - a >= 2) {
          const r = lh(m.players, a, b) / (b - a);
          const s0 = Math.max(0, Math.floor(t.start / 60) - 3), s1 = Math.floor(t.start / 60);
          if (s1 - s0 >= 2) {
            const rb = lh(m.players, s0, s1) / (s1 - s0);
            rLose.push(r); rBefore.push(rb); deltaOK++; if (r > rb) deltaUp++;
            if (rb > 0) ratioL.push(r / rb);
          }
        }
      }
    });
  }
  head();
  row('Minutos desde el fin de la pelea perdida hasta la siguiente pelea', gap);
  row('Last hits/min del perdedor entre peleas (equipo, 5 héroes)', rLose);
  row('Last hits/min del mismo equipo en los 3 min previos a la pelea', rBefore);
  row('Cociente (entre peleas)/(antes)', ratioL);
  P('');
  P(`- ${n} peleas perdidas por >1500 de gold_delta (por equipo); sin pelea posterior: ${noNext}.`);
  P(`- El ritmo de last hits del perdedor sube respecto a antes de la pelea en ${pct(deltaUp, deltaOK)} de los casos con intervalo >= 2 min.`);
  P('- Limitaciones: lh_t es serie por minuto de last hits TOTALES (creeps de línea + neutrales); neutral_kills solo existe como total de la partida, no como serie, así que no se puede aislar el farmeo de neutrales. Es un proxy. Se compara con los 3 min anteriores (que incluyen peleas y empuje).');
}
P('');

// ---------- g) base defence ----------
P('## g) Defensa de base: perder cuarteles yendo por delante en oro');
P('');
{
  let events = 0, ahead = 0, ahead2 = 0, matchesRax = 0, matchesAhead = 0;
  const advs = [];
  for (const m of matches) {
    if (m.rax.length) matchesRax++;
    let hit = false;
    for (const r of m.rax) {
      events++;
      const a = advAt(m, r.t, r.victimR); // victim team advantage
      advs.push(a / 1000);
      if (a > 0) { ahead++; hit = true; }
      if (a > 2000) ahead2++;
    }
    if (hit) matchesAhead++;
  }
  P(`- ${events} cuarteles caídos en ${matchesRax} de ${matches.length} partidas. El equipo que los pierde iba por delante en oro (>0) en ${pct(ahead, events)}, y por más de 2000 en ${pct(ahead2, events)}. Partidas con algún cuartel perdido yendo por delante: ${pct(matchesAhead, matchesRax)}.`);
  P('');
  head();
  row('Ventaja de oro (k) del equipo que pierde el cuartel, en ese minuto', advs);
  P('');
  P('- Limitación: oro por minuto; en peleas largas el signo puede cambiar dentro del minuto. No se distingue si el rival usó Aegis/buyback.');
}
P('');

// ---------- h) ults ----------
P('## h) Ultis en peleas');
P('');
{
  const pairs = new Map(), byCount = {}, hero = new Map();
  let total = 0;
  const INIT = /^(blink|swift_blink|arcane_blink|overwhelming_blink|force_staff|hurricane_pike|cyclone)$/;
  for (const m of matches) for (const t of m.tf) {
    for (const isR of [true, false]) {
      const mine = isR ? t.gdR : t.gdD, theirs = isR ? t.gdD : t.gdR;
      if (mine === theirs) continue;
      const won = mine > theirs;
      const used = [];
      t.raw.players.forEach((p, i) => {
        if (m.players[i].isRadiant !== isR) return;
        const hn = heroes[m.players[i].hero_id]?.localized_name || '?';
        const u = Object.keys(p.ability_uses || {}).filter(a => ultSet.has(a));
        const blink = Object.keys(p.item_uses || {}).some(a => /blink/.test(a));
        u.forEach(a => used.push(a));
        const h = hero.get(hn) || { fights: 0, ult: 0, ultW: 0, blink: 0, blinkW: 0 };
        h.fights++;
        if (u.length) { h.ult++; if (won) h.ultW++; }
        if (blink) { h.blink++; if (won) h.blinkW++; }
        hero.set(hn, h);
      });
      const c = Math.min(used.length, 4);
      byCount[c] = byCount[c] || [0, 0]; byCount[c][1]++; if (won) byCount[c][0]++;
      total++;
      const uniq = [...new Set(used)].sort();
      for (let i = 0; i < uniq.length; i++) for (let j = i + 1; j < uniq.length; j++) {
        const k = uniq[i] + ' + ' + uniq[j];
        const v = pairs.get(k) || [0, 0]; v[0]++; if (won) v[1]++; pairs.set(k, v);
      }
    }
  }
  P(`Identificadas ${ultSet.size} habilidades definitivas (criterio: habilidad no innata con 3 niveles en OpenDota constants; si un héroe no tiene ninguna, la última activa). Aproximación: incluye algunas habilidades de Aghanim y puede fallar con héroes de ults múltiples.`);
  P('');
  P('Victoria de la pelea (por gold_delta del equipo) según nº de ultis usadas por ese equipo en la pelea:');
  P('');
  P('| Ultis usadas | peleas-equipo | % victoria |');
  P('|---|---|---|');
  for (const k of Object.keys(byCount).sort()) P(`| ${k}${k == 4 ? '+' : ''} | ${byCount[k][1]} | ${(100 * byCount[k][0] / byCount[k][1]).toFixed(0)}% |`);
  P('');
  P('Top 30 pares de ultis usadas juntas por el mismo equipo en la misma pelea (min. 2 ocurrencias):');
  P('');
  P('| Par | veces | % victoria de la pelea |');
  P('|---|---|---|');
  [...pairs.entries()].sort((a, b) => b[1][0] - a[1][0]).slice(0, 30).forEach(([k, v]) => P(`| ${k} | ${v[0]} | ${(100 * v[1] / v[0]).toFixed(0)}% |`));
  P('');
  P('Héroes que más usan ult o blink en peleas (proxy de iniciador; min. 8 peleas):');
  P('');
  P('| Héroe | peleas | % con ult | % victoria con ult | % con blink | % victoria con blink |');
  P('|---|---|---|---|---|---|');
  [...hero.entries()].filter(([, h]) => h.fights >= 8).sort((a, b) => (b[1].ult + b[1].blink) / b[1].fights - (a[1].ult + a[1].blink) / a[1].fights).slice(0, 15)
    .forEach(([n, h]) => P(`| ${n} | ${h.fights} | ${(100 * h.ult / h.fights).toFixed(0)}% | ${h.ult ? (100 * h.ultW / h.ult).toFixed(0) + '%' : '-'} | ${(100 * h.blink / h.fights).toFixed(0)}% | ${h.blink ? (100 * h.blinkW / h.blink).toFixed(0) + '%' : '-'} |`));
  P('');
  P('- Limitaciones: ability_uses y item_uses son CONTEOS por pelea, sin orden temporal fino: no se sabe quién abre ni en qué segundo. "Iniciador" es un proxy (usa ult/blink en la pelea). Las muestras por par son pequeñas (150 partidas): muchos pares salen 1-3 veces; el % de victoria es ruidoso. Quien usa ults tiende a estar vivo/ganando, hay sesgo de supervivencia.');
}
P('');

// ---------- i) purchases ----------
P('## i) Compras: tiempos medianos por rol');
P('');
{
  const bigItem = n => (items[n]?.cost ?? 0) >= 2000 && !/^(tpscroll|ward|dust|smoke|travel)/.test(n) && n !== 'aghanims_shard';
  const data = {};
  for (const m of matches) {
    for (const isR of [true, false]) {
      const ps = m.players.filter(p => p.isRadiant === isR && p.purchase_log);
      const rank = [...ps].sort((a, b) => (b.total_gold ?? b.gold_per_min ?? 0) - (a.total_gold ?? a.gold_per_min ?? 0));
      ps.forEach(p => {
        const core = rank.indexOf(p) < 3;
        const role = !core ? 'soporte (2 menos oro)' : p.lane_role === 2 ? 'mid core' : p.lane_role === 3 ? 'offlane core' : 'safe core';
        const d = data[role] = data[role] || { n: 0, bkb: [], blink: [], big: [] };
        d.n++;
        const log = [...p.purchase_log].sort((a, b) => a.time - b.time);
        const bk = log.find(x => x.key === 'black_king_bar'); if (bk) d.bkb.push(bk.time / 60);
        const bl = log.find(x => /blink/.test(x.key) && items[x.key]?.cost >= 2000); if (bl) d.blink.push(bl.time / 60);
        const bg = log.find(x => bigItem(x.key)); if (bg) d.big.push(bg.time / 60);
      });
    }
  }
  P('Rol: lane_role de OpenDota (1 safe, 2 mid, 3 off) entre los 3 héroes con más oro del equipo = cores; los 2 con menos oro = soportes. (Aproximación a posiciones 1-5.)');
  P('');
  P('| Rol | jugadores | BKB: n, mediana (p25-p75) | Blink: n, mediana (p25-p75) | 1er ítem >= 2000 oro: n, mediana (p25-p75) |');
  P('|---|---|---|---|---|');
  const cell = a => `${a.length}, ${f1(q(a, .5))} (${f1(q(a, .25))}-${f1(q(a, .75))})`;
  for (const [r, d] of Object.entries(data)) P(`| ${r} | ${d.n} | ${cell(d.bkb)} | ${cell(d.blink)} | ${cell(d.big)} |`);
  P('');
  P('- Limitaciones: purchase_log da el momento de COMPRA del ítem final (no de los componentes); "ítem grande" = coste >= 2000 excluyendo botas de viaje, TPs y consumibles; "Blink" cuenta Blink Dagger y sus mejoras (Swift/Arcane/Overwhelming) con coste >= 2000; el n es el nº de jugadores que lo compraron, no todos lo hacen.');
}
P('');
P('## Limitaciones generales');
P('- Muestra pequeña (~150 partidas, sobre todo de unos pocos torneos recientes); los percentiles de subgrupos (por tier, por rol) son ruidosos.');
P('- Solo partidas analizadas por OpenDota (version != null): sesgo hacia partidas de torneos con replay disponible.');
P('- Profesionales en Captain\'s Mode, con comunicación, vigilancia de mapa y drafts de equipo; un bot no se comporta igual. Úsese para umbrales relativos (ventaja de oro, número de muertos) más que para minutos absolutos.');
P('- Modo normal, no Turbo. En Turbo, los tiempos son más o menos la mitad (sin verificar).');

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, out.join('\n') + '\n');
console.log(`Escrito ${OUT} (${matches.length} partidas analizadas de ${all.length} en caché).`);
