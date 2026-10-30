# Mapa de dota-bot, del custom game y de cómo operan dentro de Dota

Noche del 2026-10-29 al 30 (Pedro: «quiero que conozcas como la palma de tu mano tanto el bot como su comportamiento y
lo mismo para el custom mode»). Cada afirmación lleva su fuente:
- **[J]** visto en el juego, en las 7 partidas Turbo imitado de esta noche (`bench/series.csv`, etiquetas `mapa-*`).
- **[C]** leído en el código, con `ruta:línea` (las líneas pueden moverse unas pocas).
- **[S]** supuesto: no verificado.

Cuando el código y este mapa no coincidan, manda el código.

## 1. Cómo encaja todo

```
orquestador.mjs ── escribe bench_partida.lua, bench_valve_team.lua, [bench_variant.lua], [bench_observe.lua]
      │ lanza dota2.exe -condebug +dota_launch_custom_game dotabench dota
      ▼
Dota 2 ── servidor: addon_game_mode.lua (custom game dotabench, VScript)
      │      saca al humano, AddBot x10, Turbo imitado, host_timescale, línea de tiempo, observador
      │
      ├── VM de bots Radiant ─┐  ambos cargan scripts de tools/bench/addon/scripts/vscripts/bots = junction a bots/
      └── VM de bots Dire ────┘  el equipo de bench_valve_team.lua sale por la guardia bench_side → bots de Valve
      │
      ├── GSI → 127.0.0.1:3911 → orquestador (estado, ganador, reloj, kills)
      └── console.log → orquestador (timeline, roster, variante, modo, observaciones)
```

- **[J]** Los dos equipos cargan los scripts del mismo directorio (`Radiant/Dire bot scripting using script path
  ...dotabench\scripts\vscripts\bots` en `console.log`). El equipo que juega con Valve lo decide la guardia de la primera
  línea de cada archivo de entrada (`FunLib/bench_side.lua`): si `Customize/bench_valve_team.lua` dice su equipo, el
  archivo no define nada y el motor usa los scripts por defecto de Valve.
- **[J]** El motor busca `bots/team_desires.lua` y no lo encuentra («not found»): no existe en OHA. Valve pone sus
  deseos de equipo por defecto.
- **[J]** Los bots de Valve también son Lua: el motor avisa «Script function 'GetDesire' on bot X took N ms» también de
  los héroes del equipo de Valve.
- **[J]** El `print` de los bots **sí llega** a `console.log` (con el prefijo `[VScript]`). Quien lo silenciaba era OHA:
  `FunLib/aba_global_overrides.lua` reemplaza `print` y lo calla salvo con `Utils.DebugMode` (que vale `false`,
  `FunLib/utils.lua:703`). La nota antigua de que «los bots no pueden escribir en el log» era falsa.
- **[J]** El chat de los bots no llega al log con el humano fuera de los equipos (medido el 2026-10-29).

## 2. El custom game `dotabench` (`tools/bench/addon/scripts/vscripts/addon_game_mode.lua`)

| Qué hace | Cómo | Verificado |
|---|---|---|
| Saca al humano | `KeepHumansOut` en cada cambio de estado, equipo 1 (espectador) desde PRE_GAME; si Dota le da héroe, lo borra | [J] las 7 partidas: `humano=fuera`; el log dice «human player 0 was on team 2 (state 4); moving out» en cada partida |
| 10 bots | `Tutorial:AddBot(héroe, línea, dificultad, radiant)` con los 5 héroes sorteados para cada equipo | [J] AddBot devuelve `true` 10 veces |
| Héroes | **Radiant recibe los sorteados; Dire elige los suyos, la controle quien la controle** | [J] 7 de 7 partidas. Cuando dota-bot es Dire, los elige el draft de OHA (`hero_selection.lua`); cuando Valve es Dire, los elige Valve |
| Turbo imitado | `SetUseTurboCouriers`, filtro de oro ×2 (solo ingresos), experiencia ×2, reaparición ×0,75 | [J] 10 couriers a 1100 en cada snapshot de las 6 partidas que los registran |
| Courier por jugador | `SetFreeCourierModeEnabled(true)` | [J] 5 couriers por equipo, que llevan objetos (los bots los usan) |
| Neutrales | Los reparte el motor como en una partida normal | [J] aparecen en la casilla 16 (p. ej. `grisgris`, `seeds_of_serenity`) |
| Aceleración | `sv_cheats 1` + `host_timescale` en PRE_GAME | [J] ×4 rinde ×2,4 a ×2,9: 28-51 min de juego en 10-21 min reales, más 1-2 min de carga por partida |
| Línea de tiempo | cada minuto: kills, torres, cuarteles, vida del Ancient, patrimonio, hechizos por equipo | [J] `bench/lineas/` |
| Observador | con `observar = true`: ver la sección 6 | [J] |

