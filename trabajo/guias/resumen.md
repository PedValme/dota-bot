# Piloto de guías: resumen y paquete propuesto (`guias1`)

Base: las cinco tablas de `trabajo/guias/` (contenido de terceros, datos), el código de `bots/FunLib/propio/` en `6189cc4` y los
registros de la ronda en curso. Firma de Pedro (DECISIONES 2026-11-14): «solo reglas que digan 2 guías o más, que la API permita y que
toquen situaciones frecuentes en los registros; como mucho 8 reglas; revisión adversarial de Opus antes de programar; predicción escrita
antes de medir; como mucho 2 rondas».

> **Lo que se programó, tras la revisión adversarial de Opus (2026-11-14):** solo las reglas A, B y E. Se quitaron C (la situación
> «rival a ≤ 700» no es la de las guías, y Lich 6 dice lo contrario) y D (casi sin brecha y mezcla su efecto con B). La revisión también
> cambió la decisión: el paquete cumple por resultado (nivel y patrimonio por héroe y línea, `equipo.mjs`), y las métricas de mecanismo
> de la sección 4 solo sirven para ver en el humo que cada regla actúa. B exige un rival en la llama o maná para otra llama, y no acosa
> estando superado. La predicción vigente está en MEDICIONES (2026-11-14, `g1`); la de la sección 4 queda como borrador.

## Cómo se midió la frecuencia
- **Registros:** los logs viejos (`h2`, `p4a`, `p4b`) se perdieron. Uso los 4 de la ronda en curso que había a las 23:55 del 2026-11-13:
  - `p4r2a-a` #1 y #2, brazo A (`control_equipo_p4`);
  - `p4r2b-a` #1 y #2, brazo B (`control_equipo`).
  - **Solo la alineación a:** la difícil contra Sven y Witch Doctor, la segura contra Bristleback y Vengeful. Las b y c pueden dar otra cosa. Hay que recalcular con las 12 al cerrar la ronda.
  - `bench/lineas/*.csv` solo tiene totales por equipo y minuto: no sirve para atribuir situaciones, y no lo usé.
- **Ventana:** t 0-720 (60-720 para posiciones), lado nuestro.
- **Fuentes:**
  - del observador: líneas `fino` (posición, vida y objetivo de ataque cada segundo), `golpe` (daño por atacante y fuente), `lanza`, `hero` (nivel y últimos golpes cada 30 s) y `kill`;
  - del bot: líneas `prop estado` (intención y maná cada ~2 s), `prop decision`, `prop golpe` y `golpe_res`, `prop kill_eval` (ratio del intercambio y distancia, ~1 por segundo y objetivo) y `prop pareja` (anuncios de apertura).
- **Scripts:** de un solo uso, en el scratchpad de la sesión (`frec.mjs`, `frec2.mjs`, `frec3.mjs`, `base.mjs`, `dkidle*.mjs`).
  - No son el análisis fijo: la medición del paquete necesita su sección revisada en `linea-dos.mjs` (ver Diseño).
- **Criterio de «frecuente»:** 5 o más veces por partida, o 30 s o más por partida.

## Lo que corrigen los registros y el código en las tablas de los subagentes
- **DK, regla 7: los 186 frente a 2.758 son de `h2`.** Con el paquete 4, nuestro DK hace 1.197 de daño de ataque a héroes por partida (A) y 701 sin él (B). El carry de OHA que tiene enfrente hace 1.870.
- **DK: la causa no es el umbral del ratio.**
  - A 450 o menos con ratio ≥ 1,2, el DK casi siempre presiona.
  - El hueco está entre 450 y 900: unas 55 lecturas por partida con ratio ≥ 1,2 y Lion a ≤ 800 en las que el DK se queda en `linea` o `preparar_golpe`.
  - La razón: `K.pressReach = 300`, pensado para el Sniper, deja al cuerpo a cuerpo en 150 + 300 = 450.
