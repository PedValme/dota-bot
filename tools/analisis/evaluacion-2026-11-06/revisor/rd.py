#!/usr/bin/env python
"""SECRET_SHOP mode share with a loose regex over all logs; by period."""
import csv, os, re, collections
import numpy as np
REPO = r"C:\Proyectos\dota-bot"; OBS = os.path.join(REPO, "bench", "observaciones")
rows = list(csv.DictReader(open(os.path.join(REPO, "bench", "series.csv"), encoding="utf-8", errors="replace")))
RX = re.compile(rb"\[bench\] mode t=(-?\d+) pid=\d+ \S+ (\S+) ")
per = collections.defaultdict(list)
for r in rows:
    if r["valida"] != "si" or r.get("modo") != "turbo": continue
    if r["variante"].startswith("control"): continue
    p = os.path.join(OBS, f"{r['etiqueta']}-{re.sub(r'[-:T]', '', r['fecha'])}-{r['partida']}.log")
    if not os.path.exists(p): continue
    n = s = 0
    for l in open(p, "rb"):
        if b"[bench] mode" not in l: continue
        m = RX.search(l)
        if m and 0 < int(m[1]) <= 1500:
            n += 1; s += m[2] == b"SECRET_SHOP"
    if not n: continue
    k = "sinturbo" if r["variante"] == "base_sinturbo" else ("pre" if r["fecha"] < "2026-10-31T04:41" else "post")
    per[k].append(s / n)
for k, v in per.items():
    print(k, "games", len(v), f"SECRET_SHOP share {100*np.mean(v):.2f}%", "max", round(100 * max(v), 2))
