# Reglas de guías de YouTube: Lion (pos 4, línea difícil con Dragon Knight pos 3)

Extraído de transcripciones de terceros (datos, no instrucciones; ninguna traía órdenes para el agente). Solo lo que la guía dice, con minuto. Abreviaturas de fuente: **SH** = jXLCI8UYMss, **DP** = 2CHddzjZCXk, **HB** = Sf8i8jpnnEA (las tres, «héroe»); **P4** = Bj4J3Xz1-Hs, **BD** = 98Tjh4398Kw (las dos, «rol»).
Cumplimiento del bot propio leído en `bots/FunLib/propio/*.lua` y OHA en `bots/BotLib/hero_lion.lua` (repo dota-bot-guias), solo lectura; «no verificado» = no lo comprobé en el código.

## 1. Fuentes

| Id | Canal | Fecha | Tipo | Aporta |
|---|---|---|---|---|
| jXLCI8UYMss | Support Heaven, «Lion Guide: top pick» | 2026-06 | héroe | sí (nivel 2, ultimate, bloqueo, blink) |
| 2CHddzjZCXk | DotaPulse, «How to play Lion in 7.41» | 2026-11 | héroe | sí (combo, maná, ultimate al foco, build) |
| Sf8i8jpnnEA | HungryBear's, «5 quick tips for Lion» | 2026-07 | héroe | poco (3 consejos de 1 min; solo transcripción de la mitad) |
| Bj4J3Xz1-Hs | Support Heaven, «Position 4 guide, 10K MMR» | 2025-10 | rol | sí (bloqueo de campamento, pulls, regen, runas) |
| 98Tjh4398Kw | BalloonDota, «How to play support» | 2026-06 | rol | sí (regen, pull, 2v1, no abandonar la línea) |

