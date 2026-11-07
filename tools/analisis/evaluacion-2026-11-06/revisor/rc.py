#!/usr/bin/env python
"""B AUC, E fights (alive fix), F iteration, G empirical joint bar, H batch."""
import pickle, re, sys, collections, bisect, math, itertools, csv
import numpy as np
G = pickle.load(open("games.pkl", "rb"))
rng = np.random.default_rng(9)
def A(g): return 2 if g["r"]["dotabot"] == "radiant" else 3
def valid(g): return g["r"]["valida"] == "si"
def auc(x, y):
    x = np.asarray(x, float); y = np.asarray(y, int)
    p, n = x[y == 1], x[y == 0]
    if not len(p) or not len(n): return float("nan")
    return float(np.mean([(a > n).mean() + .5 * (a == n).mean() for a in p]))
# ---------- B
F = []
for g in G:
    r = g["r"]
    if not valid(g) or r["fecha"] < "2026-11-01" or r.get("rival") != "valve" or r["resultado"] not in ("final", "tope"): continue
    a = A(g)
    side = "radiant" if a == 2 else "dire"
    win = int(r["ganador"] == side)
    d = dict(win=win, g=g, mins=int(r["minutos"] or 0), var=r["variante"], side=side, block=(r["etiqueta"], r["bloque"]))
    for t in (600, 900, 1200, 1500):
        A_ = [s[t] for p, s in g["snap"].items() if g["team"][p] == a and t in s]; B_ = [s[t] for p, s in g["snap"].items() if g["team"][p] != a and t in s]
        if len(A_) == 5 and len(B_) == 5:
            nwa, nwb = sum(x["nw"] for x in A_), sum(x["nw"] for x in B_)
            ga, gb = sum(x["gold"] for x in A_), sum(x["gold"] for x in B_)
            d[f"nw{t}"] = nwa - nwb; d[f"it{t}"] = (nwa - ga) - (nwb - gb); d[f"k{t}"] = sum(x["k"] for x in A_) - sum(x["k"] for x in B_); d[f"idle{t}"] = ga / nwa; d[f"goldA{t}"] = ga
    F.append(d)
print("B: games", len(F), "wins", sum(f["win"] for f in F), "side wins", collections.Counter((f["side"], f["win"]) for f in F))
print("  ended before min 25:", sum(1 for f in F if "nw1500" not in f), "of which wins", sum(f["win"] for f in F if "nw1500" not in f), "| tope", sum(1 for f in F if f["g"]["r"]["resultado"] == "tope"))
for t in (600, 900, 1200, 1500):
    rows = [f for f in F if f"nw{t}" in f]
    print(f"  t={t//60} n={len(rows)} wins={sum(f['win'] for f in rows)} AUC nw {auc([f[f'nw{t}'] for f in rows],[f['win'] for f in rows]):.3f} item {auc([f[f'it{t}'] for f in rows],[f['win'] for f in rows]):.3f} kills {auc([f[f'k{t}'] for f in rows],[f['win'] for f in rows]):.3f} idleA {auc([-f[f'idle{t}'] for f in rows],[f['win'] for f in rows]):.3f}")
# ITT: games that ended before 25 win count as top-rank / loss as bottom
for key in ("nw", "it", "k"):
    x = []; y = []
    for f in F:
        if f"{key}1500" in f: x.append(f[f"{key}1500"]); y.append(f["win"])
        else: x.append(1e9 if f["win"] else -1e9); y.append(f["win"])
    print("  ITT AUC min25", key, round(auc(x, y), 3))
rows = [f for f in F if "nw1500" in f]
# clustered bootstrap by block
bl = collections.defaultdict(list)
for f in rows: bl[f["block"]].append(f)
keys = list(bl)
for key in ("nw", "it", "k"):
    bs = []
    for _ in range(1000):
        pick = [bl[keys[i]] for i in rng.integers(0, len(keys), len(keys))]
        s = [f for p in pick for f in p]
        bs.append(auc([f[f"{key}1500"] for f in s], [f["win"] for f in s]))
    print(f"  cluster boot CI {key}: [{np.nanpercentile(bs,2.5):.2f},{np.nanpercentile(bs,97.5):.2f}]  blocks {len(keys)}")
