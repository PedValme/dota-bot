// dota-bot benchmark orchestrator: plays N local bot-vs-bot matches, dota-bot on one side and Valve's own bots on the
// other (sides alternate), both teams with the same five heroes drawn per match, and records each winner from Dota's
// Game State Integration (GSI). The match runs in the local custom game tools/bench/addon ("dotabench"), which keeps
// the human out of the teams, adds the bots and speeds the match up.
//   node tools/bench/orquestador.mjs [--partidas 2] [--dificultad 4] [--velocidad 4] [--etiqueta texto]
//                                    [--dota "<dota 2 beta>"] [--muestra-gsi <file>]
//
// Limits, on purpose (Pedro, 2026-10-28: «solamente y acotado a steam y dota y lo que queremos»):
// - Starts only <dota>/game/bin/win64/dota2.exe with fixed arguments, and only stops the dota2.exe it started.
// - Does not start Steam (it must already be running) and refuses to run if any dota2.exe is already open.
// - Listens only on 127.0.0.1 and only accepts GSI posts carrying its own token.
// - Writes only: the GSI config in <dota>/game/dota/cfg/gamestate_integration/, bots/Customize/bench_valve_team.lua
//   (which team plays with Valve's bots), tools/bench/addon/scripts/vscripts/bench_partida.lua (heroes, difficulty,
//   speed; deleted at the end too), bench/partidas.csv and bench/lineas/ (per-match timelines, read from its own
//   Dota's <dota>/game/dota/console.log), and, only with --muestra-gsi <file> (debugging), the last raw GSI post in
//   that file. The team file lives only from launch until the
//   horn (scripts load before it); both temporary files are deleted when it ends, also on Ctrl+C, closing the window
//   or an error. A hard kill of this script (Task Manager) leaves its Dota open and the GSI config in place
//   (harmless), and bench_partida.lua (only dotabench reads it; the next match overwrites it); during a match's first
//   minutes it could also leave the team file, which makes that team play with
//   Valve's bots in any local game until the next run deletes it (or delete bots/Customize/bench_valve_team.lua).
import { spawn, execFile } from "node:child_process";
import { createServer } from "node:http";
import { existsSync, writeFileSync, unlinkSync, appendFileSync, mkdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const TOKEN = "dota-bot-bench"; // not a secret: only tells our GSI posts apart · fabrica:permitido
export const PORT = 3911;
const RADIANT = 2;
const DIRE = 3;
const root = fileURLToPath(new URL("../..", import.meta.url));
const VALVE_TEAM_FILE = join(root, "bots", "Customize", "bench_valve_team.lua");
const MATCH_FILE = join(root, "tools", "bench", "addon", "scripts", "vscripts", "bench_partida.lua");
const CSV = join(root, "bench", "partidas.csv");
const COLUMNS = ["fecha", "etiqueta", "partida", "dificultad", "dotabot", "ganador", "resultado", "minutos",
  "kills_radiant", "kills_dire", "humano", "heroes", "ventaja_oro_max", "minuto_10k", "torres_fin"];
const TIMELINES = join(root, "bench", "lineas");
const DIFFICULTIES = ["passive", "easy", "medium", "hard", "unfair"];

// One hero per position, from the heroes Valve's own bots were built for (their original pool, as recalled; not yet
// checked against "BotImplemented" in the game's npc_heroes.txt), so the Valve side is not crippled by an unsupported
// hero. Both teams get the same five.
export const HERO_POOL = [
  ["juggernaut", "phantom_assassin", "luna", "sven", "chaos_knight", "drow_ranger", "skeleton_king"],
  ["lina", "zuus", "sniper", "viper", "death_prophet", "razor", "necrolyte"],
  ["axe", "bristleback", "tidehunter", "dragon_knight", "sand_king", "kunkka"],
  ["lion", "jakiro", "vengefulspirit", "bane", "skywrath_mage"],
  ["crystal_maiden", "witch_doctor", "lich", "warlock", "dazzle", "oracle"],
];

export function drawHeroes(random = Math.random) {
  return HERO_POOL.map((pool) => "npc_dota_hero_" + pool[Math.floor(random() * pool.length)]);
}

// Lua read by the custom game (tools/bench/addon/scripts/vscripts/addon_game_mode.lua).
export function matchConfigLua(heroes, difficulty, timescale) {
  const list = heroes.map((h) => `"${h}"`).join(", ");
  return `-- written by tools/bench/orquestador.mjs for one match; deleted when it ends\nreturn { difficulty = "${DIFFICULTIES[difficulty]}", timescale = ${timescale}, heroes = { ${list} } }\n`;
}

// Match i (0-based) puts dota-bot on Radiant when i is even, on Dire when odd; Valve plays the other side.
export function sides(i) {
  return i % 2 === 0 ? { dotabot: "radiant", valveTeam: DIRE } : { dotabot: "dire", valveTeam: RADIANT };
}

export function launchArgs() {
  return [
    // No window or resolution flags: they could stick in the owner's video settings.
    "-console", "-condebug", "-novid", "-gamestateintegration",
    "+sv_cheats", "1", "+sv_lan", "1", "+dota_launch_custom_game", "dotabench", "dota",
  ];
}

export function gsiConfig() {
  return `"dota-bot benchmark"
{
    "uri"       "http://127.0.0.1:${PORT}/"
    "timeout"   "5.0"
    "buffer"    "0.5"
    "throttle"  "1.0"
    "heartbeat" "30.0"
    "data"
    {
        "provider" "1"
        "map"      "1"
        "player"   "1"
    }
    "auth"
    {
        "token" "${TOKEN}"
    }
}
`;
}

// Reduces a GSI post to what the benchmark needs; null if it is not ours or has no map.
export function readGsi(payload) {
  if (!payload || payload.auth?.token !== TOKEN || !payload.map) return null;
  const m = payload.map;
  return {
    state: m.game_state ?? "",
    winner: m.win_team === "radiant" || m.win_team === "dire" ? m.win_team : null,
    clock: Number(m.clock_time ?? 0),
    radiantKills: Number(m.radiant_score ?? 0),
    direKills: Number(m.dire_score ?? 0),
    human: payload.player?.team_name ?? "",
  };
}

// The custom game logs "[dotabench] timeline event=minute|end min=.. rk=.. ..." lines (addon_game_mode.lua).
export function parseTimeline(text) {
  const rows = [];
  for (const line of text.split(/\r?\n/)) {
    const at = line.indexOf("[dotabench] timeline ");
    if (at < 0) continue;
    const row = {};
    for (const pair of line.slice(at + 21).trim().split(/\s+/)) {
      const [k, v] = pair.split("=");
      if (k && v !== undefined) row[k] = k === "event" ? v : Number(v);
    }
    rows.push(row);
  }
  return rows;
}

// From dota-bot's side: its biggest net worth lead, the first minute it led by 10k, and towers standing at the end.
export function summarizeTimeline(rows, dotabot) {
  if (!rows.length) return { ventaja_oro_max: "", minuto_10k: "", torres_fin: "" };
  const lead = (r) => (dotabot === "radiant" ? r.rnw - r.dnw : r.dnw - r.rnw);
  const last = rows[rows.length - 1];
  const first10k = rows.find((r) => lead(r) >= 10000);
  return {
    ventaja_oro_max: Math.max(...rows.map(lead)),
    minuto_10k: first10k ? first10k.min : "",
    torres_fin: `${last.rt}-${last.dt}`,
  };
}

export function timelineCsv(rows) {
  const cols = ["min", "rk", "dk", "rt", "dt", "rb", "db", "rhp", "dhp", "rnw", "dnw", "event"];
  return [cols.join(","), ...rows.map((r) => cols.map((c) => r[c] ?? "").join(","))].join("\n") + "\n";
}

export function isFinished(s) {
  return s !== null && s.state === "DOTA_GAMERULES_STATE_POST_GAME" && s.winner !== null;
}

export function csvRow(r) {
  return COLUMNS.map((c) => String(r[c] ?? "").replaceAll(",", ";")).join(",");
}

function parseArgs(argv) {
  const opt = { partidas: 2, dificultad: 4, velocidad: 4, etiqueta: "oha-vs-valve", dota: "C:/Program Files (x86)/Steam/steamapps/common/dota 2 beta", maxMin: 75 };
  for (let i = 0; i < argv.length; i += 2) {
    const [k, v] = [argv[i], argv[i + 1]];
    if (k === "--partidas") opt.partidas = Number(v);
    else if (k === "--dificultad") opt.dificultad = Number(v);
    else if (k === "--velocidad") opt.velocidad = Number(v);
    else if (k === "--etiqueta") opt.etiqueta = v;
    else if (k === "--dota") opt.dota = v;
    else if (k === "--muestra-gsi") opt.muestra = v; // debugging: keeps the last raw GSI post in this file
    else throw new Error(`Opción desconocida: ${k}`);
  }
  if (!Number.isInteger(opt.partidas) || opt.partidas < 1 || opt.partidas > 50) throw new Error("--partidas: 1 a 50");
  if (!Number.isInteger(opt.dificultad) || opt.dificultad < 0 || opt.dificultad > 4) throw new Error("--dificultad: 0 a 4");
  if (!Number.isInteger(opt.velocidad) || opt.velocidad < 1 || opt.velocidad > 8) throw new Error("--velocidad: 1 a 8");
  if (!/^[\w.-]{1,40}$/.test(opt.etiqueta)) throw new Error("--etiqueta: letras, números, . _ -");
  return opt;
}

function running(image) {
  return new Promise((ok, fail) =>
    execFile("tasklist", ["/FI", `IMAGENAME eq ${image}`, "/FO", "CSV", "/NH"], (err, out) =>
      err ? fail(err) : ok(out.toLowerCase().includes(`"${image.toLowerCase()}"`))));
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main(argv) {
  const opt = parseArgs(argv);
  const exe = resolve(opt.dota, "game/bin/win64/dota2.exe");
  const gsiDir = resolve(opt.dota, "game/dota/cfg/gamestate_integration");
  const gsiFile = join(gsiDir, "gamestate_integration_dotabot.cfg");
  const consoleLog = resolve(opt.dota, "game/dota/console.log");
  if (!existsSync(exe)) throw new Error(`No encuentro ${exe}; usa --dota`);
  if (!existsSync(gsiDir)) throw new Error(`No existe ${gsiDir}`);
  if (!existsSync(resolve(opt.dota, "game/dota_addons/dotabench/addoninfo.txt"))) {
    throw new Error("Falta el custom game dotabench en Dota: corre pwsh tools/instalar.ps1");
  }
  if (!(await running("steam.exe"))) throw new Error("Steam no está abierto; ábrelo y vuelve a correr esto.");
  if (await running("dota2.exe")) throw new Error("Ya hay un Dota abierto; ciérralo primero (no lo toco).");
  if (existsSync(VALVE_TEAM_FILE)) {
    // Only this script writes it: a leftover means an earlier run was killed hard.
    unlinkSync(VALVE_TEAM_FILE);
    console.log("Aviso: quedaba bench_valve_team.lua de una corrida interrumpida; lo borré.");
  }

  let latest = null;
  let lastPost = 0;
  const server = createServer((req, res) => {
    req.on("error", () => {});
    if (req.method !== "POST") return res.writeHead(405).end();
    let body = "";
    req.on("data", (c) => {
      body += c;
      if (body.length > 256 * 1024) req.destroy();
    });
    req.on("end", () => {
      res.writeHead(200).end();
      try {
        const payload = JSON.parse(body);
        const s = readGsi(payload);
        if (s) [latest, lastPost] = [s, Date.now()];
        if (s && opt.muestra) writeFileSync(opt.muestra, JSON.stringify(payload, null, 1));
      } catch {}
    });
  });
  await new Promise((ok, fail) => server.once("error", fail).listen(PORT, "127.0.0.1", ok));

  // On Windows a killed child keeps exitCode null (signalCode is set), so liveness comes from the 'exit' event.
  let child = null;
  let childAlive = false;
  const removeTeamFile = () => {
    try { if (existsSync(VALVE_TEAM_FILE)) unlinkSync(VALVE_TEAM_FILE); } catch {}
  };
  // Synchronous on purpose: it also runs from process.on('exit'), after an uncaught error or process.exit().
  const cleanup = () => {
    try { if (childAlive) child.kill(); } catch {}
    removeTeamFile();
    try { if (existsSync(MATCH_FILE)) unlinkSync(MATCH_FILE); } catch {}
    try { if (existsSync(gsiFile)) unlinkSync(gsiFile); } catch {}
    try { server.close(); } catch {}
  };
  process.on("exit", cleanup);
  for (const sig of ["SIGINT", "SIGHUP", "SIGBREAK", "SIGTERM"]) {
    process.on(sig, () => {
      console.log("\nInterrumpido: cierro mi Dota y borro mis archivos temporales.");
      process.exit(130);
    });
  }

  try {
    writeFileSync(gsiFile, gsiConfig());
    mkdirSync(dirname(CSV), { recursive: true });
    if (!existsSync(CSV)) appendFileSync(CSV, COLUMNS.join(",") + "\n");
    const results = [];
    for (let i = 0; i < opt.partidas; i++) {
      if (await running("dota2.exe")) throw new Error("Hay un Dota abierto que no es mío; paro sin tocarlo.");
      const { dotabot, valveTeam } = sides(i);
      writeFileSync(VALVE_TEAM_FILE, `-- written by tools/bench/orquestador.mjs for one match; deleted once the bots load\nreturn ${valveTeam}\n`);
      const heroes = drawHeroes();
      writeFileSync(MATCH_FILE, matchConfigLua(heroes, opt.dificultad, opt.velocidad));
      latest = null;
      lastPost = 0;
      const short = heroes.map((h) => h.replace("npc_dota_hero_", "")).join(" ");
      console.log(`Partida ${i + 1}/${opt.partidas}: dota-bot en ${dotabot}, Valve en ${valveTeam === RADIANT ? "radiant" : "dire"}; héroes ${short}.`);
      const started = Date.now();
      child = spawn(exe, launchArgs(), { cwd: dirname(exe), stdio: "ignore" });
      childAlive = true;
      child.on("exit", () => { childAlive = false; });
      let launchError = null;
      child.on("error", (e) => { childAlive = false; launchError = e; });
      let outcome = "timeout";
      while (Date.now() - started < opt.maxMin * 60_000) {
        await sleep(2000);
        if (launchError) throw new Error(`No pude lanzar Dota: ${launchError.message}`);
        if (!childAlive) { outcome = "dota-cerrado"; break; }
        if (!lastPost && Date.now() - started > 8 * 60_000) { outcome = "sin-gsi"; break; }
        // Every bot script has loaded by the horn: the team file is not needed any more, so a hard kill of this
        // script from here on cannot leave it behind for the owner's normal games.
        if (latest?.state === "DOTA_GAMERULES_STATE_GAME_IN_PROGRESS") removeTeamFile();
        if (isFinished(latest)) { outcome = "final"; break; }
      }
      removeTeamFile();
      if (childAlive) {
        await sleep(3000);
        child.kill();
        const deadline = Date.now() + 30_000;
        while (childAlive && Date.now() < deadline) await sleep(500);
        if (childAlive) throw new Error("Mi Dota no se cerró en 30 s; paro.");
      }
      if (outcome === "dota-cerrado" && (await running("dota2.exe"))) {
        throw new Error("Mi Dota se cerró pero hay otro dota2.exe abierto; paro sin tocarlo.");
      }
      // The custom game's per-minute timeline, from this launch's console.log (-condebug rewrites it each launch).
      const fecha = new Date().toISOString().slice(0, 16);
      let timeline = [];
      try {
        // A log older than this launch belongs to another match (Dota failed before rewriting it).
        if (statSync(consoleLog).mtimeMs >= started) timeline = parseTimeline(readFileSync(consoleLog, "utf8"));
      } catch {}
      if (timeline.length) {
        mkdirSync(TIMELINES, { recursive: true });
        writeFileSync(join(TIMELINES, `${opt.etiqueta}-${fecha.replace(/[-:T]/g, "")}-${i + 1}.csv`), timelineCsv(timeline));
      }
      const s = latest ?? {};
      const row = {
        fecha, etiqueta: opt.etiqueta, partida: i + 1, dificultad: opt.dificultad,
        dotabot, ganador: outcome === "final" ? s.winner : "", resultado: outcome,
        minutos: s.clock ? Math.round(s.clock / 60) : "", kills_radiant: s.radiantKills ?? "",
        kills_dire: s.direKills ?? "", humano: s.human ?? "", heroes: short,
        ...summarizeTimeline(timeline, dotabot),
      };
      appendFileSync(CSV, csvRow(row) + "\n");
      results.push(row);
      console.log(`  ${outcome}${row.ganador ? `: gana ${row.ganador} (${row.ganador === dotabot ? "dota-bot" : "Valve"})` : ""}`);
      if (outcome === "sin-gsi") { console.log("Dota no envió datos por GSI; paro."); break; }
      await sleep(8000);
    }
    const decided = results.filter((r) => r.resultado === "final");
    const ours = decided.filter((r) => r.ganador === r.dotabot).length;
    console.log(`dota-bot ganó ${ours} de ${decided.length} partidas terminadas (de ${results.length}). Detalle en bench/partidas.csv.`);
  } finally {
    cleanup();
  }
}

const self = fileURLToPath(import.meta.url).toLowerCase();
if (process.argv[1] && resolve(process.argv[1]).toLowerCase() === self) {
  main(process.argv.slice(2)).catch((e) => {
    console.error(e.message);
    process.exit(1);
  });
}
