# Plan de mejora del equipo propio (propuesta para la firma de Pedro)

Encargo (Pedro, 2026-11-13): «con sub agentes analiza que sucede en cada linea y pulelos hasta que ganen en todo a OHA, parte del
comportamiento debe definirse por linea/rol y otra por heroe y tenemos que tenerlo medido con muchisima precision para saber que cosas se
corrigen y mejoran [...] el objetivo final es que el equipo de bot propio gane con sobra a OHA». Base: los humos de la fase 2
(MEDICIONES 2026-11-13) y tres análisis de agentes sobre sus registros (línea segura, línea difícil, medición). Se borra cuando se
cierre, y `trabajo/fase2.md` se cierra con él.

## Lo que muestran las líneas (medido, n=2 por lado, descriptivo)
- **Línea segura** (Luna + Lich contra Bristleback + Vengeful):
  - kills en la línea hasta el min 12: 0 y 0, frente a 7 y 5 de OHA;
  - muertes: 7 y 9, frente a 3-5;
  - Luna en nivel 7 al min 10, frente a 9-13.
  - 8 de las 16 muertes llegan unos 2 s después de un ataque propio en solitario con el segundo rival cerca. Otras llegan al volver a la línea con 0,4 de vida.
- **Línea difícil** (Dragon Knight + Lion contra Sven + Witch Doctor):
  - el frente queda junto a la torre propia; con OHA, en el medio de la línea;
  - Lion muere 4-5 veces, siempre igual: Earth Spike de acoso sola, respuesta del rival, vaivén entre alejarse y volver, y retirada a 0,3 de vida;
  - entre 111 y 162 s caminando a la fuente.
  - Lanzamientos del propio frente a OHA: Dragon Tail 1 y 13, Hex 1 y 8-10. OHA mata con ataques sincronizados: Breathe Fire y Earth Spike en el mismo segundo, luego Tail y Hex.
- **Mid:** el Sniper va por delante de OHA (50 últimos golpes frente a 40).
- **Causa común:** las reglas de la línea se hicieron para el 1 contra 1 del Sniper.
  - La kill solo cuenta al aliado que ya está pegando: `aliados=0` en el 97 % de las evaluaciones, así que nunca se empieza una kill en pareja.
  - El intercambio no suma al compañero.
  - La retirada no tiene histéresis y no sale del alcance de los hechizos enemigos.

## Arquitectura: tres capas de comportamiento
1. **Línea y rol** (código común, una vez para todos):
   - dónde se coloca cada rol;
   - cuándo retirarse y cuándo volver;
   - intercambio y presión contando a todos los de cada lado;
   - kill en pareja: daño y bloqueos del compañero, y lanzar juntos cuando uno abre;
   - qué hace un apoyo: dejar los últimos golpes, proteger al núcleo, regenerar maná, volver por TP.
   
   Parámetros por rol (`nucleo`, `apoyo`) y por posición, en un solo sitio.
2. **Héroe** (su módulo): qué habilidad abre, bloquea, remata o protege, su reserva de maná y su build. Expone lo que la capa 1 necesita: cuánto daño y cuántos segundos de bloqueo tiene listos.
3. **Equipo** (fase 3, después): medio juego, torres y peleas de cinco.

Cada regla lleva su motivo en el registro, para separar en el análisis qué capa produjo cada muerte o kill.

## Medición (diseño del agente de medición, con el ruido medido en 46 partidas)
- **Cara a cara contra el equipo de OHA:** `--rival dotabot --variantes control_equipo,base_sniper`.
  - Los dos brazos se intercalan en la misma tanda, con cambio de lado.
  - Nuestros cinco héroes fijos, y 3 alineaciones rivales fijas: un resultado no puede depender de una sola.
  - Nada de referencias congeladas: el mismo código dio 199 y 162 últimos golpes en tandas distintas.
- **Corte en el min 12 para las líneas,** con lectura en los min 5, 10 y 12. El min 25, para el medio juego.
- **Análisis fijo** (`tools/analisis/equipo.py`, escrito y revisado antes de usarlo):
  - por héroe: nivel, patrimonio, últimos golpes, negaciones, kills y muertes;
  - por línea: diferencias frente a sus rivales, daño hecho y recibido, tiempo en la línea, muertes tras un ataque propio en solitario;
  - por equipo: kills y patrimonio.
  - Diferencia entre los brazos emparejada por alineación y lado, con IC 95 % y la diferencia mínima detectable al lado.
