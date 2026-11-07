#!/usr/bin/env python
"""Fight episodes and attendance, gold per minute by activity, idle time, runes, unspent gold, pushes (nearest-time matching)."""
import json, sys, re, collections, bisect, math
import numpy as np
G = json.load(open(sys.argv[1]))
rng = np.random.default_rng(3)
T0, T1 = 720, 1500
SETS = {
    "OHA-fijo": r"fijo-oha-[ab]", "OHA-sorteo": r"presion-oha",
    "prop-fijo(p2,p5)": r"fijo-p[25]-[ab]", "prop-sort(p6,p7)": r"presion[67]",
}
def games(pat): return [g for g in G if re.fullmatch(pat, g["etiqueta"]) and any(l["t"] >= 1500 for l in g["linea"])]
def grid(g, pid, step=2):
    """position at each even second in [0,1500], None if unknown; alive flag from mode lines when present."""
    p = g["pos"].get(str(pid), [])
    out = {}
    if not p: return out
    ts = [x[0] for x in p]
    for t in range(0, 1502, step):
        i = bisect.bisect_left(ts, t)
        c = None
        for j in (i - 1, i):
            if 0 <= j < len(p) and abs(ts[j] - t) <= 3 and (c is None or abs(ts[j] - t) < abs(ts[c] - t)): c = j
        if c is not None: out[t] = p[c]
    return out
def modegrid(g, pid):
    m = g["modes"].get(str(pid), [])
    ts = [x[0] for x in m]; out = {}
    for t in range(0, 1502, 2):
        i = bisect.bisect_left(ts, t)
        c = None
        for j in (i - 1, i):
            if 0 <= j < len(m) and abs(ts[j] - t) <= 3 and (c is None or abs(ts[j] - t) < abs(ts[c] - t)): c = j
        if c is not None: out[t] = m[c][1]
    return out
def D(a, b): return math.hypot(a[1] - b[1], a[2] - b[2])
REACH = 1400

def episodes(g):
    """Fight second: an ally of the Sniper (not him) and a foe, both alive, within 1000 of each other, and at least one kill or a sustained 6 s.
    Episodes: consecutive fight seconds (gap<=8 s). Kept if lasting >=6 s. Uses only the 4 allies and 5 foes, never the Sniper, so it does not depend on him."""
    teams = {int(k): v for k, v in g["teams"].items()}
    al = [p for p, v in teams.items() if v == g["team"] and p != g["pid"]]
    fo = [p for p, v in teams.items() if v != g["team"]]
    A = {p: grid(g, p) for p in al}; F = {p: grid(g, p) for p in fo}
    secs = []
    for t in range(T0, T1 + 1, 2):
        pts = []
        na = set(); nf = set()
        for a in al:
            x = A[a].get(t)
            if x is None or not x[4]: continue
            for f in fo:
                y = F[f].get(t)
                if y is None or not y[4]: continue
                if D(x, y) <= 1000:
                    na.add(a); nf.add(f); pts.append(((x[1] + y[1]) / 2, (x[2] + y[2]) / 2))
        if pts:
            secs.append((t, np.mean([q[0] for q in pts]), np.mean([q[1] for q in pts]), len(na), len(nf)))
    eps, cur = [], []
    for s in secs:
        if cur and s[0] - cur[-1][0] > 8:
            eps.append(cur); cur = []
        cur.append(s)
    if cur: eps.append(cur)
    return [e for e in eps if e[-1][0] - e[0][0] >= 6]

def attend(g):
    me = grid(g, g["pid"])
    out = []
    dealt_t = collections.Counter()
    for t, a, b, ab, dmg, n in g["dano"]:
        if a == "sniper" and b not in ("creep", "torre", "neutral"): dealt_t[t] += dmg
    kills = [k for k in g["kills"] if T0 <= k["t"] <= T1]
    for e in episodes(g):
        t0, t1 = e[0][0], e[-1][0]
        big = max(x[3] + x[4] for x in e)
        dstart = None; dmin = 1e9; arr = None; near_s = 0
        for t, x, y, na, nf in e:
            m = me.get(t)
            if m is None: continue
            d = math.hypot(m[1] - x, m[2] - y)
            if dstart is None: dstart = d
            if d < dmin: dmin = d
            if d <= REACH:
                near_s += 2
                if arr is None: arr = t - t0
        dd = sum(v for t, v in dealt_t.items() if t0 - 2 <= t <= t1 + 10)
        fk = [k for k in kills if t0 - 2 <= k["t"] <= t1 + 4 and k["vteam"] != g["team"]]
        ak = [k for k in kills if t0 - 2 <= k["t"] <= t1 + 4 and k["vteam"] == g["team"] and k["vpid"] != g["pid"]]
        mk = [k for k in kills if t0 - 2 <= k["t"] <= t1 + 4 and k["vpid"] == g["pid"]]
        out.append(dict(t0=t0, dur=t1 - t0, big=big, dstart=dstart, dmin=dmin, arr=arr, near=near_s, dd=dd, fk=len(fk), ak=len(ak), mk=len(mk), est=None))
    return out
