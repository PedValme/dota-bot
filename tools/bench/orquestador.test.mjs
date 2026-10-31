import { test } from "node:test";
import assert from "node:assert/strict";
import { schedule, launchArgs, gsiConfig, readGsi, isFinished, csvRow, drawHeroes, matchConfigLua, HERO_POOL, TOKEN, PORT,
  parseTimeline, summarizeTimeline, timelineCsv, parseRoster, parseVariant, parseVersion, validity, parseStart, parseCouriers, codeState, tooManyInvalid, variantLua,
  VARIANTS, summarize, parseModo, observationLines, rivalSchedule, rivalVariantLua, rivalName } from "./orquestador.mjs";

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

test("dota-bot against dota-bot: pairs swap sides on one draw, the start flips each pair, rows from a's side", () => {
  const s = [0, 1, 2, 3].map((i) => rivalSchedule(i, ["cerebro", "base"]));
  assert.deepEqual(s.map((x) => `${x.radiant}/${x.dire}`), ["cerebro/base", "base/cerebro", "base/cerebro", "cerebro/base"]);
  assert.deepEqual(s.map((x) => x.dotabot), ["radiant", "dire", "dire", "radiant"]);
  assert.deepEqual(s.map((x) => x.block), [0, 0, 1, 1]);
  for (const x of s) assert.equal(x.variant, "cerebro");
  const lua = rivalVariantLua("cerebro", "base");
  assert.match(lua, /name = "cerebro-vs-base", teams = \{ \[2\] = \{ name = "cerebro", cerebro = true, thinkless = 1 \}, \[3\] = \{ name = "base", empuje = false, thinkless = 1 \} \}/);
  assert.equal(rivalName("a", "b"), "a-vs-b");
});

test("the variant file is plain Lua data with the variant's fields", () => {
  assert.equal(variantLua("base").split("\n")[1], 'return { name = "base", empuje = false, thinkless = 1 }');
  assert.equal(VARIANTS.thinkless0.thinkless, 0);
});