- **Lion, regla 14 (no recompra consumibles): falso.** `Consumables` repone salvia y claridad: el Lion compra entre 2 y 12 salvias por partida.
- **Regen en general: ya hay mucha.** Luna, DK y Lich reponen entre 9 y 14 salvias por partida (`repongo item_flask`).
- **Luna, regla 12:** el objeto se llama `item_faerie_fire`, no `item_fairy_fire`.
- **Sniper, regla 14:** con el paquete 4 sí lleva Magic Wand (`WithWand`).
- **Confirmado en el código:** Lich `FarmCast` no lanza con más de un aliado a 1200 (`lich.lua:189`), y Lion no usa Mana Drain (`lion.lua:13`).

## 1. Reglas que cumplen la firma (2 guías o más, API, frecuentes)

| # | Regla (situación → acción) | Guías | API | Frecuencia medida (por partida, alineación a) | Fuente de la frecuencia |
|---|---|---|---|---|---|
| A | DK con nada que rematar y un rival de su línea cerca → ir a pegarle con clic derecho (Dragon Blood lo sostiene) | DK 7 (Sky@3:04, Tor@9:02) + DK 6 (Sky, SH, Tor: «no se le echa de la línea»). **Contradicha** por las genéricas de offlane (Ace@0:00-2:00, BSJ@1:01-4:00: evitar intercambios) | `Action_AttackUnit` (ya en `RuleTrade`) | DK ocioso (sin pegar a un héroe, vida ≥ 0,6, Lion a ≤ 900) con un rival a ≤ 700: **81 s en 17 episodios** [91 74 84 75]. Con ratio ≥ 1,2 y el rival a 450-900: ~55 lecturas | `fino` + `prop kill_eval` + `prop decision` |
| B | Creep a distancia, de bandera o de asedio que el ataque no asegura → Breathe Fire para rematarlo | DK 4 (SH@1:01, Tor@3:00, Sky@2:00; +2 viejas) | `GetNearbyLaneCreeps`, `GetActualIncomingDamage`, `Action_UseAbilityOnLocation` (como `luna.lua` `FarmCast`) | ~19 creeps a distancia por partida en su línea (557 s en línea / 30 s por oleada); el DK remata **6,5**, lo intenta 10 veces y decide `preparar_golpe` sobre ellos 21,5 veces | `prop golpe`/`golpe_res`, `prop decision` |
| C | El rival puede castigar el paso al creep → no subir a negar | DK 5 (Ace@3:01, BSJ@5:00-6:02; también «ni a rematar»); Luna 8 (B@2:00, 1 guía, mismo sentido) | `GetNearbyHeroes` (ya en `Perceive`) | **28,6 negaciones por partida con un rival a ≤ 700** (segura 14, difícil 14,6). Reciben daño de héroe en 3 s entre el 57 y el 92 % de las veces (79-196 de media), frente al 10-28 % sin rival. 10 muertes nuestras en los 10 s siguientes en 4 partidas. Aciertan solo el 29-50 % | `prop golpe` + `fino` + `golpe` + `kill` |
| D | DK con poco maná → Soul Ring en las compras de línea y usarlo | DK 10 (Sky@1:01 y 3:04, SH@2:00, Tor@10:00, Bal@4:04) | `item_soul_ring` existe (OHA lo usa: `ability_item_usage_generic.lua:6660`); compra y `usar_objeto` como la varita | DK con maná < 0,25 en el **26 %** de las muestras de línea (~140 s) [21 15 45 24]; 14 Breathe Fire por partida frente a 23,3 de OHA | `prop estado`, `prop habilidad` |
| E | Luna contra una línea de magia → Infused Raindrops antes de Treads | Luna 15 (P@7:02, C@21:01 y 35) | `item_infused_raindrop` (en las listas de OHA, `aba_item.lua:153`); pasivo, solo compra | Luna recibe **4.479 de daño mágico** por partida frente a 2.016 de ataques: 62 instancias de hechizo, ~18,5 de 75 o más (aprox.: daño/número por segundo) | `golpe` |
| F | Sniper con Shrapnel cargado y la oleada enemiga en el centro → Shrapnel sobre la oleada | Sniper 5 (7evddXA3xT0@2:01, h7TG8u_jzHA@3:01) | `Action_UseAbilityOnLocation` | ~24 oleadas por partida en el centro | cuenta de oleadas (sin línea propia) |
| G | Apoyo con vida alta y el rival a tiro → clic derecho y hechizo de acoso | Lich 2 (DzL, JzQ, poPC, KJic), Lion 3 (DP, SH) | `Action_AttackUnit` | Lich ocioso con un rival a ≤ alcance + 100: 36 s en 11 episodios; Lion, 31 s en 12 | `fino` |

