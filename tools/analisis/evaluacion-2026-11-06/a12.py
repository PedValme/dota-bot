#!/usr/bin/env python
"""By phase: Assassinate casts, fight attendance and damage per attended fight, denies, kill attempts in lane. python -I a12.py <games.json>"""
import json, sys, re, os, collections, bisect, math
import numpy as np
exec(open(os.path.join(os.path.dirname(os.path.abspath(sys.argv[0])), "a4_lib.py")).read())
VERS = [("OHA", r"base2-(humo-)?oha.*"), ("v0 base2", r"base2-(humo-)?propio.*"), ("v1 equipo2", r"equipo2-.*"), ("v2 retoque", r"retoque-.*"), ("v3 build1", r"build1-.*")]
PH = [("0-10", 0, 600), ("10-20", 600, 1200), ("20-25", 1200, 1500)]
for name, pat in VERS:
    gs = [g for g in G if re.fullmatch(pat, g["etiqueta"])]
    n = len(gs)
    ass = collections.Counter(); sh = collections.Counter(); att = collections.Counter(); eps = collections.Counter(); ddd = collections.Counter(); dn10 = []; hits = collections.Counter()
    for g in gs:
        pid = g["pid"]
        for t, p_, ab in g["casts_t"]:
            if p_ != pid: continue
            for ph, a, b in PH:
                if a <= t < b:
                    if ab == "sniper_assassinate": ass[ph] += 1
                    if ab == "sniper_shrapnel": sh[ph] += 1
        for t, a, b, ab, d, nn in g["dano"]:
            if a == "sniper" and b not in ("creep", "torre", "neutral") and ab == "ataque":
                for ph, x, y in PH:
                    if x <= t < y: hits[ph] += nn
        H = g["H"][str(pid)]
        if "600" in H: dn10.append(H["600"]["dn"])
        # fight episodes (allies and foes only), by the phase they start in; T0/T1 in a4_lib cover 720-1500, so recompute wider
        global T0, T1
        T0, T1 = 300, 1500
        for e in attend(g):
            for ph, a, b in PH:
                if a <= e["t0"] < b and e["big"] >= 3:
                    eps[ph] += 1
                    if e["arr"] is not None: att[ph] += 1; ddd[ph] += e["dd"]
    print(f"\n{name} (n={n}) denies al min 10: {np.mean(dn10):.1f}")
    for ph, a, b in PH:
        print(f"   {ph:6s} Assassinate {ass[ph]/n:4.1f}  Shrapnel {sh[ph]/n:5.1f}  golpes a héroes {hits[ph]/n:5.1f}  peleas grandes {eps[ph]/n:4.1f}  atendidas {100*att[ph]/max(eps[ph],1):3.0f} %  daño por atendida {ddd[ph]/max(att[ph],1):6.0f}")