- **[J]** Runas de sabiduría: el log dice «XP Fountain: Unit X gains N XP».
- **[J]** Mapa: «Bot ward spot ward_spot_radiant_high_point_top not found in map», «ward_spot_dire_high_point_top in an
  invalid location, this may cause bots to get stuck». Son avisos del motor sobre sus propios puntos de ward.
- **[C]** Hueco de la imitación: unos 12 interruptores con `GetGameMode() == 23` **no** se encienden en el custom game.
  Entre ellos: la fase de línea ×1,65 (`mode_laning_generic.lua:60`), relojes ×2 o ×1,65 en el empuje
  (`FunLib/aba_push.lua:58`), la defensa (`FunLib/aba_defend.lua:239`) y `FunLib/global_cache.lua:207`, la compra Turbo
  (`item_purchase_generic.lua:1254`, sin secret shop ni ahorro de recompra), la venta con inventario lleno (`:1060`),
  `mode_team_roam_generic.lua:902`, la protección del courier y la charla (`ability_item_usage_generic.lua:814`, `:399`)
  y el draft, que en Turbo no espera a los humanos (`hero_selection.lua:951`). Lo que cuelga de `J.IsModeTurbo()` (24
  usos) sí se enciende.

## 3. Cómo decide el bot

### 3.1 El contrato con el motor
- **[C]** Cada frame, el motor llama `GetDesire()` de todos los modos (`mode_<nombre>_generic.lua`), activa el de mayor
  deseo y solo ese corre `Think()`. Aparte corren `ItemUsageThink`, `AbilityUsageThink`, `BuybackUsageThink`,
  `CourierUsageThink` y `AbilityLevelUpThink` (`ability_item_usage_generic.lua:~8377-8420`).
- **[C]** Quién mueve de verdad al héroe en cada modo:

| Modo | `Think` | Lo mueve |
|---|---|---|
| push ×3, defend ×3, farm, roam, team_roam, rune, ward, secret_shop, side_shop (= Tormentor), outpost, assemble | propio | OHA |
| laning | solo para 9 héroes «buggy» o pos 1 con pos 5 humana | Valve (OHA solo pone el deseo) |
| retreat | no (el archivo acaba en `return X`, `mode_retreat_generic.lua:784`) | Valve |
| roshan | no | Valve |
| attack | solo para los 9 «buggy» (`FunLib/utils.lua:721`) | Valve |
| item, defend_ally, evasive_maneuvers | no hay archivo | Valve |

- **[C]** No se cargan: `--mode_item_generic.lua`, `mode_retreat_generic_wip.lua` (nombre que el motor no reconoce
  [S]).
- **[J]** Hay un modo activo con número 28 que no está en la lista de constantes del API (1 % del tiempo). [S] es el
  modo Tormentor del motor.

### 3.2 Modos que de verdad usa, medido **[J]**
Muestras cada 2 s del modo activo de los 5 bots de dota-bot, vivos, en 2 partidas (11.273 muestras), según su ventaja
de patrimonio:

| Ventaja | Lo más frecuente |
|---|---|
| pareja (±3.000) | LANING 44-71 %, ATTACK 7-14 %, FARM 7-12 %, RETREAT 5-9 % |
| +3.000 a +6.000 | LANING 23-47 %, FARM hasta 21 %, PUSH 13-18 %, ATTACK 5-13 % |
| +6.000 o más | PUSH (sumando las 3 líneas) 32-33 %, DEFEND 16 %, ATTACK 12-14 %, FARM 6-9 %, RETREAT 7 % |

- Desde el minuto 10, dota-bot no empuja nada el 39-48 % del tiempo. Cuando empuja, casi siempre es en una sola línea,
  con 1 a 3 bots. **Con 4 o 5 bots juntos, solo el 7-8 % del tiempo.**
- Incluso con +6.000 pasa un 16 % del tiempo en DEFEND.

