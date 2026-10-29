# Benchmark: ¿juega mejor dota-bot que los bots de Valve?

Partidas de bots contra bots sin clics, en un custom game local (`tools/bench/addon`, «dotabench»): dota-bot en un
equipo y los bots de Valve en el otro, cinco héroes sorteados por partida (uno por posición; se piden para los dos
lados, pero los bots de Valve eligen los suyos: no son espejo), misma dificultad, tu usuario fuera de los equipos,
cambiando de lado en cada partida y acelerado. El ganador lo dice el propio Dota por Game State Integration (GSI).

```
node tools/bench/orquestador.mjs --partidas 10 --dificultad 4 --velocidad 4 --etiqueta oha-vs-valve-unfair
```

- Requisitos: Steam abierto, ningún Dota abierto, Dota 2 Workshop Tools (DLC gratuito) y `pwsh tools/instalar.ps1`
  (enlaza `bots/` y el custom game; ya hecho en el PC de Pedro).
- Qué hace y qué no toca: los límites están al inicio de [orquestador.mjs](../tools/bench/orquestador.mjs). Solo
  lanza y cierra su propio `dota2.exe`, escucha en `127.0.0.1`, y sus archivos temporales (la config de GSI,
  `bots/Customize/bench_valve_team.lua` y `tools/bench/addon/scripts/vscripts/bench_partida.lua`) se borran al
  terminar o al interrumpirlo con Ctrl+C.
- Si el orquestador se cierra a la fuerza (Administrador de tareas), su Dota queda abierto y, en los primeros minutos
  de una partida, puede quedar `bots/Customize/bench_valve_team.lua`: mientras exista, un equipo juega con los bots de
  Valve en cualquier partida local. La siguiente corrida lo borra; también se puede borrar a mano.
- Línea de tiempo: el custom game escribe cada minuto torres, cuarteles, vida del Ancient, kills y oro de los dos
  equipos; el orquestador la guarda en `lineas/<etiqueta>-<fecha>-<n>.csv` y resume en `partidas.csv` la ventaja de oro
  máxima de dota-bot (`ventaja_oro_max`), el minuto en que llegó a +10.000 (`minuto_10k`) y las torres en pie al final
  (`torres_fin`, Radiant-Dire, de la última línea registrada). Las filas anteriores al 2026-10-29 no tienen esas
  columnas.
- Depuración: `--muestra-gsi <archivo>` guarda en ese archivo el último mensaje de GSI tal cual.
- Resultados: una fila por partida en `partidas.csv` (ganador, minutos, kills, héroes). Desde 2026-10-29, `heroes` son
  los reales («Radiant / Dire», del log) y `humano` dice si tu usuario quedó fuera: `fuera` (limpia), `heroe-quitado`
  (Dota le dio héroe y el custom game lo quitó; cuenta) o `en-equipo` (descartar). Antes, `humano` era solo el lado
  desde el que mira GSI: la línea base `oha-vs-valve-unfair` no puede probar que tu usuario quedara fuera (ver
  ESTADO.md).
- Dificultad: 0 pasiva … 4 injusta. Velocidad: 1 a 8 (por defecto ×4: una partida de 40 min dura unos 10).
- Cuidado: `tools/bench/addon/scripts/vscripts/bots` es un enlace a `bots/`. No uses `git clean -x` ni borres
  `tools/bench/addon` en recursivo (podría borrar `bots/` a través del enlace); el enlace se quita con
  `cmd /c rmdir "tools\bench\addon\scripts\vscripts\bots"`.

- Si una partida acaba en `sin-gsi`, mira `game/dota/console.log`: «No usable DX11 adapters» significa que Dota no
  tuvo pantalla ni GPU (monitor apagado, sesión bloqueada o remota). Deja la pantalla encendida durante la serie.
- Mide la máquina antes de una serie y anótalo con los resultados (regla del entorno): CPU, memoria libre y procesos.

## Cómo leerlo
- 10 partidas solo distinguen diferencias grandes (por ejemplo 8 de 10); un 6 de 10 puede ser suerte.
- Los héroes salen de los que los bots de Valve saben jugar (lista recordada, sin verificar aún contra
  `BotImplemented` de `npc_heroes.txt`).
