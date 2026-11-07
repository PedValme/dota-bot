#!/usr/bin/env python
"""Parse every Sniper-comparison log of the bench into one JSON record per match. Read-only on the repo.
Usage: python -I parse.py <repo> <out.json>"""
import csv, json, math, os, re, sys, collections

repo, out = sys.argv[1], sys.argv[2]
OBS = os.path.join(repo, "bench", "observaciones")
HERO = re.compile(r"obs t=(-?\d+) hero pid=(\d+) team=(\d) (\S+) lvl=(\d+) gold=(-?\d+) nw=(\d+) lh=(\d+) dn=(\d+) k=(\d+) d=(\d+) a=(\d+) alive=(\d) x=(-?\d+) y=(-?\d+) hp=(\d+) mp=(\d+) items=(\S*)")
MODE = re.compile(r"\[bench\] mode t=(-?\d+) pid=(\d+) (\S+) (\S+) (-?[\d.]+) alive=(\d) hp=([\d.]+) amenaza=([\d.]+) x=(-?\d+) y=(-?\d+)")
POS = re.compile(r"prop pos t=(-?[\d.]+) pid=(\d+) x=(-?\d+) y=(-?\d+)")
EST = re.compile(r"prop estado t=(-?[\d.]+) pid=(\d+) intencion=(\S+) vida=([\d.]+) mana=([\d.]+) modo=(\d+)")
DEC = re.compile(r"prop decision t=(-?[\d.]+) pid=(\d+) intencion=(\S+) motivo=(.*)$")
DANO = re.compile(r"obs t=(\d+) dano (\S+)")
KILL = re.compile(r"obs t=(\d+) kill victim=(\S+) vteam=(\d) vpid=(\d+) killer=(\S*) kteam=(\d*) kpid=(-?\d*)")
CAST = re.compile(r"obs t=(\d+) cast pid=(\d+) (\S+) (\S+)")
LINEA = re.compile(r"\[bench\] linea t=(\d+) pid=(\d+) team=(\d) heroe=(\S+) lh=(\d+) dn=(\d+) nw=(\d+) oro=(-?\d+) nivel=(\d+) muertes=(\d+) kills=(\d+)")
OLINEA = re.compile(r"obs t=(\d+) linea pid=(\d+) (\S+) alive=(\d) x=(-?\d+) y=(-?\d+) hp=(\d+) maxhp=(\d+) mp=(\d+) xp=(\d+) dmg=(\d+) aps=([\d.]+) rango=(\d+)")
INGRESOS = re.compile(r"obs t=(\d+) ingresos pid=(\d+) (\S+) oro=(\S*) xp=(\S*)")
CK = re.compile(r"obs t=(\d+) creepkill victim=(\S+) vteam=(\d) killer=(\S+) kteam=(\d) kpid=(-?\d+) inflictor=(\S+) x=(-?\d+) y=(-?\d+) d=(\d+)")

