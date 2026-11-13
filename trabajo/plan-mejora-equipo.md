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
