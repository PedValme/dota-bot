# Estado

<!-- pic-method: next-session -->
## Próxima sesión
- **2026-10-29/30, noche de reconocimiento** (DECISIONES 2026-10-29, Pedro): leer todo el bot, el custom game y cómo
  operan en Dota, y comprobarlo en partidas Turbo imitado. Entregable: [docs/mapa.md](docs/mapa.md), con cada dato
  marcado como visto en el juego, leído en el código o supuesto. Léelo antes de cualquier prueba.
- Nuevo: modo observador (`--observar`, bench/README.md) y `node tools/bench/analizar.mjs <log>`. Con él, cada bot anota
  su modo activo cada 2 s: el `print` de los bots sí llega al log (lo silenciaba OHA, no Valve).
- 7 partidas Turbo imitado (`mapa-*` en `bench/series.csv`): dota-bot ganó 6 de 7 y tarda en rematar (de 17 a 25
  min desde +10.000). Causas leídas en el código y vistas en los modos: con +6.000 deja de farmear, y el empuje va con
  tope y casi nunca con 4-5 bots juntos (7-8 % del tiempo).
- Corregido sobre el benchmark: Radiant recibe los héroes sorteados y Dire elige los suyos, la controle quien la
  controle (antes se creía que eran «los mismos héroes»).
- Siguiente: lo que Pedro decida con el mapa. Pendiente sin probar: una partida en lobby Local Host (draft de OHA,
  humanos en los equipos, Turbo real), que es lo que usará con amigos.

## Madurez
Prototipo: OHA 7.41a (127 héroes) con limpieza de seguridad, al día con 7.41f. Sin cambios de juego propios activos
(el de empuje se midió sin mejora y quedó apagado).

## Entregado
- 2026-10-28/29 · Investigación, fork limpio (PR #1), junctions (#2), orquestador con GSI y guardia por equipo (#4),
  custom game dotabench (#5), línea base (#7, contaminable), 7.41f (#8), línea de tiempo (#9), topes de empuje (#11),
  humano fuera (#13), series A/B con validez (#14), Turbo imitado, courier y espectador (#15), empuje apagado (#17).
- 2026-10-30 · Mapa (docs/mapa.md), modo observador y analizador.

## Siguientes pasos
1. Las 3 etapas en Turbo (empuje, `ThinkLess` 0, capitán LLM), si Pedro las retoma; el mapa sugiere mirar antes la
   regla de farm con +6.000 y el empuje en grupo.
2. Probar con amigos en un lobby Local Host.
3. Defectos del mapa (sección 8): Drow (`GetNearbyHeroes` con modo), Roshan, Tormentor, secret shop, ward.
4. Del informe de parches: talentos de 16 héroes; Tusk, Invoker y Outworld Destroyer. Verificar los héroes del pool
   contra `BotImplemented` y los objetos de las builds contra 7.41f.

## Problemas conocidos
- ~10 «error in error handling» por partida, sin origen localizado; cientos de órdenes inválidas por partida (docs/mapa.md §4).
- ~12 interruptores de Turbo por `GetGameMode() == 23` no se encienden en el custom game (docs/mapa.md §2).
- Saludos con promoción del Workshop (`mode_laning_generic.lua:249`, `mode_farm_generic.lua:904`,
  `hero_faceless_void.lua:151`). FretBots `set`/`nudge` usan `loadstring` (host). Dependencias npm heredadas con
  conflicto de `typescript`. Durante una serie, `bots/` se lee en vivo.
