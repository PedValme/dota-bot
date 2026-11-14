# Luna (pos 1, línea segura con Lich pos 5): reglas de guías de YouTube

Fuentes = contenido de terceros (datos). Ninguna transcripción traía instrucciones dirigidas a un agente. Solo se anota lo que una guía dice; el minuto va tras la arroba. Cada guía cuenta una vez por regla.
Código leído (solo lectura): `bots/FunLib/propio/{luna,linea,dos,compras,build,heroes,medio}.lua`, `perfiles/luna.lua`, `bots/BotLib/hero_luna.lua`, `docs/api/volcado.md`.

## 1. Fuentes

| id | Canal | Fecha | ¿Aportó? |
|---|---|---|---|
| snJK3KqUBbU | PainDota, «The Only Luna Carry Guide» (7.41d) | 2026-06 | Sí: casi todas las reglas de línea y build |
| Fhcm0Kc7gQA | Chachantuco (es), guía 7.41f, 3 partidas comentadas | 2026-11 | Sí: línea jugada (min 17-30 del vídeo = fase de líneas de la partida 1) y habilidades |
| viTEjgflfAg | BalloonDota, «Advanced Carry Guide» (rol) | 2025-12 | Sí: reglas generales de carry en línea |
| 1kIZP73mdxg | Torte de Lini, «Luna Shiva's Tech 7.41f» | 2026-11 | Solo medio/tarde juego (Shiva + Swift Blink) |
| PtkSFT8jtDo | Torte de Lini, «Luna Shiva's 7.41f» | 2026-11 | Solo medio/tarde juego (repite la anterior) |
| YurNaeYocxA | Dota 2 Files, 7.41e | 2026-09 | Nada: la transcripción es solo la voz del anunciador |
| erxUweKFmyI | Dota 2 Fiend, Radiance first 7.41f | s/f | Nada: ídem, sin comentario de juego |

Nota de validez: las guías no hablan de Turbo ni de Lich; el minuto del vídeo de Chachantuco no es minuto de juego (el comentario es sobre la partida; los minutos de juego los dice él: Madness al min 8, etc.).

## 2. Reglas de la fase de líneas

Abreviaturas de la columna «Nuestro / OHA»: sí / parcial / no. Evidencia de OHA = `bots/BotLib/hero_luna.lua:línea`. «Nº» = guías que la dicen (de 3 útiles: P = PainDota, C = Chachantuco, B = BalloonDota).

