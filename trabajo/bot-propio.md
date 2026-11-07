# Bot propio: diseño propuesto (para la firma de Pedro)

Base: DECISIONES 2026-11-03 (control completo, supervisable al 100 %, de OHA solo datos); la prueba de control
(MEDICIONES 2026-11-03, «Prueba de control completo, humo»); `docs/api/` (la API de primera mano). Se borra cuando el
bot propio sustituya a OHA o Pedro lo descarte.

## Lo que ya sabemos
- El control completo funciona: con `Think()` propio el motor no actúa solo (0 ataques automáticos) y de OHA solo
  queda `ItemPurchaseThink`, que se neutraliza.
- Pensar cuesta 0,1 ms por bot y tick: hay margen de sobra.
- El Sniper propio, sin habilidades ni compras, saca en el min 10 el 67-80 % de los últimos golpes de OHA. Le falta:
  responder al acoso y usar sus habilidades, una regla de peligro que mire el alcance real del enemigo, y su build.

## Cómo es (igual para cada héroe)
1. **Percibir**: una foto por tick (la propia, creeps, héroes, torres, proyectiles), con los valores leídos en vivo
   del motor; lo de equipo, una vez por tick en `TeamThink`.
2. **Decidir**: reglas en orden, cada una devuelve intención, motivo y objetivo; la primera que aplica manda. Los
   umbrales en un solo sitio.
3. **Actuar**: una orden solo cuando cambia la intención; nunca se corta el amago de un ataque.
4. **Registrar**: cada decisión con su motivo (`[bench] prop`), aciertos y fallos de cada golpe, el coste de pensar.
   Se supervisa con el registro, el analizador fijo y los paneles `dota_bot_debug_*` de Valve.

## Fases (cada una se mide contra OHA y contra Valve antes de pasar a la siguiente)
1. **Línea completa con un héroe (Sniper).** Peligro por alcance real (distancia frente al rango y lanzamiento del
   enemigo, con margen para no ir y volver), responder al acoso cuando el intercambio sale a favor, sus habilidades
   (Shrapnel para últimos golpes y acoso, Assassinate para rematar), su build con mensajero (datos de Valve,
   `bot_loadouts.txt`). Meta: igualar a OHA en últimos golpes y patrimonio del min 10 en humo; después, una serie con
   su puerta de medición.
2. **Los cinco en línea**, con héroes de los 39 que Valve sabe llevar, una posición cada uno. Con los cinco propios el
   equipo deja de cargar los reemplazos de la API de OHA (`aba_global_overrides`): la API es la de Valve.
3. **Medio juego**: un cerebro de equipo propio con las reglas que el diagnóstico pide (tomar torres tras ganar una
   pelea, limpiar la oleada metida en casa, defender solo si es viable; ideas 1-4 de
   `docs/investigacion/2026-11-03-d2ai-tinkering.md`).
4. **Peleas y objetos activos.**

Hasta la fase 2, OHA juega el resto del equipo; en ningún momento el bot por defecto cambia sin la variante.

## Avance
- 2026-11-03: firmado («ok procede»). Fase 1 hecha en humo: 111 frente a 101 últimos golpes en el min 10 y el 96 % del
  patrimonio de OHA (MEDICIONES, «Fase 1 del bot propio, humo»). Falta la serie de la fase 1 (con la puerta de
  medición) antes de pasar a la fase 2. Huecos conocidos: Shrapnel no se usa para últimos golpes; las piezas de
  tienda secreta se saltan (sin compra con el mensajero en la tienda secreta); no persigue ni usa objetos activos.

- 2026-11-04: la cifra de arriba dependía de una pareja; revisión adversarial y plan de la siguiente vuelta en
  `trabajo/fase1-plan.md` (MEDICIONES, «Revisión adversarial de la fase 1»). La serie, aplazada (DECISIONES 2026-11-04).
  Pedro cambió ese día la meta de la fase 1 (suelo y paridad a −15 %, patrimonio informativo), la build (se aparta de
  Valve) y la confirmación (20 parejas): manda DECISIONES sobre lo escrito arriba.

- 2026-11-04: confirmación de la fase 1 aprobada en la línea (MEDICIONES, «Confirmación de la fase 1»): 59,4 últimos golpes
  frente a 55, IC95 +1,2 a +7,6. Falta la partida de Pedro. Defectos abiertos en ESTADO: runas y menos kills.

- 2026-11-05: línea de la fase 1 cerrada, con el rival de mid como deuda (12,1 LH frente a ≤ 11). **Orden cambiado por Pedro:** antes de los
  cinco en línea, el medio juego del Sniper (`bots/FunLib/propio/medio.lua`): gastar el oro, tienda secreta, Shadow Blade/Silver Edge,
  Force Staff/Hurricane Pike, y el criterio de riesgo, ataque y sigilo. Humos cortados en el min 25; su partida sigue decidiendo.

- 2026-11-06: tras la evaluación adversarial, Pedro aprueba la ruta de `trabajo/evaluacion-adversarial-2026-11-06.md`, que manda sobre el orden de arriba hasta cerrar el Sniper.

## Lo que pide la firma
- Este orden de fases y la meta de la fase 1.
- Que la fase 1 empiece ya, con Sniper, sin serie hasta igualar a OHA en humo.