# strata
for lbl, cond in (("base only", lambda f: f["var"] in ("base", "base_b")), ("cerebro_v3", lambda f: f["var"].startswith("cerebro_v3")), ("base_sniper", lambda f: f["var"] == "base_sniper"), ("control_sniper", lambda f: f["var"] == "control_sniper"), ("radiant", lambda f: f["side"] == "radiant"), ("dire", lambda f: f["side"] == "dire")):
    s = [f for f in rows if cond(f)]
    if s: print(f"  {lbl:14s} n={len(s)} wins={sum(f['win'] for f in s)} nw {auc([f['nw1500'] for f in s],[f['win'] for f in s]):.3f} item {auc([f['it1500'] for f in s],[f['win'] for f in s]):.3f} k {auc([f['k1500'] for f in s],[f['win'] for f in s]):.3f}")
# item within nw band: does hoarding add once nw controlled?
for lo, hi in ((-1e9, 0), (0, 10000), (10000, 20000), (20000, 1e9)):
    s = [f for f in rows if lo <= f["nw1500"] < hi]
    print(f"  nw25 in [{lo:.0f},{hi:.0f}) n={len(s)} wins={sum(f['win'] for f in s)} auc(item|band) {auc([f['it1500'] for f in s],[f['win'] for f in s]):.2f} idleA win {np.mean([f['idle1500'] for f in s if f['win']]) if any(f['win'] for f in s) else 0:.2f} loss {np.mean([f['idle1500'] for f in s if not f['win']]) if any(not f['win'] for f in s) else 0:.2f}")
print("  corr nw25 vs item25", round(np.corrcoef([f["nw1500"] for f in rows], [f["it1500"] for f in rows])[0, 1], 2), " mean min remaining after 25:", round(np.mean([f["mins"] - 25 for f in rows]), 1), "median mins of wins", np.median([f["mins"] for f in rows if f["win"]]), "losses", np.median([f["mins"] for f in rows if not f["win"]]))
# block-paired concordance: among pairs in a same block with different outcomes, does the higher lead win?
for key in ("nw", "it", "k"):
    c = n = 0
    for fs in bl.values():
        for a, b in itertools.combinations(fs, 2):
            if a["win"] != b["win"]:
                n += 1; w, l = (a, b) if a["win"] else (b, a)
                c += (w[f"{key}1500"] > l[f"{key}1500"]) + .5 * (w[f"{key}1500"] == l[f"{key}1500"])
    print(f"  within-block concordance {key}: {c/n:.3f} (pairs {n})")
# ---------- E
def grid(pts, step=2):
    ts = [p[0] for p in pts]; out = {}
    if not ts: return out
    for t in range(0, 1502, step):
        i = bisect.bisect_left(ts, t); c = None
        for j in (i - 1, i):
            if 0 <= j < len(pts) and abs(ts[j] - t) <= 3 and (c is None or abs(ts[j] - t) < abs(ts[c] - t)): c = j
        if c is not None: out[t] = pts[c]
    return out