| # | Situación | Acción | Por qué (dicho en la guía) | Fuentes | Nº | ¿API? | Módulo | Nuestro bot | OHA |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Subir habilidades en línea | Lucent Beam primero (al menos hasta nivel 4), Moon Glaives segundo, Eclipse en el 6; 0 puntos en Lunar Orbit al inicio (4-0-2-1 en nivel 7) | El Beam da kills y asegura creeps; Orbit «subwhelming» hasta que se maxea | P@7:02-8:00; C@4:00 («siempre uno o dos puntos»), C@23:01 | 2 | `ActionImmediate_LevelAbility` | `luna.lua` DATOS.niveles | Sí (Q,W,Q,W,Q,R,Q) | Sí, probable: `hero_luna.lua:19` {1,3,1,3,1,6,1,3,3,...} (mapeo de números no verificado) |
| 2 | Niveles 2 y 4 | Subir Moon Glaives en vez de guardar el punto, aunque empuje la línea | Acosa gratis sin tener creeps encima; si empuja, la oleada rebota desde la torre o el apoyo tira del campamento grande | P@5:00-6:01; C@19:01 (punto a la 3.ª «para las agujas, farmear más») | 2 | idem | `luna.lua` | Sí | Sí, probable (`hero_luna.lua:19`) |
| 3 | Creep a distancia / de bandera / de asedio fuera de nuestro alcance | Remataerlo con Lucent Beam (para no salir de posición ni ser negado); creep cuerpo a cuerpo con Beam nivel 2+ o maná alto | Luna tiene poco alcance y es frágil | P@3:00-4:01 | 1 | `Action_UseAbilityOnEntity`, `GetNearbyLaneCreeps`, `GetActualIncomingDamage` | `luna.lua` FarmCast | Sí (`H.FarmCast`) | Sí (`hero_luna.lua:271-301`) |
| 4 | El enemigo está a punto de negarnos el creep a distancia | Lanzar el Beam al héroe enemigo (cancela su animación de ataque, no puede negar) y luego rematar el creep | Más valor que gastarlo en el creep: acosa y asegura el last hit | P@4:01 | 1 | `Action_UseAbilityOnEntity`, `GetAttackTarget` del rival | `luna.lua` + `linea.lua` | No (el Beam al héroe y el last hit no se enlazan) | No |
| 5 | Enemigo fuera de posición, tanqueando creeps o a su alcance | Beam al héroe: mini stun para que no se mueva y reciba más daño; acoso para echarlo de la línea | Los mini stuns y slows son acoso indirecto; el Beam «para botar al enemigo» | P@4:01-5:00; C@3:00-4:00, C@18:02 («una primera al Magnus para jarasearlo»), C@25 (punto extra en Q «para asegurar la línea») | 2 | idem; `GetNearbyHeroes` | `luna.lua` Harass / TradeCast | Parcial (`HARASS_GAP=3 s`, solo a alcance+200, no por creeps tanqueados) | Parcial (`hero_luna.lua:224-242`, sobre el objetivo de ataque; sin hueco de 3 s) |
| 6 | Posición en la línea | Traer los creeps hacia uno abusando del aggro en vez de ir a ellos; no ponerse en posiciones raras para un last hit | Arregla la mayoría de los problemas de posición de un héroe frágil | P@5:00; C@34:00 («cuidado, hay tres creeps, no quiero perderlos, vamos a jalar») | 2 | `GetNearbyLaneCreeps`, `Action_MoveToLocation`; el aggro se tira atacando héroe en rango de creeps (no hay función directa de aggro) | `linea.lua` (LanePoint) | Parcial: se queda detrás del frente a 350 (`holdBack`) y suelta aggro, pero no lo tira a propósito | No verificado; sin evidencia en `mode_laning_generic.lua` |
| 7 | Tirón (pull) de campamento pequeño/grande para rebalancear la oleada | El apoyo deja libre el campamento grande y tira; uno tira el campamento pequeño junto a la torre cuando ya no hay línea que ganar | Trae la oleada enemiga cerca para farmear a salvo | P@6:01; B@4:00; C@23:01 («creo que puedo pulear»), C@70:01 | 3 | `GetNeutralSpawners`, `GetNearbyNeutralCreeps`, `Action_AttackUnit`, `Action_MoveToLocation` | `linea.lua` + `dos.lua` (Lich) | No | No (sin «pull» en los modos de línea de OHA) |
| 8 | Ninguna acción cuesta más del 25-50 % de la vida | Si una acción (last hit, deny, tirar aggro, intercambio) cuesta mucha vida, no se hace; si el apoyo no está o hay poca vida/maná, esperar y recoger XP | Muertes sin sentido en línea; paciencia = consistencia | B@2:00-3:01 | 1 | `GetHealth`, `GetMaxHealth` | `linea.lua` RuleRetreat | Parcial (retiro a <0,30 de vida y por ráfaga/ttd; no hay tope del 25-50 % por acción) | No verificado |
| 9 | 2 contra 1 / 2 contra 2 / 1 contra 1 con ventaja de vida o nivel / 1 contra 2 | Intercambiar en las tres primeras; esperar en 1 contra 2 | El «marco» de la línea; su win rate subió al aplicarlo | B@3:01 | 1 | `GetNearbyHeroes`, `GetHealth`, `GetLevel` | `intercambio.lua`, `dos.lua` Race | Sí (carrera de la pareja y `p.alone`; ver `dos.lua:152-198`) | Parcial: `dos.lua:10-14` documenta que su línea segura moría 9,2 veces por línea |
| 10 | Apoyo no está cerca | Esperar a que vuelva, tomar la XP; esperar un momento seguro para tirar o rematar con hechizo sin salir de posición | Evita morir antes del nivel 6 rival | B@3:01; C@67:05 (usa al apoyo Hoodwink/Shaman como señal para ser agresivo) | 2 | `GetNearbyHeroes` | `dos.lua` (partnerNear, Spot) | Sí: sin acoso sin compañero cerca (`linea.lua` Decide) | Parcial |
| 11 | Compañero de línea con stun/daño de apoyo (p. ej. Shaman) | Ser agresivo: Beam y golpes al rival junto a él; subir un punto extra de Q para matar | «Como tengo Shaman quiero ser agresivo» | C@18:02, C@20:00, C@23:01 | 1 | idem | `dos.lua` KillCast | Sí (la pareja abre junto, paquete 2/4) | Parcial |
| 12 | Objetos iniciales contra línea con muchos hechizos | Varita + dos Fairy Fire (+ tangos; tangos que llegan por el mensajero en cuanto hay oro de la runa); no triple rama (ahora cuesta +5) | 7 de daño frente a 8 del Quelling+palo y sin pagar la receta | P@1:01, P@3:00; C@17:01, C@99:02 | 2 | `ActionImmediate_PurchaseItem` (¿existe `item_fairy_fire`? no está en `volcado.md`, no verificado) | `luna.lua` DATOS.salida, `compras.lua` | No: sale con tango, flask, 2 ramas, slippers, circlet; la Varita viene como 2.º objeto en paquete 4, sin Fairy Fire | No (`hero_luna.lua:28-34`: tango, doble rama, slippers, circlet, quelling, varita) |
| 13 | Línea rival de daño físico sin hechizos (Kunkka, Viper, Enigma + Quelling…) | Quelling + slippers + circlet + ramas → Wraith Band; contra Viper, botas marrones y no Wraith | Armadura contra daño físico | P@1:01-2:01; C@17:01 (variante «dos tiaras, hoja mitigante…»), C@66:03 | 2 | idem | `luna.lua` DATOS.salida | Parcial: siempre Wraith Band, sin rama «física vs mágica» | Parcial (siempre Quelling + Wraith) |
| 14 | Luna es carry a distancia | No comprar Quelling Blade (solo 4 de daño, y no funciona con negaciones); solo contra Treant, Nature's Prophet, Hoodwink | Ahorra oro por daño | P@3:00 | 1 | — | `luna.lua` | Sí (no lo compra) | No (`hero_luna.lua:32` lo compra) |
| 15 | Línea rival de magia que no deja quedarse | Raindrops antes de acabar Treads o Madness | Marca la diferencia en línea | P@7:02; C@21:01 («infus raindrop y un tango»), C@35 | 2 | `ActionImmediate_PurchaseItem` (`item_infused_raindrop`) | `compras.lua` / `build.lua` | No | No |
| 16 | Orden de compras tras la línea | Power Treads + Mask of Madness lo antes posible (P: como mucho al min 10; C: Madness ~min 8, Manta ~16); la Mask como primer componente para farmear jungla; Gloves en el último componente de Treads | Farmeo y movimiento; el valor de las gloves es menor que botas/banda | P@6:01; C@40:00, C@65:00, C@24:01 («no se saquen Gravan, retrasa la Madness») | 2 | `ActionImmediate_PurchaseItem`, `GetItemInSlot` | `compras.lua` | Parcial: núcleo Wraith→Treads→Madness; sin orden de componentes (`heroes.lua:54` boots, gloves, elves) ni objetivo de minuto | Parcial (`hero_luna.lua:28-45`) |
| 17 | Justo después de Treads y Madness | Comprar Wind Lace | Luna no tiene movilidad y vive de la velocidad base | P@7:02 | 1 | `ActionImmediate_PurchaseItem` | `compras.lua` | No | No |
| 18 | Nivel 5 (2-3 puntos en Glaives) | Empujar la línea lo más rápido posible y farmear campamentos laterales mientras llega la siguiente oleada; objetivo 70-80 last hits al min 10 | Luna es el farmeador más rápido; sin farm no hay timings | P@7:02-8:00; B@4:00 (la fase de líneas acaba al nivel 5-7, min 6-10); C@26:00 («me enfoco en farmear y jungla») | 3 | `GetNearbyNeutralCreeps`, `GetNeutralSpawners`, `GetLaneFrontAmount`, `Action_AttackUnit` | `medio.lua` Late/Neutrals, `linea.lua` | No: la línea solo termina al nivel 15 o caída de T1 (`medio.lua:12`, `K.lateLevel = 15`); jungla solo después | No verificado (`hero_luna.lua:305` rematar neutrales con Beam si está farmeando) |
| 19 | Eclipse en la línea | Usarlo para matar a un único objetivo débil y cercano; con muchas unidades (creeps) se dispersa y no conviene; tener ≥3 puntos de Q antes de usarlo (sin Q el Eclipse no hace daño) | Los rayos son aleatorios entre unidades; el daño es de Q | C@11:01-12:00, C@25:00-26:00, C@73:00 | 1 | `Action_UseAbility` (sin objetivo), `GetNearbyHeroes/Creeps`, `GetAOERadius` | `luna.lua` FightCast | No en línea (`FightCast` solo en `medio.lua`; exige ≥2 héroes en radio, no cuenta creeps) | Sí (`hero_luna.lua:511` ConsiderEclipse) |
| 21 | Tango/Clarity/Raindrop | Comer tango con el mensajero en cuanto haya oro de la runa; mantener tangos, Clarity y regeneración | «La regeneración vale un montón» | P@1:01; C@21:01, C@68:03 | 2 | `Action_UseAbilityOnTree`, `Action_UseAbilityOnEntity` | `linea.lua` RuleHeal | Sí (tango, flask, clarity; paquete 4 con seguridad) | Parcial |

