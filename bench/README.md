# Benchmark: ¿juega mejor dota-bot que los bots de Valve?

Partidas de bots contra bots sin clics, en un custom game local (`tools/bench/addon`, «dotabench»): dota-bot en un
equipo y los bots de Valve en el otro, cinco héroes sorteados por partida (uno por posición; se piden para los dos
lados: espejo desde el 2026-10-31, ver «Héroes»), misma dificultad, tu usuario fuera de los equipos,
cambiando de lado en cada partida y acelerado. El ganador lo dice el propio Dota por Game State Integration (GSI).

```
node tools/bench/orquestador.mjs --partidas 40 --dificultad 4 --velocidad 4 --modo turbo --variantes base,empuje --etiqueta turbo-empuje-ab
```

- Turbo (`--modo turbo`, el objetivo de Pedro desde el 2026-10-29): imitado, porque el Turbo real no corre en un custom
  game (forzar el modo 23 no cambia nada y la API no tiene esa opción; probado). El custom game pone couriers Turbo
  (1100 de velocidad, que es como OHA detecta Turbo y activa su lógica), oro y experiencia ×2 ganados en partida y
  reaparición al 75 %; torres, runas y demás quedan como en modo normal. Medido: 10 couriers a 1100 y, del minuto 0
  al 5, entre 5.100 y 8.700 de oro por equipo (unos 2.700 en modo normal). Cada partida exige «turbo on/off» en el
  log según `--modo` (columna `modo`).
- Desde el 2026-10-29 cada jugador tiene courier (`SetFreeCourierModeEnabled`): antes, el custom game no daba
  ninguno, así que **todas las series anteriores (la `empuje-ab` normal incluida) se jugaron sin courier** en los dos
  lados.
- Tu usuario mira como espectador (equipo 1, desde la previa del minuto 0): puedes elegir la visión de Radiant, Dire o
  ambos. Asignarlo antes, en la pantalla de configuración, deja el custom game trabado (probado).

