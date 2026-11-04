// Pedro plays against the own Sniper (DECISIONES 2026-11-04): leaves bots/Customize/bench_variant.lua, git-ignored, so in
// the next local lobby the bots of that team take the Sniper as position 2 (mid), played by FunLib/propio/, and the rest
// is OHA. Without the file every lobby plays as always. Delete it when done: while it exists, every local lobby plays so
// (the benchmark's orchestrator also deletes it when it starts).
//   node tools/jugar-sniper.mjs [dire|radiant]     the team of the Sniper (dire by default; you take the other one)
//   node tools/jugar-sniper.mjs quitar
import { existsSync, unlinkSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const file = fileURLToPath(new URL("../bots/Customize/bench_variant.lua", import.meta.url));
const side = process.argv[2] ?? "dire";
if (side === "quitar") {
  if (existsSync(file)) unlinkSync(file);
  console.log("Listo: los lobbies vuelven a jugar como siempre.");
} else if (side === "dire" || side === "radiant") {
  const team = side === "radiant" ? 2 : 3;
  writeFileSync(file, `-- written by tools/jugar-sniper.mjs; delete it with "node tools/jugar-sniper.mjs quitar"\nreturn { name = "lobby_sniper", lobby_mid = "npc_dota_hero_sniper", lobby_team = ${team}, control_completo = "sniper", linea_heroe = "sniper", empuje = false, thinkless = 1 }\n`);
  console.log(`Listo: el Sniper propio va en ${side}, en mid. Custom Lobby, servidor Local Host, Local Dev Script. Al acabar: node tools/jugar-sniper.mjs quitar`);
} else {
  console.log("Uso: node tools/jugar-sniper.mjs [dire|radiant|quitar]");
  process.exit(1);
}
