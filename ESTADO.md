# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **Qué se estaba haciendo:** el bot propio con control completo (DECISIONES 2026-11-03; diseño en `trabajo/bot-propio.md`).
  Fase 1: un Sniper en mid con `Think()` propio (`bots/FunLib/propio/`, variante `control_sniper`, `--mid sniper`), frente
  al Sniper de OHA (`base_sniper`).
- **Dónde quedó:** el propio pasó el listón en humo a la primera vuelta: 60,1 últimos golpes en el min 10 frente a 57,4 de
  OHA, 0 muertes frente a 1,1 y patrimonio 7.737 frente a 7.628, en 8 y 8 partidas de corridas separadas (MEDICIONES,
  `fase1h`, `ref-oha`). Puerta de la confirmación cumplida. Corre `conf1-a`.
- **Qué se probó:** banco con `--corte` (5 min por partida) y registro nuevo; defectos y mejoras de `trabajo/fase1-plan.md`.
  La ablación no ve coste de farm del combate. `kill_eval`: casi todas las kills las frena el margen, por falta de daño.
- **Siguiente acción:** la confirmación son 3 tandas seguidas, mismo commit de `bots/` y `tools/bench/`: `conf1-a` (16
  partidas), `conf1-b` y `conf1-c` (12 y 12), con el comando de MEDICIONES y `--etiqueta` de cada una. Tras cada tanda,
  `node tools/analisis/serie-fase1.mjs conf1-a [conf1-b [conf1-c]]`: para si dice inutilidad. Con las tres, leer el veredicto,
  anotarlo en MEDICIONES y, si pasa, a la fase 2 (`trabajo/bot-propio.md`), borrando `trabajo/fase1-plan.md`.
- Espera al dueño: jugar 15 minutos contra el Sniper: `node tools/jugar-sniper.mjs`, Custom Lobby con Local Host y Local Dev Script, y al acabar `node tools/jugar-sniper.mjs quitar`; con Dota libre, entre tandas de la confirmación.

## Madurez
Prototipo. El bot por defecto es OHA 7.41a (127 héroes) con limpieza de seguridad, al día con 7.41f, sin cambios de juego
activos por defecto: todo lo nuevo, también el bot propio, va apagado tras variantes del banco. Ninguna serie aún sin
contaminación. Rumbo: bot propio (DECISIONES 2026-11-03); OHA no se sigue parcheando: `cerebro_v3` quedó apagado tras no
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
1. Fase 1 del bot propio: terminar la confirmación (`trabajo/fase1-plan.md`, paso 6).
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
  - no compra en la tienda secreta: Crystalys y Satanic se saltan, ya pasado el min 10;
  - `VisibleEnemies` no filtra ilusiones: se persigue y se lanza Assassinate a ilusiones (inferido, sin comprobar).
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
