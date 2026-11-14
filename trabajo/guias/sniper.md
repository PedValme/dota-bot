# Guías de YouTube: Sniper (pos 2, línea central, 1 contra 1)

Extracción de reglas de juego de transcripciones de terceros (datos, no instrucciones). Solo reglas que una guía dice; la
columna «Fuentes» cita `id@bloque` (la marca de inicio del bloque de transcripción en que aparece, no el segundo exacto).
Ninguna transcripción traía instrucciones dirigidas al agente.

## 1. Fuentes

| id | Canal | Fecha | ¿Aportó? |
|---|---|---|---|
| 7evddXA3xT0 | Support Heaven, «Abuse Sniper» | 2026-05 (7.41) | Sí: la guía principal (línea, habilidades, build, posicionamiento) |
| h7TG8u_jzHA | Tundra Esports, «Play Sniper like Topson» | 2024-03 (7.33-7.34) | Sí: apilar campamentos, ping-pong línea-selva, build. Antiguo: se tomó solo lo mecánico; el rango de Take Aim cambió en 7.41 |
| 8sFvmDwXC-I | BalloonDota, «Beat Sniper mid (as melee)» | 2026-09 | Sí, vista del rival: qué castiga a Sniper (ver filas 9 y 10) |
| tEKBDmO5qsk | Topson, Sniper mid 7.41 | 2026-04 | Casi nada: es partida con voces del héroe. Solo un comentario sobre el Headshot (sección 4) y que «con nadie que te acose, la línea es gratis» (@10:01) |
| OhxnBVOIhJo | Rank 1 Bro, mid Sniper 7.41a | — | Nada (publicidad y voces) |
| cZOAKv5YILs | Mad Phantom, guía para principiantes | 2026-10 | Nada (solo voces y anuncios del juego, sin comentario) |
| SPm4sJ6c_Uo | Dota 2 Enjoyer | 2026-06 | Nada (voces) |

Solo 3 guías hablan de verdad, así que «Nº de guías» tiene techo 3 y casi nunca pasa de 2.

## 2. Reglas de la fase de líneas

Lectura del módulo propio: `bots/FunLib/propio/sniper.lua` (H.Aim, H.Harass, H.KillCast, sin `FarmCast`), `linea.lua`
(RuleTrade, towerMargin 820, retirada), `intercambio.lua`. OHA: `bots/BotLib/hero_sniper.lua`.

