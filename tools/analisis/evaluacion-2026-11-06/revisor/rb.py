#!/usr/bin/env python
"""A extras (S6 natural experiment, SECRET_SHOP mode share, orphan recipes). C towers. D allies. H batch. Machine/real-time asymmetries."""
import pickle, re, sys, collections, itertools
import numpy as np
G = pickle.load(open("games.pkl", "rb"))
rng = np.random.default_rng(5)
def A(g): return 2 if g["r"]["dotabot"] == "radiant" else 3
def valid(g): return g["r"]["valida"] == "si"
# --- A: natural experiment within Valve team: pids with [bench] mode lines (= OHA code) vs not
rows = []
for g in G:
    if not valid(g) or g["r"].get("rival") == "dotabot": continue
    a = A(g); mp = {m[1] for m in g["modes"]}
    if not g["r"]["fecha"] >= "2026-10-31T04:41" or g["r"]["variante"] == "base_sinturbo": continue
    for p, tm in g["team"].items():
        s = g["snap"][p].get(1500)
        if s and tm != a:
            rows.append((p in mp, s["gold"] / max(s["nw"], 1), g["r"]["etiqueta"]))
for f in (True, False):
    v = [r[1] for r in rows if r[0] == f]
    print("rival-team hero with OHA mode lines:", f, "n", len(v), f"idle {100*np.mean(v):.0f}%" if v else "", collections.Counter(r[2] for r in rows if r[0] == f).most_common(5) if f else "")
# --- A: SECRET_SHOP mode share pre vs post, per bot-sec
for lbl, S in (("pre", [g for g in G if valid(g) and g["r"].get("modo") == "turbo" and g["r"]["fecha"] < "2026-10-31T04:41"]),
               ("post", [g for g in G if valid(g) and g["r"].get("modo") == "turbo" and g["r"]["fecha"] >= "2026-10-31T04:41" and g["r"]["variante"] != "base_sinturbo"]),
               ("sinturbo", [g for g in G if g["r"]["variante"] == "base_sinturbo"])):
    c = collections.Counter(); per = []
    for g in S:
        n = ss = 0
        for m in g["modes"]:
            if m[0] > 0 and m[0] <= 1500:
                n += 1; ss += m[2] == "SECRET_SHOP"
        if n: per.append(ss / n)
    print(lbl, "games", len(per), f"SECRET_SHOP share of mode samples {100*np.mean(per):.2f}%")
# --- A: inventory orphan recipes and unassembled parts at min 25; last buy time for hoarders
BASICS = re.compile(r"recipe_")
for lbl, S in (("pre", [g for g in G if valid(g) and g["r"].get("modo") == "turbo" and g["r"]["fecha"] < "2026-10-31T04:41"]),
               ("post", [g for g in G if valid(g) and g["r"].get("modo") == "turbo" and g["r"]["fecha"] >= "2026-10-31T04:41" and g["r"]["variante"] != "base_sinturbo" and not g["r"]["variante"].startswith("control")])):
    rec = []; lb = []
    for g in S:
        a = A(g); nrec = 0; ok = 0
        for p, tm in g["team"].items():
            s = g["snap"][p].get(1500)
            if s and tm == a:
                ok += 1; nrec += len(BASICS.findall(s["items"]))
                if s["gold"] > 5000:
                    bs = [q[0] for q in g["buys"] if q[1] == p and q[0] <= 1500 and not q[3] in ("item_tpscroll", "item_ward_observer", "item_ward_sentry", "item_dust", "item_clarity", "item_flask", "item_tango", "item_smoke_of_deceit", "item_enchanted_mango")]
                    if bs: lb.append(1500 - max(bs))
        if ok == 5: rec.append(nrec)
    print(lbl, "recipes in inventory per team at min25", f"{np.mean(rec):.2f}", "n", len(rec), "| hero gold>5000: n", len(lb), "median seconds since last real buy", np.median(lb) if lb else None)
# --- C towers from csv
def tw(g):
    a, b = g["r"]["torres_fin"].split("-"); a, b = int(a), int(b)
    return (a, b) if g["r"]["dotabot"] == "radiant" else (b, a)
