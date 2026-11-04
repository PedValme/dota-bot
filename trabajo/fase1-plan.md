# Fase 1, siguiente vuelta: plan para una sesión nueva

Pedido por Pedro el 2026-11-04: revisar con subagentes adversariales lo que tenemos, analizar qué mejorar antes de los
humos y dejar listo el plan «para implementar las mejoras y correr los humos en nueva sesión fresca». Se borra al cerrar
la fase 1. Diseño general: `trabajo/bot-propio.md`. Datos y correcciones: MEDICIONES, «Revisión adversarial de la fase 1».

Tres revisores (Opus, esfuerzo alto: datos, bot y método), sin ejecutar partidas. Sus cifras salen de 16 partidas en
`bench/observaciones/` (git las ignora: están solo en el PC de Pedro) y sus scripts, en
`tools/analisis/revision-2026-11-04/` (leen esa carpeta; fuente nueva: las líneas `[dotabench] obs`, que dan cada 30 s
K/D/A, posición, vida e ítems de los 10 héroes, y cada lanzamiento, compra, runa y kill, de los dos brazos).

## Lo que hay que tomar como sólido
1. **La brecha de patrimonio del min 10 (−1.581 de media) es 51 % kills, 41 % últimos golpes, 8 % asistencias**, por
   regresión y con residuo de hasta ±700 por pareja. Se concentra en 3 de 10 parejas (OHA con 5 o más kills). Las muertes
   no la explican (6 frente a 7).
2. **Asimetrías que no habíamos visto** (cotejado a mano, partidas enteras): runas activadas 0 frente a 5-13, TP 0
   frente a 4-19, Take Aim 0 frente a 7-15. `decision intencion=runa` aparece con «disponible a 0» y aun así no la toma.
3. **Hay enemigos cerca igual que con OHA, pero casi nunca bajos de vida** (fotos de 30 s con enemigo a menos de 1.200:
   2 de 63 con vida bajo 400, frente a 11 de 48). Los acosos cayeron 38→26→9→5 de humo en humo.
4. **Los últimos golpes de OHA salen casi todos del corredor mid** (515 de 528), no de neutrales.
5. **Un bloque no decide nada:** ±18 LH al 95 %. Ninguna mejora o empeoramiento entre humos se puede leer: cambian
   código y héroes a la vez. **El Sniper de OHA piensa 30,0/s; el brazo OHA no cambió** desde `7008627`.

## Lo que sigue sin probar
- Que Shrapnel lejano falle (no hay dato de aciertos); sí está medido que el maná baja de 100 % a 27 % en t=38.
- Que la regla de peligro o el tiempo fuera sean la causa principal (correlación −0,54, n=8).
- Que el propio remate tan bien como OHA (no hay denominador de creeps).
- Que el combate o la colocación bajen los LH (55,5 con n=2 frente a 43 con n=6, con varios cambios a la vez).
- Que un mejor umbral de `matar` dé kills (lectura: falta daño previo, no umbral). Que un humano no regale rotaciones.
- **Desacuerdo entre revisores:** el del bot pone primero un Assassinate más liberal; el de datos midió que solo 3 de 23
  kills de OHA lo llevan. No va primero: se mira con `assassinate_res` y `kill_eval`.

## Decidido por Pedro (DECISIONES 2026-11-04: «ok si a todo lo que propones, lo abordamos en sesion fresca»)
1. **Listón de la fase 1:** suelo de ≥45 LH y muertes ≤ OHA; paridad con margen −15 %; patrimonio solo informativo.
2. **Humos cortados en el min 12** con la carga anotada, sin preguntar; máximo 3 vueltas, con la salida del paso 5.
3. **La build se aparta de Valve:** Take Aim temprano, stats al inicio, Treads en agilidad, Dragon Lance pronto.
4. **Rotación apagada** hasta medir lo demás.
5. **Confirmación:** 20 parejas (unas 4 h con corte), con parada por inutilidad a 8 y 14, en vez de las 24 partidas.
6. **Pedro juega 15 minutos** contra el Sniper tras esta vuelta.

## Lo que hace la sesión nueva, en orden
Una rama y un PR por paso. Antes de cada humo, por escrito en MEDICIONES: la predicción de mecanismo (qué línea del
registro debe moverse y cuánto). Los LH solo se comparan con 8 o más partidas del mismo commit. Una causa cuenta si
aparece en 2 o más partidas. Un defecto visible en el registro se arregla y se verifica por su mecanismo, sin mirar LH.

**Paso 1. Banco** (`tools/bench/`, control: subagente que no lo escribió, y pruebas en `orquestador.test.mjs`).
- `--corte N`: termina la partida tras el minuto N (`validity` lo acepta como `corte`; el camino `tope` ya cierra y lee
  el registro). Estimado: de 75 a unos 23 min por humo de 4; la primera corrida lo mide. Se pierde victoria y cierre, que
  esta pregunta no usa. Una partida completa por cada commit candidato, para ver errores tardíos.
