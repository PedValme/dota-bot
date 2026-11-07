#!/usr/bin/env python
"""Deaths of the own Sniper in Pedro's lobbies, read one by one, and whether exposure separates them. python -I a8.py <repo>"""
import os, re, sys, collections, bisect, math
import numpy as np
repo = sys.argv[1]
OBS = os.path.join(repo, "bench", "observaciones")
MODE = re.compile(r"\[bench\] mode t=(-?\d+) pid=(\d+) (\S+) (\S+) (-?[\d.]+) alive=(\d) hp=([\d.]+) amenaza=([\d.]+) x=(-?\d+) y=(-?\d+)")
POS = re.compile(r"prop pos t=(-?[\d.]+) pid=(\d+) x=(-?\d+) y=(-?\d+) frente=(-?\d+) torre=(-?\d+) heroe=(-?\d+)")
EST = re.compile(r"prop estado t=(-?[\d.]+) pid=(\d+) intencion=(\S+) vida=([\d.]+) mana=([\d.]+) modo=\d+ .*creeps_e=(\d+) creeps_a=(\d+) heroes_e=(\d+) daño3s=(\d+)")
EST2 = re.compile(r"prop estado t=(-?[\d.]+) pid=(\d+) intencion=(\S+) vida=([\d.]+) mana=([\d.]+)")
DEC = re.compile(r"prop decision t=(-?[\d.]+) pid=(\d+) intencion=(\S+) motivo=(.*)$")
ACO = re.compile(r"prop acoso t=(-?[\d.]+) pid=(\d+) (.*)$")
LINEA = re.compile(r"\[bench\] linea t=(\d+) .*muertes=(\d+) kills=(\d+)")
for f in sorted(x for x in os.listdir(OBS) if x.startswith("lobby")):
    print("=" * 100); print(f)
    pos = collections.defaultdict(list); team = {}; names = {}; est = []; dec = []; aco = []; me = None; late = None; lin = []
    for l in open(os.path.join(OBS, f), encoding="latin1"):
        m = MODE.search(l)
        if m:
            pos[int(m[2])].append((int(m[1]), int(m[9]), int(m[10]), float(m[7]), int(m[6]))); names[int(m[2])] = m[3]; continue
        m = POS.search(l)
        if m:
            me = int(m[2]); pos[me].append((float(m[1]), int(m[3]), int(m[4]), None, 1, int(m[5]), int(m[6]), int(m[7]))); continue
        m = EST2.search(l)
        if m:
            q = EST.search(l)
            est.append((float(m[1]), m[3], float(m[4]), float(m[5]), int(q[8]) if q else -1, int(q[9]) if q else -1, int(q[6]) if q else -1, int(q[7]) if q else -1)); continue
        m = DEC.search(l)
        if m:
            dec.append((float(m[1]), m[3], m[4].strip()[:90]))
            if "medio juego" in l and late is None: late = float(m[1])
            continue
        m = ACO.search(l)
        if m: aco.append((float(m[1]), m[3][:80])); continue
        m = re.search(r"\[bench\] load pid=(\d+) team=(\d)", l)
        if m: team[int(m[1])] = int(m[2])
        m = LINEA.search(l)
        if m: lin.append((int(m[1]), int(m[2]), int(m[3])))
        if "prop medio" in l and "empieza" in l and late is None:
            late = float(re.search(r"t=(-?[\d.]+)", l)[1])
    print("own pid", me, "team", team.get(me), "late game starts", late, "names", {k: v for k, v in names.items()})
    ts = [e[0] for e in est]
    deaths = []
    for a, b in zip(est, est[1:]):
        if b[0] - a[0] > 9 and a[0] > 0: deaths.append(a[0])
    print("gaps in own log (candidate deaths):", [round(d) for d in deaths], "| deaths per minute line, last:", lin[-1] if lin else None)
    def near(pid, t):
        p = pos[pid]; tt = [x[0] for x in p]
        i = bisect.bisect_left(tt, t)
        best = None
        for j in (i - 1, i):
            if 0 <= j < len(p) and abs(tt[j] - t) <= 4 and (best is None or abs(tt[j] - t) < abs(tt[best] - t)): best = j
        return p[best] if best is not None else None
    allies = [p for p in pos if p != me and team.get(p) == team.get(me)]
    foes = [p for p in pos if p != me and team.get(p) != team.get(me)]
    print("allies", [names.get(a) for a in allies], "foes (bots)", [names.get(a) for a in foes], "(the human is not logged)")
    def snap(t):
        m = near(me, t)
        if m is None: return None
        da = [math.hypot(near(p, t)[1] - m[1], near(p, t)[2] - m[2]) for p in allies if near(p, t) and near(p, t)[4]]
        df = [math.hypot(near(p, t)[1] - m[1], near(p, t)[2] - m[2]) for p in foes if near(p, t) and near(p, t)[4]]
        return dict(ally=min(da) if da else 99999, a1400=sum(d <= 1400 for d in da), f1400=sum(d <= 1400 for d in df), frente=m[5] if len(m) > 5 else None, torre=m[6] if len(m) > 6 else None)
    for d in deaths:
        print(f"\n--- death ~t={d:.0f} ({'LINE' if (late is None or d < late) else 'late'})")
        for tt in (d - 16, d - 8, d - 3):
            s = snap(tt)
            i = min(bisect.bisect_left(ts, tt), len(est) - 1); e = est[i]
            if s: print(f"  t-{d-tt:>2.0f}: vida {e[2]:.2f} mana {e[3]:.2f} intent {e[1]:14s} heroes_e {e[4]} daño3s {e[5]} creeps e/a {e[6]}/{e[7]} | aliado {s['ally']:6.0f} aliados1400 {s['a1400']} bots_rival1400 {s['f1400']} frente {s['frente']} torre_enemiga {s['torre']}")
        for x in [x for x in dec if d - 12 <= x[0] <= d + 1][-7:]:
            print("     dec", round(x[0], 1), x[1], "·", x[2])
        for x in [x for x in aco if d - 12 <= x[0] <= d + 1][-3:]:
            print("     aco", round(x[0], 1), x[1])
    # Exposure: alone (no ally within 1400) x position; base rate vs before deaths
    print("\nExposure, whole game vs 10 s before each death:")
    start = 60
    allt = [t for t in range(start, int(est[-1][0]), 4)]
    def expo(t):
        s = snap(t)
        if s is None: return None
        return (s["a1400"] == 0, s["f1400"] >= 1)
    A = [expo(t) for t in allt]; A = [x for x in A if x]
    B = [expo(d - 10) for d in deaths]; B = [x for x in B if x]
    print(f"  alone: all game {100*np.mean([x[0] for x in A]):.0f}% | before death {100*np.mean([x[0] for x in B]):.0f}% (n={len(B)})")
    print(f"  bot rival within 1400: all game {100*np.mean([x[1] for x in A]):.0f}% | before death {100*np.mean([x[1] for x in B]):.0f}%")
    print(f"  alone AND rival near: all game {100*np.mean([x[0] and x[1] for x in A]):.0f}% | before death {100*np.mean([x[0] and x[1] for x in B]):.0f}%")
