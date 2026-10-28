# ML/RL approaches to high-level Dota 2 bots: OpenAI Five and after (state as of 2026-10-28)

Method note: ~17 search/fetch calls. The primary paper PDF (cdn.openai.com/dota-2.pdf) could not be parsed by WebFetch; numbers below come from an ar5iv HTML fetch (first 100k of 184k characters read, via a small summarizing model, so treat exact figures as "read via summarizer", not hand-verified). openai.com blog pages returned 403; blog figures come from search snippets of secondary coverage. Searches for 2025-2026 Dota-specific research returned very little; that absence is itself a finding, but search coverage was shallow.

## 1. OpenAI Five (2017-2019): architecture, observations, actions, training, compute

### Takeaway
OpenAI Five was ordinary PPO + self-play scaled enormously: a single 4096-unit LSTM (~159M params), ~16k-value observations, ~8k-80k discrete actions, batches of 1-3M timesteps, ~10 months of training with "surgery" to preserve progress across environment/architecture changes. It beat OG 2-0 on 2019-04-13 with a 17-hero pool.

### Cited Findings
- Paper: "Dota 2 with Large Scale Deep Reinforcement Learning", arXiv:1912.06680, 25 authors, submitted 13 Dec 2019; abstract: scaled existing RL methods, custom distributed training and continual-training tools, trained over 10 months, beat world champions OG in April 2019, public arena 99.4% of >7000 games — [arXiv](https://arxiv.org/abs/1912.06680)
- Agent acts every 4th frame (engine 30 FPS, ~0.133 s per step, ~20,000 steps per 45-minute game) — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Model: single-layer LSTM with 4096 units (was 2048 before a surgery doubled it); ~159M parameters (158,502,815 at final surgery per Table 1), LSTM ~84% of parameters — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Observation ~16,000 values per timestep (floats+categoricals); the task brief's "~20k" is approximate, paper summary read gives ~16k — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Action space ~8,000-80,000 discrete actions per timestep depending on hero (not all valid at once, masked) — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Training: 30 Jun 2018 to 22 Apr 2019; ~180 days training; "over twenty surgeries" (~one per 2 weeks); paper estimates restarting each time would have taken ~40 months vs 10 — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Compute: 770 ± 50 PFlops/s-days at the OG match, 820 ± 50 at shutdown; "Rerun" (retrain from scratch with surgery-free recipe) used 150 ± 5 PFlops/s-days over ~2 months — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Batch size 1-3M timesteps (peak 2,949,120 = 120 samples x 16 timesteps x up to 1,536 GPUs); Rerun 983,040; Rerun used 512 optimizer GPUs, 512 rollout GPUs, 51,200 rollout CPUs — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Hyperparameters: lr 5e-5 (Rerun ended 5e-6), entropy coef 0.01 -> 0.001, GAE lambda 0.95, PPO clip 0.2, GAE horizon 180 s -> 360 s in Rerun — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Team spirit: reward blend parameter, 0.3 at start; Rerun to 0.8, OpenAI Five schedule up to 1.0 — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Hand-scripted (not learned): item purchase order, ability order, courier, item reserves — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Surgery appendix: Adam lr set to 0 for first several hours after a surgery; gradients clipped; staleness target 0-1, ~8 versions of staleness caused significant slowdown — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Hero pool: 17 of 117 heroes — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680); also stated in secondary source [theneuralbase](https://theneuralbase.com/ai-for-gaming/learn/advanced/openai-five-dota-2/)
- Results: beat OG 2-0 (Bo3) 13 Apr 2019; avg reaction time 217 ms vs ~250 ms human; Arena 99.4% over >7000 games. Note: the summarizer flagged an apparent inconsistency in the paper's raw game counts in the arena text; verify against the PDF before quoting exact counts — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Infrastructure (2018 blog, via secondary coverage): 256 GPUs and 128,000 CPU cores, ~180 years of game experience per day (~900 years/day counting each hero separately); the 1v1 bot used 60,000 CPU cores on Azure and 256 K80 GPUs and ~300 years/day — [Register](https://www.theregister.co.uk/2018/06/25/openai_dota_2/), [PCGamesN](https://www.pcgamesn.com/dota-2-open-ai-match), [Wikipedia](https://en.wikipedia.org/wiki/OpenAI_Five); blog [openai.com/research/openai-five](https://openai.com/research/openai-five) (not directly fetched, 403)
- Appendix mentions a "Dota 2 Gym Environment" and Rapid platform; the Dota 2 bot API is Lua-based with a Go gRPC helper process wrapping the environment per another summary (not verified against the paper text) — [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680), [kiiiiii123 notes](https://kiiiiii123.github.io/2020/05/31/post_67.html)

### Inferences
- The 770 PFlops/s-days figure and 128k CPU / 256 GPU cluster put training in the multi-million-USD range at cloud prices; I found no official dollar figure (do not quote one).
- The "Rerun" result (150 PF/s-days, ~5x less than the main run, ~2 months) shows the compute can be cut substantially with a known recipe, but is still orders of magnitude beyond a hobbyist.

### Gaps
- Exact PDF text not read; the 1v1 Shadow Fiend (TI 2017) details, exact reward-shaping table, and "observation every 4 frames" confirmation beyond frame-skip 4 not independently verified. No dollar-cost estimate found. Whether the paper mentions gRPC: summarizer said no for the portion read.

## 2. How OpenAI interfaced with the game; speed constraints

### Takeaway
Valve's Lua bot scripting API (restricted to prevent cheating) is the only sanctioned interface; the game's console var `host_timescale` speeds it up; community projects report ~10x real time per headless server.

### Cited Findings
- Valve bot scripting is Lua, and the API is restricted (no fog-of-war queries, no controlling units you don't own) — [Valve Developer Wiki](https://developer.valvesoftware.com/wiki/Dota_Bot_Scripting)
- `host_timescale` is the console variable used for speedup; luafun docs expose a speed multiplier option (default 2) and a dedicated-server option — [luafun docs](https://luafun.readthedocs.io/en/latest/pages/options.html)
- Dota 2 dedicated servers run on Windows/Linux/macOS (AlliedMods forum, old) — [AlliedMods](https://forums.alliedmods.net/archive/index.php/t-236635.html)
- dotasim (Oct 2026): headless Linux server under WSL2, 12 servers at ~10x real time each, ~62x real time aggregate with replay recording and 72x without, each server ~1 GB RAM + half a CPU core — [wience/dotasim](https://github.com/wience/dotasim)
- dotaservice README: `reset()` ~5 s, `step()` 10-30 ms — [dotaservice](https://github.com/TimZaman/dotaservice)

### Inferences
- A practical speed ceiling for one hobbyist machine is roughly 10x per game instance, scaled by running many instances in parallel limited by CPU/RAM; I found no documented hard cap beyond that.

### Gaps
- `-botworldstatesocket` flag: no source found documenting it. A 2024 Reddit question on headless bot games went unanswered in results. Not verified whether Valve's current Linux dedicated server runs bot Lua scripts headless without a display beyond dotasim's claim.

## 3. Open-source reproductions/environments and 2026 status

### Takeaway
Tim Zaman's dotaservice (2018-19) is effectively abandoned; the only fresh (Oct 2026) project found is dotasim, an early-stage 1v1 mid self-play harness whose own README reports imitation learning failed its criterion and self-play has barely started.

### Cited Findings
- dotaservice: gRPC service, OpenAI-Gym-like Python client, Python 3.7, macOS/Ubuntu, Dockerfile provided (local build, port 13337), 133 stars, 21 forks, 11 open issues; newest open issue Feb 2019; one client per server, one service per VM — [dotaservice](https://github.com/TimZaman/dotaservice), [issues](https://github.com/TimZaman/dotaservice/issues)
- dotasim (wience): MIT, Python 3.12/uv, needs ~73 GB Dota 2 Linux install via SteamCMD app 570, PPO updates on AMD GPU via ROCm 7.2, 108 commits, 0 stars; Phase 2 imitation exit criterion not met; Phase 3 self-play training "barely started"; patch compatibility not stated — [wience/dotasim](https://github.com/wience/dotasim)
- Other repos (small, mostly toy/old): pydota2_archive (archived), Cobaramin/Dota2Bot (creep-block DDPG), karvozavr/DotA-DeepRL (incomplete), Mohsen-Arshad/DotaBotAI (tabular Q-learning on a synthetic env, not the real game), d2ai (C++ API over Lua via HTTP), luafun (Lua/Python wrapper docs) — [search results](https://github.com/pydota2/pydota2_archive), [Dota2Bot](https://github.com/Cobaramin/Dota2Bot), [DotA-DeepRL](https://github.com/karvozavr/DotA-DeepRL), [DotaBotAI](https://github.com/Mohsen-Arshad/DotaBotAI), [d2ai](https://github.com/2aius/d2ai)
- Community Lua bots still maintained (e.g., OpenHyperAI) say playstyle is limited by Valve's bot API; a community changelog notes a Valve update broke bot API functions and froze bots (year not shown) — [OpenHyperAI](https://github.com/forest0xia/dota2bot-OpenHyperAI), [Steam workshop changelog](https://steamcommunity.com/sharedfiles/filedetails/changelog/2873408973)

### Inferences
- dotaservice's Python 3.7 / 2019 bot-API assumptions almost certainly break against the 2026 game (many patches since; Valve does not announce bot-API changes); treat as reference code, not a working tool. Not tested by me.

### Gaps
- Did not test any repo; dotaservice commit dates/closed issues not seen; no verification of a working public Docker image; DotaGym / "Dota2AI by Chris" not found.

## 4. Other notable systems and recent work (2020-2026)

### Takeaway
The MOBA analog with the most open follow-up work is Tencent's Honor of Kings (JueWu); for Dota 2 itself I found no 2023-2026 RL or LLM-agent papers, only drafting/win-prediction work and LLM assistants.

### Cited Findings
- Tencent: "Towards Playing Full MOBA Games with Deep RL" (NeurIPS 2020, arXiv 2011.12692), full 5v5 with large hero pool and drafting where minimax is infeasible — [NeurIPS paper](https://papers.neurips.cc/paper_files/paper/2020/file/06d5ae105ea1bea4d800bc96491876e9-Paper.pdf), [arXiv](https://arxiv.org/pdf/2011.12692v3)
- JueWu-SL (supervised learning, ~High King level in 5v5) — [arXiv 2011.12582](https://arxiv.org/pdf/2011.12582)
- Honor of Kings Arena (2022): open RL environment, 20 target heroes — [arXiv 2209.08483](https://arxiv.org/pdf/2209.08483)
- Hokoff (2024): real-game Honor of Kings offline RL dataset and benchmarks — [arXiv 2408.10556](https://arxiv.org/pdf/2408.10556)
- RLHG (ICLR 2024): RL from human gain to build agents that help human players in Honor of Kings — [ICLR 2024 paper](https://proceedings.iclr.cc/paper_files/paper/2024/file/218cd617bd162199a13a5dcdea4a029d-Paper-Conference.pdf)
- Review: "A Comprehensive Review of Multi-Agent RL in Video Games" (2025) — [arXiv 2509.03682](https://arxiv.org/pdf/2509.03682)
- Dota 2 drafting/prediction: Gourdeau & Archambault IEEE ToG 2019 (next-pick in top-3 17.6% for Dota 2), "Which Heroes to Pick?" (2020, tree search + NN) , outcome prediction ML (2021) — [ToG](https://transactions.games/spotlight/discriminative-neural-network-for-hero-selection-in-professional-heroes-of-the-storm-and-dota-2), [arXiv 2012.10171](https://fugumt.com/fugumt/paper_check/2012.10171v1_enmode), [arXiv 2106.01782](https://arxiv.org/pdf/2106.01782)
- LLM/Dota: only assistants found: a local-LLM Dota spell-interaction assistant (dota-gpt) and a Phi-3 Mini fine-tune on Captains Mode drafts (Medium); no LLM that actually plays — [dota-gpt](https://github.com/Nishanthkeelanur/dota-gpt), [Medium](https://medium.com/@sanket_mhaiskar/fine-tuning-an-llm-on-dota-2-captains-mode-drafts-my-journey-to-building-a-draft-e67bf2de14c0)
- General VLM/LLM game-agent benchmarks 2024-2026 (none verified to include a MOBA): BALROG, VS-Bench, GameWorld (2604.07429), OmniGameArena (2606.09826), RTSGameBench (2606.18950) — [BALROG](https://arxiv.org/html/2411.13543v2), [VS-Bench](https://arxiv.org/pdf/2506.02387), [GameWorld](https://arxiv.org/pdf/2604.07429), [OmniGameArena](https://arxiv.org/pdf/2606.09826), [RTSGameBench](https://arxiv.org/pdf/2606.18950)
- Commentary (unverified secondary): general LLM APIs are too high-latency for millisecond-level real-time Dota control — [theneuralbase](https://theneuralbase.com/ai-for-gaming/learn/advanced/openai-five-dota-2/)

### Inferences
- Any LLM Dota agent would need to be a high-level planner on top of a fast low-level policy; no evidence that anyone has demonstrated this.

### Gaps
- No Dota 2 imitation-learning-from-replays paper 2023-2026 found; no hierarchical-RL MOBA paper beyond Tencent line found; Cradle-like Dota demos not found; Reddit r/reinforcementlearning and r/DotA2 not searched directly; Tencent's 2025-26 output not found.

## 5. Practical feasibility for an individual developer (2026)

### Takeaway
Full 5v5 is out of reach; a single-hero 1v1 mid or sub-skills (last hitting, creep blocking) are plausible with many CPU-hosted accelerated game instances plus one GPU, but I found no public evidence of anyone reaching strong results, and the freshest project (dotasim) reports negative imitation results so far.

### Cited Findings
- Reference scale: OpenAI's 1v1 bot used 60k CPU cores/256 K80 GPUs; Five used 128k CPUs/256 GPUs; the 2019 paper's Rerun alone used 51,200 rollout CPUs — [Register](https://www.theregister.co.uk/2018/06/25/openai_dota_2/), [ar5iv](https://ar5iv.labs.arxiv.org/html/1912.06680)
- One desktop: 12 headless servers at ~10x real time each; ~72x aggregate; ~1 GB RAM and 0.5 CPU core per server; AMD GPU PPO via ROCm — [dotasim](https://github.com/wience/dotasim)
- Setup cost: ~73 GB game install per host — [dotasim](https://github.com/wience/dotasim)
- Small tasks done before: creep-block DDPG repo — [Dota2Bot](https://github.com/Cobaramin/Dota2Bot)

### Inferences (not from sources)
- At ~72x aggregate, one machine yields ~72 game-seconds per wall-second, i.e. 72 x 86,400 s = ~6.2M game-seconds/day = ~72 game-days/day (~0.2 years/day) versus OpenAI Five's ~180 years/day, roughly 900x less. This is my arithmetic from dotasim's figure, not a reported comparison.
- Imitation learning from replays is hampered because the bot API is Lua-restricted and replay-to-observation conversion must match the API's observation; dotasim's failed imitation criterion is consistent with that difficulty (cause not stated by source).
- No cost estimates in USD were found; any budget figure would be speculation.

### Gaps
- No documented cloud cost for any Dota RL training run; no evidence on Valve ToS/anti-cheat constraints beyond bot scripting being a sanctioned custom-game/lobby feature; no benchmark of last-hitting/1v1 RL results from the real 2026 game.
