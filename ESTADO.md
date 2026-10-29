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
- Línea base `oha-vs-valve-unfair` (2026-10-28/29, bench/partidas.csv): **dota-bot gana 15 de 20** a los bots de
  Valve en Unfair (5 contra 5, héroes espejo): 8 de 10 desde Radiant, 7 de 10 desde Dire; IC 95 % (Wilson) 53-89 %,
  p≈0,04 frente a 50 %. Derrotas: 45, 49, 52, 73 y 75 min; en la 9 de la noche perdió con kills 46-13 (no cierra
  partidas: hipótesis reforzada). Una partida extra quedó `sin-gsi` por falta de GPU (pantalla apagada) y no cuenta.
  Máquina antes de la serie nocturna: CPU media 16 %, 60 % de memoria libre, 24 núcleos; la primera serie se midió
  durante. Ritmo: 16-30 min reales por partida a ×4.
- Siguiente acción: medir estructuras por minuto (GSI) para atacar el cierre de partidas, comparando contra esta
  línea base. Verificar los héroes del benchmark contra `BotImplemented`.
- Espera a Pedro: la prueba con un amigo en un lobby Local Host.

## Madurez
Prototipo: OHA 7.41a (127 héroes) con la limpieza de seguridad, al día con 7.41f (2026-10-29: 7.41b-f no trae cambios
estructurales; corregidos Witchbane y tres nombres de objetos mal escritos; docs/investigacion/2026-10-29-parches-7.41b-f.md).
Pendiente de ese informe: preferencias de talentos de 16 héroes y ajustes de Tusk, Invoker y Outworld Destroyer.

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
