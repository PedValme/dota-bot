import { test } from "node:test";
import assert from "node:assert/strict";
import { sides, launchArgs, gsiConfig, readGsi, isFinished, csvRow, drawHeroes, matchConfigLua, HERO_POOL, TOKEN, PORT,
  parseTimeline, summarizeTimeline, timelineCsv } from "./orquestador.mjs";

const post = (map, token = TOKEN) => ({ auth: { token }, map, player: { team_name: "radiant" } });

test("sides alternate and Valve always takes the other team", () => {
  assert.deepEqual(sides(0), { dotabot: "radiant", valveTeam: 3 });
  assert.deepEqual(sides(1), { dotabot: "dire", valveTeam: 2 });
  assert.deepEqual(sides(2), sides(0));
});

test("launch arguments start the local benchmark custom game and nothing else", () => {
  const a = launchArgs();
  assert.ok(a.includes("-gamestateintegration"));
  assert.deepEqual(a.slice(a.indexOf("+dota_launch_custom_game") + 1, a.indexOf("+dota_launch_custom_game") + 3), ["dotabench", "dota"]);
  assert.ok(!a.some((x) => /connect|exec|quit|rcon|-w$|-h$|windowed/i.test(x)));
});

test("both teams get the same five heroes, one per position, from the pool", () => {
  const heroes = drawHeroes(() => 0.999);
  assert.equal(heroes.length, 5);
  heroes.forEach((h, i) => assert.equal(h, "npc_dota_hero_" + HERO_POOL[i].at(-1)));
  assert.equal(new Set(drawHeroes()).size, 5);
});

test("the match config is plain Lua data for the custom game", () => {
  const lua = matchConfigLua(["npc_dota_hero_axe", "npc_dota_hero_lina"], 4, 4);
  assert.match(lua, /return \{ difficulty = "unfair", timescale = 4, heroes = \{ "npc_dota_hero_axe", "npc_dota_hero_lina" \} \}/);
  assert.match(matchConfigLua(["x"], 0, 1), /difficulty = "passive"/);
});

test("the GSI config posts only to localhost with the token", () => {
  const c = gsiConfig();
  assert.match(c, new RegExp(`"uri"\\s+"http://127\\.0\\.0\\.1:${PORT}/"`));
  assert.match(c, new RegExp(`"token"\\s+"${TOKEN}"`));
});

test("GSI posts without our token or a map are ignored", () => {
  assert.equal(readGsi(post({ game_state: "x" }, "other")), null);
  assert.equal(readGsi({ auth: { token: TOKEN } }), null);
  assert.equal(readGsi(null), null);
});

test("a finished match needs post-game and a winner", () => {
  const playing = readGsi(post({ game_state: "DOTA_GAMERULES_STATE_GAME_IN_PROGRESS", win_team: "none", clock_time: 600 }));
  assert.equal(isFinished(playing), false);
  assert.equal(playing.winner, null);
  const over = readGsi(post({ game_state: "DOTA_GAMERULES_STATE_POST_GAME", win_team: "dire", clock_time: 1980, radiant_score: 21, dire_score: 35 }));
  assert.equal(isFinished(over), true);
  assert.equal(over.winner, "dire");
  assert.equal(over.direKills, 35);
  assert.equal(over.human, "radiant");
});

test("CSV rows keep their columns", () => {
  const row = csvRow({ fecha: "2026-10-28T19:00", etiqueta: "a,b", partida: 1, dotabot: "radiant", ganador: "dire" });
  assert.equal(row.split(",").length, 15);
  assert.ok(row.includes("a;b"));
});

const tl = (event, min, rnw, dnw, rt = 11, dt = 11) =>
  `10/29 10:00:00 [VScript] [dotabench] timeline event=${event} min=${min} rk=1 dk=2 rt=${rt} dt=${dt} rb=6 db=6 rhp=4500 dhp=4500 rnw=${rnw} dnw=${dnw}`;

test("the custom game's timeline lines are parsed and the rest of the log ignored", () => {
  const rows = parseTimeline(["noise", tl("minute", 0, 3000, 3000), "more noise", tl("end", 40, 60000, 45000, 7, 2)].join("\r\n"));
  assert.equal(rows.length, 2);
  assert.deepEqual(rows[1], { event: "end", min: 40, rk: 1, dk: 2, rt: 7, dt: 2, rb: 6, db: 6, rhp: 4500, dhp: 4500, rnw: 60000, dnw: 45000 });
});

test("the summary is from dota-bot's side", () => {
  const rows = parseTimeline([tl("minute", 10, 20000, 15000), tl("minute", 20, 40000, 29000), tl("end", 30, 50000, 52000, 3, 5)].join("\n"));
  assert.deepEqual(summarizeTimeline(rows, "radiant"), { ventaja_oro_max: 11000, minuto_10k: 20, torres_fin: "3-5" });
  assert.deepEqual(summarizeTimeline(rows, "dire"), { ventaja_oro_max: 2000, minuto_10k: "", torres_fin: "3-5" });
  assert.deepEqual(summarizeTimeline([], "dire"), { ventaja_oro_max: "", minuto_10k: "", torres_fin: "" });
  assert.equal(timelineCsv(rows).split("\n")[0], "min,rk,dk,rt,dt,rb,db,rhp,dhp,rnw,dnw,event");
});
