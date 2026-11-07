#!/usr/bin/env python
"""Why does the own Sniper fight less? Presence at fights, damage by source, time allocation, teammates' modes, runes, deaths."""
import json, sys, collections, re, bisect
import numpy as np
G = json.load(open(sys.argv[1]))
rng = np.random.default_rng(7)
T0, T1 = 720, 1500

def groups(pattern, var=None):
    return [g for g in G if re.fullmatch(pattern, g["etiqueta"]) and (var is None or g["variante"] == var) and any(l["t"] >= 1500 for l in g["linea"])]

SETS = {
    "OHA-fijo": groups(r"fijo-oha-[ab]"),
    "OHA-sorteo": groups(r"presion-oha"),
    "propio-fijo(p2,p5)": groups(r"fijo-p[25]-[ab]"),
    "propio-sorteo(p6,p7)": groups(r"presion[67]"),
}

def track(g, pid):
    p = g["pos"].get(str(pid), [])
    ts = [x[0] for x in p]
    return ts, p
def where(tr, t):
    ts, p = tr
    if not ts: return None
    i = bisect.bisect_left(ts, t)
    if i >= len(ts): i = len(ts) - 1
    if i > 0 and abs(ts[i - 1] - t) < abs(ts[i] - t): i -= 1
    if abs(ts[i] - t) > 6: return None
    return p[i]
