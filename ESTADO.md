# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **2026-10-31. Todo lo medido hasta hoy está contaminado** (MEDICIONES.md, sesgos S1-S6). Se construye el nivel 0
  del protocolo nuevo (DECISIONES 2026-10-31: puerta de medición y avance en tres niveles).
- En `main` (#22): commit por partida, tope de 60 min, parada con más del 20 % inválidas, junctions comprobadas,
  couriers, `rojas` en `.fabrica.json`, MEDICIONES.md.
- Rama `claude/banco-s6` (revisada, falta humo y PR):
  - S6 corregido: el archivo de equipo dura toda la partida y una línea de carga por bot lo comprueba;
  - fase previa de 90 s: todos los héroes antes del inicio;
  - una partida que llega al tope es válida, sin ganador;
  - **mismo enfrentamiento en los dos lados** (decisión de Pedro): dos sorteos sin héroes en común, dota-bot siempre
    el primero, y la validez exige a cada equipo su grupo. El espejo y la creación de héroes, que cerraban Dota, se
    quitaron.
- Siguiente: dos partidas de humo válidas, PR y fusión; la pregunta en MEDICIONES.md y la serie A contra A
  (`--variantes base,base_b`, 12 partidas).

## Madurez
Prototipo: OHA 7.41a (127 héroes) con limpieza de seguridad, al día con 7.41f. Sin cambios de juego activos por
defecto. Variantes del benchmark: `empuje`, `grupo`, `cerebro`, `cerebro_builds`, `fase_estado` y otras, apagadas sin
archivo de variante. Ninguna medida aún sin contaminación.

## Entregado
- 2026-10-28/29 · Investigación, fork limpio, junctions, orquestador con GSI, custom game dotabench, series A/B con
  validez, Turbo imitado con courier y espectador (PR #1-#17).
- 2026-10-30 · Mapa, modo observador y analizador (#18); variantes de remate (#19); diseño y cerebro v1 (#20, #21).
- 2026-10-31 (rama, sin fusionar) · Cerebro v2, builds con datos, fases por estado de partida, espejo de héroes, rival
  dota-bot, `mecanismo.mjs`, registro de ultis y torres, protocolo de medición, MEDICIONES.md.

## Siguientes pasos
1. Nivel 0: humo, revisor adversarial y serie A contra A.
2. Nivel 1, mecanismo: el filtro de ultis (que no se lancen sin enemigos cerca) y la defensa de T1/T2 «con cabeza».
3. Nivel 2: el punto dulce del empuje en grupo, y elegir entre base, fases por estado y cerebro.
4. Una prueba en el entorno real: lobby Local Host con amigos, Turbo real.

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
  - el sorteo de héroes sale de una lista recordada, no de `BotImplemented`;
  - el Turbo imitado no es el Turbo real: torres y runas son las normales.
- **Bot:**
  - la defensa se apaga cuando 3 aliados empujan (`FunLib/aba_defend.lua:~915-937`);
  - la recompra por el Ancient está rota (`ability_item_usage_generic.lua:569`);
  - torres sin defender y ultis lanzadas a creeps o a la nada en la base propia (vistas por Pedro);
  - más en docs/mapa.md §8.
- ~10 «error in error handling» por partida, sin origen.
- Saludos con promoción del Workshop.
- FretBots `set`/`nudge` usan `loadstring` (host).
- Dependencias npm heredadas con un conflicto de `typescript`.
