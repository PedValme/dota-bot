#!/usr/bin/env python
"""A: unspent gold. Independent recompute, by series, by variant, by role, and secret shop purchases."""
import pickle, re, sys, collections
import numpy as np
G = pickle.load(open("games.pkl", "rb"))
SECRET = {"item_hyperstone","item_demon_edge","item_reaver","item_eagle","item_mystic_staff","item_ultimate_orb","item_sacred_relic","item_platemail","item_talisman_of_evasion","item_energy_booster","item_vitality_booster","item_point_booster","item_relic"}
def sides(g):
    d = 2 if g["r"]["dotabot"] == "radiant" else 3
    return d, 5 - d
def idle(g, t, team):
    gs = nw = n = 0
    for p, tm in g["team"].items():
        if tm == team and t in g["snap"][p]:
            s = g["snap"][p][t]; gs += s["gold"]; nw += s["nw"]; n += 1
    return (gs / nw, gs, nw) if n == 5 and nw else None
rows = collections.OrderedDict()
for g in G:
    r = g["r"]
    if r["valida"] != "si" or r.get("modo") != "turbo" or r["variante"].startswith("control_sniper"): continue
    a, b = sides(g)
    k = (r["fecha"][:10], r["etiqueta"], r["variante"] or "-", (r.get("codigo") or "")[:7])
    d = rows.setdefault(k, dict(n=0, a=[], b=[], sec=[], secfoe=[], mins=[], fails=0))
    d["n"] += 1
    x = idle(g, 1500, a); y = idle(g, 1500, b)
    if x: d["a"].append(x[0]); d["b"].append(y[0])
    upto = [q for q in g["buys"] if 0 <= q[0] <= 1200 and q[3] in SECRET]
    d["sec"].append(sum(1 for q in upto if g["team"].get(q[1]) == a))
    d["secfoe"].append(sum(1 for q in upto if g["team"].get(q[1]) == b))
    d["fails"] += len(g["fails"])
print("date series variant code n n25 idleA25 idleB25 secret_buys<=20min A B fails")
for k, d in rows.items():
    print(*k, d["n"], len(d["a"]), f"{100*np.mean(d['a']):.0f}" if d["a"] else "-", f"{100*np.mean(d['b']):.0f}" if d["b"] else "-", f"{np.mean(d['sec']):.1f} {np.mean(d['secfoe']):.1f}", d["fails"])
