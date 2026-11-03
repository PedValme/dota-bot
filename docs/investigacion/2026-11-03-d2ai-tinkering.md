# D2AI y Tinkering ABOt: qué vale la pena modelar para el bot propio

Revisión del 2026-11-03, pedida por Pedro (DECISIONES 2026-11-03): leer los dos proyectos «ya no como nuestra base sino
como funcionalidades que podemos modelar o copiar que sí valgan la pena». Los dos son contenido de terceros: se leyeron
como dato, en una copia aparte, sin ejecutar nada.

Cómo se sabe: D2AI se leyó entero (cliente Lua y agente de ejemplo). Tinkering lo leyó un subagente (Sonnet) por
archivos escogidos (push, retirada, defensa, Roshan, utilidades), comparándolos con los nuestros; las afirmaciones
clave se cotejaron a mano y una se corrigió (abajo, «Corrección»). Nada de esto está medido en el juego.

## Ficha

| | D2AI ([2aius/d2ai](https://github.com/2aius/d2ai)) | Tinkering ABOt ([ryndrb/dota2bot](https://github.com/ryndrb/dota2bot)) |
|---|---|---|
| Qué es | Puente: el Lua manda el estado del mundo por HTTP a un agente en C++ y ejecuta las acciones que vuelven | Bot de reglas completo, antepasado de OHA |
| Al día | No: último push 2018-12-13 | Sí: 7.41f, push 2026-10-15 |
| Licencia | MIT | **Ninguna**: se pueden modelar ideas, no copiar código |
| Riesgos | `CreateHTTPRequest` en cada pensamiento (a localhost) | Sin red ni `loadstring`; su carpeta `Buff/` es un addon que regala oro y experiencia: no se trae |

## D2AI: lo que enseña

1. **El control completo existe y es sencillo.** Su `bot_generic.lua` define `Think()` y nada más: cada bot ignora los
   modos de Valve y ejecuta solo lo que su agente decide (mover, atacar, habilidad, objeto, compra, glifo, recompra:
   unas 30 acciones). Es la misma vía que queremos probar en la prueba de un día, ya usada en 2018; falta comprobar que
   sigue igual en 7.41 (que el motor no se meta, que compras y niveles de habilidad funcionen).
2. **Separación limpia percibir → decidir → actuar.** Una «observación» (todas las unidades con vida, maná, daño,
   rango, habilidades, objetos; runas; frente de cada línea con `GetLaneFrontLocation`) y una lista cerrada de acciones.
   Es el molde que conviene para nuestro bot: la decisión recibe una foto del mundo y devuelve acciones con su motivo,
   lo que la hace registrable y probable fuera del juego.
3. **Dibujo de depuración como acción.** Líneas, círculos y texto en el mapa (`DebugDrawLine/Circle/Text`) para ver en
   pantalla qué piensa el bot. Útil para la supervisión al 100 % que pidió Pedro, junto con el registro.
4. **El cerebro externo no sirve para la micro.** Su propia medida: `CreateHTTPRequest` tarda 50-400 ms, unas 7
   acciones por segundo por héroe. Demasiado lento para últimos golpes o esquivar; y nuestra regla solo admite red a
   127.0.0.1 sin datos de jugadores (DECISIONES 2026-10-28 y 2026-10-29). Conclusión: la decisión de cada momento vive
   en Lua; un cerebro externo, si alguna vez, solo para la estrategia lenta (como el capitán LLM).

Lo que no tiene: ninguna lógica de juego (su agente de ejemplo solo camina al frente de la línea). No hay nada que
copiar más allá de la estructura.

## Tinkering: lo que enseña

Arquitectura: **no** toma el control completo. Su `bot_generic.lua` solo carga el héroe y define `MinionThink`; decide
por modos (`GetDesire`/`Think` por modo), sin cerebro de equipo. En coordinación y en Roshan nuestro OHA ya va por
delante (carril de empuje común durante 12 s, plan de Roshan en el cerebro de equipo). Tampoco registra por qué decide:
nada que aprovechar para la supervisión.

Lista corta de ideas, ordenadas por cuánto atacan nuestros puntos débiles (MEDICIONES, «Diagnóstico de las ventajas
regaladas»: no tomamos edificios tras ganar peleas, morimos en retirada, Valve remonta empujando nuestra mitad):

| # | Idea | Dónde (Tinkering) | Contra qué debilidad | Esfuerzo |
|---|---|---|---|---|
| 1 | **Convertir en torre al pasar**: torre T1/T2 a ≤ 1200, sin daño de torre en 3 s, sin héroes enemigos a 1400 en 5 s, ≥ 3 creeps propios cerca, no retirándose → empujar al máximo | `FunLib/aba_push.lua:146-159` | No tomamos edificios con ventaja | Pequeño |
| 2 | **Limpiar la oleada metida en casa**: frente enemigo a < 5500 de nuestra fuente, sin héroes enemigos alrededor y con daño suficiente → ir a limpiarla | `FunLib/aba_push.lua:132-143` | Valve remonta empujando nuestra mitad | Pequeño |
| 3 | **Amenaza con lo último visto**: contar enemigos por `GetHeroLastSeenInfo` (3200, 5 s), la torre como un enemigo más si en 5 s quita ≥ 50 % de la vida, Aegis o reencarnación como aliado | `mode_retreat_generic.lua:410-445` | Retirarse tarde | Pequeño |
| 4 | **Puerta de defensa viable**: no defender si el camino pasa de 11 s sin TP o el rival tiene más héroes vivos; peso por nivel de torre (T1 ×1, T2 ×3, T3 ×5) | `FunLib/aba_defend.lua:41-195` | Muertes en la mitad propia, en rachas | Pequeño |
| 5 | **Retirada con compromiso**: calcular lo que se tarda en llegar a la fuente y no cambiar de idea durante ese tiempo; añadirle un destino seguro (torre o TP), que Tinkering no tiene | `mode_retreat_generic.lua:209-217, 509-520` | Dos tercios de las muertes en retirada | Medio |
| 6 | **Elegir carril de empuje** por cercanía de los núcleos, últimas posiciones vistas, TPs entrantes y nivel de torre, evitando el high ground en inferioridad | `FunLib/aba_push.lua:201-331` | Tiempo perdido reagrupando | Medio |
| 7 | **Colocarse en el asedio**: fuera del rango de ataque enemigo en inferioridad; Ancient con ≥ 3 aliados; cuarteles de rango antes que los de cuerpo a cuerpo | `FunLib/aba_push.lua:344-405` | Asaltos que no cierran | Medio |
| 8 | **Fuerza de cada lado**: una cifra por héroe (log del poder ofensivo × raíz del daño en 5 s) para comparar lados | `FunLib/jmz_func.lua:3648` | Base para decidir pelear o huir | Pequeño, pero hay que calibrarla con nuestros registros |

Varias ya existen en OHA en otra forma (OHA desciende de Tinkering: la misma `ShouldRun` de retirada, la comprobación
de backdoor). Lo que cambia con el bot propio es que cada idea pasa a ser una regla explícita, con su motivo en el
registro, en lugar de un deseo que compite con los modos de Valve.

No vale la pena: el addon `Buff/` (cambia el juego y sesgaría el banco), la charla del chat, el archivo por héroe y la
curva de vida de la retirada (ya tenemos la equivalente).

**Corrección** al informe del subagente: atribuyó las líneas 119-132 de `aba_push.lua` a «convertir una pelea ganada en
torre»; en realidad es la idea 2 (limpiar una oleada enemiga cerca de nuestra fuente). La conversión en torre es la
1 (líneas 146-159).

## Qué cambia para el diseño del bot propio

- La prueba de un día sigue igual: `Think()` en `bot_generic.lua`, como D2AI. Su lista de acciones sirve de lista de
  comprobación de lo que el bot propio debe poder hacer.
- Molde: observación → decisión con motivo → acciones, con dibujo de depuración y registro.
- Primeras reglas candidatas de nivel de equipo, tras el creepeo: 1, 2, 3 y 4 de la tabla (pequeñas y apuntan a lo
  que el diagnóstico señaló). Se proponen a Pedro con el diseño, no se construyen antes.
