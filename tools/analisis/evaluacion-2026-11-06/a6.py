#!/usr/bin/env python
"""Where do OHA heroes stop buying? Per hero in clean-bench full matches: time and item of last real purchase, unspent gold at the end, inventory at min 25.
Items sold only at the secret shop are checked against Valve's shops file when available. python -I a6.py <repo>"""
import csv, os, re, sys, collections, json
import numpy as np
repo = sys.argv[1]
OBS = os.path.join(repo, "bench", "observaciones")
rows = list(csv.DictReader(open(os.path.join(repo, "bench", "series.csv"), encoding="utf-8", errors="replace")))
BUY = re.compile(r"obs t=(-?\d+) buy pid=(\d+) (\S+) (\S+) cost=(\d+)")
HERO = re.compile(r"obs t=(-?\d+) hero pid=(\d+) team=(\d) (\S+) lvl=(\d+) gold=(-?\d+) nw=(\d+) .* items=(\S*)")
SKIP = ("tpscroll", "ward", "smoke", "dust", "tango", "flask", "clarity", "blood_grenade", "enchanted_mango", "faerie")
stats = []; last_item = collections.Counter(); slot_full = 0; total = 0; per = collections.defaultdict(list)
for r in rows:
    if r.get("valida") != "si" or r.get("rival") != "valve" or r["variante"] not in ("base", "base_b") or r["fecha"] < "2026-11-01" or r.get("resultado") != "final": continue
    path = os.path.join(OBS, f"{r['etiqueta']}-{re.sub(r'[-:T]', '', r['fecha'])}-{r['partida']}.log")
    if not os.path.exists(path): continue
    side = 2 if r["dotabot"] == "radiant" else 3
    buys = collections.defaultdict(list); snap = {}; name = {}
    for l in open(path, encoding="latin1"):
        m = BUY.search(l)
        if m:
            buys[int(m[2])].append((int(m[1]), m[4], int(m[5]))); name[int(m[2])] = m[3]; continue
        if " hero pid=" in l:
            m = HERO.search(l)
            if m and int(m[3]) == side and int(m[1]) >= 0:
                t = int(m[1]); pid = int(m[2]); name[pid] = m[4]
                if t <= 1800: snap[pid] = (t, int(m[6]), int(m[7]), m[8])
    for pid, (t, gold, nw, items) in snap.items():
        if t < 1500: continue
        b = [x for x in buys[pid] if not any(s in x[1] for s in SKIP)]
        if not b: continue
        lt, li, _ = b[-1]
        total += 1
        n_inv = sum(1 for it in items.split("|") if it and int(it.split(":")[0]) <= 8)
        slot_full += n_inv >= 9
        stats.append((name[pid], lt, li, gold, nw, n_inv))
        if gold > 3000:
            last_item[li] += 1
            per[name[pid]].append(li)
print("hero-matches with data at min>=25:", total, "| with >3000 unspent:", sum(1 for s in stats if s[3] > 3000), "| inventory 9/9:", slot_full)
a = np.array([(s[1], s[3], s[4], s[5]) for s in stats], float)
print("median last real purchase t:", np.median(a[:, 0]), "| mean unspent:", a[:, 1].mean(), "| mean nw", a[:, 2].mean(), "| mean items in 9 slots", a[:, 3].mean())
print("LAST item bought before hoarding (top 25):", last_item.most_common(25))
print("Inventory distribution:", collections.Counter(int(s[5]) for s in stats).most_common())
print("Unspent by inventory count:")
for n in range(4, 10):
    q = [s[3] for s in stats if s[5] == n]
    if q: print(" ", n, len(q), round(np.mean(q)))
print("Sample hoarders:")
for s in sorted(stats, key=lambda s: -s[3])[:12]: print("  ", s)