def fights(g):
    a = A(g); sn = [p for p, tm in g["team"].items() if tm == a and g["hero"][p] == "sniper"][0]
    M = collections.defaultdict(list)
    for m in g["modes"]:
        M[m[1]].append((m[0], m[4], m[5], m[3], m[2]))
    for k in M: M[k].sort(key=lambda z: z[0])
    al = [p for p, tm in g["team"].items() if tm == a and p != sn]; fo = [p for p, tm in g["team"].items() if tm != a]
    GA = {p: grid(M[p]) for p in al}; GF = {p: grid(M[p]) for p in fo}
    prop = g["r"]["variante"].startswith("control")
    me_pts = sorted([(q[0], q[2], q[3], 1, "") for q in g["pos"] if q[1] == sn], key=lambda z: z[0]) if prop else M[sn]
    me = grid(me_pts)
    secs = []
    for t in range(720, 1501, 2):
        pts = []; na = set(); nf = set()
        for x in al:
            u = GA[x].get(t)
            if not u or not u[3]: continue
            for y in fo:
                v = GF[y].get(t)
                if not v or not v[3]: continue
                if math.hypot(u[1] - v[1], u[2] - v[2]) <= 1000:
                    na.add(x); nf.add(y); pts.append(((u[1] + v[1]) / 2, (u[2] + v[2]) / 2))
        if pts: secs.append((t, np.mean([q[0] for q in pts]), np.mean([q[1] for q in pts]), len(na), len(nf)))
    E = []; cur = []
    for s in secs:
        if cur and s[0] - cur[-1][0] > 8: E.append(cur); cur = []
        cur.append(s)
    if cur: E.append(cur)
    E = [e for e in E if e[-1][0] - e[0][0] >= 6]
    # alive by snapshots & kills: sniper dead windows from kills + respawn approximated by next pos or mode alive
    dt = collections.Counter(); rec = collections.Counter()
    for d in g["dano"]:
        if d[1] == "sniper" and d[2] != "sniper": dt[d[0]] += d[4]
        if d[2] == "sniper": rec[d[0]] += d[4]
    res = []
    for e in E:
        t0, t1 = e[0][0], e[-1][0]; big = max(x[3] + x[4] for x in e)
        att = False; att_alive = False; miss = 0; cov = 0
        for t, x, y, _, _ in e:
            m = me.get(t)
            if m is None: miss += 1; continue
            cov += 1
            if math.hypot(m[1] - x, m[2] - y) <= 1400:
                att = True
                if m[3]: att_alive = True
        dd = sum(v for t, v in dt.items() if t0 - 2 <= t <= t1 + 10)
        res.append(dict(big=big, att=att, att_alive=att_alive, dd=dd, miss=miss, n=len(e), dur=t1 - t0))
    dtot = sum(v for t, v in dt.items() if 720 <= t <= 1500); rtot = sum(v for t, v in rec.items() if 720 <= t <= 1500)
    rtot_h = sum(d[4] for d in g["dano"] if d[2] == "sniper" and 720 <= d[0] <= 1500 and d[1] not in ("creep", "torre", "neutral"))
    deadmode = sum(1 for z in me_pts if 720 <= z[0] <= 1500 and not z[3])
    return res, dtot, rtot, rtot_h, deadmode, len([z for z in me_pts if 720 <= z[0] <= 1500])
ST = {"OHA a": r"fijo-oha-a", "OHA b": r"fijo-oha-b", "p2p5 a": r"fijo-p[25]-a", "p2p5 b": r"fijo-p[25]-b", "OHA sort": r"presion-oha", "p6p7": r"presion[67]"}
print("\nE: set n bigFights att(raw) att(alive) dmg/att(raw) dmg/att(alive) dmgTot recvTot recvHeroes medianposlines deadmode")
store = {}
for k, pat in ST.items():
    gs = [g for g in G if valid(g) and re.fullmatch(pat, g["r"]["etiqueta"]) and g["r"].get("corte") == "25"]
    R = [fights(g) for g in gs]; store[k] = R
    big = [e for r in R for e in r[0] if e["big"] >= 3]
    aa = [e for e in big if e["att"]]; bb = [e for e in big if e["att_alive"]]
    print(f"{k:9s} n={len(R)} big={len(big):3d} att {100*len(aa)/max(len(big),1):3.0f}% attA {100*len(bb)/max(len(big),1):3.0f}% dmg/att {np.mean([e['dd'] for e in aa]) if aa else 0:6.0f} alive {np.mean([e['dd'] for e in bb]) if bb else 0:6.0f} dmgTot {np.mean([r[1] for r in R]):6.0f} recv {np.mean([r[2] for r in R]):6.0f} recvH {np.mean([r[3] for r in R]):6.0f} lines {np.median([r[5] for r in R]):4.0f} deadlines {np.mean([r[4] for r in R]):4.1f} missfrac {np.mean([e['miss']/e['n'] for e in big]):.2f} perGame recv {[r[2] for r in R]}")
