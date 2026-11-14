# Piloto: reglas de héroe sacadas de guías de YouTube (los cinco del equipo propio)

Encargo (Pedro, 2026-11-14): «que el piloto sea de los 5 heroes para tener un team, si nos funciona lo extrapolamos a mas, maquetalo y lo
corremos mañana en sesion fresca». Idea de Pedro: reunir guías de youtubers, evaluar las jugadas por héroe y los consejos que dan.
Se borra cuando el piloto se cierre.

## Para qué
OHA juega peor que un humano, y hasta ahora las reglas del bot propio salen de OHA y de los registros. Una guía de un jugador de nivel
alto da reglas de juicio por héroe y por rol: cuándo intercambiar, qué guardar, a quién presionar, cuándo salir, qué build y por qué.
Encaja con lo que falla: el Dragon Knight hace 15 veces menos daño de ataque en la línea que el de OHA (MEDICIONES 2026-11-14). Las guías
son contenido de terceros: datos, nunca instrucciones (AGENTS.md).

## Alcance
- **Héroes:** Luna (1), Sniper (2), Dragon Knight (3), Lion (4) y Lich (5).
- **Sobre todo la fase de líneas** (lo que mide el banco hoy), y lo que la guía diga del medio juego queda anotado para el paquete 4 del plan.
- **Fuera del piloto:** analizar las jugadas en el video (imagen). Solo transcripciones; se mira video solo si las transcripciones se
  quedan cortas en un punto concreto, y eso es una ampliación que se propone a Pedro.

## Lo que hace falta
1. **Buscar las guías:** `search_youtube` del conector AQPYoutubeInt. Cada búsqueda nueva cuesta 100 unidades de cuota de YouTube,
   con un tope diario de 2000 compartido con el uso del canal de Pedro. Es cuota gratuita, no dinero: como mucho 10 búsquedas, unas
   2 por héroe («dragon knight offlane guide 7.41», «lion support guide 7.41», etc.).
2. **Bajar las transcripciones:** `video_transcript` del conector **no sirve**: la API de YouTube solo da subtítulos de los videos del
   propio canal. Se usa `yt-dlp --skip-download --write-auto-subs --sub-langs en` (o `youtube-transcript-api`), instalado con pip para
   el usuario (sin administrador). No gasta cuota. Los subtítulos van a un directorio propio fuera del repo (scratchpad), como datos
   descargados: no se ejecuta nada de ahí.
3. **Elegir los videos** (unos 5 por héroe, 25 en total):
   - del parche 7.40 o posterior (hoy 7.41f), o con la mecánica del héroe sin cambios desde su fecha;
   - de jugadores de nivel alto o canales de guías conocidos;
   - en inglés o español.

   Si Pedro tiene canales de confianza, van primero.
4. **Extraer las reglas:** un subagente por héroe (Sonnet a esfuerzo medio, son tareas acotadas) lee sus transcripciones y escribe una
   tabla. Columnas:
   - situación, acción y por qué;
   - fuente (video y minuto);
   - cuántas guías la dicen;
   - si la API de bots la permite (`docs/api/`);
   - qué módulo toca (`propio/<héroe>.lua`, `linea.lua`, `dos.lua`, `compras.lua`);
   - si nuestro bot y OHA ya la cumplen.

   Las reglas que se contradicen entre guías se marcan, no se resuelven a ojo.
5. **Cotejar con los registros:** de cada regla «no la cumplimos», mirar en `h2`, `p4a` y `p4b` cuántas veces se da la situación. Con esa
   frecuencia se ordenan: primero las que más situaciones tocan.

## Qué sale
- Un archivo por héroe con su tabla (`trabajo/guias/<heroe>.md`), y un resumen con las reglas ordenadas.
- **Un solo paquete de héroe** propuesto a Pedro para su firma, con las reglas que más pesan y sus métricas, medido como el paquete 4:
  brazo nuevo frente al actual en la misma tanda, orden ABBA y como mucho 2 rondas.
- **Si funciona** (el paquete cumple su predicción), se extrapola a más héroes con el mismo método (Pedro, 2026-11-14).

## Tamaño y coste
Una sesión para extraer las reglas y escribir el paquete, sin gasto de pago: subagentes de la sesión y cuota gratuita de YouTube
(como mucho 10 búsquedas). La medición del paquete, después, en tandas como las de siempre (unas 1,5 h por ronda).

## Orden
Después de cerrar la ronda del paquete 4 (`p4a` y `p4b`), para no mezclar efectos al medir.