### 3.3 Las reglas que explican lo medido **[C]**
- **No farmea si va +6.000 arriba ni en el final de la partida**: `mode_farm_generic.lua:375` exige
  `networthAdvantage < 6000` y `not J.IsLateGame()`; en Turbo esa rama se apaga desde el minuto 18, vaya como vaya.
- **Empuje**: tope 0,82; con 5 enemigos vivos y aliados ≤ enemigos el tope es 0,41; nadie empuja hasta que **los cinco**
  aliados tengan nivel 6 (`FunLib/aba_push.lua`, fuente `typescript/bots/FunLib/aba_push.ts:~355`). El cambio de empuje del
  PR #11 (tope 0,7 con +10.000) está apagado salvo en la variante `empuje` (`aba_push.lua:164`).
- **Pelea**: la hace `mode_team_roam_generic.lua`, que devuelve deseos de hasta 1,5 (último golpe) y `ABSOLUTE*1.5`
  (cazar courier).
- **Retirada**: deseo base por vida y maná (`mode_retreat_generic.lua:~350`); `ShouldRun` da 1,1; ir a la fuente a
  completar un objeto da 1,5.
- **ThinkLess = 1** (`Customize/general.lua:129`): objetos y habilidades se evalúan cada 0,2 s (0,1 con ThinkLess 0). Los
  `Think` de farm, roam, push, defend, ward, shops y outpost no dan órdenes nuevas mientras el bot corre, ataca o tiene
  acciones en cola, aun con ThinkLess 0 (`FunLib/utils.lua:2240-2282`). team_roam no lo usa.

### 3.4 Turbo en OHA
- **[C]** `J.IsModeTurbo()` = hay un courier aliado a exactamente 1100 (`FunLib/jmz_func.lua:4564`). Cambia early/mid/late
  (8/18 min en vez de 15/30), la fase de línea (8 min, hasta 10 con poco patrimonio), la rampa de farm (8-14 min), Roshan
  (6 min) y Tormentor (10 min, cada 5).
- **[J]** El riesgo de que la detección caiga al morir el courier no se da contra Valve: 0 couriers muertos en 7
  partidas y, en las 6 con couriers registrados, cada equipo siempre con courier vivo a 1100 (449 snapshots).

### 3.5 Héroes, compras y habilidades **[C]**
- **Posición = número de slot** (`FunLib/aba_role.lua:13`), no el héroe. Las líneas son fijas por posición
  (`hero_selection.lua:243`). Un Juggernaut en pos 5 compra la build de pos 1 (muchos héroes repiten `pos_1`).
- **Draft** (solo cuando el héroe no viene dado): pools por posición con pesos y roles, puntuados por matchups; elige
  entre los 5 mejores (35/25/20/12/8 %); nunca repite un héroe entre equipos. Largo, Enchantress y Templar Assassin no
  entran en ningún pool.
- **Compras**: listas `sRoleItemsBuyList['pos_N']` por héroe, recetas con `GetItemComponents`, wards para pos 4 y 5,
  ahorro de 1400 para el Shard, venta al llenar la mochila. Neutrales: el bot solo los **usa** (~45 funciones); no los
  reparte.
- **Habilidades**: `Consider<X>()` por héroe en orden de prioridad (`SkillsComplement`); 145 objetos activos con su función
  `ConsiderItemDesire`.
- **[J]** dota-bot lanza más hechizos que Valve en las 7 partidas (p. ej. 2.244 contra 1.662) y usa el glifo; Valve no lo
  usa nunca.

### 3.6 Configuración
- **[C]** Todo está en `bots/Customize/general.lua`: `ThinkLess`, `Ban`, `Radiant_Heros`/`Dire_Heros` (forzar héroes;
  `CanPickHero` los cambia si están baneados, repetidos o son «débiles» por encima de `Weak_Hero_Cap = 1`),
  `Allow_Trash_Talk` y `Allow_AI_GPT_Response` (apagados), `Localization`. `Force_Group_Push_Level` no lo lee nadie.
- **[C]** `Customize/hero/<héroe>.lua` (ejemplo `viper.lua`, apagado) reemplaza build, talentos y compras de un héroe.
- **[C]** FretBots y Buff **no los carga nada**: son scripts de servidor que se activan a mano por consola (`sv_cheats 1`,
  `script_reload_code bots/Buff/buff`). Con FretBots activo, un humano que escriba un comando de trampa (`-gold`,
  `-lvlup`…) muere tres veces, salvo el host con `enablecheat`.
