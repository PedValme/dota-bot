# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **Cerebro de equipo v1 construido y medido** (variante `cerebro`, apagado por defecto; resultado arriba de
  [trabajo/cerebro-equipo.md](trabajo/cerebro-equipo.md)). Serie `cerebro-ab`: cierra en 10 min frente a 19, pero gana
  8/12 frente a 11/12 (Dire 2/6). Pierde al cerrar en high ground y cuando un split-pusher arrastra a los defensores.
- **Espera a Pedro:** recomendado una v2 corta sobre esos dos fallos (cerrar solo con pelea favorable y retirarse si
  falla; un héroe enemigo solo no arrastra a dos) y una sola serie más; o dejarlo apagado y pasar a builds.
- Herramientas: `node tools/bench/resumir-serie.mjs <etiqueta>`, `tools/bench/analizar.mjs`, líneas `[bench] plan`
  y `plan_tick` en `bench/observaciones/`.

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