**F y G cumplen la firma, pero quedan fuera del paquete:**
- **F:** el centro no es una brecha. El Sniper ya va por delante (2.930 de daño de ataque, y la mejor línea).
- **G:** contradice lo medido. El diagnóstico de `p4a` vio que 14 de 31 muertes de la segura venían de presionar, y la difícil ya iguala el daño de ataque de su rival (Lion 1.415, Witch Doctor 1.628).

Quedan para cuando se extrapole.

### Descartadas (una línea cada una)
- **Tirar aggro para negar el creep a distancia, aggro defensivo y atraer la oleada** (DK 1 y 2, Luna 6): que la orden de ataque de un bot arrastre a los creeps no está verificado en el banco. Antes hace falta una sonda.
- **Tirar o apilar campamentos** (Luna 7, Lich 9, Lion 13, DK 18, Sniper 7 y 8): el momento y el arrastre de los neutrales con la API no están verificados, y es un comportamiento nuevo y grande.
- **Bloquear la oleada al empezar** (DK 3): mecánica no verificada, y una sola vez por partida.
- **Centinela en el campamento** (Lich 8, Lion 12): OHA nunca tira de campamentos, así que la situación no se da (0).
- **Runas de recompensa, sabiduría y poder** (Lich 18 y 19, Lion 20): defecto conocido, el bot no recoge runas.
- **Rotar con el portal** (Lich 17, Lion 19): las rotaciones están apagadas (DECISIONES 2026-11-04) y no son de la línea que se mide.
- **Lotos** (DK 16, Lich 16, Lion 18): la API no tiene función para ellos.
- **Sacrificio de Lich** (Lich 12): no está en el volcado (`docs/api/volcado.md`).
- **Luna a los campamentos desde el nivel 5** (Luna 18): deja sola a su apoyo y es medio juego (fase 3). Fuera del alcance del piloto.
- **Agresivo con ventaja de nivel** (Lich 13, la parte de nivel de Lion 17 y Luna 9):
  - abrir con 2 niveles o más de desventaja no muere más (9 % frente al 13-22 % en paridad);
  - ir por delante en nivel no se da casi nunca (1 de 85 aperturas).
- **2 contra 2 solo con ventaja de vida** (Lion 17, Lich 4, Luna 9):
  - situación infrecuente: 4 aperturas en 4 partidas con la pareja 0,3 o más por debajo en vida sumada;
  - mata: 3 de esas 4 acabaron en muerte nuestra, frente al 8 % en paridad;
  - queda anotada para un paquete de la segura.
- **Mucha regeneración y tangos** (Lich 1, Lion 14, Luna 21): ya se cumple (9-14 salvias repuestas por partida para Luna, DK y Lich, 2-12 para el Lion, y claridades).
- **Mango o claridad con poco maná** (Lich 14): la claridad ya se repone, y el Lich pasa poco tiempo con poco maná (9 % de las muestras).
- **Mana Drain** (Lion 4): el Lion pasa con maná < 0,25 solo el 2,5 % de las muestras.
- **Ya cumplidas en el código** (verificado):
  - Lion: Spike al suelo (5), cadena Spike, Hex y Finger (6), kill con la pareja (8);
  - Lich: escudo al atacado (5), posición junto al núcleo (6), no dejar la línea (7);
  - órdenes de habilidades (DK 9, Luna 1 y 2, Sniper 1 y 2, Lich 21);
  - Bracer y varita (DK 11 y 12, Sniper 14) y maná para el stun (DK 19);
  - Luna: esperar al apoyo (10) y Beam de acoso (5);
  - Breathe Fire con su reducción (DK 8) y Sniper fuera de alcance (11 y 13).
