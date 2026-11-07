#!/usr/bin/env python
"""Why WithTeam did not bring the own Sniper to the group (equipo1-*): is there a group, how far, what does it do instead. python -I a10.py <games.json>"""
import json, sys, re, bisect, math, collections
import numpy as np
G = json.load(open(sys.argv[1]))
T0, T1 = 720, 1500
def track(g, pid):
    p = g["pos"].get(str(pid), []); return [x[0] for x in p], p
def at(tr, t):
    ts, p = tr
    i = bisect.bisect_left(ts, t); c = None
    for j in (i - 1, i):
        if 0 <= j < len(p) and abs(ts[j] - t) <= 3 and (c is None or abs(ts[j] - t) < abs(ts[c] - t)): c = j
    return p[c] if c is not None else None
def D(a, b): return math.hypot(a[1] - b[1], a[2] - b[2])
for name, pat in [("base2-propio", r"base2-(humo-)?propio.*"), ("equipo1", r"equipo1-.*"), ("OHA base2", r"base2-(humo-)?oha.*")]:
    tot = grp = 0; near = 0; dist = []; intent_g = collections.Counter(); intent_n = collections.Counter(); hp = []; grp3 = 0; dur = []; intent_far = collections.Counter()
    hop = 0
    for g in G:
        if not re.fullmatch(pat, g["etiqueta"]): continue
        teams = {int(a): b for a, b in g["teams"].items()}
        al = [q for q, v in teams.items() if v == g["team"] and q != g["pid"]]
        T = {q: track(g, q) for q in al}; me = track(g, g["pid"])
        ets = [e[0] for e in g["est"]]
        prev = None; run = 0
        for t in range(T0, T1, 4):
            m = at(me, t)
            if m is None: continue
            P = {q: at(T[q], t) for q in al}; P = {q: v for q, v in P.items() if v is not None and v[4]}
            best = None; bn = 1
            for q, v in P.items():
                n = sum(1 for w in P.values() if D(v, w) < 900)
                if n > bn: best, bn = v, n
            tot += 1
            i = min(bisect.bisect_left(ets, t), len(ets) - 1) if ets else None
            it = g["est"][i][1] if ets else "-"
            if best is None:
                intent_n[it] += 1
                if prev: dur.append(run); run = 0
                prev = False
                continue
            grp += 1; grp3 += bn >= 3
            if prev is True:
                run += 4
            else:
                run = 4
            prev = True
            d = D(best, m); dist.append(d); near += d <= 1500
            intent_g[it] += 1
            if d > 1500: intent_far[it] += 1
    if not tot: continue
    print(f"\n{name}: group (>=2 allies within 900) exists {100*grp/tot:.0f}% of time (>=3: {100*grp3/tot:.0f}%); typical episode {np.median(dur) if dur else 0:.0f} s, p90 {np.percentile(dur,90) if dur else 0:.0f} s, n={len(dur)}; within 1500 of it {100*near/max(grp,1):.0f}% ; median distance {np.median(dist):.0f}; p90 {np.percentile(dist,90):.0f}")
    s = sum(intent_g.values()); print("  intent with group:", [(a, round(100 * b / max(s, 1))) for a, b in intent_g.most_common(8)])
    s = sum(intent_far.values()); print("  intent with group, farther than 1500:", [(a, round(100 * b / max(s, 1))) for a, b in intent_far.most_common(8)])
    s = sum(intent_n.values()); print("  intent no group:", [(a, round(100 * b / max(s, 1))) for a, b in intent_n.most_common(6)])
# What decides con_el_grupo: reasons and where
for g in G:
    if g["etiqueta"].startswith("equipo1-a") and g["partida"] == "1":
        ms = [d for d in g["dec"] if d[1] in ("con_el_grupo", "teleporte") and T0 <= d[0] <= T1]
        print("\nSample decisions:", [(round(d[0]), d[1][:6], d[2][:32]) for d in ms[:18]])