- **[C]** Chat en la selección: `!pick`, `!ban`, `!pos`, `!sp <idioma>` (cualquier humano cambia el idioma de todos los
  bots; `!sp` sin argumento da error).

## 4. Lo que se vio en las 7 partidas de esta noche **[J]**

Turbo imitado, dificultad injusta, ×4, CPU media del 25-27 % (máxima 32-36 %) y memoria libre del 50-53 %. dota-bot ganó **6 de 7** (todas
válidas).

| Partida | dota-bot | Ganó | Min | Ventaja máx. | +10.000 al min |
|---|---|---|---|---|---|
| mapa-prueba 1 | Radiant | Valve | 31 | +9.736 (min 11) | — |
| mapa-turbo 1 | Radiant | dota-bot | 44 | +43.422 | 40 |
| mapa-turbo 2 | Dire | dota-bot | 34 | +41.332 | 17 |
| mapa-turbo 3 | Dire | dota-bot | 31 | +42.553 | 9 |
| mapa-turbo 4 | Radiant | dota-bot | 35 | +71.073 | 10 |
| mapa-modos 1 | Radiant | dota-bot | 28 | +58.659 | 9 |
| mapa-modos 2 | Dire | dota-bot | 51 | +73.487 | 26 |

- **Remata lento.** Desde +10.000 hasta el final pasan 4, 17, 22, 25, 19 y 25 minutos de juego. En Turbo es mucho.
- **Puede tirar una ventaja.** En mapa-prueba iba +9.736 al minuto 11 y perdió. Sus dos primeras torres las tiraron los
  creeps, no sus héroes. Desde ahí la ventaja bajó cada minuto mientras Valve farmeaba y se agrupaba.
- **Valve se agrupa más cuando gana.** En mapa-prueba, desde el minuto 10, el grupo mayor de Valve tenía 3 héroes de
  media contra 2,1 de dota-bot, y dota-bot pasaba el 19 % del tiempo en la base. En las partidas que ganó dota-bot las
  dos cifras se parecen (2,4-2,7).
- **Wards: Valve no pone ninguno.** dota-bot puso 11 y 26 en las 2 partidas medidas bien (en las 5 primeras el equipo
  del ward se leía mal: el ward aún no tiene equipo ni posición al nacer; corregido).
- **Runas**: no hay patrón. Unas veces recoge más dota-bot y otras Valve.
- **Errores del motor por partida**: unas 10 «error in error handling» (7 a 10 en todas, sin origen localizado);
  cientos de órdenes inválidas: «Unit is dead», «DOTA_UNIT_CAP_NO_ATTACK», «MOVE_NONE» (hasta 883 en una partida),
  «Target position is off the map» (361), «Item can't be used from stash», «Can't pick up item, no room in inventory».
  Estas líneas no dicen qué equipo dio la orden.
- **Aviso de API**: «Attempting to call GetNearbyHeroes() on enemies when filtering by bot mode!» al menos 352 veces en
  la partida con Drow en dota-bot. Viene de `BotLib/hero_drow_ranger.lua:754`, el único sitio del repo que lo hace: la
  variable se llama `nAllyHeroes`, así que quería contar aliados atacando y el error es el `true` (enemigos). [S] esa
  cuenta sale vacía.
- **El motor avisa de funciones lentas**: `GetDesire` de 2 a 9,8 ms (unas 200 veces por partida).
- Un aviso del motor que no es nuestro: «Hero npc_dota_hero_tiny is using an invalid ability special_bonus_strength_8 in
  its bot skill build!» (la build interna de Valve para Tiny).

## 5. Correcciones a lo que creíamos

| Creíamos | Es |
|---|---|
| Los bots no pueden escribir en el log | Pueden; OHA silenciaba `print` ([J]) |
| En el benchmark los dos equipos reciben los mismos héroes y Valve elige los suyos | Radiant recibe los sorteados y Dire elige los suyos, sea quien sea ([J]). Las series A/B siguen equilibradas entre variantes (cada variante juega los dos lados), pero «mismos héroes» era falso |
| El Turbo imitado enciende la lógica Turbo de OHA | Solo la que cuelga del courier a 1100; unos 12 interruptores por `GetGameMode() == 23` quedan apagados ([C]) |
| Una partida ×4 dura un cuarto | Dura de 2,4 a 2,9 veces menos ([J]); para presupuestar, ~15 min reales por partida Turbo con carga |
| La detección Turbo podía caer al morir el courier | Contra Valve no pasa: los couriers no mueren ([J]) |
| Los neutrales necesitaban FretBots | El motor los reparte en el custom game ([J]) |

