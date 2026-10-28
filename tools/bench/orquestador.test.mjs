import { test } from "node:test";
import assert from "node:assert/strict";
import { sides, launchArgs, gsiConfig, readGsi, isFinished, csvRow, TOKEN, PORT } from "./orquestador.mjs";

const post = (map, token = TOKEN) => ({ auth: { token }, map, player: { team_name: "radiant" } });

test("sides alternate and Valve always takes the other team", () => {
  assert.deepEqual(sides(0), { dotabot: "radiant", valveTeam: 3 });
  assert.deepEqual(sides(1), { dotabot: "dire", valveTeam: 2 });
  assert.deepEqual(sides(2), sides(0));
});

test("launch arguments start a local bot game and nothing else", () => {
  const a = launchArgs(4);
  assert.ok(a.includes("-gamestateintegration"));
  assert.equal(a[a.indexOf("+dota_bot_set_difficulty") + 1], "4");
  assert.equal(a[a.indexOf("+map") + 1], "dota");
  assert.ok(!a.some((x) => /connect|exec|quit|rcon/i.test(x)));
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
  assert.equal(row.split(",").length, 11);
  assert.ok(row.includes("a;b"));
});
