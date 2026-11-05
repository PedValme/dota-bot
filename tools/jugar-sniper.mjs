// Pedro plays against the own Sniper (DECISIONES 2026-11-04): leaves bots/Customize/bench_variant.lua and bench_observe.lua,
// git-ignored, so in the next local lobby the bots of that team take the Sniper as position 2 (mid), played by
// FunLib/propio/, and the rest is OHA; and starts Dota with its console log on, so the match can be reviewed. "quitar"
// keeps the bots' lines of that log in bench/observaciones/ and deletes both files: while they exist, every local lobby
// plays so (the benchmark's orchestrator also deletes them when it starts). Only the bots' lines: no chat, no players.
//   node tools/jugar-sniper.mjs [dire|radiant]     the team of the Sniper (dire by default; you take the other one)
//   node tools/jugar-sniper.mjs quitar
import { execFileSync, spawn } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, statSync, unlinkSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { observationLines } from "./bench/orquestador.mjs";

const root = fileURLToPath(new URL("..", import.meta.url));
const variant = join(root, "bots", "Customize", "bench_variant.lua");
const observe = join(root, "bots", "Customize", "bench_observe.lua");
const dota = "C:/Program Files (x86)/Steam/steamapps/common/dota 2 beta";
const exe = resolve(dota, "game/bin/win64/dota2.exe");
const consoleLog = resolve(dota, "game/dota/console.log");
const running = (image) => execFileSync("tasklist", ["/FI", `IMAGENAME eq ${image}`, "/FO", "CSV", "/NH"]).toString().toLowerCase().includes(`"${image}"`);

const side = process.argv[2] ?? "dire";
if (side === "quitar") {
  // The log of the match just played: only if the lobby's files were there, and it is newer than them.
  if (existsSync(observe) && existsSync(consoleLog) && statSync(consoleLog).mtimeMs >= statSync(observe).mtimeMs) {
    const text = readFileSync(consoleLog, "latin1");
    if (text.includes("[bench] prop ")) {
      const out = join(root, "bench", "observaciones", `lobby-${new Date().toISOString().slice(0, 16).replace(/[-:T]/g, "")}.log`);
      mkdirSync(dirname(out), { recursive: true });
      writeFileSync(out, observationLines(text), "latin1");
      console.log(`Registro de la partida: ${out}`);
    } else console.log("El registro no tiene líneas del Sniper propio: no lo guardo.");
  }
  for (const f of [variant, observe]) if (existsSync(f)) unlinkSync(f);
  console.log("Listo: los lobbies vuelven a jugar como siempre.");
} else if (side === "dire" || side === "radiant") {
  const team = side === "radiant" ? 2 : 3;
  writeFileSync(variant, `-- written by tools/jugar-sniper.mjs; delete it with "node tools/jugar-sniper.mjs quitar"\nreturn { name = "lobby_sniper", lobby_mid = "npc_dota_hero_sniper", lobby_team = ${team}, control_completo = "sniper", linea_heroe = "sniper", empuje = false, thinkless = 1 }\n`);
  writeFileSync(observe, `-- written by tools/jugar-sniper.mjs; delete it with "node tools/jugar-sniper.mjs quitar"\nreturn true\n`);
  if (running("dota2.exe")) {
    console.log("Dota ya está abierto: la partida no dejará registro. Ciérralo y vuelve a correr esto si lo quieres.");
  } else {
    if (!running("steam.exe")) { console.log("Abre Steam primero y vuelve a correr esto."); process.exit(1); }
    spawn(exe, ["-console", "-condebug", "-novid"], { cwd: dirname(exe), detached: true, stdio: "ignore" }).unref();
    console.log("Abriendo Dota con su registro activado.");
  }
  console.log(`Listo: el Sniper propio va en ${side}, en mid. Custom Lobby, servidor Local Host, Local Dev Script en los dos equipos. Al acabar y con Dota cerrado: node tools/jugar-sniper.mjs quitar`);
} else {
  console.log("Uso: node tools/jugar-sniper.mjs [dire|radiant|quitar]");
  process.exit(1);
}
