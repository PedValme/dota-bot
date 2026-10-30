# Cerebro de equipo: diseño para aprobar

Pedro, 2026-10-30: «quiero que postulemos una mejor cuantiosa basada en argumentos solidos y mejoremos», con criterio de
juego en profundidad y no solo timings y oro (DECISIONES 2026-10-30). Este documento es la propuesta. Nada está
construido; se construye con tu visto bueno y se mide **una sola vez**, al final.

Base argumental: [docs/mapa.md](../docs/mapa.md) (25 partidas observadas), la serie `remate-ab`,
[datos de 119 partidas profesionales](../docs/investigacion/2026-10-30-datos-pro.md) y el
[catálogo de criterio de juego](../docs/investigacion/2026-10-30-criterio-de-juego.md).

## 1. Por qué un cerebro y no más ajustes

**El bot ya gana el cuerpo a cuerpo y pierde la estrategia.** Contra los bots de Valve ganó 20 de 25 partidas, pero:

| | Profesionales (normal) | dota-bot (Turbo imitado) |
|---|---|---|
| Minutos desde +10.000 de oro hasta el final | 7,5 (mediana) | 13-22 |
| Quien llega primero a +10.000 pierde | 4 % | 1 de 25 partidas con +18.000 |
| Cuarteles perdidos yendo por delante | 6 % de los cuarteles caídos | 2 de 12 partidas con empuje en grupo |
| Torres tras ganar una pelea | 38 % de las T3 caen en los 90 s siguientes | sin coordinar (cada bot decide solo) |
| Tras matar a Roshan | 2 torres en 5 min (mediana) | Roshan sin plan de después |

**La causa es estructural, no un número mal puesto** (todo leído en el código):
- OHA no tiene `team_desires.lua`: el motor lo busca y no lo encuentra. Cada bot decide solo con umbrales sueltos
  (no farmear con +6.000, tope de empuje 0,41…).
- La defensa se apaga en todas las líneas en cuanto 3 aliados empujan juntos (`FunLib/aba_defend.lua:~915-937`), y su
  modo pánico solo cuenta héroes, no creeps. Así cayó la base de la partida 17 ante megacreeps yendo +18.000.
- La recompra de emergencia por el Ancient nunca se dispara: compara la vida absoluta con 0,8
  (`ability_item_usage_generic.lua:569`).
- «Somos más fuertes» (`J.WeAreStronger`, `jmz_func.lua:4734`) ignora cooldowns, maná y enemigos en niebla. De ahí
  cuelgan la retirada, la defensa y si se queda a pelear.
- Las ultis de iniciador (Ravage, Black Hole, Chrono, Reverse Polarity) esperan a que la pelea ya haya empezado
  (`J.IsInTeamFight`, `jmz_func.lua:1452`). Los stuns no se encadenan por tiempo restante (solo Mirana lo mira) y
  ninguna ulti se coordina con la de un aliado.

Por eso cada parche arregla algo y rompe otra cosa: el empuje en grupo agrupó a los bots (del 9 al 34 % del tiempo) y
dejó la base sin defensa, porque defender y empujar los decide cada bot por su cuenta.

## 2. Qué es

- **`bots/team_desires.lua`**: el motor lo llama una vez por frame, antes que a los bots. Allí el cerebro lee el
  estado de la partida y escribe **un plan de equipo**: estado, línea objetivo, punto de reunión, objetivo de foco y quién
  defiende.
- **Los modos de cada bot obedecen el plan**: push, defend, farm, team_roam y retreat consultan el plan antes que sus
  umbrales propios. Además, el cerebro fija los deseos de equipo del motor (`UpdatePushLaneDesires`,
  `UpdateDefendLaneDesires`, `UpdateRoshanDesire`), que mueven los modos que OHA deja a Valve (retreat, roshan, attack).
- **Viable, comprobado en el juego** (sonda del 2026-10-30): un módulo cargado con `require` desde `team_desires.lua`
  comparte estado en vivo con los bots del mismo equipo.
