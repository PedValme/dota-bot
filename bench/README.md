# Benchmark: ¿juega mejor dota-bot que los bots de Valve?

Partidas locales de bots contra bots, sin clics: dota-bot en un equipo y los bots de Valve en el otro, en la misma
dificultad, cambiando de lado en cada partida. El ganador lo dice el propio Dota por Game State Integration (GSI).

```
node tools/bench/orquestador.mjs --partidas 10 --dificultad 4 --etiqueta oha-vs-valve-unfair
```

- Requisitos: Steam abierto, ningún Dota abierto, `bots/` instalado (`pwsh tools/instalar.ps1`, ya hecho).
- Qué hace y qué no toca: los límites están al inicio de [orquestador.mjs](../tools/bench/orquestador.mjs). Solo
  lanza y cierra su propio `dota2.exe`, escucha en `127.0.0.1`, y sus dos archivos temporales (la config de GSI y
  `bots/Customize/bench_valve_team.lua`) se borran al terminar o al interrumpirlo con Ctrl+C.
- Resultados: una fila por partida en `partidas.csv` (ganador, minutos, kills, en qué equipo quedó el humano).
- Dificultad: 0 pasiva … 4 injusta.

- Si el orquestador se cierra a la fuerza (Administrador de tareas), su Dota queda abierto y, en los primeros minutos
  de una partida, puede quedar `bots/Customize/bench_valve_team.lua`: mientras exista, un equipo juega con los bots de
  Valve en cualquier partida local. La siguiente corrida lo borra; también se puede borrar a mano.

## Límites conocidos (2026-10-28)
- Tu usuario entra como jugador de Radiant con un héroe quieto (medido; `jointeam spectator` en partida no lo saca):
  esas partidas son 4 contra 5. El orquestador lo marca en la columna `humano` y en el resumen. Se resuelve con un
  custom game de las Workshop Tools (en curso).
- Sin acelerar: `host_timescale 4` solo funciona escrito ya en partida; a velocidad normal una partida dura 30-80 min.
- 10 partidas solo distinguen diferencias grandes (por ejemplo 8 de 10); un 6 de 10 puede ser suerte.
