# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **Qué se estaba haciendo:** el plan de mejora del equipo propio, firmado por Pedro (`trabajo/plan-mejora-equipo.md`, DECISIONES 2026-11-13). Meta: ganar con sobra al equipo de OHA, con cada cambio medido cara a cara, intercalado, en 3 alineaciones y con `tools/bench/equipo.mjs`.
- **Dónde quedó:** cinco paquetes en la línea de dos. Los paquetes 1 y 2 (reglas de línea), la capa de pareja `dos.lua` y el paquete 3 (héroes) no movieron el resultado; su código sigue en `main`, tras la variante.
  - El diagnóstico de las 94 muertes de `h2`, con su revisión adversarial, mostró la causa: no devolvíamos daño y nadie seguía nuestras aperturas.
  - El paquete 4 ataca eso.
  - Al min 12 frente a OHA con los mismos héroes, la diferencia de kills del equipo ronda −10 a −12.
- **Qué se probó:** reglas del 1 contra 1, pareja que entra y sale, hechizos como OHA, y ahora seguir las aperturas y presionar en pareja.
- **Siguiente acción:** paquete 4 (firmado por Pedro, DECISIONES 2026-11-14; variante `control_equipo_p4`), ronda 1 hecha (MEDICIONES 2026-11-14):
  - la pareja ya hace el daño que le faltaba: difícil ×1,67, tras una apertura 228 frente a 51;
  - la difícil mejora (+1,7 kills);
  - la segura empeora (+1,8 muertes, −2,2k);
  - el equipo queda en −2,2 kills, dentro del ruido.

  Siguiente:
  1. diagnosticar en `p4a-*` por qué empeora la segura (¿presión 2 contra 2 frente a rivales tanque?) y comprobar si el tango «con un rival a 900» son rivales que el bot no ve;
  2. ronda 2, la última, solo con causas leídas;
  3. después, el piloto de guías de YouTube.

  Antes: diagnóstico de las muertes de `h2` y su revisión adversarial.
  Cada tanda se revisa por `prop error` antes de leerla.
- **Después, en sesión nueva** (Pedro, DECISIONES 2026-11-14): piloto de reglas de héroe sacadas de guías de YouTube, con los cinco héroes (`trabajo/guias-youtube.md`).
  - Las transcripciones se bajan con `yt-dlp`, a instalar con pip: el conector de YouTube solo da subtítulos de los videos del canal propio.
  - Va después de cerrar la ronda del paquete 4.
- Lo que espera a Pedro vive en OmniBrain (P-177): `omnibrain_esperas` con repo `dota-bot`, o «Te espera» en el panel.

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
- 2026-11-06/12 · Evaluación adversarial (#84); banco con tienda universal (#85); base nueva (#86); «con el equipo» (#87); selección del lobby (#88); retoque (#90); marcador de fin de partida (#91); build según los enemigos, Shrapnel por cargas y daño a edificios (#92); partidas de Pedro (#89, #93); paquete de varias mejoras (#95); fase 2, base y cuatro héroes (#97); plan de mejora, análisis fijo y A contra A (#99); paquetes 1 y 2, medidos sin mejora (#100); registro fino y estudio de OHA en las líneas de dos (#101); capa de la línea de dos, TP a la fuente y sombra, 2 rondas sin cumplir (#103); paquete 3, héroes, sin cumplir (#105); paquete 4, la pareja sigue sus aperturas, ronda 1 (#108).

## Siguientes pasos
1. Plan de mejora del equipo (`trabajo/plan-mejora-equipo.md`): diagnóstico de las muertes en las líneas de dos (ver «Próxima sesión»).
2. Medio juego del Sniper: farm frente a presencia y las rotaciones, con lo que Pedro vea al jugar contra el equipo.
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
  - menos kills que OHA (7,3 frente a 9,5, `paquete1`) y remata menos cuando pega (59 % frente a 67 %);
  - menos últimos golpes que OHA desde que sigue siempre al aliado (126 frente a 154, `paquete1`);
  - las rotaciones eligen objetivos que los aliados matan con hechizos antes de que llegue (17 de 22 `objetivo_muerto`, `paquete2`);
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