- **Precisión:**
  - con 8 partidas por brazo se ven diferencias de unos 1,4 DE: Luna ±2 niveles, línea segura ±3,1k de patrimonio;
  - con 16, de 1 DE: ±1,4 niveles por héroe, ±2,2k en la línea segura y ±3,6k en la difícil.
  - Las brechas de hoy (15 kills, 7k en la línea segura, 4 niveles de Luna) se ven con 4-8 por brazo; cerca de la paridad hacen falta 16.
- **Una vez, antes de todo:** A contra A (`base_sniper` contra `base_sniper`) con 16 partidas, para medir el ruido real de esta alineación en vez de suponerlo.
- **Puerta de cada paquete:**
  - métrica principal y valor predicho, escritos antes;
  - humo cotejado y revisor adversarial de la medición;
  - n calculado con la tabla del ruido.
  - Como mucho 2 rondas de mecanismo, y una constante solo cambia por un fallo de regla visto en el registro (DECISIONES 2026-11-06).

## Paquetes, en orden (cada uno con sus causas leídas)
1. **Sobrevivir en la línea de dos** (capa 1). Métrica principal: muertes en la línea hasta el min 12 (hoy 7-9 en la segura y 4-5 de Lion).
   - Retirada con histéresis: no vuelve hasta 0,65 de vida o tras usar salvia.
   - Fuera del alcance de los hechizos enemigos, contando el daño en el tiempo.
   - Nada de ataque ni habilidad de acoso en solitario si los rivales cerca superan a los aliados cerca.
   - TP de vuelta en vez de caminar.
   - Clarity y pausa entre lanzamientos para los apoyos.
   - Para el cuerpo a cuerpo: soltar el aggro solo con poca vida, y contestar con habilidad cuando no llega a golpear.
2. **Matar en pareja** (capas 1 y 2). Métrica principal: diferencia de kills en las líneas de dos hasta el min 12 (hoy 0 frente a 5-7 de OHA).
   - La kill suma el daño y los bloqueos del compañero cercano.
   - Cuando uno abre con un bloqueo (Spike, Tail, Frost Blast o Beam), el otro entra con su combo en el mismo segundo.
   - Presionar en 2 contra 2 cuando la suma de las parejas lo da.
3. **Héroes** (capa 2). Métrica principal: nivel y patrimonio por héroe al min 10, frente a su par de OHA.
   - Lion: Hex para proteger y abrir, Mana Drain.
   - Dragon Knight: Tail.
   - Luna: reserva de maná del Beam y Quelling Blade.
   - Lich: Sinister Gaze, y el escudo antes de la ráfaga, no en medio.
   - Builds comparadas con las de OHA.
4. **Medio juego del equipo** (min 25): que lo ganado en la línea no se regale. Rotaciones, agrupación y torres, y el cerebro de equipo de la fase 3.
5. **Final:** 24 partidas completas cara a cara. «Gana con sobra» = 18 o más de 24 (75 %; p ≈ 0,01 frente al 50 %).

**Cuándo juega Pedro:** cuando las líneas estén a la par o mejor que OHA (tras el paquete 2 o el 3), y al final. Así su tiempo va
a una versión con una mejora plausible (DECISIONES 2026-11-08).

## Tiempo de máquina (ningún gasto de pago; la PC de Pedro)
| Tramo | Partidas | Tiempo |
|---|---|---|
| A contra A, una vez | 16 al min 12 | ≈ 1,8 h |
| Cada ronda de mecanismo | 8 + 8 al min 12 | ≈ 1,8 h |
| Serie de confirmación de un paquete | 16 + 16 al min 12 | ≈ 3,5 h |
| Final | 24 completas | ≈ 6-8 h |

Los humos cortados corren con la carga anotada (DECISIONES 2026-11-04 y 2026-11-05). Las series y la final piden la máquina libre,
o tu palabra para correrlas con la carga anotada.

