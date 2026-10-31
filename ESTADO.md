# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **2026-10-31. Todo lo medido hasta hoy está contaminado** (MEDICIONES.md, sesgos S1-S5). Se está construyendo el
  nivel 0 del protocolo nuevo (DECISIONES 2026-10-31: puerta de medición y avance en tres niveles).
- Hecho en el banco:
  - espejo con patrimonio completo, guardianes y humo devueltos, y borrado del héroe viejo;
  - validez exige mismos héroes y patrimonio inicial por equipo y por héroe;
  - commit por partida, tope de 60 min, parada con más del 20 % inválidas, junctions comprobadas;
  - `rojas` en `.fabrica.json`.
- Siguiente:
  1. Repetir la partida de humo con el commit `5d8bfb5` o posterior y comprobar que Dota ya no se cierra solo.
  2. Pasar el log al revisor adversarial.
  3. Serie A contra A (`--variantes base,base_b`, 12 partidas), con la pregunta escrita antes en MEDICIONES.md.
- **Espera a Pedro:** si una partida que llega al tope de 60 min cuenta como válida y como «no ganó» para dota-bot
  (recomendado) o se descarta.
- La rama `claude/cerebro-v2-builds` se parte en un PR por tarea (orden de la fábrica, 2026-10-31).

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
- **Banco: Dota se cierra solo** (access violation) en 3 de 11 partidas con espejo; ninguna antes del espejo. Causa
  probable: el héroe reemplazado seguía en el mapa. Corregido en `5d8bfb5` (se borra), **sin comprobar** aún.
- **Banco: héroes que aparecen tarde.** El héroe del puesto 1 de cada equipo apareció unos 20 s de juego después del
  inicio en una partida de humo, en los dos lados por igual. Sin explicar. La línea `start` espera a que estén todos.
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