- Héroes fijos (`--heroes`), solo para desarrollo y atribuir causas; la confirmación mantiene el sorteo.
- Humos solo del brazo propio: `--variantes control_sniper` ya funciona, sin tocar el banco. Hace falta una referencia
  de OHA con las líneas nuevas: 8 partidas `base_sniper`, una vez.

**Paso 2. Registro, en los dos brazos** (el `addon` y `bench_*` son control; se revisa).
- `addon_game_mode.lua:390`: `creepkill killer inflictor victim x y`, por creep muerto a menos de 1.000 del Sniper (da
  clic, Shrapnel o neutral, y el denominador).
- `addon_game_mode.lua:41,45`: oro y XP por motivo, cada 30 s (sustituye la regresión).
- Filtro de daño Sniper↔héroes por `inflictor`, cada 10 s (dice si Shrapnel acierta y quién hiere).
- `addon_game_mode.lua:338` (`obs hero`): `maxhp`, `xp`, `dmg`, `aps`, `rango`; Sniper y rival de mid, cada 5 s.
- Propio: `prop kill_eval objetivo vida dmg4s score margen unsafe veto` cada 1 s con héroe a menos de 1.500
  (`combate.lua`); `pos` (x, y, distancia a frente, torre y héroe); `runa_res`, `assassinate_res`; `golpe_res` en cola
  (hoy `linea.lua` pisa el intento pendiente y por eso el «65-70 %» está sesgado).
- OHA: `mode` con x, y y objetivo de ataque (`ability_item_usage_generic.lua`, BuybackUsageThink).

**Paso 3. Defectos del bot** (`bots/FunLib/propio/`; se verifican por mecanismo).
1. Runas: por qué no se activan nunca, con la causa antes del arreglo (`combate.lua`, `Action_PickUpRune`).
2. Vender lejos de la tienda: `compras.lua` registra 4 ventas con 2 ramas (supuesto: la venta falla sin aviso).
3. Oro ocioso: 300 en t=0 (OHA 40), 1.596 en t=360 esperando el martillo.
4. Sustain: `RuleHeal` pide ningún héroe a 1.500 (OHA, 900 o su alcance), árbol a 350 (OHA, 800), sin recompra de salvia.
5. Maná: no gastar Shrapnel al principio (OHA, primer Shrapnel a los 137-219 s), a ≤ alcance+200, y reservar el maná de
   Assassinate.
6. Torres: `RuleLastHit` y `preparar_golpe` no miran el margen de torre (m3 t=45-52, de 0,94 a 0,20).
7. Denegar: no gastar el ataque si un último golpe madura dentro del enfriamiento.
8. Simplificar si la predicción no los defiende: `burstHold`, `soltar_aggro` con un solo creep.

**Paso 4. Mejoras decididas:** build y Take Aim (alcance, y con él vuelven los acosos que cayeron), apagar la rotación,
TP de vuelta tras fuente o muerte. Ya con `kill_eval`: prueba de kill propia (golpes por
daño real, Assassinate, aliados) en lugar de `GetEstimatedDamageToTarget`, que no es supervisable.

**Paso 5. Medir.** Prueba de ablación, combate encendido y apagado (4+4, propio). Después 8 partidas del propio frente a
la referencia de OHA.
- Máximo 3 vueltas.
- **Media ≥ −5 % en LH y muertes ≤ OHA:** confirmación.
- **Entre −5 % y −15 %, con el suelo cumplido y Pedro conforme:** fase 2, con la brecha anotada como defecto.
- **Peor de −15 %, o sin combate rinde claramente mejor y no se arregla:** cuestionar el diseño (orden de reglas, o
  adelantar el medio juego) y llevárselo a Pedro. OHA ya gana la línea y regala la ventaja después (MEDICIONES
  2026-11-02/03): empatarle en línea no ataca esa causa, solo es un suelo.

**Paso 6.** Pedro juega contra el Sniper (avisarle cuando esté listo). La confirmación pasa por la puerta de `bench/README.md` y su
análisis (`tools/analisis/serie-fase1.mjs`) se ajusta antes al listón decidido; su tamaño de ±5 LH quedó desfasado.

## Ya no se hace
Botella, Shrapnel para farmear (OHA lo excluye en línea), escenarios dentro del juego (alterar héroes ya cerró Dota).
Probar reglas fuera del juego con una foto simulada (Lua sobre Node, `fengari`) ahorraría 25 min por defecto de umbral,
pero toca el check: se propone si los humos cortos no bastan.