test("a match counts only if it ended, 5v5 bots, human out, the right variant and the same Dota", () => {
  const start = { radiant: 5, dire: 5, mismos: true, nwRadiant: 3005, nwDire: 3005, heroGap: 20 };
  const ok = { outcome: "final", roster: { radiant: 5, dire: 5, humano: "fuera", mismos: true, viejos: 0 }, variant: "base",
    loggedVariant: "base", version: "6969", firstVersion: "6969", modo: "normal", loggedModo: "normal", start,
    codigo: "abc123", firstCodigo: "abc123", couriers: { radiant: 5, dire: 5, slowRadiant: 290, slowDire: 290 } };
  assert.match(validity({ ...ok, couriers: undefined }), /couriers 0-0/);
  assert.match(validity({ ...ok, couriers: { ...ok.couriers, dire: 3 } }), /couriers 5-3/);
  assert.match(validity({ ...ok, modo: "turbo", loggedModo: "turbo" }), /couriers lentos 290-290/);
  assert.equal(validity({ ...ok, modo: "turbo", loggedModo: "turbo",
    couriers: { radiant: 5, dire: 5, slowRadiant: 1100, slowDire: 1100 } }), "");
  assert.match(validity({ ...ok, outcome: "tope" }), /tope de 60 min/);
  assert.match(validity({ ...ok, codigo: "abc123+cambios" }), /código sin commit/);
  assert.match(validity({ ...ok, codigo: undefined }), /código sin commit/);
  assert.match(validity({ ...ok, codigo: "def456" }), /cambió en la serie/);
  assert.match(validity({ ...ok, loggedModo: undefined }), /modo/);
  assert.equal(validity(ok), "");
  assert.match(validity({ ...ok, roster: { ...ok.roster, mismos: false } }), /héroes distintos/);
  assert.match(validity({ ...ok, roster: { ...ok.roster, mismos: undefined } }), /héroes distintos/);
  assert.match(validity({ ...ok, start: { ...start, mismos: false } }), /héroes distintos/);
  assert.match(validity({ ...ok, start: undefined }), /inicio/);
  assert.match(validity({ ...ok, start: { ...start, dire: 4 } }), /inicio/);
  assert.match(validity({ ...ok, start: { ...start, nwDire: 1030 } }), /patrimonio inicial 3005-1030/);
  assert.match(validity({ ...ok, start: { ...start, heroGap: 145 } }), /de un héroe \(diferencia 145\)/);
  assert.match(validity({ ...ok, start: { ...start, heroGap: undefined } }), /de un héroe/);
  assert.equal(validity({ ...ok, start: { ...start, nwDire: 2800 } }), "");
  assert.match(validity({ ...ok, espejo: "no" }), /espejo apagado/);
  assert.match(validity({ ...ok, roster: { ...ok.roster, viejos: 1 } }), /sin borrar \(1\)/);
  assert.match(validity({ ...ok, roster: { ...ok.roster, viejos: undefined } }), /sin borrar/);
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
    row(2, "empuje", "si", true), { ...row(2, "base", "no", false), resultado: "tope" }, row(2, "empuje", "si", true), row(2, "base", "si", true),
  ];
  assert.deepEqual(summarize(results, ["base", "empuje"]), [
    { variante: "base", ganadas: 1, validas: 2, jugadas: 4, topes: 1 },
    { variante: "empuje", ganadas: 2, validas: 2, jugadas: 4, topes: 0 },
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
  assert.match(lua, /return \{ difficulty = "unfair", timescale = 4, turbo = false, observar = false, heroes = \{ "npc_dota_hero_axe", "npc_dota_hero_lina" \} \}/);
  assert.match(matchConfigLua(["x"], 0, 1), /difficulty = "passive"/);
  assert.match(matchConfigLua(["x"], 4, 4, true), /turbo = true/);
  assert.match(matchConfigLua(["x"], 4, 4), /observar = false/);
  assert.match(matchConfigLua(["x"], 4, 4, true, true), /observar = true/);
});

test("observer mode keeps the custom game's lines and the engine's bot lines, nothing else", () => {
  const log = [
    "10/29 22:41:21 [VScript] [dotabench] obs t=30 buy pid=1 lion item_tango cost=90",
    "10/29 22:45:38 [VScript] Script Runtime Error: error in error handling",
    "10/29 22:41:36 Script function 'GetDesire' on bot npc_dota_hero_witch_doctor took 29.029ms",
    "10/29 22:46:26 [Server] Client (account 0) tried to execute invalid order (37). Item can't be used from stash.",
    "10/29 22:45:59 Building: npc_dota_goodguys_tower1_mid destroyed at 725.300049.",
    "10/30 00:40:00 Attempting to call GetNearbyHeroes() on enemies when filtering by bot mode!",
    "10/30 00:40:01 [VScript] [WARN] Ability build failed",
    "10/29 22:45:37 **** Panel  has fill-parent-flow for width",
    "10/29 22:45:40 [Localization System] CLocalize::FindSafe failed to localize: 'invalid index'",
  ].join("\r\n");
  const kept = observationLines(log).trim().split("\n");
  assert.equal(kept.length, 7);
  assert.ok(!kept.some((l) => /Panel|Localization/.test(l)));
});

test("the mode the custom game applied is read from the log and must match the series", () => {
  assert.equal(parseModo("[VScript] [dotabench] turbo on gold=2 xp=2 respawn=0.75 couriers=turbo"), "turbo");
  assert.equal(parseModo("[VScript] [dotabench] turbo off"), "normal");
  assert.equal(parseModo("nothing"), "");
  const ok = { outcome: "final", roster: { radiant: 5, dire: 5, humano: "fuera", mismos: true, viejos: 0 }, variant: "", loggedVariant: "",
    version: "1", firstVersion: "1", start: { radiant: 5, dire: 5, mismos: true, nwRadiant: 3005, nwDire: 3005, heroGap: 0 },
    codigo: "a", firstCodigo: "a", couriers: { radiant: 5, dire: 5, slowRadiant: 1100, slowDire: 1100 } };
  assert.equal(validity({ ...ok, modo: "turbo", loggedModo: "turbo" }), "");
  assert.match(validity({ ...ok, modo: "turbo", loggedModo: "normal" }), /modo/);
  assert.match(validity({ ...ok, modo: "turbo", loggedModo: "" }), /modo/);
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
  assert.equal(row.split(",").length, 26);
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
  assert.deepEqual(parseRoster(clean), { humano: "fuera", heroes: "luna razor / viper", radiant: 2, dire: 1, mismos: false, viejos: 0 });
  const removed = ["[VScript] [dotabench] human hero removed pid=0 team=2 npc_dota_hero_phantom_assassin", clean].join("\n");
  assert.equal(parseRoster(removed).humano, "heroe-quitado");
  assert.equal(parseRoster([clean, roster(2, 0, 0, "phantom_assassin")].join("\n")).humano, "en-equipo");
  assert.deepEqual(parseRoster("no roster here"), { humano: "", heroes: "", radiant: 0, dire: 0, mismos: false });
});

test("each match records its commit, marked when bots/ had uncommitted changes; too many invalid stops a series", () => {
  assert.equal(codeState("0123456789abcdef\n", ""), "0123456789ab");
  assert.equal(codeState("0123456789abcdef\n", " M bots/x.lua\n"), "0123456789ab+cambios");
  const rows = (bad, total) => Array.from({ length: total }, (_, i) => ({ valida: i < bad ? "no" : "si" }));
  assert.equal(tooManyInvalid(rows(2, 4)), false);
  assert.equal(tooManyInvalid(rows(1, 5)), false);
  assert.equal(tooManyInvalid(rows(2, 5)), true);
  assert.equal(tooManyInvalid(rows(2, 10)), false);
  assert.equal(tooManyInvalid(rows(3, 10)), true);
  assert.deepEqual(VARIANTS.base_b, VARIANTS.base);
});

test("couriers alive per team at minute 1, with the slowest speed per side", () => {
  const line = (team, n, speeds) => `[VScript] [dotabench] couriers team=${team} n=${n} speeds=${speeds}`;
  assert.deepEqual(parseCouriers([line(2, 5, "1100/1100/1100/1100/1100"), line(3, 4, "1100/1100/290/1100")].join("\r\n")),
    { radiant: 5, dire: 4, slowRadiant: 1100, slowDire: 290 });
  assert.deepEqual(parseCouriers(line(3, 0, "")), { radiant: 0, dire: 0, slowRadiant: 0, slowDire: 0 });
});

test("the start line tells the heroes really controlled and each team's starting net worth", () => {
  const line = (team, pid, hero, nw) => `[VScript] [dotabench] start team=${team} pid=${pid} hero=npc_dota_hero_${hero} nw=${nw}`;
  const log = [line(2, 1, "luna", 601), line(2, 2, "razor", 600), line(3, 6, "razor", 11), line(3, 7, "luna", 511)].join("\r\n");
  assert.deepEqual(parseStart(log), { radiant: 2, dire: 2, mismos: true, nwRadiant: 1201, nwDire: 522, heroGap: 589 });
  assert.equal(parseStart([line(2, 1, "luna", 601), line(3, 6, "none", 0)].join("\n")).mismos, false);
  assert.equal(parseStart([line(2, 1, "none", 0), line(3, 6, "none", 0)].join("\n")).mismos, false);
  assert.equal(parseStart([line(2, 1, "luna", 601), line(3, 6, "viper", 601)].join("\n")).mismos, false);
  assert.equal(parseStart("nothing").mismos, false);
});

test("the mirror replaces Dire's random heroes; only the same five per side count as mismos", () => {
  const mirror = (pid, from, to, ok = "true") =>
    `[VScript] [dotabench] mirror slot=1 pid=${pid} npc_dota_hero_${from} -> npc_dota_hero_${to} ok=${ok}  now=npc_dota_hero_${to} refund=145 gold=601 restock=-`;
  const base = [roster(2, 1, 1, "luna"), roster(2, 2, 1, "razor"), roster(3, 6, 1, "viper"), roster(3, 7, 1, "lina")];
  const gone = (pid) => `[VScript] [dotabench] mirror_old pid=${pid} removed=true`;
  const both = [...base, mirror(6, "viper", "razor"), mirror(7, "lina", "luna"), gone(6), gone(7)].join("\n");
  assert.deepEqual(parseRoster(both), { humano: "fuera", heroes: "luna razor / razor luna", radiant: 2, dire: 2, mismos: true,
    viejos: 0 });
  const stayed = [...base, mirror(6, "viper", "razor"), mirror(7, "lina", "luna"), gone(6),
    "[VScript] [dotabench] mirror_old pid=7 removed=false"].join("\n");
  assert.equal(parseRoster(stayed).viejos, 1);
  const half = [...base, mirror(6, "viper", "razor")].join("\n");
  assert.equal(parseRoster(half).mismos, false);
  const failed = [...base, mirror(6, "viper", "razor"), mirror(7, "lina", "luna", "false")].join("\n");
  assert.equal(parseRoster(failed).mismos, false);
});
