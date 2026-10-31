# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **2026-10-31, rama `claude/cerebro-v2-builds` (sin fusionar).** Causa de la «debilidad en Dire»: en el custom game
  Dire jugaba con **héroes al azar** en todas las series anteriores. Resuelto: espejo con `ReplaceHeroWith` 0,5 s
  después de aparecer (addon_game_mode.lua, por defecto; `--espejo no` lo apaga); comprobado con dota-bot y con Valve.
  Las series anteriores por lado no valen. Geometría de la API: relativa a cada equipo (medido).
- **Corriendo: serie `justa`** (12 partidas, `base,base_estado,cerebro_def`, los dos lados, espejo):
  `node tools/bench/mecanismo.mjs justa` y `resumir-serie.mjs justa`. A la 5.ª: base 1/1, base_estado 0/2 y
  cerebro_def 0/1 (las tres derrotas tras +10k). Una partida invalidada: Dota se cerró solo en el minuto 7.
- Decisiones nuevas de Pedro (DECISIONES 2026-10-31): reglas por estado de partida y no por reloj (hecho como
  variante `fase_estado`: fases por nivel medio calibrado con datos pro, `J.StateTime()`, farm y Roshan); punto dulce
  del empuje en grupo; observadas: torres sin defender y ultis malgastadas (el observador ya registra `ult` y
  defensores de torre). Siguiente: con la serie, decidir qué variante vale; filtro único de ultis y defensa de T1/T2.
- Hecho en la rama: `--rival dotabot` (partidas largas, falta tope), `--lado`, `--espejo`, `mecanismo.mjs`, cerebro
  v2, builds, `base_sinturbo` (`J.IsImitatedTurbo`), variantes de prueba de Dire.

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
