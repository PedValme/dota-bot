# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **Qué se estaba haciendo:** pulir el medio juego del Sniper propio (variante `control_sniper`) frente al de OHA, con el banco arreglado (tienda universal, #85), el marcador de fin de partida (`tools/analisis/evaluacion-2026-11-06/a11.py`, `a12.py`) y la build según los enemigos (`trabajo/build-estrategica.md`, #92). Historia completa en MEDICIONES, del 2026-11-06 al 2026-11-12.
- **Dónde quedó:** última versión, `build2` (#92). Frente a OHA en el banco: daño 21.313 y 25.285, muertes 1,0 y 3,1, últimos golpes 153 y 154; kills 5,2 y 9,5. En la quinta partida de Pedro (2026-11-12): «se posiciona regular, antes se ocultaba mejor [...] pero su presión es mucho mayor, si es más agresivo y jodido, bastante jodido».
- **Qué se probó:** de una en una, las mejoras dan poco (Pedro, 2026-11-12: «estamos atacando muy poco»). Lo que mejor funcionó fueron los paquetes de varias mejoras con causas leídas en el registro («con el equipo», #87).
- **Siguiente acción:** un paquete de varias mejoras a la vez (DECISIONES 2026-11-12), con diagnóstico en los registros, a lo sumo 2 rondas de mecanismo y luego la partida de Pedro. Candidatas, todas con su causa vista:
  - posición y sigilo: volver a seguir siempre al aliado más cercano, manteniendo los campamentos junto a él (la regla del retoque en `medio.lua`, `TeamSpot`; entra oculto a 1 pelea frente a 13);
  - remates: 48 % de las muertes en las que pega frente a 67 % de OHA (¿el filtro «lo matan mis golpes» de `sniper.lua`?);
  - kills de línea: 1,0 al min 10 frente a 3,2 (las rotaciones las apagó Pedro el 2026-11-04: pedirle su palabra para encenderlas);
  - golpes a héroes entre los min 10 y 20: 30 frente a 56.
- Espera al dueño: nada hasta que el paquete esté medido

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
- 2026-11-06/12 · Evaluación adversarial (#84); banco con tienda universal (#85); base nueva (#86); «con el equipo» (#87); selección del lobby (#88); retoque (#90); marcador de fin de partida (#91); build según los enemigos, Shrapnel por cargas y daño a edificios (#92); partidas de Pedro (#89, #93).

## Siguientes pasos
1. Medio juego del Sniper propio, hasta el visto bueno de Pedro: paquete de varias mejoras (ver «Próxima sesión»); `trabajo/bot-propio.md`.
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
  - menos kills que OHA (5,2 frente a 9,5, `build2`) y remata menos cuando pega (48 % frente a 67 %);
  - contra Pedro (2026-11-12) se oculta y se posiciona peor que en la versión anterior (menos tiempo con el grupo);
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
