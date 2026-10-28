# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- Se hizo: fork limpio (PR #1), instalación por junction y benchmark (PR #2). Después, pruebas en vivo lanzando
  `dota2.exe` desde el agente (2026-10-28), medido en `console.log`:
  - Funciona sin clics: `dota2.exe -console -condebug -novid -windowed +sv_cheats 1 +sv_lan 1 +dota_start_ai_game 1
    +dota_force_gamemode 1 +dota_bot_set_difficulty 4 +map dota` carga el mapa, la selección de héroes vence sola,
    entran 9 bots «*.OHA» y la partida empieza (unos 4 min). Radiant y Dire cargan los dos `vscripts/bots`.
  - No funciona: lo que imprimen los bots (`print`) no llega a `console.log` (ni el «Picking hero» de OHA), así que
    el registrador `[BENCH]` de PR #2 no deja nada; `-condebug` además reescribe el log en cada arranque. Los `+cmd`
    después de `+map` corren antes de cargar (no hay `jointeam spec` ni `dota_bot_populate` tardíos); `host_timescale`
    antes de `+map` no acelera; no hay `-netconport` (Dota no abre puertos); esta sesión no puede capturar pantalla
    ni usar computer use. El humano queda en Radiant con héroe aleatorio quieto (partida desigual).
  - 10 «Script Runtime Error: error in error handling» al empezar la partida, origen sin aislar (no es el pcall del
    registrador: su diagnóstico `[BENCH-ERR]` no salió, aunque puede ser el mismo problema de `print`).
- Siguiente acción: resultado por GSI (`map.win_team`, `game_state`; carpeta `cfg/gamestate_integration` ya existe)
  con un servidor local en Node, en vez de `print`; luego resolver espectador y velocidad (probar `cfg/server.cfg` o
  un custom game de las Workshop Tools con `SendToServerConsole`) y el guardia por equipo en Lua para que un lado use
  los bots de Valve. Rama `claude/bench-auto` con el diagnóstico `[BENCH-ERR]`.
- Espera a Pedro: si sigue la automatización (recomendado) o juega él las partidas a mano.

## Madurez
Prototipo: es OHA 7.41/7.41a (127 héroes) con la limpieza de seguridad; sin cambios de juego propios.

## Entregado
- 2026-10-28 · Investigación (docs/investigacion/), fork con limpieza y check (PR #1), junction y benchmark (PR #2).

## Siguientes pasos
1. Benchmark automático (ver «Próxima sesión»); después, 10 partidas dota-bot contra Valve en Unfair.
2. Probar con amigos en un lobby Local Host.
3. Mejorar un héroe débil (Invoker, Rubick o Morphling); ponerse al día con 7.41b-f (docs/PATCH_UPDATE_GUIDE.md).

## Problemas conocidos
- Saludos de inicio con promoción del Workshop siguen saliendo (`mode_laning_generic.lua:248`,
  `mode_farm_generic.lua:903`, `BotLib/hero_faceless_void.lua:151`); textos ofensivos solo con la burla encendida.
- `custom_loader.lua` carga antes `game/Customize/general` si existe; FretBots `set`/`nudge` usan `loadstring` (host).
- Dependencias npm heredadas: conflicto de `typescript`. API de Valve: 8 héroes mal soportados, sin facets ni Tormentor.
