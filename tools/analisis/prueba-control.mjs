// dota-bot: reads the full-control test's observed matches (trabajo/prueba-control.md) from bench/observaciones/.
// Fixed before seeing the data. Per match and arm (control_sniper / base_sniper): the Sniper's lane numbers at minutes
// 5 and 10 ("[bench] linea"), and for the own Think: last-hit attempts and their result, decisions by intent, which
// OHA/engine entry points still get called ("[bench] prop llamadas"), the active mode it reports, and Think's cost.
//   node tools/analisis/prueba-control.mjs [etiqueta]      (default: every observation file with "prueba-control")
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const dir = join(root, "bench", "observaciones");
const tag = process.argv[2] ?? "prueba-control";
const files = readdirSync(dir).filter((f) => f.includes(tag)).sort();
if (!files.length) { console.log(`Sin archivos con "${tag}" en bench/observaciones.`); process.exit(0); }

const kv = (line) => Object.fromEntries([...line.matchAll(/(\w+)=(\S+)/g)].map((m) => [m[1], m[2]]));

for (const f of files) {
  const lines = readFileSync(join(dir, f), "latin1").split(/\r?\n/);
  const linea = lines.filter((l) => l.includes("[bench] linea ")).map(kv);
  const control = linea.some((x) => x.control === "true");
  console.log(`\n== ${f} · ${control ? "control_sniper (Think propio)" : "base_sniper (OHA)"}`);
  for (const min of [5, 10]) {
    const x = linea.find((r) => Math.floor(Number(r.t) / 60) === min);
    console.log(x ? `  min ${min}: lh=${x.lh} dn=${x.dn} nw=${x.nw} nivel=${x.nivel} muertes=${x.muertes}` : `  min ${min}: sin dato`);
  }
  if (!control) continue;
  const res = lines.filter((l) => l.includes("[bench] prop golpe_res "));
  const hits = (kind) => res.filter((l) => l.includes(` ${kind} `));
  for (const kind of ["ultimo_golpe", "denegar"]) {
    const all = hits(kind), ok = all.filter((l) => l.includes(" acierto "));
    const t10 = all.filter((l) => Number(kv(l).t) <= 600);
    console.log(`  ${kind}: ${ok.length}/${all.length} aciertos (hasta min 10: ${t10.filter((l) => l.includes(" acierto ")).length}/${t10.length})`);
  }
  const fallos = hits("ultimo_golpe").filter((l) => l.includes(" fallo ")).slice(0, 5);
  for (const l of fallos) console.log(`    fallo: ${l.slice(l.indexOf("t="))}`);
  const dec = {};
  for (const l of lines.filter((l) => l.includes("[bench] prop decision "))) {
    const i = kv(l).intencion; dec[i] = (dec[i] ?? 0) + 1;
  }
  console.log(`  decisiones: ${Object.entries(dec).map(([k, n]) => `${k} ${n}`).join(", ")}`);
  // Phase 1 (trabajo/bot-propio.md): abilities, trades and purchases up to minute 10.
  const upTo10 = (kind) => lines.filter((l) => l.includes(`[bench] prop ${kind} `) && Number(kv(l).t) <= 600);
  const casts = upTo10("habilidad");
  console.log(`  hasta min 10: shrapnel ${casts.filter((l) => l.includes("shrapnel:")).length}, assassinate ${casts.filter((l) => l.includes("assassinate:")).length}, acosos ${upTo10("acoso").length}`);
  const bought = upTo10("compra").filter((l) => /\(para /.test(l) && !l.includes("no comprado")).map((l) => l.match(/compra t=\S+ pid=\d+ (\S+)/)?.[1]);
  console.log(`  compras hasta min 10: ${bought.join(" ") || "ninguna"}`);
  const calls = lines.filter((l) => l.includes("[bench] prop llamadas ")).slice(-1)[0];
  console.log(`  aún llamadas por el motor (último informe): ${calls ? calls.slice(calls.indexOf("pid=")) : "ninguna"}`);
  const modes = new Set(lines.filter((l) => l.includes("[bench] prop estado ")).map((l) => kv(l).modo));
  console.log(`  modo activo que ve el bot: ${[...modes].join(", ")}`);
  const think = lines.filter((l) => l.includes("[bench] prop think ")).map(kv);
  if (think.length) {
    const avg = (k) => (think.reduce((a, x) => a + Number(x[k]), 0) / think.length).toFixed(3);
    console.log(`  Think: ${avg("por_s")} por s, ${avg("ms_media")} ms de media, máx ${Math.max(...think.map((x) => Number(x.ms_max))).toFixed(2)} ms`);
  }
  const errors = lines.filter((l) => l.includes("[bench] prop error "));
  if (errors.length) console.log(`  ERRORES: ${errors.length}; el primero: ${errors[0].slice(errors[0].indexOf("t="))}`);
}
