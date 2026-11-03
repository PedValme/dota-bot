# La API de bots, de primera mano

Base del bot propio (DECISIONES 2026-11-03: «no podemos seguir a ciegas»). Tres fuentes, de más a menos fiable:

1. **El propio motor**, volcado desde dentro de un bot: [volcado.md](volcado.md) (y el registro en bruto,
   [volcado-crudo.txt](volcado-crudo.txt)). Se rehace en cada parche: partida con
   `node tools/bench/orquestador.mjs --partidas 2 --variantes volcado_api --observar --modo turbo`, cortarla cuando
   el registro diga `apidump fin handles` y lleguen las unidades del minuto 15, y `node tools/datos/api_volcado.mjs`.
2. **La wiki de Valve** (2016-2017), resumida en [../investigacion/2026-11-03-api-valve.md](../investigacion/2026-11-03-api-valve.md):
   explica qué hace cada cosa y qué sustituye cada archivo.
3. **Los archivos de datos del juego** (`scripts/npc/*.txt`, empaquetados en los VPK de Dota), leídos del espejo
   público [dotabuff/d2vpkr](https://github.com/dotabuff/d2vpkr) del 2026-11-03 y **cotejados con el motor**: los
   valores de creeps y torres coinciden con los leídos en partida.

`docs/BOT_API_REFERENCE.md` (comunidad, heredado de OHA) queda como lectura secundaria: tiene errores probados.

## Lo que dice el volcado (7.41f, partida del 2026-11-03)

- **156 funciones globales, 220 métodos de unidad y 50 de habilidad u objeto, 358 constantes.** Héroe, creep, edificio
  y mensajero son la misma clase (`CDOTA_Bot_Script`); habilidad y objeto, `CDOTABaseAbility_BotScript`.
- **El entorno no trae la biblioteca `debug`**, y el Lua de cada equipo es compartido: no se puede distinguir en
  partida una función del motor de una reemplazada por un script. Por eso el generador marca **OHA** lo que define
  este repositorio.
- **OHA reemplaza unas 30 llamadas de Valve** (`FunLib/aba_global_overrides.lua`), entre ellas `GetHealth`,
  `GetMaxHealth`, `GetMana`, `GetLocation`, `GetAttackRange`, `GetAttackTarget`, todas las `GetNearby*` de unidades,
  `HasModifier`, `IsIllusion`, `IsInvulnerable`, `IsMagicImmune`, `Action_UseAbility`, `GetTeamPlayers`,
  `GetUnitToUnitDistance` y `print`. **El bot propio no debe cargar ese archivo**, y mientras convivan en el mismo
  equipo hay que saber que esas llamadas no son las de Valve.
- **Existen y no las documenta la referencia de la comunidad:** `GetUnitPotentialValue` (dónde puede estar un enemigo
  oculto), `GeneratePath` y `AddConditionalAvoidanceZone`, `GetBotByHandle` y `GetBotAbilityByHandle`,
  `GetCourierForPlayer`, `GetOutpost`, `GetTalent`, `IsNull` (una unidad que ya no existe), `GetNearbyFillers`,
  `IsSpeciallyUndeniable`, las `TimeSinceDamagedBy*` y `WasRecentlyDamagedByPlayer`, y todas las variantes
  `ActionPush_*`/`ActionQueue_*`.
- **El entorno trae `CreateHTTPRequest`, `CreateRemoteHTTPRequest`, `loadstring`, `load`, `loadfile` y `dofile`.** Nuestro
  check prohíbe las de red (DECISIONES 2026-10-28).

## Datos de creeps y torres (motor y archivos de Valve coinciden)

| Unidad | Vida | Daño | Punto de ataque | Ataques/s | Proyectil | Armadura | Oro |
|---|---|---|---|---|---|---|---|
| Creep cuerpo a cuerpo | 550 | 19-23 | 0,467 | 1 | — | 2 | 34-39 |
| Creep a distancia (rango 500) | 300 | 21-26 | 0,5 | 1 | 900 | 0 | 43-52 |
| Catapulta (rango 690) | 935 | 35-46 | 0,7 | 1/3 | 1100 | 0 (80 % mágica) | 59-72 |
| Torre 1 (rango 700) | 1.800 | 88-92 | 0,6 | 1/0,9 | 750 | 12 | — |
| Torres 2 y 3 | 2.500 | 170-174 | 0,6 | 1/0,9 | 750 | 16 | — |

**Los creeps se fortalecen con el tiempo:** en el minuto 7,5 el de distancia pasa a 312 de vida y 23-28 de daño, y el
cuerpo a cuerpo a 562 y 20-24 (leído en partida). El bot propio lee los valores en vivo, no de una tabla.
`GetAttackDamage` devuelve el daño redondeado hacia abajo (23 con una base de 23,5): para un último golpe seguro se
usa `GetBaseDamage - GetBaseDamageVariance`.

## Los bots de Valve (archivos `bot_*.txt` del juego)

- `bot_builds.txt` y `bot_loadouts.txt` tienen orden de habilidades y objetos solo para **39 héroes**; `bot_roles.txt`
  da posición a 127. Los 31 héroes del sorteo del banco están entre los 39: el rival de Valve juega siempre con un
  héroe que sabe llevar (queda verificado el pendiente «la lista de héroes del sorteo»).