# all rows from csv including those without logs are in series; here logs suffice for these labels
cut = [g for g in G if valid(g) and g["r"].get("rival") == "dotabot" and g["r"]["resultado"] == "corte" and g["r"].get("corte") == "25" and g["r"]["torres_fin"]]
def lab(pat): return [g for g in cut if re.fullmatch(pat, g["r"]["etiqueta"])]
def diff(gs): return np.array([tw(g)[0] - tw(g)[1] for g in gs], float)
OHA = lab(r"presion-oha|fijo-oha-[ab]")
print("csv rows: last timeline matches torres_fin?", sum(1 for g in cut if g["tl"] and f"{g['tl'][-1][3]}-{g['tl'][-1][4]}" == g["r"]["torres_fin"]), "of", len(cut), "last timeline min:", collections.Counter(g["tl"][-1][0] for g in cut if g["tl"]))
sets = {"OHA": OHA, "prop-all": [g for g in cut if g["r"]["variante"] == "control_sniper"], "fijo-p2p5": lab(r"fijo-p[25]-[ab]"), "fijo-all": lab(r"fijo-p\d-[ab]"), "pres6-7": lab(r"presion[67]"), "last(p2,p5,6,7)": lab(r"fijo-p[25]-[ab]|presion[67]")}
for k, v in sets.items():
    d = diff(v)
    print(f"towers {k:16s} n={len(d):3d} mean {d.mean():+.2f} sd {d.std(ddof=1):.2f} own {np.mean([tw(g)[0] for g in v]):.2f} rival {np.mean([tw(g)[1] for g in v]):.2f} per-side R {np.mean([tw(g)[0]-tw(g)[1] for g in v if g['r']['dotabot']=='radiant']):+.2f} D {np.mean([tw(g)[0]-tw(g)[1] for g in v if g['r']['dotabot']=='dire']):+.2f}")
def perm(a, b, n=50000):
    a, b = np.asarray(a, float), np.asarray(b, float); z = np.r_[a, b]; o = abs(a.mean() - b.mean()); c = 0
    for _ in range(n):
        rng.shuffle(z); c += abs(z[:len(a)].mean() - z[len(a):].mean()) >= o - 1e-9
    return (c + 1) / (n + 1)
print("perm game-level OHA vs all", perm(diff(OHA), diff(sets["prop-all"])), "vs last", perm(diff(OHA), diff(sets["last(p2,p5,6,7)"])), "vs fijo p2p5", perm(diff(OHA), diff(sets["fijo-p2p5"])))
# by block (draw): average within (etiqueta, bloque) so same-heroes both-sides is one unit
def blk(gs):
    d = collections.defaultdict(list)
    for g in gs: d[(g["r"]["etiqueta"], g["r"]["bloque"])].append(tw(g)[0] - tw(g)[1])
    return np.array([np.mean(v) for v in d.values()])
print("block means OHA", blk(OHA), "prop-all n blocks", len(blk(sets["prop-all"])), "mean", blk(sets["prop-all"]).mean())
print("perm block-level OHA vs all", perm(blk(OHA), blk(sets["prop-all"])), "vs last", perm(blk(OHA), blk(sets["last(p2,p5,6,7)"])))
# Per code group, range of means for propio
per = collections.defaultdict(list)
for g in sets["prop-all"]: per[re.sub(r"-[ab]$", "", g["r"]["etiqueta"])].append(tw(g)[0] - tw(g)[1])
print("propio by code", {k: (len(v), round(np.mean(v), 2)) for k, v in per.items()})
print("share of propio code groups with mean >= OHA 3.25:", sum(np.mean(v) >= 3.25 for v in per.values()), "of", len(per))
# same heroes: fijo-oha a/b vs fijo-pN a/b, paired by set
for m in "ab":
    print(" set", m, "OHA", diff(lab(rf"fijo-oha-{m}")), "p2", diff(lab(rf"fijo-p2-{m}")), "p5", diff(lab(rf"fijo-p5-{m}")), "all-prop", round(diff(lab(rf"fijo-p\d-{m}")).mean(), 2), "n", len(diff(lab(rf"fijo-p\d-{m}"))))