for lbl, a, b in (("OHA fijo vs p2p5", ("OHA a", "OHA b"), ("p2p5 a", "p2p5 b")), ("OHA sort vs p6p7", ("OHA sort",), ("p6p7",))):
    def attend(keys):
        out = []
        for k in keys:
            for r in store[k]:
                big = [e for e in r[0] if e["big"] >= 3]
                out.append(sum(e["att_alive"] for e in big) / max(len(big), 1))
        return np.array(out)
    x, y = attend(a), attend(b)
    z = np.r_[x, y]; o = abs(x.mean() - y.mean()); c = 0
    for _ in range(20000):
        rng.shuffle(z); c += abs(z[:len(x)].mean() - z[len(x):].mean()) >= o - 1e-9
    print(f"  attendance alive per game {lbl}: {x.mean():.2f} vs {y.mean():.2f} perm p {c/20000:.3f}")
# sniper dead coverage in propio: are pos lines present while dead?
for pat, lbl in ((r"fijo-p[25]-[ab]", "prop"), (r"fijo-oha-[ab]", "OHA")):
    gaps = []; tot = 0
    for g in G:
        if not (valid(g) and re.fullmatch(pat, g["r"]["etiqueta"])): continue
        a = A(g); sn = [p for p, tm in g["team"].items() if tm == a and g["hero"][p] == "sniper"][0]
        ts = sorted(q[0] for q in g["pos"] if q[1] == sn) if lbl == "prop" else sorted(m[0] for m in g["modes"] if m[1] == sn)
        deaths = [k[0] for k in g["kills"] if k[3] == sn]
        for d in deaths:
            n = sum(1 for t in ts if d + 2 <= t <= d + 10)
            gaps.append(n)
        tot += len(ts)
    print(f"  {lbl}: pos lines in [death+2, death+10]: mean {np.mean(gaps) if gaps else 0:.1f} (4 would mean no gap) deaths {len(gaps)} lines/game {tot/4 if lbl=='OHA' else tot/12:.0f}")
# modo share
md = collections.Counter(); fr = collections.Counter()
for g in G:
    if valid(g) and re.fullmatch(r"fijo-p[25]-[ab]|presion[67]", g["r"]["etiqueta"]):
        for e in g["est"]:
            if e[0] > 0: md[e[4]] += 1
print("  propio modo counter", md.most_common(5))
# ---------- D push with forward fill
print("\nD push>=2 allies, 2s grid nearest")
def push(g):
    a = A(g); sn = [p for p, tm in g["team"].items() if tm == a and g["hero"][p] == "sniper"][0]
    al = [p for p, tm in g["team"].items() if tm == a and p != sn]; fo = [p for p, tm in g["team"].items() if tm != a]
    M = collections.defaultdict(list)
    for m in g["modes"]: M[m[1]].append((m[0], m[2]))
    Gr = {p: grid(sorted(M[p], key=lambda z: z[0])) for p in al + fo}
    n = pa = pf = 0
    for t in range(720, 1500, 2):
        n += 1
        pa += sum(1 for p in al if Gr[p].get(t, (0, ""))[1].startswith("PUSH")) >= 2
        pf += sum(1 for p in fo if Gr[p].get(t, (0, ""))[1].startswith("PUSH")) >= 2
    return pa / n, pf / n
for k, pat in ST.items():
    gs = [g for g in G if valid(g) and re.fullmatch(pat, g["r"]["etiqueta"]) and g["r"].get("corte") == "25"]
    v = np.array([push(g) for g in gs])
    print(f"  {k:9s} n={len(gs)} allies>=2 push {100*v[:,0].mean():4.0f}% rival>=2 push {100*v[:,1].mean():4.0f}%  per game {np.round(100*v[:,0]).astype(int).tolist()}")
# ---------- F
print("\nF iteration")
order = ["presion-propio", "presion2", "presion3", "presion4", "presion5", "presion6", "presion7", "presion8", "fijo-p1", "fijo-p2", "fijo-p3", "fijo-p4", "fijo-p5"]
R = []
for i, nm in enumerate(order):
    for g in G:
        et = g["r"]["etiqueta"]
        if valid(g) and (et == nm or et.startswith(nm + "-")) and g["r"].get("corte") == "25" and g["r"].get("rival") == "dotabot":
            a = A(g); sn = [p for p, tm in g["team"].items() if tm == a and g["hero"][p] == "sniper"][0]
            s = g["snap"][sn].get(1500)
            if not s: continue
            hs = g["r"]["heroes"]; dt = sum(d[4] for d in g["dano"] if d[1] == "sniper" and d[2] != "sniper" and 720 <= d[0] <= 1500)
            parts = [set(x.split()) for x in hs.split(" / ")]
            key = "|".join(sorted(" ".join(sorted(x)) for x in parts))
            R.append(dict(i=i, nm=nm, block=key, lh=s["lh"], k=s["k"], d=s["d"], nw=s["nw"], dmg=dt, ta=sum(g["snap"][p][1500]["k"] for p in g["team"] if g["team"][p] == a and 1500 in g["snap"][p])))