- **Rematar cuerpo a cuerpo para cargas de Finger** (Lion 9): el Lion es a distancia, y las cargas no pesan antes del min 12.
- **Elder Dragon Form al 6 para la torre** (DK 20): como mucho 2 veces antes del min 12; su fin, la torre, no es de la línea medida, y trae riesgo de meterse bajo la torre.
- **Botas primero en línea dura** (DK 13): las Treads ya van segundas, y no hay situación que medir.
- **Quedarse en la línea** (DK 6): va dentro de la regla A; sola, es vaga.
- **Línea imposible y controlar su zona tras una kill** (DK 14 y 17): infrecuentes, o del medio juego.
- **Retoques de la build de Luna** (12, 13 y 16): sin situación medible en la línea, y la varita ya está.
- **Elegir a quién presionar** (Lich 3): la carrera ya elige el objetivo.
- **Ultimate del Sniper solo con kills a la vista** (Sniper 3): orden de subida, sin efecto medible al min 12.

## 2. Paquete propuesto: `guias1`, 5 reglas, por peso esperado
Todas tras una bandera de variante (`Variant.guias1`), como el paquete 4.

### 1. El DK presiona desde más lejos (regla A). Peso alto: ataca la brecha medida del daño de ataque del DK.
- **Qué cambia:**
  - `heroes.lua`, `R.ALCANCE.cuerpo`: nuevo `presionaDesde = 550`. El que va a distancia sigue con los 300 de `K.pressReach`.
  - `linea.lua`, `RuleTrade`: con `guias1`, la condición `d <= p.range + K.pressReach` usa ese alcance por tipo, solo para un núcleo cuerpo a cuerpo con vida ≥ 0,6.
  - El resto de condiciones no cambia: ratio ≥ 1,2, nada que rematar en 2 s, sin torre enemiga y compañero cerca.
- **Si la referencia es `control_equipo` (sin paquete 4):** la regla trae también la presión en pareja (`pairPress`) solo para este héroe; sin ella, el DK no presiona en una línea de dos.
- **Por qué 550:** sale del registro, no de afinar. Las ~55 lecturas perdidas por partida están entre 450 y 900. Con 550 el alcance llega a 700, unos 1,8 s de camino a 310 de velocidad.
- **Situación:** DK ocioso con un rival a ≤ 700, 81 s por partida.
- **Métrica de mecanismo:**
  - daño de ataque del DK a héroes, t 0-720: de 1.197 (A) o 701 (B) a **≥ 1,5 veces el del brazo de referencia y ≥ 1.600**;
  - segundos ociosos con un rival a ≤ 700: de 81 a **≤ 55**.
- **Riesgo:** más exposición del DK. Por eso su salvaguarda: muertes de la difícil.

### 2. Breathe Fire remata el creep a distancia (regla B). Peso medio: oro y nivel del DK.
- **Qué cambia:** `dragon_knight.lua`, nuevo `H.FarmCast`. `linea.lua` ya lo llama antes de `RuleLastHit` (`linea.lua:834`), como a Luna y Lich.
- **Cuándo lanza:**
  - sobre un creep enemigo a distancia, de asedio o de bandera dentro del alcance del lanzamiento;
  - si la llama lo mata (`GetActualIncomingDamage` mágico ≥ su vida) y el ataque no llega a tiempo (más allá de `p.range + 80`, como Luna);
  - guardando el maná de Tail y de la forma (`ManaToKeep`), y no a menos de 1 s de otra llama.
- **Situación:** ~12 creeps a distancia perdidos por partida (19 frente a 6,5 rematados).
- **Métrica de mecanismo:**
  - remates del DK a creeps a distancia o de bandera: de 6,5 a **≥ referencia + 2,5**;
  - últimos golpes del DK en t=720: de 23-25 a **≥ referencia + 3**.

### 3. No negar con un rival a tiro (regla C). Peso medio: vida y muertes en las dos líneas, sobre todo la segura.
- **Qué cambia:**
  - `linea.lua`, `RuleLastHit`: con `guias1` y en una línea de dos (`p.dos`), la rama de negar salta el creep si un héroe enemigo visible está a ≤ 700 del punto desde el que se pegaría (`StandFor`);
  - una línea de registro por segundo: `negar descartado: rival a N`.
  - Los remates siguen: aciertan el 59-80 % y dan oro.
