# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **Qué se estaba haciendo:** pulir el medio juego del Sniper propio (variante `control_sniper`) frente al de OHA con un paquete de varias mejoras (DECISIONES 2026-11-12). Historia en MEDICIONES, del 2026-11-06 al 2026-11-12.
- **Dónde quedó:** versión `paquete1` (este PR): sigue siempre al aliado más cercano, rotaciones encendidas solo hacia un enemigo con un aliado cerca (Pedro: «Sí, con su causa»), Assassinate no corta los golpes a tiro con un aliado encima ni se gasta abriendo peleas sobre objetivos a tiro, y dispara a un enemigo a tiro si es seguro. Frente a `build2` en el banco: kills 5,2 → 7,3 (OHA 9,5), remates 48 % → 59 % (67 %), muertes 1,0 → 0,7, daño 21.313 → 24.549 (25.285); últimos golpes 153 → 126 (154).
- **Qué se probó:** en la ronda 2, farmear antes de seguir a un aliado suelto devolvió los últimos golpes (154) pero bajó kills, daño y remates: se deshizo. Contar a todo aliado cerca del objetivo no arregla las rotaciones (17 de 22 acaban `objetivo_muerto`: los aliados matan con hechizos que la estimación no ve); cuestan poco y dan 2 kills por ronda.
- **Siguiente acción:** la partida de Pedro contra `paquete1` (rondas agotadas). Después, según lo que vea: farm frente a presencia, y si las rotaciones se quedan.
- Espera al dueño: jugar contra el Sniper `paquete1` (lobby, ver `bench/README.md`) y contar qué ve · Recomendado: sí, es una mejora plausible en lo que pediste (más ataque), a cambio de farm

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
- 2026-11-06/12 · Evaluación adversarial (#84); banco con tienda universal (#85); base nueva (#86); «con el equipo» (#87); selección del lobby (#88); retoque (#90); marcador de fin de partida (#91); build según los enemigos, Shrapnel por cargas y daño a edificios (#92); partidas de Pedro (#89, #93); paquete de varias mejoras (#95).

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
