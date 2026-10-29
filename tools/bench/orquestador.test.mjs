import { test } from "node:test";
import assert from "node:assert/strict";
import { schedule, launchArgs, gsiConfig, readGsi, isFinished, csvRow, drawHeroes, matchConfigLua, HERO_POOL, TOKEN, PORT,
  parseTimeline, summarizeTimeline, timelineCsv, parseRoster, parseVariant, parseVersion, validity, variantLua,
  VARIANTS, summarize } from "./orquestador.mjs";

const post = (map, token = TOKEN) => ({ auth: { token }, map, player: { team_name: "radiant" } });

test("without variants, sides alternate (flipping every block) and Valve always takes the other team", () => {
  const s = [0, 1, 2, 3].map((i) => schedule(i, []));
  assert.deepEqual(s.map((x) => x.dotabot), ["radiant", "dire", "dire", "radiant"]);
  for (const x of s) assert.equal(x.valveTeam, x.dotabot === "radiant" ? 3 : 2);
  assert.equal(s[0].variant, "");
});

test("with variants, every block plays each variant once per side and flips the order", () => {
  const vs = ["base", "empuje"];
  const s = Array.from({ length: 8 }, (_, i) => schedule(i, vs));
  for (const b of [0, 1]) {
    const blk = s.filter((x) => x.block === b);
    assert.equal(blk.length, 4);
    for (const v of vs) for (const side of ["radiant", "dire"]) {
      assert.equal(blk.filter((x) => x.variant === v && x.dotabot === side).length, 1);
    }
  }
  assert.deepEqual(s.slice(0, 4).map((x) => `${x.variant}-${x.dotabot}`), ["base-radiant", "empuje-radiant", "base-dire", "empuje-dire"]);
  assert.deepEqual(s.slice(4).map((x) => `${x.variant}-${x.dotabot}`), ["empuje-dire", "base-dire", "empuje-radiant", "base-radiant"]);
});

test("the variant file is plain Lua data with the variant's fields", () => {
  assert.equal(variantLua("base").split("\n")[1], 'return { name = "base", empuje = false, thinkless = 1 }');
  assert.equal(VARIANTS.thinkless0.thinkless, 0);
});

test("a match counts only if it ended, 5v5 bots, human out, the right variant and the same Dota", () => {
  const ok = { outcome: "final", roster: { radiant: 5, dire: 5, humano: "fuera" }, variant: "base", loggedVariant: "base",
    version: "6969", firstVersion: "6969" };
  assert.equal(validity(ok), "");
  assert.equal(validity({ ...ok, roster: { ...ok.roster, humano: "heroe-quitado" } }), "");
  assert.match(validity({ ...ok, outcome: "timeout" }), /final/);
  assert.match(validity({ ...ok, roster: { ...ok.roster, radiant: 6 } }), /reparto 6-5/);
  assert.match(validity({ ...ok, roster: { ...ok.roster, humano: "en-equipo" } }), /humano/);
  assert.match(validity({ ...ok, roster: { ...ok.roster, humano: "" } }), /humano/);
  assert.match(validity({ ...ok, loggedVariant: null }), /variante/);
  assert.match(validity({ ...ok, loggedVariant: "empuje" }), /variante/);
  assert.equal(validity({ ...ok, variant: "", loggedVariant: "" }), "");
  assert.match(validity({ ...ok, variant: "", loggedVariant: null }), /variante/);
  assert.match(validity({ ...ok, version: "6970" }), /versión/);
});

test("the summary counts only complete, fully valid blocks", () => {
  const row = (bloque, variante, valida, win) => ({ bloque, variante, valida, dotabot: "radiant", ganador: win ? "radiant" : "dire" });
  const results = [
    row(1, "base", "si", true), row(1, "empuje", "si", true), row(1, "base", "si", false), row(1, "empuje", "si", true),
    row(2, "empuje", "si", true), row(2, "base", "no", false), row(2, "empuje", "si", true), row(2, "base", "si", true),
  ];
  assert.deepEqual(summarize(results, ["base", "empuje"]), [
    { variante: "base", ganadas: 1, validas: 2, jugadas: 4 },
    { variante: "empuje", ganadas: 2, validas: 2, jugadas: 4 },
  ]);
});

test("the variant and Dota's version are read from the log and steam.inf", () => {
  assert.equal(parseVariant("x\n[VScript] [dotabench] variant name=base empuje=false thinkless=1\n"), "base");
  assert.equal(parseVariant("[VScript] [dotabench] variant none"), "");
  assert.equal(parseVariant("nothing"), null);
  assert.equal(parseVersion("ClientVersion=6969\r\nServerVersion=6969\r\n"), "6969");
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
  assert.equal(row.split(",").length, 23);
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
  assert.equal(timelineCsv(rows).split("\n")[0], "min,rk,dk,rt,dt,rb,db,rhp,dhp,rnw,dnw,rc,dc,event");
});

const roster = (team, pid, bot, hero) =>
  `10/29 12:26:40 [VScript] [dotabench] roster team=${team} pid=${pid} bot=${bot} hero=npc_dota_hero_${hero} name=Bot ${pid}`;

test("the roster tells the real heroes, the team sizes and whether the human played a slot", () => {
  const clean = [roster(2, 1, 1, "luna"), roster(2, 2, 1, "razor"), roster(3, 6, 1, "viper")].join("\r\n");
  assert.deepEqual(parseRoster(clean), { humano: "fuera", heroes: "luna razor / viper", radiant: 2, dire: 1 });
  const removed = ["[VScript] [dotabench] human hero removed pid=0 team=2 npc_dota_hero_phantom_assassin", clean].join("\n");
  assert.equal(parseRoster(removed).humano, "heroe-quitado");
  assert.equal(parseRoster([clean, roster(2, 0, 0, "phantom_assassin")].join("\n")).humano, "en-equipo");
  assert.deepEqual(parseRoster("no roster here"), { humano: "", heroes: "", radiant: 0, dire: 0 });
});