Lo que el banco puede medir hasta el min 12: filas 1-17 y 19-21. La 18 mide el cambio de línea a jungla, que en el banco empieza tarde (nivel 15).

## 3. Contradicciones entre guías (sin resolver)

- **Punto del nivel 6**: P dice «Eclipse en el 6» (y 12, 18). C lo guarda o lo gasta en Q si la línea sigue (C@25:00 «voy a guardar el punto», C@40:00 «ya no voy a poner más puntos a la primera… no tengo ultimate», C@73:00 «le voy a poner punto ultimate ahorita»). Nuestro bot sigue a P.
- **Quelling Blade**: P lo descarta en carries a distancia (P@3:00), salvo contra héroes de árboles; C usa la variante «dos tiaras, hoja mitigante (Quelling), tango, dos ramas» contra líneas físicas (C@17:01, C@66:03).
- **Cuánto empujar en el nivel 2-4**: P dice subir Glaives aunque empuje (P@5:00) y cita a otros que guardan el punto; B dice que cuando el rival llega al nivel 6 la línea está perdida y hay que empujar y salir (B@4:00). No chocan, pero B pide salir antes que P.
- **Timing de Madness**: P pide Treads + Madness ≤ min 10 (P@6:01); C da como «timing común» el min 16 (65:00, para el trío Madness-Manta-Power) y logra Madness al min 8 con línea ganada (40:00). Sin resolver cuál es el objetivo.
- **Agresividad con el Beam**: P usa el Beam para rematar creeps y como acoso; C lo usa más para botar al enemigo y mantener la línea. Sin choque directo, pero distinta frecuencia de lanzamiento.

