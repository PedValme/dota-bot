# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **Qué se estaba haciendo:** el bot propio con control completo (DECISIONES 2026-11-03; diseño en `trabajo/bot-propio.md`).
  Fase 1: un Sniper en mid con `Think()` propio (`bots/FunLib/propio/`, variante `control_sniper`, `--mid sniper`), frente
  al Sniper de OHA (`base_sniper`).
- **Dónde quedó:** **la confirmación pasó** (20 parejas, 40 de 40 válidas): 59,4 últimos golpes en el min 10 frente a 55, +4,4
  con IC95 +1,2 a +7,6, y 0,20 muertes frente a 1,00. Patrimonio −193 (informativo), kills 1,25 frente a 2,35 y 0 runas
  (MEDICIONES, «Confirmación de la fase 1»). Solo mide la línea: las 2 partidas completas de este commit las ganó Valve.
- **Qué se probó:** banco con `--corte` (5 min por partida) y registro nuevo; defectos y mejoras de `trabajo/fase1-plan.md`.
  La ablación no ve coste de farm del combate. `kill_eval`: casi todas las kills las frena el margen, por falta de daño.
  Pedro jugó contra el Sniper (2026-11-05): «la subnormalidad de nuestro sniper es inconmensurable jajajajaja es nefasto, todos
  los bots lo son, solo empiezan a ser competentes en late porque usan bien sus poders». La partida no dejó registro.
  Sus quejas se ven en los registros (MEDICIONES 2026-11-05): sin devolver nada en el 44 % de los acosos (OHA 17 %), menos de la
  mitad de daño a héroes, y el rival de mid hace 15,3 LH frente a 10,8. El banco no reproduce la presión de un humano.
  Hecho, con el listón nuevo (DECISIONES 2026-11-05): `intercambio.lua` y registro de sus partidas. Tras 3 vueltas, `fase1k`: 61,5 LH,
  0,0 muertes, 13 % sin devolver (2 de 16), 3,0 kills, patrimonio 8.252; **sin cumplir: rival de mid 12,1 LH frente a ≤ 11**.
  Segunda partida de Pedro, con registro: «muchisimo mejor en early game», pero en medio juego y late «se posiciona muy mal» y falta el
  «criterio de riesgo-taque-sigilo». El registro lo confirma: 1 muerte hasta el min 10, 10 al final, 17.087 de oro sin gastar y las
  mismas reglas de línea toda la partida (MEDICIONES 2026-11-05): el Sniper no tiene medio juego.
- **Siguiente acción:** según lo que decida Pedro: medio juego del Sniper con objetos, colocación por riesgo y sigilo, antes de la fase 2.
- Espera al dueño: cerrar la línea de la fase 1 aceptando el rival en 12,1 LH, y adelantar el medio juego del Sniper a los cinco en línea · Recomendado: las dos cosas

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
1. Fase 1 del bot propio: intercambio en línea según lo que vio Pedro, antes de la fase 2 (`trabajo/fase1-plan.md`, paso 6).
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
  - sin medio juego: mismas reglas de línea toda la partida, lista de compras agotada en el min 20 (17.087 de oro sin gastar en el
    min 36), sin tienda secreta ni objetos de movilidad o sigilo, sin usar objetos activos;
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
