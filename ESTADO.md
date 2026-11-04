# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **Cerebro v3 (firmado 2026-11-01) construido, medido y parado: no mejora a `base`.** Serie `n3-v3r` parada por
  perjuicio en la primera mirada (3-4; con la serie cortada antes, 11 de 32 frente a 12 de 32). Corridas paradas hasta
  corregir (DECISIONES 2026-11-03). Todo en MEDICIONES desde `v3-partida0`.
- **Diagnóstico hecho** (MEDICIONES, «Diagnóstico de las ventajas regaladas»): dota-bot, con y sin v3, pierde ventajas de
  oro sin edificios (en el pico Valve conserva 7-8 de 11 torres y todos los cuarteles); Valve remonta empujando su
  mitad (6-7 torres y 3-4 cuarteles perdidos, el 65-70 % de las muertes en la mitad propia, en rachas). v3 apenas
  asalta después del pico (89 % del tiempo en línea, reagrupando o defendiendo).
- **Bot propio con control completo** (DECISIONES 2026-11-03). Hecho el 2026-11-03:
  - base de primera mano: `docs/api/` (volcado del motor, datos de Valve cotejados), la wiki de Valve
    (`docs/investigacion/2026-11-03-api-valve.md`), la API y OHA (`…-api-y-oha.md`), D2AI y Tinkering (`…-d2ai-tinkering.md`);
  - **prueba de control completo hecha** (MEDICIONES, «Prueba de control completo, humo»): con `Think()` propio el
    motor no actúa solo y de OHA solo queda `ItemPurchaseThink`, neutralizado; el Sniper propio (`bots/FunLib/propio/`,
    variante `control_sniper`, `--mid sniper`) creepea en los dos lados y saca en el min 10 el 67-80 % de los
    últimos golpes de OHA, sin habilidades ni compras. Le falta: peligro por alcance real, responder al acoso, sus
    habilidades y su build.
  - diseño firmado (DECISIONES 2026-11-03, «ok procede»); **fase 1 hecha en humo** (MEDICIONES, «Fase 1 del bot
    propio, humo»): con build y mensajero (`compras.lua`), Shrapnel y Assassinate (`sniper.lua`), acoso y peligro por
    alcance, el Sniper propio suma 111 últimos golpes frente a 101 de OHA en el min 10 (dos lados) y el 96 % de su
    patrimonio; 0 errores, 0 ataques automáticos, 30 Think/s. Meta del diseño cumplida en humo.
  - Siguiente acción: la serie de la fase 1 con su puerta de medición (pregunta escrita, revisor adversarial,
    tamaño fijado antes, máquina libre), y con su resultado, la fase 2 (los cinco en línea).
- Espera al dueño: aprobar la serie de la fase 1 (6 bloques, 24 partidas, unas 8 h de máquina libre, sin coste de cuota; pregunta: ¿el Sniper propio iguala a OHA en LH y patrimonio del min 10?) · Recomendado: aprobarla y correrla de noche con el PC libre
- El código de v3 está en `main` apagado por defecto (variante `cerebro_v3`), con las mejoras del banco
  (`--repetir-invalidas`, contador de Think, `tools/analisis/n3-v3.mjs`). La fase de líneas queda como está
  (DECISIONES 2026-11-02).
- Pedro critica, con razón, que el bot por defecto sigue igual tras días de trabajo. No repetir construcciones grandes
  sin un diagnóstico que diga dónde se pierde.
