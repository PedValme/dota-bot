#!/usr/bin/env python
"""Team-level effect of who plays the Sniper, plus variance components. Numbers only; bootstrap and permutation with numpy."""
import json, sys, collections, re
import numpy as np
G = json.load(open(sys.argv[1]))
rng = np.random.default_rng(20261106)

def at(H, pid, t):
    d = H.get(str(pid), {})
    if str(t) in d: return d[str(t)]
    return None

def feats(g):
    pid, tm = g["pid"], g["team"]
    teams = {int(k): v for k, v in g["teams"].items()}
    allies = [p for p, v in teams.items() if v == tm and p != pid]
    foes = [p for p, v in teams.items() if v != tm]
    f = dict(et=g["etiqueta"], var=g["variante"], riv=g["rival"], code=g["codigo"], lado=g["lado"], fijos=g["fijos"], heroes=g["heroes"], part=g["partida"], res=g["resultado"], cpu=g["cpu"], ganador=g["ganador"], bloque=g["bloque"])
    for T in (300, 600, 900, 1200, 1500):
        s = at(g["H"], pid, T)
        if s is None: continue
        al = [at(g["H"], p, T) for p in allies]
        fo = [at(g["H"], p, T) for p in foes]
        if any(x is None for x in al + fo): continue
        tag = f"_{T//60}"
        f["s_nw" + tag] = s["nw"]; f["s_gold" + tag] = s["gold"]; f["s_item" + tag] = s["nw"] - max(s["gold"], 0)
        f["s_lh" + tag] = s["lh"]; f["s_dn" + tag] = s["dn"]; f["s_k" + tag] = s["k"]; f["s_d" + tag] = s["d"]; f["s_a" + tag] = s["a"]; f["s_lvl" + tag] = s["lvl"]
        f["al_nw" + tag] = sum(x["nw"] for x in al); f["al_k" + tag] = sum(x["k"] for x in al); f["al_d" + tag] = sum(x["d"] for x in al)
        f["al_item" + tag] = sum(x["nw"] - max(x["gold"], 0) for x in al); f["al_gold" + tag] = sum(max(x["gold"], 0) for x in al)
        f["fo_nw" + tag] = sum(x["nw"] for x in fo); f["fo_k" + tag] = sum(x["k"] for x in fo); f["fo_d" + tag] = sum(x["d"] for x in fo)
        f["fo_item" + tag] = sum(x["nw"] - max(x["gold"], 0) for x in fo); f["fo_gold" + tag] = sum(max(x["gold"], 0) for x in fo)
        f["t_diff" + tag] = s["nw"] + f["al_nw" + tag] - f["fo_nw" + tag]
        f["t_itemdiff" + tag] = s["nw"] - max(s["gold"], 0) + f["al_item" + tag] - f["fo_item" + tag]
        f["t_k" + tag] = s["k"] + f["al_k" + tag]
        f["t_kdiff" + tag] = f["t_k" + tag] - f["fo_k" + tag]
        f["k_share" + tag] = s["k"] / max(f["t_k" + tag], 1)
        f["kp" + tag] = (s["k"] + s["a"]) / max(f["t_k" + tag], 1)
    return f

F = [feats(g) for g in G]
def sel(**kw):
    out = []
    for f in F:
        ok = True
        for k, v in kw.items():
            if k == "et_re":
                ok = ok and re.fullmatch(v, f["et"]) is not None
            else:
                ok = ok and f[k] == v
        if ok: out.append(f)
    return out
def col(rows, k): return np.array([r[k] for r in rows if k in r], float)
def boot_ci(a, b, n=20000):
    if len(a) == 0 or len(b) == 0: return (np.nan, np.nan)
    da = rng.choice(a, (n, len(a))).mean(1); db = rng.choice(b, (n, len(b))).mean(1)
    return tuple(np.percentile(da - db, [2.5, 97.5]))
def perm_p(a, b, n=20000):
    if len(a) == 0 or len(b) == 0: return np.nan
    obs = abs(a.mean() - b.mean()); z = np.concatenate([a, b]); c = 0
    for _ in range(n):
        rng.shuffle(z)
        c += abs(z[:len(a)].mean() - z[len(a):].mean()) >= obs - 1e-9
    return (c + 1) / (n + 1)
def cmp(a_rows, b_rows, keys, la="A", lb="B"):
    print(f"{'metric':16s} {la:>10s} (sd) {lb:>10s} (sd)   diff   [boot95]    perm_p  n={len(a_rows)}/{len(b_rows)}")
    for k in keys:
        a, b = col(a_rows, k), col(b_rows, k)
        if len(a) == 0 or len(b) == 0: continue
        lo, hi = boot_ci(a, b)
        print(f"{k:16s} {a.mean():10.2f} ({a.std(ddof=1) if len(a)>1 else 0:7.1f}) {b.mean():10.2f} ({b.std(ddof=1) if len(b)>1 else 0:7.1f}) {a.mean()-b.mean():8.2f} [{lo:8.1f},{hi:8.1f}] p={perm_p(a,b):.4f} n={len(a)}/{len(b)}")

