# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **Qué se estaba haciendo:** el medio juego del Sniper propio (`bots/FunLib/propio/medio.lua`), que Pedro adelantó a los cinco en línea, y el pulido que pidió antes de volver a probar (DECISIONES 2026-11-05 y 2026-11-06). Variante `control_sniper`.
- **Dónde quedó:** Pedro cerró esta sesión al acabar `fijo-p5`, la base firme (8 partidas, héroes fijos, contra un equipo OHA, min 25; OHA con 4): LH 162,1 y 160,8 ✓; muertes 1,3 y 1,5 ✓; rival de mid 24,6 y 26,8 ✓; sin devolver 19,0 % (✗ frente a 17 %; OHA 27,4 %); patrimonio 21.468 y 26.442 ✗; daño a héroes 13.956 y 21.823 ✗; kills 7,1 y 13,0 ✗. Vueltas de pulido usadas: 4 de 6.
- **Qué se probó:** la brecha es tiempo peleando (ventanas con daño 20 % frente a 30 %); cuando pelea, pega casi igual. Contestar siempre en línea (`fijo-p3`) y cazar con compañía (`fijo-p4`) salieron mal y están revertidos. Con 4 partidas hay mucho ruido, incluso con héroes fijos: `fijo-p2`, el mismo código, dio 199 LH y 24.742 (MEDICIONES 2026-11-06).
- **Siguiente acción:** evaluación adversarial, sin partidas nuevas ni esperar a que Pedro juegue (DECISIONES 2026-11-06), con dos preguntas: qué y cómo mejorar (pulir el Sniper o decisiones de equipo; por qué pelea menos) y qué criterio de pulido usar (la propuesta del agente, en DECISIONES). Base: MEDICIONES 2026-11-06, `bench/observaciones/`, `node tools/analisis/pulido.mjs --referencia fijo-oha-a,fijo-oha-b <etiquetas>`. Luego, decidirlo con Pedro.
- Espera al dueño: nada hasta tener la evaluación adversarial

## Madurez
Prototipo. El bot por defecto es OHA 7.41a (127 héroes) con limpieza de seguridad, al día con 7.41f, sin cambios de juego
activos por defecto: todo lo nuevo, también el bot propio, va apagado tras variantes del banco. Primera serie limpia que
decide: la confirmación de la línea del Sniper (2026-11-04). Rumbo: bot propio (DECISIONES 2026-11-03); OHA no se sigue parcheando: `cerebro_v3` quedó apagado tras no
mejorar a `base` (11 de 32 frente a 12 de 32; regala ventajas sin edificios, MEDICIONES 2026-11-03).

