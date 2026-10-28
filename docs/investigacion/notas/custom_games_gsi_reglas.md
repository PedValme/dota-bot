# Official Valve interfaces around Dota 2 for bots: Workshop/custom games, GSI, Web API/replays, and rules (as of 28 Oct 2026)

Method note: Valve's developer wiki (developer.valvesoftware.com), openai.com, esports.gg and win.gg returned 403/410 to the fetch tool, so several wiki facts below come from search-result snippets or secondary sources and are flagged. No 2026-dated source was found for any topic; everything is dated as stated. Not legal advice.

## 1. Workshop Tools / custom games (VScript Lua, Panorama), Arcade status, RL-environment use

### Takeaway
Workshop Tools are a free Windows-only Steam DLC that let you author custom games (addons) with server-side Lua (VScript). Valve also has a separate "Dota Bot Scripting" Lua API that lets you replace the bots' AI. I found no 2025–2026 Valve change notice on either. Using a custom game as an RL environment is technically plausible, but I found no verified public example, only the LuaFun project using the bot-script route.

### Cited Findings
- Workshop Tools launched as an alpha in August 2014 as a free optional download; custom game modes are distributed via the Steam Workshop and uploaded from the Dota 2 client — [Valve developer post via Steam](https://steamcommunity.com/workshop/discussions/-1/35220315609182517/?appid=570); [Dota Workshop Tools FAQ (snippet)](https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Dota_Workshop_Tools_FAQ)
- Per the FAQ, after the content-system overhaul the tools support only custom game modes; cosmetics are handled through the Workshop website. Format changes can force creators to resubmit — [Dota Workshop Tools FAQ (search snippet)](https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Dota_Workshop_Tools_FAQ)
- The tools are Windows-only and installed as a DLC checkbox in Steam; launched through "Launch Dota 2 - Tools" — [Installing and Launching Tools (snippet)](https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Installing_and_Launching_Tools)
- Players install custom games from the Arcade tab (an undated Workshop comment) — [Steam comment](https://steamcommunity.com/sharedfiles/filedetails/comments/1809587874). Date unknown, low confidence.
- Valve's "Dota Bot Scripting" page: bots are scripted in Lua, files go in `vscripts/bots`, shared through the Workshop, and the API is restricted so scripts cannot cheat (for example, units in fog of war cannot be queried). The older function list is marked outdated and points to moddota.com/api — [Dota Bot Scripting](https://developer.valvesoftware.com/wiki/Dota_Bot_Scripting); [List of Dota 2 Script Functions](https://developer.valvesoftware.com/wiki/List_of_Dota_2_Script_Functions) (both via search snippets)
- Community bot-script projects exist (adamqqqplay/dota2ai, forest0xia/dota2bot-OpenHyperAI, Nostrademous/Dota2-FullOverwrite). One notes its playstyle is limited by Valve's bot scripting API — [adamqqqplay/dota2ai](https://www.github.com/adamqqqplay/dota2ai); [OpenHyperAI](https://github.com/forest0xia/dota2bot-OpenHyperAI)
- LuaFun (Python wrapper) exposes `host_timescale` (default 2), `dedicated` (default True, no rendering), `ticks_per_observation` (default 4, server at 30 fps), plus `interactive` and `draft` options. This shows a headless, sped-up, bot-script-driven Dota 2 is practical — [LuaFun options](https://luafun.readthedocs.io/en/latest/pages/options.html)
- OpenAI said early on that Dota did not support custom dedicated servers, so they stubbed out OpenGL calls to run headless. One practitioner report says a headless environment needs more than 1 GB RAM each — search-result summaries of [OpenAI blog](https://openai.com/blog/more-on-dota-2/) and the [LuaFun docs](https://luafun.readthedocs.io/en/latest/pages/options.html); not directly verified
- OpenAI Five acted on every 4th frame (engine at 30 fps), got structured observations ("all the information a human player would see"), and used hand-scripted logic for item purchase order and the courier — [arXiv 1912.06680 (ar5iv)](https://ar5iv.labs.arxiv.org/html/1912.06680)

### Inferences
- From background knowledge, not verified in this session: the custom-game VScript API (`ExecuteOrderFromTable`, `CDOTA_BaseNPC`, `GameRules`, `Timers`, `SetContextThink`) gives full server-side control of units and, in a local `dota2` tools session, the map and time can be accelerated. Custom games run on a custom map, not the standard 5v5 map unless you rebuild it, so an RL env for the real game fits better with the Bot Scripting route (LuaFun).
- Panorama (JS/XML UI) is client-side only and does not drive units. It is useful for a debug HUD, not for a policy.

### Gaps
- Could not fetch the Valve wiki pages, so exact signatures and semantics for `ExecuteOrderFromTable`, `Timers`, `SetContextThink` are unverified here (use moddota.com/api).
- No source on whether Workshop Tools or the Arcade changed in 2025–2026 (patch notes not checked).
- No verified example of a custom game used for RL training; no data on `host_timescale` in custom games.

## 2. Game State Integration (GSI)

### Takeaway
GSI is a one-way HTTP POST feed of game state to a local listener, configured by `gamestate_integration_<name>.cfg`. It carries no inputs, and outside spectating it exposes only the local player's data. Good for overlays and coaching, useless for control.

### Cited Findings
- File location: `game/dota/cfg/gamestate_integration/`, name `gamestate_integration_<CUSTOM NAME>.cfg`; contains `uri`, `timeout`, `buffer`, `throttle`, `heartbeat` and a `data` block — [antonpup/Dota2GSI](https://github.com/antonpup/Dota2GSI); [npm dota2-gsi](https://www.npmjs.com/package/dota2-gsi)
- Nodes: auth, provider, map, player, hero, abilities, items, events, buildings, league, draft, wearables, minimap, roshan, couriers, neutralitems — [antonpup/Dota2GSI](https://github.com/antonpup/Dota2GSI)
- All-players data only while spectating; in normal play only the local player (`IsSpectating`, `IsLocalPlayer`) — [antonpup/Dota2GSI](https://github.com/antonpup/Dota2GSI)
- A Rust crate says the `-gamestateintegration` launch option is required, a Japanese blog says restart is needed after editing the cfg; the Rust crate shows the cfg directly in cfg folder, conflicting with the subfolder path — search summary of [docs.rs/dota-gsi](https://docs.rs/dota-gsi)
- Windows gotcha: Explorer may create `.cfg.txt`, which Dota ignores — [dota2-cast-assist](https://github.com/data-mission/dota2-cast-assist)
- Overwolf documents enabling GSI for Dota 2 via a Steam launch option — [Overwolf support](https://support.overwolf.com/support/solutions/articles/9000212745-how-to-enable-game-state-integration-for-dota-2)

### Inferences
- GSI being a documented, Valve-provided feature, reading it is not itself cheating, but a tool that turns the data into live advice is subject to the third-party-software rules in section 4. Unverified by Valve statement.
- Cannot send inputs: the config only defines an outbound HTTP endpoint (supported by the documented format); no input channel appears in any source.

### Gaps
- No 2024–2026 GSI changes found. Official Valve GSI documentation for Dota 2 not found (the wiki page for CS:GO is the usual reference; not verified).
- Update rate/throttle limits, and whether the `-gamestateintegration` flag is still required, unverified.

## 3. Replays and data APIs (Steam Web API, OpenDota, STRATZ, parsers, datasets)

### Takeaway
Replays are fetched from Valve servers only while Valve still holds them, and the retention window is not documented in anything I found. Parsers (Clarity, Manta) and OpenDota/STRATZ APIs exist. Large public parsed datasets are mostly old.

### Cited Findings
- GetMatchDetails endpoint: `IDOTA2Match_570/GetMatchDetails/v1?match_id=` — [community wiki](https://wiki.teamfortress.com/wiki/WebAPI/GetMatchDetails)
- OpenDota: basic data from Steam API for every public match; parsing a subset; parse requests work only while the replay is on Valve servers; if the client cannot fetch it, OpenDota cannot either (FAQ dated 2014) — [OpenDota FAQ](https://blog.opendota.com/2014/08/01/faq/)
- STRATZ: API moved from REST to GraphQL and uses Clarity for replay data — [stratz.com](https://stratz.com/) (search summary)
- Clarity (Java, skadistats; also CS2/Deadlock) — [github.com/skadistats/clarity](https://github.com/skadistats/clarity); Manta (Go, low-level) — [github.com/dotabuff/manta forks listed in search](https://github.com/lashtaba/manta); d2_stampede (Rust) — [docs.rs/d2-stampede](https://docs.rs/d2-stampede)
- Datasets: Kaggle "dota-2-matches" (about 50,000 ranked matches, from the OpenDota dump); Kaggle pro matches 2019–2021 (47,150 rows); OpenDota 2015 dump (about 100 GB gzipped JSON) and a March 2016 dump on Academic Torrents (about 10 million parsed matches per the listing) — [OpenDota datadump](https://blog.opendota.com/2015/12/20/datadump/); [Academic Torrents](https://academictorrents.com/details/c41059d1fd3b9a0f3dfec769ac2d6468c0e955b8?stats=True); [Kaggle mirror](https://baselight.app/u/kaggle/dataset/teocalvo_dota2_pro_players_matches_2019_202106)
- Noxville's Source 2 reparse: just under 49k replays, 98.69% success — [Substack](https://noxville.substack.com/p/source-1-any-complete-for-now)
- No clearly documented parsed-replay dataset on Hugging Face (closest: Vitrous/Dota2, contents unclear) — [HF](https://huggingface.co/datasets/Vitrous/Dota2/blob/main/2432453_state.json)
- One blog claims the OpenDota API is restricted for non-premium users; single source — [search summary](https://docs.opendota.com/). Unconfirmed.

### Inferences
- For imitation learning at scale you would need to download and parse replays yourself shortly after matches; the Steam API alone returns summary data, not trajectories (from the endpoint's description, not tested).

### Gaps
- Replay retention period in 2026; current Steam GetMatchDetails status (any deprecation); OpenDota/STRATZ current rate limits and ToS on bulk use; data volumes of any modern (Source 2, post-7.x) public replay dataset.

## 4. Rules: scripts, bots, third-party software, bans

### Takeaway
Valve's Steam Subscriber Agreement explicitly bans scripts, bots, macros and unauthorized third-party software, with account termination without notice. Valve actively bans tools that give in-game advantage (Overplus, honeypot wave). Valve's own bot-script API for bot matches is the sanctioned route; automated play in public matchmaking is not.

### Cited Findings
- SSA section 4.B: no Cheats, mods, hacks or unauthorized third-party software; no tampering with the execution of Steam or content unless authorized — [Steam Subscriber Agreement](https://store.steampowered.com/subscriber_agreement/)
- SSA section 4.C: "You may not use any form of scripts, bots, macros, or other non-human-controlled systems"; faking gameplay stats prohibited — [SSA](https://store.steampowered.com/subscriber_agreement/) (the fetch tool paraphrased the sections; wording of 4.C quote could not be checked in full context)
- Valve may restrict or terminate accounts without notice — [SSA](https://store.steampowered.com/subscriber_agreement/)
- February 2023: Valve banned over 40,000 accounts caught by a honeypot (data only cheat software could read) — [PC Gamer](https://www.pcgamer.com/valve-lured-40000-dota-cheaters-into-a-trap-before-banning-them-in-one-day)
- Early 2024: ban waves against Overplus (draft assistant that auto-looks-up opponents) users, around 10,000 accounts per one report; B8 coach Mag reportedly banned; sources disagree on whether it was explicitly bannable beforehand — [esports.gg](https://esports.gg/news/dota-2/dota-coach-mag-banned-overplus); [CPG](https://consolepcgaming.com/valve-has-finally-decided-to-ban-dota-2-players-using-overplus); [esports.gg (pros call for ban)](https://esports.gg/news/dota-2/dota-2-pros-call-for-overplus-draft-assistant-to-be-banned)
- A Valve spokesperson, relayed by the developer on Reddit, said the vulnerability was fixed (secondhand) — [Hawk Live](https://hawk.live/posts/valve-has-declared-overplus-useless)
- A Valve patch (month and day only reported, year not stated in the snippet) disabled functions third-party tools such as Overwolf relied on, including pregame access to player profiles — [esports.gg](https://esports.gg/news/dota-2/dota-2-update-kills-third-party-applications-including-overwolf/) (page could not be fetched)
- Other waves: over 65,000 smurf/win-trading accounts (Dec 2024) and over 75,000 after Compendium 2025 (Russian report) — [GosuGamers](https://www.gosugamers.net/dota2/news/74033-dota-2-bans-over-65-000-accounts-for-smurfing-and-win-trading); [Hawk Live](https://hawk.live/ru/posts/valve-zabanili-desyatki-tysyach-igrokov-dota-2-posle-vyhoda-kompendiuma-2025). None of these mention scripting.

### Inferences
- Legal (documented as sanctioned): playing against Valve bots and custom bot scripts from the Workshop in local/bot lobbies; reading GSI for local use or for your own bot-match experiments.
- Likely bannable under SSA 4.B/4.C and Valve's stance: any scripted or AI agent controlling a client in public/ranked matchmaking; tools reading client memory or hidden data; live overlays that surface information not available in-game (Overplus precedent).
- Gray area: AI coaching on post-game replays or via GSI only. No official Valve statement found. Private lobbies with bots: not covered explicitly in what I found.

### Gaps
- Dota 2-specific rules page and Valve's own statements on AI coaching in 2025–2026: none found. VAC/Overwatch documentation not retrieved. No 2025–2026 ban wave specifically for scripting found (search returned none, not proof none occurred). Overwolf's own Dota 2 rules not retrieved.

## 5. Valve's Bot API history with OpenAI

### Takeaway
OpenAI Five used a Valve-provided game interface, but the retrievable sources do not describe it. The publicly usable equivalent is the Lua Bot Scripting API, which is deliberately restricted.

### Cited Findings
- OpenAI reports it initially lacked custom dedicated server support and worked around it; the paper credits a "Dota 2 gym interface" and describes observations as what a human could see, with hand-scripted item buying and courier — [OpenAI blog (snippet)](https://openai.com/blog/more-on-dota-2/); [arXiv 1912.06680](https://ar5iv.labs.arxiv.org/html/1912.06680)
- Valve's public Bot Scripting API restricts queries so scripts can't cheat — [Dota Bot Scripting](https://developer.valvesoftware.com/wiki/Dota_Bot_Scripting)

### Inferences
- From background knowledge (unverified here): the OpenAI interface was a separate gRPC bot API not released publicly. Treat as unconfirmed.

### Gaps
- Second half of the paper (Appendix K, gym environment) was not read; no source confirming public availability or non-availability of OpenAI's API.