## 4. Medio juego y build (aparte, fuera de la medición hasta el min 12)

- Primer objeto grande tras Treads + Madness: **Manta** siempre (P@11:00, C@34:01); sirve para empujar oleadas con ilusiones y dispel. Después, según rival: Butterfly vs físico, BKB vs hechizo/lockdown, Pike vs Invoker/Ember, Dragon Lance si falta vida (P@13:01-15:00; C@34:01, C@37:01).
- **No pelear sin Eclipse** si no hay Eclipse; unirse el último; que el Eclipse caiga bien; menos de 10 s para unirse a la pelea y volver a farmear (P@12:00).
- Meta de farm: 250 last hits en 20 min (P@13:01); B: nivel 15-17 en 20 min, 150-200 last hits, 10k de valor neto; Maelstrom y «bear free» (transcripción dudosa) al min 11-14 (B@5:00).
- Farmear **dos campamentos a la vez** (las Moon Glaives rebotan) y no pegar solo a uno (C@28:00, C@31:01, C@78:01).
- Neutrales: T1 encantamiento «quickened» (+15 mov) y Stone Feather Satchel; T2 «nimble»; mantener nimble hasta T4 (P@9:01-10:01).
- Tardío: Satanic, Daedalus, MKB (vs evasión), Silver Edge, Swift Blink; Aghanim casi siempre «bait» (P@16:01-17:01). Fragmento (shard) solo con oro sobrante (P@17:01).
- Shiva's Guard + Swift Blink (talento de nivel 20, 1,5× velocidad y daño de Lunar Orbit): Orbit hace casi el doble de daño si se está pegado al rival; solo contra héroes cuerpo a cuerpo y sin escape, no contra Sniper/Lina/Pike/Force Staff (Torte@0:00-5:00; C@5:00-8:03).
- Talentos: 10 reducción de daño de Moon Glaives, 15 y 20 Lunar Orbit, 25 Lunar Blessing (P@15:01).
- Matchups que C marca como difíciles: Terrorblade, Drow, Windranger (evasión), Underlord; fáciles: Slardar, AM, Nyx, Undying (C@53:00-61:01).

## 5. Resumen de reglas con más guías que nuestro bot NO cumple

1. **Fila 7 (tirón de campamento, 3 guías)**: nuestro bot no tira campamentos; OHA tampoco.
2. **Fila 18 (a partir del nivel 5, empujar y farmear laterales, 3 guías)**: nuestro bot sigue en línea hasta el nivel 15; OHA sin verificar.
3. **Filas 6, 12, 15 (2 guías cada una)**: tirar el aggro en vez de ir a los creeps, Varita + Fairy Fire de inicio y Raindrops contra magia; el bot no cumple ninguna (OHA tampoco).