## Entregado
- 2026-10-28/29 · Investigación, fork limpio, junctions, orquestador con GSI, custom game dotabench, series A/B con
  validez, Turbo imitado con courier y espectador (PR #1-#17).
- 2026-10-30 · Mapa, modo observador y analizador (#18); variantes de remate (#19); diseño y cerebro v1 (#20, #21).
- 2026-10-31/11-01 · Banco de medición fiable y protocolo (#22, #24, #25), cerebro v2, builds y fases por estado (#23),
  nivel 1 (#26), MEDICIONES.md.
- 2026-11-02/03 · Cerebro v3, medido y apagado (#42, #43); diagnóstico de ventajas regaladas; nuevo rumbo (#45).
- 2026-11-03/04 · Base de primera mano de la API: `docs/api/`, wiki de Valve, API y OHA, D2AI y Tinkering (#46-#49).
  Prueba de control completo (#50); fase 1 y fase 1 completa (#51, #52); diagnóstico y ajustes (#53).
- 2026-11-04 · Vuelta de la fase 1: banco con `--corte` y `--heroes` (#56), registro (#57), defectos y build (#58, #59),
  puerta de la confirmación y lobby para jugar contra el Sniper (#60).
- 2026-11-05/06 · Confirmación de la línea, intercambio con números propios, medio juego con objetos y riesgo, neutrales, TP a peleas, daño aprendido de cada rival, Assassinate en peleas, rival OHA y `pulido.mjs` (#61-#82).

## Siguientes pasos
1. Medio juego del Sniper propio, hasta el visto bueno de Pedro: `trabajo/bot-propio.md`. Hipótesis sin medir: un héroe propio con cuatro de OHA quizá no llegue a sus kills sin decisiones de equipo.
2. Fase 2, los cinco en línea: `trabajo/bot-propio.md`.
3. Revisar otros bots de la comunidad (Ranked Matchmaking AI, BOT Experiment, New Beginner AI, ExtremePush) al llegar a
   peleas, objetos o estrategia (DECISIONES 2026-11-03).
4. Una prueba en el entorno real: lobby Local Host con amigos, Turbo real.
5. Menores del banco: que la línea `start` registre las bajas (estrechar el margen de patrimonio inicial).

## Problemas conocidos
Defectos sin resolver. Mientras sigan abiertos, no se mide sobre los del banco.
- **Banco: Dota se cierra solo** al cambiar o crear héroes de Dire (5 de 16 partidas con espejo, 1 de 2 creando).
  Se dejó de hacer: cada equipo pide su propio sorteo. Sin comprobar aún en una serie que no vuelva a pasar (20 de 20
  partidas de humo sin cierres).
- **Banco: el primer bot añadido aparece de 15 a 50 s tarde.** Con 90 s de fase previa llega antes del inicio, y la
  validez rechaza cualquier héroe aparecido después. Causa sin explicar.
- **Banco: velocidad real variable** (×1,6 a ×3,4 con `--velocidad 4`), sin saber si afecta distinto a cada lado.
- **Banco, sin comprobar:**
  - si a ×4 los bots de Lua piensan menos por segundo de juego que los de Valve;
  - el Turbo imitado no es el Turbo real: torres y runas son las normales.
- **Banco, sin comprobar:** el oro pasivo parece no llevar el ×2 del Turbo imitado (ningún `GameTick` en `obs ingresos`);
  igual en los dos lados.
- **Bot propio** (`bots/FunLib/propio/`):
  - no puede activar runas: de pie sobre la runa, con su tipo leído, ni `Action_`, ni `ActionQueue_`, ni `ActionPush_PickUpRune`
    hacen nada desde el `Think` propio, y la misma llamada funciona en OHA desde su modo. Causa sin explicar; apagadas (`K.runas`);
  - menos kills que OHA (1,6 frente a 2,4 hasta el min 10): el daño de 4 s queda en la mitad de la vida del rival;
  - el rival de mid farmea más que contra OHA (12,1 LH frente a 10,8): deuda aceptada por Pedro al cerrar la línea (DECISIONES 2026-11-05);
  - poco daño a héroes y pocas kills en medio juego frente a OHA con el mismo rival (`fijo-p5`: 13.956 frente a 21.823, 7,1 frente a 13,0): pelea menos tiempo;
  - contra un humano, sin comprobar con este código: en sus partidas anteriores iba a 40-42 LH en el min 10 y 7-10 muertes;
  - la API no distingue una ilusión enemiga (`IsIllusion` falso con tres Zeus a la vez): el peligro ya cuenta una por héroe, pero
    `VisibleEnemies` y el Assassinate aún pueden apuntar a una copia.
- **Bot OHA:**
  - la defensa se apaga cuando 3 aliados empujan (`FunLib/aba_defend.lua:~915-937`);
  - la recompra por el Ancient está rota (`ability_item_usage_generic.lua:569`);
  - torres sin defender y ultis lanzadas a creeps o a la nada en la base propia (vistas por Pedro): corregido como
    variante `nivel1`, que no mejora y no se activa;
  - más en docs/mapa.md §8.
- ~10 «error in error handling» por partida, sin origen.
- Saludos con promoción del Workshop.
- FretBots `set`/`nudge` usan `loadstring` (host).
- Dependencias npm heredadas con un conflicto de `typescript`.
