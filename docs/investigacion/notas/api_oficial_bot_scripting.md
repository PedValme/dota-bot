# Official Dota 2 Bot Scripting API (Valve) and its status as of 28 Oct 2026

Note on method: Valve's wiki (developer.valvesoftware.com) returned HTTP 403 to direct fetch, so the wiki content is known only through search snippets and through community mirrors/docs (shikyo13 BOT_API_REFERENCE, which is a community document, not Valve). About 13 tool calls used.

## 1. What is the official system, and where is the documentation?

### Takeaway
Valve's official system is a Lua bot scripting API introduced with the 7.00 update (Dec 2016). Its official documentation is the Valve Developer Community wiki page "Dota Bot Scripting". Valve's own documentation is described by the community as incomplete, and Valve has not responded to requests for updates.

### Cited Findings
- The API launched with the 7.00 update, which let players create bots and share them via the Workshop ("create your own Dota bots using a brand new scripting API") — [dota2.com 7.00 Also In This Update](https://www.dota2.com/700/other/)
- Official wiki page: "Dota Bot Scripting" — [Valve Developer Community](https://developer.valvesoftware.com/wiki/Dota_Bot_Scripting) (not fetchable by me, 403; existence confirmed in search results)
- Per the Valve wiki (via search snippet), in-development bot scripts live in `game/dota/scripts/vscripts/bots` of the Dota 2 install — [Dota Bot Scripting](https://developer.valvesoftware.com/wiki/Dota_Bot_Scripting)
- Community-written API reference (not Valve) — [shikyo13/Dota2AI BOT_API_REFERENCE.md](https://github.com/shikyo13/Dota2AI/blob/main/docs/BOT_API_REFERENCE.md)
- A Dec 2024 issue to Valve states the official documentation is incomplete and some supported APIs are missing from it — [ValveSoftware/Dota2-Gameplay #23152](https://github.com/ValveSoftware/Dota2-Gameplay/issues/23152)

### Inferences
- The "official" API is effectively whatever the game binary exposes to Lua; the wiki is a partial description of it.

### Gaps
- Could not read the Valve wiki directly; the full official function list was obtained only from a community reference.

## 2. File structure and override levels

### Takeaway
A script is a folder `bots/` of Lua files named by convention; each file overrides one aspect of the default bot AI, and unspecified aspects fall back to Valve's defaults (a mode's GetDesire may return nil to fall through).

### Cited Findings
- File names: `bot_generic.lua` (per-unit hook; `MinionThink` for summons), `mode_[name]_generic.lua`, `ability_item_usage_generic.lua` and `ability_item_usage_[hero].lua`, `item_purchase_generic.lua` and `item_purchase_[hero].lua`, `team_desires.lua`, `hero_selection.lua` — [shikyo13 reference](https://github.com/shikyo13/Dota2AI/blob/main/docs/BOT_API_REFERENCE.md)
- Per-frame order: `TeamThink()`, each mode's `GetDesire()`, the winning (highest-desire) mode's `Think()`, then ability/item Think functions. Ability/item and purchase Think run regardless of active mode. Returning `nil` from a desire falls through to Valve's default — [shikyo13 reference](https://github.com/shikyo13/Dota2AI/blob/main/docs/BOT_API_REFERENCE.md)
- Team desire functions cover push, defend, farm (per lane), plus roam and Roshan — same source.
- Modes are named `mode_<name>_generic.lua`; the exact mode list (laning, farm, push, defend, roam, team_roam, rune, ward, secret shop, side shop, retreat, attack, etc.) was not shown in what I could read — see Gaps.

### Inferences
- "Complete takeover vs partial override": overriding only e.g. one mode file or one hero's ability usage gives a partial override; supplying all files with nothing returning nil is effectively full takeover. The documented nil fall-through is the mechanism for partial override.

### Gaps
- Full list of mode names and hero-specific `bot_<hero>.lua` semantics not verified from a fetched source.

## 3. API surface, visibility, tick rate, performance

### Takeaway
Rich Lua API: world queries, unit queries, an action queue, immediate commands, debug drawing and HTTP. Information is team-visibility-based (fog respected in the documented functions); the documentation I found shows no explicit "cheat" function, but several data points are limited.

### Cited Findings
- Time: `DotaTime()`, `GameTime()`, `RealTime()`; players/teams: `GetBot`, `GetTeam`, `GetTeamPlayers`, `GetTeamMember`, `IsHeroAlive`, `GetHeroLevel`; game state `GetGameState`, `GetGameMode`, `GetTimeOfDay`; map, lanes, towers, shops, runes, items/neutrals, linear projectiles, avoidance zones, Roshan, courier, captains mode; callbacks for damage, cast, courier death, Roshan death, chat — [shikyo13 reference](https://github.com/shikyo13/Dota2AI/blob/main/docs/BOT_API_REFERENCE.md)
- Actions come in three variants: `Action_` (replace queue), `ActionPush_` (front), `ActionQueue_` (append). Examples: MoveToLocation (pathfinds), MoveDirectly, MovePath, MoveToUnit, AttackMove, AttackUnit, ability use (no target/unit/point/tree), rune/item pickup, drop, shrine use, delay. Immediate (non-queued): purchase, sell, disassemble, swap, courier commands, buyback, glyph, level ability, chat — same source.
- `Think()` and every mode `GetDesire()` run every frame; no explicit tick rate given — same source.
- Visibility is team-based (`IsLocationVisible`, `IsRadiusVisible`); enemies in fog come from `GetHeroLastSeenInfo` (can be stale); enemy cooldowns always read 0; enemy buyback info hidden — same source.
- `GetUnitList()` scans the whole map and is expensive; `GetNearby*` capped at radius 1600 — same source.
- Debug: `DebugDrawLine`, `DebugDrawCircle`, `DebugDrawText`, `DebugPause`; draws last one frame — same source.
- Sandboxed HTTP: `CreateHTTPRequest(url)` (localhost only) and `CreateRemoteHTTPRequest(url)` for remote servers — same source (community document; behavior not independently verified).

### Inferences
- Because `CreateHTTPRequest` exists, bots can in principle talk to an external process (this is the basis of ML/LLM bridges), though the source says remote use is a separate function and I did not verify whether it works in matches.
- No file I/O documented in what I read.

### Gaps
- Actual frame/tick rate (30 Hz game tick presumably) not verified; performance limits/time budgets per Think not found; whether Valve enforces script timeouts not found.

## 4. Loading and testing

### Takeaway
Scripts are tested locally by placing them in `vscripts/bots`, creating a Custom Lobby with Local Host and choosing "Local Dev Script" for each team's bot settings, then filling slots with bots. Workshop distribution exists, but custom scripts reportedly work only on local hosts.

### Cited Findings
- Custom Lobby, server location Local Host; Bot Settings > Radiant/Dire Bots > "Local dev Script" — community instructions via [OpenHyperAI repo](https://github.com/forest0xia/dota2bot-OpenHyperAI) and [LuaFun docs](https://luafun.readthedocs.io/en/latest/pages/interaction.html)
- `dota_bot_populate` fills empty slots with (passive) bots per Valve's wiki; exceeding team size ends the session; a forum guide ran `sv_cheats 1` first — search results summarizing [Dota Bot Scripting](https://developer.valvesoftware.com/wiki/Dota_Bot_Scripting)
- Directory symlink trick to sync Workshop content into `bots` is a community tip — same search summary.
- Workshop scripts: subscribe in Workshop, create lobby with Local Host (e.g. OpenHyperAI, bot names end ".OHA") — [OpenHyperAI](https://github.com/forest0xia/dota2bot-OpenHyperAI)
- Most custom bot scripts work only on local servers; on remote servers they revert to the default script — [Valve issue #23152](https://github.com/ValveSoftware/Dota2-Gameplay/issues/23152)
- Other console commands mentioned in a launch-option guide search: `dota_bot_set_difficulty`, `dota_start_ai_game` — search result summary only, unverified.

### Gaps
- `dota_bot_reload_scripts`, `dota_bot_debug_team` etc. were not confirmed in any fetched source. Not verified.

## 5. Known limitations, bugs, 2024-2026 status

### Takeaway
Valve has not added API features since about 2018-2019 per community complaints, and the main Valve GitHub issue asking for updates was auto-closed as "not planned" on 22 Jul 2026 with no Valve reply. Community scripts (e.g. OpenHyperAI) keep bots working through patches by hand.

### Cited Findings
- Issue #23152 "BOT Match: BOT updates and API" opened 4 Dec 2024; marked stale 14 Apr 2026; closed as not planned 22 Jul 2026; no Valve staff response — [GitHub](https://github.com/ValveSoftware/Dota2-Gameplay/issues/23152)
- Issues listed there: custom scripts local-only; no API for neutral item token or facet selection (a 7.37 facet change left some heroes without abilities); incomplete docs; `GetAvoidanceZones` crashes the client; `GetNearbyTrees` ignores hero-created trees; unsupported new runes (Wisdom etc.), Twin Gates, Lotus Pools, Visage familiars alt-cast; eight heroes (incl. Muerta, Marci, Lone Druid) fall back to basic default behavior; no Tormentor mode; item stat bonuses sometimes not applied — same source (claims by the issue author, not Valve)
- Commenters in 2025 said they would prefer no game changes over constant bot breakage — same source.
- Search summary: no new API support since 2018/2019 and patches keep breaking scripts (issue text) — [search result of #23152](https://github.com/ValveSoftware/Dota2-Gameplay/issues/23152)
- OpenHyperAI supports 127 heroes on 7.41/7.41a and lists Largo, Kez and Ringmaster as supported; says playstyle is "limited by Valve's API" — [OpenHyperAI](https://github.com/forest0xia/dota2bot-OpenHyperAI). Its patch guide says last updated for 7.41a (March 2026) and itemizes 7.41 breakages (e.g. Bloodrage self-only, Guardian Angel no-target, Meepo Divided We Stand max level) — [PATCH_UPDATE_GUIDE](https://github.com/forest0xia/dota2bot-OpenHyperAI/blob/main/docs/PATCH_UPDATE_GUIDE.md)
- Patches: latest found was 7.41f on 15 Sep 2026 — search listing of [dota2.com/news/updates](https://www.dota2.com/news/updates) (not directly verified). Ringmaster added to Captains Mode in 7.38, Kez only hero unavailable for tournaments as of Sept 2025 — [bo3.gg](https://bo3.gg/dota2/news/ringmaster-has-been-added-to-captains-mode-kezu-has-not) (headline-level snippet)
- Older official bot changes exist: 2017 PC Gamer report of Valve bot desire tweaks — [PC Gamer](https://pcgamer.com/dota-2-patch-boosts-bots-tweaks-attack-desire-defend-desire-roshan-desire); Steam Workshop "Dota 2 bot experiment" changelog 2017-2018 — [Steam changelog](https://steamcommunity.com/sharedfiles/filedetails/changelog/837040016)

### Inferences
- Valve still ships the bot system and occasionally touches default bots in patch notes, but is not actively developing the scripting API. Treat as "maintained minimally, not developed."

### Gaps
- UNVERIFIED: a search snippet claimed the 7/1/2026 update note contains bot fixes ("bots going after items near enemy towers", "stuck while dewarding") and Seeing Stones rewards for Co-op Bot Matches; my fetch of [that page](https://www.dota2.com/newsentry/670621050832160174) returned only the title, so I could not confirm, and the date is ambiguous (1 Jul vs 7 Jan). Report writer should treat as unconfirmed.
- No official bot-specific patch note for 7.39/7.40/7.41 confirming bot support for Ringmaster/Kez found. Default-bot hero coverage for new heroes was not verified from Valve.

## 6. Other APIs: world-state protobuf / dotaservice

### Takeaway
The OpenAI-era CMsgBotWorldState socket and dotaservice (gRPC) exist as community tooling built on undocumented game launch options; I could not confirm the flags or that they work in 2026.

### Cited Findings
- dotaservice: Python 3.7 service exposing Dota 2 over gRPC, default port 13337, one client per server, `reset` about 5 s, `step` 10-30 ms, Unix/Docker only; repo has a `botcpp` folder — [TimZaman/dotaservice](https://github.com/TimZaman/dotaservice)
- In dotaservice, the bot script's `Observe()` receives a `CMsgBotWorldState` — [dotaservice issue 25 mirror](https://github.com/onedrive11.workers.dev/TimZaman/dotaservice/issues/25) (mirror; unverified)
- LuaFun (a community framework) imports `CMsgBotWorldState` from generated protobuf (`dota_gcmessages_common_bot_script_pb2`) and listens on a socket — [luafun source](https://luafun.readthedocs.io/en/latest/_modules/luafun/game/states.html) (search summary)
- LuaFun workflow: Local Dev Script in both teams, launches via `luafun --render --speed 1 --interactive` — [LuaFun docs](https://luafun.readthedocs.io/en/latest/pages/interaction.html)

### Gaps
- The launch flags (`-botworldstatesocket_threaded` etc.) were not confirmed by any source I retrieved; a search for the strings returned nothing. Message schema not retrieved. No evidence either way that these work in Oct 2026 (dotaservice targets Python 3.7, last commit dates not seen; likely stale). No official C++/Python API from Valve found.
