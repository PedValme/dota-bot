# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- Plan de Pedro (DECISIONES 2026-10-29): 3 etapas medidas por separado, sin contaminación: (1) empuje (PR #11),
  (2) `ThinkLess` 0, (3) capitán LLM con pic. Cada una en una serie A/B intercalada contra la anterior
  (`--variantes`, bench/README.md); solo cuentan las partidas `valida=si` de `bench/series.csv`.
- Siguiente acción: serie `empuje-ab`, 40 partidas `--variantes base,empuje` (unas 14 h). Comparar victorias y
  minutos de `minuto_10k` al final. Luego `empuje,thinkless0` (o `base,thinkless0` si el empuje no ayuda).
- Contaminación encontrada el 2026-10-29: Dota metía al humano en Radiant y a veces le daba un héroe aleatorio sin
  control (6 contra 5; PR #13 lo saca y lo registra). Por eso la línea base 15/20 de `bench/partidas.csv` (histórico)
  no es comparable; la serie `cierre-v1` secuencial se paró. Los héroes de Valve no son espejo (Valve elige los suyos).
- Etapa 3: puente capitán en 127.0.0.1 (probar primero que el Lua llega a localhost), capitán de reglas y después
  subagente pic por partida; antes, aprobación de cuota de Pedro (partidas × decisiones × costo).
- Espera a Pedro: dejar el PC con pantalla encendida para la serie; la prueba con un amigo en un lobby Local Host.

## Madurez
Prototipo: OHA 7.41a (127 héroes) con limpieza de seguridad, al día con 7.41f (docs/investigacion/2026-10-29-parches-
7.41b-f.md). Primer cambio de juego propio (empuje con +10.000 de oro) sin medir todavía.

## Entregado
- 2026-10-28/29 · Investigación, fork limpio (PR #1), junctions (#2), orquestador con GSI y guardia por equipo (#4),
  custom game dotabench (#5), línea base (#7, contaminable), al día con 7.41f (#8), línea de tiempo (#9), topes de
  empuje relajados (#11), humano fuera de verdad (#13), series A/B intercaladas con validez por partida.

## Siguientes pasos
1. Las 3 etapas de arriba, en orden.
2. Probar con amigos en un lobby Local Host.
3. Del informe de parches: talentos de 16 héroes; Tusk, Invoker y Outworld Destroyer. Verificar los héroes del
   benchmark contra `BotImplemented`. Aislar los «error in error handling» del VM de bots (20 al añadir bots).

## Problemas conocidos
- Saludos con promoción del Workshop (`mode_laning_generic.lua:248`, `mode_farm_generic.lua:903`,
  `hero_faceless_void.lua:151`). `custom_loader.lua` carga antes `game/Customize/general` (no existe en el PC de
  Pedro); FretBots `set`/`nudge` usan `loadstring` (host). Dependencias npm heredadas con conflicto de `typescript`.
- El `print` de los bots no llega a `console.log`; el VScript del custom game sí. API de Valve: 8 héroes mal
  soportados, sin facets ni Tormentor. Mientras corre una serie, `bots/` del clon enlazado se lee en vivo.
