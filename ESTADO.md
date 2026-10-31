# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **En curso (2026-10-31, encargo de Pedro: reparar Dire con pruebas cortas, 2-3 soluciones a la vez).** Rama
  `claude/cerebro-v2-builds` (sin fusionar). Hallado: en el custom game Dire juega con héroes al azar (selección,
  estrategia y previa en el mismo segundo; tres intentos de espejo fallaron, documentado en addon_game_mode.lua); la
  geometría de la API es relativa a cada equipo (medido, `[bench] geo`). El cerebro gana rápido pero muere ~2,5 veces
  más que el base (Dire con héroes peores: 3/10). `cerebro_def` (defensa de los cinco) arregló las defensas por un
  héroe; `prudente` no ayudó. Los bloques de 2 partidas por variante en Dire son ruido (héroes al azar en cada
  partida; `dire-aislar` no aisló nada). Corriendo: `dire-ab`, 20 partidas en Dire `base,cerebro_def` intercaladas
  (`node tools/bench/mecanismo.mjs dire-ab`, `resumir-serie.mjs dire-ab`): contesta si `cerebro_def` iguala al base.
- Hecho en la rama: `--rival dotabot` (cada equipo su variante; partidas largas, falta un tope), `--lado`,
  `tools/bench/mecanismo.mjs`, lógica Turbo de OHA activa también en el banco (`J.IsModeTurbo()`), cerebro v2 y builds.
- Herramientas: `resumir-serie.mjs`, `mecanismo.mjs`, `analizar.mjs`; líneas `[bench] plan`, `plan_tick`, `geo`.

## Madurez
Prototipo: OHA 7.41a (127 héroes) con limpieza de seguridad, al día con 7.41f. Sin cambios de juego activos por
defecto; variantes del benchmark `empuje`, `grupo`, `grupo_farm` y `cerebro` (apagadas sin archivo de variante).

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
