#!/usr/bin/env python
"""End-of-match scoreboard of the Sniper and how each enemy death happens, for the four versions measured on the same three matchups.
python -I a11.py <games.json> <repo>"""
import json, sys, re, os, bisect, math, collections
import numpy as np
G = json.load(open(sys.argv[1])); repo = sys.argv[2]
OBS = os.path.join(repo, "bench", "observaciones")
VERS = [("OHA", r"base2-(humo-)?oha.*"), ("v0 base2", r"base2-(humo-)?propio.*"), ("v1 equipo2", r"equipo2-.*"), ("v2 retoque", r"retoque-.*")]
ITEMS = ["power_treads", "dragon_lance", "maelstrom", "mask_of_madness", "force_staff", "hurricane_pike", "invis_sword", "silver_edge", "black_king_bar", "mjollnir", "ultimate_scepter", "lesser_crit", "greater_crit", "satanic", "monkey_king_bar"]
def track(g, pid):
    p = g["pos"].get(str(pid), []); return [x[0] for x in p], p
def at(tr, t, tol=4):
    ts, p = tr; i = bisect.bisect_left(ts, t); c = None
    for j in (i - 1, i):
        if 0 <= j < len(p) and abs(ts[j] - t) <= tol and (c is None or abs(ts[j] - t) < abs(ts[c] - t)): c = j
    return p[c] if c is not None else None
def D(a, b): return math.hypot(a[1] - b[1], a[2] - b[2])
def logxp(g):
    path = os.path.join(OBS, f"{g['etiqueta']}-{re.sub(r'[-:T]', '', g['fecha'])}-{g['partida']}.log")
    xp = {}
    for l in open(path, encoding="latin1"):
        m = re.search(r"obs t=(\d+) linea pid=(\d+) \S+ .* xp=(\d+)", l)
        if m and int(m[2]) == g["pid"]: xp[int(m[1])] = int(m[3])
    return xp