print("  n games", len(R), "blocks", len({r['block'] for r in R}), "codes", len({r['i'] for r in R}))
def slope(rows, key):
    x = np.array([r["i"] for r in rows], float); y = np.array([r[key] for r in rows], float)
    return np.polyfit(x, y, 1)[0]
for key in ("lh", "k", "d", "nw", "dmg"):
    b = slope(R, key)
    # cluster bootstrap by (block)
    B = collections.defaultdict(list)
    for r in R: B[r["block"]].append(r)
    ks = list(B); bs = []
    for _ in range(3000):
        s = [r for i in rng.integers(0, len(ks), len(ks)) for r in B[ks[i]]]
        if len({r["i"] for r in s}) > 1: bs.append(slope(s, key))
    lo, hi = np.percentile(bs, [2.5, 97.5])
    se = np.std(bs)
    y = np.array([r[key] for r in R], float)
    # within-block (fixed effects): demean by block; only blocks with >1 code carry information
    Ms = {k: np.mean([r[key] for r in v]) for k, v in B.items()}; Mx = {k: np.mean([r["i"] for r in v]) for k, v in B.items()}
    xw = np.array([r["i"] - Mx[r["block"]] for r in R], float); yw = np.array([r[key] - Ms[r["block"]] for r in R], float)
    bw = (xw * yw).sum() / (xw ** 2).sum(); res = yw - bw * xw
    nb = len(ks); dof = max(len(R) - nb - 1, 1); seW = math.sqrt((res ** 2).sum() / dof / (xw ** 2).sum())
    # only fijo: FE by set
    sd = y.std(ddof=1); mean = y.mean()
    print(f"  {key:4s} mean {mean:7.1f} sd {sd:7.1f} | pooled slope {b:7.2f} clusterCI [{lo:7.2f},{hi:7.2f}] | MDE(80%) over 12 steps {2.8*se*12:8.1f} ({100*2.8*se*12/abs(mean):.0f}% of mean) | blockFE slope {bw:7.2f} se {seW:6.2f} info-rows {sum(1 for r in R if abs(r['i']-Mx[r['block']])>0)}")
# fijo only: set FE, codes as categories; F test for 'code matters'
fi = [r for r in R if r["nm"].startswith("fijo")]
print("  fijo codes per set means:", {(n,): (sum(1 for r in fi if r['nm']==n), round(np.mean([r['lh'] for r in fi if r['nm']==n]),0), round(np.mean([r['k'] for r in fi if r['nm']==n]),1), round(np.mean([r['d'] for r in fi if r['nm']==n]),1)) for n in order[8:]})
for key in ("lh", "k", "d", "dmg"):
    y = np.array([r[key] for r in fi], float); codes = sorted({r["nm"] for r in fi}); sets = sorted({r["block"] for r in fi})
    X = np.zeros((len(fi), 1 + len(sets) - 1 + len(codes) - 1))
    X[:, 0] = 1
    for j, s in enumerate(sets[1:]): X[:, 1 + j] = [r["block"] == s for r in fi]
    X0 = X[:, :len(sets)]
    for j, c in enumerate(codes[1:]): X[:, len(sets) + j] = [r["nm"] == c for r in fi]
    rs0 = ((y - X0 @ np.linalg.lstsq(X0, y, rcond=None)[0]) ** 2).sum(); rs1 = ((y - X @ np.linalg.lstsq(X, y, rcond=None)[0]) ** 2).sum()
    Fv = ((rs0 - rs1) / (len(codes) - 1)) / (rs1 / (len(fi) - X.shape[1]))
    # permutation of code labels within set
    cnt = 0; N = 5000
    lab = np.array([r["nm"] for r in fi]); st = np.array([r["block"] for r in fi])
    for _ in range(N):
        L = lab.copy()
        for s in sets:
            idx = np.where(st == s)[0]; L[idx] = rng.permutation(L[idx])
        for j, c in enumerate(codes[1:]): X[:, len(sets) + j] = L == c
        rs = ((y - X @ np.linalg.lstsq(X, y, rcond=None)[0]) ** 2).sum()
        cnt += ((rs0 - rs) / (rs / (len(fi) - X.shape[1]))) >= ((rs0 - rs1) / (rs1 / (len(fi) - X.shape[1]))) - 1e-9
    print(f"  fijo {key:4s} F(code|set)={Fv:.2f} permutation p={cnt/N:.3f} n={len(fi)} residSD={math.sqrt(rs1/(len(fi)-X.shape[1])):.1f}")