- **2026-11-01. Niveles 0 y 1 hechos y en `main`** (#22-#26):
  - banco completo; serie A contra A (`aa`): brazos parejos, las victorias son demasiado ruidosas para el nivel 2
    (~90 partidas por brazo para 20 puntos) y el minuto de +10.000 apenas varía (~1,4 min);
  - nivel 1: variantes `filtro_ultis`, `defensa_t12` y `nivel1`; su humo pasó (MEDICIONES, `humo-n1`). Falta ver en
    partida un rechazo de ulti (héroes con ultis de riesgo: Skywrath, DK).
- **Nivel 2, serie 1 hecha** (MEDICIONES, `n2-nivel1`): `nivel1` no mejora y no se activa. Los datos señalan dos
  palancas: dos tercios de las muertes de dota-bot ocurren en RETIRADA, y `base` no cierra con ventajas enormes (dos
  topes con +94.000 y +52.000).
- **Nivel 2, serie 2 hecha** (MEDICIONES, `n2-pd`): el empuje en grupo no muestra mejora; dota-bot pierde la mitad de
  las partidas en que llega a ir +10.000. Prioridad: la retirada (Pedro: «si, agrega la retirada al nivel 1»).
- **Retirada, nivel 1 hecho** (#36, MEDICIONES): `retirada_temprana` v2 adelanta la huida (2 s desde la amenaza ≥ 1,
  antes 4) y ningún bot muere sin huir.
- Pendientes del banco, menores: que la línea `start` registre las bajas (estrechar el margen de patrimonio inicial);
  contar cuántas veces piensa un bot por segundo de juego. La lista de héroes del sorteo quedó verificada: los 31
  están entre los 39 que Valve sabe llevar (`docs/api/README.md`).

## Madurez
Prototipo: OHA 7.41a (127 héroes) con limpieza de seguridad, al día con 7.41f. Sin cambios de juego activos por
defecto. Variantes del benchmark: `empuje`, `grupo`, `cerebro`, `cerebro_builds`, `fase_estado` y otras, apagadas sin
archivo de variante. Ninguna medida aún sin contaminación.

## Entregado
- 2026-10-28/29 · Investigación, fork limpio, junctions, orquestador con GSI, custom game dotabench, series A/B con
  validez, Turbo imitado con courier y espectador (PR #1-#17).
- 2026-10-30 · Mapa, modo observador y analizador (#18); variantes de remate (#19); diseño y cerebro v1 (#20, #21).
- 2026-10-31/11-01 · Banco de medición fiable y protocolo (#22, #24, #25), cerebro v2, builds y fases por estado (#23),
  nivel 1 (#26), MEDICIONES.md.

## Siguientes pasos
1. Nivel 2 (arriba).
2. Contar cuántas veces piensa un bot por segundo de juego, con y sin carga.
3. Una prueba en el entorno real: lobby Local Host con amigos, Turbo real.

## Problemas conocidos
Defectos sin resolver. Mientras sigan abiertos, no se mide sobre los del banco.
- **Banco: Dota se cierra solo** al cambiar o crear héroes de Dire (5 de 16 partidas con espejo, 1 de 2 creando).
  Se dejó de hacer: cada equipo pide su propio sorteo. Sin comprobar aún en una serie que no vuelva a pasar (2 de 2
  partidas de humo sin cierres).
- **Banco: el primer bot añadido aparece de 15 a 50 s tarde.** Con 90 s de fase previa llega antes del inicio, y la
  validez rechaza cualquier héroe aparecido después. Causa sin explicar.
- **Banco: velocidad real variable** (×1,6 a ×3,4 con `--velocidad 4`), sin saber si afecta distinto a cada lado.
- **Banco, sin comprobar:**
  - si a ×4 los bots de Lua piensan menos por segundo de juego que los de Valve;
  - el Turbo imitado no es el Turbo real: torres y runas son las normales.
- **Bot:**
  - la defensa se apaga cuando 3 aliados empujan (`FunLib/aba_defend.lua:~915-937`);
  - la recompra por el Ancient está rota (`ability_item_usage_generic.lua:569`);
  - torres sin defender y ultis lanzadas a creeps o a la nada en la base propia (vistas por Pedro): corregido como
    variante `nivel1`, sin medir aún contra `base`;
  - más en docs/mapa.md §8.
- ~10 «error in error handling» por partida, sin origen.
- Saludos con promoción del Workshop.
- FretBots `set`/`nudge` usan `loadstring` (host).
- Dependencias npm heredadas con un conflicto de `typescript`.
