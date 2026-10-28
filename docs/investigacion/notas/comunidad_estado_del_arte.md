# Estado del arte comunitario: bots scripted de Dota 2 (a 28-oct-2026)

Nota de método: GitHub API/páginas leídas el 28-oct-2026. Steam Workshop devolvió HTTP 429 en varios intentos, así que NO pude verificar suscriptores ni changelogs de Workshop directamente. Reddit/Discord no aportaron resultados útiles.

## 1. Qué scripts son más populares/fuertes y su mantenimiento

### Takeaway
Open Hyper AI (OHA, forest0xia) es hoy el script comunitario de referencia (MIT, 127 héroes, parche 7.41/7.41a según README, usa Claude Code para mantenimiento). Ryndrb "Tinkering ABout" está activo (push 15-oct-2026) pero es de uso personal. Ranked Matchmaking AI (adamqqq) está estancado desde mayo 2024.

### Cited Findings
- OHA: 300 estrellas, 80 forks, licencia MIT, 44-50 issues abiertos, creado 28-abr-2024, `pushed_at` 2026-04-17 en el repo principal; 392 commits; sin Releases publicadas — [GitHub](https://github.com/forest0xia/dota2bot-OpenHyperAI), [API](https://api.github.com/repos/forest0xia/dota2bot-OpenHyperAI)
- OHA README: 127 héroes en parche 7.41/7.41a; laning, gank, push, defend, jungla, Roshan, items activos; modos All Pick, Turbo, Captain Mode, 1v1 mid; 4 idiomas, respuesta a pings; comandos `!pos`, `!pick`, `!ban`, `!sp`; modo FretBots (bonos de oro/XP/stats por dificultad, neutrals, chatbot IA) — [README](https://github.com/forest0xia/dota2bot-OpenHyperAI)
- OHA reconoce limitaciones: "playstyle limited by Valve's API"; planea arreglar Dark Willow, IO, Lone Druid, Muerta y mejorar Invoker, Rubick, Morphling — [README](https://github.com/forest0xia/dota2bot-OpenHyperAI)
- OHA credita como base: New Beginner AI, Tinkering About, Ranked Matchmaking AI, fretbots, BOT Experiment, ExtremePush — [README](https://github.com/forest0xia/dota2bot-OpenHyperAI)
- Commits recientes de OHA (1-3 abr 2026): reglas de runas, correcciones críticas en aba_defend/aba_push (un commit habilita DefendThink y otro lo revierte por bugs críticos), mejoras por héroe (Meepo, Beastmaster, KotL, Monkey King) — [commits API](https://api.github.com/repos/forest0xia/dota2bot-OpenHyperAI/commits?per_page=10)
- OHA en Workshop: listado como "todos los héroes soportados", ID 3246316298; Patreon del autor existe — [Workshop comments](https://steamcommunity.com/sharedfiles/filedetails/comments/3246316298), [Patreon](https://www.patreon.com/cw/openhyper)
- Ryndrb/dota2bot ("Tinkering ABo(u)t"): 55 estrellas, 11 forks, 574 commits, `pushed_at` 2026-10-15, sin licencia declarada; README titulado 7.41f; basado en Beginner:AI NEW, "mainly for personal use"; 127/127 héroes (pos 1-5) pero lista como bugueados por Valve: Dark Willow, Elder Titan, Hoodwink, IO, Kez, Marci, Muerta, Primal Beast — [GitHub](https://github.com/ryndrb/dota2bot), [API](https://api.github.com/repos/ryndrb/dota2bot)
- Ryndrb: bots "challenging mainly through aura stacking"; recomienda vscript compañero que sube GPM/XPM y da neutral items a bots; usa Local Dev Script en lobby local — [GitHub](https://github.com/ryndrb/dota2bot)
- Ranked Matchmaking AI (adamqqqplay/dota2ai, hoy adam3q/dota2ai): 347 estrellas, 87 forks, GPL-3.0, `pushed_at` 2024-05-23 (estancado >2 años), 183 commits; "100+ héroes"; el About afirma "más de 3 millones de suscriptores" (auto-declarado; una captura del repo vía búsqueda decía "1 millón") — [GitHub](https://github.com/adamqqqplay/dota2ai), [API](https://api.github.com/repos/adamqqqplay/dota2ai)
- Forks/derivados activos de OHA en oct-2026: Fawxy ("SDK/humaniser work"), ChimCatz/TI_Champions_Bot (drafting por posición, disciplina de lane, timing de objetivos), DavoudTeimouri/dota2-ai-bot (chat wheel, hints, pure Lua), shikyo13/Dota2AI (127 héroes), todos con 0-6 estrellas — [búsqueda GitHub](https://api.github.com/search/repositories?q=dota2+bot+language:lua&sort=updated&per_page=20)
- VULFT: comentarios Workshop de 2023 lo llaman fuerte ("best by a long shot"); sin datos de mantenimiento 2025-26 — [Workshop comments](https://steamcommunity.com/sharedfiles/filedetails/comments/2872725543)

### Inferences
- OHA `pushed_at` (17-abr-2026) es anterior a 7.41b (7-abr)... y a 7.41d (5-jun-2026); es posible que el repo principal no cubra 7.41b-d ni parches posteriores (7.42?), pero no lo verifiqué. Hay rama(s)/forks más recientes (el `updated_at` del repo era 28-oct-2026, por issues/estrellas).
- Beginner AI, BOT Experiment, Phalanx: no encontré evidencia 2025-26; tratarlos como no verificados/posiblemente obsoletos.

### Gaps
- Suscriptores reales de Workshop (429), fecha del último cambio en Workshop, hero coverage de Phalanx/BOT Experiment/Beginner AI, nuevos scripts 2025-26 con tracción real.

## 2. Patrones de arquitectura

### Takeaway
Todos siguen el esqueleto de Valve (`bot_generic`, `mode_*_generic`, `ability_item_usage_*`, `item_purchase_*`, `hero_selection`) y añaden: un archivo por héroe con funciones `Consider<Ability>` que devuelven (desire, target), una librería utilitaria monolítica (`jmz_func`, namespace `J`) y tablas de datos de items/roles.

### Cited Findings
- OHA estructura: `bots/` con `BotLib/` (builds/lógica por héroe), `FunLib/` (librerías), `FretBots/`, `Customize/`; `typescript/` compilado a Lua con TSTL (desarrollo futuro en TS); `docs/` con ARCHITECTURE, PATCH_UPDATE_GUIDE, BOT_API_REFERENCE — [README](https://github.com/forest0xia/dota2bot-OpenHyperAI)
- Cada `hero_<x>.lua` sigue plantilla: talentos, orden de habilidades (índices sobre lista filtrada), builds por posición, sell list, `SkillsComplement()` con casteo priorizado, una función `Consider` por habilidad — [ARCHITECTURE.md](https://raw.githubusercontent.com/forest0xia/dota2bot-OpenHyperAI/main/docs/ARCHITECTURE.md)
- Desire: niveles `BOT_ACTION_DESIRE_NONE/MODERATE/HIGH`; items activos vía `X.ConsiderItemDesire["item"]` devolviendo desire, target, tipo de cast y motivo — [ARCHITECTURE.md](https://raw.githubusercontent.com/forest0xia/dota2bot-OpenHyperAI/main/docs/ARCHITECTURE.md)
- `jmz_func.lua` agrega sublibrerías (`aba_item`, `aba_skill`, `aba_role`, `aba_hero_roles_map`, `aba_site`, `spell_list`, `advanced_item_strategy`, `aba_chat`, etc.); builds en tablas escritas a mano con fallback por posición; componentes vía `GetItemComponents()` de la API — [ARCHITECTURE.md](https://raw.githubusercontent.com/forest0xia/dota2bot-OpenHyperAI/main/docs/ARCHITECTURE.md)
- Modos como archivos `mode_*_generic.lua` (assemble, attack, defend tower por lane, farm, laning, outpost, push por lane, retreat, roshan, rune, secret shop, team roam, ward) — [ryndrb](https://github.com/ryndrb/dota2bot)
- Ryndrb: carpetas `API`, `BotLib`, `Buff`, `FunLib`; wards en coordenadas predefinidas — [ryndrb](https://github.com/ryndrb/dota2bot)
- Ranked Matchmaking AI: un archivo `ability_item_usage_<hero>.lua` por héroe, carpetas `hero/items`, `util`, `dev`, `docs` — [GitHub](https://github.com/adamqqqplay/dota2ai)
- Dificultad: OHA usa FretBots (ventajas de oro/XP/stats/neutrals escaladas) en vez de mejor IA; Ryndrb usa vscript que sube GPM/XPM y da neutrals — [README OHA](https://github.com/forest0xia/dota2bot-OpenHyperAI), [ryndrb](https://github.com/ryndrb/dota2bot)

### Inferences
- La "fuerza" percibida viene en gran parte de bonos económicos/aura stacking y reglas heurísticas, no de planificación. Las builds son estáticas (no vi evidencia de ingesta automática de Dotabuff/STRATZ; OHA usa d2vpkr/Liquipedia manualmente para parches).
- Que OHA no documente targeting ni teamfights (ARCHITECTURE.md los omite) sugiere lógica de teamfight emergente de desires por modo + `IsGoingOnSomeone`, sin coordinador explícito.

### Gaps
- Cómo cada script decide teamfights/target selection (no leí código); si usan funciones omniscientes; fuente de datos de builds de BOT Experiment/Phalanx.

## 3. Problemas comunes y mantenimiento tras parches

### Takeaway
La rotura principal es por renombres/innates/aspectos de habilidades y cambios de items; OHA tiene un proceso de actualización documentado y asistido por IA, con ciclos de parche muy frecuentes.

### Cited Findings
- Roturas típicas listadas por OHA: habilidades renombradas, transiciones a innate que desplazan índices de build, cambios de targeting, items eliminados/cambiados, listas neutral desincronizadas, intercambio día/noche de Roshan y Tormentor; notas de parche inexactas causaron errores en 7.41 (p. ej. Bloodstone) — [PATCH_UPDATE_GUIDE](https://raw.githubusercontent.com/forest0xia/dota2bot-OpenHyperAI/main/docs/PATCH_UPDATE_GUIDE.md)
- Flujo de actualización: detectar parche, clasificar cambios, usar d2vpkr/Liquipedia, actualizar items/habilidades/neutrals/héroes nuevos/mapa, editar `.ts` no los `.lua` generados, grep de nombres obsoletos — [PATCH_UPDATE_GUIDE](https://raw.githubusercontent.com/forest0xia/dota2bot-OpenHyperAI/main/docs/PATCH_UPDATE_GUIDE.md)
- OHA incluye `CLAUDE.md` con instrucciones para parches/héroes: el proyecto usa Claude Code — [README](https://github.com/forest0xia/dota2bot-OpenHyperAI)
- Cronología de parches: 7.41 el 25-mar-2026 (quita aspectos, rework de innates, cambios de terreno), 7.41b 7-abr, 7.41d 5-jun-2026; 7.41a emergencia por crashes — [búsqueda de noticias](https://bo3.gg/dota2/articles/when-will-patch-7-41-be-released-for-dota-2) (resultados agregados; no abrí cada página)
- Héroes bugueados por la API de Valve en Ryndrb: Dark Willow, Elder Titan, Hoodwink, IO, Kez, Marci, Muerta, Primal Beast — [ryndrb](https://github.com/ryndrb/dota2bot)
- Rendimiento: Ryndrb reporta caídas de FPS al ser el PC el servidor local — [ryndrb](https://github.com/ryndrb/dota2bot)
- Un commit de OHA habilita DefendThink y otro lo revierte por bugs críticos en `aba_defend.lua` (ejemplo de regresiones rápidas) — [commits](https://api.github.com/repos/forest0xia/dota2bot-OpenHyperAI/commits?per_page=10)
- Un changelog Workshop (script de ID 2873408973, no confirmé cuál) menciona: bots más coordinados al atacar Tormentor, no canjean neutral tokens, no interactúan con nuevos edificios — [changelog](https://steamcommunity.com/sharedfiles/filedetails/changelog/2873408973?p=10) (resultado de búsqueda; contenido no verificado)

### Inferences
- Con 2-3 parches mayores al año y aspectos/innates cambiando, un script sin actualización continua queda obsoleto en meses (como Ranked Matchmaking AI, parado desde 2024).

### Gaps
- No encontré fuentes específicas de roturas en 7.33, 7.36, 7.37-7.39 ni 7.40 (búsqueda sin resultados concretos).

## 4. Fuerza frente a humanos y benchmarks

### Takeaway
No encontré ningún benchmark creíble ni torneos bot-vs-bot ni afirmaciones fiables por MMR.

### Cited Findings
- La documentación de OHA admite que el estilo está limitado por la API de Valve y que la dificultad alta se logra con bonos (FretBots) — [README](https://github.com/forest0xia/dota2bot-OpenHyperAI)
- Ryndrb dice que son difíciles principalmente por aura stacking — [ryndrb](https://github.com/ryndrb/dota2bot)
- Los listados de "mejores scripts" son de 2022-23 o sitios generados por IA; sus afirmaciones son anecdóticas — [Gamersdecide](https://www.gamersdecide.com/articles/dota-2-best-bot-scripts)

### Inferences
- Ningún script escrito en Lua bajo la API de Valve se acerca a OpenAI Five; el techo es probablemente jugadores de bajo-medio MMR, pero esto es una suposición mía sin evidencia.

### Gaps
- Brackets de MMR, torneos, benchmarks, hilos de Reddit 2025-26 (no accesibles/encontrados).

## 5. Flujo de desarrollo

### Takeaway
Evidencia disponible: reload por consola, ejecución local con cheats, TypeScript->Lua y documentación de mantenimiento; poca información sobre debugging.

### Cited Findings
- Reload: lobby local con cheats, `sv_cheats 1; script_reload_code bots/fretbots` en consola — resumen de búsqueda sobre la guía de OHA ([Workshop discussion](https://steamcommunity.com/workshop/filedetails/discussion/3246316298/4764334012741504141))
- Setup de pruebas bot-vs-bot con cheat console en Ryndrb — [ryndrb](https://github.com/ryndrb/dota2bot)
- ARCHITECTURE de OHA no tiene guía de depuración; recomienda guards de nil y verificar nombres contra d2vpkr/Liquipedia — [ARCHITECTURE.md](https://raw.githubusercontent.com/forest0xia/dota2bot-OpenHyperAI/main/docs/ARCHITECTURE.md)
- OHA: desarrollo futuro en TypeScript (TSTL), personalizaciones permanentes en `game/Customize/`, `docs/BOT_API_REFERENCE.md` — [README](https://github.com/forest0xia/dota2bot-OpenHyperAI)
- Valve wiki "Dota Bot Scripting" es la referencia oficial pero devolvió 403 — [wiki](https://developer.valvesoftware.com/wiki/Dota_Bot_Scripting)

### Gaps
- DebugDrawText, replays, tests: no verificados. Lecciones prácticas a validar leyendo `BOT_API_REFERENCE.md`.

## 6. Noticias 2025-26 y Valve

### Takeaway
No encontré anuncio de Valve sobre mejoras de bots en 2025-26; las noticias de bots de Valve halladas son de 2017.

### Cited Findings
- Valve cerró en 2017 el servidor dedicado de "Full Bot Overwrite" y añadió filtros de partidas con bots — [Cybersport 2017](https://www.cybersport.ru/news/razrabotchiki-dota-2-uprostili-prosmotr-igr-s-botami-iz-workshop)
- Parche 7.41 (25-mar-2026) cambió mapa/innates/aspectos, causa principal de mantenimiento para los scripts — [bo3.gg](https://bo3.gg/dota2/articles/when-will-patch-7-41-be-released-for-dota-2)
- Actividad de forks en oct-2026 indica comunidad viva alrededor de OHA (ver sección 1).

### Gaps
- Discords comunitarios, nuevos parches tras 7.41d, cambios de API de Valve en 2025-26.
