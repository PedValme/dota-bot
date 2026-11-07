#!/usr/bin/env python
"""Natural experiment: did unspent gold jump when the imitated Turbo started using OHA's Turbo purchase path (2026-10-31)?
For every series: share of the OHA team's net worth unspent at min 20 and 25, and of the other team; purchase failures printed by OHA."""
import csv, os, re, sys, collections
import numpy as np
repo = sys.argv[1]
OBS = os.path.join(repo, "bench", "observaciones")
rows = list(csv.DictReader(open(os.path.join(repo, "bench", "series.csv"), encoding="utf-8", errors="replace")))
HERO = re.compile(r"obs t=(-?\d+) hero pid=(\d+) team=(\d) (\S+) lvl=(\d+) gold=(-?\d+) nw=(\d+)")
FAIL = re.compile(r"(\S+) \S+ (item_\w+) : (\S+)")
res = collections.OrderedDict(); fails = collections.Counter(); fail_games = 0; failcodes = collections.Counter()
secretbuys = collections.defaultdict(list)
for r in rows:
    if r.get("valida") != "si" or r.get("modo") != "turbo": continue
    path = os.path.join(OBS, f"{r['etiqueta']}-{re.sub(r'[-:T]', '', r['fecha'])}-{r['partida']}.log")
    if not os.path.exists(path) or r["variante"] in ("control_sniper", "control_sniper_sincombate"): continue
    side = 2 if r["dotabot"] == "radiant" else 3
    T = collections.defaultdict(lambda: [[0, 0, 0], [0, 0, 0]])
    nf = 0; sb = 0
    for l in open(path, encoding="latin1"):
        if " hero pid=" in l:
            m = HERO.search(l)
            if m and int(m[1]) in (900, 1200, 1500):
                i = 0 if int(m[3]) == side else 1
                t = int(m[1]); T[t][i][0] += int(m[6]); T[t][i][1] += int(m[7]); T[t][i][2] += 1
        elif "item_" in l and ("æªèƒ½" in l or "未能" in l or "\xe6\x9c\xaa\xe8\x83\xbd" in l):
            nf += 1
            m = re.search(r"(item_\w+)\s*:\s*(\S+)", l)
            if m and r["fecha"] > "2026-11-01": fails[m[1]] += 1; failcodes[m[2]] += 1
        elif " buy pid=" in l and re.search(r"item_(point_booster|hyperstone|demon_edge|reaver|eagle|mystic_staff|ultimate_orb|sacred_relic|platemail)", l):
            sb += 1
    key = (r["fecha"][:10], r["etiqueta"])
    d = res.setdefault(key, dict(n=0, nf=0, sb=0, oha={}, foe={}, riv=r.get("rival") or "-", mode=r.get("corte") or ""))
    d["n"] += 1; d["nf"] += nf; d["sb"] += sb
    for t, v in T.items():
        if v[0][2] == 5 and v[1][2] == 5:
            d["oha"].setdefault(t, []).append(v[0][0] / max(v[0][1], 1)); d["foe"].setdefault(t, []).append(v[1][0] / max(v[1][1], 1))
print("date       series          rival   n  fails/game secretBuys/game | OHA idle% min15/20/25 | other team idle% min15/20/25")
for (date, et), d in res.items():
    if not d["oha"]: continue
    f = lambda m, t: f"{100*np.mean(m[t]):4.0f}" if t in m else "   -"
    print(f"{date} {et:16s}{d['riv']:7s}{d['n']:3d} {d['nf']/d['n']:8.1f} {d['sb']/d['n']:10.1f}    | {f(d['oha'],900)} {f(d['oha'],1200)} {f(d['oha'],1500)} | {f(d['foe'],900)} {f(d['foe'],1200)} {f(d['foe'],1500)}")
print("top failed items after 11-01:", fails.most_common(15), failcodes.most_common(6))