# ---------- H
print("\nH p2 vs p5")
for key in ("lh", "k", "d", "nw", "dmg", "ta"):
    a = [r[key] for r in R if r["nm"] == "fijo-p2"]; b = [r[key] for r in R if r["nm"] == "fijo-p5"]
    z = np.array(a + b, float); o = np.mean(a) - np.mean(b); ge = tot = 0
    for c in itertools.combinations(range(len(z)), len(a)):
        m = np.zeros(len(z), bool); m[list(c)] = True; tot += 1
        ge += abs(z[m].mean() - z[~m].mean()) >= abs(o) - 1e-9
    print(f"  {key:4s} p2 {np.mean(a):8.1f} {a} p5 {np.mean(b):8.1f} {b} exact p {ge/tot:.3f}")
gs = [g for g in G if valid(g) and re.fullmatch(r"fijo-p\d-[ab]|fijo-oha-[ab]|presion.*", g["r"]["etiqueta"]) and g["r"].get("corte") == "25"]
T = []
for g in gs:
    a = A(g); sn = [p for p, tm in g["team"].items() if tm == a and g["hero"][p] == "sniper"][0]
    s = g["snap"][sn].get(1500)
    if s: T.append((float(g["r"]["cpu_media"]), float(g["r"]["mem_libre"]), g["dur"] / 60, s["lh"], s["k"], s["d"], g["r"]["etiqueta"], g["r"]["fecha"][11:16], g["r"]["variante"]))
ar = np.array([t[:6] for t in T], float)
print("  corr across all n=", len(T), "cpu-dur", round(np.corrcoef(ar[:,0], ar[:,2])[0,1],2), "mem-dur", round(np.corrcoef(ar[:,1], ar[:,2])[0,1],2), "lh-cpu", round(np.corrcoef(ar[:,3], ar[:,0])[0,1],2), "lh-mem", round(np.corrcoef(ar[:,3], ar[:,1])[0,1],2), "lh-dur", round(np.corrcoef(ar[:,3], ar[:,2])[0,1],2), "k-mem", round(np.corrcoef(ar[:,4], ar[:,1])[0,1],2), "d-mem", round(np.corrcoef(ar[:,5], ar[:,1])[0,1],2), "d-cpu", round(np.corrcoef(ar[:,5], ar[:,0])[0,1],2), "d-dur", round(np.corrcoef(ar[:,5], ar[:,2])[0,1],2))
pr = [t for t in T if t[8] == "control_sniper"]; ap = np.array([t[:6] for t in pr], float)
print("  propio only n=", len(pr), "lh-cpu", round(np.corrcoef(ap[:,3], ap[:,0])[0,1],2), "lh-mem", round(np.corrcoef(ap[:,3], ap[:,1])[0,1],2), "lh-dur", round(np.corrcoef(ap[:,3], ap[:,2])[0,1],2), "d-dur", round(np.corrcoef(ap[:,5], ap[:,2])[0,1],2), "d-mem", round(np.corrcoef(ap[:,5], ap[:,1])[0,1],2))
for t in sorted((t for t in T if t[6].startswith("fijo-p5") or t[6].startswith("fijo-p2")), key=lambda z: z[7]):
    print("   ", t[6], t[7], "cpu", t[0], "mem", t[1], f"dur {t[2]:.1f}", "LH", t[3], "K", t[4], "D", t[5])