def d2(a, b): return ((a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5

def fights(g):
    """Cluster all kills in [T0,T1] within 20 s into fights. Location: victim's last position. side: killers team."""
    ev = sorted([k for k in g["kills"] if T0 <= k["t"] <= T1], key=lambda k: k["t"])
    out, cur = [], []
    for k in ev:
        if cur and k["t"] - cur[-1]["t"] > 20:
            out.append(cur); cur = []
        cur.append(k)
    if cur: out.append(cur)
    return out

def analyse(g):
    pid, tm = g["pid"], g["team"]
    me = track(g, pid)
    r = collections.Counter()
    teams = {int(k): v for k, v in g["teams"].items()}
    # kill events: presence
    for k in g["kills"]:
        if not (T0 <= k["t"] <= T1) or k["vpid"] == pid: continue
        v = where(track(g, k["vpid"]), k["t"] - 2)
        m = where(me, k["t"] - 2)
        if v is None or m is None: continue
        d = d2(v, m)
        side = "ally_dies" if k["vteam"] == tm else "foe_dies"
        r[side] += 1
        if d <= 1500: r[side + "_1500"] += 1
        if d <= 2500: r[side + "_2500"] += 1
        if d <= 4000: r[side + "_4000"] += 1
        r[side + "_dist"] += d
        if k["vteam"] != tm:
            r["foe_by_me"] += k["kpid"] == pid
    # own deaths and where
    deaths = [k for k in g["kills"] if k["vpid"] == pid and T0 <= k["t"] <= T1]
    r["deaths"] = len(deaths)
    # alive heroes close: time near >=2 allies, time near a visible foe
    nearA = nearE = tot = 0
    allies = [p for p, v in teams.items() if v == tm and p != pid]
    foes = [p for p, v in teams.items() if v != tm]
    hist = []
    for t in range(T0, T1, 4):
        m = where(me, t)
        if m is None: continue
        tot += 1
        na = sum(1 for p in allies if (lambda w: w is not None and w[4] == 1 and d2(w, m) <= 1500)(where(track(g, p), t)))
        ne = sum(1 for p in foes if (lambda w: w is not None and w[4] == 1 and d2(w, m) <= 1500)(where(track(g, p), t)))
        nearA += na >= 2; nearE += ne >= 1
        hist.append((na, ne))
    r["t_tot"] = tot; r["t_near2allies"] = nearA; r["t_nearfoe"] = nearE
    # Damage by source after min 12
    out = collections.Counter(); inn = collections.Counter(); hits = collections.Counter(); act = 0; wins = set()
    for t, a, b, ab, dmg, n in g["dano"]:
        if t < T0 or t > T1: continue
        if a == "sniper" and b not in ("creep", "torre", "neutral"):
            out[ab] += dmg; hits[ab] += n; wins.add(t)
        if b == "sniper" and a not in ("creep", "torre", "neutral"):
            inn[ab] += dmg
    r["win_active"] = len(wins)
    r["dmg_out"] = sum(out.values()); r["dmg_in"] = sum(inn.values())
    r["dmg_attack"] = out.get("ataque", 0); r["hits_attack"] = hits.get("ataque", 0)
    for ab, v in out.items():
        r["src_" + ab] = v
    # Casts
    for key, c in g["casts"].items():
        p, ab = key.split("|")
        if int(p) == pid and "sniper" in ab: r["cast_" + ab] = c
    # runes
    return r

def stat(rs, key):
    return np.array([x.get(key, 0) for x in rs], float)
AN = {k: [analyse(g) for g in v] for k, v in SETS.items()}
print("n", {k: len(v) for k, v in AN.items()})
KEYS = ["foe_dies", "foe_dies_1500", "foe_dies_2500", "foe_dies_4000", "foe_by_me", "ally_dies", "ally_dies_1500", "ally_dies_2500", "ally_dies_4000", "deaths", "win_active", "dmg_out", "dmg_in", "dmg_attack", "hits_attack", "t_near2allies", "t_nearfoe", "t_tot"]
print(f"{'':20s}" + "".join(f"{k[:22]:>24s}" for k in AN))
for key in KEYS:
    print(f"{key:20s}" + "".join(f"{stat(v, key).mean():12.1f} ({stat(v, key).std(ddof=1):7.1f})   " for v in AN.values()))
print("\nDerived shares (pooled):")
for k, v in AN.items():
    s = lambda q: sum(x.get(q, 0) for x in v)
    print(k, "| foe deaths within 1500: %.0f%%, 2500: %.0f%%, 4000: %.0f%% | ally deaths within 1500: %.0f%%, 2500: %.0f%%, 4000: %.0f%% | dist avg foe %.0f ally %.0f | my kill of foe deaths %.0f%%| near >=2 allies %.0f%% | near foe %.0f%% | dmg per active win %.0f | dmg/hit %.0f" % (
        100 * s("foe_dies_1500") / s("foe_dies"), 100 * s("foe_dies_2500") / s("foe_dies"), 100 * s("foe_dies_4000") / s("foe_dies"),
        100 * s("ally_dies_1500") / s("ally_dies"), 100 * s("ally_dies_2500") / s("ally_dies"), 100 * s("ally_dies_4000") / s("ally_dies"),
        s("foe_dies_dist") / s("foe_dies"), s("ally_dies_dist") / s("ally_dies"), 100 * s("foe_by_me") / s("foe_dies"),
        100 * s("t_near2allies") / s("t_tot"), 100 * s("t_nearfoe") / s("t_tot"), s("dmg_out") / max(s("win_active"), 1), s("dmg_attack") / max(s("hits_attack"), 1)))

print("\nDamage to heroes by source, mean per match (min 12-25):")
srcs = collections.Counter()
for v in AN.values():
    for x in v:
        for q, val in x.items():
            if q.startswith("src_"): srcs[q] += val
for q, _ in srcs.most_common(14):
    print(f"{q:42s}" + "".join(f"{stat(v, q).mean():12.0f}" for v in AN.values()))
print("\nCasts of sniper abilities, whole match (mean):")
cs = collections.Counter()
for v in AN.values():
    for x in v:
        for q, val in x.items():
            if q.startswith("cast_"): cs[q] += val
for q, _ in cs.most_common(10):
    print(f"{q:42s}" + "".join(f"{stat(v, q).mean():12.1f}" for v in AN.values()))

print("\nDecomposition of damage gap: time x presence x rate")
for k, v in AN.items():
    print(k, "dmg", round(stat(v, 'dmg_out').mean()), "active windows", round(stat(v, 'win_active').mean(), 1), "dmg/window", round(stat(v, 'dmg_out').sum() / stat(v, 'win_active').sum()))

print("\nOwn bot: intention share, min 12-25 (prop estado every 2 s)")
for k in ["propio-fijo(p2,p5)", "propio-sorteo(p6,p7)"]:
    c = collections.Counter(); nn = 0
    for g in SETS[k]:
        for t, i, vida, mana, modo in g["est"]:
            if T0 <= t <= T1: c[i] += 1; nn += 1
    print(k, nn, [(a, round(100 * b / nn, 1)) for a, b in c.most_common(18)])
    m = collections.Counter()
    for g in SETS[k]:
        for t, i, vida, mana, modo in g["est"]:
            if T0 <= t <= T1: m[modo] += 1
    print("   engine GetActiveMode value while in own Think:", m.most_common(10))
print("\nOHA Sniper: mode share, min 12-25")
for k in ["OHA-fijo", "OHA-sorteo"]:
    c = collections.Counter(); nn = 0
    for g in SETS[k]:
        for t, mo in g["modes"].get(str(g["pid"]), []):
            if T0 <= t <= T1: c[mo] += 1; nn += 1
    print(k, nn, [(a, round(100 * b / nn, 1)) for a, b in c.most_common(14)])
print("\nTeammates (4 OHA): mode share, min 12-25, per arm")
for k in SETS:
    c = collections.Counter(); nn = 0
    for g in SETS[k]:
        teams = {int(a): b for a, b in g["teams"].items()}
        for p, v in teams.items():
            if v == g["team"] and p != g["pid"]:
                for t, mo in g["modes"].get(str(p), []):
                    if T0 <= t <= T1: c[mo.split("_TOWER")[0]] += 1; nn += 1
    print(k, nn, [(a, round(100 * b / nn, 1)) for a, b in c.most_common(10)])
print("\nEnemies: mode share")
for k in SETS:
    c = collections.Counter(); nn = 0
    for g in SETS[k]:
        teams = {int(a): b for a, b in g["teams"].items()}
        for p, v in teams.items():
            if v != g["team"]:
                for t, mo in g["modes"].get(str(p), []):
                    if T0 <= t <= T1: c[mo.split("_TOWER")[0]] += 1; nn += 1
    print(k, nn, [(a, round(100 * b / nn, 1)) for a, b in c.most_common(10)])

print("\nRunes: casts/pickup log counts")
print("Propio fijo income at last 'ingresos' (Sniper)")
def income(g):
    i = g["ingresos"].get(str(g["pid"])) or []
    i = [x for x in i if x[0] <= 1500]
    if not i: return {}
    return {a.split(":")[0]: int(a.split(":")[1]) for a in i[-1][1].split(",") if ":" in a}
for k in SETS:
    c = collections.Counter(); n = 0
    for g in SETS[k]:
        v = income(g)
        if v:
            n += 1
            for a, b in v.items(): c[a] += b
    print(k, n, {a: round(b / max(n, 1)) for a, b in c.most_common()})
print("\nTeammates' income, same")
for k in SETS:
    c = collections.Counter(); n = 0
    for g in SETS[k]:
        teams = {int(a): b for a, b in g["teams"].items()}
        for p, v in teams.items():
            if v == g["team"] and p != g["pid"]:
                i = [x for x in (g["ingresos"].get(str(p)) or []) if x[0] <= 1500]
                if i:
                    n += 1
                    for a in i[-1][1].split(","):
                        if ":" in a: c[a.split(":")[0]] += int(a.split(":")[1])
    print(k, n, {a: round(b / max(n, 1)) for a, b in c.most_common()})