## Lo que pide la firma
- Las tres capas y este orden de paquetes.
- El sistema de medición: cara a cara intercalado, 3 alineaciones, A contra A y análisis fijo con IC.
- El criterio final: 18 o más de 24.
- Que juegues tras los paquetes 2 o 3 y al final, no tras cada uno.

## Avance
- 2026-11-13, A contra A: 24 partidas. El banco y el análisis aguantan, y queda la tabla de ruido (MEDICIONES).
- 2026-11-13, paquete 1: 2 rondas, no cumple. Su arreglo de la retirada que cruzaba el mapa a pie se queda.
- 2026-11-13, paquete 2: 2 rondas, no cumple. En el registro los mecanismos funcionan (menos retiradas que cortan, sin falsos `objetivo_muerto`, más kills cerradas en la persecución), pero las líneas de dos siguen unos 5 kills y 4-5 niveles por detrás, y la línea segura muere más.
- **Cambio de orden (Pedro, DECISIONES 2026-11-13):** antes del paquete 3, estudiar lo que hace OHA en las líneas de dos y reescribir de cero la capa de línea y rol para 2 contra 2:
  - se registran sus modos y decisiones como datos, no como base;
  - dónde se coloca cada rol, cuándo entra, cómo encadenan habilidades y cuándo se van.

## Estudio de OHA en las líneas de dos (2026-11-13, MEDICIONES `oha-dos-*`)
Datos de 12 líneas de dos de OHA (6 partidas al min 12, los dos equipos), con el registro fino y `tools/analisis/linea-dos.mjs`.
Son la especificación de la reescritura, no su base: se copia lo que gana y se corrige lo que pierde.

**Lo que gana (la pareja de la difícil, en las 12 líneas):**
- juntos, a unos 600-700 uno del otro, y de 100 a 400 por delante de su ola;
- entran los dos con la vida llena: los dos pegan en el 78-95 % de las peleas que acaban en kill;
- la primera habilidad de cada uno sale con 1 s de diferencia;
- abren con un control o una ráfaga: DK y Lion encadenan Breathe Fire con Earth Spike, y después Tail, Hex y Finger;
- persiguen: una pelea con kill dura unos 15-21 s.

**Lo que pierde (la segura de OHA, 9,2 muertes por línea):**
- muere con la vida alta (90 % 10 s antes), frente a 2 rivales y sin aliado a 1200;
- en el 60 % de los casos había pegado a un héroe justo antes, y casi siempre muere ya en RETREAT;
- Luna y Lich se separan (unos 900 en la línea, 5000 al empezar sus peleas con kill).

**Lo que pide la capa nueva, en orden:**
1. La pareja como unidad:
   - el apoyo sigue al núcleo a unos 600;
   - no se pega a un héroe si el compañero no está a 800 o menos y con vida.
2. Entrar juntos y no a medias:
   - una entrada la decide la pareja (daño y bloqueos de los dos frente a la vida de un rival);
   - los dos lanzan en el mismo segundo y siguen la persecución.
3. Salir antes, no durante:
   - si el rival entra con los dos y la suma no da, la pareja se va a la vez, antes del primer golpe recibido, y no a 0,3 de vida;
   - el registro de OHA muestra que la retirada en mitad de la ráfaga ya no salva.
4. Volver con TP con poca vida, como OHA.

**Avance:**
- 2026-11-13, capa de la línea de dos (`dos.lua`, rondas `dos1` y `dos2`): no cumple. La segura muere menos (de 8,8 a 5,8), pero la pareja no mata (0,5-0,7 kills por línea) y la difícil pierde farm.
- La sombra (`linea-dos.mjs --sombra`) confirma la regla de entrada en OHA: mata con «nuestro» ≥ 1,2, «suyo» ≤ 0,6 y la pareja a 530-710. Nuestros héroes leen «suyo» cerca de 1,0-1,6: falta nivel y daño, que es el paquete 3 (Pedro, DECISIONES 2026-11-13).

**Herramienta:** el mismo análisis lee los brazos del bot propio, y cada versión se compara con `oha-dos-*` en estas métricas. La medición que decide sigue siendo `equipo.mjs`.
