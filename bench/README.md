# Benchmark: ¿juega mejor dota-bot que los bots de Valve?

> **No funciona todavía (2026-10-28):** lo que imprimen los bots no llega a `console.log`, así que el registrador
> `[BENCH]` no deja resultados. Se reemplaza por GSI; detalle en ESTADO.md, «Próxima sesión».

Partidas de bots contra bots en tu PC, sin ventajas (FretBots apagado, que es lo normal si no lo activas a mano). Un
equipo usa dota-bot y el otro los bots de Valve, los dos en la misma dificultad. Los bots de dota-bot escriben el
estado de la partida en la consola (`bots/FunLib/bench.lua`) y `tools/bench/resumen.mjs` lo convierte en una tabla.

## Una vez
- Instalación: `pwsh tools/instalar.ps1` (ya hecha el 2026-10-28). Enlaza `bots/` dentro de Dota y copia `bench.cfg`.
  Es un enlace, no una copia: si algún día Dota o «verificar archivos» borrara `vscripts/bots`, podría borrar el
  contenido del clon; lo que esté en git se recupera, lo no guardado no.
- Abre Dota siempre con [Dota-benchmark.url](../tools/bench/Dota-benchmark.url) (doble clic): arranca con
  `-console -condebug`, que guarda la consola en `game/dota/console.log`. Steam pide confirmar las opciones.

## Cada partida
1. Jugar → Crear lobby personalizado. Ubicación del servidor: **Local Host**. Modo: All Pick. Marca **Enable Cheats**.
2. Bots: un equipo con **Local Dev Script** (dota-bot) y el otro con los **bots por defecto de Valve**, los dos en
   **Unfair**. Tú, en espectador o sin asignar, y que los bots llenen los huecos.
3. Cuando empiece, abre la consola y escribe `exec bench` (acelera ×4; si va a tirones, `host_timescale 2`).
4. Déjala terminar. En la siguiente, cambia de lado (dota-bot en el otro equipo), porque el lado del mapa influye.

## Resultados
`node tools/bench/resumen.mjs` muestra las partidas del `console.log`; con `--guardar <etiqueta>` (por ejemplo
`--guardar oha-vs-valve-unfair`) las añade a [resultados.csv](resultados.csv) sin repetir las ya guardadas. Guarda
cuando las partidas hayan terminado: una partida guardada a medias no se actualiza después. Si Dota no está en
`C:\Program Files (x86)\Steam`, pasa la ruta del log: `node tools/bench/resumen.mjs "<dota 2 beta>\game\dota\console.log"`.

Columna `how`: «final», se vio el fin de la partida; «inferido», un Ancient aparece destruido; «probable», la última
línea tiene un Ancient casi muerto (menos de 1500) y el otro sano (3000 o más); «?», no se sabe. El resumen cuenta
«probable» como decidida; si dudas, míralo en la tabla.

## Cómo leerlo
- 10 partidas solo distinguen diferencias grandes (por ejemplo 8 de 10); un 6 de 10 puede ser suerte.
- Los héroes los elige cada script, así que cada partida es distinta: mira también las columnas de héroes.
- Por verificar en la primera partida: los nombres exactos de las opciones del lobby, que cada equipo acepte un script
  distinto y que aparezcan líneas `[BENCH]` en `console.log`.