print("### Fight episodes defined only by the 4 allies and 5 enemies (independent of the Sniper). min 12-25, per match")
ALL = {k: {id(g): attend(g) for g in games(p)} for k, p in SETS.items()}
print(f"{'':18s}{'n':>3s}{'eps':>7s}{'eps>=3her':>10s}{'sec.fight':>10s}{'att<=1400':>10s}{'att big':>9s}{'dStart':>8s}{'lat(s)':>8s}{'dmg/att':>9s}{'dmg/abs':>9s}{'foeK/ep att':>12s}{'foeK/ep abs':>12s}{'allyK att':>10s}{'allyK abs':>10s}")
for k, d in ALL.items():
    n = len(d); e = [x for v in d.values() for x in v]
    att = [x for x in e if x["arr"] is not None]; abs_ = [x for x in e if x["arr"] is None]
    bigs = [x for x in e if x["big"] >= 3]; batt = [x for x in bigs if x["arr"] is not None]
    print(f"{k:18s}{n:3d}{len(e)/n:7.1f}{len(bigs)/n:10.1f}{sum(x['dur'] for x in e)/n:10.0f}{100*len(att)/len(e):9.0f}%{100*len(batt)/max(len(bigs),1):8.0f}%{np.median([x['dstart'] for x in e if x['dstart'] is not None]):8.0f}{np.median([x['arr'] for x in att]):8.0f}{np.mean([x['dd'] for x in att]):9.0f}{np.mean([x['dd'] for x in abs_]):9.0f}{np.mean([x['fk'] for x in att]):12.2f}{np.mean([x['fk'] for x in abs_]):12.2f}{np.mean([x['ak'] for x in att]):10.2f}{np.mean([x['ak'] for x in abs_]):10.2f}")
print("\nPer match, big fights (>=3 heroes): attended, foe kills, ally deaths")
for k, d in ALL.items():
    a = [sum(1 for x in v if x["big"] >= 3 and x["arr"] is not None) for v in d.values()]
    b = [sum(1 for x in v if x["big"] >= 3) for v in d.values()]
    print(k, "attended", a, "of", b)
print("\nDistance to fight at its start (share): <=1400, 1400-3500 (walk rule), 3500-6000, >6000")
for k, d in ALL.items():
    ds = np.array([x["dstart"] for v in d.values() for x in v if x["dstart"] is not None and x["big"] >= 3])
    print(k, [round(100 * ((ds > lo) & (ds <= hi)).mean()) for lo, hi in [(0, 1400), (1400, 3500), (3500, 6000), (6000, 1e9)]], "n", len(ds))
print("\nAttendance share by distance at start (big fights)")
for k, d in ALL.items():
    r = []
    for lo, hi in [(1400, 3500), (3500, 6000), (6000, 1e9)]:
        e = [x for v in d.values() for x in v if x["dstart"] is not None and x["big"] >= 3 and lo < x["dstart"] <= hi]
        r.append(f"{100*sum(1 for x in e if x['arr'] is not None)/max(len(e),1):3.0f}% (n{len(e)})")
    print(k, r)
print("\nOwn bot: intent when a big fight starts and it is NOT within 1400; and for those it never attends")
for k in list(SETS)[2:]:
    c = collections.Counter(); c2 = collections.Counter()
    for g in games(SETS[k]):
        ts = [x[0] for x in g["est"]]
        for x in attend(g):
            if x["big"] < 3 or x["dstart"] is None or x["dstart"] <= REACH: continue
            i = min(bisect.bisect_left(ts, x["t0"]), len(ts) - 1)
            c[g["est"][i][1]] += 1
            if x["arr"] is None: c2[g["est"][i][1]] += 1
    tot = sum(c.values())
    print(k, tot, [(a, round(100 * b / tot)) for a, b in c.most_common(9)])
    print("  never attended:", sum(c2.values()), [(a, round(100 * b / sum(c2.values()))) for a, b in c2.most_common(7)])

print("\n### Gold per minute by activity (30 s hero samples, min 12-25; dominant activity of the interval)")
def activity(g):
    pid = str(g["pid"])
    H = {int(t): v for t, v in g["H"][pid].items()}
    own = g["variante"].startswith("control")
    out = []
    if own:
        ev = [(e[0], e[1]) for e in g["est"]]
    else:
        ev = [(t, m) for t, m in g["modes"].get(pid, [])]
    for t in range(T0, T1, 30):
        if t not in H or t + 30 not in H: continue
        c = collections.Counter(a for x, a in ev if t <= x < t + 30)
        if not c: continue
        act = c.most_common(1)[0][0]
        if not own:
            act = re.sub(r"_(TOP|MID|BOT)$", "", act).replace("_TOWER", "")
        out.append((act, H[t + 30]["nw"] - H[t]["nw"], H[t + 30]["lh"] - H[t]["lh"], H[t + 30]["k"] - H[t]["k"], H[t + 30]["a"] - H[t]["a"]))
    return out
