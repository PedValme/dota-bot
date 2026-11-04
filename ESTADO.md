# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **Qué se estaba haciendo:** el bot propio con control completo (DECISIONES 2026-11-03; diseño en `trabajo/bot-propio.md`).
  Fase 1: un Sniper en mid con `Think()` propio (`bots/FunLib/propio/`, variante `control_sniper`, `--mid sniper`), frente
  al Sniper de OHA (`base_sniper`).
- **Dónde quedó:** el control completo funciona (el motor no actúa solo; de OHA solo queda `ItemPurchaseThink`,
  neutralizado). En cinco humos el propio sigue por debajo de OHA en la mayoría de las métricas, así que la serie queda
  aplazada (DECISIONES 2026-11-04: solo confirma lo que los humos ya muestran a la par o mejor).
- **Qué se probó:** tres revisores adversariales (datos, bot, método) corrigieron el diagnóstico: la brecha de patrimonio
  es 51 % kills y 41 % últimos golpes; el propio no activa runas, no usa TP ni Take Aim (OHA, sí); llega a las peleas sin
  haber dañado al rival; y un bloque no decide nada (±18 LH). MEDICIONES, «Revisión adversarial de la fase 1».
- **Decidido por Pedro** (DECISIONES 2026-11-04, las seis propuestas del plan): nuevo listón, humos cortados con la
  carga anotada, build propia, rotación apagada, confirmación de 20 parejas, y él juega 15 minutos al final de la vuelta.
- **Siguiente acción:** leer `trabajo/fase1-plan.md` y seguirlo en orden: `--corte` y registro nuevo en el banco, con
  revisión; defectos del bot; mejoras decididas; luego 8 partidas del propio frente a una referencia de OHA.
- Espera al dueño: nada

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

## Siguientes pasos
1. Fase 1 del bot propio: `trabajo/fase1-plan.md`.
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
- **Bot propio** (`bots/FunLib/propio/`; plan en `trabajo/fase1-plan.md`):
  - nunca activa una runa, con 116 decisiones de ir a por ella; causa sin comprobar;
  - no usa TP, y Take Aim no llega hasta el nivel 11;
  - `compras.lua` registra ventas que no ocurren (4 ventas con 2 ramas), deja oro ocioso, no compra en la tienda secreta
    ni repone salvia;
  - último golpe y `preparar_golpe` no miran el margen de torre;
  - `golpe_res` pisa el intento pendiente: su porcentaje de aciertos está sesgado.
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