- Comparar versiones del bot: `--variantes a,b` (las de `VARIANTS` en el orquestador: `base` sin el cambio de empuje
  del PR #11, `empuje` con él, `thinkless0` con él y `ThinkLess` 0, `sonda` solo para comprobar el mecanismo). Se intercalan en bloques: por cada sorteo de
  héroes, cada variante juega en los dos lados y el orden se invierte en cada bloque, así que héroes, lado, versión de
  Dota y carga del PC caen igual sobre todas. `--partidas` debe ser múltiplo de 2 × variantes. El orquestador escribe
  `bots/Customize/bench_variant.lua` en cada partida (lo leen los bots con `FunLib/bench_variant.lua`) y lo borra al
  terminar; sin ese archivo el bot juega su código actual.
- Que los bots aplican la variante se comprobó en el juego el 2026-10-29 con la variante `sonda` (`ThinkLess` 1000):
  mismos héroes en Radiant, al minuto 10 dota-bot lanzó 24 hechizos con sonda y 152 sin ella. En cada partida el
  custom game confirma el archivo de variante y anota los hechizos por equipo (`rc`, `dc` en `lineas/`) como huella.
- Corrección del 2026-10-30: los bots **sí** pueden escribir en el log. Quien silenciaba su `print` era OHA
  (`FunLib/aba_global_overrides.lua`, salvo `Utils.DebugMode`), no Valve; con el modo observador llega a
  `console.log` con el prefijo `[VScript]`.
- Modo observador (`--observar`, para mapear cómo juegan los bots; no cambia cómo juegan): el custom game registra cada
  30 s de juego el estado de cada héroe (nivel, oro, patrimonio, últimos golpes, K/D/A, posición, vida, maná, objetos
  por casilla) y de cada courier, y cada compra, punto de habilidad, hechizo, muerte de héroe, torre, courier o Roshan,
  runa, recompra, glifo y ward. Además el orquestador escribe `bots/Customize/bench_observe.lua` (lo lee
  `FunLib/bench_observe.lua`): con él, el `print` de los bots llega al log y cada bot de dota-bot anota su modo activo
  y su deseo cada 2 s (`[bench] mode`). Todo eso, más las líneas del motor sobre los bots (errores de script, órdenes
  inválidas, funciones lentas, edificios), queda por partida en `observaciones/<etiqueta>-<fecha>-<n>.log` (ignorado por
  git: pesan varios MB). `node tools/bench/analizar.mjs observaciones/<archivo>.log` lo resume: zonas, agrupación,
  farm, couriers, modos de dota-bot según su ventaja, empuje en grupo y errores.
- Héroes: espejo en los dos equipos desde el 2026-10-31. En este custom game la selección, la estrategia y la previa
  pasan en el mismo segundo: `AddBot` da a Radiant los sorteados y el motor da a Dire **héroes al azar**. Así fueron
  todas las partidas anteriores a esa fecha, y por eso rendía peor quien jugaba en Dire. Ahora el custom game cambia
  cada héroe de Dire por el sorteado de su posición medio segundo después de aparecer (`ReplaceHeroWith`; los scripts
  del bot se reinician con el héroe nuevo, comprobado) y lo anota como `[dotabench] mirror`. `--espejo no` lo apaga.
- Validez (decisión de Pedro, DECISIONES 2026-10-29: no se acepta contaminación): cada partida va a `series.csv` con
  `valida` y `motivo`. Cuenta solo si terminó, hubo 5 bots por lado, tu usuario quedó fuera, el log confirma la
  variante y el modo, y Dota no cambió de versión (`dota_version`, de `steam.inf`). También se anotan la CPU de la máquina
  durante la partida (`cpu_media`, `cpu_max`, toda la máquina, Dota incluido) y la memoria libre al final.

- Requisitos: Steam abierto, ningún Dota abierto, Dota 2 Workshop Tools (DLC gratuito) y `pwsh tools/instalar.ps1`
  (enlaza `bots/` y el custom game; ya hecho en el PC de Pedro).
- Qué hace y qué no toca: los límites están al inicio de [orquestador.mjs](../tools/bench/orquestador.mjs). Solo
  lanza y cierra su propio `dota2.exe`, escucha en `127.0.0.1`, y sus archivos temporales (la config de GSI,
  `bots/Customize/bench_valve_team.lua`, `bench_variant.lua`, `bench_observe.lua` y `tools/bench/addon/scripts/vscripts/bench_partida.lua`) se borran al
  terminar o al interrumpirlo con Ctrl+C.
- Si el orquestador se cierra a la fuerza (Administrador de tareas), su Dota queda abierto y, en los primeros minutos
  de una partida, puede quedar `bots/Customize/bench_valve_team.lua`: mientras exista, un equipo juega con los bots de
  Valve en cualquier partida local. La siguiente corrida lo borra; también se puede borrar a mano.
- Línea de tiempo: el custom game escribe cada minuto torres, cuarteles, vida del Ancient, kills y oro de los dos
  equipos (el oro, solo de los bots); el orquestador la guarda en `lineas/<etiqueta>-<fecha>-<n>.csv` y resume la
  ventaja de oro máxima de dota-bot (`ventaja_oro_max`), el minuto en que llegó a +10.000 (`minuto_10k`) y las torres
  en pie al final (`torres_fin`, Radiant-Dire, de la última línea registrada).
- Depuración: `--muestra-gsi <archivo>` guarda en ese archivo el último mensaje de GSI tal cual.
- Resultados: una fila por partida en `series.csv`. `heroes` son los reales («Radiant / Dire», del log) y `humano` dice
  si tu usuario quedó fuera: `fuera`, `heroe-quitado` (Dota le dio héroe y el custom game lo quitó; cuenta) o
  `en-equipo` (no válida). `partidas.csv` es el histórico de antes del 2026-10-29: allí `humano` era solo el lado desde
  el que mira GSI, así que esas series (la línea base `oha-vs-valve-unfair` incluida) no prueban que tu usuario quedara
  fuera.
- Dificultad: 0 pasiva … 4 injusta. Velocidad: 1 a 8 (por defecto ×4: una partida de 40 min dura unos 10).
- Cuidado: `tools/bench/addon/scripts/vscripts/bots` es un enlace a `bots/`. No uses `git clean -x` ni borres
  `tools/bench/addon` en recursivo (podría borrar `bots/` a través del enlace); el enlace se quita con
  `cmd /c rmdir "tools\bench\addon\scripts\vscripts\bots"`.

- Si una partida acaba en `sin-gsi`, mira `game/dota/console.log`: «No usable DX11 adapters» significa que Dota no
  tuvo pantalla ni GPU (monitor apagado, sesión bloqueada o remota). Deja la pantalla encendida durante la serie.
- Mide la máquina antes de una serie y anótalo con los resultados (regla del entorno): CPU, memoria libre y procesos.

## Protocolo de medición
Una serie mide solo si cada condición de esta tabla se comprueba sola, en cada partida. Una condición que nadie
comprueba es una suposición: va a «Sin comprobar» y se resuelve antes de sacar conclusiones, no después. Una asimetría
conocida entre los lados bloquea la serie hasta arreglarla. Lección del 2026-10-31: los héroes al azar de Dire estaban
anotados como un hecho del banco y no como contaminación, y se midieron horas encima.

| Condición | Cómo se comprueba | Si falla |
|---|---|---|
| La partida terminó | GSI da ganador | `sin final` |
| 5 bots por lado, humano fuera | `[dotabench] roster` | `reparto`, `humano` |
| Mismos cinco héroes en los dos lados | `roster` + `[dotabench] mirror ok=true` | `héroes distintos por lado` |
| Variante y modo pedidos | `[dotabench] variant`, `turbo on/off` | `variante`, `modo` |
| Misma versión de Dota en toda la serie | `steam.inf` | `Dota cambió de versión` |
| Lado, héroes y orden repartidos igual entre variantes | calendario por bloques (pruebas) | solo cuentan bloques completos |
| Máquina libre | CPU y memoria por partida en `series.csv` | se anota; con carga alta, no se corre |

Sin comprobar (supuestos a la vista):
- El sorteo de héroes sale de una lista recordada de los que saben jugar los bots de Valve, no de `BotImplemented`.
- El Turbo imitado (couriers, oro y experiencia ×2, reaparición) no es el Turbo real: torres y runas son las normales.
- La columna `heroes` de las series anteriores al control (hasta `justa` incluida) muestra los héroes de Dire antes
  del espejo; el espejo se comprobó en los logs de `observaciones/` (las 7 primeras de `justa`: 5 de 5 en todas).

## Cómo leerlo
- 10 partidas solo distinguen diferencias grandes (por ejemplo 8 de 10); un 6 de 10 puede ser suerte. Con 20 por
  variante, solo se ve una diferencia de unos 30 puntos en victorias; el tiempo de cierre (`minuto_10k` hasta el final)
  es más sensible.
- Mientras corre una serie, no cambies de rama ni toques `bots/` en el clon que enlaza Dota: los bots se leen en vivo
  de ahí en cada partida. Para trabajar a la vez, usa otro worktree.
- Los héroes salen de los que los bots de Valve saben jugar (lista recordada, sin verificar aún contra
  `BotImplemented` de `npc_heroes.txt`).