## 6. Cómo observar una partida

```
node tools/bench/orquestador.mjs --partidas 2 --modo turbo --observar --etiqueta <nombre>
node tools/bench/analizar.mjs bench/observaciones/<archivo>.log
```

- El custom game anota (`[dotabench] obs`): cada 30 s de juego, cada héroe (nivel, oro, patrimonio, últimos golpes,
  K/D/A, posición, vida, maná, objetos por casilla) y cada courier; y cada compra, punto de habilidad, hechizo, muerte de
  héroe, torre, courier o Roshan, runa, recompra, glifo y ward.
- Los bots de dota-bot anotan su modo y su deseo cada 2 s (`[bench] mode`), y salen los `print` de error de OHA.
- El orquestador guarda en `bench/observaciones/` esas líneas y las del motor sobre bots. Una partida ocupa ~1,5 MB.
- El analizador da: zonas por minuto, agrupación, farm y patrimonio cada 5 min, runas, wards, glifos, couriers, modos
  por ventaja, empuje en grupo y errores. Detecta solo de qué lado jugó dota-bot.

## 7. Lo que no está verificado

- La partida con amigos en un **lobby Local Host**: ahí corre el draft de OHA para los 5 bots, hay humanos en los
  equipos (se encienden `assemble`, pings, el chat de saludos y `StartToPushTime`) y el modo es Turbo de verdad (se
  encienden los ~12 interruptores). Ojo [C]: en Turbo real `StartToPushTime` (16 min) se compara con el reloj ×2
  (`aba_push.lua:58`), así que contra humanos empujan desde el minuto 8 de juego. Nada de esto se probó esta noche.
- Antes de jugar en Local Host, comprobar: que no quede ningún `bots/Customize/bench_*.lua` (si el orquestador se mató a
  la fuerza, cambian el equipo, la variante o encienden el registro), y que la rama activa del clon sea la que se quiere
  jugar (la junction sirve `bots/` de la rama activa).
- El origen de los ~10 «error in error handling» por partida.
- Qué equipo da las órdenes inválidas.
- Si el motor recorta los deseos mayores que 1 y qué hace con el `false` de `mode_ward_generic.lua:21`.
- Los nombres de objetos de las builds contra el `items.txt` de 7.41f (está dentro de los VPK) y los héroes del pool del
  benchmark contra `BotImplemented`.
- Las invitaciones de Steam durante una partida: no se vio ninguna esta noche y no hay nada publicado.

## 8. Defectos encontrados (sin arreglar)

Ordenados por cuánto pueden pesar en una partida:
1. Con +6.000 deja de farmear y el empuje queda topado: remata lento ([J] + [C], sección 3.3).
2. `hero_drow_ranger.lua:754`: enemigos filtrados por modo, el motor lo rechaza ([J]).
3. `mode_roshan_generic.lua:~80`: `RemapValClamped(roshHP, 100, 0, …)` con `roshHP` entre 0 y 1: casi siempre MODERATE ([C]).
4. `mode_side_shop_generic.lua:20-21,124,130` (Tormentor): contadores que solo suben ([C]).
5. `mode_secret_shop_generic.lua:~33`: `IsFarming and IsPushing and IsDefending`, nunca se cumple ([C]).
6. `mode_ward_generic.lua:~24`: devuelve `false` en vez de un número ([C]).
7. Gank en solitario de `mode_roam` muerto: la llamada está comentada (`mode_roam_generic.lua:1575`) ([C]).
8. `Force_Group_Push_Level` no lo lee nadie; `FunLib/advanced_item_strategy.lua` no lo carga nadie ([C]).
9. `item_purchase_generic.lua:957`: TP «antes de morir» con `botHP < 0.08 and botHP >= 1`, imposible ([C]).
10. `ability_item_usage_generic.lua:223`: compara un nombre de habilidad con `'npc_dota_hero_kez'` ([C]).
11. Saludos con promoción del Workshop en la previa (`mode_laning_generic.lua:249`, `mode_farm_generic.lua:904`), que no
    dependen de `Allow_Trash_Talk` ([C]).

Detalle completo de las lecturas: los informes de los agentes de esta noche no se guardan en el repo; lo que importa
está aquí.