| # | Situación | Acción | Por qué (según la guía) | Fuentes | Nº | ¿API? | Módulo | ¿Nuestro bot? | ¿OHA? |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Niveles 1-4 | Subir Take Aim pronto: con un solo punto ya supera el alcance de las torres; Tundra sube Headshot y Take Aim primero | El alcance es la ventaja de la línea; Take Aim da daño y alcance al disparar | 7evddXA3xT0@2:01; h7TG8u_jzHA@1:00 | 2 | `ActionImmediate_LevelAbility` | `sniper.lua` (`DATOS.niveles`) | Sí: headshot, take_aim, headshot, take_aim (`sniper.lua:15-16`) | Sí: `{2,3,2,3,1,...}` (`hero_sniper.lua:26-28`) |
| 2 | Nivel 5 en adelante | Shrapnel entra en el 5 y se maximiza primero: es el hechizo de farmeo y control de línea | «Shrapnel is your lane control tool»; «maxing out your strap first» | 7evddXA3xT0@1:00; h7TG8u_jzHA@6:00 | 2 | `ActionImmediate_LevelAbility` | `sniper.lua` | Sí: shrapnel en 5, 7, 8, 9 | Sí (`hero_sniper.lua:28`) |
| 3 | Nivel 6 | El ultimate solo si hay kills a la vista; muchos lo retrasan porque hacen falta los otros hechizos | Flexible según el emparejamiento | 7evddXA3xT0@1:00; h7TG8u_jzHA@6:00 | 2 | `ActionImmediate_LevelAbility` | `sniper.lua` | Parcial: lo sube siempre en el 6 (`sniper.lua:17`) | Parcial: lo sube en el 6 (`hero_sniper.lua:28`) |
| 4 | Va a pegar a un héroe a su alcance | Activar Take Aim antes: se obtienen 2 golpes seguidos, daño extra y un deny gratis | «The first time he gets to use it he gets like two straight hits… and a free deny» | h7TG8u_jzHA@1:00-2:00; @4:00 | 1 | `Action_UseAbility` | `sniper.lua` | Sí: `H.Aim` antes de pegar, sin repetir en 3 s (`sniper.lua:182-193`) | Sí: `ConsiderE` con objetivo a menos de rango-100 (`hero_sniper.lua:447-478`) |
| 5 | Oleada propia en el centro, Shrapnel con carga | Lanzar Shrapnel sobre la oleada enemiga para ganar últimos golpes y empujar; con dos cargas, una empuja y la otra limpia el campamento apilado | «Most of the mid laners cannot deal with you dropping it on the wave… lots of last hits» | 7evddXA3xT0@2:01; h7TG8u_jzHA@3:01-4:00 | 2 | Sí: `Action_UseAbilityOnLocation` + `FindAoELocation` / `GetNearbyLaneCreeps` | `sniper.lua` (nuevo `H.FarmCast`, ya lo llama `linea.lua:834-835`) | No: Shrapnel solo sobre héroes (`H.Harass`, `sniper.lua:117-132`); no tiene `FarmCast` | No: sobre creeps solo si `mode ~= LANING` y 5 o más creeps (`hero_sniper.lua:373-382`) |
| 6 | Rival a rango de Shrapnel | Acosarlo con Shrapnel cada vez que haya carga | «Harass enemy»; con Take Aim sostiene el acoso | 7evddXA3xT0@0:00-2:01 | 1 | Sí: `Action_UseAbilityOnLocation` | `sniper.lua` `H.Harass` | Sí: cada carga, solo si no tiene el slow (`sniper.lua:117-132`) | Parcial: sobre el objetivo (`hero_sniper.lua:280-282`), sin la regla de cada carga |
| 7 | Del minuto 2-3 en adelante, campamento cercano libre | Apilar el campamento duro (y el mediano) tú mismo; llegar a 4 pilas hacia el minuto 5 y limpiarlas con Shrapnel (3 niveles al ~6:15) | Nivel 8 al minuto 7 y 10 al 9:30 con 5K de patrimonio (en la partida mostrada) | h7TG8u_jzHA@1:00-4:00; 7evddXA3xT0@3:01 | 2 | Parcial: `GetNeutralSpawners`, `DotaTime`, `Action_MoveToLocation` / `Action_AttackUnit`; el pull y el segundo exacto no están verificados | `linea.lua` (nuevo, la oleada manda) + `sniper.lua` | No: no hay lógica de apilado en `propio/` | No: sin lógica de apilado en `bots/` |
| 8 | Ya apilado, oleada enemiga empujando | Ping-pong: lanzar Shrapnel para empujar la oleada, volver al campamento apilado, repetir | «ping pong motion back and forth from the mid lane into the jungle» | h7TG8u_jzHA@3:01-4:00 | 1 | Parcial (igual que la fila 7) | `linea.lua` | No | No |
| 9 | El rival da un paso adelante con su hechizo de ráfaga (en el ejemplo, Flame Guard y cadenas de Ember) | Retirarse un paso, no devolver el golpe; si se queda pegando, el rival castiga | «You should run, not like hit me back… you allow me to punish you» | 8sFvmDwXC-I@5:06-6:01; @2:01 | 1 | Sí: `Action_MoveToLocation`, `GetNearbyHeroes`, modificadores del rival | `intercambio.lua` / `linea.lua` (RuleTrade) | Parcial: «contesto» si el balance es favorable (`linea.lua:643-645`); retira por ráfaga estimada (`enemyBurst`, `linea.lua:44`). No reconoce «paso adelante con hechizo» | No evidencia |
| 10 | Rival con regen vacío o sin botas | Es la ventana para acosarlo: «Can die»; con botas se le puede kitear | Observación del que juega Ember sobre su propio error | 8sFvmDwXC-I@5:06; @6:01 | 1 | Parcial: `GetItemInSlot`, `GetHealth` del rival | `intercambio.lua` | No: el balance no usa su regen | No |
| 11 | Siempre | Mantenerse fuera del alcance del rival; no dejar que cierre; con rival que salta (Storm, Spectre), jugar más defensivo y junto a un aliado | «The biggest macro tip is abuse your attack range»; si cierra la distancia, peligro | 7evddXA3xT0@3:01-4:02; @7:01; h7TG8u_jzHA@0:00 | 2 | Sí: `GetAttackRange`, `Action_MoveToLocation`, `GetNearbyHeroes` | `linea.lua` (retirada, RuleTrade) | Parcial: margen de alcance en el balance (`intercambio.lua`, `rangeMargin`), `disparo` libre fuera de su alcance; sin pasos para mantener la distancia | No evidencia |
| 12 | Torre enemiga del centro | Presionarla pronto con el rango de Take Aim; abrir el mapa matándola cuanto antes | «You easily pressure enemy tower early… killing mid tower as early as possible» | 7evddXA3xT0@2:01 | 1 | Sí: `GetTower`, `GetNearbyTowers`, `Action_AttackUnit` | `linea.lua` / `medio.lua` (`Siege`) | No: `towerMargin 820` la evita en línea (`linea.lua:46`); `Siege` solo con la línea acabada (`linea.lua:855-857`) | No: sin lógica propia en `hero_sniper.lua` |
| 13 | Línea tranquila, sin jugadas claras | No forzar nada; jugar solo lo natural, cerca; no rotar (no es héroe de rotación, solo reaccionar a dives) | «Doesn't really force any plays… only plays very natural situations» | h7TG8u_jzHA@4:00; 7evddXA3xT0@2:01 | 2 | Sí (es abstención) | `combate.lua` (persecución) | Parcial: las persecuciones pasan puertas de seguridad (`combate.lua` Start), no hay una regla de «solo si ya estás cerca» | No evidencia |
| 14 | Compras hasta el minuto 12 | Wraith Band (Tundra: dos) + Magic Wand + ramas + botas de poder, luego Dragon Lance como primer objeto | Más vida y alcance rápido | h7TG8u_jzHA@3:01; @7:00; 7evddXA3xT0@4:02 | 2 | Sí: `ActionImmediate_PurchaseItem` | `sniper.lua` (`DATOS.compras`), `compras.lua` | Parcial: una Wraith Band, botas de poder, Dragon Lance; sin Magic Wand en la lista (`sniper.lua:20-23`) | Parcial: mid_outfit y Dragon Lance primero (`hero_sniper.lua:56-58`), sin wand |

