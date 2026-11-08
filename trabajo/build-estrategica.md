# Build estratégica según los enemigos (diseño para la firma de Pedro)

Origen: DECISIONES 2026-11-08 («el build se arme estrategicamente considerando a los enemigos [...] debe poder extrapolarse a otros
heroes»). Dos agentes Opus, uno de diseño y otro adversarial, revisaron cómo hacerlo; esto junta lo que comparten y resuelve en qué
difieren. Se borra cuando el módulo esté hecho y medido.

## Lo que dicen los datos
- El Sniper de OHA compra Mask of Madness en el min 11 en 8 de 8 partidas, y entre los min 10 y 20 pega el doble por pelea (MEDICIONES
  2026-11-08). Es un objeto de ritmo del núcleo, no una respuesta al rival.
- Los datos de alto nivel no sirven para decidir: miden la popularidad por héroe, no frente a cada rival (`tools/datos/builds.mjs:60`),
  son 150 partidas de Captain's Mode y no Turbo, y su build del Sniper ni siquiera trae MoM (`bots/FunLib/data_builds.lua:98`).
  Además tienen sesgo de supervivencia: los objetos caros salen «ganadores» porque los compra quien ya va ganando.
- El bot solo sabe usar Blade/Silver Edge, Pike/Force, BKB y TP (`medio.lua`). Ya hoy compra Satanic y Mjollnir sin usar su activo.

## Diseño
1. **Núcleo fijo por héroe y rol**, medido y sin depender del rival. Sniper: Wraith Band, Treads de agilidad, Dragon Lance.
2. **Puntos de elección.** Pocos y en el límite entre objetos completos, nunca a mitad de uno; una vez comprada la primera pieza, se
   mantiene. Sin vender para cambiar.
3. **Reglas en orden, sin pesos.** En cada punto, candidatos ordenados; gana el primero cuya regla se cumple, y si no, el de por
   defecto. Así cada compra se explica con una frase («compro MKB porque Phantom Assassin tiene evasión») y no hay pesos que ajustar.
   El agente de diseño proponía puntuar con pesos; el adversarial lo descarta porque no se pueden calibrar con este ruido y choca con
   «sin vueltas de umbrales» (DECISIONES 2026-11-06). **Se elige el orden.**
4. **Etiquetas de amenaza por héroe enemigo**, compartidas por todos nuestros héroes: evasión, magia o control, invisibles, curación,
   saltan encima, ilusiones. Las genera una herramienta a partir de los archivos de datos de Valve (el mismo espejo que `docs/api`) y
   se corrigen a mano con su porqué. Todas quedan en Lua dentro del repo: el bot no hace llamadas de red.
5. **Lectura del rival.** Al inicio, los héroes elegidos. Durante la partida, los objetos vistos (Blink, Butterfly, Gem o Sentry). El
   daño real que ya aprende de cada rival sirve para saber cuál pesa más.
6. **Guardia de uso.** Un objeto con activo solo puede ser candidato si existe su regla de uso; el check lo comprueba. Con MoM entra su
   regla de Berserk, en `medio.lua`, junto a las de los demás objetos.
7. **Registro.** Al inicio, una línea `plan` con la build prevista contra los cinco rivales. Una línea por decisión, con la alternativa
   descartada, y otra cada vez que cambia una etiqueta.
8. **Otros héroes.** Lo genérico es el motor de reglas, las etiquetas, la guardia y el registro. Lo propio de cada héroe es un perfil con
   su núcleo y sus puntos de elección. Ejemplo, Lion: núcleo Tranquil Boots y Blink; luego Force Staff contra los que saltan encima o
   Glimmer contra mucha magia; detección si hay invisibles.
9. **Encaje.** Cambia de dónde sale la lista en `compras.lua`: se pide el siguiente objeto al módulo cuando acaba el actual. La compra
   directa, la tienda secreta, el mensajero y el alijo no cambian.

## Primera versión, solo el Sniper
- Punto A, tras Dragon Lance: MoM con Berserk por defecto; Hurricane Pike antes si hay dos o más que saltan encima.
- BKB antes si hay dos o más controles o mucho daño mágico de ráfaga.
- MKB en lugar de Daedalus si hay evasión: es pasivo y no necesita regla de uso.
- Blade/Silver Edge y Force/Pike siguen, porque los eligió Pedro (2026-11-05): las reglas los mueven de sitio, nunca los quitan.
- Fuera: detección, anticuración, Nullifier, replanificar a mitad de objeto, datos pro por enfrentamiento y perfiles de otros héroes.

## Cómo se comprueba sin engañarse
1. Sin partidas: la línea `plan` de cada alineación ya jugada en el banco, revisada por alguien que no escribió el módulo.
2. Mecanismo, en una ronda con el marcador (`a11.py`, `a12.py`): MoM antes del min 12; Berserk en las peleas; golpes a héroes entre
   los min 10 y 20 ≥ 40 (hoy 24; OHA, 56); daño por pelea atendida ≥ 1.700 (hoy 1.047); el resto del núcleo no se retrasa. Además, se
   informa en cuántas partidas se activó cada regla: si en casi ninguna, la ronda no dice nada de la adaptación.
3. La adaptación como tal no se puede medir con este ruido: la valida la partida de Pedro. MoM y Shrapnel por cargas van en el mismo
   paquete y no se separan.
