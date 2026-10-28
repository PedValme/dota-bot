import { test } from "node:test";
import assert from "node:assert/strict";
import { parseLine, splitMatches } from "./resumen.mjs";

const line = (event, me, t, rhp, dhp, extra = "") =>
  `[VScript] [BENCH] v=1 event=${event} me=${me} t=${t} real=1 rk=3 rd=4 rt=9 rhp=${rhp} dk=4 dd=3 dt=8 dhp=${dhp} rh=axe,lina dh=zuus,sniper${extra}`;

test("parses a bench line and ignores the rest of the console", () => {
  assert.equal(parseLine("Some other console output"), null);
  const r = parseLine(line("tick", 2, 600, 4500, 4500));
  assert.equal(r.event, "tick");
  assert.equal(r.me, 2);
  assert.equal(r.t, 600);
  assert.equal(r.rh, "axe,lina");
});

test("one team logging against Valve: winner from the end line", () => {
  const recs = [line("start", 2, 0, 4500, 4500), line("tick", 2, 1500, 4500, 300), line("end", 2, 1530, 4200, 0)].map(parseLine);
  const [m] = splitMatches(recs);
  assert.equal(m.radiant, "dota-bot");
  assert.equal(m.dire, "valve");
  assert.equal(m.winner, "radiant");
  assert.equal(m.winnerScript, "dota-bot");
  assert.equal(m.how, "final");
  assert.equal(m.minutes, 26);
});

test("no end line: winner inferred from a dead Ancient, unknown otherwise", () => {
  const inferred = splitMatches([line("start", 3, 0, 4500, 4500), line("tick", 3, 1800, 0, 2000)].map(parseLine));
  assert.equal(inferred[0].winner, "dire");
  assert.equal(inferred[0].winnerScript, "dota-bot");
  assert.equal(inferred[0].how, "inferido");
  const open = splitMatches([line("start", 3, 0, 4500, 4500), line("tick", 3, 900, 4500, 4500)].map(parseLine));
  assert.equal(open[0].winner, "?");
  const probable = splitMatches([line("start", 2, 0, 4500, 4500), line("tick", 2, 2000, 4100, 400)].map(parseLine));
  assert.equal(probable[0].winner, "radiant");
  assert.equal(probable[0].how, "probable");
  const close = splitMatches([line("start", 2, 0, 4500, 4500), line("tick", 2, 2000, 1200, 1400)].map(parseLine));
  assert.equal(close[0].winner, "?");
});

test("a match keeps its id when saved before and after it ends", () => {
  const start = line("start", 2, 0, 4500, 4500);
  const half = splitMatches([start, line("tick", 2, 900, 4500, 4500)].map(parseLine));
  const done = splitMatches([start, line("tick", 2, 900, 4500, 4500), line("end", 2, 1600, 3000, 0)].map(parseLine));
  assert.equal(half[0].id, done[0].id);
});

test("swapping sides between matches starts a new match", () => {
  const recs = [line("start", 2, 0, 4500, 4500), line("end", 2, 1500, 0, 800), line("start", 3, 0, 4500, 4500)].map(parseLine);
  const ms = splitMatches(recs);
  assert.equal(ms.length, 2);
  assert.equal(ms[1].dire, "dota-bot");
  assert.equal(ms[1].radiant, "valve");
});

test("splits consecutive matches and merges both teams' lines of one match", () => {
  const recs = [
    line("start", 2, 0, 4500, 4500), line("start", 3, 0, 4500, 4500), line("end", 2, 1200, 0, 900),
    line("start", 2, 0, 4500, 4500, " real=900"), line("end", 2, 1300, 800, 0),
  ].map(parseLine);
  const ms = splitMatches(recs);
  assert.equal(ms.length, 2);
  assert.equal(ms[0].radiant, "dota-bot");
  assert.equal(ms[0].dire, "dota-bot");
  assert.equal(ms[0].winner, "dire");
  assert.equal(ms[1].dire, "valve");
  assert.equal(ms[1].winner, "radiant");
  assert.notEqual(ms[0].id, ms[1].id);
});
