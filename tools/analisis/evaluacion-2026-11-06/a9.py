#!/usr/bin/env python
"""Fixed analysis of the new baseline (MEDICIONES, base2-*), per match and matchup. python -I a9.py <games.json> [prefix ...]"""
import json, sys, re, bisect, math, collections
import numpy as np
G = json.load(open(sys.argv[1]))
PRE = sys.argv[2:] or ["base2-"]
rng = np.random.default_rng(9)
T0, T1 = 720, 1500
def grid(g, pid):
    p = g["pos"].get(str(pid), []); ts = [x[0] for x in p]; out = {}
    for t in range(0, 1502, 4):
        i = bisect.bisect_left(ts, t); c = None
        for j in (i - 1, i):
            if 0 <= j < len(p) and abs(ts[j] - t) <= 3 and (c is None or abs(ts[j] - t) < abs(ts[c] - t)): c = j
        if c is not None: out[t] = p[c]
    return out
def D(a, b): return math.hypot(a[1] - b[1], a[2] - b[2])
rows = []
for g in G:
    if not any(g["etiqueta"].startswith(p) for p in PRE): continue
    pid, tm = g["pid"], g["team"]
    teams = {int(a): b for a, b in g["teams"].items()}
    al = [q for q, v in teams.items() if v == tm and q != pid]; fo = [q for q, v in teams.items() if v != tm]
    H = lambda q, t=1500: g["H"][str(q)].get(str(t))
    if H(pid) is None or any(H(q) is None for q in al + fo): print("skip", g["etiqueta"], g["partida"], g["resultado"]); continue
    l25 = next((x for x in g["linea"] if x["t"] >= 1500), None)
    s = H(pid); kills = l25["kills"] if l25 else s["k"]; deaths = l25["muertes"] if l25 else s["d"]
    tk = kills + sum(H(q)["k"] for q in al); fk = sum(H(q)["k"] for q in fo)
    dmg = sum(d[4] for d in g["dano"] if d[1] == "sniper" and T0 <= d[0] <= T1 and d[2] not in ("creep", "torre", "neutral"))
    recv = sum(d[4] for d in g["dano"] if d[2] == "sniper" and T0 <= d[0] <= T1 and d[1] not in ("creep", "torre", "neutral"))
    G_ = {q: grid(g, q) for q in al}; me = grid(g, pid); c = n = 0
    for t in range(T0, T1, 4):
        m = me.get(t)
        if m is None: continue
        n += 1; c += not any(G_[q].get(t) is not None and G_[q][t][4] and D(G_[q][t], m) <= 1500 for q in al)
    a, b = map(int, g["torres"].split("-")); tw = (a - b) if g["lado"] == "radiant" else (b - a)
    allnw = lambda qs: sum(H(q)["nw"] for q in qs); allg = lambda qs: sum(max(H(q)["gold"], 0) for q in qs)
    tot = s["nw"] + allnw(al)
    rows.append(dict(et=g["etiqueta"], part=g["partida"], arm="propio" if g["variante"].startswith("control") else "OHA", match=g["etiqueta"][-1] if g["etiqueta"][-2] == "-" and not g["etiqueta"].endswith(("-oha", "-propio")) else "a",
        lado=g["lado"][0], lh=s["lh"], k=kills, d=deaths, a=s["a"], kp=(kills + s["a"]) / max(tk, 1), nw=s["nw"], item=s["nw"] - max(s["gold"], 0), oro=max(s["gold"], 0),
        dmg=dmg, recv=recv, alone=100 * c / max(n, 1), tw=tw, tk=tk, fk=fk, td=tot - allnw(fo), itd=(tot - allg(al) - max(s["gold"], 0)) - (allnw(fo) - allg(fo)),
        idle_al=100 * allg(al) / allnw(al), idle_fo=100 * allg(fo) / allnw(fo), cpu=float(g["cpu"] or 0)))
K = ["lh", "k", "d", "a", "kp", "item", "oro", "dmg", "recv", "alone", "tw", "tk", "fk", "td", "itd", "idle_al", "idle_fo"]
print("et part arm lado | " + " ".join(K))
for r in sorted(rows, key=lambda r: (r["match"], r["arm"], r["et"], r["part"])):
    print(f"{r['et']:18s}{r['part']} {r['arm']:7s}{r['lado']} " + " ".join(f"{k}={r[k]:.2f}" if k == "kp" else f"{k}={r[k]:.0f}" for k in K))
def S(sel): return [r for r in rows if sel(r)]
print("\nMeans (sd)")
for name, sel in [("OHA todas", lambda r: r["arm"] == "OHA"), ("propio todas", lambda r: r["arm"] == "propio")] + [(f"{arm} {m}", (lambda a, m: lambda r: r["arm"] == a and r["match"] == m)(arm, m)) for m in "abc" for arm in ("OHA", "propio")]:
    x = S(sel)
    if not x: continue
    print(f"{name:14s} n={len(x):2d} " + " ".join(f"{k} {np.mean([r[k] for r in x]):.2f}" if k == "kp" else f"{k} {np.mean([r[k] for r in x]):.0f}" for k in K))
print("\nAmong-matchup balanced difference propio-OHA (mean of per-matchup differences) with bootstrap within matchup")
for k in K:
    def est(res=False):
        ds = []
        for m in "abc":
            a = np.array([r[k] for r in rows if r["arm"] == "propio" and r["match"] == m], float); b = np.array([r[k] for r in rows if r["arm"] == "OHA" and r["match"] == m], float)
            if len(a) == 0 or len(b) == 0: continue
            if res: a, b = rng.choice(a, len(a)), rng.choice(b, len(b))
            ds.append(a.mean() - b.mean())
        return float(np.mean(ds))
    bs = [est(True) for _ in range(5000)]
    print(f"{k:8s} {est():9.2f} [{np.percentile(bs,2.5):9.2f},{np.percentile(bs,97.5):9.2f}]")
print("\nA vs A, OHA matchup a: two runs of the same code")
for k in K:
    h = [r[k] for r in rows if r["et"] == "base2-humo-oha"]; n = [r[k] for r in rows if r["et"] == "base2-oha-a"]
    if h and n: print(f"{k:8s} humo {np.round(h,1).tolist()}  tanda {np.round(n,1).tolist()}")
print("\nWithin-matchup residual SD, by arm, and n per arm to see half the gap at 80 %")
for k in K:
    res = []
    for arm in ("OHA", "propio"):
        for m in "abc":
            v = np.array([r[k] for r in rows if r["arm"] == arm and r["match"] == m], float)
            if len(v) > 1: res += list(v - v.mean())
    sd = np.sqrt(np.sum(np.square(res)) / max(len(res) - 6, 1))
    a = np.mean([r[k] for r in rows if r["arm"] == "OHA"]); b = np.mean([r[k] for r in rows if r["arm"] == "propio"])
    print(f"{k:8s} sd {sd:9.2f} gap {b-a:9.2f}  n half gap {2*(2.8*sd/max(abs(b-a)/2,1e-9))**2:8.1f}")
print("\nOwn: intent share, min 12-25; secret direct purchase; Group")
for arm in ("propio",):
    c = collections.Counter(); n = 0
    for g in G:
        if any(g["etiqueta"].startswith(p) for p in PRE) and g["variante"].startswith("control"):
            for e in g["est"]:
                if T0 <= e[0] <= T1: c[e[1]] += 1; n += 1
    print(n, [(a, round(100 * b / max(n, 1), 1)) for a, b in c.most_common(12)])
