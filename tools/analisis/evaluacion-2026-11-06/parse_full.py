#!/usr/bin/env python
"""Full matches (not cut) from the clean bench: team net worth, items, kills per minute, and who won. Read-only.
Usage: python -I parse_full.py <repo> <out.json>"""
import csv, json, os, re, sys, collections
repo, out = sys.argv[1], sys.argv[2]
OBS = os.path.join(repo, "bench", "observaciones")
HERO = re.compile(r"obs t=(-?\d+) hero pid=(\d+) team=(\d) (\S+) lvl=(\d+) gold=(-?\d+) nw=(\d+) lh=(\d+) dn=(\d+) k=(\d+) d=(\d+) a=(\d+)")
rows = list(csv.DictReader(open(os.path.join(repo, "bench", "series.csv"), encoding="utf-8", errors="replace")))
games = []
for r in rows:
    if r.get("valida") != "si" or r.get("resultado") != "final" or r.get("modo") != "turbo" or not r.get("rival"):
        continue
    if r["fecha"] < "2026-11-01":  # before the clean bench (MEDICIONES, biases S1-S6)
        continue
    name = f"{r['etiqueta']}-{re.sub(r'[-:T]', '', r['fecha'])}-{r['partida']}.log"
    path = os.path.join(OBS, name)
    if not os.path.exists(path):
        continue
    H = collections.defaultdict(dict); team = {}
    for l in open(path, encoding="latin1"):
        if " hero pid=" not in l: continue
        m = HERO.search(l)
        if m:
            t = int(m[1])
            if t % 300: continue
            pid = int(m[2]); team[pid] = int(m[3])
            H[pid][t] = dict(gold=int(m[6]), nw=int(m[7]), k=int(m[10]), d=int(m[11]), lvl=int(m[5]))
    if len(team) < 10: continue
    side = 2 if r["dotabot"] == "radiant" else 3
    rec = dict(et=r["etiqueta"], var=r["variante"], rival=r["rival"], win=int(r["ganador"] == r["dotabot"]), mins=float(r["minutos"] or 0), torres=r.get("torres_fin"), lado=r["dotabot"], fecha=r["fecha"])
    for T in (300, 600, 900, 1200, 1500, 1800):
        try:
            a = [H[p][T] for p, v in team.items() if v == side]; b = [H[p][T] for p, v in team.items() if v != side]
        except KeyError:
            continue
        tag = T // 60
        rec[f"nw{tag}"] = sum(x["nw"] for x in a) - sum(x["nw"] for x in b)
        rec[f"item{tag}"] = sum(x["nw"] - max(x["gold"], 0) for x in a) - sum(x["nw"] - max(x["gold"], 0) for x in b)
        rec[f"k{tag}"] = sum(x["k"] for x in a) - sum(x["k"] for x in b)
        rec[f"lvl{tag}"] = sum(x["lvl"] for x in a) - sum(x["lvl"] for x in b)
    games.append(rec)
json.dump(games, open(out, "w"))
print(len(games))