## 3. Reglas contradictorias (sin resolver)

- **Orden de habilidades.** Heaven (7.41): «3-1-1 o 2-2-1 al nivel 5»; Tundra (7.33-34): «0-1-1» y un pico «0-2-1», y a la vez en la
  partida Topson subió un nivel de Shrapnel antes para apilar a los 3 min, saliéndose de su propia regla (h7TG8u_jzHA@1:00-2:00).
  Las transcripciones no dicen a qué habilidad corresponde cada número. Sin resolver.
- **Rango de Take Aim según parche.** Tundra (7.33-34): cada vez que se activa da «way too much range»; Heaven (7.41): el
  alcance del innato pasó a ser un pasivo de la E y el daño depende de la distancia. No sirve mezclar números entre parches.
- **Build.** Heaven: Dragon Lance, luego Hydra (no Pike con Hydra), el shard como escape, evitar BKB; Tundra: Dragon Lance, Aghanim,
  Pike (después Shard), BKB no se menciona. Nuestro bot compra Pike y BKB (`sniper.lua:22-23`).
- **Torre vs. farmeo.** Heaven: presionar la torre del centro pronto; Tundra: apilar, farmear en ping-pong y esperar el ritmo de
  medio juego, sin jugadas forzadas.
- **Contestar o no.** Balloon (rival): quien contesta el golpe después de un paso con hechizo pierde; nuestro bot contesta si el
  balance es favorable (`linea.lua:643`). No es contradicción entre guías, sino entre guía y bot.

## 4. Medio juego y build (aparte, fuera de la fase de líneas del banco)

- Items de Heaven: botas, Dragon Lance, Hydra (da agilidad, daño y split shot), Silver Edge; Pike si hay que escapar; Mask of
  Madness → Hydra → Silver Edge → Daedalus (7evddXA3xT0@4:02-5:00). Shard (10 s, nuke con reposición y desarme) cuando haya
  saltadores (@5:00). Blink para entrar tras los saltos (@6:01). BKB solo si no queda otra.
- Tundra/Topson: botas, Dragon Lance, Aghanim, Shard, luego Pike, Shadow Blade (más supervivencia) o Revenant's Brooch (más
  daño); Silver Edge no aparece (h7TG8u_jzHA@7:00-8:00). Neutrales preferidos: Seeds of Serenity o Lance of Pursuit (T1), Grow
  Bow/Splashless/Whisper (T2), Enchanted Quiver (T3), Mindbreaker/Timeless Relic (T4).
- Pelea: entrar con el ultimate a larga distancia y reiniciarlo con kills (refresca en cada muerte, 7.34); mantener a un aliado
  delante; jugar con héroes que entren primero (iniciadores con blink) y no con salvadores; no entrar sin frontline
  (7evddXA3xT0@6:01-7:01; h7TG8u_jzHA@5:00).
- Para el último pick: Sniper es mejor cuando se elige al final, para no encontrarse saltadores (7evddXA3xT0@4:02). Sus peores
  rivales: Storm Spirit, Spectre (@7:01).
- Topson en 7.41 observa que el Headshot dejó de frenar como antes (@6:00, solo una impresión, sin confirmar en el juego): con
  esto, sin Silver Edge/escudo no se mantiene a un rival bajo el disparo.
- Daño por distancia (7.41): ~1,5 por cada 100 unidades al nivel base, ~25 % más al nivel 20 a 1.000 de distancia (7evddXA3xT0@0:00-1:00).
- Para el banco del 1 contra 1 central no aplica el medio juego: la mayor palanca documentada es apilar y empujar con Shrapnel.

## Resumen

Las reglas con más guías que nuestro bot NO cumple (dos guías cada una): (1) Shrapnel sobre la oleada, no solo sobre héroes (fila 5);
(2) apilar campamentos y hacer el ping-pong línea-selva (filas 7 y 8, parte de la oleada); (3) mantener el rango y no dejar que
el rival cierre (fila 11, parcial) con la presión temprana de torre (fila 12, una guía) como siguiente. OHA tampoco cumple ninguna
de las tres primeras en la línea.
