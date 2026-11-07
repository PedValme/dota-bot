# Evaluación adversarial: qué y cómo mejorar (2026-11-06)

Encargo: DECISIONES 2026-11-06. Sin partidas nuevas. 196 partidas con Sniper y 159 completas del banco limpio, releídas desde
los registros. Dos revisores Opus independientes: uno recalculó los números sin conocer las conclusiones, otro atacó la ruta.
Scripts: `tools/analisis/evaluacion-2026-11-06/`. Se borra cuando Pedro decida y la ruta quede en `trabajo/bot-propio.md`.

## Qué se sostiene

### 1. Los equipos OHA no gastan su oro desde el 2026-10-31
- Oro sin gastar en el min 25: mediana 37 % (p5-p95: 22-51 %, n=172); antes, 5 %. Valve, 9 %. Ninguna partida posterior baja de 14,7 %.
- No es duración: mismo patrimonio (71k y 69k), objetos 67,5k a 43,6k. Cada héroe sube, de 2-9 % a 6-65 %.
- Compras de piezas de tienda secreta hasta el min 20: de 2-5 por partida a 0,0-0,5. Valve sigue en 1-7.
- Coincide con la ruta de compra Turbo activada en el banco (`item_purchase_generic.lua:1297`, #23). `base_sinturbo`, 4 %, pero n=1 y con S4.
- En las derrotas contra Valve, OHA va **+5.561 en patrimonio y −13.946 en objetos** (min 25). **Buena parte de la «ventaja regalada» eran monedas.**
- Causa: confirmada después con la sonda (MEDICIONES 2026-11-06): la compra devuelve 62, el stock siempre da 0 y la pieza se descarta en silencio (`:466-473`). Con la tienda universal, −1 en 11 de 11.
- **Abierto:** los lobbies de Pedro son Turbo real (`game_mode: 23`) y usan esa misma ruta; no registran el oro de los bots. Una fuente débil dice que allí
  las piezas secretas se compran en cualquier tienda. Si es así, es un defecto del banco; si no, también lo ve Pedro en sus aliados y rivales.

### 2. La brecha del Sniper propio no es de objetos
Con héroes fijos, frente a un equipo OHA, min 25 (`fijo-p2`+`p5`, n=12, contra `fijo-oha`, n=4; descriptivo):

| | Propio | OHA |
|---|---|---|
| Objetos | 21.594 | 15.400 (exacto en las 4; 42 % sin gastar) |
| Kills | 7,7 | 13,0 |
| Daño a héroes, min 12-25 | 14.629 | 21.822 |
| Daño recibido de héroes | 3.721 | 7.488 |
| Últimos golpes | 174,6 | 160,8 |
| Muertes | 1,25 | 1,5 |

Tiene un 40 % más en objetos y hace un 33 % menos de daño. Tiempo en `linea`+`a_neutrales`+`farmear`: 62-81 %. No tiene ninguna regla para pegar a torres.

### 3. El listón propuesto no sirve
- Patrimonio ≥ 95 % compara oro ocioso. Contra un OHA así, las kills y el daño de hoy son un suelo bajo.
- Bajo paridad real, con 8 frente a 4 partidas, las 5 filas se cumplen el **36 %** (cálculo corregido por el revisor). Con 8 frente a 8, 40 %; con 32 frente a 32, 48 %: «muertes ≤ OHA» es una moneda. Con la referencia congelada, de 1 % a 89 % según la tanda.
- Un mismo código dio 199 y 162 últimos golpes (exacto p=0,008 solo en esa métrica; Bonferroni ≈ 0,05). La carga no lo explica. Ruido o tanda no medida: no se separan.

### 4. El banco no anticipa la partida de Pedro
Min 25: 91-100 LH y 5-7 muertes contra un humano; 162 LH y 1,3 muertes en `fijo-p5`. En `lobby-202611060402`, 3 de las 5 primeras muertes ocurren en línea, antes del medio juego.

## Lo que el análisis propuso y no se sostuvo
- **«El pulido no movió nada»: retirado.** Con estas partidas, 12 vueltas solo detectarían ±120 LH o ±3,4 kills. El método no pudo verlo, en ningún sentido. El código sí importa en muertes (p<0,001: `fijo-p1`/`p3` ≈ 5,6; `p2`/`p5` 1,25).
- **«16 % de pasar el listón»: era 36 %** (suponía independencia; patrimonio y kills correlacionan 0,88).
- **«No camina a la tienda secreta» como causa:** el modo SECRET_SHOP casi no cambia; el fallo es de la ruta de compra.
- **«Objetos predice mejor que patrimonio»:** no robusto (correlación 0,92, cambia según variante). AUC 0,94, 0,92 y 0,75, pero dentro de un mismo bloque las kills igualan (0,926). Quedan ~10 min de partida: es un marcador, no una palanca.
- **«El propio hunde a sus aliados»: no demostrado.** Por héroes fijos, el juego `a` no difiere; toda la diferencia está en `b` (n=2 de OHA). Igual pasa con torres (+3,25 frente a +0,05, p=0,0016, concentrado en `b`) y con el daño por pelea atendida (selección posterior al tratamiento).

## Problemas nuevos sin resolver
- **El brazo OHA es un espejo del mismo código (`base_sniper-vs-base`) y aun así va +25,3k en 7 de 8.** Nunca hubo A contra A con `rival=dotabot`: el grupo con Sniper fijo tiene una ventaja sin medir y «paridad» no está definida.
- **Cerebro v3 y todo lo medido contra Valve desde el 2026-10-31** jugó con este fallo: la base gana 22 de 54 desde entonces (31 de 34 antes, con S4, así que no se comparan) y no vale de suelo. No demuestra que el rumbo fuera erróneo, porque su razón también es el control; es de Pedro.
- Asimetría de compras: si se arregla, OHA compraría al instante y el propio seguiría usando el mensajero (`compras.lua:164-167`, `:187-189`).
- La contaminación estaba a la vista desde el 2026-11-05 (MEDICIONES, «Oro sin gastar 476 frente a 8.967») y no se leyó como tal.

## Ruta propuesta (espera a Pedro)
1. **Banco.** Sonda de 2-3 min antes de la bocina: `ActionImmediate_PurchaseItem('item_point_booster')` con y sin `GameRules:SetUseUniversalShopMode(true)`, registrando el código (−1 o 62). Si no vale, quitar `IsImitatedTurbo` en `:1297`, solo en el banco. Compra directa en el propio. Fila en el protocolo: modo y compras secretas por partida. Registrar oro y objetos de todos en el lobby, para resolver el caso del Turbo real en su próxima partida. Revisión previa: es un control.
2. **Base nueva, una vez.** Puerta de medición; 8 partidas OHA contra OHA con etiquetas a/b (A contra A) y 4 del propio, unas 3 h. Tres enfrentamientos fijos: se añade uno con los que lo mataron en el lobby (Bloodseeker o Alchemist).
3. **Muertes contra humano, sin partidas.** Leer las 3 muertes en línea. Medir **exposición** (sin aliado a 1.400, fuera de torre propia, con ≥2 enemigos sin ver) en banco y lobbies. Si separa las muertes, es la métrica principal.
4. **Un paquete de macro: «con el equipo».** Tras la línea, su sitio es detrás del grupo, no la línea y los campamentos. Tránsito seguro: TP a más de 2.500, Blade, sin caminar con riesgo alto, histéresis y salida oculta si el grupo cae. Torres solo acompañado y desde rango máximo. Basado en posiciones, pasa a los cinco. Reordena `linea.lua:580-600`.
5. **Sin vueltas de umbrales.** Máximo 2 rondas de mecanismo; un `K` cambia solo por un fallo de regla visto en el registro. Dos métricas fijadas tras la base (candidatas: exposición y participación en kills). El paquete cierra al menos media brecha, o no se lee.
6. **Decide Pedro jugando,** con registro de todos los bots. Si no ve el cambio, se acaba el Sniper y se pasa a los cinco con cerebro propio.

Por qué esta ruta y no ir ya a los cinco: no toca lo que Pedro se queja ni el fallo del banco, y va contra DECISIONES 2026-11-05. Deuda: seguir a cuatro OHA hereda su macro; se acepta como puente, no como control completo.

## Decisión de Pedro
Aprobó la ruta, reemplazar el listón y mantener el rumbo (DECISIONES 2026-11-06). Avance: paso 1 hecho (tienda universal en el Turbo del banco, comprobada en cada partida; compra directa en el propio; oro de los aliados en el lobby).
