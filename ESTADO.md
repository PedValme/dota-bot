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
- Rama `claude/banco-s6` (sin PR): S6 corregido, línea de carga por bot, fase previa de 90 s (todos los héroes antes
  del inicio), tope de 60 min válido. Falta la revisión de sus últimos commits antes del PR.
- **Bloqueo: el espejo (`ReplaceHeroWith`) cierra Dota** en 5 de 16 partidas (1 de 126 sin él). Medido: el primer
  equipo añadido recibe sus héroes, el segundo al azar (30 s de selección no cambia nada) y uno añadido 1 s tarde
  ninguno.
- Opción 1 (Dire sin héroe y `CreateHeroForPlayer`) probada y descartada: Dota se cerró igual y el motor no reconoce
  esos héroes. Causa de fondo, medida: el motor nunca da el mismo héroe a los dos equipos (0 de 112 partidas).
- **Funciona `--espejo cruzado`** (2 humos, `b3138c2` y siguiente): dos sorteos sin héroes en común, dota-bot siempre
  el primero en los dos lados; ningún héroe cambiado, sin crashes.
- **Espera a Pedro:** aceptar «mismo enfrentamiento en los dos lados» en vez de «mismos héroes» (recomendado); con su
  sí, validez por grupo pedido, modo cruzado por defecto, quitar espejo y creación de héroes, revisión y PR.
- Después: revisor adversarial del humo y serie A contra A (`--variantes base,base_b`, 12 partidas), con la pregunta
  escrita antes en MEDICIONES.md.
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
- **Banco: Dota se cierra solo** (access violation) en 3 de 12 partidas con espejo; antes del espejo, 1 en 126.
  Causa probable: el héroe reemplazado seguía en el mapa. Corregido en `5d8bfb5` (se borra), **sin comprobar** aún,
  como tampoco que los couriers de Dire sobreviven a ese borrado (ahora es un control de validez).
- **Banco: héroes que aparecen tarde**, sobre todo el del puesto 1 de Radiant (de t=-3 a t=+40), y no en Dire salvo
  por el espejo. Pierden tiempo de línea y, hasta el arreglo de S6, los jugaba dota-bot aunque fueran de Valve.
  Hipótesis: el humano ocupa un hueco de Radiant cuando se añaden los bots. Prueba en curso: añadir los bots 1 s
  después de sacarlo. Ahora la validez rechaza cualquier héroe aparecido tras el inicio.
- **Banco: S6 corregido sin comprobar en partida** (rama `claude/banco-s6`): el archivo de equipo dura toda la
  partida y la validez rechaza héroes de Valve jugados por dota-bot.
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