# ---------- G empirical
print("\nG bar, empirical joint resampling")
def vec(g):
    a = A(g); sn = [p for p, tm in g["team"].items() if tm == a and g["hero"][p] == "sniper"][0]
    s = g["snap"][sn].get(1500)
    return np.array([s["lh"], s["nw"], s["k"], sum(d[4] for d in g["dano"] if d[1] == "sniper" and d[2] != "sniper" and 720 <= d[0] <= 1500), s["d"]], float)
OW = {m: np.array([vec(g) for g in G if valid(g) and re.fullmatch(rf"fijo-p[25]-{m}", g["r"]["etiqueta"])]) for m in "ab"}
OH = {m: np.array([vec(g) for g in G if valid(g) and re.fullmatch(rf"fijo-oha-{m}", g["r"]["etiqueta"])]) for m in "ab"}
print("  means own", {m: np.round(OW[m].mean(0), 1).tolist() for m in "ab"}, "\n  means OHA", {m: np.round(OH[m].mean(0), 1).tolist() for m in "ab"})
resid = np.vstack([OW[m] - OW[m].mean(0) for m in "ab"])
print("  residual corr (LH,NW,K,dmg,D):\n", np.round(np.corrcoef(resid.T), 2))
scale = np.sqrt(len(resid) / (len(resid) - 2))
def bar(a, b):
    return np.array([a[0] >= .95 * b[0], a[1] >= .95 * b[1], a[2] >= .85 * b[2], a[3] >= .85 * b[3], a[4] <= b[4]])
def sim(mu_own, mu_ref, n_own, n_ref, it=40000, fixed_ref=None):
    idx = rng.integers(0, len(resid), (it, n_own))
    own = mu_own + scale * resid[idx].mean(1)
    if fixed_ref is None:
        ref = mu_ref + scale * resid[rng.integers(0, len(resid), (it, n_ref))].mean(1)
    else:
        ref = np.tile(fixed_ref, (it, 1))
    # K/D counts are floors at zero but means fine
    c = [own[:, 0] >= .95 * ref[:, 0], own[:, 1] >= .95 * ref[:, 1], own[:, 2] >= .85 * ref[:, 2], own[:, 3] >= .85 * ref[:, 3], own[:, 4] <= ref[:, 4]]
    c = np.array(c)
    return c.mean(1).round(3).tolist(), round(float(c.all(0).mean()), 3)
muO = np.vstack([OH["a"], OH["b"]]).mean(0)
print("  muRef (OHA 4 games)", np.round(muO, 1).tolist())
print("  parity random ref 8v4", sim(muO, muO, 8, 4)); print("  parity random ref 8v8", sim(muO, muO, 8, 8)); print("  parity 16v16", sim(muO, muO, 16, 16)); print("  parity 32v32", sim(muO, muO, 32, 32))
print("  frozen ref at observed OHA, own true = OHA mean (=parity) n=8 (same thing conditional)", sim(muO, muO, 8, 4, fixed_ref=muO))
# frozen reference draws: spread of pass prob over possible reference samples
ps = []
for _ in range(300):
    ref = muO + scale * resid[rng.integers(0, len(resid), 4)].mean(0)
    ps.append(sim(muO, muO, 8, 4, it=2000, fixed_ref=ref)[1])
print("  pass prob over frozen references: p10 %.2f p50 %.2f p90 %.2f" % tuple(np.percentile(ps, [10, 50, 90])))
own_mean = np.vstack([OW[m] for m in "ab"]).mean(0); print("  own mean (p2,p5)", np.round(own_mean, 1).tolist(), "observed passes", bar(own_mean, muO).tolist())
worse = muO * np.array([.85, .85, .65, .65, 1]) + np.array([0, 0, 0, 0, .5])
print("  clearly worse 8v4", sim(worse, muO, 8, 4)); print("  own true p2p5 mean vs OHA 8v4", sim(own_mean, muO, 8, 4))
# t-based independence check: product vs joint
c, j = sim(muO, muO, 8, 4)
print("  product of marginals", round(float(np.prod(c)), 3), "joint", j)
