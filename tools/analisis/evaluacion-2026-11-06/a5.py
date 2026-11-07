#!/usr/bin/env python
"""Why OHA stops spending, unspent gold over time in full matches, deaths alone, human lobbies, metric sensitivity, CI of the damage decomposition."""
import json, sys, re, os, collections, bisect, math, csv
import numpy as np
from math import comb
exec(open(os.path.join(os.path.dirname(os.path.abspath(sys.argv[0])), "a4_lib.py")).read())
repo = sys.argv[2]
rng = np.random.default_rng(5)
OBS = os.path.join(repo, "bench", "observaciones")

print("### OHA Sniper: last purchases and final items at min 25 (fijo-oha)")
for f in sorted(os.listdir(OBS)):
    if f.startswith("fijo-oha-") and f.endswith(".log"):
        last = []; items = None
        for l in open(os.path.join(OBS, f), encoding="latin1"):
            m = re.search(r"obs t=(\d+) buy pid=2 sniper (\S+)", l)
            if m: last.append((int(m[1]), m[2]))
            m = re.search(r"obs t=(\d+) hero pid=2 team=\d sniper .* items=(\S*)", l)
            if m: items = (int(m[1]), m[2])
        print(f, "last buys", last[-6:], "\n   items", items)
print("Sample raw buy lines:")
f = sorted(x for x in os.listdir(OBS) if x.startswith("fijo-oha-a"))[0]
n = 0
for l in open(os.path.join(OBS, f), encoding="latin1"):
    if " buy " in l and "obs t=" in l and n < 3:
        print("  ", l.strip()[:160]); n += 1

