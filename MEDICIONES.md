# Mediciones

Una entrada por medición, añadida y nunca reescrita (reglas globales, «Measurements»). Se lee antes de medir: lo medido
no se repite. Cada entrada: fecha, pregunta, qué cambió desde la anterior, código y configuración, estado de la máquina,
resultado, validez (sesgos conocidos) y decisión. Datos por partida: `bench/series.csv` (antes del 2026-10-29,
`bench/partidas.csv`); cómo se mide: `bench/README.md`.

## Sesgos conocidos de las series antiguas
Las entradas hasta el 2026-10-31 se escribieron después, el 2026-10-31, desde los datos. Sufren sesgos que entonces no
se vieron, y por eso **ninguna sirve para elegir entre variantes**:
- **S1, sin courier:** nadie tenía courier hasta el 2026-10-29. Afecta a `oha-vs-valve-unfair` y `prueba-sonda`.
- **S2, el humano en Radiant:** el usuario podía quedar en Radiant con un héroe sin control. No se descartó antes del
  2026-10-29 (`partidas.csv`).
- **S3, la lógica Turbo de OHA apagada:** el custom game no es el modo 23, así que unos 12 interruptores Turbo de OHA
  no se activaban. Afecta a todas las series en Turbo hasta el 2026-10-31.
- **S4, Dire con héroes al azar:** Radiant jugaba los cinco sorteados y Dire, cinco al azar. Afecta a todas las series
  hasta `dire-ab` incluida y favorece a quien jugaba en Radiant.
- **S5, el espejo con fallos (`justa`):** Dire perdía los objetos iniciales, los guardianes y el humo; el héroe viejo
  seguía en el mapa; y Dota se cerró solo 3 veces en 12 partidas con espejo (antes del espejo, 1 vez en 126:
  `prueba-sonda`, 2026-10-29, causa desconocida).
- **S6, dota-bot jugando héroes del equipo de Valve:** el orquestador borraba el archivo de equipo al empezar la
  partida; un héroe que aparecía o se cambiaba después cargaba los scripts de dota-bot. Afecta a muchas partidas de
  todas las series: casi siempre el pid 1 de Radiant, que aparecía tarde, y desde el espejo también héroes de Dire
  (en `justa-3`, los cinco de Valve). Lo encontró el revisor adversarial del humo del 2026-10-31.
- **Filas contaminadas en `series.csv`:** muchas filas de series con estos sesgos dicen `valida=si`, porque la
  validez de entonces no los miraba. Esa columna solo vale desde el banco del 2026-10-31.
- **R, sin registro:** ninguna serie anterior anotó el commit; el estado de la máquina solo quedó por partida
  (`cpu_media`, `mem_libre`) desde el 2026-10-29.

## Entradas

### 2026-10-28 · `oha-vs-valve-unfair` (21 partidas, modo normal, Valve en Injusto)
- Pregunta: ¿juega OHA mejor que los bots de Valve?
- Resultado: dota-bot ganó 15 de 21.
- Validez: S1, S2, S4 y R. Contaminada.
- Decisión: adoptar OHA como base.

### 2026-10-29 · `empuje-ab` (24, normal; antes, `prueba-sonda`, 2)
- Pregunta: ¿gana más el cambio de empuje del PR #11?
- Cambió: el orquestador A/B intercalado y la validez por partida; los couriers llegaron en mitad del día.
- Resultado: base 11 de 12, empuje 9 de 12.
- Validez: S4 y R.
- Decisión: quitar el empuje del bot (DECISIONES 2026-10-29).

### 2026-10-30 · `mapa-prueba`, `mapa-turbo`, `mapa-modos`, `sonda-equipo`, `sonda-api` (9, Turbo imitado)
- Pregunta: reconocer cómo juegan los bots, para el mapa; no comparaban variantes.
- Resultado: docs/mapa.md.
- Validez: S3, S4 y R. Sirven como observación, no como comparación.

### 2026-10-30 · `remate-ab` (18, Turbo; antes, `remate-humo`, 2)
- Pregunta: ¿cierran antes las partidas `grupo` y `grupo_farm`?
- Resultado:
  - victorias: base 5 de 6, grupo 5 de 6, grupo_farm 4 de 6;
  - `grupo`: 4-5 bots empujando juntos el 34 % del tiempo, frente al 9 % de base, pero dejó caer la base yendo +18.000.
- Validez: S3, S4 y R.
- Decisión: no activarlo; pasar a una mejora grande, el cerebro (DECISIONES 2026-10-30).

### 2026-10-30 · `cerebro-ab` (24, Turbo; antes, `cerebro-humo` y `cerebro-humo2`, 4)
- Pregunta: ¿mejora el cerebro de equipo v1?
- Resultado:
  - victorias: base 11 de 12, cerebro 8 de 12;
  - cierre desde +10.000: cerebro unos 10 min, base unos 19;
  - el cerebro muere más.
- Validez: S3, S4 y R.
- Decisión: v2 y builds juntas (DECISIONES 2026-10-30).

### 2026-10-30/31 · `v2-ab` (15, Turbo, parada en la 16.ª; antes, `v2-humo`, 2)
- Pregunta: ¿mejoran el cerebro v2 y las builds con datos?
- Resultado: base 7 de 7 y cerebro_builds 5 de 8 contadas aquí. En el momento se resumió como «cerebro 10 de 10 en
  Radiant y 3 de 10 en Dire» sumando dos series.
- Validez: S3, S4 y R. La diferencia entre lados era S4, no un fallo de posición.
- Decisión: parar y arreglar Dire (DECISIONES 2026-10-31). La causa que se buscó era errónea.

### 2026-10-31 · `v2-dire`, `dire-fix`, `dire-aislar`, `dire-ab`, `turbo-oha` (25, Turbo, todo en Dire)
- Pregunta: ¿qué hace perder a dota-bot en Dire?
- Resultado:
  - `v2-dire`: 2 de 6;
  - `dire-ab`: base 0 de 3, cerebro_def 0 de 3;
  - bloques de 2 partidas por variante, sin poder para distinguir nada.
- Validez: S3, S4 y R. Medían S4 sin saberlo.
- Decisión: tras la insistencia de Pedro se encontró S4 y se hizo el espejo (`base-espejo`, 2 partidas, lo comprobó).

### 2026-10-31 · `justa` (8 de 12, Turbo, parada)
- Pregunta: base contra base_estado contra cerebro_def, con héroes espejo.
- Resultado: no se usa.
- Validez: S5 y R. Contaminada.
- Decisión: parar la serie, arreglar el espejo y crear la puerta de medición y los tres niveles (DECISIONES 2026-10-31).

### 2026-10-31 · `humo` (partidas de humo del banco nuevo)
- Pregunta: ¿cumple el banco la tabla del protocolo?
- Resultado:
  - 1.ª: el control de inicio miraba demasiado pronto;
  - 3.ª, con el commit `8b602799af26`: mismos héroes, patrimonio inicial 2.950 frente a 3.001, y Dota se cerró en el
    minuto 15 (S5: el héroe viejo).
- Validez: puerta del nivel 0, no comparación.
- Decisión: borrar el héroe viejo (commit `5d8bfb5`); repetir el humo y comprobar que Dota ya no se cierra antes de la
  serie A contra A.

### 2026-10-31 · `humo` con el banco fusionado (1 partida, commit `448f626`)
- Pregunta: puerta del nivel 0 antes de la serie A contra A.
- Máquina: CPU 38 %, memoria libre 50 %.
- Resultado:
  - terminó (35 min), sin crash;
  - espejo, borrado del héroe viejo, patrimonio inicial (2.977 frente a 3.026) y couriers (5 y 5 a 1.100), correctos.
- Validez, según el revisor adversarial:
  - **S6:** el Necrophos de Dire, que debía jugar Valve, lo jugó dota-bot;
  - el héroe del puesto 1 de Radiant apareció en t=+3;
  - la velocidad real fue ×2,28, no ×4, y varía con la carga de Lua.
- Decisión: no lanzar la serie A contra A.
  - Arreglos: el archivo de equipo se queda hasta el final, y la validez exige el observador, ningún héroe de Valve
    jugado por dota-bot y ningún héroe aparecido tras el inicio.
  - Prueba: añadir los bots un segundo después de sacar al humano.
  - Siguiente paso: repetir el humo con dota-bot en cada lado.

### 2026-10-31 · `humo` del reparto de héroes (13 partidas, commits `2b3de55` a `b3138c2` y siguiente)
- Pregunta: ¿cómo consiguen los dos equipos los héroes pedidos, sin que se cierre Dota?
- Resultado, medido:
  - si los dos equipos entran a la vez, el primero recibe sus héroes y el segundo, unos al azar que nunca coinciden
    con los del primero (0 de 112 partidas): el motor no repite héroe entre equipos;
  - con 30 s de selección pasa lo mismo, y un equipo que entra 1 s después no recibe ninguno;
  - el primer bot añadido aparece de 15 a 50 s después que los demás; con 90 s de fase previa llegan todos antes del
    inicio;
  - cambiar los héroes de Dire (`ReplaceHeroWith`) cerró Dota en 5 de 16 partidas, y crearlos (`CreateHeroForPlayer`)
    también lo cerró, además de que el motor no los cuenta como héroes de sus jugadores;
  - con dos sorteos sin héroes en común, cada equipo recibió el suyo y no hubo cierres (2 de 2).
- Validez: puerta del nivel 0, no comparación.
- Decisión: mismo enfrentamiento en los dos lados en lugar de mismos héroes (DECISIONES 2026-10-31); se quitan el
  espejo y la creación de héroes.

### 2026-10-31 · `humo` del banco final (2 partidas, rama `claude/banco-s6`, PR #24)
- Pregunta: puerta del nivel 0; ¿pasan todos los controles con dota-bot en cada lado?
- Resultado: 2 de 2 válidas (43 y 29 min, sin cierres); cada equipo con su grupo, todos los héroes antes del inicio,
  ningún héroe de Valve jugado por dota-bot, couriers Turbo y patrimonio inicial parejo. Antes, dos partidas
  invalidadas por el propio control de código al tocar el orquestador y hacer un commit durante la serie (corregido:
  se comparan los árboles de `bots/` y `tools/bench/`).
- Decisión: pasar a la serie A contra A.

### 2026-10-31 · `aa` (serie A contra A, nivel 0) — pregunta escrita antes de lanzarla
- Pregunta: con dos versiones idénticas, ¿cuánto se separan por azar (el ruido) y cuánto gana el lado del mapa por sí
  solo? Sin eso, ninguna diferencia entre variantes se puede leer.
