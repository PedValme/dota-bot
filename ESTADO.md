# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **Qué se estaba haciendo:** el medio juego del Sniper propio (`bots/FunLib/propio/medio.lua`), que Pedro adelantó a los cinco en línea
  (DECISIONES 2026-11-05): gastar el oro, tienda secreta, Shadow Blade/Silver Edge, Force Staff/Hurricane Pike y el «criterio de
  riesgo-taque-sigilo». Variante `control_sniper`, `--mid sniper`, frente a `base_sniper`.
- **Dónde quedó:** línea cerrada: `fase1k`, 61,5 últimos golpes y 0 muertes en el min 10 (OHA 55 y 1,00); el rival de mid en 12,1 frente a
  ≤ 11, como deuda. Pedro: «muchisimo mejor en early game». Contra él: 40 LH en el min 10, 10 muertes y 17.087 de oro sin gastar en 36 min
  (MEDICIONES 2026-11-05). Noche del 2026-11-06 (encargo de Pedro): contra un equipo OHA, que presiona de verdad (`--rival dotabot --variantes control_sniper,base`),
  `presion6` en el min 25: 212,5 LH, 0,5 muertes, 5,3 kills, patrimonio 21.689; el Sniper de OHA, 181,3, 2,0, 13,8 y 28.094 (4 partidas cada uno, sorteos distintos).
- **Qué se probó:** partidas de Pedro con registro: `node tools/jugar-sniper.mjs` y `quitar`; `bench/observaciones/lobby-*.log`. Cambios de la noche en MEDICIONES 2026-11-06.
  Pedro pidió seguir con humos hasta el pulido (DECISIONES 2026-11-06), con héroes fijos para comparar vueltas: `fijo-oha-a`/`-b` hechos; `fijo-p1` cortado el 2026-11-06 por falta de memoria (Unreal Editor ajeno, 77 GB; 5 % libre).
- **Siguiente acción:** con memoria libre y el sí de Pedro, repetir la línea base y medir con `node tools/analisis/pulido.mjs --referencia fijo-oha-a,fijo-oha-b <etiquetas>`. **Sin jugar aún:** aprender el daño de cada rival, Assassinate para abrir peleas y antes en la build; `fightOdds` 1 y grupo a 6.000, una sola vuelta ruidosa (`presion8`).
- Espera al dueño: decir cuándo hay memoria libre para seguir con los humos de pulido · Recomendado: cerrar los Unreal Editor que no use, y relanzar con su sí

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

## Siguientes pasos
1. Medio juego del Sniper propio, hasta el visto bueno de Pedro: `trabajo/bot-propio.md`.
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
  - poco daño a héroes y pocas kills en medio juego frente a OHA con el mismo rival: 31.102 frente a 89.369 tras el min 12, 5,3 kills frente a 13,8 en el min 25;
  - en línea, con un rival que presiona, no contesta en el 49 % de los acosos (OHA 23 %), y el rival de mid hace 20,3 LH: el `ratio` con daño real lo aleja más;
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