rows = collections.defaultdict(list); kills = collections.defaultdict(list); timeline = collections.defaultdict(lambda: collections.defaultdict(list)); items = collections.defaultdict(lambda: collections.defaultdict(list))
for name, pat in VERS:
    for g in G:
        if not re.fullmatch(pat, g["etiqueta"]): continue
        pid = g["pid"]; H = {int(t): v for t, v in g["H"][str(pid)].items()}
        if 1500 not in H: continue
        teams = {int(a): b for a, b in g["teams"].items()}
        foes = [q for q, v in teams.items() if v != g["team"]]
        xp = logxp(g); xt = max([t for t in xp if t <= 1500] or [0])
        dmg = collections.Counter(); dmg_t = collections.defaultdict(int); hits = 0
        for t, a, b, ab, d, n in g["dano"]:
            if t > 1500: continue
            if a == "sniper" and b not in ("creep", "torre", "neutral"):
                ph = "0-10" if t <= 600 else ("10-20" if t <= 1200 else "20-25")
                dmg[ph] += d; dmg_t[(t, b)] += d
                if ab == "ataque": hits += n
        dead = sum(30 for t, v in H.items() if 0 < t <= 1500 and not v["alive"])
        s = H[1500]
        r = dict(k=s["k"], d=s["d"], a=s["a"], lh=s["lh"], dn=s["dn"], lvl=s["lvl"], gpm=s["nw"] / 25, xpm=xp.get(xt, 0) / (max(xt, 1) / 60), dmg=sum(dmg.values()),
                 d0=dmg["0-10"], d1=dmg["10-20"], d2=dmg["20-25"], hits=hits, dead=dead,
                 casts_ass=sum(1 for t, p_, ab in g["casts_t"] if p_ == pid and ab == "sniper_assassinate" and t <= 1500),
                 casts_sh=sum(1 for t, p_, ab in g["casts_t"] if p_ == pid and ab == "sniper_shrapnel" and t <= 1500))
        rows[name].append(r)
        for T in (300, 600, 900, 1200, 1500):
            if T in H:
                for k in ("nw", "lh", "k", "a", "d", "lvl"): timeline[name][(T, k)].append(H[T][k])
        for it in ITEMS:
            first = next((t for t in sorted(H) if t <= 1500 and re.search(rf"\d+:{it}(\||$)", H[t]["items"] or "")), None)
            items[name][it].append(first)
        # every enemy hero death up to min 25: how it happened for the Sniper
        me = track(g, pid)
        for kl in g["kills"]:
            if kl["t"] > 1500 or kl["vteam"] == g["team"]: continue
            t = kl["t"]; v = at(track(g, kl["vpid"]), t - 2); m = at(me, t - 2)
            dist = D(v, m) if v and m else 1e9
            w = (t // 10) * 10
            hit = any(dmg_t.get((ww, kl["victim"]), 0) > 0 for ww in (w - 10, w, w + 10))
            castA = any(p_ == pid and ab == "sniper_assassinate" and t - 4 <= tc <= t + 1 for tc, p_, ab in g["casts_t"])
            vhp8 = None
            tv = track(g, kl["vpid"])
            q = at(tv, t - 8)
            if q and q[3] is not None: vhp8 = q[3]
            kind = "mía" if kl["kpid"] == pid else ("con mi daño" if hit else ("cerca, sin pegar" if dist <= 1500 else "lejos"))
            kills[name].append(dict(t=t, kind=kind, ass=castA and kl["kpid"] == pid, dist=dist, vhp8=vhp8, phase="0-12" if t < 720 else "12-25", mid=kl["vpid"] in [q_ for q_ in foes if (g["linea"] and False)]))
def mean(xs): xs = [x for x in xs if x is not None]; return np.mean(xs) if xs else float("nan")
print("### Marcador al min 25 (media por partida)")
K = ["k", "d", "a", "lh", "dn", "lvl", "gpm", "xpm", "dmg", "d0", "d1", "d2", "hits", "dead", "casts_ass", "casts_sh"]
print(f"{'':12s}" + "".join(f"{k:>8s}" for k in K) + "    n")
for name, _ in VERS:
    print(f"{name:12s}" + "".join(f"{mean([r[k] for r in rows[name]]):8.1f}" for k in K) + f"   {len(rows[name])}")
print("\n### Curvas: media a los 5, 10, 15, 20 y 25 min")
for k in ("nw", "lh", "k", "a", "d", "lvl"):
    print(k)
    for name, _ in VERS:
        print(f"   {name:12s}" + "".join(f"{mean(timeline[name][(T, k)]):9.1f}" for T in (300, 600, 900, 1200, 1500)))
print("\n### Minuto medio en que tiene cada objeto (n con él al min 25)")
for it in ITEMS:
    print(f"{it:18s}" + "".join(f"{(mean(items[n][it]) / 60 if not math.isnan(mean(items[n][it])) else float('nan')):7.1f} ({sum(1 for x in items[n][it] if x is not None)}/{len(items[n][it])})" for n, _ in VERS))
print("\n### Muertes de enemigos hasta el min 25: qué tenía que ver el Sniper (por partida)")
for name, _ in VERS:
    n = len(rows[name]); ks = kills[name]
    for ph in ("0-12", "12-25"):
        c = collections.Counter(x["kind"] for x in ks if x["phase"] == ph)
        print(f"{name:12s} {ph:6s} total {sum(c.values())/n:5.1f} | mía {c['mía']/n:4.1f} | con mi daño {c['con mi daño']/n:4.1f} | cerca sin pegar {c['cerca, sin pegar']/n:4.1f} | lejos {c['lejos']/n:4.1f}")
    mine = [x for x in ks if x["kind"] == "mía"]
    print(f"{'':12s} kills mías con Assassinate {sum(x['ass'] for x in mine)}/{len(mine)}; vida de la víctima 8 s antes: {mean([x['vhp8'] for x in mine]):.2f}; distancia media {mean([x['dist'] for x in mine if x['dist']<1e8]):.0f}")
print("\n### Conversión: de las muertes en las que pegó, cuántas remató")
for name, _ in VERS:
    ks = kills[name]; mine = sum(1 for x in ks if x["kind"] == "mía"); helped = sum(1 for x in ks if x["kind"] == "con mi daño")
    print(f"{name:12s} remata {mine}/{mine+helped} = {100*mine/max(mine+helped,1):.0f} %   presente sin pegar {sum(1 for x in ks if x['kind']=='cerca, sin pegar')}")
