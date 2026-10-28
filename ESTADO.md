# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- Se hizo (2026-10-28): benchmark automático completo. El orquestador (PR #4) lanza el custom game local dotabench
  (`tools/bench/addon`, Workshop Tools instaladas): humano fuera, 10 bots con los mismos 5 héroes por lado, ×4, ganador
  por GSI. Medido: primera partida válida, dota-bot gana a Valve Unfair en 43 min (kills 52-23). La anterior, 4 contra
  5 en partida normal, la perdió con kills 84-26 (no válida).
- Medido: `print` de los bots no llega a `console.log`; los `+cmd` tras `+map` corren antes de cargar; el VScript de un
  custom game sí imprime y sí ejecuta comandos (`SendToServerConsole`); los errores del VM de bots salen como «error in
  error handling» (20 al añadir bots), sin aislar.
- Serie `oha-vs-valve-unfair` (2026-10-28, bench/partidas.csv): dota-bot gana 4 de 6 partidas válidas (2 de 3 en
  cada lado); victorias de 39-53 min, derrotas de 45 y 73 min. La 7 quedó `sin-gsi`: Dota no encontró GPU («No usable
  DX11 adapters», rasterizador por software) y se colgó al arrancar, probablemente pantalla apagada o sesión
  bloqueada; el orquestador paró y limpió. Máquina medida durante la serie (no antes, como pide la regla): CPU 8 %,
  57 % de memoria libre, 24 núcleos. El ×4 rinde menos: unos 30 min reales por partida.
- Siguiente acción: completar la serie (4 partidas más, `--partidas 4`, con la pantalla del PC encendida) y leer el
  total; verificar la lista de héroes contra `BotImplemented` de `npc_heroes.txt`.
- Espera a Pedro: cuándo puede dejar el PC con la pantalla activa unas 2 horas.

## Madurez
Prototipo: es OHA 7.41/7.41a (127 héroes) con la limpieza de seguridad; sin cambios de juego propios.

## Entregado
- 2026-10-28 · Investigación (docs/investigacion/), fork con limpieza y check (PR #1), junction (PR #2), orquestador
  con GSI y guardia por equipo (PR #4), custom game dotabench (5 contra 5, héroes espejo, ×4).

## Siguientes pasos
1. Serie de 10 partidas dota-bot contra Valve en Unfair (ver «Próxima sesión»).
2. Probar con amigos en un lobby Local Host.
3. Mejorar un héroe débil (Invoker, Rubick o Morphling); ponerse al día con 7.41b-f (docs/PATCH_UPDATE_GUIDE.md).

## Problemas conocidos
- Saludos de inicio con promoción del Workshop siguen saliendo (`mode_laning_generic.lua:248`,
  `mode_farm_generic.lua:903`, `BotLib/hero_faceless_void.lua:151`); textos ofensivos solo con la burla encendida.
- `custom_loader.lua` carga antes `game/Customize/general` si existe; FretBots `set`/`nudge` usan `loadstring` (host).
- Dependencias npm heredadas: conflicto de `typescript`. API de Valve: 8 héroes mal soportados, sin facets ni Tormentor.
