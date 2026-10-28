# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- Se hizo: investigación, fork de OHA con limpieza de seguridad y método (PR #1); instalación en el PC de Pedro
  (junction a `bots/`, `tools/instalar.ps1`) y benchmark contra los bots de Valve listo sin estrenar (bench/README.md).
- Siguiente acción: primera partida de Pedro con `tools/bench/Dota-benchmark.url`: confirmar que los bots se llaman
  «*.OHA», que el lobby acepta un script distinto por equipo y que salen líneas `[BENCH]` en `console.log`; luego
  correr `node tools/bench/resumen.mjs` y ajustar lo que falle.
- Espera a Pedro: esa partida, las 10 del benchmark, la prueba con un amigo y elegir el primer héroe a mejorar.

## Madurez
Prototipo: es OHA 7.41/7.41a (127 héroes) con la limpieza de seguridad; sin cambios de juego propios.

## Entregado
- 2026-10-28 · Informe de investigación sobre APIs de bots de Dota 2 (docs/investigacion/2026-10-28-bots-dota2.md).
- 2026-10-28 · Fork, limpieza de seguridad y check (`tools/check`).
- 2026-10-28 · Instalación por junction y benchmark (registrador `[BENCH]`, resumen y protocolo en bench/).

## Siguientes pasos
1. Probar en el PC de Pedro: solo, y con amigos en el mismo lobby Local Host.
2. Correr el benchmark: 10 partidas dota-bot contra Valve en Unfair, cambiando de lado; resultados en bench/.
3. Elegir un héroe débil (Invoker, Rubick o Morphling) y mejorar sus funciones `Consider*`.
4. Ponerse al día con los parches 7.41b-f (OHA se quedó en 7.41a; ver docs/PATCH_UPDATE_GUIDE.md).

## Problemas conocidos
- Quedan textos ofensivos y de promoción en `bots/FunLib/localization.lua` y `aba_chat_table.lua`; con la burla
  apagada no salen, salvo los saludos de inicio («buy me a coffee… Workshop», `mode_laning_generic.lua:248`,
  `mode_farm_generic.lua:903`) y una línea de Faceless Void (`BotLib/hero_faceless_void.lua:151`).
- `FunLib/custom_loader.lua` carga primero `game/Customize/general` (ignorado por git): una personalización vieja de OHA
  en ese PC puede volver a encender la burla.
- Los comandos `set`/`nudge` del host en FretBots evalúan texto con `loadstring` (`FretBots/Utilities.lua:515`);
  solo el host, dentro del juego.
- Las dependencias npm heredadas no instalan sin `--legacy-peer-deps` (conflicto de `typescript`).
- La API de Valve no soporta bien a 8 héroes (Dark Willow, Elder Titan, Hoodwink, IO, Kez, Marci, Muerta, Primal
  Beast) ni facets ni Tormentor; Valve no la actualiza.
