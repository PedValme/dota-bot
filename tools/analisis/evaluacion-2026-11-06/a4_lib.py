G = json.load(open(sys.argv[1]))
T0, T1 = 720, 1500

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
