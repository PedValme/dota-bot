# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- Se hizo (2026-10-28): orquestador `tools/bench/orquestador.mjs` + guardia por equipo `FunLib/bench_side` (rama
  `claude/orquestador-gsi`). Medido en una partida real: lanza Dota sin clics, un equipo con 4 bots «*.OHA» y el otro
  con 5 bots de Valve, GSI da el ganador, cierra su Dota y borra sus temporales. Resultado (no válido, 4 contra 5):
  79 min, kills 84-26 a favor de dota-bot, y ganó Valve: OHA pelea pero no cierra partidas (hipótesis a confirmar).
- Medido también: el `print` de los bots no llega a `console.log` (el registrador `[BENCH]` se quitó); los `+cmd`
  tras `+map` corren antes de cargar; `host_timescale 4` sí acelera si se escribe ya en partida (Pedro); `jointeam
  spectator` en partida no saca al héroe del humano, que ocupa un lugar en Radiant.
- Siguiente acción: con las Workshop Tools (instalación pedida a Steam), un custom game local que deje al humano fuera
  antes de elegir héroes, añada 10 bots y ponga `host_timescale 4`; primero comprobar que carga nuestros `bots/` y que
  la guardia por equipo sigue funcionando. Luego las 10 partidas.
- Espera a Pedro: nada, salvo que la instalación de Steam pida confirmación.

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