rows = list(csv.DictReader(open(os.path.join(repo, "bench", "series.csv"), encoding="utf-8", errors="replace")))
games = []
for r in rows:
    if r.get("valida") != "si" or r.get("variante") not in ("control_sniper", "base_sniper", "control_sniper_sincombate"):
        continue
    name = f"{r['etiqueta']}-{re.sub(r'[-:T]', '', r['fecha'])}-{r['partida']}.log"
    path = os.path.join(OBS, name)
    if not os.path.exists(path):
        continue
    H = collections.defaultdict(dict)  # pid -> t -> dict
    team = {}
    names = {}
    pos = collections.defaultdict(list)  # pid -> (t,x,y,hp)
    modes = collections.defaultdict(list)  # pid -> (t, mode)
    kills = []
    dano = []
    casts = collections.Counter()
    casts_t = []
    dec = []
    est = []
    linea = []
    ingresos = {}
    oline = collections.defaultdict(list)
    ck = []
    for l in open(path, encoding="latin1"):
        if "[bench] " not in l and "[dotabench] " not in l:
            continue
        m = MODE.search(l)
        if m:
            t, pid = int(m[1]), int(m[2])
            names[pid] = m[3]
            modes[pid].append((t, m[4]))
            pos[pid].append((t, int(m[9]), int(m[10]), float(m[7]), int(m[6])))
            continue
        m = POS.search(l)
        if m:
            pos[int(m[2])].append((float(m[1]), int(m[3]), int(m[4]), None, 1))
            continue
        m = EST.search(l)
        if m:
            est.append((float(m[1]), m[3], float(m[4]), float(m[5]), int(m[6])))
            continue
        m = DEC.search(l)
        if m:
            dec.append((float(m[1]), m[3], m[4].strip()[:60]))
            continue
        m = HERO.search(l)
        if m:
            t, pid = int(m[1]), int(m[2])
            team[pid] = int(m[3])
            names[pid] = m[4]
            H[pid][t] = dict(lvl=int(m[5]), gold=int(m[6]), nw=int(m[7]), lh=int(m[8]), dn=int(m[9]), k=int(m[10]), d=int(m[11]), a=int(m[12]), alive=int(m[13]), x=int(m[14]), y=int(m[15]), items=m[18])
            continue
        m = DANO.search(l)
        if m:
            t = int(m[1])
            for it in m[2].split(","):
                q = re.match(r"^(.+)>(.+):(.+):(\d+):(\d+)$", it)
                if q:
                    dano.append((t, q[1], q[2], q[3], int(q[4]), int(q[5])))
            continue
        m = KILL.search(l)
        if m:
            kills.append(dict(t=int(m[1]), victim=m[2], vteam=int(m[3]), vpid=int(m[4]), killer=m[5], kteam=int(m[6] or 0), kpid=int(m[7] or -1)))
            continue
        m = CAST.search(l)
        if m:
            casts[(int(m[2]), m[4])] += 1
            casts_t.append((int(m[1]), int(m[2]), m[4]))
            continue
        m = LINEA.search(l)
        if m:
            linea.append(dict(t=int(m[1]), pid=int(m[2]), team=int(m[3]), lh=int(m[5]), dn=int(m[6]), nw=int(m[7]), oro=int(m[8]), nivel=int(m[9]), muertes=int(m[10]), kills=int(m[11])))
            continue
        m = OLINEA.search(l)
        if m:
            oline[int(m[2])].append((int(m[1]), int(m[4]), int(m[5]), int(m[6]), int(m[7]), int(m[8]), int(m[11]), float(m[12]), int(m[13])))
            continue
        m = INGRESOS.search(l)
        if m:
            ingresos.setdefault(int(m[2]), []).append((int(m[1]), m[4], m[5]))
            continue
        m = CK.search(l)
        if m:
            ck.append((int(m[1]), m[2], int(m[3]), m[4], int(m[5]), int(m[6]), m[7]))
            continue
    if not linea:
        continue
    pid = linea[0]["pid"]
    tm = linea[0]["team"]
    games.append(dict(
        etiqueta=r["etiqueta"], partida=r["partida"], fecha=r["fecha"], variante=r["variante"], bloque=r["bloque"],
        rival=r.get("rival"), corte=r.get("corte"), codigo=(r.get("codigo") or "")[:7], lado=r["dotabot"], heroes=r["heroes"],
        fijos=r.get("heroes_fijos"), ganador=r.get("ganador"), resultado=r.get("resultado"), minutos=r.get("minutos"), torres=r.get("torres_fin"),
        cpu=r.get("cpu_media"), vmax=r.get("ventaja_oro_max"), krad=r.get("kills_radiant"), kdir=r.get("kills_dire"),
        pid=pid, team=tm, names=names, teams=team, H=H, pos=pos, modes=modes, kills=kills, dano=dano,
        casts={f"{a}|{b}": c for (a, b), c in casts.items()}, casts_t=casts_t, dec=dec, est=est, linea=linea, oline=oline, ingresos=ingresos, ck=ck,
    ))
    print(name, len(kills), len(dano), file=sys.stderr)
json.dump(games, open(out, "w"))
print(len(games), "games")