- Qué cambió desde la anterior: nada en el bot; primera serie con el banco completo (PR #24).
- Configuración: `--variantes base,base_b --partidas 12 --modo turbo`, sin observador, Valve en Injusto, ×4. Bloques de
  4 (cada variante en los dos lados, mismo enfrentamiento), 3 bloques.
- Métricas, fijadas antes: victorias por brazo; victorias de dota-bot en Radiant frente a Dire; minutos de partida y
  minuto de +10.000 hasta el final, con su dispersión por brazo; partidas inválidas y topes.
- Qué se espera: brazos parecidos. Una diferencia grande entre brazos idénticos mide el ruido que tendrá cualquier
  comparación de 12 partidas.
- Sin comprobar que puede pesar: la velocidad real variable (×1,6 a ×3,4); la lista de héroes del sorteo, recordada.

### 2026-11-01 · `aa` — resultado (11 de 12 jugadas, parada sola por >20 % inválidas)
- Máquina: libre en las partidas 1-3 (CPU media 32-46 %); saturada en las 4-11 (76-98 %, Unreal, python y sumo;
  Pedro decidió seguir, DECISIONES 2026-10-31). Código `349e8da` (árboles iguales en toda la serie).
- Inválidas: 3 (partidas 7, 10 y 11), todas por patrimonio inicial con ~850 de diferencia, y las tres con una baja
  antes del inicio (minuto 0 con kills); las 8 válidas, ninguna. Es juego, no sesgo: el control se corrige (rama
  `claude/banco-nw`).
- Resultado de las 8 válidas:

  | Métrica | base (5) | base_b (3) | Juntas (8) |
  |---|---|---|---|
  | dota-bot ganó | 3 | 2 | 5 de 8 |
  | Minutos de partida | 38, 40, 31, 31, 31 | 29, 35, 22 | media 32 |
  | Minuto en que llegó a +10.000 | 10, 12, 8, 12, 11 | 9, 11, 10 | media 10,4 (dispersión ~1,4) |

  - Lado: dota-bot ganó 3 de 4 en Radiant y 2 de 4 en Dire; Radiant ganó 5 de 8 partidas.
  - Carga: con la máquina libre, 2 de 3; con la máquina saturada, 3 de 5. Duración media 35,7 frente a 30 min.
    Con estos números ninguna diferencia se distingue del azar.
- Lectura:
  - los dos brazos idénticos quedan en 3 de 5 y 2 de 3: compatibles con ninguna diferencia, como debe ser;
  - **el porcentaje de victorias es demasiado ruidoso para el nivel 2**: con victorias en torno al 60 %, distinguir
    20 puntos entre dos variantes pide del orden de 90 partidas por brazo (unas 50 horas);
  - el minuto en que se llega a +10.000 varía poco (~1,4 min): es una métrica mucho más sensible, igual que el tiempo
    de cierre desde +10.000;
  - ni el lado ni la carga muestran efecto con 8 partidas; no se descarta uno pequeño.
- Decisión: corregir el control de patrimonio inicial; para el nivel 2, métricas principales sensibles (minuto de
  +10.000, cierre desde +10.000, ventaja máxima, muertes) con victorias como métrica secundaria. Tamaño y pregunta, en
  su entrada antes de lanzar.

### 2026-11-01 · `humo-n1` (nivel 1, variante `nivel1`, 2 partidas con observador, commit `39f4b1d`)
- Pregunta: ¿se mueven las métricas de los dos arreglos (filtro de ultis y defensa de T1/T2) sin romper nada?
- Máquina: CPU 15-23 %, memoria libre 54 %.
- Resultado:
  - variante aplicada en las dos (`filtro_ultis=true defensa_t12=true` en el log), ningún `ult_gate error`;
  - ultis de dota-bot: 40, ninguna sin un enemigo a 1.200 (antes, el 10 %); el filtro no tuvo que rechazar ninguna
    con estos héroes (Chaos Knight, Necrophos, Kunkka, Lion, Witch Doctor), así que el rechazo y que el héroe no se
    quede quieto **siguen sin comprobarse en partida**;
  - defensa: 45 y 51 decisiones; con 1-2 atacantes y aliados a tiempo, «defiende», y los elegidos pasan a
    `DEFEND_TOWER_*` con deseo 0,95; cuando los defensores mueren y no llegan bastantes, «concede». Las torres que
    cayeron sin defensores cayeron tras peleas perdidas, no por abandono;
  - las dos partidas las ganó Valve (2 partidas no dicen nada).
- Validez: puerta del nivel 1, no comparación.
- Decisión: el nivel 1 pasa; el rechazo de ultis se comprobará cuando salgan héroes con ultis de riesgo (Skywrath,
  DK). Fusionar y pasar al nivel 2.

### 2026-11-01 · `n2-nivel1` (nivel 2: `nivel1` frente a `base`) — pregunta escrita antes de lanzarla
- Pregunta: ¿juega mejor dota-bot con el filtro de ultis y la defensa de T1/T2 que sin ellos?
- Qué cambió: el nivel 1 (#26); el banco, solo el control de patrimonio inicial (#25), comprobado sobre los datos de
  `aa`.
- Configuración: `--variantes nivel1,base --partidas 16 --modo turbo --observar`, Valve en Injusto, ×4; 4 bloques de 4
  (cada variante en los dos lados, mismo enfrentamiento). El observador va en los dos brazos por igual.
- Tamaño: 16 partidas, unas 8 horas. Con la dispersión de `aa` (~1,4 min en el minuto de +10.000), 8 por brazo
  distinguen unos 2 min de diferencia; en victorias solo una diferencia enorme.
- Métricas, fijadas antes:
  - principales, del mecanismo: torres T1/T2 perdidas sin defensores ante 1-2 atacantes, por partida; ultis de dota-bot
    sin enemigos a 1.200; muertes de dota-bot por 10 min;
  - principales, de resultado: minuto de +10.000, cierre desde +10.000, ventaja máxima;
  - secundaria: victorias.
- Análisis fijo: por brazo, solo partidas válidas de bloques completos; sin cortar por lado o héroe después.
- Sin comprobar que puede pesar: velocidad real variable; lista de héroes del sorteo.

### 2026-11-01 · `n2-nivel1` — resultado (16 de 16 jugadas)
- Máquina: CPU media 32-59 % (Dota incluido); código `6632fb7`.
- Inválidas: 2 (partidas 5 y 12, las dos de `base`), por patrimonio inicial con una baja antes del inicio: una valió
  955 (más que los 650 supuestos) y otra ocurrió justo después de la foto del patrimonio. Falsos rechazos; el control
  se corrige (margen de 0 a 1.100 por baja, hacia el bando que mata). Con eso, solo 2 bloques completos de 4.
- Resultado, regla fijada (bloques 1 y 4, 4 partidas por brazo):

  | Métrica | nivel1 | base |
  |---|---|---|
  | Ganó | 1 de 4 | 2 de 4 (1 tope) |
  | Llegó a +10.000 | 3 de 4, minuto medio 16 | 4 de 4, minuto medio 12,5 |
  | Ventaja máxima media | 18.566 | 62.382 |
  | Muertes de dota-bot por 10 min | 9,1 | 5,0 |
  | Ultis sin enemigo a 1.200 | 9 de 101 | 12 de 220 |
  | T1/T2 perdidas sin defensa ante 1-2 atacantes | 2 | 1 |

- Sensibilidad (las 16, marcado aparte, no es la regla fijada): nivel1 ganó 2 de 8 y base 2 de 8 (2 topes con +94.000
  y +52.000 sin cerrar); muertes por 10 min 9,4 frente a 7,0; T1/T2 perdidas sin defensa ante 1-2: 5 frente a 2.
- Mecanismo:
  - el filtro rechazó 1 ulti en 16 partidas: las ultis sin enemigo de `base` (8 %) eran casi todas legítimas; con
    estos héroes apenas había qué filtrar;
  - la defensa decidió (25-44 veces por partida) pero no redujo las torres perdidas sin defensa;
  - las muertes por partida son iguales (252 frente a 255): la tasa por minuto sube en `nivel1` porque sus derrotas
    fueron más cortas, no por morir defendiendo (9 muertes en modo defensa frente a 4);
  - **dos tercios de las muertes de dota-bot ocurren en modo RETIRADA** (172 de 252 y 170 de 255, en los dos brazos).
- Lectura: no hay señal de que `nivel1` mejore; los indicadores van en contra o empatan, con mucho ruido (4 partidas
  por brazo). `base` llegó dos veces al tope con ventajas enormes sin cerrar.
- Decisión: `nivel1` no se activa. Lo que los datos señalan como palancas de verdad: la retirada (dos tercios de las
  muertes) y el cierre con ventaja grande (el punto dulce del empuje).

### 2026-11-01 · `humo-pd` (humo del punto dulce, 4 partidas con observador, commit `f74e25b`)
- Resultado: 4 de 4 válidas; el empuje en grupo se activa (4 o más bots empujando juntos en 33 y 91 momentos con
  `grupo_5k`; 17 con `grupo_15k` en la partida que llegó a esa ventaja, 0 en la que no). Valve ganó las 4 (mismo
  sorteo en las 4; no dice nada).

### 2026-11-01 · `n2-pd` (nivel 2: punto dulce del empuje) — pregunta escrita antes de lanzarla
- Pregunta: ¿desde qué ventaja conviene que los cinco empujen juntos una línea: nunca (`base`), desde +5.000
  (`grupo_5k`) o desde +15.000 (`grupo_15k`)?
- Qué cambió: el umbral parametrizado (#30); el banco, el margen por bajas antes del inicio (#29).
- Configuración: `--variantes base,grupo_5k,grupo_15k --partidas 24 --modo turbo --observar`, Valve en Injusto, ×4;
  4 bloques de 6 (cada variante en los dos lados, mismo enfrentamiento).
- Tamaño: 24 partidas, unas 12 horas; 8 por brazo.
- Métricas, fijadas antes:
  - principales: cierre desde +10.000 (minutos desde que se llega a +10.000 hasta ganar), partidas que llegan al tope,
    derrotas tras haber ido +10.000, ventaja máxima, y momentos con 4-5 bots empujando juntos;
  - secundaria: victorias.
- Cómo leerlo (de la revisión): la ventaja que usan los bots es su estimación por objetos visibles, no la real de GSI;
  entre +6.000 y +15.000, `grupo_15k` juega como `base` sin farmear (regla de OHA). Compara «empujar en grupo desde
  +5.000» con «esperar a +15.000».
- Análisis fijo: por brazo, solo partidas válidas de bloques completos; las 24 aparte como sensibilidad.
- Sin comprobar que puede pesar: velocidad real variable; lista de héroes del sorteo.

### 2026-11-01 · `n2-pd` — resultado (24 de 24 jugadas)
- Máquina: CPU media 27-59 % (Dota incluido); código `ceea03e`.
- Inválidas: 1 (partida 17, `grupo_5k`): un héroe apareció 7 s después del inicio pese a los 90 s de fase previa. El
  control lo detectó; el bloque 3 queda fuera del análisis principal.
- Resultado, regla fijada (bloques 1, 2 y 4; 6 partidas por brazo):

  | Métrica | base | grupo_5k | grupo_15k |
  |---|---|---|---|
  | Ganó | 3 | 1 | 1 |
  | Llegó a +10.000 | 6 | 5 | 4 |
  | Perdió tras ir +10.000 | 3 | 4 | 3 |
  | Cierre desde +10.000 en las ganadas (min) | 22, 9, 37 | 19 | 12 |
  | Topes | 0 | 0 | 0 |
  | Ventaja máxima media | 35.916 | 30.880 | 22.921 |
  | Momentos con 4-5 empujando, media | 42 | 51 | 71 |

- Sensibilidad (todas las válidas): base 4 de 8, grupo_5k 2 de 7, grupo_15k 2 de 8; perdió tras +10.000: 4, 4 y 3.
- Lectura:
  - el empuje en grupo se activa (más momentos con 4-5 empujando) pero **no hay señal de que ayude**: los dos brazos
    de grupo ganan menos que `base`, con tamaños muy pequeños (6 por brazo), así que tampoco se puede afirmar que
    empeore;
  - el cierre en las ganadas parece más rápido con grupo (12-19 min frente a 9-37), pero con 1 partida ganada por brazo
    no dice nada;
  - **el problema de fondo no es el umbral: dota-bot pierde la mitad de las partidas en las que llega a ir +10.000**
    (10 de 15 en los brazos de la regla fijada). Junto con que dos tercios de sus muertes son en retirada y casi todas
    en los primeros 4 s, la palanca está en no regalar las ventajas, no en cuándo empujar.
- Decisión: no se elige umbral; el punto dulce queda sin respuesta con este tamaño. Prioridad a la retirada (nivel 1,
  DECISIONES 2026-11-01).

### 2026-11-01 · Retirada, nivel 1: `humo-ret`, `humo-rt`, `humo-rt2` (2 partidas cada uno, con observador)
- Pregunta: ¿cuándo debió huir cada bot que murió, y adelanta la huida la variante `retirada_temprana`?
- `humo-ret` (sin variante, registro nuevo de vida y amenaza = daño enemigo estimado en 5 s / vida): las 14 muertes
  tuvieron amenaza ≥ 1 entre 1 y 10 s antes (la mitad, 7 s o más); en ese momento 6 seguían atacando. Lectura previa
  con 714 muertes de series anteriores: el 70 % de las muertes en retirada ocurre en los primeros 4 s.
- `humo-rt` (v1: amenaza ≥ 1,5 y más enemigos que aliados o vida < 50 %): no adelantó la huida (mediana 4 s desde la
  amenaza ≥ 1 hasta huir, igual que sin variante) y 9 héroes murieron sin huir. No pasa la puerta.
- `humo-rt2` (v2: amenaza ≥ 1,0; también con igualdad si recibe daño de héroes y tiene < 60 %; se mantiene 2,5 s):
  la regla se disparó 90 veces, sin errores; mediana 2 s desde la amenaza ≥ 1 hasta huir, ninguna muerte sin haber
  huido, solo 5 casos de amenaza ≥ 1 sin huir antes de morir. Sigue igual la proporción de muertes en los 2 primeros
  segundos de huida (44 %): parte de los héroes está condenada aunque huya antes.
- Validez: puerta del nivel 1, no comparación (los sorteos cambian mucho las muertes: 14, 71 y 18 en cada par).
- Decisión: la v2 pasa la puerta; serie `retirada_temprana` frente a `base`, con su pregunta antes.

### 2026-11-01 · `n2-rt` (nivel 2: `retirada_temprana` frente a `base`) — pregunta escrita antes de lanzarla
- Pregunta: ¿muere menos dota-bot y regala menos ventajas si huye cuando los enemigos cercanos pueden matarlo?
- Qué cambió: la variante (#36, v2 con la huida que se renueva); el banco, nada desde `n2-pd`.
- Configuración: `--variantes retirada_temprana,base --partidas 16 --modo turbo --observar`, Valve en Injusto, ×4;
  4 bloques de 4.
- Tamaño: 16 partidas, unas 8 horas; 8 por brazo.
- Métricas, fijadas antes:
  - principales: muertes de dota-bot por partida; derrotas tras haber ido +10.000; ventaja máxima; muertes en
    retirada en los 2 primeros segundos de huida;
  - secundarias: victorias, minuto de +10.000.
- Análisis fijo: por brazo, solo partidas válidas de bloques completos; todas las válidas aparte como sensibilidad.
- Cómo leerlo (de las revisiones): con 4 contra 3 o más, héroes sanos pueden salir de la pelea si la amenaza sumada
  pasa de 1; el ATTACK de OHA a 0,95 (objetivo a punto de caer) sigue ganando a la huida, a propósito.

### 2026-11-01 · `n2-rt` — cortada en la partida 7 de 16
- Pedro decidió cortarla al terminar la partida en curso para pasar al cerebro v3 (DECISIONES 2026-11-01). Jugadas 7,
  las 7 válidas, con la máquina cargada en parte (CPU media 29-85 %).
- Sin conclusión: menos de dos bloques completos. Los datos (`series.csv`, `lineas/`, `observaciones/n2-rt-*`) quedan
  para la capa 2 del cerebro v3 (retirada).

### 2026-11-02 · `v3-partida0` (cerebro v3, partida 0: qué responde la API sobre los enemigos)
- Pregunta: ¿qué funciones de la API dan datos de héroes enemigos, se puede prohibir el ataque con `GetDesire` y
  devolverlo a Valve con `nil`, y sigue el farm pasado el min 18 sin el corte de OHA?
- Qué cambió: variante `sonda_api` (`FunLib/api_probe.lua`, gancho en `mode_attack_generic.lua`, `farm_sin_reloj`).
- Configuración: `--variantes sonda_api --partidas 2 --modo turbo --observar`, Valve en Injusto, ×4; código
  `f1b9d61d95bb`; CPU de la máquina al 81 % al lanzar (mecanismo, no tiempos).
- Resultado (líneas `[bench] api` de las dos partidas):
  - **`nil` en `GetDesire` del ataque NO cae en el deseo de Valve: vale 0.** Ningún bot entró en ATTACK en toda la
    partida (0 de ~5.000 registros de modo; 580 en `n2-rt` #7). La referencia de la API (línea 51) está mal. Las dos
    partidas se perdieron por eso: no cuentan para nada más. El ataque de Valve pide casi siempre 0,95 (383 de 497 en
    `n2-rt` #7): el plan «prohíbe» atacar dando a otro modo más de 0,95, no anulando el ataque.
  - Ulti enemiga: `GetCooldown` y `GetCooldownTimeRemaining` dan -1; **`IsFullyCastable` sí responde** (pasa a
    falso tras verla lanzar: Lich a los 273 s, falso a los 285 s). `GetCurrentActiveAbility` e `IsUltimate` en
    enemigos funcionan (lanzamientos de ulti vistos).
  - `GetModifierSourceAbility` no existe (error en cada llamada); `NumModifiers`/`GetModifierName`/
    `GetModifierRemainingDuration` se llaman sin error (su valor ya se usaba en `J.GetDisableRemaining`).
  - TP: `GetIncomingTeleports` lista también los de enemigos (con `playerid`).
  - Reaparición: un enemigo muerto no está en `GetUnitList`, así que `GetRespawnTime` no se puede pedir; se estima.
  - `GetHeroLastSeenInfo` devuelve una lista (`info[1].location`), como la usa OHA, no la tabla de la referencia.
  - Farm después del min 18: 14 % y 12 % de los registros en FARM, como en `n2-rt` (11 % y 17 %); sin conclusión,
    porque sin ataque la partida no es normal y quedan otras puertas de OHA (`IsTimeToFarm`). Lo comprueba la capa 3
    con sus líneas `[bench] farm`.
- Validez: partida de mecanismo, no comparación.
- Decisión: el gancho del ataque se quita; la capa 4 forma e inicia con deseos de otros modos por encima de 0,95. La
  capa 1 usa `IsFullyCastable` de la ulti enemiga visible y cuenta los TP enemigos hacia la pelea.

### 2026-11-02 · `v3-sombra` (cerebro v3, capas observadas con la evaluación de la capa 1 en sombra)
- Pregunta: ¿actúa cada capa en partida (farm, glifo, recompra, fases) y separa la evaluación de pelea las peleas
  ganadas de las perdidas, para fijar sus umbrales?
- Qué cambió: variante `cerebro_v3_sombra`, código `4959dd1` (antes de los arreglos de la capa 4 de la segunda
  revisión: la capa 4 de estas partidas no vale para juzgarla).
- Configuración: `--variantes cerebro_v3_sombra --partidas 2 --modo turbo --observar`; Valve en Injusto, ×4.
- Resultado: 1 de 2 (gana como Dire). Sin `plan error`. Capa 5: 2 glifos (T3 al 38 % con 2 héroes, cuartel al 33 % con
  3) y 3 recompras para la base. Capa 3: líneas `[bench] farm` de los núcleos con el objeto que les falta (`farm=true`
  todo el tiempo: «falta» cuenta el objeto entero, componentes comprados o no). Capa 1, 106 peleas, valor al empezar
  frente a muertes en 10 s a 2.500: con ≥ 1,6, 10 ganadas y 1 perdida (41 peleas); con < 0,5, 2 ganadas y 1 perdida
  (24); entre 0,5 y 1,6, 2 y 2 (41, casi todas sin muertes). Coincide con «somos más fuertes» de OHA en el 68 % de
  las decisiones (2.752 iguales, 1.319 distintas, por segundo y bot).
- Validez: mecanismo, no comparación; dos partidas cortas (11 min reales).
- Decisión: los umbrales 1,1 y 0,8 se quedan (la franja media no tiene datos para moverlos); partida activa por lado
  con la capa 4 arreglada (`v3-activo`).

### 2026-11-02 · `n3-v3` (serie final única: `cerebro_v3` frente a `base`) — pregunta escrita antes de lanzarla
- Pregunta: ¿gana más dota-bot con el cerebro v3 completo (paquete firmado: v2, `builds`, `defensa_total`,
  `fase_estado`, `retirada_temprana`, `farm_sin_reloj` y las 5 capas) que con `base`? Firmada por Pedro (DECISIONES
  2026-11-01).
- Qué cambió: todo el cerebro v3; el banco, `--repetir-invalidas` (una partida inválida se repite con los mismos
  héroes, lado y variante).
- Configuración: `--variantes cerebro_v3,base --modo turbo --repetir-invalidas 2`, Valve en Injusto, ×4, sin
  `--observar` salvo la primera tanda (para el registro de mecanismo); en tandas de bloques de 4, cada tanda con su
  etiqueta (`n3-v3-a`, `n3-v3-b`…: el orquestador numera las partidas desde 1 en cada ejecución).
- Tamaño: secuencial, máximo 40 por brazo (80 partidas, unas 40 h); miradas a 16 y 28 por brazo.
- Métrica principal: victorias (un tope de 60 min cuenta como no ganada).
- Análisis fijo: por bloques (mismo sorteo en los dos brazos), Cochran-Mantel-Haenszel a una cola sobre bloques
  completos y válidos (con repeticiones). Fronteras Lan-DeMets tipo O'Brien-Fleming, α = 0,05 a una cola (calculadas
  con 400.000 simulaciones): z ≥ 2,81 a 16 por brazo, ≥ 2,04 a 28, ≥ 1,70 a 40 (p nominal 0,0025, 0,0205, 0,044).
  Parada por inutilidad, no vinculante, en la mirada de 28 si v3 no gana más que `base` (z ≤ 0).
- Secundarias de mecanismo, fijadas antes: patrimonio por minuto de dota-bot menos el de Valve en el min 18-26;
  estructuras propias perdidas yendo por encima de +5.000; torres enemigas en pie al llegar a +10.000; derrotas tras
  +10.000; muertes por partida; inválidas por brazo (una asimetría ahí es contaminación y para la serie).
- Lo que vale la conclusión: para el paquete entero, no para cada capa.
- Completado tras la revisión adversarial de la medición (2026-11-02), antes de lanzarla:
  - Tandas: `n3-v3-a` de 32 partidas (8 bloques, con `--observar`), `n3-v3-b` y `n3-v3-c` de 24 (6 bloques), sin
    observar. Cada mirada es por bloques completos y válidos, con clave (etiqueta, bloque): 8, 14 y 20 bloques. Si
    faltan bloques, se juega otra tanda corta hasta llegar; si una mirada no cae justa, la frontera se recalcula con
    la misma función de gasto en la fracción real.
  - Todas las filas `n3-v3-*` deben tener los mismos árboles de `bots/` y `tools/bench/` (el commit de la tanda a) y
    la misma `dota_version`; si no, la serie para. Se lanza desde el clon principal (las junctions de Dota apuntan
    ahí) con el commit en `HEAD`.
  - Inválidas: la serie para e investiga si `cerebro_v3` tiene más `sin final` que `base`, o si un brazo tiene 3
    inválidas más que el otro (todas las filas, repetidas incluidas).
  - Llamadas a Think por segundo de juego (`[bench] think`, solo con observador, una línea por bot y minuto): se
    comparan entre brazos en la tanda a. Si v3 piensa claramente menos (más de un 10 % por debajo de `base`), la
    serie para: el banco a ×4 lo castigaría por un artefacto.
  - Análisis con `tools/analisis/n3-v3.mjs <mirada>` (fuera de `tools/bench/`, que entra en la comprobación de
    código). Secundaria con prueba fijada: patrimonio por minuto en el min 18-26, diferencia por bloque, prueba de
    signos; el resto de secundarias se describen, sin prueba.
  - Potencia (simulación del revisor, 40.000 series): α real ≈ 0,05; frente a `base` ≈ 50 %: +10 puntos ≈ 20 %, +20 ≈
    50-55 %, +30 ≈ 85 %. La mirada de 16 casi nunca para por eficacia (4 % con +20); la inutilidad a 28 para el 55 %
    de las series sin efecto.
  - Máquina medida antes de cada tanda (regla global); con carga, no se lanza sin el sí de Pedro. Tanda a: CPU 24 %,
    memoria libre 54 %.
  - Parada por perjuicio, no vinculante, en la primera mirada: z ≤ −1 corta la serie (Pedro, DECISIONES 2026-11-02;
    añadida con la tanda a en curso, antes de mirar sus victorias).
  - Sin comprobar: el Turbo imitado no es el Turbo real (torres y runas normales); el primer bot aparece tarde
    (lo rechaza la validez); la velocidad real varía (×1,6-3,4) sin saber si distinto por lado; la lista de héroes del
    sorteo es recordada, no de `BotImplemented`.

### 2026-11-02 · Humo del cerebro v3 activo (`v3-activo`, `v3-humo`, `v3-humo2`)
- Pregunta: puerta de medición (DECISIONES 2026-10-31): ¿son válidas las partidas con `cerebro_v3`, actúa cada capa y
  sale el plan sin errores?
- `v3-activo` (código `6a0b8c2`, 2 partidas, 0 ganadas): 34 `plan error` (`J.IsInLaningPhase` lee `GetBot()`, nil en el
  cerebro de equipo; con cada error el plan se apagaba 10 s). No vale como humo. Arreglo `57f4219`.
- `v3-humo` (`57f4219`, 2 partidas, 0 ganadas): sin errores del plan; todas las capas actúan (fases 6+15 FORMAR,
  52+86 INICIAR; glifos, recompras para la base, retiradas v3). Pero en las 6 partidas con v3 hasta aquí ganó 1, y en
  dos fue +20.000 y +29.000 y perdió. Causa leída en el plan: los umbrales relativos con suelos de 3.000/6.000 metían a
  los cinco en CERRAR en el minuto 10 con +9.400 y los tenían agrupados del min 9 al 20 con el farm de los núcleos
  prohibido: faltaba la alternancia ASALTO/PREPARAR del plan firmado. Arreglo `9284050`: asaltos de 60 s y 45 s de
  preparar (farm), umbrales nunca por debajo de los de v2 (+5.000, +10.000).
- `v3-humo2` (`9284050`, 2 partidas, 2 ganadas): válidas, sin errores del plan, 3 y 5 fases de preparar.
- Validez: humo, no comparación; las victorias de estas partidas no cuentan para nada.
- Decisión: el humo pasa con `9284050`; revisor adversarial de la medición antes de lanzar `n3-v3`.

### 2026-11-02 · `n3-v3`, primera mirada (tanda `n3-v3-a`, 8 bloques)
- Resultado: `cerebro_v3` 8 de 16, `base` 8 de 16; CMH z = 0,00. Ni eficacia (z ≥ 2,81) ni perjuicio (z ≤ −1): la
  serie sigue. Sin inválidas (0 y 0). Think igual en los dos brazos (~30 llamadas por segundo de juego).
- Descriptivo, sin prueba: llegó a +10.000 en 11 (v3) y 14 (`base`) partidas, y perdió tras ir +10.000 en 3 y 6;
  minutos medios 32,5 y 35,7. Secundaria fijada (patrimonio por minuto, min 18-26, por bloque): v3 mejor en 3, peor
  en 4.
- Decisión: tandas `n3-v3-b` y `n3-v3-c` (24 partidas cada una, sin observar), mismo commit `1162c9c`. Máquina antes
  de la tanda b: CPU 27 %, memoria libre 53 %.

### 2026-11-02 · `n3-v3` cortada tras la primera mirada; relanzada como `n3-v3r`
- Pedro cortó la serie (DECISIONES 2026-11-02) tras la primera mirada (8-8) y la partida 1 de la tanda b, que no
  cuentan para la serie relanzada. Causa, leída en la tanda a observada (16 partidas por brazo), en la fase de líneas:
  - ventaja media en el min 5, 10 y 18: v3 +1.100, +5.000 y +7.200; `base` +2.100, +7.100 y +13.500; kills en el
    min 5: 1,2 frente a 2,6;
  - la retirada v3 (0,97) se disparó 739 veces antes del min 10 (unas 46 por partida); el plan mandó a objetivos
    de equipo 63 veces y hubo 473 entradas en INICIAR antes del min 10.
- Arreglo (`646e767`, `f447404`, revisados por Opus): en la fase de líneas (hasta que el nivel medio de los diez llega a
  9,2 o cae una T1) v3 no actúa: sin retirada temprana, plan en LINEA salvo defender la base, sin fases de pelea salvo
  contrainiciación, y «somos más fuertes» de OHA.
- Humo `v3-humo3` (`646e767`, 1 bloque observado, v3 contra `base`): antes del min 10, retirada temprana 1,5 por
  partida; modos de línea como `base`; ventaja en el min 5 +3.400 y +3.400, en el min 10 +8.400 y +9.200. Mecanismo,
  no comparación. Queda, después de las líneas, menos farm en v3 (7 % frente a 16 % en el min 10-18): es el diseño de
  asaltos firmado y lo mide la serie.
- Relanzamiento `n3-v3r`: mismo diseño, fronteras, paradas (eficacia, perjuicio a 16, inutilidad a 28), umbral de
  inválidas y análisis (`tools/analisis/n3-v3.mjs <mirada>`, prefijo `n3-v3r-`). Tandas `n3-v3r-a` (32, observada),
  `-b` y `-c` (24). Código `f447404` (con humo `v3-humo4` antes).
- Humo `v3-humo4` (código de `f447404`, árbol `9c6b553.2e6ca87`, 1 partida por lado): las 2 válidas, sin errores del
  plan, líneas `[bench] think` presentes. Pasa.
- Tanda `n3-v3r-a` lanzada el 2026-11-02 con la máquina cargada (una pestaña de Chrome al 96 % de un núcleo; CPU total
  23-65 %), con el sí de Pedro (DECISIONES 2026-11-02); la carga va por partida en `series.csv` y el Think se compara
  entre brazos en esta tanda.

### 2026-11-02 · Diagnóstico de la fase de líneas: dota-bot (OHA en líneas) frente a Valve, sin partidas nuevas
- Pregunta (Pedro: «¿no tenemos una métrica de todo lo que sacamos que nos permita tomar decisiones útiles para la fase
  de líneas?»): ¿dónde pierde o gana dota-bot frente a Valve hasta el min 10, para decidir si hace falta una capa de
  líneas?
- Datos: registros observados ya existentes, 18 partidas válidas en las que dota-bot juega las líneas como OHA
  (`n3-v3-a` brazo `base` y `n3-v3r-a` hasta ese momento); mismos héroes por bloque en los dos lados. Rol aproximado
  por patrimonio en el min 10 dentro del equipo (r1 = el más rico); mid = el más cercano a la diagonal en el min 2-5.
  Script: `scratchpad/lanes.mjs` de la sesión (lectura).
- Resultado, dota-bot frente a Valve, medias por partida en el min 10:
  - patrimonio del equipo 25.200 frente a 17.500 (+44 %); kills 9,7 frente a 6,2; muertes 6,5 frente a 9,7;
  - últimos golpes por rol (r1-r5): 48/35/31/17/13 frente a 21/20/12/14/6 (más del doble en los núcleos);
  - el mid de Valve pasa el 49 % del tiempo fuera de su línea desde el nivel 6 (el de dota-bot, el 9 %), pero mata
    menos (1,2 frente a 2,9 kills hasta el min 10);
  - los soportes de dota-bot pasan el 64 % del tiempo a 1.500 o menos de un núcleo (Valve, 35 %).
- Validez: descriptivo; 18 partidas; rol y mid aproximados; los últimos golpes incluyen neutrales.
- Lectura: contra Valve, dota-bot gana la fase de líneas con holgura (unos +7.700 en el min 10). Lo que pierde
  partidas está después (regalar ventajas, no cerrar), que es lo que mide `n3-v3r`. Una capa de líneas contra Valve
  tendría poco margen; contra humanos puede ser distinto (rotaciones del mid, por ejemplo): se mira con el resultado
  de la serie y con la prueba con amigos.

### 2026-11-02 · `n3-v3r`, primera mirada (tanda `n3-v3r-a`, 8 bloques)
- Resultado: `cerebro_v3` 3 de 16, `base` 4 de 16; CMH z = −1,00: toca la parada por perjuicio (z ≤ −1, no
  vinculante). Sin inválidas. Think 30,0 y 30,0. CPU media 28 %, máximo 76 %.
- v3 no arregla el defecto que ataca: llegó a +10.000 en 13 y perdió 10 (`base`: 12 y 8). Secundaria (patrimonio
  por minuto, min 18-26, por bloque): v3 mejor en 2, peor en 6. Sumando `n3-v3-a` y `n3-v3r-a`: v3 11 de 32,
  `base` 12 de 32.
- Validez: en esta tanda los dos brazos ganan mucho menos que en `n3-v3-a` (`base` 4/16 frente a 8/16, mismo
  código): cae igual sobre los dos (mismo sorteo y lados por bloque); causa sin aislar (sorteo, carga).
- Decisión: pendiente de Pedro (recomendación: aceptar la parada y diagnosticar en los registros observados por qué v3
  sigue regalando ventajas antes de diseñar nada).

### 2026-11-03 · Diagnóstico de las ventajas regaladas (lectura de `n3-v3r-a`, los dos brazos observados)
- Pregunta: ¿por qué dota-bot, con y sin v3, pierde partidas en las que fue +10.000? Pedro aceptó la parada y pidió
  diagnosticar antes de corregir (DECISIONES 2026-11-03).
- Datos: las 25 partidas de `n3-v3r-a` que llegaron a +10.000 (v3: 10 perdidas y 3 ganadas; `base`: 8 y 4). Scripts de
  lectura de la sesión (`scratchpad/throws.mjs`, `numbers.mjs`).
- Resultado:

  | | v3 perdidas | `base` perdidas | v3 ganadas | `base` ganadas |
  |---|---|---|---|---|
  | Pico de ventaja (media) y minuto | +14.300, min 18 | +33.600, min 26 | +39.400, min 25 | +44.600, min 31 |
  | Torres enemigas en pie en el pico (de 11) / cuarteles (de 6) | 8,4 / 6,0 | 7,1 / 5,4 | 1,3 / 2,7 | 4,3 / 3,5 |
  | Desde el pico: muertes / kills | 16,9 / 10,5 | 14,8 / 9,4 | 0 / 0 | 3,5 / 3,0 |
  | Desde el pico: torres / cuarteles propios perdidos | 7,0 / 3,5 | 6,5 / 3,8 | 0 / 0 | 1,3 / 0,5 |
  | Rachas de 3+ muertes en 20 s desde el pico | 2,4 | 2,9 | 0 | 0,5 |
  | Muertes en la mitad propia | 65 % | 70 % | — | 41 % |

  - Plan de v3 desde el pico en las perdidas: LINEA 58 %, REAGRUPAR 17 %, DEFENDER 14 %, y los estados de asalto
    (TOMAR, AGRUPAR, EMPUJAR, CERRAR, ROSHAN) juntos un 11 %.
- Lectura:
  1. Las ventajas que se pierden son ventajas de oro sin edificios: en el pico Valve conserva 7-8 de sus 11 torres y
     todos sus cuarteles; cuando dota-bot gana, en el pico le quedan 1-4 torres.
  2. Valve remonta empujando la mitad de dota-bot: tras el pico, dota-bot pierde 6-7 torres y 3-4 cuarteles y muere
     en su propia mitad (65-70 %), a menudo varios a la vez.
  3. v3 no cambia nada de eso: llega antes a un pico más bajo y luego pasa el 89 % del tiempo en línea, reagrupando o
     defendiendo. Los asaltos que diseñamos apenas ocurren después del pico.
- Validez: descriptivo, 25 partidas. Las posiciones son cada 30 s: a esa resolución no se ve la pelea en el momento
  de cada muerte (la foto anterior muestra 2-3 aliados y 1 enemigo cerca), así que «pierde las peleas en su mitad
  porque llega en inferioridad» no está comprobado.
- Decisión: pendiente de Pedro.

### 2026-11-03 · Prueba de control completo, humo (`prueba-control`, 1 bloque, 4 partidas)
- Pregunta (DECISIONES 2026-11-03; `trabajo/prueba-control.md`): ¿un `Think()` propio controla de verdad a un héroe,
  sin que Valve ni OHA se metan? ¿Puede hacer lo básico de la línea? ¿Cuánto le falta frente al mismo héroe en OHA?
- Qué cambió desde la última: `bots/FunLib/propio/` (Sniper con `Think()` propio en `bot_generic.lua`), variantes
  `control_sniper` y `base_sniper`, `--mid sniper`; revisado por un subagente antes de usarlo.
- Configuración: `--partidas 4 --variantes control_sniper,base_sniper --mid sniper --modo turbo --observar`, código
  `7008627` + `15fb014` (correcciones de la revisión). Héroes: sven sniper bristleback skywrath_mage oracle contra
  drow_ranger death_prophet sand_king bane dazzle (Death Prophet en mid). Lectura fija: `tools/analisis/prueba-control.mjs`.
- Máquina: CPU 40-77 % al lanzar (Dota, Chrome al 100 % de un núcleo y un script de otra sesión del proyecto
  `trafico`), 65 % de memoria libre. Humo de mecanismo, no de tiempos.
- Resultado:
  1. **Control: sí.** Con el `Think()` propio, el motor solo siguió llamando `ItemPurchaseThink` de OHA (900 veces
     por 30 s, interceptado: no hizo nada); ni habilidades, ni objetos, ni mensajero, ni recompra, ni subida de
     nivel, ni el `GetDesire` de línea o retirada. **0 ataques automáticos** en 2 partidas: el motor no actúa solo.
     `GetActiveMode()` sigue diciendo LANING aunque nadie lo llame (valor viejo, como avisa Valve).
  2. **Lo básico: sí, en los dos lados.** Compra, sube habilidades con la build de Valve, se coloca, predice y pega
     una vez. Últimos golpes acertados hasta el min 10: 27 de 44 (Radiant) y 37 de 50 (Dire); denegaciones 22 de 42 y
     24 de 55. Muchos fallos son creeps que mató otro antes (la predicción subestima el daño que reciben). Ninguna
     muerte del Sniper propio hasta el min 10.
  3. **Cuánto falta (min 10):**

     | Lado | Brazo | LH | DN | Patrimonio |
     |---|---|---|---|---|
     | Radiant | propio | 32 | 24 | 4.083 |
     | Radiant | OHA | 48 | 34 | 6.037 |
     | Dire | propio | 41 | 30 | 4.857 |
     | Dire | OHA | 51 | 38 | 5.788 |

     En el min 5 la distancia es mayor (10 y 17 frente a 26 y 23). Por qué, leído en el registro: el Sniper propio
     no lanza habilidades ni responde al acoso; con la vida baja se va (una vez hasta la fuente) y pasa minutos
     recuperándose; y la regla de peligro huye con el daño que Valve estima para el mid enemigo con todo su
     arsenal (923-1.043 en 3 s frente a ~600 de vida) aunque esté fuera de su alcance: entre el min 3 y el 5 no sumó
     ningún último golpe.
  4. **Peso:** 0,09-0,10 ms por `Think` de media, máximo 10 ms. 25-27 llamadas por segundo frente a 30 de los demás:
     el contador no contaba el tiempo muerto (corregido).
  5. Defecto: 6 y 11 errores por partida por una posición nula (el reemplazo de `GetLocation` de OHA devuelve nil
     para unidades no visibles); el `pcall` los contuvo. Corregido.
- Validez: humo, un bloque, mismos héroes y lados; la comparación de LH tiene un sesgo conocido y declarado a favor
  de OHA (compra su build, usa el mensajero, lanza Shrapnel). Sirve para el mecanismo, no para decidir por números.
  Las cuatro partidas las ganó Valve (no cuenta: el humo no mide victorias).
- Decisión: el control completo funciona; siguiente paso, el diseño del bot propio para la firma de Pedro.

### 2026-11-03 · Fase 1 del bot propio, humo (`fase1`, 1 bloque, 4 partidas)
- Pregunta (DECISIONES 2026-11-03, diseño firmado: «no hay serie hasta igualar a OHA en últimos golpes y patrimonio
  del min 10 en humo»): con build y mensajero, Shrapnel y Assassinate, acoso y peligro por alcance, ¿iguala el Sniper
  propio al de OHA en el min 10?
- Qué cambió desde `prueba-control`: `compras.lua` (build de Valve por piezas con `GetItemComponents`, mensajero,
  inventario), `sniper.lua` (Shrapnel para acosar, Assassinate para rematar), regla de acoso con ataque normal, peligro
  solo de enemigos que llegan (con 2 s de margen), la recuperación hasta 0,65 solo tras retirarse por vida. Revisado por
  un subagente antes del humo; aplicadas sus correcciones (mensajero que salía vacío, piezas de tienda secreta que
  bloqueaban la build, inventario, compras estando muerto).
- Configuración: la de `prueba-control`, `--etiqueta fase1`, código `502f47e`. Héroes: chaos_knight sniper axe
  skywrath_mage witch_doctor contra juggernaut razor sand_king lion lich (Razor en mid).
- Máquina: CPU 42-64 % al lanzar (el mismo script de otra sesión del proyecto `trafico`), 63 % de memoria libre.
- Resultado (min 10):

  | Lado | Brazo | LH | DN | Patrimonio | Kills | Muertes |
  |---|---|---|---|---|---|---|
  | Radiant | propio | 58 | 30 | 6.744 | 1 | 0 |
  | Radiant | OHA | 60 | 30 | 9.143 | 5 | 0 |
  | Dire | propio | 53 | 28 | 7.045 | 2 | 0 |
  | Dire | OHA | 41 | 26 | 5.190 | 0 | 1 |

  - Suma de los dos lados: últimos golpes 111 frente a 101; patrimonio 13.789 frente a 14.333 (96 %). La diferencia de
    patrimonio viene casi entera de los 5 kills del OHA Radiant (el propio no persigue).
  - Respecto a `prueba-control`: de 32 y 41 a 58 y 53 últimos golpes (otros héroes rivales: no es comparable uno a uno).
  - Mecanismo: 0 errores, 0 ataques automáticos, 30 llamadas a `Think` por segundo (como los demás bots), 0,11-0,15 ms
    de media. Hasta el min 10: 10 y 14 Shrapnel, 2 y 3 Assassinate, 20 y 18 acosos; aciertos de último golpe 48 de 72
    y 42 de 62. Compró botas, Power Treads y las piezas de Maelstrom/Mjollnir.
  - Defecto visto: al saltar el Hyperstone (tienda secreta) compraba igual la receta de Mjollnir; corregido después.
- Validez: humo, un bloque, máquina cargada; mismo sesgo declarado (OHA usa objetos activos y persigue). Cumple la meta
  del diseño en últimos golpes; en patrimonio queda al 96 %, dentro del ruido de un bloque.
- Decisión: pendiente de Pedro (la serie de la fase 1, con su puerta de medición). Pedro acotó la meta: antes de la
  serie, el héroe completo (DECISIONES 2026-11-03).

### 2026-11-04 · Fase 1 completa, humo (`fase1c`, 1 bloque, 4 partidas)
- Pregunta: con buscar kills, perseguir con criterio, rotar y runas (`combate.lua`, revisado y corregido antes), ¿el
  mecanismo funciona limpio y cómo queda frente a OHA en el min 10?
- Configuración: `--etiqueta fase1c`, código `ba765cc`. Héroes: phantom_assassin sniper sand_king skywrath_mage dazzle
  contra chaos_knight viper kunkka vengefulspirit warlock (Viper en mid). Análisis fijo: `tools/analisis/serie-fase1.mjs`
  (escrito antes de ver estos datos) y `prueba-control.mjs`.
- Máquina: CPU 48-70 % al lanzar (tres Unreal Editor, Chrome y un script de Python que no son del banco), 49 % de
  memoria libre.
- Resultado (min 10): propio 39 y 47 LH, 5.985 y 6.166 de patrimonio, 2 y 2 muertes; OHA 59 y 53 LH, 7.611 y 9.354,
  0 muertes. Diferencia media: −23 % en LH y −28 % en patrimonio. Mecanismo limpio: 0 errores, 0 ataques automáticos,
  30 Think/s; las persecuciones empiezan con motivo (daño de su lado ×1,4-1,6) y terminan por kill, muerte del
  objetivo, torre o retirada; 5-6 runas buscadas hasta el min 10.
- Diagnóstico (registro): las muertes revisadas son iguales: el héroe quieto en la línea pierde vida 6-8 s seguidos
  (creeps con aggro tras acosar, o un héroe con poco daño por golpe que no dispara la regla de daño de golpe) y solo se
  retira con 0,30, tarde. Además se colocaba a 350 del frente, cerca para un héroe de rango largo.
- Validez: humo de un bloque, máquina cargada; no decide nada, solo bloquea la serie.
- Decisión (dentro de la autorización de Pedro, «si el humo falla corrige hasta que salga limpio»): no se lanza la
  serie; se corrige (`283f763`: retirada por daño sostenido, soltar el aggro de creeps, colocarse según el rango) y se
  repite el humo (`fase1d`).

### 2026-11-04 · Fase 1 completa, humo tras las correcciones (`fase1d`, 1 bloque, 4 partidas)
- Pregunta: ¿sale limpio el mecanismo con `283f763`, para pasar a la serie autorizada?
- Configuración: `--etiqueta fase1d`, código `283f763`. Héroes: chaos_knight sniper bristleback jakiro lich contra sven
  death_prophet tidehunter bane dazzle (Death Prophet en mid). Máquina: CPU 26-44 % al lanzar, 49 % de memoria libre.
- Resultado (min 10, `serie-fase1.mjs`): propio 47 y 46 LH, 6.088 y 5.944, muertes 1 y 0; OHA 61 y 47 LH, 7.383 y
  6.387, muertes 0 y 2. Diferencia media −14 % en LH y −13 % en patrimonio (en `fase1c`, −23 % y −28 %). Las 4
  válidas; 0 errores, 0 ataques automáticos.
- Lectura: el propio gasta hasta el min 10 unos 24 s en runas, 18 s soltando aggro y 34 s retirándose, y hace menos
  intentos de último golpe que en `fase1` (56 frente a 62-72); con un bloque y héroes distintos en cada humo no se
  separa eso del rival de línea.
- Decisión: mecanismo limpio; se pasa a la puerta de medición de la serie autorizada (DECISIONES 2026-11-04).

### 2026-11-04 · Serie de la fase 1 (`serie-fase1`): pregunta escrita antes de lanzar
- Pregunta: ¿el Sniper propio (`control_sniper`, código `283f763`) iguala al Sniper de OHA (`base_sniper`) en últimos
  golpes (principal) y patrimonio (secundaria) del min 10?
- Tamaño (autorizado por Pedro, DECISIONES 2026-11-04): 6 bloques, 24 partidas, `--mid sniper --modo turbo --observar
  --repetir-invalidas 1`. Las partidas de los humos no se suman.
- Análisis fijo: `tools/analisis/serie-fase1.mjs serie-fase1` (revisado). Una pareja por bloque y lado; diferencia media
  propio − OHA con intervalo del 95 %. Veredictos por métrica: **IGUALA** si el extremo inferior queda por encima del
  −10 % de la media de OHA; **PEOR** si el extremo superior queda por debajo de 0; si no, **INDETERMINADO**. Regla
  conjunta: la fase 1 **PASA** si LH IGUALA y el patrimonio no es PEOR.
- Potencia (revisor adversarial): con la dispersión de los humos (desviación ~8 LH y ~1.150 de patrimonio por pareja,
  de solo 4 parejas) el intervalo sale de unos ±5 LH y ±730; el margen del 10 % es de unos 5,5 LH y 770. Si los dos
  brazos fueran iguales, la serie diría IGUALA solo la mitad de las veces: un INDETERMINADO no es «peor», es que 12
  parejas no alcanzan. Solo PEOR dice que el propio es peor.
- Qué cambió desde los humos: nada en el código; el análisis cuenta parejas perdidas por brazo y motivo, lee solo el
  último intento de cada partida y coteja la variante del csv con la del log.
- Sin comprobar (no bloquean; ruido más que sesgo, según el revisor):
  - si el brazo propio cambia lo que hacen los 9 compañeros de OHA (leen modo, objetivo y posición del Sniper) y el mid
    rival; se puede mirar después en los registros sin cambiar la regla;
  - si a esta velocidad OHA piensa menos veces por segundo de juego (no hay contador de Think de OHA para el Sniper de
    la serie; el propio piensa 30/s);
  - quién va de verdad al mid de Valve (no se registra).
- Máquina: se mide al lanzar y va en la entrada del resultado.
- **No se corrió.** La máquina no se liberó en la noche (cinco Unreal Editor ajenos al banco) y, a la mañana, Pedro la
  aplazó: una serie solo confirma lo que los humos ya muestran a la par o mejor (DECISIONES 2026-11-04).

### 2026-11-04 · Diagnóstico: dónde pierde últimos golpes el Sniper propio (registros de `fase1`, `fase1c`, `fase1d`)
- Pregunta (Pedro): ¿por qué sigue por debajo de OHA? Sin partidas nuevas; `tools/analisis/diag-linea.mjs`.
- Resultado:
  1. **La brecha se abre desde el min 5-6.** Hasta el min 5 van casi iguales en últimos golpes (`fase1d`: 26 y 23 el
     propio, 27 y 20 OHA); del min 5 al 10, OHA suma 34 y 27, el propio 21 y 23. En `fase1c` igual.
  2. **El propio sale de creepear mucho más que antes del combate:** 92-226 s de 600 en `fase1c`/`fase1d`, frente a
     50-62 s en `fase1`. Intentos de último golpe hasta el min 10: 41-56 frente a 62-72.
  3. **La mayor fuga, la regla de peligro.** En `fase1d` Dire: 156 s de retirada, 108 con más del 60 % de vida y 102 con
     un héroe enemigo a la vista; de 35 a 36 decisiones de `daño_enemigo_3s` (1.009 estimados frente a 857-1.110 de vida,
     el arsenal entero de Death Prophet, sin que le estuviera pegando), una huida cada 4 s, con vida casi llena.
  4. **Runas:** 24-34 s hasta el min 10, justo cuando se abre la brecha (desde el min 6), con creeps a mano.
  5. **Soltar el aggro:** 18 s en `fase1d`, con un solo creep pegando a veces y delante del último golpe.
  6. Colocarse a `rango − 100` (`fase1d`) coincide con menos intentos; no se separa de lo anterior.
  7. Lo que no explica la brecha: aciertos del 65-70 % de los intentos en todos los humos; 4-11 los mató otro antes.
- Validez: descriptivo, 6 partidas del propio y 6 de OHA; héroes distintos por humo. Las posiciones de OHA no se comparan.
- Decisión: ajustar (`daño_enemigo_3s` solo con un héroe encima de verdad; soltar el aggro tras el último golpe y solo
  con 2 creeps o vida bajando; runas sin dejar una oleada a mano; `rango − 200`), humo `fase1e`.

### 2026-11-04 · Humo tras el diagnóstico (`fase1e`, 1 bloque, 4 partidas)
- Pregunta: ¿los ajustes del diagnóstico ponen al propio a la par de OHA en el min 10?
- Configuración: `--etiqueta fase1e`, código `cd9e90e`. Héroes: skeleton_king sniper sand_king vengefulspirit oracle
  contra luna death_prophet axe lion witch_doctor. Máquina: CPU 48-62 %, 35 % de memoria libre, seis Unreal Editor
  ajenos al banco.
- Resultado (min 10): Radiant, propio 51 LH y 5.822 (0 kills, 0 muertes), OHA 50 y 5.795 (0 y 2): **a la par**. Dire,
  propio 28 LH y 3.803 (0 y 1), OHA 58 y 9.699 (6 y 1): **muy por debajo**. Media −27 % LH, −38 % patrimonio. Fase 1:
  NO PASA. 4 válidas, 0 errores.
- Lectura de la partida mala (Dire, frente a Death Prophet):
  1. 122 s fuera por vida: 70 s andando a la fuente y 52 s de retirada; se quedó sin salvia en el min 1 y no compra más
     (Power Treads no se completa hasta el min 3:35, el martillo hasta el 7:49).
  2. Shrapnel derrochado: 16 hasta el min 10, a 1.228 de distancia media (38 de 46 a más de 1.000).
  3. No pelea: 1 sola persecución hasta el min 10 en las dos partidas y 0 kills; OHA hizo 6 kills en esa misma línea,
     y es casi toda su ventaja de patrimonio.
  4. La regla de peligro ya no huye en falso con vida llena: 62 s fuera de creepear en la partida buena.
  5. Los 7 `autoataque` de la partida 1 son todos sobre Axe, después del min 15: con toda probabilidad su Berserker's
     Call, que obliga a atacar (supuesto, no comprobado), no el motor actuando solo.
- Validez: un bloque, máquina cargada. Las dos parejas se parecen poco: la varianza entre líneas es enorme.
- Decisión: la serie sigue aplazada (DECISIONES 2026-11-04). Siguiente vuelta, para que Pedro decida: reponer salvia y
  tango, Shrapnel a corta distancia, y por qué casi no empieza kills.

### 2026-11-04 · Revisión adversarial de la fase 1 (lectura de `prueba-control` a `fase1e`, sin partidas nuevas)
- Pregunta (Pedro): antes de relanzar humos, ¿qué dicen de verdad los datos y qué mejorar en el bot propio?
- Tres revisores (Opus, esfuerzo alto), por separado: datos, bot y método. Scripts en
  `tools/analisis/revision-2026-11-04/`. Fuente que estas entradas no usaron: las líneas `[dotabench] obs`.
- **Correcciones a las entradas de arriba** (no se reescriben):
  - «La brecha se abre desde el min 5-6»: solo de media. Por pareja hay −8 y −10 en el min 5. El patrimonio salta en los
    min 7 y 9, con las rachas: 21 de 23 kills de OHA son posteriores al min 6.
  - «La mayor fuga, la regla de peligro»: se midió en `fase1d` Dire, la pareja con −1 LH; no es la causa de esa brecha.
    Correlación tiempo fuera-LH −0,54 (n=8): 226 s fuera dieron 46 LH, 98 s dieron 39.
  - «Aciertos 65-70 %»: son 56-70 %, y `golpe_res` pisa el intento pendiente; OHA no tiene dato comparable, así que
    «no explica la brecha» no está probado.
  - «Runas 24-34 s»: 24-40 s, y faltó lo importante: **0 activaciones del propio** en partidas enteras.
  - «Shrapnel derrochado» (`fase1e`): 1.228 y 38 de 46 son de la partida entera; hasta el min 10, 14 lanzamientos, 1.168
    y 10 de 13. OHA lanzó 13 en la misma línea. Los registros no dicen si acierta.
  - «6 kills en esa misma línea» y «casi toda su ventaja»: 4 fueron a Axe y Lion, héroes que no son el mid; kills 55 %,
    últimos golpes 38 %.
  - «Cumple la meta» (`fase1`): depende de un +12 frente al OHA más bajo de los 10 (41; media 52,8).
  - «NO PASA» con un bloque: el análisis da INDETERMINADO (IC −211 a +182).
  - Potencia escrita para la serie (±5 LH, ±730): desfasada; con 12 parejas sería ±8 LH y ±1.460.
  - «Declarado sin dato»: las posiciones de OHA están en `obs`, el Sniper de OHA piensa 30,0/s en las 10 partidas, y el mid
    rival es el sorteado en pos 2 (primer ocupante en 20 de 20, muestras cada 30 s).
- **Resultado:**
  - Brecha media de patrimonio −1.581 en 10 parejas: kills −801 (51 %), LH −648 (41 %), asistencias −127 (8 %), por
    regresión de ΔNW por 30 s en 4.000 ventanas (76 por LH, 534 por kill, 159 por asistencia), residuo hasta ±700. Tres
    parejas con OHA ≥5 kills suman el 72 %; las otras cinco con habilidades dan −296.
  - Asimetrías no declaradas (cotejadas a mano, partidas enteras): runas 0 frente a 5-13; TP 0 frente a 4-19; Take Aim 0
    frente a 7-15. Torres enemigas caídas 1 frente a 10; T1 mid propia perdida 3 frente a 0. OHA compra Lance, varita y MoM.
  - Enemigo a menos de 1.200 con vida bajo 400: 2 de 63 fotos el propio, 11 de 48 OHA. Acosos 38→26→9→5 por humo.
  - Muertes 6 frente a 7; tiempo muerto 134 s frente a 182 s: no explican la brecha. Los LH de OHA: 515 de 528 en el
    corredor mid. Los bloques no se distinguen del azar: dentro de bloque 8,2 LH, entre bloques 3,8 (F 0,22).
- Validez: descriptivo, código del propio cambiando entre humos, muestras de 30 s. Un bloque: ±18 LH al 95 %. Emparejar
  no reduce ruido aquí (desviación por pareja 13 LH, sin emparejar ~11,5; correlación entre brazos −0,30, n=8).
- Decisión: plan en `trabajo/fase1-plan.md`; lo que cambia lo firmado espera a Pedro. El desacuerdo entre revisores
  (Assassinate más liberal como mejora número 1 frente a 3 de 23 kills de OHA con él) queda abierto: se mide antes.

### 2026-11-04 · Humo del banco y del registro (`fase1f-reg`, 1 bloque, 4 partidas cortadas en el min 12)
- Pregunta: ¿funcionan `--corte` y las líneas nuevas en los dos brazos, y qué dicen de por qué el propio no activa runas?
  No compara LH: un bloque no decide nada (±18).
- Qué cambió: `--corte` y `--heroes` (#56); `creepkill`, `ingresos`, `dano`, `linea` en el custom game; `kill_eval`, `pos`,
  `runa_res`, `assassinate_res` y `golpe_res` en cola en el propio; `x`, `y` y `obj` en `mode` de OHA. Comportamiento del
  bot, sin cambios.
- Ya medido en los registros, antes del humo (fase1 a fase1e, 92 decisiones `runa`): con la runa a más de 700,
  `Action_PickUpRune` deja al héroe parado (`accion=1` en 111 de 125 muestras); a menos de 100, 12 intentos, `accion=2`,
  nunca 7, y ninguna activación.
- Predicción de mecanismo:
  - cada partida acaba con `resultado=corte` y `valida=si`, con la línea `[bench] linea t=720` en el registro, en
    6-8 min reales cada una (estimación del plan: 23 min por humo de 4);
  - `obs creepkill` distingue clic de Shrapnel y da decenas de creeps por partida en los dos brazos;
  - `obs dano` dice si Shrapnel hiere (`sniper_shrapnel` como fuente) y `kill_eval` qué veto frena las kills (lectura de la
    revisión: `margen`, por falta de daño previo);
  - `runa_res` a poca distancia muestra `estado=1` y un `tipo` válido; si es así, el fallo está en la orden y no en el dato.
- Máquina: 63 % de memoria libre al lanzar; CPU media 33-48 % por partida, con Chrome y otras tareas: humo cortado,
  corre con la carga anotada (DECISIONES 2026-11-04).
- Configuración: `--etiqueta fase1f-reg`, código `f50d4d2`. Héroes: chaos_knight sniper sand_king bane warlock contra
  phantom_assassin lina axe skywrath_mage lich.
- Resultado:
  - `--corte`: 4 de 4 válidas con `resultado=corte`, y **unos 5 min reales por partida** (20 por humo de 4; el plan
    estimaba 23).
  - Líneas nuevas: 0 `obs error` y 0 `prop error`, con los «error in error handling» de siempre (1-2 por partida).
    `creepkill` 146-178 por partida, distingue ataque, Shrapnel, Maelstrom y habilidades de aliados.
  - Min 10, solo mecanismo (no compara): propio 50 y 49 LH, muertes 1 y 1; OHA 49 y 61, muertes 3 y 2.
  - **`kill_eval`** (659 líneas): `margen` 559, `veto_reciente` 43, `inseguro` 31, sin veto 26. Coincide con la lectura de
    la revisión: con el daño de 4 s el propio llega a ×0,4-0,5 de la vida del rival, frente a un margen de 1,2-2.
  - **`dano`:** Shrapnel sí hiere (54-59 por tanda en esta partida); algunas tandas dan total 0 con golpes (sin explicar).
  - **Runas:** `runa_res` confirma que de lejos la orden no hace andar al héroe: a 1.734-1.799, `accion=1` (parado) tras la
    primera orden, con `estado=1`. No hubo intento cerca en este humo. A veces `tipo=-1` con `estado=1`.
  - **`ingresos`:** sin `GameTick`: el oro pasivo no pasa por el filtro (ver `bench/README.md`, «Sin comprobar»).
- Revisión (Opus, sobre `f50d4d2`, con este humo a la vista): solo registro, `C.Start` igual línea a línea, coste de `Think`
  dentro de lo habitual (0,148 ms, 30/s). Aplicado después: errores de notas a la vista, `ilusion` en `kill_eval` y
  `assassinate_res`, veto `rotacion`, `orden` en `golpe_res`.
- Validez: un bloque, no decide nada. **El porcentaje de aciertos no es comparable con los humos anteriores:** los que antes
  salían `reemplazado` ahora cuentan, y `acierto` solo dice que el contador subió (en la partida 1, 56 aciertos frente a 49
  muertes por ataque; el resto, Shrapnel y Maelstrom): la tasa de remate se calcula con `creepkill inflictor=ataque`.
- Decisión: el registro vale; pasar a los defectos del bot.

### 2026-11-04 · Referencia de OHA (`ref-oha`, 8 partidas `base_sniper` cortadas en el min 12)
- Pregunta: ¿cuánto hace el Sniper de OHA en el min 10 con el registro nuevo, para comparar los humos del propio sin
  repetir OHA en cada vuelta? (`trabajo/fase1-plan.md`, paso 1).
- Código `4793c23`; sorteo por bloque, `--mid sniper`. Máquina: CPU media 32 %.
- Resultado (min 10, `tools/analisis/humo-linea.mjs`): 8 de 8 válidas. **LH 57,4** [53 47 57 74 57 44 65 62], DN 28,8, muertes
  1,1, kills 2,4, patrimonio 7.628. Para el listón: −5 % son 54,5 LH y −15 %, 48,8.
- Validez: OHA no cambia al tocar `bots/FunLib/propio/` (`linea.lua` solo se carga con `control_completo`), pero la referencia
  y el propio van en corridas separadas, con sorteos y carga distintos: `serie-fase1.mjs` rechaza mezclarlas a propósito. La
  comparación es descriptiva, para los humos; la confirmación de 20 parejas sigue intercalada.

### 2026-11-04 · Humo de los defectos y las mejoras (`fase1g`, ablación 4+4, propio): predicción antes de lanzar
- Pregunta: ¿se mueve cada mecanismo como dice su arreglo? (`trabajo/fase1-plan.md`, pasos 3 a 5). Los LH de 8 partidas se
  comparan con `ref-oha`; la ablación mira cuánto farm cuesta el combate.
- Qué cambió: runas (andar y recoger de cerca, 3 s y abandono), compras (oro inicial, piezas baratas primero, salvia y TP,
  venta solo junto a la tienda), `RuleHeal`, maná de Shrapnel, torres, denegar, soltar aggro con 2 creeps, build, Take Aim,
  Treads en agilidad, rotación apagada, TP de vuelta, prueba de kill propia, variante `control_sniper_sincombate`.
- Predicción de mecanismo, por línea del registro y hasta el min 10:
  - runas: `runa_res` con `d` que baja hasta 80 y `accion=2` mientras anda (antes, parado). Si de cerca sigue sin activar, las
    coordenadas de `intento=si` dicen a dónde va, y la causa sigue abierta: máximo 3 s perdidos por runa;
  - oro: `oro` bajo 100 en t=0; ningún tramo de más de 1.000 ocioso; `repongo item_flask` y `repongo item_tpscroll`;
  - ventas: 0 `vendo` lejos de la tienda;
  - Take Aim: `habilidad take_aim` mayor que 0 (antes, 0 frente a 7-15 de OHA); `rango` de `obs linea` mayor que antes;
  - Treads: `botas cambio` a lo sumo 2 veces por partida, y `agi` por encima de `int` tras el último cambio; si no, la lectura
    de OHA está al revés;
  - maná: primer `shrapnel` tras el quinto punto, a ≤ alcance+200;
  - torres: ninguna caída de más de 0,5 de vida en 10 s bajo una torre por ir a por un creep;
  - TP: `habilidad tp` mayor que 0 en partidas con vuelta a la fuente (antes, 0 frente a 4-19);
  - kills: `kill_eval` con `golpes` y `habilidades` mayores que 0, `veto=margen` por debajo del 85 % actual, más `persecucion`
    que en `fase1f-reg`, y muertes no por encima de las de OHA. Si `habilidades` da solo Assassinate, la clave
    `shrapnel_damage` está mal;
  - denegados: que no caigan de 25 en el min 10 por `soon`, y tangos usadas (`curar_tango`) sin abandonar oleadas.
- Máquina: CPU media 23-46 % por partida.
- Configuración: `--etiqueta fase1g`, código `b6d1815`, 2 bloques, 8 de 8 válidas. Héroes: rival Death Prophet y Lina.
- Resultado (min 10), con n=4 por brazo: no compara, solo mecanismo.

  | Brazo | LH | DN | Muertes | Kills | Patrimonio |
  |---|---|---|---|---|---|
  | Con combate | 57,3 [60 53 60 56] | 36,8 | 0,5 | 1,0 | 6.990 |
  | Sin combate | 57,3 [53 56 57 63] | 32,0 | 0,3 | 0 | 6.286 |
  | `ref-oha` (n=8) | 57,4 | 28,8 | 1,1 | 2,4 | 7.628 |

  - La ablación no ve coste de farm: el combate no baja los LH y sube el patrimonio unos 700.
  - Cumplido: 0 errores, 0 autoataques; oro 5 en t=0; salvia y TP repuestos (0-3 por partida); 0 ventas; TP usado (2-3 en las
    partidas con vuelta); Take Aim 1-6 (antes 0); denegados 29-46; `habilidades` con Shrapnel y Assassinate (clave correcta).
  - **Treads:** en la única partida que los cambió, `stat_api` 0→1→2: el primer cambio sube `int` de 33 a 43 con la API diciendo
    agilidad, y el segundo sube el daño de 68 a 84. **La lectura invertida de OHA es correcta.** Las otras siete no los
    cambian: falta saber qué leen al montarlos (línea nueva, `botas montadas`).
  - **No cumplido, runas:** 0 activaciones. Causa acotada: **ahora el héroe llega a la runa** (`d=0`, `estado=1`, `tipo` válido,
    9 y 1) **y se queda parado** con `Action_PickUpRune` a cada tick (`accion=1`), mientras la misma llamada activa en OHA desde
    su modo de runa. Se pierden como mucho 3 s por intento. Sin explicar.
  - **No cumplido, kills:** `veto=margen` sigue entre el 87 % y el 100 %, frente a la predicción de bajar del 85 %; persecuciones
    0, 1, 5 y 0. Con los números propios el daño de 4 s es honesto y queda en la mitad de la vida del rival (395 frente a 868 a
    nivel 7): falta daño previo o más daño, no otro umbral.
- Validez: máquina con carga moderada; dos bloques; héroes distintos a los de `ref-oha`.
- Decisión: seguir la vuelta: probar otras formas de dar la orden de runa y medir 8 partidas del mismo commit.

### 2026-11-04 · Humo del listón (`fase1h`, 8 partidas del propio): predicción antes de lanzar
- Pregunta: ¿el Sniper propio queda a −5 % o mejor de `ref-oha` en LH del min 10, con muertes ≤ OHA y suelo de 45? Salida
  fijada el 2026-11-04: media ≥ 54,5 LH y muertes ≤ 1,1, a confirmación.
- Qué cambió desde `fase1g`: tres formas de la orden de runa (`runa_res metodo=`) y la línea `botas montadas`.
- Predicción: LH de 50 a 62, con una media cerca de 57 si `fase1g` no fue suerte; alguna activación si una de las otras dos
  formas funciona, y si no, 0 y queda como defecto sin resolver.
- Máquina: CPU media 27-39 % por partida.
- Configuración: `--etiqueta fase1h`, código `2d798f0`, 4 bloques, 8 de 8 válidas, sorteo. Rivales: Razor, Death Prophet,
  Necrophos y Lina.
- Resultado (min 10, `humo-linea.mjs`), frente a `ref-oha` (n=8):

  | | LH | DN | Muertes | Kills | Patrimonio | Muertes de creep cerca |
  |---|---|---|---|---|---|---|
  | Propio | **60,1** [66 63 54 61 57 65 55 60] | 35,0 | **0,0** | 1,6 | 7.737 | 143-155, 80-105 suyas |
  | OHA | 57,4 [53 47 57 74 57 44 65 62] | 28,8 | 1,1 | 2,4 | 7.628 | 118-143, 64-103 suyas |

  - **+4,7 % en LH, suelo cumplido, muertes por debajo:** se cumple la salida a confirmación. Las 0 muertes cuadran con `kill
    victim=sniper` y con `d=` de `obs hero` en t=600.
  - La brecha de kills sigue: 1,6 frente a 2,4, aunque el patrimonio ya no queda por debajo.
  - **Runas:** ninguna de las tres formas de la orden activa una (`metodo` action, cola y push): 0 en las 8 partidas enteras.
    **Defecto sin resolver**: las runas quedan apagadas, porque cada viaje solo cuesta farm. Es una desventaja del propio frente
    a OHA (5-13 runas), no un sesgo a su favor.
  - **Treads:** `botas montadas` lee `stat_api=2` en 8 de 8: salen en agilidad real de la receta, y por eso no hace falta
    cambiarlas (la partida de `fase1g` que las cambió, sin explicar).
- Validez: **no decide**: dos corridas separadas, con sorteos distintos, y sin intervalo emparejado; a ojo, con desviaciones de
  4,4 y 9,7 LH, la diferencia lleva unos ±8. Cumple para pasar a confirmar, que es para lo que sirve un humo.
- Decisión: pasar a la confirmación por su puerta (DECISIONES 2026-11-04: 20 parejas).

### 2026-11-04 · Confirmación de la fase 1 (`conf1-a`, `conf1-b`, `conf1-c`): pregunta escrita antes de lanzar
- Pregunta: el Sniper propio (`control_sniper`) frente al de OHA (`base_sniper`), intercalados y emparejados por bloque y lado:
  ¿queda en LH del min 10 por encima de −15 % de OHA (IC95), con suelo de 45 y muertes ≤ OHA? Patrimonio y kills, informativos.
- Tamaño (DECISIONES 2026-11-04): 20 parejas, 40 partidas cortadas en el min 12, en tres tandas: 16, 12 y 12 partidas. Unas
  3,5 h. Parada por inutilidad a 8 y 14 parejas si la media queda por debajo de −8 LH. `--mid sniper --modo turbo --observar
  --corte 12 --repetir-invalidas 1`, sorteo.
- Análisis fijo: `node tools/analisis/serie-fase1.mjs conf1-a conf1-b conf1-c`, ajustado al listón antes de ver estos datos;
  rechaza `--heroes` y mezclas de código o corte.
- Qué cambió desde `fase1h`: runas apagadas, sonda quitada; `hero_selection.lua` lee `lobby_mid` (sin efecto sin su archivo).
- Sin comprobar: el oro pasivo sin ×2 (igual en los dos brazos); si a esta velocidad OHA piensa menos por segundo de juego (30/s
  medidos); el corte no ve lo que pasa después del min 12: OHA ya ganaba la línea y regalaba la ventaja después (MEDICIONES
  2026-11-02/03), así que **pasar esta confirmación es un suelo, no dice que el bot gane más**.
- Partida completa del commit candidato (`conf1-humo`, 2 partidas, `e1744a3`, CPU 41-44 %): 2 de 2 válidas, 0 `prop error` y 0
  `obs error`, 30 Think/s; las dos las ganó Valve (27 y 32 min). El cierre no es lo que esta serie mide.
- Revisor adversarial (Opus, medio, sobre esos registros y `fase1h`, `ref-oha`): nada tumba la serie; tabla cotejada fila por
  fila. Contadores de `[bench] linea` iguales a `obs hero` en 18 de 18; el registro pesa un 32 % más en el brazo propio, pero el
  Sniper piensa 30,0/s en los dos; el corte no afecta al min 10. Sin comprobar: que los `Think` de los modos de OHA también
  corran a 30/s (el contador va en `BuybackUsageThink`).
- Aplicado antes de lanzar, solo en el análisis: intervalo por bloque (dos parejas de un bloque comparten héroes), «parcial, no
  decide» hasta las tres tandas, y error si cambian versión, modo o dificultad, si una pareja no comparte héroes o si el brazo no
  corresponde a sus líneas del bot propio; texto «no inferior a −15 %» en vez de «iguala».
- **Potencia** (estimada por el revisor, desviación por pareja de unos 12, con 20 parejas): si los brazos son iguales, pasa el
  71-83 % de las veces; si el propio está en −5 %, el 44 %; en −10 %, el 12 %; en −15 %, el 2,5 %. Un PASA descarta −15 % y
  razonablemente −10 %; **no distingue 0 de −5 %**.
- **Corrección a `fase1h`** («no un sesgo a su favor»): en ingresos es cierto, pero en LH es al revés: el propio no paga los viajes
  a runas que OHA sí paga (OHA recoge 0-3 antes de t=600, media 0,9). Pequeño; patrimonio, kills y runas van junto a los LH.
- Máquina: al lanzar, CPU 26 % y 59 % de memoria libre, sin Unreal; CPU media por partida 27-69 %.
- Configuración: `conf1-a`, `conf1-b`, `conf1-c`, 40 de 40 válidas sin repetir ninguna, un solo árbol (`a139fd9.3d57f56`), 10
  sorteos, unas 3,5 h. Miradas a 8 y 14 parejas: +4,5 y +5,5 LH, sin parada.
- **Resultado (20 parejas, min 10, `serie-fase1.mjs`): Fase 1 PASA.**

  | | Propio | OHA | Diferencia |
  |---|---|---|---|
  | **LH** (principal) | **59,4** | 55 | **+4,4, IC95 +1,2 a +7,6 (10 bloques), +8,0 %** |
  | Muertes | 0,20 | 1,00 | |
  | Patrimonio (informativo) | | 7.422 | −193, IC95 −862 a +475, −2,6 % |
  | Kills (informativo) | 1,25 | 2,35 | |
  | Runas (informativo) | 0 | 1,65 | |

  Suelo de 45 cumplido; Think/s mínimo, 30 en los dos brazos; 0 `prop error`.
- Lectura: el intervalo queda entero por encima de 0: en últimos golpes y muertes el propio no solo no es inferior, va por
  delante de OHA en la línea. Pero recoge la mitad de kills y ninguna runa, y por eso el patrimonio se queda en un empate
  ligeramente por debajo.
- Validez: sin sesgo conocido entre brazos salvo los viajes a runas, pequeños, a favor del propio en LH. **Solo mide el min 10:**
  no dice nada de victorias; las 2 partidas completas de este commit las ganó Valve.
- Decisión: cumplido el listón de Pedro (DECISIONES 2026-11-04). Queda su partida contra el Sniper antes de la fase 2.

### 2026-11-05 · Partida de Pedro contra el Sniper propio (lobby Local Host, sin banco)
- Pregunta: ¿qué ve un humano jugando contra él? Es la única prueba real frente al objetivo (DECISIONES 2026-11-04).
- Configuración: `tools/jugar-sniper.mjs`, código `970b7c5`, Sniper propio en Dire con cuatro de OHA. Pedro no detalló modo,
  duración ni resultado.
- Resultado, con sus palabras: «la subnormalidad de nuestro sniper es inconmensurable jajajajaja es nefasto, todos los bots lo
  son, solo empiezan a ser competentes en late porque usan bien sus poders».
- Validez: una partida, sin registro: el lobby no corre con `-condebug` ni observador (`console.log` sigue siendo del 2026-11-04).
  No dice qué conductas fallan.
- Lectura: **contradice lo que el listón parecía decir**: el propio va por delante de OHA en últimos golpes y muertes, frente a
  bots de Valve, y aun así un humano lo ve nefasto. El listón compara bots entre sí: pasarlo era un suelo, no jugar bien.
- Decisión: pendiente de Pedro; recomendado no empezar la fase 2 hasta traducir lo que vio en conductas medibles.

### 2026-11-05 · Lo que vio Pedro, cotejado con la confirmación (`conducta-linea.mjs`, 40 partidas ya jugadas)
- Pregunta: ¿los registros muestran lo que Pedro vio? Sin partidas nuevas.
- Lo que contó: «no mide correctamente el riesgo, asume mas daño [d]el necesario antes de escapar o no contraresta con sus propios
  ataques aun teniendo ventaja de highground incluso, no tiene en cuenta sus propias ventajas, rango skills, etc. Y tampoco ataca
  por iniciativa propia para provocar que el heroe enemigo retroceda, si deniega decentemente y da last hit tambien pero solo
  cuando no lo estan molestando». Él iba de Viper en mid, y su equipo ganó «con relativa facilidad».
- Resultado hasta el min 10, 20 partidas por brazo, rival bot de Valve:

  | | Propio | OHA |
  |---|---|---|
  | Daño a héroes | 2.983 | 6.315 |
  | Daño recibido de héroes | 901 | 2.211 |
  | Ventanas de 10 s acosado (≥50 de daño de héroes) | 8 % | 14 % |
  | De ellas, sin devolver nada | **44 %** | 17 % |
  | Últimos golpes del rival de mid | **15,3** | 10,8 |
  | Muertes del rival de mid | 1,10 | 1,70 |
  | Últimos golpes por ventana: acosado / tranquilo | 1,60 / 1,66 | 1,00 / 1,59 |
  | Creeps cercanos rematados: acosado / tranquilo | 56 % / 64 % | 44 % / 64 % |

- Lectura:
  - **Confirmado, no contesta:** casi la mitad de las veces que le pegan no devuelve nada, y hace menos de la mitad de daño a héroes.
  - **Confirmado, sin iniciativa:** el rival de mid farmea un 42 % más contra el propio que contra OHA. Eso no lo miraba el listón:
    **parte de los LH del propio es no pelear.**
  - **Confirmado en el código:** nada compara su alcance o su daño con los del rival; `GetHeightLevel` no se usa nunca; el peligro
    `daño_enemigo_3s` sale de la estimación de Valve, y la decisión de pegar (`RuleTrade`) solo mira vida y creeps cercanos.
  - **No se ve, «solo cuando no lo molestan»:** bajo acoso rinde casi igual, pero un bot de Valve casi no acosa (8 % de ventanas).
    **El banco no reproduce la presión de un humano:** por eso no se veía.
- Validez: descriptivo, sin intervalos. Daño según lo recibe el filtro. La lectura de «asume más daño» como «pierde más vida de la
  necesaria antes de irse» es del agente; sin medir, porque no hay registro de la vida al empezar cada intercambio.
- Decisión: Pedro aprueba el listón nuevo (DECISIONES 2026-11-05). Referencia: `base_sniper` de la confirmación, 55 LH (−5 % son
  52,3), 1,00 muertes, 17 % sin devolver, rival 10,8 LH.

### 2026-11-05 · Humo del intercambio (`fase1i`, 8 partidas del propio): predicción antes de lanzar
- Pregunta: con el intercambio por números propios, ¿cumple el listón: LH ≥ 52,3, muertes ≤ 1,00, sin devolver ≤ 17 %, rival ≤ 11 LH?
- Qué cambió: `intercambio.lua` (quién mata antes a quién, con alcance, altura, creeps y otros héroes); contestar y presionar en
  vez de `RuleTrade` por vida; `alejarse` al perder el intercambio; el peligro, sin `GetEstimatedDamageToTarget`.
- Predicción, por línea del registro:
  - `prop acoso contesto` y `presiono`, decenas por partida; sin devolver baja de 44 %;
  - daño a héroes sube de 2.983 hacia 6.315, y el daño recibido, de 901 hacia 2.211;
  - rival de mid baja de 15,3 LH hacia 11;
  - LH bajan algo de 59,4 y las muertes suben de 0,20: **es el coste que se espera**; `alejarse` lo limita;
  - `ratio` de `kill_eval` por encima de 1 en buena parte de las líneas. Si casi nunca lo supera, los factores de
    `intercambio.lua`, que son criterio y no datos, hay que revisarlos.
- Máquina: CPU media 31 %. Código `eccf2c7`, 8 de 8 válidas, sorteo. Rivales: Zeus, Razor, Necrophos y otros.
- Resultado, min 10 (`humo-linea.mjs`, `conducta-linea.mjs`), frente a la referencia:

  | | `fase1i` | Listón | Antes (`conf1`) | OHA (`conf1`) |
  |---|---|---|---|---|
  | LH | **62,6** | ≥ 52,3 | 59,4 | 55 |
  | Muertes | **0,1** | ≤ 1,00 | 0,20 | 1,00 |
  | Sin devolver | 31 % (9 de 29) | ≤ 17 % | 44 % | 17 % |
  | LH del rival de mid | 11,6 | ≤ 11 | 15,3 | 10,8 |
  | Daño a héroes | 4.589 | | 2.983 | 6.315 |
  | Muertes del rival | 2,88 | | 1,10 | 1,70 |
  | Kills | 2,6 | | 1,25 | 2,35 |
  | Patrimonio | 8.240 | | 6.990 aprox. | 7.422 |

  - **La predicción falló a favor:** se esperaba perder algo de farm a cambio de pelear, y suben los LH, las kills y el patrimonio.
  - Mecanismo: 29 `contesto` y 440 `presiono` hasta t=720; 0 errores. `ratio` > 1,2 en el 77 % de las líneas.
  - Sin cumplir: sin devolver (31 %) y rival (11,6, a 0,6 del listón; n=8).
  - De las 9 ventanas sin respuesta: **3 son el ulti global de Zeus**, sin nadie a quien contestar (la métrica las excluye desde
    ahora, en los dos brazos); otras pasan antes de t=50 con `ratio` 0,3 y el héroe alejándose.
  - **Defecto encontrado:** la API no distingue una ilusión enemiga (`ilusion=0` en 2.114 de 2.114 líneas, con tres Zeus a la vez
    tras una runa), y cada copia contaba como un héroe entero: bajaba el `ratio` y provocaba huidas en falso. Corregido: una unidad
    por héroe, la más cercana.
- Validez: corridas separadas, sorteo distinto: las diferencias con `conf1` son descriptivas.
- Decisión: repetir con el arreglo (`fase1j`, segunda vuelta).

### 2026-11-05 · Humo tras el arreglo de las ilusiones (`fase1j`, 8 partidas del propio): predicción antes de lanzar
- Pregunta: ¿cumple ahora los cuatro números del listón, con la métrica sin el ulti global?
- Qué cambió: `OnePerHero` en `intercambio.lua` y en el peligro de `combate.lua`. `conducta-linea.mjs` excluye el ulti global de Zeus;
  la referencia de OHA se recalcula con la misma definición.
- Predicción: menos `alejarse` en los primeros 60 s de las partidas con ilusiones; sin devolver por debajo del 31 %; LH del rival en
  torno a 11, sin separarse del ruido de 8 partidas; LH y muertes, sin cambios grandes.
- Máquina: CPU media 31 %. Código `751f66c`, 8 de 8 válidas, sorteo. Rivales: Death Prophet en varias, Razor.
- Resultado (min 10): LH 58,1 ✓ [56 56 47 61 60 57 64 64], muertes 0,0 ✓, **sin devolver 43 % (10 de 23) ✗**, **rival 12,5 LH ✗**. Kills 2,8,
  patrimonio 8.044, daño a héroes 5.176, muertes del rival 1,88. 0 errores; `alejarse` antes de t=60: 35 frente a 40.
- Lectura: la predicción de «sin devolver» falló. Las ventanas son casi todas de los primeros 140 s frente a Death Prophet: a nivel 1
  (50 de daño, 0,79 ataques/s) el `ratio` queda entre 0,5 y 0,8. **Había un hueco en las reglas:** bajo 1 no contesta, y solo se aleja
  bajo 0,7 y con vida menor de 0,8; entre medias se queda parado recibiendo, lo que vio Pedro. Con tan pocas ventanas (23) esta
  cifra se mueve mucho entre humos: 23 % y 43 %.
- Decisión: cerrar el hueco (`fase1k`, tercera vuelta).

### 2026-11-05 · Humo tras cerrar el hueco (`fase1k`, 8 partidas del propio): predicción antes de lanzar
- Pregunta: ¿cumple los cuatro números del listón?
- Qué cambió: al recibir golpes, o se aleja (`ratio` bajo 0,7 y vida bajo 0,8) o contesta; no hay tercera opción.
- Predicción: `contesto` sube de unas decenas; sin devolver baja de 23-43 % hacia 17 %, salvo golpes recibidos fuera de alcance; LH y
  muertes sin grandes cambios, con algo más de daño recibido. El rival de mid puede no moverse: esto no toca la presión.
- Máquina: CPU media 32 %. Código `0af27b8`, 8 de 8 válidas, sorteo, 0 errores; 47 `contesto` y 367 `presiono` hasta t=720.
- Resultado (min 10), frente al listón (DECISIONES 2026-11-05):

  | | `fase1k` | Listón | ¿Cumple? | `fase1i`+`j`+`k` (n=24) | OHA (`conf1`) |
  |---|---|---|---|---|---|
  | LH | 61,5 [60 62 62 65 63 59 57 64] | ≥ 52,3 | sí | 60,7 | 55 |
  | Muertes | 0,0 | ≤ 1,00 | sí | 0,04 | 1,00 |
  | Sin devolver | 13 % (2 de 16) | ≤ 17 % | sí, con muy pocas ventanas | 28 %, mezcla reglas | 15 % |
  | LH del rival de mid | 12,1 | ≤ 11 | **no** | 12,1 | 10,8 |
  | Kills | 3,0 | | | 2,8 | 2,35 |
  | Muertes del rival | 3,50 | | | 2,75 | 1,70 |
  | Patrimonio | 8.252 | | | 8.178 | 7.422 |

- Lectura:
  - Tres de los cuatro números. El rival va **un LH por encima del listón en las tres vueltas** (11,6, 12,5, 12,1): no es solo ruido de 8
    partidas, aunque OHA oscila mucho por tanda (9,5, 8,2 y 15,0 con las mismas reglas). Antes del intercambio, 15,3.
  - «Sin devolver» se apoya en 16 ventanas: con tan pocas, el 13 % puede moverse mucho.
  - El rival muere el doble que con OHA y aun así farmea algo más: lo mata, pero no le quita creeps entre muertes.
- Validez: corridas separadas de `conf1`, con sorteos distintos; sin serie emparejada. Sin partida completa de este commit.
- Decisión: **se agotan las 3 vueltas**. El listón no se da por cumplido: el rival queda para Pedro, con la partida contra el Sniper.

### 2026-11-05 · Segunda partida de Pedro contra el Sniper propio (lobby, con registro: `lobby-202611052104.log`)
- Pregunta: tras el intercambio, ¿sigue siendo nefasto? Pedro, de Viper en mid (Radiant), con el Sniper propio en Dire. Código `7371db2`.
- Lo que contó: «se comportó muchisimo mejor en early game, en late igual que antes haciendo combos, pero en el juego intermedio y
  en late se posiciona muy mal, nuevamente cae en lo de no aprovechar sus ventajas con el rsngo que tiene deberia entrar oculto
  siempre, pero se pasea campante por las lineas, no se hace invisible, no salta mo se oculta ese criterio de riesgo-taque-sigilo es
  lo que falta».
- Resultado del registro, partida de 36 min:
  - Min 10: 40 LH, 27 DN, 2 kills, 1 muerte, patrimonio 7.122 (bajo presión humana, por debajo de los 61,5 LH frente a bots de Valve).
  - **De 1 muerte en los primeros 10 min a 10 al final**; kills de 2 a 5.
  - **Oro sin gastar: 6.575 en el min 24, 17.087 en el min 36.** La última compra es del min 19,6: la lista se acaba, porque las
    piezas de tienda secreta se saltan (Crystalys y Satanic), y no hay nada después.
  - **Hace lo mismo toda la partida:** `linea` y `preparar_golpe` son las decisiones más frecuentes en los tres tramos (0-10, 10-25, 25+).
- Lectura: confirma a Pedro, y la causa es de diseño: **el Sniper propio no tiene medio juego.** Sus reglas son las de la línea; las fases 3 y 4
  aún no existen. No hay objetos de movilidad o sigilo en la lista, ni reglas para usarlos, ni colocación según riesgo.
- Validez: una partida, un rival humano. Es la única prueba frente al objetivo; no se generaliza a números.
- Decisión: cerrar la línea con el rival como deuda y adelantar el medio juego (DECISIONES 2026-11-05: «si a las dos»).

### 2026-11-05 · Humo del medio juego (`medio1`, 4+4, cortado en el min 25): predicción antes de lanzar
- Pregunta: ¿el Sniper propio gasta el oro, usa los objetos y muere menos que antes desde el min 10, frente a OHA en las mismas partidas?
- Qué cambió: `medio.lua` (entra por nivel 15 o T1 de mid caída: elegir línea por riesgo, unirse a peleas, kite, irse en inferioridad, Blade, Pike,
  BKB), compras (Blade, Pike, Silver Edge, tienda secreta con el mensajero, recompra, tirar ramas). Revisado por un subagente antes de lanzar.
- Comando: `--variantes control_sniper,base_sniper --partidas 8 --corte 25 --mid sniper --modo turbo --observar --repetir-invalidas 1`. Autorizado
  el corte en el min 25 (DECISIONES 2026-11-05). `humo-linea.mjs --min 25` y `--min 10`.
- Predicción, hasta el min 25:
  - `empieza el medio juego` después de t=600, y LH y muertes del min 10 sin separarse de `fase1k` (61,5 y 0,0);
  - oro sin gastar bajo 1.500 de media (en la partida de Pedro, 6.575 en el min 24);
  - `prop objeto` con los tres tipos: escapar, entrar oculto y BKB; `mensajero a la tienda secreta` y compra de Demon Edge o Reaver;
  - muertes desde el min 10 por debajo de las de OHA; de partida contra un humano, 6 entre el min 10 y el 24;
  - sin ir y volver: menos de 20 cambios de línea por partida; `a_la_pelea` no alterna con `retirada` en menos de 3 s.
- Sin medir: si el Sniper rinde mejor en una pelea: los bots de Valve no castigan como un humano. Eso lo dirá Pedro.
- Máquina: CPU media 31-79 % por partida, no intercalada de forma pareja (propio 31-71 %, OHA 32-79 %).
- Configuración: `--etiqueta medio1`, código `3b9553b`, 8 de 8 válidas, sorteo. 1 partida de OHA acabó antes del corte (ganó su equipo).
- Resultado:

  | | Propio (n=4) | OHA (n=3) |
  |---|---|---|
  | Min 10: LH / muertes / kills | 59,3 / 0,0 / 1,8 | 54,3 / 0,3 / 3,5 (n=4) |
  | Min 25: LH | 175,5 | 156,3 |
  | **Muertes desde el min 10** | **0,0** | 1,0 |
  | Kills desde el min 10 | 8,5 | 8,0 |
  | Patrimonio | 26.448 | 24.553 |
  | **Oro sin gastar** | **476** | 8.967 |

  - Cumplido: medio juego desde t=681-718, tras el min 10; LH del min 10 sin salir de lo esperado; oro por debajo de 1.500; tienda secreta con
    2-3 compras por partida; a t=1500 ya lleva Silver Edge, Pike y BKB, y en 3 de 4 Mjollnir. 0 errores; 0 cambios de línea (**ni una vez cambió:
    la regla no actúa o el margen es muy alto**, sin comprobar); 0 saltos de `a_la_pelea` a retirada.
  - Objetos usados: Blade 8-17 veces por partida, casi siempre para «entro oculto». Pike 0-4: **Force Staff y Pike se usan poco**.
  - `prop nivel` salta del 14 al 18 también en OHA (`learn`, de t=654 a t=889): **lo hace el motor**, no es un defecto. Corrección a lo anotado.
- Validez: 4 partidas por brazo, sin intervalos, bots de Valve que no castigan como un humano. Las 0 muertes no se trasladan a una partida contra Pedro.
- Decisión: mecanismo limpio; avisar a Pedro para que juegue.

### 2026-11-05 · Tercera partida de Pedro contra el Sniper propio (lobby, con registro: `lobby-202611060402.log`)
- Lo que contó: «ha mejorado bastante, se hace invisible y es algo más escurridizo, pero sigue posicionandose mal o atacando solo a pesar de que es
  uno de los heroes mas endebles». Código `3dffae7`, partida de 37 min.
- Resultado del registro: 7 muertes (10 antes), 2 kills (5 antes), oro gastado (428 y 188 en los min 30 y 35, frente a 17.087). 10 cambios de línea: la
  regla sí actúa cuando hay riesgo. Por lo que se ve en los 14 s antes de cada muerte:
  - **El `ratio` veía poco daño:** Bloodseeker 258 y hacía 476 por segundo; Alchemist 35 y hacía 128. Faltan críticos, habilidades y robo de vida: seguía
    contestando y presionando cuerpo a cuerpo (a 68, 190 y 233 de distancia), con `ratio` 1,3-2.
  - **Presiona solo:** 35 `presiono` después del min 10, sin mirar si hay aliados. En 3 de 7 muertes sale `presiono` o `contesto` poco antes.
  - **Pike repetido:** 5 órdenes en 0,5 s en t=1198, mientras moría; el héroe no llegó a separarse.
  - **Va a la línea aunque esté solo y falten enemigos:** en 3 muertes lo cazan en otra línea, a 3.200-4.400 del frente, recién teletransportado o yendo.
  - Las dos primeras, frente a Alchemist en la línea, también caen en lo primero: la fase de línea tampoco queda libre contra un humano.
- Validez: una partida; la cuenta de causas es por lectura, no por medida. El registro de un lobby no tiene líneas `obs`: las muertes se ven como huecos en `estado`.
- Decisión, dentro de lo que pidió Pedro: `ratio` con el daño real de los últimos 2 s; solo y tras la línea, no presiona, contesta solo fuera del alcance enemigo,
  no empieza persecuciones salvo kill clara, y si hay riesgo espera junto a su torre; cada objeto, como mucho cada 1,5 s.

### 2026-11-05 · Humo de «no atacar solo» (`medio2`, 4 partidas del propio, min 25): predicción antes de lanzar
- Pregunta: ¿los cambios actúan sin dejarlo sin farmear?
- Predicción: `prop acoso presiono` después del medio juego solo con aliados cerca; decisiones `esperar` en todas las partidas; 0 repeticiones de un objeto en
  menos de 1,5 s; LH del min 25 por debajo de 175, por esperar: **es el coste**; si baja de 150, espera demasiado.
- Máquina: CPU media 44 %. Código `328b542`, 4 de 4 válidas, sorteo; 1 partida acabó antes del min 25.
- Resultado: min 10, 57,0 LH y 0 muertes. Min 25 (n=3): **138,7 LH**, 0,7 muertes, 2,7 kills desde el min 10, patrimonio 18.066, 503 de oro sin gastar. Frente a `medio1`:
  175,5, 0,0, 8,5 y 26.448. 0 errores. Espera el 13-24 % del tiempo tras el min 12.
- Lectura: **espera demasiado**, bajo el umbral de 150 fijado antes. No muere menos que `medio1`, aunque con 3-4 partidas y rivales distintos eso no se separa del azar. Con
  `holdRisk` 0,4, tres enemigos fuera del mapa bastaban, y frente a bots de Valve casi siempre faltan.
  Pedro añadió de su partida: «se quedó parado como pendejo»; candidato en el registro: t=393-413, 20 s quieto en la torre con 0,27 de vida, sin salvia (sin confirmar).
- Decisión: esperar solo con un enemigo visto cerca (0,9); persecución en solitario desde 1,5 veces el margen; sin salvia y con TP, a la fuente si recuperarse tarda más de 15 s.

### 2026-11-05 · Humo del ajuste (`medio3`, 4 partidas del propio, min 25): predicción antes de lanzar
- Pregunta: ¿recupera el farm sin volver a presionar solo?
- Predicción: `esperar` por debajo del 10 % del tiempo; LH del min 25 por encima de 150; kills desde el min 10, entre 2,7 y 8,5; menos tramos de 12 s o más quieto con `retirada`.
- Máquina: CPU media 49 %. Código `d6e014a`, 4 de 4 válidas, sorteo, 0 errores.
- Resultado: min 10, 62,8 LH y 0 muertes. Min 25: 156,0 LH, 0,0 muertes, 2,8 kills desde el min 10, patrimonio 19.954, 1.767 de oro sin gastar. `esperar`, 7-9 % del tiempo.
- Lectura: cumple la predicción, justo en kills: **2,8 frente a 8,5 de `medio1`, y patrimonio 19.954 frente a 26.448**. Es el precio de no empezar solo. Contra bots de Valve, «0 muertes» no
  separa nada, porque no castigan: hay que medir contra un rival que presione.
- Decisión: encargo nocturno de Pedro (DECISIONES 2026-11-06): medir contra OHA en la misma partida.

### 2026-11-06 · El Sniper propio y el de OHA contra un equipo OHA (`presion-propio`, `presion-oha`, 4 y 4, min 25): pregunta antes de lanzar
- Pregunta: los bots de Valve casi no acosan (5-14 % de las ventanas): ¿un equipo OHA presiona más, y cómo queda el Sniper propio frente al de OHA con ese mismo rival?
- Qué cambió: el custom game sigue al héroe también con `--rival dotabot` (`--variantes control_sniper,base` y `base_sniper,base`). Es un brazo cada vez, con sorteos separados: descriptivo.
- Predicción: más ventanas acosado que contra Valve; el Sniper propio muere más que 0; las muertes dirán qué regla falla. Sin mirar victorias.
- Máquina: CPU media 32-48 % por partida, con picos de 77 %.
- Resultado: acosado el 22-23 % de las ventanas: **presiona de verdad**. En `presion-propio`, muertes 1,8. Propio frente a OHA, min 25: patrimonio 16.985 y 28.094; kills 3,5 y 13,8; LH 134,8 y 181,3; muertes 1,8 y 2,0.
  Tras el min 12, el propio pasa el 62 % del tiempo en `linea`.
- Decisión: las siguientes vueltas de la noche se miden contra este rival.

### 2026-11-06 · Vueltas de la noche contra un equipo OHA (`presion2` a `presion6`, 4 partidas cada una, min 25) y contra Valve (`medio4`)
- Encargo: DECISIONES 2026-11-06. Código `3dbc5ab` a `af0e191`. Todas válidas, 0 `prop error`, sorteo distinto en cada una. **Con 4 partidas por vuelta y sorteos distintos, una diferencia entre dos vueltas puede ser ruido:** se lee la tendencia y el mecanismo, no cada salto.
- Causas encontradas en los registros y qué se cambió:
  - **Compras:** una Belt of Strength de la Lance que llegaba con las piezas de los Treads los montaba en fuerza; la Lance no se montaba, se llenaba el inventario y el mensajero iba y volvía cada 15 s (`presion-propio` partida 3, t=210-575). Ahora los Treads se montan antes de comprar piezas de otro objeto.
  - **Cruzar el mapa:** `ChooseLane` lo mandaba a otra línea en plena emboscada, andando 6.000-7.000, gastando el Blade. Ahora solo sin enemigos a la vista y, si está lejos, con TP.
  - **Riesgo y retirada:** la torre enemiga cuenta; no se retira a través de los enemigos, y mantiene la torre elegida.
  - **Sin nada que hacer:** neutrales de nuestro lado si no hay oleada ni riesgo, y TP a peleas de dos o más aliados. Disparo gratis estando solo. Assassinate con aliados aunque haya otro enemigo a 900. Salir antes con vida bajo 0,45 si un héroe lo alcanza.
  - Revisión de un subagente (Opus) sobre neutrales y peleas, aplicada: vuelve a entrar oculto en caminatas medias, porque reservarlo recortaba lo que pidió Pedro. Sigue sin entrar oculto en caminatas de más de 3.000: **ajuste del agente**.
- Resultado, min 25:

  | Vuelta | Qué cambia | LH | Muertes | Kills | Patrimonio |
  |---|---|---|---|---|---|
  | `presion-oha` | Sniper de OHA, referencia | 181,3 | 2,0 | 13,8 | 28.094 |
  | `presion-propio` | antes de la noche | 134,8 | 1,8 | 3,5 | 16.985 |
  | `presion2` | Lance, cruzar el mapa, retirada | 142,3 | 2,0 | 6,3 | 21.533 |
  | `presion3` | neutrales, TP a peleas | 213,0 | 1,3 | 5,8 | 21.558 |
  | `presion4` | disparo gratis, campamentos a 1.800 | 149,8 | 2,3 | 4,0 | 19.126 |
  | `presion5` | campamentos a 3.000, salir antes | 189,0 | 1,3 | 4,0 | 20.832 |
  | `presion6` | Assassinate con aliados | **212,5** | **0,5** | 5,3 | 21.689 |
  | `medio4` | como `presion5`, rival Valve | 241,8 | 0,3 | 10,0 | 27.219 |

- Lectura:
  - **Mejor:** farmea más que OHA y muere menos con el mismo rival; `presion6` tiene las mejores muertes de las vueltas, y `medio4` frente a `medio3` (156,0 LH, 19.954) sube mucho.
  - **Sigue lejos en lo que más pesa:** 5,3 kills frente a 13,8, patrimonio 21.689 frente a 28.094, **daño a héroes tras el min 12: 31.102 en `presion6` frente a 89.369 de OHA** (suma de 4 partidas).
  - En línea, bajo presión, no devuelve nada en el 49 % de las ventanas de acoso (`presion6`, 18 de 37; OHA 23 %), y el rival de mid hace 20,3 LH. Con el `ratio` que cuenta el daño real se aleja más que contesta. Sin decidir si es mejor o peor: lo juzga Pedro.
- Validez: descriptivo. Un equipo OHA tampoco es un humano. Sin partida completa de este código.
- Decisión: dejar el resultado para que Pedro juegue.
