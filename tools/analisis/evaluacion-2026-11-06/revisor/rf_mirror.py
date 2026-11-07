#!/usr/bin/env python
"""Mirror check in the OHA arm, Sniper idle by arm, allies' deaths and rival NW tests with strata, base win rate by period."""
import pickle, re, collections
import numpy as np
G = pickle.load(open("games.pkl", "rb"))
rng = np.random.default_rng(1)
def A(g): return 2 if g["r"]["dotabot"] == "radiant" else 3
def valid(g): return g["r"]["valida"] == "si"
def perm(a, b, n=20000):
    a, b = np.asarray(a, float), np.asarray(b, float); z = np.r_[a, b]; o = abs(a.mean() - b.mean()); c = 0
    for _ in range(n):
        rng.shuffle(z); c += abs(z[:len(a)].mean() - z[len(a):].mean()) >= o - 1e-9
    return (c + 1) / (n + 1)
def st(g):
    a = A(g); sn = [p for p, tm in g["team"].items() if tm == a and g["hero"][p] == "sniper"][0]
    al = [p for p, tm in g["team"].items() if tm == a and p != sn]; fo = [p for p, tm in g["team"].items() if tm != a]
    s = lambda ps, k: sum(g["snap"][p][1500][k] for p in ps)
    return dict(lead=s(al + [sn], "nw") - s(fo, "nw"), klead=s(al + [sn], "k") - s(fo, "k"), ald=s(al, "d"), fonw=s(fo, "nw"), alnw=s(al, "nw"), snidle=g["snap"][sn][1500]["gold"] / g["snap"][sn][1500]["nw"], snnw=g["snap"][sn][1500]["nw"], side=g["r"]["dotabot"], alidle=s(al, "gold") / s(al, "nw"), foidle=s(fo, "gold") / s(fo, "nw"))
sel = lambda pat: [st(g) for g in G if valid(g) and re.fullmatch(pat, g["r"]["etiqueta"]) and g["r"].get("corte") == "25"]
O = sel(r"presion-oha|fijo-oha-[ab]")
print("OHA arm (same code both teams): NW lead per game", [q["lead"] for q in O], "mean", np.mean([q["lead"] for q in O]), "K lead", [q["klead"] for q in O])
print("  sign: lead>0 in", sum(q["lead"] > 0 for q in O), "of", len(O), " by block mean", [int(np.mean([O[i]["lead"], O[i + 1]["lead"]])) for i in range(0, 8, 2)])
P = sel(r"fijo-p[25]-[ab]|presion[67]"); PA = sel(r"fijo-p\d-[ab]|presion[2-8]|presion-propio")
print("propio last (n=%d) NW lead mean %.0f, lead>0 %d; all (n=%d) mean %.0f, lead>0 %d" % (len(P), np.mean([q["lead"] for q in P]), sum(q["lead"] > 0 for q in P), len(PA), np.mean([q["lead"] for q in PA]), sum(q["lead"] > 0 for q in PA)))
print("  perm lead OHA vs last", perm([q["lead"] for q in O], [q["lead"] for q in P]), "vs all", perm([q["lead"] for q in O], [q["lead"] for q in PA]))
print("idle: Sniper OHA %.2f propio %.2f | allies OHA arm %.2f propio arm %.2f | rival OHA arm %.2f propio arm %.2f" % (np.mean([q["snidle"] for q in O]), np.mean([q["snidle"] for q in PA]), np.mean([q["alidle"] for q in O]), np.mean([q["alidle"] for q in PA]), np.mean([q["foidle"] for q in O]), np.mean([q["foidle"] for q in PA])))
print("Sniper item value: OHA %.0f propio %.0f" % (np.mean([q["snnw"] * (1 - q["snidle"]) for q in O]), np.mean([q["snnw"] * (1 - q["snidle"]) for q in P])))
print("ally deaths perm: OHA", np.mean([q["ald"] for q in O]), "vs all", np.mean([q["ald"] for q in PA]), perm([q["ald"] for q in O], [q["ald"] for q in PA]), "| vs last", np.mean([q["ald"] for q in P]), perm([q["ald"] for q in O], [q["ald"] for q in P]))
print("rival NW: OHA", np.mean([q["fonw"] for q in O]), "vs all", np.mean([q["fonw"] for q in PA]), perm([q["fonw"] for q in O], [q["fonw"] for q in PA]), "| vs last", np.mean([q["fonw"] for q in P]), perm([q["fonw"] for q in O], [q["fonw"] for q in P]))
for m in "ab":
    a = sel(rf"fijo-oha-{m}"); b = sel(rf"fijo-p[25]-{m}")
    print(f" set {m}: ald OHA {[q['ald'] for q in a]} p2p5 {[q['ald'] for q in b]} rivalNW OHA {[q['fonw'] for q in a]} p2p5 mean {np.mean([q['fonw'] for q in b]):.0f} lead OHA {[q['lead'] for q in a]} p2p5 mean {np.mean([q['lead'] for q in b]):.0f}")
print("ally deaths vs own Sniper deaths?")
# hero composition of allies in sort arms
# win rate base vs Valve by period and code
W = collections.defaultdict(lambda: [0, 0])
for g in G:
    r = g["r"]
    if not valid(g) or r["resultado"] not in ("final", "tope") or r["variante"] not in ("base", "base_b", ""): continue
    a = "radiant" if A(g) == 2 else "dire"
    k = ("pre" if r["fecha"] < "2026-10-31T04:41" else ("post-S4fixed" if r["fecha"] >= "2026-11-01" else "post-oct31"), r["dotabot"])
    W[k][0] += r["ganador"] == a; W[k][1] += 1
print("base vs Valve wins by period/side", dict(W))