for k, p in SETS.items():
    r = collections.defaultdict(list)
    for g in games(p):
        for a, nw, lh, ki, asi in activity(g): r[a].append((nw, lh, ki, asi))
    tot = sum(len(v) for v in r.values())
    print(k, "intervals", tot)
    for a, v in sorted(r.items(), key=lambda q: -len(q[1]))[:10]:
        v = np.array(v, float)
        print(f"   {a:20s} share {100*len(v)/tot:5.1f}%  NW/min {2*v[:,0].mean():7.0f}  LH/min {2*v[:,1].mean():5.1f}  K/min {2*v[:,2].mean():5.2f}  A/min {2*v[:,3].mean():5.2f}")

print("\n### Idle: moved <100 in 2 s (samples), min 12-25, and with no damage dealt that 10 s window")
for k, p in SETS.items():
    idle = tot = idleNoDmg = 0
    per = []
    for g in games(p):
        me = grid(g, g["pid"]); dealt = {t for t, a, b, ab, dmg, n in g["dano"] if a == "sniper"}
        i0 = t0 = 0
        for t in range(T0, T1, 2):
            a, b = me.get(t), me.get(t + 2)
            if a is None or b is None or not a[4]: continue
            tot += 1; t0 += 1
            if D(a, b) < 100:
                idle += 1
                w = (t // 10 + 1) * 10
                if not any(q in dealt for q in (w - 10, w, w + 10)): idleNoDmg += 1; i0 += 1
        per.append(round(100 * i0 / max(t0, 1)))
    print(f"{k:18s} still {100*idle/tot:5.1f}%  still with no damage to anything near {100*idleNoDmg/tot:5.1f}%  per match {per}")

print("\n### Pushes with nearest-time matching: share of time >=2 allies in PUSH; Sniper within 1500 of them")
for k, p in SETS.items():
    tot = sec = near = 0; dist = []; intent = collections.Counter()
    for g in games(p):
        teams = {int(a): b for a, b in g["teams"].items()}
        al = [q for q, v in teams.items() if v == g["team"] and q != g["pid"]]
        M = {q: modegrid(g, q) for q in al}; P = {q: grid(g, q) for q in al}; me = grid(g, g["pid"])
        ts = [x[0] for x in g["est"]]
        for t in range(T0, T1, 2):
            tot += 1
            pp = [q for q in al if str(M[q].get(t, "")).startswith("PUSH")]
            if len(pp) < 2: continue
            sec += 1
            m = me.get(t)
            pts = [P[q].get(t) for q in pp]; pts = [x for x in pts if x]
            if m and pts:
                d = min(D(m, x) for x in pts); dist.append(d); near += d <= 1500
                if ts:
                    i = min(bisect.bisect_left(ts, t), len(ts) - 1); intent[g["est"][i][1]] += 1
    print(f"{k:18s} time>=2 allies pushing {100*sec/tot:5.1f}%  near them {100*near/max(len(dist),1):5.1f}%  median d {np.median(dist) if dist else 0:6.0f}  intent {[(a, round(100*b/max(sum(intent.values()),1))) for a,b in intent.most_common(5)]}")

print("\n### Unspent gold at min 25 (items = nw-gold): per team, all games vs OHA team")
for k, p in SETS.items():
    S, Al, Fo = [], [], []
    for g in games(p):
        teams = {int(a): b for a, b in g["teams"].items()}
        x = {q: g["H"][str(q)].get("1500") for q in teams}
        if any(v is None for v in x.values()): continue
        S.append(x[g["pid"]]["gold"] / x[g["pid"]]["nw"])
        Al.append(sum(x[q]["gold"] for q in teams if teams[q] == g["team"] and q != g["pid"]) / sum(x[q]["nw"] for q in teams if teams[q] == g["team"] and q != g["pid"]))
        Fo.append(sum(x[q]["gold"] for q in teams if teams[q] != g["team"]) / sum(x[q]["nw"] for q in teams if teams[q] != g["team"]))
    print(f"{k:18s} share of NW unspent: Sniper {100*np.mean(S):4.0f}%  4 allies {100*np.mean(Al):4.0f}%  enemies {100*np.mean(Fo):4.0f}%")

print("\n### Runes")
print("(see rune lines in the logs; parsed separately)")