print("\n### Unspent gold over time in full matches, clean bench, OHA team vs Valve team (mean per team)")
rows = list(csv.DictReader(open(os.path.join(repo, "bench", "series.csv"), encoding="utf-8", errors="replace")))
HERO = re.compile(r"obs t=(-?\d+) hero pid=(\d+) team=(\d) (\S+) lvl=(\d+) gold=(-?\d+) nw=(\d+)")
acc = collections.defaultdict(list)
for r in rows:
    if r.get("valida") != "si" or r.get("resultado") != "final" or r.get("rival") != "valve" or r["variante"] not in ("base", "base_b", "base_sniper") or r["fecha"] < "2026-11-01": continue
    path = os.path.join(OBS, f"{r['etiqueta']}-{re.sub(r'[-:T]', '', r['fecha'])}-{r['partida']}.log")
    if not os.path.exists(path): continue
    side = 2 if r["dotabot"] == "radiant" else 3
    T = collections.defaultdict(lambda: [[0, 0, 0], [0, 0, 0]])
    for l in open(path, encoding="latin1"):
        if " hero pid=" not in l: continue
        m = HERO.search(l)
        if not m: continue
        t = int(m[1])
        if t % 300: continue
        i = 0 if int(m[3]) == side else 1
        T[t][i][0] += int(m[6]); T[t][i][1] += int(m[7]); T[t][i][2] += 1
    win = r["ganador"] == r["dotabot"]
    for t, v in T.items():
        if v[0][2] == 5 and v[1][2] == 5:
            acc[(t // 60, win)].append((v[0][0], v[0][1], v[1][0], v[1][1]))
print("min  result   n   OHA gold  OHA NW  OHA%idle | Valve gold Valve NW  V%idle | item lead")
for (t, w), v in sorted(acc.items()):
    if t < 10 or t > 40 or len(v) < 3: continue
    v = np.array(v, float)
    print(f"{t:3d} {'win ' if w else 'loss'} {len(v):4d} {v[:,0].mean():9.0f} {v[:,1].mean():8.0f} {100*v[:,0].sum()/v[:,1].sum():6.0f}% | {v[:,2].mean():9.0f} {v[:,3].mean():9.0f} {100*v[:,2].sum()/v[:,3].sum():5.0f}% | {(v[:,1]-v[:,0]-v[:,3]+v[:,2]).mean():9.0f}")

print("\n### Own Sniper's deaths vs OHA's: alone? (all min 12-25) allies within 1500 / foes within 1500, 4 s before the death")
for k, p in SETS.items():
    gs = games(p); al_n = []; fo_n = []; loc = collections.Counter(); deaths = 0
    for g in gs:
        teams = {int(a): b for a, b in g["teams"].items()}
        al = [q for q, v in teams.items() if v == g["team"] and q != g["pid"]]
        fo = [q for q, v in teams.items() if v != g["team"]]
        G_ = {q: grid(g, q) for q in teams}
        for x in g["kills"]:
            if x["vpid"] != g["pid"] or x["t"] < 720 or x["t"] > 1500: continue
            t = (x["t"] - 4) // 2 * 2
            me = G_[g["pid"]].get(t)
            if me is None: continue
            deaths += 1
            al_n.append(sum(1 for q in al if G_[q].get(t) is not None and G_[q][t][4] and D(G_[q][t], me) <= 1500))
            fo_n.append(sum(1 for q in fo if G_[q].get(t) is not None and G_[q][t][4] and D(G_[q][t], me) <= 1500))
    print(f"{k:18s} deaths {deaths:3d}  per match {deaths/len(gs):.2f}  no ally near {100*np.mean(np.array(al_n)==0) if al_n else 0:4.0f}%  allies {np.mean(al_n) if al_n else 0:.2f}  foes {np.mean(fo_n) if fo_n else 0:.2f}")
print("\nTime alone (no ally within 1500), min 12-25")
for k, p in SETS.items():
    per = []
    for g in games(p):
        teams = {int(a): b for a, b in g["teams"].items()}
        al = [q for q, v in teams.items() if v == g["team"] and q != g["pid"]]
        Gq = {q: grid(g, q) for q in al}; me = grid(g, g["pid"]); c = n = 0
        for t in range(720, 1500, 4):
            m = me.get(t)
            if m is None: continue
            n += 1; c += not any(Gq[q].get(t) is not None and Gq[q][t][4] and D(Gq[q][t], m) <= 1500 for q in al)
        per.append(100 * c / max(n, 1))
    print(f"{k:18s} alone {np.mean(per):5.1f}%  sd {np.std(per, ddof=1):4.1f}")

print("\n### Human lobbies: ally proximity from mode lines (own bot's prop pos)")
MODE = re.compile(r"\[bench\] mode t=(-?\d+) pid=(\d+) (\S+) (\S+) (-?[\d.]+) alive=(\d) hp=([\d.]+) amenaza=([\d.]+) x=(-?\d+) y=(-?\d+)")
POS = re.compile(r"prop pos t=(-?[\d.]+) pid=(\d+) x=(-?\d+) y=(-?\d+)")
for f in sorted(x for x in os.listdir(OBS) if x.startswith("lobby")):
    pos = collections.defaultdict(list); teams = {}
    lines = open(os.path.join(OBS, f), encoding="latin1").read().splitlines()
    for l in lines:
        m = MODE.search(l)
        if m: pos[int(m[2])].append((int(m[1]), int(m[9]), int(m[10]), float(m[7]), int(m[6])))
        m = POS.search(l)
        if m: pos[int(m[2])].append((float(m[1]), int(m[3]), int(m[4]), None, 1))
        m = re.search(r"\[bench\] load pid=(\d+) team=(\d)", l)
        if m: teams[int(m[1])] = int(m[2])
    print(f, "pids with positions", {k: len(v) for k, v in pos.items()}, "teams", teams, "decisions", sum(" prop decision" in l for l in lines))
    c = collections.Counter()
    for l in lines:
        m = re.search(r"prop estado t=(-?[\d.]+) pid=\d+ intencion=(\S+)", l)
        if m and float(m[1]) >= 720: c[m[2]] += 1
    tot = sum(c.values())
    print("  intent min 12+:", [(a, round(100 * b / tot)) for a, b in c.most_common(9)])

print("\n### Sensitivity: which metric separates OHA and own at min 25, per n needed at the observed gap (80 %)")
F = json.load(open(sys.argv[3]))
def co(rows, k): return np.array([r[k] for r in rows if k in r], float)
Ofi = [f for f in F if re.fullmatch(r"fijo-oha-[ab]", f["et"])]; Pfi = [f for f in F if re.fullmatch(r"fijo-p[25]-[ab]", f["et"])]
Oso = [f for f in F if f["et"] == "presion-oha"]; Pso = [f for f in F if re.fullmatch(r"presion[67]", f["et"])]
def tw(fr):
    out = []
    for f in fr:
        g = next(g for g in G if g["etiqueta"] == f["et"] and g["partida"] == f["part"])
        a, b = map(int, g["torres"].split("-"))
        f["tower_diff"] = (a - b) if f["lado"] == "radiant" else (b - a)
    return fr
for fr in (Ofi, Pfi, Oso, Pso): tw(fr)
for k in ["tower_diff", "kp_25", "k_share_25", "s_k_25", "s_nw_25", "s_lh_25", "s_d_25", "t_kdiff_25", "al_d_25", "fo_nw_25"]:
    a, b = np.concatenate([co(Ofi, k), co(Oso, k)]), np.concatenate([co(Pfi, k), co(Pso, k)])
    sa, sb = a.std(ddof=1), b.std(ddof=1)
    sp = math.sqrt((sa ** 2 + sb ** 2) / 2)
    gap = a.mean() - b.mean()
    print(f"{k:12s} OHA {a.mean():9.2f}  own {b.mean():9.2f}  gap {gap:8.2f}  SDp {sp:8.2f}  d={abs(gap)/sp:4.2f}  n/arm {2*(2.8*sp/max(abs(gap),1e-9))**2:7.1f}")

print("\nCI of damage decomposition (bootstrap of matches, fight damage per attended fight, attendance, damage outside episodes)")
def per_match(p):
    r = []
    for g in games(p):
        e = attend(g)
        tot = sum(d[4] for d in g["dano"] if d[1] == "sniper" and 720 <= d[0] <= 1500 and d[2] not in ("creep", "torre", "neutral"))
        att = [x for x in e if x["arr"] is not None]
        r.append((len(e), len(att), sum(x["dd"] for x in att), sum(x["dd"] for x in e), tot))
    return np.array(r, float)
for k, p in SETS.items():
    m = per_match(p)
    def s(a): return np.array([a[:, 1].sum() / a[:, 0].sum(), a[:, 2].sum() / a[:, 1].sum(), max(a[:, 4].sum() - a[:, 3].sum(), 0) / len(a)])
    bs = np.array([s(m[rng.integers(0, len(m), len(m))]) for _ in range(5000)])
    lo, hi = np.percentile(bs, [2.5, 97.5], axis=0); v = s(m)
    print(f"{k:18s} attendance {100*v[0]:4.0f}% [{100*lo[0]:3.0f},{100*hi[0]:3.0f}]  dmg/attended {v[1]:6.0f} [{lo[1]:6.0f},{hi[1]:6.0f}]  dmg outside fights/match {v[2]:6.0f} [{lo[2]:6.0f},{hi[2]:6.0f}]")

print("\nFisher exact, full games vs Valve, base_sniper 4/11 vs control_sniper 1/13")
def fisher(a, b, c, d):
    n = a + b + c + d; r = a + b; k = a + c
    p0 = comb(r, a) * comb(n - r, k - a) / comb(n, k); tot = 0
    for x in range(max(0, k - (n - r)), min(r, k) + 1):
        p = comb(r, x) * comb(n - r, k - x) / comb(n, k)
        if p <= p0 + 1e-12: tot += p
    return tot
print(round(fisher(4, 7, 1, 12), 3))
print("Base OHA vs Valve clean, 19/49, Wilson 95%:")
n, x = 49, 19; z = 1.96; ph = x / n; den = 1 + z * z / n; c = (ph + z * z / (2 * n)) / den; h = z * math.sqrt(ph * (1 - ph) / n + z * z / (4 * n * n)) / den; print(round(c - h, 3), round(c + h, 3))

print("\n### Runes picked by Sniper and allies by min 10 and min 25, by arm (rune=5 bounty; others power)")
for name, pat in [("conf1 own", r"conf1-[abc]|control"), ("conf1 OHA", r"conf1-[abc]|base")]:
    label, var = pat.split("|")
    va = "control_sniper" if var == "control" else "base_sniper"
    b10 = []; p10 = []; a10 = []; ab10 = []
    for g in G:
        if not re.fullmatch(label, g["etiqueta"]) or g["variante"] != va: continue
        path = os.path.join(OBS, f"{g['etiqueta']}-{re.sub(r'[-:T]', '', g['fecha'])}-{g['partida']}.log")
        teams = {int(a): b for a, b in g["teams"].items()}
        s_b = s_p = a_b = a_p = 0
        for l in open(path, encoding="latin1"):
            m = re.search(r"obs t=(\d+) rune pid=(\d+) \S+ rune=(\d+)", l)
            if not m: continue
            t, pid, rt = int(m[1]), int(m[2]), int(m[3])
            if t == 0 or t > 600: continue
            if pid == g["pid"]:
                if rt == 5: s_b += 1
                else: s_p += 1
            elif teams.get(pid) == g["team"]:
                if rt == 5: a_b += 1
                else: a_p += 1
        b10.append(s_b); p10.append(s_p); a10.append(a_p); ab10.append(a_b)
    print(name, "n", len(b10), "Sniper bounty", np.mean(b10), "power", np.mean(p10), "| allies bounty", np.mean(ab10), "power", np.mean(a10))