- **Ajuste del agente:** las guías dicen «ni negar ni rematar» cuando la oleada empuja hacia ti. Me quedo con negar porque el registro lo separa: el remate con rival cerca acierta y paga, la negación no.
- **Situación:** 28,6 negaciones con rival a ≤ 700 por partida, 10 muertes en los 10 s siguientes en 4 partidas.
- **Métrica de mecanismo:**
  - negaciones intentadas con un rival a ≤ 700: de 28,6 a **≤ 5**;
  - daño de héroes recibido por la segura (Luna + Lich), t 0-720: de 11.190-12.853 a **≤ 0,9 veces la referencia**.

### 4. Soul Ring para el DK (regla D). Peso medio-bajo: sostiene las reglas 1 y 2, que gastan maná.
- **Qué cambia:**
  - `compras.lua`, como `WithWand`: con `guias1`, `item_soul_ring` justo después del Bracer;
  - `linea.lua`, `Decide`, junto a la varita, intención `usar_objeto` si se cumple todo esto:
    - vida ≥ 0,6 y maná < 0,5;
    - un rival de su línea visible a ≤ 1.200, para que el maná temporal se gaste;
    - sin retirada en curso, ni mudo ni hexeado, y no más de una vez por enfriamiento.
  - Como la regla de OHA: en línea, vida > 0,5 y maná < 0,5.
- **Antes de programar:** leer en `items.txt` de 7.41f el coste en vida, el maná y la duración.
- **Situación:** maná < 0,25 en el 26 % de las muestras.
- **Métrica de mecanismo:**
  - muestras del DK con maná < 0,25: de 18-35 % a **≤ 15 %**;
  - Breathe Fire lanzados: de 12-14,5 a **≥ referencia + 4**.
- **Coste:** retrasa las Treads lo que cuesta el anillo.

### 5. Infused Raindrops para Luna (regla E). Peso bajo: muertes de la segura.
- **Qué cambia:** `compras.lua`, como `WithWand`: con `guias1`, `item_infused_raindrop` tras la Wraith Band y antes de las Treads, en las tres alineaciones (todas llevan magia en la segura: Vengeful, Jakiro y Skywrath).
- **Antes de programar:** leer en `items.txt` de 7.41f el umbral, el bloqueo, las cargas y el enfriamiento. No los doy por sabidos.
- **Situación:** 4.479 de daño mágico por partida sobre Luna.
- **Métrica de mecanismo:** daño mágico recibido por Luna, t 0-720: de 4.235-4.723 a **≤ referencia − 500**.

**Antes de programar:** la revisión adversarial de Opus (firma) recibe este paquete, la firma literal y las frecuencias. Que mire sobre todo:
- la contradicción de la regla 1 con las guías genéricas;
- el estrechamiento de la regla 3.

## 3. Diseño de la medición (como el paquete 4)
- **Variante nueva `control_equipo_g1`** (`tools/bench/orquestador.mjs`; es zona roja, se revisa antes de usarla):
  - si gana `control_equipo_p4`: `{ control_completo: "luna,sniper,dragon_knight,lion,lich", linea_heroe: "sniper", paquete4: true, guias1: true, empuje: false, thinkless: 1 }`, y la referencia es `control_equipo_p4`;
  - si gana `control_equipo`: lo mismo sin `paquete4`, y la referencia es `control_equipo` (la regla 1 lleva entonces la presión en pareja del DK).
- **Brazos:**
  - A, `control_equipo_g1` (`g1a-<x>`), y B, la referencia (`g1b-<x>`);
  - los dos con `--rival dotabot --variantes <brazo>,base --modo turbo --observar --corte 12 --heroes luna,sniper,dragon_knight,lion,lich/<alineación>`;
  - 2 partidas por invocación, con cambio de lado.
- **Orden ABBA por alineación:**
  - a: A y B;
  - b: B y A;
  - c: A y B.
  - En total, 12 partidas al min 12, en la misma tanda y con el mismo código.