- **Va primero como variante del benchmark** (apagada en el juego normal). Se enciende por defecto solo si la serie final
  lo justifica y tú lo apruebas.

## 3. Qué decide el cerebro

### 3.1 Estados del plan (uno por equipo, con histéresis para no oscilar)

| Estado | Cuándo (reglas con su fuente) | Qué hace el equipo |
|---|---|---|
| **DEFENDER** | Prioridad absoluta: héroes **o creeps** atacando T3, cuarteles o Ancient propios, vayamos como vayamos [datos: un equipo por delante casi nunca pierde cuarteles] | Los más cercanos (o todos, según la amenaza) defienden; recompra si el Ancient peligra |
| **LÍNEA / FARM** | Fase de línea, o sin ventaja clara | Como hoy: cada uno su línea y su farm; el pos 5 apila campamentos |
| **AGRUPAR → EMPUJAR** | Ventaja clara de pelea (`EvaluarPelea`, 3.2) y de patrimonio [datos: con +5.000 se gana el 85 %, con +10.000 el 96 %] | Reunirse en el punto de la línea objetivo **antes** de empujar, y empujar los cinco juntos |
| **TOMAR TRAS PELEA** | Pelea ganada: enemigos muertos con tiempo de reaparición largo [datos: 38 % de las T3 caen en los 90 s siguientes] | Ir de inmediato a la torre o Roshan más valiosos en esa ventana; salir antes de que reaparezcan |
| **ROSHAN** | Ventaja de pelea y enemigos lejos o muertos [datos: quien mata a Roshan va por delante el 78 % y gana el 79 %] | Roshan juntos y, con Aegis, high ground [datos: el 49 % de las primeras T3 se tiran con Aegis] |
| **CERRAR** | Ventaja grande (en profesionales, +13.000 al tirar la primera T3) o Aegis | Asalto al high ground por una línea; si no se rompe, retirarse a farmear y volver con la siguiente ventana, en vez de quedarse frente a la T3 |
| **ESPERAR** | Ultis clave en cooldown o un objeto clave (BKB, Blink) a punto | No forzar peleas; farmear cerca y juntos |
| **REAGRUPAR** | Pelea perdida o un aliado caído aislado [datos: solo el 6 % de esas muertes acaban en pelea, y el equipo del caído la gana el 41 %] | No vengar de uno en uno: retirarse a una torre, farmear la jungla propia y volver juntos |

Las cifras de los profesionales son de modo normal. Para Turbo se usan las **relativas** (ventajas, ventanas de
reaparición, números de héroes), no los minutos absolutos. OpenDota no analiza las partidas Turbo públicas: sí trae su
duración y sus objetos, que sirven para ajustar el ritmo.

### 3.2 Criterio de pelea (lo que pediste: no solo oro y tiempos)

- **`EvaluarPelea`** sustituye a «somos más fuertes». Cuenta quién llega en unos 8 s (incluidos los TP), las ultis
  aliadas listas, las ultis enemigas que vimos lanzar hace poco (inferimos su cooldown), BKB, Aegis, recompras, y
  descuenta a los enemigos que no vemos según cuándo los vimos por última vez.
- **Aliado cazado: salvar, ceder o contraatacar.** Se salva si llegamos a tiempo y `EvaluarPelea` es favorable con los
  que llegan. Si no, se cede (REAGRUPAR) y nadie entra de uno en uno. Se contraataca si el enemigo se expuso para
  cazarlo y tenemos ultis listas.
- **Reagrupar y farmear tras perder.** Se reúnen en una torre segura y farmean neutrales propios; el soporte apila
  campamentos; vuelven juntos cuando cambie la evaluación.
- **Encadenar disables sin pisarlos.** El siguiente stun se lanza cuando al anterior le queda menos que su tiempo de
  lanzamiento, no cuando ya terminó ni encima. Con el cerebro, cada objetivo tiene una cola de disables para que dos
  aliados no gasten el suyo a la vez.
