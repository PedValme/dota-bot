# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **En pausa desde 2026-10-29 por decisión de Pedro** (DECISIONES): se paró la serie `turbo-empuje-ab` en su primera
  partida, sin datos. Nada corre; temporales del benchmark borrados. Retomar solo si Pedro lo pide.
- Plan que quedó (DECISIONES 2026-10-29): 3 etapas medidas por separado y sin contaminación (empuje, `ThinkLess` 0,
  capitán LLM), cada una en serie A/B intercalada; solo cuentan partidas `valida=si` de `bench/series.csv`. El
  objetivo era **Turbo**, imitado dentro del custom game (`--modo turbo`, bench/README.md).
- Medido en modo normal (`empuje-ab`, 24 partidas válidas, sin courier): `base` 11/12, `empuje` 9/12; cierre desde
  +10.000 de oro 16,5 contra 19,8 min; `empuje` perdió 2 partidas tras +10.000, `base` ninguna. No ayuda en normal.
- Encontrado el 2026-10-29: el custom game no daba courier (todas las series anteriores sin courier; ya corregido) y
  tu usuario ahora mira como espectador con visión elegible.
- Si se retoma: serie `turbo-empuje-ab` (40 partidas `--modo turbo --variantes base,empuje`, unas 6-7 h), luego
  `ThinkLess` 0 y la etapa 3 (puente en 127.0.0.1, capitán de reglas, pic; antes, aprobación de cuota). El cambio de
  empuje (PR #11) está apagado por defecto desde el 2026-10-29 (Pedro): el bot juega como OHA; solo la variante
  `empuje` del benchmark lo enciende.

## Madurez
Prototipo: OHA 7.41a (127 héroes) con limpieza de seguridad, al día con 7.41f. Sin cambios de juego propios activos
(el de empuje se midió sin mejora y quedó apagado).

## Entregado
- 2026-10-28/29 · Investigación, fork limpio (PR #1), junctions (#2), orquestador con GSI y guardia por equipo (#4),
  custom game dotabench (#5), línea base (#7, contaminable), al día con 7.41f (#8), línea de tiempo (#9), topes de
  empuje relajados (#11), humano fuera (#13), series A/B con validez (#14), Turbo imitado, courier y espectador.

## Siguientes pasos
1. Las 3 etapas de arriba, en Turbo.
2. Probar con amigos en un lobby Local Host.
3. Del informe de parches: talentos de 16 héroes; Tusk, Invoker y Outworld Destroyer. Verificar los héroes del
   benchmark contra `BotImplemented`. Aislar los «error in error handling» del VM de bots (20 al añadir bots).

## Problemas conocidos
- Saludos con promoción del Workshop (`mode_laning_generic.lua:248`, `mode_farm_generic.lua:903`,
  `hero_faceless_void.lua:151`). FretBots `set`/`nudge` usan `loadstring` (host). Dependencias npm heredadas con
  conflicto de `typescript`.
- Los bots no escriben en el log (ni `print` ni chat); el custom game sí. Turbo imitado: torres y runas como en normal.
  API de Valve: 8 héroes mal soportados, sin facets ni Tormentor. Durante una serie, `bots/` se lee en vivo.
