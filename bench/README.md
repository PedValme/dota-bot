# Benchmark: ¿juega mejor dota-bot que los bots de Valve?

Partidas de bots contra bots sin clics, en un custom game local (`tools/bench/addon`, «dotabench»): dota-bot en un
equipo y los bots de Valve en el otro, **los mismos cinco héroes en los dos lados** (sorteados en cada partida, uno por
posición), misma dificultad, tu usuario fuera de los equipos, cambiando de lado en cada partida y acelerado. El
ganador lo dice el propio Dota por Game State Integration (GSI).

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
- Resultados: una fila por partida en `partidas.csv` (ganador, minutos, kills, héroes). La columna `humano` es el
  equipo que GSI atribuye al espectador (desde dónde mira), no un lugar en la partida: en dotabench el humano queda
  fuera de los equipos (lo dice el log: «human player 0 kept out of the teams»).
- Dificultad: 0 pasiva … 4 injusta. Velocidad: 1 a 8 (por defecto ×4: una partida de 40 min dura unos 10).
- Cuidado: `tools/bench/addon/scripts/vscripts/bots` es un enlace a `bots/`. No uses `git clean -x` ni borres
  `tools/bench/addon` en recursivo (podría borrar `bots/` a través del enlace); el enlace se quita con
  `cmd /c rmdir "tools\bench\addon\scripts\vscripts\bots"`.

## Cómo leerlo
- 10 partidas solo distinguen diferencias grandes (por ejemplo 8 de 10); un 6 de 10 puede ser suerte.
- Los héroes salen de los que los bots de Valve saben jugar (lista recordada, sin verificar aún contra
  `BotImplemented` de `npc_heroes.txt`).