- **Alineaciones:** las de MEDICIONES 2026-11-13:
  - a: sven, viper, bristleback, vengefulspirit, witch_doctor;
  - b: juggernaut, lina, axe, jakiro, crystal_maiden;
  - c: phantom_assassin, razor, tidehunter, skywrath_mage, oracle.
- **Antes de la tanda:**
  1. **Análisis fijo:** una sección «Paquete de guías» en `tools/analisis/linea-dos.mjs` con las métricas M1 a M6, escrita y revisada antes de usarla (la lógica está en `base.mjs` del scratchpad).
  2. **Valores de referencia:** recalcular con las 12 de `p4r2` del brazo que gane y anotarlos en MEDICIONES.
  3. **Predicción** escrita en MEDICIONES.
  4. **Humo `g1-humo`** (2 partidas, alineación a, carga anotada). Pasa si cumple todo esto:
     - 0 `prop error`;
     - el DK presiona a más de 450 al menos 5 veces por partida y `breathe_fire remata` al menos 3;
     - salen las líneas `negar descartado`;
     - el Soul Ring se compra y se usa al menos 3 veces;
     - las Raindrops se compran antes de las Treads.
  5. **Revisor adversarial** de la medición.
- **Lectura:**
  - `linea-dos.mjs "g1a-.*"` frente a `"g1b-.*"`;
  - `node tools/bench/equipo.mjs "g1a-.*" "g1b-.*" --t 720`;
  - cada tanda se revisa por `prop error` antes de leerla.
- **Decisión:**
  - **cumple** si se cumplen M1 y al menos 3 de M2 a M6, y la salvaguarda;
  - si no, ronda 2 (la última) solo con causas leídas en el registro;
  - una constante cambia solo por un fallo de regla visto (DECISIONES 2026-11-06).

## 4. Predicción numérica (A − referencia, por partida, t 0-720)
Referencias de hoy, con 2 partidas por brazo y solo la alineación a: «A» es `control_equipo_p4` y «B» es `control_equipo`.

| Métrica | Hoy (A / B) | Predicción para `control_equipo_g1` |
|---|---|---|
| M1 (principal): daño de ataque del DK a héroes | 1.197 / 701 | ≥ 1,5 veces la referencia y ≥ 1.600 |
| M2: segundos del DK ocioso con un rival a ≤ 700 (vida ≥ 0,6, Lion a ≤ 900) | 82,5 / 79,5 | ≤ 55 |
| M3: remates del DK a creeps a distancia o de bandera | 7,5 / 5,5 | ≥ referencia + 2,5 |
| M3b: últimos golpes del DK en t=720 | 23 / 25 | ≥ referencia + 3 |
| M4: negaciones intentadas con un rival a ≤ 700 (las dos líneas de dos) | 28,5 / 28,5 | ≤ 5 |
| M4b: daño de héroes recibido por la segura | 12.853 / 11.190 | ≤ 0,9 veces la referencia |
| M5: muestras del DK con maná < 0,25 | 18 % / 34,5 % | ≤ 15 % |
| M5b: Breathe Fire lanzados | 14,5 / 12 | ≥ referencia + 4 |
| M6: daño mágico recibido por Luna | 4.723 / 4.235 | ≤ referencia − 500 |
| Nivel del DK menos el del pos 3 de OHA, t=600 (descriptivo) | −3,5 / −3,5 | ≥ referencia + 0,5 |
| Kills de la difícil sobre sus rivales (descriptivo) | 2,0 / 0,5 | ≥ referencia + 0,5 |
| Muertes de la difícil (vigilancia de la regla 1) | 6,5 / 4,5 | ≤ referencia + 1 |
| Muertes de la segura | 6,0 / 6,5 | ≤ referencia |
| Salvaguarda `equipo.mjs`: diferencia de kills del equipo | — | no peor que −3 |
| Salvaguarda `equipo.mjs`: muertes por línea | — | no más de +2 |

Con 6 partidas por brazo, la diferencia mínima que detecta el equipo es de unas 7 kills: solo avisa, no decide.
