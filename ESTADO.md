# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **Qué se estaba haciendo:** la ruta que Pedro aprobó tras la evaluación adversarial: `trabajo/evaluacion-adversarial-2026-11-06.md`, DECISIONES 2026-11-06.
- **Dónde quedó:** pasos 1 a 5 hechos (MEDICIONES 2026-11-07). Banco arreglado y paquete «con el equipo» fusionado en la variante `control_sniper`. Ronda 2, frente a `base2-propio` y OHA: tiempo sin aliado 40 % (66 %, 59 %), participación en kills 0,53 (0,36, 0,49). Coste mayor del previsto: 98 últimos golpes (168, 154), 17.113 de objetos (19.188, 21.070), 3,3 muertes (2, 3).
- **Qué se probó:** la exposición no separa las muertes contra un humano. Ronda 1, fallida: iba y venía y perseguía grupos que duran 12 s. Con 4-8 partidas solo se lee mecanismo. Se agotaron las 2 rondas.
- **Siguiente acción:** la partida de Pedro decide. Al jugar, el registro dice además si OHA acumula oro en Turbo real (`[bench] aliado`) y si las piezas secretas se compran directo (`prop compra ... secreta`): leerlo después. Si no ve el cambio, se cierra el Sniper y se pasa a los cinco con cerebro propio (DECISIONES 2026-11-06).
- Espera al dueño: jugar contra el Sniper y decir si se nota · Recomendado: con Dota cerrado, `node tools/jugar-sniper.mjs`, una partida en Turbo, y al acabar `node tools/jugar-sniper.mjs quitar`

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
1. Medio juego del Sniper propio, hasta el visto bueno de Pedro: ruta propuesta en `trabajo/evaluacion-adversarial-2026-11-06.md`, pendiente de su decisión; `trabajo/bot-propio.md`.
2. Fase 2, los cinco en línea: `trabajo/bot-propio.md`.
3. Revisar otros bots de la comunidad (Ranked Matchmaking AI, BOT Experiment, New Beginner AI, ExtremePush) al llegar a
   peleas, objetos o estrategia (DECISIONES 2026-11-03).
4. Una prueba en el entorno real: lobby Local Host con amigos, Turbo real.
5. Menores del banco: que la línea `start` registre las bajas (estrechar el margen de patrimonio inicial).

## Problemas conocidos
Defectos sin resolver. Mientras sigan abiertos, no se mide sobre los del banco.
- **OHA en Turbo real, sin comprobar:** en el banco no compraba piezas de tienda secreta desde el 2026-10-31 (código 62 descartado en silencio, `item_purchase_generic.lua:466-473`; mediana de 37 % de patrimonio sin gastar en el min 25). Arreglado en el banco con la tienda universal; toda serie Turbo anterior no es comparable. Si en Turbo real pasa igual, es un defecto de lo que Pedro juega: se ve en su próxima partida.
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
  - menos kills que OHA con el banco arreglado (6,7 frente a 10, `equipo2`), y 98 últimos golpes frente a 154 al ir con el equipo: el coste de ese paquete, sin decidir si compensa;
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
