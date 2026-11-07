#!/usr/bin/env python
"""A: who hoards, since when; sample of queues; variance by hero; within post-change games without hoarding; by game length."""
import pickle, re, sys, collections
import numpy as np
G = pickle.load(open("games.pkl", "rb"))
def sideA(g): return 2 if g["r"]["dotabot"] == "radiant" else 3
post = [g for g in G if g["r"]["valida"] == "si" and g["r"].get("modo") == "turbo" and g["r"]["fecha"] >= "2026-10-31T04:41" and g["r"]["variante"] != "base_sinturbo" and not g["r"]["variante"].startswith("control_sniper")]
pre = [g for g in G if g["r"]["valida"] == "si" and g["r"].get("modo") == "turbo" and g["r"]["fecha"] < "2026-10-31T04:41"]
print("post", len(post), "pre", len(pre))
# hero-level: post-change OHA team, min 25
H = collections.defaultdict(list); Hpre = collections.defaultdict(list); HV = collections.defaultdict(list)
game = []
for g in post:
    a = sideA(g)
    tot = gs = 0; ok = 0
    for p, tm in g["team"].items():
        s = g["snap"][p].get(1500)
        if not s: continue
        if tm == a:
            H[g["hero"][p]].append(s["gold"] / max(s["nw"], 1)); tot += s["nw"]; gs += s["gold"]; ok += 1
        elif g["r"].get("rival") == "valve":
            HV[g["hero"][p]].append(s["gold"] / max(s["nw"], 1))
    if ok == 5:
        game.append((gs / tot, tot, g["r"]["etiqueta"], g["r"]["partida"], g))
for g in pre:
    a = sideA(g)
    for p, tm in g["team"].items():
        s = g["snap"][p].get(1500)
        if s and tm == a: Hpre[g["hero"][p]].append(s["gold"] / max(s["nw"], 1))
print("hero post_n post_idle pre_n pre_idle  (min 25), top by n")
for h, v in sorted(H.items(), key=lambda x: -np.mean(x[1])):
    if len(v) >= 8:
        print(f"{h:20s} {len(v):4d} {100*np.mean(v):5.0f} {len(Hpre.get(h, [])):4d} {100*np.mean(Hpre.get(h, [0])):5.0f}   valve-team: {len(HV.get(h, []))} {100*np.mean(HV.get(h, [0])):.0f}")
game.sort(key=lambda x: x[0])
print("games post-change lowest idle:")
for x in game[:12]:
    r = x[4]["r"]
    print(f"{100*x[0]:5.1f}% nw={x[1]:6d} {x[2]} {x[3]} {r['variante']} lado={r['dotabot']} gan={r['ganador']} min={r['minutos']} heroes={r['heroes'][:60]}")
v = np.array([x[0] for x in game]); w = np.array([x[1] for x in game])
print("n", len(v), "pct: p5 %.0f p25 %.0f p50 %.0f p75 %.0f p95 %.0f" % tuple(100 * np.percentile(v, [5, 25, 50, 75, 95])), "corr idle vs team nw", np.corrcoef(v, w)[0, 1])
gold = np.array([x[0] * x[1] for x in game])
print("unspent gold abs mean", gold.mean(), "item nw mean", (w - gold).mean(), "corr gold-nw", np.corrcoef(gold, w)[0, 1], "corr items-nw", np.corrcoef(w - gold, w)[0, 1])
# time series of idle and item value by minute, pre vs post, per team, in matched minutes
for label, S in (("pre", pre), ("post", post)):
    for t in (300, 480, 600, 720, 900, 1200, 1500):
        I = []; Gd = []; N = []
        for g in S:
            a = sideA(g); ok = 0; gs = nw = 0
            for p, tm in g["team"].items():
                s = g["snap"][p].get(t)
                if s and tm == a: gs += s["gold"]; nw += s["nw"]; ok += 1
            if ok == 5: I.append(gs / nw); Gd.append(gs); N.append(nw)
        print(label, t, "n", len(I), f"idle {100*np.mean(I):.0f}% gold {np.mean(Gd):.0f} nw {np.mean(N):.0f} items {np.mean(N)-np.mean(Gd):.0f}")
# sample
for nm in ("fijo-oha-b",):
    g = [g for g in G if g["r"]["etiqueta"] == nm][0]
    a = sideA(g)
    print(g["name"])
    for p, tm in g["team"].items():
        if tm != a: continue
        b = [q for q in g["buys"] if q[1] == p and q[0] >= 300]
        print(" ", g["hero"][p], "gold", [g["snap"][p].get(t, {}).get("gold") for t in (600, 900, 1200, 1500)], "nw", g["snap"][p].get(1500, {}).get("nw"))
        print("    items25", g["snap"][p].get(1500, {}).get("items"))
        print("    buys", [(q[0], q[3].replace("item_", "")) for q in b][-14:])
