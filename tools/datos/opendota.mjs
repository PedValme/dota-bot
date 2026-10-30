// Downloads recent analyzed pro matches from the public OpenDota API into a local cache.
// The cache holds player names (third-party data): keep it OUTSIDE the repo.
// Usage: node tools/datos/opendota.mjs [--cache <dir>] [--n 150] [--max-calls 400]
// Limits: stays under 50 calls/min (1.3 s between calls) and under --max-calls in total.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf('--' + k); return i >= 0 ? args[i + 1] : d; };
const CACHE = opt('cache', path.join(os.tmpdir(), 'dota-bot-datos', 'pro'));
const WANT = Number(opt('n', 150));
const MAX_CALLS = Number(opt('max-calls', 400));
const GAP_MS = 1300; // ~46 calls/min
const BASE = 'https://api.opendota.com/api';
fs.mkdirSync(CACHE, { recursive: true });

let calls = 0;
let last = 0;
async function get(url) {
  if (calls >= MAX_CALLS) throw new Error('límite de llamadas alcanzado');
  const wait = last + GAP_MS - Date.now();
  if (wait > 0) await new Promise(r => setTimeout(r, wait));
  last = Date.now(); calls++;
  const r = await fetch(url);
  if (r.status === 429) { console.log('429: espero 60 s'); await new Promise(r => setTimeout(r, 60000)); return get(url); }
  if (!r.ok) throw new Error(`HTTP ${r.status} ${url}`);
  return r.json();
}
const cached = f => fs.existsSync(path.join(CACHE, f));
const save = (f, o) => fs.writeFileSync(path.join(CACHE, f), JSON.stringify(o));

// Constants (heroes, abilities) are cached once.
for (const [f, u] of [['heroes.json', '/heroes'], ['abilities.json', '/constants/abilities'], ['ability_ids.json', '/constants/ability_ids'], ['items.json', '/constants/items'], ['hero_abilities.json', '/constants/hero_abilities']]) {
  if (!cached(f)) { save(f, await get(BASE + u)); console.log('constante descargada:', f); }
}

const have = () => fs.readdirSync(CACHE).filter(f => /^m\d+\.json$/.test(f)).length;
const seen = new Set(fs.existsSync(path.join(CACHE, 'skipped.json')) ? JSON.parse(fs.readFileSync(path.join(CACHE, 'skipped.json'))) : []);
let lessThan = null;
let patch = null;
while (have() < WANT && calls < MAX_CALLS) {
  const list = await get(BASE + '/proMatches' + (lessThan ? `?less_than_match_id=${lessThan}` : ''));
  if (!list.length) break;
  lessThan = list[list.length - 1].match_id;
  for (const m of list) {
    if (have() >= WANT || calls >= MAX_CALLS) break;
    if (m.version == null || m.duration < 900) continue; // not analyzed, or a short/abandoned game
    if (cached(`m${m.match_id}.json`) || seen.has(m.match_id)) continue;
    try {
      const full = await get(`${BASE}/matches/${m.match_id}`);
      if (full.version == null || !full.objectives || !full.radiant_gold_adv) { seen.add(m.match_id); continue; }
      patch = patch ?? full.patch;
      save(`m${m.match_id}.json`, full);
      if (have() % 10 === 0) console.log(`en caché: ${have()}/${WANT} (llamadas ${calls})`);
    } catch (e) { console.log('error:', e.message); seen.add(m.match_id); }
  }
}
save('skipped.json', [...seen]);
console.log(`Listo: ${have()} partidas en caché, ${calls} llamadas en esta ejecución.`);
