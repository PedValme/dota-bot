#!/usr/bin/env python
"""What the own Sniper does during the big fights it attends (min 10-20), and its distance to the nearest enemy while there, against OHA's Sniper.
python -I a13.py <games.json>"""
import json, sys, re, os, collections, bisect, math
import numpy as np
exec(open(os.path.join(os.path.dirname(os.path.abspath(sys.argv[0])), "a4_lib.py")).read())
T0, T1 = 600, 1200
VERS = [("OHA", r"base2-(humo-)?oha.*"), ("v1 equipo2", r"equipo2-.*"), ("v2 retoque", r"retoque-.*")]
for name, pat in VERS:
    c = collections.Counter(); dist = []; hp_leave = []; secs = 0; rng = []
    for g in [g for g in G if re.fullmatch(pat, g["etiqueta"])]:
        teams = {int(a): b for a, b in g["teams"].items()}
        foes = [q for q, v in teams.items() if v != g["team"]]
        me = grid(g, g["pid"]); F = {q: grid(g, q) for q in foes}
        ets = [e[0] for e in g["est"]]
        modes = g["modes"].get(str(g["pid"]), []); mts = [m[0] for m in modes]
        rangos = [int(x[8]) for x in g["oline"].get(str(g["pid"]), []) if 600 <= x[0] <= 1200]
        rng += rangos
        for e in attend(g):
            if e["big"] < 3 or e["arr"] is None: continue
            for t in range(e["t0"] + e["arr"], e["t0"] + e["dur"] + 1, 2):
                m = me.get(t)
                if m is None: continue
                ds = [D(m, F[q][t]) for q in foes if F[q].get(t) is not None and F[q][t][4]]
                if ds: dist.append(min(ds))
                secs += 2
                if ets:
                    i = min(bisect.bisect_left(ets, t), len(ets) - 1); it = g["est"][i][1]; c[it] += 1
                    r = (rangos[0] if rangos else 1000)
                    if it in ("con_el_grupo", "linea", "a_neutrales", "esperar", "farmear") and ds:
                        c["· ocioso, enemigo al alcance"] += min(ds) <= r
                        c["· ocioso, enemigo a alcance+300"] += r < min(ds) <= r + 300
                elif mts:
                    i = min(bisect.bisect_left(mts, t), len(mts) - 1); c[modes[i][1]] += 1
    tot = sum(c.values())
    print(f"\n{name}: {secs} s en peleas grandes atendidas; distancia al enemigo más cercano mediana {np.median(dist):.0f} (p25 {np.percentile(dist,25):.0f}, p75 {np.percentile(dist,75):.0f}); alcance medio {np.mean(rng) if rng else 0:.0f}")
    print("   ", [(a, round(100 * b / tot)) for a, b in c.most_common(10)])
