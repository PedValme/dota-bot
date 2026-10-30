// Per-variant summary of one benchmark series: wins, closing time from a 10k net worth lead, and (with --observar
// logs) how often 4-5 of dota-bot's bots pushed together from minute 10.
//   node tools/bench/resumir-serie.mjs <etiqueta>
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../..", import.meta.url));
const tag = process.argv[2];
if (!tag) throw new Error("Uso: node tools/bench/resumir-serie.mjs <etiqueta>");
const [header, ...rows] = readFileSync(join(root, "bench", "series.csv"), "utf8").trim().split(/\r?\n/);
const cols = header.split(",");
const matches = rows.map((r) => Object.fromEntries(r.split(",").map((v, i) => [cols[i], v]))).filter((r) => r.etiqueta === tag);
const obsDir = join(root, "bench", "observaciones");
let obsFiles = [];
const ownFile = new RegExp(`^${tag.replace(/[.]/g, "\\.")}-\\d{12}-\\d+\\.log$`); // not another series' "<tag>-x-..."
try { obsFiles = readdirSync(obsDir).filter((f) => ownFile.test(f)); } catch {}

// Share of 2-second samples from minute 10 with 4 or 5 bots in the same push mode.
function groupedPush(file) {
  const byT = {};
  for (const l of readFileSync(join(obsDir, file), "utf8").split(/\r?\n/)) {
    const m = l.match(/\[bench\] mode t=(\d+) pid=(\d+) \S+ (\S+) [\d.]+ alive=(\d)/);
    if (!m || +m[1] < 600) continue;
    (byT[Math.floor(+m[1] / 2) * 2] ??= {})[m[2]] = m[4] === "1" ? m[3] : "DEAD";
  }
  let n = 0, grouped = 0;
  for (const modes of Object.values(byT)) {
    const ms = Object.values(modes);
    if (ms.length < 5) continue;
    n++;
    const push = {};
    for (const m of ms) if (m.startsWith("PUSH")) push[m] = (push[m] ?? 0) + 1;
    if (Math.max(0, ...Object.values(push)) >= 4) grouped++;
  }
  return n ? grouped / n : null;
}

const median = (xs) => { const s = [...xs].sort((a, b) => a - b); return s.length ? (s.length % 2 ? s[(s.length - 1) / 2] : (s[s.length / 2 - 1] + s[s.length / 2]) / 2) : null; };
console.log(`Serie ${tag}: ${matches.length} partidas`);
for (const v of [...new Set(matches.map((m) => m.variante))]) {
  const ms = matches.filter((m) => m.variante === v && m.valida === "si");
  const wins = ms.filter((m) => m.ganador === m.dotabot).length;
  const closes = ms.filter((m) => m.ganador === m.dotabot && m.minuto_10k !== "").map((m) => +m.minutos - +m.minuto_10k);
  const lostAfter10k = ms.filter((m) => m.ganador !== m.dotabot && m.minuto_10k !== "").length;
  const groups = ms.map((m) => obsFiles.find((f) => f.endsWith(`-${m.partida}.log`))).filter(Boolean).map(groupedPush).filter((x) => x !== null);
  console.log(`  ${v.padEnd(11)} ganó ${wins}/${ms.length} válidas · cierre desde +10k: mediana ${median(closes) ?? "-"} min (${closes.join(", ") || "-"}) · perdió tras +10k: ${lostAfter10k}` +
    ` · minutos de partida: mediana ${median(ms.map((m) => +m.minutos)) ?? "-"} · 4-5 bots empujando juntos: ${groups.length ? (100 * groups.reduce((a, b) => a + b, 0) / groups.length).toFixed(0) + "%" : "-"}`);
}