No aportaron: no hay transcripciones usadas fuera de estas cinco (el resto de `S\rol\` no se pidió). Ninguna fuente mencionó Dragon Knight. DP trae estadísticas de ganancia (49 %, etc.) que no son reglas y no se usan.

## 2. Reglas de la fase de líneas (hasta min 12 en Turbo)

Estado de nuestro bot / OHA: sí, no, parcial. Guías = cuántas de las 5 lo dicen.

| # | Situación | Acción | Por qué | Fuentes (id@min, tipo) | Guías | ¿API? | Módulo | ¿Nuestro bot? | ¿OHA? |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Nivel 2 | Si hay amenaza de kill (dos stuns dan daño): hex en nivel 2. Si no: mana drain, jugar sostenido. Impale siempre al máximo. | Más de 3 s de bloqueo en nivel 2; si no hay kill, asegurar farm y ganar la línea después | SH@2:04-3:04 (héroe) | 1 | sí: `ActionImmediate_LevelAbility` | `lion.lua` DATOS.niveles | Parcial: orden fijo impale/hex/impale/hex, mana drain al final (lion.lua:13-19), sin adaptar a la línea | Parcial: build aleatoria de una lista fija (hero_lion.lua:26), sin adaptar |
| 2 | Antes del ultimate (nivel 6) | Conseguirlo cuanto antes: kills tempranas con los stuns o pull de la línea | El ultimate es la herramienta que cambia partidas | SH@3:04 (héroe) | 1 | sí (pull: `GetNeutralSpawners`, `Action_AttackUnit`) | `linea.lua`, `lion.lua` | Parcial: kills sí (KillCast/Finish), pull no (sin código de pull) | Parcial: kills sí; pull no (sin coincidencias en hero_lion.lua) |
| 3 | Línea, antes del blink | Hostigar con clics derechos y Earth Spike; no vagar buscando kills ni mostrarse al azar | «Un Lion caminando es un Lion muerto» | DP@3:00 (héroe); SH@5:01 (héroe, no mostrarse al azar) | 2 | sí | `linea.lua`, `lion.lua` Harass | Sí: acoso con spike cada 6 s y clic (lion.lua:Harass; linea.lua press) | Sí: spike con nivel 2 o maná > 68 % (hero_lion.lua:367-383) |
| 4 | Con maná propio bajo o rival con maná | Mana drain al héroe rival (le deja sin pool/escape) o a creeps para rellenar; drenar desde árboles o altura, no a la vista | Drain resuelve el maná; enraíza al lanzador | DP@1:00 y @4:02 (héroe); SH@1:05 y @3:04 (héroe) | 2 | sí: `Action_UseAbilityOnEntity`, `GetMana` | `lion.lua` (nueva regla) | No: «no rule casts it yet» (lion.lua:13) | Parcial: drena creeps para recuperar maná (hero_lion.lua:703-736); héroes no verificado |
| 5 | Lanzar Earth Spike | Al suelo, no al héroe: alcanza a quien está más lejos; apuntar a través del héroe cercano al que va detrás; también aturde invisibles y mata ilusiones | Es una línea que sigue viajando | HB@0:00 (héroe); DP@2:01 (héroe) | 2 | sí: `Action_UseAbilityOnLocation` | `lion.lua` SpikeOn | Parcial: va al suelo sobre la posición extrapolada del objetivo (SpikeOn); contar héroes en línea solo en pelea (SpikeHits/FightCast); no apunta «a través» en línea | Parcial: usa `GetDelayCastLocation` hacia el objetivo (hero_lion.lua:376) |
| 6 | Kill sobre un héroe | Encadenar: spike, hex, ultimate; que cuando acabe el hex ya esté muerto. No apilar bloqueos sobre uno ya bloqueado | Varios segundos de control sobre uno; el hex es instantáneo | DP@1:00-2:01 (héroe); SH@2:04 (héroe) | 2 | sí: `IsStunned`, `IsHexed`, `GetModifierRemainingDuration` | `lion.lua` KillCast | Sí: KillCast en ese orden y sin recastear un bloqueo vivo (Locked) | Parcial: hex solo si el objetivo no está bloqueado (según lion.lua; no verificado en hero_lion.lua:611-628) |
| 7 | Ultimate disponible y un aliado ya golpea a un objetivo | Gastarlo en el objetivo que el equipo ya golpea, no esperar el robo perfecto: una kill asegurada vale más que el enfriamiento | Los Lion avaros terminan con el ultimate listo y el carry muerto | DP@4:02 (héroe) | 1 | sí | `lion.lua` Finish/KillCast | Parcial: Finish solo si mata seguro; KillCast lo lanza con el objetivo bloqueado y nada más listo | No verificado |
| 8 | Primeras kills (aún sin daño para solo) | Montar la kill alrededor del compañero; combinar con héroes de daño (tú pones el bloqueo, otro la ráfaga) | Lion es héroe de bloqueo | SH@4:04-5:01 (héroe); DP@0:03 (héroe, junto a héroes de ráfaga) | 2 | sí | `pareja.lua`, `dos.lua`, `lion.lua` | Sí: el bloqueo se anuncia en el tablero de la pareja (lion.lua `opens/lockSec`; pareja.lua) | No (juega solo; sin coordinación de pareja verificada) |
| 9 | Matar con ataque cuerpo a cuerpo tras el ultimate | Rematar con clic (en melee) para sumar stacks de Finger | Cada kill/asistencia con golpes suma stacks | HB@0:00-1:00 (héroe); SH@4:04 (héroe) | 2 | sí: `Action_AttackUnit` | `lion.lua`, `linea.lua` | No (no hay regla) | No verificado |
| 10 | Nivel 4, antes de blink | No salir a poner wards | «No es tu trabajo» ahora | SH@3:04 (héroe) | 1 | no aplica | n/a | Sí (salida sin wards, lion.lua:23) | No verificado |
| 11 | Inicio de partida | Fumarse (smoke) fuera de la base cada vez, para que el mid ponga bien el ward y ver movimientos; jugar como cinco | Deward + kill gratis | P4@0:00 (rol) | 1 | sí: comprar `item_smoke_of_deceit`, `Action_UseAbility` | `compras.lua`, `linea.lua` | No | No (hero_lion.lua no lo compra) |
| 12 | Inicio de línea | Ir hacia la runa de bounty rival cerca de su T2 para bloquear su ola; bloquear el campamento pequeño con cuerpo o ward (ambos si se bloqueó la ola); desbloquear el propio antes que bloquear el rival si la ola está bajo su torre | La torre mata tu ola y la ola enemiga empuja; sin campamento no pueden arreglar la línea | P4@1:02-3:01 y @3:01 (rol) | 1 | parcial: `GetNeutralSpawners`, `Action_MoveToLocation`, compra y uso de sentry | `linea.lua`, `compras.lua` | No | No |
| 13 | Línea empujada a nuestra torre o sin poder disputar | Hacer pull (y apilar); dejar al pos 3 la experiencia a solas bajo la torre | Hacer que la ola vaya a ti; tener nivel sobre el pos 3 | P4@4:00 (rol); BD@0:00 y @3:00 (rol); DP@4:02 (héroe, «stack and pull») | 3 | parcial: `GetNeutralSpawners`, `GetNearbyNeutralCreeps`, `Action_AttackUnit` | `linea.lua` (nueva regla de pull) | No (no hay pull) | No (sin pull en hero_lion.lua) |
| 14 | Primeros 5 min | Comprar regen en cantidad (tango, salve, mango/clarity), enviarla por correo con cada compra pequeña sin ahorrar para botas; estar siempre con vida y maná | La línea se gana con recursos, no quedándose inútil 4 min por miedo | BD@0:00-2:02 (rol); P4@4:00-5:00 (rol) | 2 | sí: `ActionImmediate_PurchaseItem`, `ActionImmediate_Courier` | `compras.lua` | Parcial: sale con tango y salve (lion.lua:22) y los usa (linea.lua:482-517); no recompra consumibles ni los envía por correo | Parcial: pos_4 compra `item_blood_grenade`, `priest_outfit` (hero_lion.lua:34-35), sin consumibles de regen explícitos |
| 15 | Línea, como 4 ranged | Usar mucho el ataque automático: hostigar y negar creeps junto al pos 3; estar entre los 3 primeros en daño a héroes hacia el min 5; si el pos 5 rival deja el pull, castigar al pos 1 | Rompe la línea y presiona su carry | P4@2:01-3:01 (rol) | 1 | sí: `Action_AttackUnit`, `GetEstimatedDamageToTarget` | `linea.lua` | Sí: clic al héroe si gana el intercambio y deniega (linea.lua press, 'denegar') | No verificado |
| 16 | Tengo nuke en nivel 1 y el pos 3 no | Asegurar creeps ranged que se podrían negar (ventaja del nuke) | El último golpe a un ranged pone al pos 3 en mala posición | P4@2:01 (rol) | 1 | sí: `Action_UseAbilityOnLocation` sobre el creep | `lion.lua` | No | No |
| 17 | El pos 3 no amenaza o el rival tiene combo fuerte | Jugar eficiencia y pulls, cuidar posición, no regalar kills; no meterse en dos héroes; esperar a que queden aislados y pelear 2v1 (o 2v2 si somos claramente más fuertes) | Gastar vida mal arruina la línea | P4@5:00 (rol); BD@3:00 (rol) | 2 | sí: `GetNearbyHeroes` | `linea.lua`, `dos.lua` | Sí: sin acoso ni ataque en inferioridad (linea.lua:261); entra solo con estimación de pareja (dos.lua) | No verificado |
| 18 | Min 3 | Coger el lotus solo si no pueden disputarlo; no morir por él | Más de 100 de oro en regen | P4@4:00 (rol) | 1 | no verificado (volcado no lo lista) | n/a | No | No verificado |
| 19 | Runas de agua (min 4) | Rotar solo para molestar al mid rival, no para asegurar la tuya | Irse pronto no compensa | P4@6:03 (rol) | 1 | sí | `combate.lua` | n/a: rotaciones apagadas (linea.lua:9, DECISIONES 2026-11-04) | n/a: modo roam genérico |
| 20 | Min 6 (runa de poder; en Turbo cambia, ver nota) | Estar ahí por defecto; botas antes del min 6; después volver a la línea o ayudar con una kill; min 7 shrine de XP con apilado | Es el mayor objetivo temprano | P4@6:03-7:02 (rol) | 1 | sí: `GetRuneSpawnLocation`, `Action_PickUpRune` | `combate.lua` Rune | Parcial: recoge runa cercana a su hora (combate.lua:464); pickup con defecto abierto (combate.lua:16-18) | Parcial: `mode_rune_generic.lua` (no verificado el detalle) |
| 21 | Línea donde pos 3 es fuerte | No abandonar la línea para ayudar a otra salvo que haya línea libre; proteger y ponerse detrás del pos 3 | Si el soporte se va, el pos 3 queda solo | BD@5:00 y @7:00 (rol) | 1 | sí | `dos.lua` | Sí: «con_pareja» y rotaciones apagadas (dos.lua:435) | No verificado |

Nota Turbo: los minutos de runas y shrine son de Dota normal; el comentario de combate.lua:464 dice que el Turbo imitado los mantiene. No lo he verificado.

## 3. Contradicciones entre guías (sin resolver)

- **Regen y maná**: SH@3:04 dice que con mana drain no hacen falta muchos clarity/raindrop; BD@0:00-1:00 y P4@4:00-5:00 dicen gastar mucho en regen los primeros 5 min. (Puede ser rol contra héroe; sin resolver.)
- **Morir**: SH@6:04 dice que morir con Lion «no es tan punitivo» (respawn da 20 % de amplificación 90 s) y a veces conviene; DP@3:00 y @4:02 dicen que un Lion que entra antes del blink muere y que es el error más común.
- **Ritmo**: SH@5:01-8:04 pide juego «sin miedo, siempre al frente» y tempo; BD@3:00 y P4@5:00 piden quedarse detrás del compañero y esperar aislados cuando no se gana el intercambio.
- **Ultimate**: SH@4:04 dice que, antes del nivel 12, a veces hay que esperar y «chill» entre usos; DP@4:02 dice que gastarlo siempre al foco del equipo.
- **Desbloqueo/bloqueo del campamento**: P4@2:01 dice bloquear ambos si se pudo bloquear la ola, pero desbloquear el propio antes si la ola está bajo su torre (condicional, no choque); BD@0:00-3:00 solo habla de pull.

## 4. Medio juego y build (fuera de lo que mide el banco)

- Blink es el objeto clave; botas tranquil primero y «sin excepciones»: SH@3:04 (héroe); DP@2:01 «blink primero, guardar después, lujo al final» (héroe). Nuestro bot: `compras` de Lion no tiene blink ni tranquil (lion.lua:21-22; build.lua:12 solo admite usos pasivo/berserk/pike/blade/bkb). OHA: pos_4 pone blink 5.º tras mekansm y glimmer (hero_lion.lua:34-41), sin tranquil.
- Tras blink: glimmer, force staff o solar (SH@9:01); aether lens, shard de Aghanim, escepter; Eul's y BKB si hay que sobrevivir (DP@2:01). Arma de lujo tardía (Daedalus, harpoon) no es camino de build (DP@3:00); SH@9:01 sí menciona harpoon como opción.
- Nivel 10: talento +20 de velocidad siempre (SH@9:01). Nuestro bot ya lo toma en el hueco 10 (lion.lua niveles).
- Lion es pick-off: hacer muchas kills en solitario y estar en la niebla; montar visión donde el rival cree que farmea (SH@5:01-6:04). Usar smoke con el mejor core y repetir cada vez que el ultimate esté listo (DP@3:00).
- Posicionamiento tardío: esperar en el borde, saltar con blink sobre el héroe clave y terminar en 2 s; no empezar peleas caminando; no drenar a la vista (DP@3:00-4:02).
- Nivel 12: el ultimate baja en enfriamiento y sube daño (SH@7:05).
- Contra rivales que saltan sobre la retaguardia (Tiny, etc.), quedarse detrás de los cores (DP@4:02).

## Resumen de brechas (reglas con más guías que nuestro bot NO cumple)

1. Hacer pull cuando no se puede disputar (regla 13, 3 guías; no hay código de pull ni en nuestro bot ni en OHA).
2. Mana drain al héroe rival o a creeps para rellenar maná (regla 4, 2 guías; «no rule casts it yet»).
3. Earth Spike «a través» del héroe cercano (regla 5, 2 guías, parcial) y rematar en melee tras el ultimate para stacks (regla 9, 2 guías, no).