- **Iniciar y rematar por fases.** Formar, iniciar (el que tiene Blink y un control de área entra primero) y seguir
  (daño de área, ultis de los demás). Se acaba con las ultis que hoy esperan a que la pelea «ya haya empezado».
- **Combos de ultis.** Una tabla por tipo: control de área (Black Hole, Ravage, Reverse Polarity, Chrono) seguido de
  daño de área. El iniciador espera unos segundos a que el que sigue esté en rango, y no tira Chrono encima de
  aliados.
- **Foco común.** Un objetivo por pelea, elegido por el cerebro (el soporte sin salvadas o el carry sin BKB, según
  convenga), en lugar de que cada bot elija el suyo.

## 4. Cómo lo construyo

Todo como una sola variante, `cerebro`, en este orden. Las partidas que juegue durante la construcción son pruebas de
humo para ver que no se rompe (una o dos, con `--observar`), no mediciones.
1. **Verificaciones de la API, en una partida observada**:
   - si se lee el tiempo restante de un stun en un enemigo visible;
   - si se ven los TP enemigos, el tiempo de reaparición de un enemigo muerto y la habilidad que está lanzando.

   De esto depende cuánto de 3.2 se puede hacer bien.
2. **Arreglos concretos**: defensa antes que «el equipo empuja», defensa contra creeps, recompra por el Ancient y
   encadenado de disables por tiempo restante en las funciones comunes. Son pequeños y van primero porque los
   necesita todo lo demás.
3. **El cerebro**: plan y estados (3.1), `EvaluarPelea`, DEFENDER, TOMAR TRAS PELEA, ROSHAN, CERRAR, REAGRUPAR y
   ESPERAR, y los modos obedeciendo el plan.
4. **Criterio de pelea**: aliado cazado, foco, iniciación por fases y combos de ultis.

Coste estimado: 2 o 3 sesiones de construcción, más las revisiones de Opus que pide el protocolo para el código del
bot. Si el punto 4 alarga demasiado, lo propongo para una segunda vuelta en vez de recortar el resto.

## 5. Cómo se mide (una vez)

- Una serie `base` contra `cerebro` en Turbo imitado, intercalada, con el observador: **24 partidas, unas 6 horas**,
  sin gasto de pago.
- Qué cuenta como mejora:
  - **cierre** desde +10.000 claramente más corto (hoy 13-22 min);
  - **0 bases perdidas** yendo por delante;
  - **empuje en grupo** alto;
  - victorias iguales o mejores.

  Con 12 partidas por variante, las victorias solo distinguen diferencias grandes; el cierre y las bases perdidas son
  las señales sensibles.
- Contra humanos no se puede medir automáticamente. La prueba con tus amigos en Local Host (Turbo real, draft de OHA) es
  la validación de verdad.

## 6. Riesgos y límites

- **Pasividad:** ESPERAR y REAGRUPAR pueden volver al bot tímido. Por eso tienen histéresis y tiempo límite.
- **Información oculta:** el bot no ve cooldowns ni recompras enemigas, ni héroes en niebla. Se infieren, y pueden
  fallar.
- **Datos de normal, no de Turbo:** los minutos no se trasladan; se usan relaciones y ventanas.
- **Contra Valve, la micro ya es buena:** el gran salto esperado está en cerrar y defender. Los combos y el encadenado
  rinden más contra humanos.
- **El capitán LLM (etapa 3 antigua):** encaja después, como quien elige el estado del plan en vez de las reglas.

## 7. Lo que decides

1. **Recomendado:** apruebas el diseño completo y lo construyo en el orden del punto 4, con una sola medición al final.
2. Apruebas sin el punto 4 (criterio de pelea fino) para una primera vuelta más corta, y lo añadimos después.
3. Cambios al diseño antes de empezar.
