# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- Hecho (2026-10-28/29): benchmark automático (orquestador + custom game dotabench: humano fuera, 5 contra 5 con
  héroes espejo, ×4, ganador por GSI) y línea de tiempo por minuto de los dos equipos en `bench/lineas/`.
- Línea base `oha-vs-valve-unfair` (bench/partidas.csv): **dota-bot gana 15 de 20** a Valve Unfair (8/10 Radiant,
  7/10 Dire; IC 95 % 53-89 %, p≈0,04). Derrotas de 45-75 min, una con kills 46-13. Máquina antes de la serie
  nocturna: CPU 16 %, 60 % de memoria libre. Ritmo: 16-30 min reales por partida.
- Medido: dota-bot pasó 20 minutos con más de 10.000 de oro de ventaja (+27.000 en el 58) sin romper la base. Causa
  probable en `FunLib/aba_push.lua` (fuente `typescript/bots/FunLib/aba_push.ts`), `GetPushDesireHelper`: tope 0,41 si
  los 5 enemigos viven sin superioridad numérica y 0,08 en terreno alto sin 3 aliados juntos.
- Siguiente acción: relajar esos topes con ventaja grande de oro (Lua y TS) y medir una serie de 20 contra la línea
  base (victorias y minutos desde `minuto_10k` hasta el final).
- Espera a Pedro: la prueba con un amigo en un lobby Local Host.

## Madurez
Prototipo: OHA 7.41a (127 héroes) con limpieza de seguridad, al día con 7.41f (docs/investigacion/2026-10-29-parches-
7.41b-f.md). Sin cambios de juego propios todavía.

## Entregado
- 2026-10-28/29 · Investigación, fork limpio (PR #1), junctions (#2), orquestador con GSI y guardia por equipo (#4),
  custom game dotabench (#5), línea base 15/20 (#7), al día con 7.41f (#8), línea de tiempo por minuto (#9).

## Siguientes pasos
1. Mejorar el cierre de partidas (ver «Próxima sesión») y medirlo.
2. Probar con amigos en un lobby Local Host.
3. Del informe de parches: talentos de 16 héroes; Tusk, Invoker y Outworld Destroyer. Verificar los héroes del
   benchmark contra `BotImplemented`. Aislar los «error in error handling» del VM de bots (20 al añadir bots).

## Problemas conocidos
- Saludos con promoción del Workshop (`mode_laning_generic.lua:248`, `mode_farm_generic.lua:903`,
  `hero_faceless_void.lua:151`). `custom_loader.lua` carga antes `game/Customize/general`; FretBots `set`/`nudge` usan
  `loadstring` (host). Dependencias npm heredadas con conflicto de `typescript`.
- El `print` de los bots no llega a `console.log`; el VScript del custom game sí. API de Valve: 8 héroes mal
  soportados, sin facets ni Tormentor.
