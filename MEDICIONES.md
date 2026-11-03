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
