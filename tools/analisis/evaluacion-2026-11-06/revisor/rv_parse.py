#!/usr/bin/env python
"""Independent reviewer's minimal parser. One pickle with one record per log that has a series.csv row."""
import csv, os, re, sys, pickle, collections, datetime
REPO = r"C:\Proyectos\dota-bot"
OBS = os.path.join(REPO, "bench", "observaciones")
OUT = sys.argv[1]
rows = list(csv.DictReader(open(os.path.join(REPO, "bench", "series.csv"), encoding="utf-8", errors="replace")))
TS = re.compile(r"^(\d\d)/(\d\d) (\d\d):(\d\d):(\d\d) ")
games = []
missing = 0
for r in rows:
    name = f"{r['etiqueta']}-{re.sub(r'[-:T]', '', r['fecha'])}-{r['partida']}.log"
    p = os.path.join(OBS, name)
    if not os.path.exists(p):
        missing += 1
        continue
    snap = collections.defaultdict(dict)
    team, hero = {}, {}
    buys, kills, modes, pos, est, dano, fails = [], [], [], [], [], [], []
    nl = 0; first = None; last = None; maxlen = 0; lens = []
    tl = []
    t_real = {}
    took = 0
    for raw in open(p, "rb"):
        nl += 1
        l = raw.decode("utf-8", "replace").rstrip("\r\n")
        maxlen = max(maxlen, len(l))
        m = TS.match(l)
        if m:
            ts = int(m[3]) * 3600 + int(m[4]) * 60 + int(m[5])
            if first is None: first = ts
            last = ts
        if "took" in l and " ms" in l: took += 1
        if "未能购买" in l:
            q = re.search(r"(npc_dota_hero_\S+) 未能购买物品 (\S+) : (\S+)", l)
            fails.append((q[1], q[2], q[3]) if q else l[-80:])
            continue
        if "[bench] mode t=" in l:
            q = re.search(r"mode t=(-?\d+) pid=(\d+) (\S+) (\S+) (-?[\d.]+) alive=(\d) hp=([\d.]+) amenaza=([\d.]+) x=(-?\d+) y=(-?\d+)", l)
            if q: modes.append((int(q[1]), int(q[2]), q[4], int(q[6]), int(q[9]), int(q[10])))
            continue
        if "prop pos t=" in l:
            q = re.search(r"prop pos t=(-?[\d.]+) pid=(\d+) x=(-?\d+) y=(-?\d+)", l)
            if q: pos.append((float(q[1]), int(q[2]), int(q[3]), int(q[4])))
            continue
        if "prop estado t=" in l:
            q = re.search(r"prop estado t=(-?[\d.]+) pid=(\d+) intencion=(\S+) vida=([\d.]+) mana=([\d.]+) modo=(\d+)", l)
            if q: est.append((float(q[1]), int(q[2]), q[3], float(q[4]), int(q[6])))
            continue
        if "obs t=" not in l and "timeline" not in l: continue
        if "[dotabench] timeline" in l:
            q = re.search(r"min=(\d+) rk=(\d+) dk=(\d+) rt=(\d+) dt=(\d+) rb=(\d+) db=(\d+) rhp=(\d+) dhp=(\d+) rnw=(\d+) dnw=(\d+)", l)
            if q: tl.append(tuple(int(x) for x in q.groups()))
            continue
        q = re.search(r"obs t=(-?\d+) hero pid=(\d+) team=(\d) (\S+) lvl=(\d+) gold=(-?\d+) nw=(\d+) lh=(\d+) dn=(\d+) k=(\d+) d=(\d+) a=(\d+) alive=(\d) x=(-?\d+) y=(-?\d+) hp=(\d+) mp=(\d+) items=(\S*)", l)
        if q:
            t, pid = int(q[1]), int(q[2])
            team[pid] = int(q[3]); hero[pid] = q[4]
            snap[pid][t] = dict(lvl=int(q[5]), gold=int(q[6]), nw=int(q[7]), lh=int(q[8]), dn=int(q[9]), k=int(q[10]), d=int(q[11]), a=int(q[12]), alive=int(q[13]), x=int(q[14]), y=int(q[15]), items=q[18])
            continue
        q = re.search(r"obs t=(-?\d+) buy pid=(\d+) (\S+) (\S+) cost=(\d+)", l)
        if q:
            buys.append((int(q[1]), int(q[2]), q[3], q[4], int(q[5])))
            continue
        q = re.search(r"obs t=(-?\d+) kill victim=(\S+) vteam=(\d) vpid=(-?\d+) killer=(\S*) kteam=(\d*) kpid=(-?\d*)", l)
        if q:
            kills.append((int(q[1]), q[2], int(q[3]), int(q[4]), q[5], int(q[6] or 0), int(q[7] or -1)))
            continue
        q = re.search(r"obs t=(-?\d+) dano (\S+)", l)
        if q:
            lens.append(len(l))
            for it in q[2].split(","):
                z = re.match(r"^(.+)>(.+):(.+):(\d+):(\d+)$", it)
                if z: dano.append((int(q[1]), z[1], z[2], z[3], int(z[4]), int(z[5])))
            continue
    games.append(dict(r=r, name=name, snap={k: v for k, v in snap.items()}, team=team, hero=hero, buys=buys, kills=kills, modes=modes, pos=pos, est=est, dano=dano, fails=fails, nl=nl, dur=(last - first) if first is not None else None, maxlen=maxlen, danolen=lens, tl=tl, took=took, size=os.path.getsize(p)))
print(len(games), "logs parsed;", missing, "rows without log")
pickle.dump(games, open(OUT, "wb"))
