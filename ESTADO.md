# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **Espera a Pedro:** aprobar el diseño del cerebro de equipo, [trabajo/cerebro-equipo.md](trabajo/cerebro-equipo.md)
  (recomendado: completo, construido en orden y medido una sola vez). DECISIONES 2026-10-30: mejora grande con
  argumentos sólidos y criterio de juego, no una corrida por cada detalle.
- Base del diseño: [docs/mapa.md](docs/mapa.md) (25 partidas observadas), 119 partidas profesionales
  (docs/investigacion/2026-10-30-datos-pro.md, `tools/datos/`), criterio de juego contra el código
  (docs/investigacion/2026-10-30-criterio-de-juego.md). Comprobado en el juego que un módulo cargado desde
  `team_desires.lua` comparte estado con los bots.
- Con el sí: verificaciones de la API en una partida observada, arreglos de defensa, recompra y disables, el cerebro y
  el criterio de pelea, como variante `cerebro`; serie única `base,cerebro` de 24 partidas al final.

## Madurez
Prototipo: OHA 7.41a (127 héroes) con limpieza de seguridad, al día con 7.41f. Sin cambios de juego activos por
defecto; variantes del benchmark `empuje`, `grupo`, `grupo_farm` (apagadas sin archivo de variante).

## Entregado
- 2026-10-28/29 · Investigación, fork limpio, junctions, orquestador con GSI, custom game dotabench, series A/B con
  validez, Turbo imitado con courier y espectador (PR #1-#17).
- 2026-10-30 · Mapa, modo observador y analizador (#18); variantes de remate y su serie `remate-ab` (#19): `grupo`
  agrupa (4-5 bots empujando el 34 % frente al 9 %) pero dejó caer la base yendo +18.000; no se enciende.

## Siguientes pasos
1. Cerebro de equipo (arriba), si Pedro aprueba.
2. Probar con amigos en un lobby Local Host (draft de OHA, humanos, Turbo real): no probado.
3. Después: builds con datos, capitán LLM sobre el cerebro.

## Problemas conocidos
- La defensa se apaga cuando 3 aliados empujan (`FunLib/aba_defend.lua:~915-937`); recompra por el Ancient rota
  (`ability_item_usage_generic.lua:569`); más defectos en docs/mapa.md §8.
- ~10 «error in error handling» por partida, sin origen; ~12 interruptores Turbo por `GetGameMode() == 23` apagados en
  el custom game.
- Saludos con promoción del Workshop; FretBots `set`/`nudge` usan `loadstring` (host); dependencias npm heredadas con
  conflicto de `typescript` (sin compilar TS: los `.lua` generados se editan a mano junto a su `.ts`).