print("selection: which series used the set b before?", sorted({g["r"]["etiqueta"] for g in G if "juggernaut sniper axe lion lich" in g["r"]["heroes"]}), "set a", sorted({g["r"]["etiqueta"] for g in G if "skeleton_king sniper kunkka bane dazzle" in g["r"]["heroes"]}))
# --- D allies
def ally_stats(g):
    a = A(g); sn = [p for p, tm in g["team"].items() if tm == a and g["hero"][p] == "sniper"]
    if not sn or not all(1500 in s for s in g["snap"].values()): return None
    sn = sn[0]
    al = [p for p, tm in g["team"].items() if tm == a and p != sn]; fo = [p for p, tm in g["team"].items() if tm != a]
    S = lambda ps, k: sum(g["snap"][p][1500][k] for p in ps)
    ms = collections.defaultdict(lambda: [0, 0])
    tot = np.zeros(2); bins = collections.Counter(); cnt = 0
    bypt = collections.defaultdict(lambda: collections.defaultdict(str))
    for m in g["modes"]:
        if 720 <= m[0] <= 1500: bypt[m[0]][m[1]] = m[2]
    ge2 = n = 0; side = {"al": [0, 0], "fo": [0, 0]}
    for t, d in bypt.items():
        n += 1; pa = sum(1 for p in al if d.get(p, "").startswith("PUSH")); ge2 += pa >= 2
    return dict(ald=S(al, "d"), alk=S(al, "k"), ala=S(al, "a"), alnw=S(al, "nw"), fod=S(fo, "d"), fok=S(fo, "k"), fonw=S(fo, "nw"), snk=g["snap"][sn][1500]["k"], snd=g["snap"][sn][1500]["d"], snnw=g["snap"][sn][1500]["nw"], snlh=g["snap"][sn][1500]["lh"], sna=g["snap"][sn][1500]["a"], push2=ge2 / max(n, 1), allh=S(al, "lh"), fogold=S(fo, "gold"), algold=S(al, "gold"))
sets2 = {"OHA-fijo a": r"fijo-oha-a", "OHA-fijo b": r"fijo-oha-b", "p2p5 a": r"fijo-p[25]-a", "p2p5 b": r"fijo-p[25]-b", "pall a": r"fijo-p\d-a", "pall b": r"fijo-p\d-b", "OHA-sort": r"presion-oha", "prop-sort(2..8)": r"presion[2-8]|presion-propio"}
print("set n ald alk alnw fok(foe kills) fod fonw foNW-alNW sn:k d lh nw push>=2")
for k, pat in sets2.items():
    x = [ally_stats(g) for g in G if valid(g) and re.fullmatch(pat, g["r"]["etiqueta"]) and g["r"].get("corte") == "25"]
    x = [q for q in x if q]
    f = lambda z: np.mean([q[z] for q in x])
    print(f"{k:16s} {len(x):3d} ald {f('ald'):5.1f} alk {f('alk'):5.1f} alnw {f('alnw'):7.0f} fok {f('fok'):5.1f} fod {f('fod'):5.1f} fonw {f('fonw'):7.0f} d(fonw-alnw) {f('fonw')-f('alnw'):7.0f} sn k{f('snk'):4.1f} d{f('snd'):4.1f} lh{f('snlh'):5.0f} nw{f('snnw'):6.0f} push2 {100*f('push2'):4.0f}%")
# draw-level comparision OHA vs prop in sorteo: hero of allies shared? compare each ally hero mean deaths within each arm
# --- H batch and machine
print("label n cpu mem durmin size_MB nl took LH K D")
for lbl, pat in [("fijo-oha", r"fijo-oha-[ab]"), ("presion-oha", r"presion-oha"), ("fijo-p1", r"fijo-p1-[ab]"), ("fijo-p2", r"fijo-p2-[ab]"), ("fijo-p3", r"fijo-p3-[ab]"), ("fijo-p4", r"fijo-p4-[ab]"), ("fijo-p5a", r"fijo-p5-a"), ("fijo-p5b", r"fijo-p5-b"), ("presion6", "presion6"), ("presion7", "presion7"), ("presion8", "presion8")]:
    x = [g for g in G if valid(g) and re.fullmatch(pat, g["r"]["etiqueta"])]
    if not x: continue
    def sn(g):
        for p, h in g["hero"].items():
            if h == "sniper" and g["team"][p] == A(g): return g["snap"][p].get(1500)
    y = [sn(g) for g in x]; y = [q for q in y if q]
    print(f"{lbl:12s} {len(x):2d} cpu {np.mean([float(g['r']['cpu_media']) for g in x]):4.0f} mem {np.mean([float(g['r']['mem_libre']) for g in x]):4.0f} dur {np.mean([g['dur'] for g in x])/60:5.1f} MB {np.mean([g['size'] for g in x])/1e6:5.2f} lines {np.mean([g['nl'] for g in x]):7.0f} took {np.mean([g['took'] for g in x]):6.0f} LH {np.mean([q['lh'] for q in y]):5.0f} K {np.mean([q['k'] for q in y]):4.1f} D {np.mean([q['d'] for q in y]):4.1f}")