keys25 = ["t_diff_25", "t_itemdiff_25", "t_kdiff_25", "t_k_25", "fo_k_25", "s_nw_25", "s_item_25", "s_gold_25", "s_lh_25", "s_k_25", "s_a_25", "s_d_25", "s_lvl_25", "al_nw_25", "al_item_25", "al_gold_25", "al_k_25", "al_d_25", "fo_nw_25", "fo_item_25", "fo_gold_25", "k_share_25", "kp_25"]
keys10 = ["t_diff_10", "t_kdiff_10", "s_nw_10", "s_lh_10", "s_k_10", "s_d_10", "s_a_10", "al_nw_10", "al_k_10", "al_d_10", "fo_nw_10", "fo_k_10", "k_share_10", "kp_10"]

print("### 1. Matched heroes vs OHA team: same code as fijo-p5 (p2+p5) vs OHA, min 25")
oha = sel(et_re=r"fijo-oha-[ab]")
own = sel(et_re=r"fijo-p[25]-[ab]")
cmp(own, oha, keys25, "propio", "OHA")
for m in "ab":
    print(f"--- matchup {m}")
    cmp(sel(et_re=rf"fijo-p[25]-{m}"), sel(et_re=rf"fijo-oha-{m}"), ["t_diff_25", "t_itemdiff_25", "t_kdiff_25", "s_item_25", "s_gold_25", "s_k_25", "al_k_25", "al_nw_25", "fo_k_25"], "propio", "OHA")
print("\n--- min 10, same")
cmp(own, oha, keys10, "propio", "OHA")
print("\n--- trajectories team NW diff (propio p2+p5 | OHA)")
for t in (5, 10, 15, 20, 25):
    a, b = col(own, f"t_diff_{t}"), col(oha, f"t_diff_{t}")
    print(t, round(a.mean()), round(a.std(ddof=1)), "|", round(b.mean()), round(b.std(ddof=1)), "alldiff", np.round(a).astype(int).tolist(), np.round(b).astype(int).tolist())

print("\n### 2. Random draws vs OHA team: all own presion* (latest 3 codes) vs presion-oha")
cmp(sel(et_re=r"presion[67]"), sel(et="presion-oha"), keys25, "propio", "OHA")
print("\n### 3. All vs OHA-team games of own (any code) vs all OHA-arm vs OHA-team")
cmp(sel(var="control_sniper", riv="dotabot"), sel(var="base_sniper", riv="dotabot"), keys25, "propio", "OHA")

print("\n### 4. conf1 vs Valve, paired by design, min 10 (unpaired print)")
cmp(sel(et_re=r"conf1-[abc]", var="control_sniper"), sel(et_re=r"conf1-[abc]", var="base_sniper"), keys10, "propio", "OHA")

print("\n### 5. Identical-code noise: fijo-p2 vs fijo-p5, by metric (same code, same heroes)")
cmp(sel(et_re=r"fijo-p2-[ab]"), sel(et_re=r"fijo-p5-[ab]"), ["s_lh_25", "s_nw_25", "s_item_25", "s_k_25", "s_d_25", "t_diff_25", "t_kdiff_25"], "p2", "p5")

print("\n### 6. Variance components, within same code+matchup (residual SD) from fijo-p2/p5, and sample size for 80% power")
keys = ["s_lh_25", "s_nw_25", "s_item_25", "s_k_25", "s_d_25", "t_diff_25", "t_kdiff_25", "t_itemdiff_25", "s_lh_10", "s_nw_10", "s_d_10", "s_k_10", "t_diff_10"]
Z = 2.8
for k in keys:
    res = []
    for m in "ab":
        v = col(sel(et_re=rf"fijo-p[25]-{m}"), k)
        res += list(v - v.mean())
    res = np.array(res)
    sd = np.sqrt((res ** 2).sum() / (len(res) - 2))
    m_all = col(own, k).mean()
    n10 = 2 * (Z * sd / (0.10 * abs(m_all))) ** 2 if m_all else float("nan")
    n20 = 2 * (Z * sd / (0.20 * abs(m_all))) ** 2 if m_all else float("nan")
    print(f"{k:16s} mean {m_all:10.1f} residSD {sd:9.1f} CV {sd/abs(m_all):5.2f}  n/arm for 10%: {n10:7.0f}  20%: {n20:6.0f}")

print("\n### 7. Own arm: side effect within matched games (Radiant vs Dire)")
cmp([f for f in own if f["lado"] == "radiant"], [f for f in own if f["lado"] == "dire"], ["t_diff_25", "s_lh_25", "s_k_25", "s_d_25"], "rad", "dire")
cmp([f for f in oha if f["lado"] == "radiant"], [f for f in oha if f["lado"] == "dire"], ["t_diff_25", "s_lh_25", "s_k_25", "s_d_25"], "rad", "dire")

print("\n### 8. Ended before cut (survivorship in pulido.mjs)")
for f in F:
    if f["riv"] and f["et"].startswith(("medio", "presion", "fijo")) and "t_diff_25" not in f:
        print(f["et"], f["part"], f["var"], f["res"], f["ganador"], f["lado"])

print("\n### 9. Per-game table fijo")
for f in sel(et_re=r"fijo-.*"):
    print(f["et"], f["part"], f["lado"], "tdiff25", f.get("t_diff_25"), "items", f.get("t_itemdiff_25"), "tK", f.get("t_k_25"), "foK", f.get("fo_k_25"), "sK", f.get("s_k_25"), "sD", f.get("s_d_25"), "sLH", f.get("s_lh_25"), "sItem", f.get("s_item_25"), "sGold", f.get("s_gold_25"))
json.dump(F, open(sys.argv[1].replace("games.json", "feats.json"), "w"))
