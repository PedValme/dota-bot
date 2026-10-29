# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- Hecho (2026-10-28/29): benchmark automático (orquestador + custom game dotabench: 5 contra 5, ×4, ganador por GSI)
  y línea de tiempo por minuto en `bench/lineas/`. Corregido 2026-10-29 (Pedro lo vio en pantalla): Dota metía al
  humano en Radiant y a veces le daba un héroe aleatorio sin control (6 contra 5). Ahora se saca y se registra
  (`humano` = fuera/heroe-quitado/en-equipo). La línea base no puede descartarlo. Los héroes de Valve no son espejo.
- Línea base `oha-vs-valve-unfair` (bench/partidas.csv): **dota-bot gana 15 de 20** a Valve Unfair (8/10 Radiant,
  7/10 Dire; IC 95 % 53-89 %, p≈0,04). Derrotas de 45-75 min, una con kills 46-13. Máquina antes de la serie
  nocturna: CPU 16 %, 60 % de memoria libre. Ritmo: 16-30 min reales por partida.
- Medido: dota-bot pasó 20 minutos con más de 10.000 de oro de ventaja (+27.000 en el 58) sin romper la base. Causa
  probable en `FunLib/aba_push.lua` (fuente `typescript/bots/FunLib/aba_push.ts`), `GetPushDesireHelper`: tope 0,41 si
  los 5 enemigos viven sin superioridad numérica y 0,08 en terreno alto sin 3 aliados juntos.
- Hecho: topes relajados con +10.000 de oro (PR #11). En curso: serie `cierre-v1` de 20 (relanzada con el arreglo
  del humano; la línea base pudo tener un héroe de más en Radiant); luego `ThinkLess` 0. Etapa 2 (DECISIONES
  2026-10-29): puente capitán en 127.0.0.1 (probar primero que el Lua llega a localhost), capitán de reglas y después subagente pic por partida; antes, aprobación de cuota de Pedro.
- Espera a Pedro: avisar cuándo deja el PC para la serie; la prueba con un amigo en un lobby Local Host.

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
