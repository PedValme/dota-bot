# Criterios de juego de equipo para el cerebro de dota-bot

Catálogo de diseño para `team_desires.lua` + un plan de equipo que los modos obedecen. Investigación solo de lectura
del 2026-10-30, pedida por Pedro (DECISIONES 2026-10-30: «las mecanicas del juego en profundidad y de criterio no solo
timings oro y mecanicas superficiales»). La sonda de ese día confirmó en el juego que un módulo cargado con `require`
desde `team_desires.lua` comparte estado con los bots del mismo equipo.

Fuentes, marcadas en cada afirmación:
- **[G]** conocimiento del juego (Dota 2, parche 7.3x-7.41). Las cifras llevan «≈» cuando pueden haber cambiado en 7.41
  y hay que confirmarlas en el `npc_abilities.txt` / `items.txt` de 7.41f (en los VPK) antes de fijarlas en el código.
- **[C]** leído en el código de este repo, `ruta:línea` (las líneas pueden moverse unas pocas).
- **[API]** lo que dice `docs/BOT_API_REFERENCE.md`.
- **[S]** supuesto sin verificar; cada uno dice cómo verificarlo.

---

## 0. Tres hallazgos del código que condicionan todo el diseño [C]

1. **`J.WeAreStronger` ignora cooldowns y maná.** Calcula `ourPower` (con `GetOffensivePower`, que respeta cooldowns)
   y `ourPowerRaw`, pero decide con `ourPowerRaw > enemyPower` (`FunLib/jmz_func.lua:4734`). Es decir: «somos más
   fuertes» vale lo mismo con las ultis listas que con todas gastadas. Y solo cuenta héroes **visibles** en el radio
   (`GetUnitList(UNIT_LIST_ALL)` filtrado por distancia, `:4657-4699`): los enemigos en niebla no existen. Lo usan la
   retirada (`mode_retreat_generic.lua:170`, `:360-361`), la defensa (`FunLib/aba_defend.lua:1044`) y
   `ShouldNotRetreat` (`mode_team_roam_generic.lua:1310`).
2. **`J.IsInTeamFight` = «hay ≥ 2 aliados en modo ATTACK a 1200»** (`jmz_func.lua:1452-1458`), y el modo ATTACK lo
   mueve Valve (mapa §3.1). Casi todas las ultis de iniciador esperan a esa condición (Ravage
   `BotLib/hero_tidehunter.lua:762`, Reverse Polarity `hero_magnataur.lua:637`, Black Hole `hero_enigma.lua:647`,
   Chronosphere `hero_faceless_void.lua:441`). Consecuencia: **las ultis de iniciación no inician**; se lanzan cuando la
   pelea ya empezó, como ultis de reacción.
3. **`J.IsDisabled` sobre un enemigo es un booleano sin tiempo restante** (`jmz_func.lua:1385-1391`): rooted, stunned,
   hexed, nightmared o taunted. Para aliados sí mira el tiempo (`GetRemainStunTime > 0.8`, `:1395`). Los héroes lo usan
   como `not J.IsDisabled(objetivo)` antes de cada stun (483 usos en `BotLib/`; p. ej. Lion `hero_lion.lua:583,617`,
   Tide `hero_tidehunter.lua:751,769`, Magnus `hero_magnataur.lua:333`). Evita solapar, pero **no encadena**: el
   siguiente stun solo se considera cuando el anterior ya acabó, y entonces llega tarde por el tiempo de
   lanzamiento + viaje + el intervalo de pensamiento (0,2 s con `ThinkLess = 1`, mapa §3.3).

Más dos defectos que pesan en la macro:
- **La defensa se apaga si el equipo empuja.** `aba_defend.lua:915-937`: si cualquier aliado está en modo push con
  ≥ 3 aliados a 1600, la defensa de **todas** las líneas vale `VeryLow`, aunque haya megacreeps en el Ancient. La
  excepción de pánico (`enemiesOnHG >= 2`, `:947`) va después y nunca se alcanza. Explica bien «deja caer la base yendo
  por delante».
- **Recompra por Ancient en peligro, rota.** `ability_item_usage_generic.lua:569`: `ancient:GetHealth() < 0.8` compara
  la vida absoluta (miles) con 0,8: solo es cierto con el Ancient ya muerto. Además nadie recompra por debajo del nivel
  16 (`:542`).

---

## 1. Medir el poder de pelea (la base de todos los demás criterios)

**Principio [G].** Un equipo bueno no pelea por «quién tiene más oro», sino por la pelea *que va a ocurrir en los
próximos 10-20 s*: cuántos héroes llegan de cada lado (vivos, cerca, con TP), qué ultis hay listas, quién tiene BKB o
salvadas, y quién tiene la iniciación. Picos típicos: nivel 6 (primera ulti), Blink en el iniciador, BKB en el carry
(≈9 s de inmunidad a magia [G≈]), nivel 12/18 (ulti nivel 2/3, talentos 10/15/20), Aghanim. Una ulti de 120-160 s
de cooldown en espera vale más que 2.000 de oro en la pelea siguiente.

**Lo que la API permite saber [API].**
- Vivos y reaparición: `IsHeroAlive(pid)` para todos; `GetRespawnTime()` del héroe (en enemigos [S]: comprobar que da
  algo con el héroe muerto, si no, estimarlo por `GetHeroLevel(pid)` y la tabla de reaparición ×0,75 del custom game).
- Niveles: `GetHeroLevel(pid)` de los diez. Objetos: `GetItemInSlot` en enemigos visibles [S] (OHA lo hace en varios
  sitios; verificar que el slot del enemigo se lee).
- Poder: `GetOffensivePower()` (con cooldowns) y `GetRawOffensivePower()`; `GetEstimatedDamageToTarget(true, t, d,
  DAMAGE_TYPE_ALL)` con `bAvailable=true` solo cuenta lo lanzable.
- Ultis aliadas: `GetAbilityInSlot(5)` o por nombre, `GetCooldownTimeRemaining()`, `IsFullyCastable()`.
- Stun disponible: `GetStunDuration(true)`, `HasBlink(true)`, `HasSilence(true)`.
- Posición de enemigos en niebla: `GetHeroLastSeenInfo(pid)` (`location`, `time_since_seen`).
- Refuerzos: `GetIncomingTeleports()` (`playerid`, `location`, `time_remaining`): ¿incluye los TP enemigos? [S]: el
  efecto de TP enemigo es visible en el juego; verificarlo con una partida observada.
- Recompra propia: `HasBuyback()`, `GetBuybackCost()`, `GetBuybackCooldown()`.

**Lo que NO se puede saber [API].** Cooldowns enemigos (`GetCooldownTimeRemaining` devuelve 0), recompra enemiga
(`HasBuyback` = false, coste -1), héroes enemigos en niebla más allá de su última posición, oro sin gastar enemigo.
Inferencia posible [S]: registrar cuándo vemos lanzar una ulti enemiga (comparar cada frame `IsCastingAbility()` /
`GetCurrentActiveAbility()` de los enemigos visibles, o `InstallCastCallback` si acepta pids enemigos) y suponerla en
cooldown durante su cooldown base (`GetCooldown()` de la habilidad del enemigo, si se lee). Recompra enemiga: suponer
que la tienen si su patrimonio estimado lo permite y no la vimos usar (el `[dotabench] obs` del custom game ve las
recompras, pero el bot no).

**OHA hoy [C].** Sin modelo de pelea de equipo: cada bot calcula `WeAreStronger` en su radio, con poder bruto, sin
ultis ni refuerzos (hallazgo 0.1). La retirada sí suma enemigos vistos hace ≤ 5 s a ≤ 3200
(`mode_retreat_generic.lua:308-320`).

**Brecha y propuesta.** En el **cerebro de equipo**, una función `EvaluarPelea(lugar)` llamada en `TeamThink` cada
0,5 s que devuelva un número firmado y sus partes:
- héroes que llegan en ≤ 8 s por cada lado (vivos, distancia / velocidad, TP en curso, enemigos vistos hace < 6 s);
- poder con cooldowns (`GetOffensivePower`) para los aliados, y para los enemigos poder bruto **menos** las ultis que
  vimos lanzar hace menos de su cooldown;
- bonos: iniciación disponible (blink + ulti de control lista), BKB disponible en el carry, Aegis, torre propia cerca;
- penalizaciones: enemigos sin ver con `time_since_seen` < 10 s que pueden estar en la zona.
El resultado lo leen todos los modos en vez de su `WeAreStronger` local. Riesgo: un peso mal puesto hace que el equipo
entero se tire o huya a la vez (antes solo fallaba un bot). Mitigar con histéresis (cambiar de «pelear» a «huir» solo
si la evaluación cruza un umbral distinto) y medirlo en serie A/B.

---

## 2. Caza de un aliado: ir a salvarlo o cederlo y reagrupar

**Principio [G].** Cuando atrapan a un aliado, la pregunta es «¿llegamos a tiempo y ganamos la pelea que resulta?», no
«¿está cerca?». Se va si: el aliado puede sobrevivir hasta que lleguen (vida, salvadas propias, el enemigo ya gastó su
control), llegan suficientes (ventaja numérica en el lugar tras la llegada), las ultis propias están listas y la
posición no es la del enemigo (bajo su torre, en su jungla sin visión, o con enemigos sin ver). Si no, se cede: el
aliado muere solo (1 muerte) en vez de 3-4 llegando de uno en uno. Al ceder, los demás aprovechan el tiempo en que los
enemigos están ocupados y lejos: farmean el lado opuesto, empujan una línea lejana o toman un objetivo (cambio de
mapa). Regla práctica: **nunca llegar de uno en uno**; si hay que ir, se va junto o con TP simultáneo.

**API [API].** Vida del aliado y `WasRecentlyDamagedByHero(e, t)`; `IsStunned()`/`IsHexed()` del aliado y su tiempo
restante (`GetModifierByName` + `GetModifierRemainingDuration`, funciona en aliados); enemigos visibles a su
alrededor y sus `GetEstimatedDamageToTarget(true, aliado, 3, ALL)` → tiempo de vida estimado; distancia y velocidad
de cada aliado (`GetCurrentMovementSpeed`), TP disponible (`item_tpscroll` y su cooldown), `GetIncomingTeleports`.
**No se sabe:** cuántos enemigos más hay en la niebla al lado; si el enemigo tiene su control listo.

**OHA hoy [C].** `ConsiderHelpWhenCoreIsTargeted` (`mode_team_roam_generic.lua:1248-1274`) y `ConsiderHelpAlly`
(`:252-283`): ayuda al aliado/core más cercano en 3500 si `#aliados_cerca + 1 >= #enemigos_cerca` (radios 1200/1600
alrededor del aliado) y un enemigo le pega o lo persigue. Deseo hasta 0,98 por la propia vida. No mira si **llega a
tiempo**, ni cuántos aliados más van a ir, ni ultis, ni niebla; cada bot decide solo, así que llegan escalonados. Cuenta
el `+1` (a sí mismo) aunque esté a 3500, es decir, a ~10 s.

**Brecha y propuesta.** En el **cerebro de equipo**: detector de «aliado cazado» (enemigos con su objetivo puesto en
él, o recibe daño de héroe ≥ 2 en 2 s) → estima `t_vida` (vida / daño estimado por segundo de los enemigos
visibles) y, para cada aliado, `t_llegada`. Decide una de tres:
- **Salvar**: si los que llegan antes de `t_vida + 2 s` dan `EvaluarPelea(lugar) > umbral`. Asigna quiénes van (solo
  ellos) y quién usa salvada a distancia (Force, Glimmer, Eul's, Lotus, habilidades de salvar). Los modos de esos bots
  reciben el objetivo del plan con prioridad alta.
- **Ceder**: si no. Prohíbe a los demás acudir (baja su deseo de team_roam para ese objetivo) y lanza el criterio 3
  (reagrupar/farmear/cambio de mapa).
- **Contraatacar**: si el enemigo que caza está lejos de su equipo y llegan ≥ 2: la caza se convierte en nuestra caza.
Riesgo: estimar mal `t_vida` (salvadas enemigas, ilusiones). Empezar conservador (salvar solo con ventaja clara).

---

## 3. Tras perder una pelea (o ceder): reagrupar y farmear sin regalar más

**Principio [G].** Tras perder 2+ héroes, los vivos no deben pelear 3 contra 5 ni quedarse en las líneas lejanas: se
retiran hacia la siguiente torre, juntos, y mientras el enemigo empuja o hace Roshan, farmean donde es seguro (jungla
propia, campamentos cerca de las torres, *stacks* que dejaron los soportes) para que los muertos vuelvan con oro.
Ventana: hasta que reaparecen los aliados (reaparición por nivel ≈ 6 s + 3,8×nivel en 7.3x [G≈], ×0,75 en el custom
game según mapa §2, o hasta 100+ s tarde). El soporte apila campamentos al minuto :53-:55 [G] para que el carry los
limpie después de una pelea perdida. La recompra es para defender estructuras clave o para la pelea decisiva, no para
volver a pelear la misma pelea perdida.

**API [API].** `IsHeroAlive` y reaparición de aliados; `GetNeutralSpawners()` (equipo, tipo, lugar) para elegir
campamentos propios; `GetNearbyNeutralCreeps`; posición de enemigos vistos (`GetHeroLastSeenInfo`); `DotaTime()` para
el minuto de stack. **No se sabe:** si un campamento ya está vacío sin verlo (solo al acercarse).

**OHA hoy [C].** La retirada la mueve Valve (`mode_retreat_generic.lua` termina en `return X`, mapa §3.1): OHA solo
pone el deseo (vida/maná + diferencia de héroes, `:350-362`). No hay estado de equipo «perdimos la pelea». Farm: no
farmea con +6.000 ni en el final de partida (`mode_farm_generic.lua:375`, mapa §3.3), que es justo cuando, tras una
pelea perdida, más compensa farmear seguro. No hay *stacking* coordinado [C: no se encontró lógica de stack en los
modos; verificar en `mode_farm_generic.lua` si existe alguna].

**Brecha y propuesta.** **Cerebro de equipo**: estado `REAGRUPAR` mientras `vivos_aliados < vivos_enemigos` o
`EvaluarPelea` del lugar más cercano < 0. Durante ese estado: (a) el plan fija un punto de reunión (la torre propia
más adelantada que no esté siendo atacada), (b) los modos push y team_roam topan su deseo, (c) se desbloquea el farm
de jungla propia aunque haya ventaja de patrimonio, solo en campamentos con `team == GetTeam()` y lejos de los
enemigos vistos, (d) defensa solo si es T3/barracones/Ancient (criterio 11). Salida: cuando reaparecen los muertos.
Añadir un **stack** del soporte de pos 5 (ir al campamento grande al :53, golpear y salir) como acción de modo farm o
roam, pedida por el plan. Riesgo bajo; el farm en la jungla puede chocar con wards enemigos (contra Valve no hay
wards, mapa §4).

---

## 4. Encadenado de disables (sin solapar, sin huecos)

**Principio [G].** En Dota los stuns **no se suman**: si un stun cae sobre otro, solo cuenta el que acaba más tarde
(el que cae se superpone, no se añade). No hay rendimientos decrecientes, así que el encadenado ideal es que el
siguiente disable **aterrice** justo cuando el anterior está por acabar (≈ 0,1-0,3 s antes, para cubrir el error). El
orden: primero el disable que más dura o que no falla (target, p. ej. Hex ≈ 2,5-3,5 s, Fiend's Grip), luego los de
área o proyectil cuando el objetivo no se mueve (Fissure, Earth Spike, Arrow, Light Strike Array, que necesita un
objetivo quieto por su retardo de 0,5 s [G]), y al final el daño. Se reservan los disables que **interrumpen** (stun,
hex, silencio no siempre) para canalizaciones enemigas (Black Hole, Death Ward, teletransportes) y para el objetivo que
se libera con BKB (BKB quita los disables de magia, no los que atraviesan inmunidad: Chrono, Black Hole a medias,
Duel, Roar [G]). Un *root* no impide lanzar ni atacar; un silencio no impide atacar: no son equivalentes a un stun.

**API [API].** `IsStunned()`, `IsHexed()`, `IsRooted()`, `IsSilenced()`, `IsNightmared()`; `GetModifierList()` /
`GetModifierName(i)` / `GetModifierRemainingDuration(i)` del objetivo (tiempo exacto que le queda a cada modificador).
De la propia habilidad: `GetCastPoint()`, `GetCastRange()`, `GetSpecialValueFloat('duration'|'stun_duration'|...)`,
velocidad del proyectil por `GetSpecialValueInt('speed')`. De aliados: sus habilidades y `GetCooldownTimeRemaining`,
y si están lanzando (`IsCastingAbility()`, `GetCurrentActiveAbility()`, `GetAbilityTarget()`).
**Dudas [S]:** que `GetModifierRemainingDuration` funcione sobre **enemigos** (OHA lo usa en `J.GetRemainStunTime`,
pero solo en la rama de aliados de `IsDisabled`); y qué nombres de modificador usa cada disable en 7.41 (muchos stuns
usan el genérico `modifier_stunned`, otros el suyo, p. ej. `modifier_lion_voodoo`, `modifier_tidehunter_ravage` [S]).
Verificable con una partida observada que imprima `GetModifierList()` de los enemigos aturdidos.
**No se sabe:** si el enemigo tiene Linken's/Lotus listo (se ve el objeto en su inventario, no su cooldown) ni su BKB.

**OHA hoy [C].** Hallazgo 0.3: `not J.IsDisabled(objetivo)` en cada stun. Hay un `J.FilterEnemiesForStun`
(`jmz_func.lua:970-978`) que excluye a los ya aturdidos, usado solo en `FunLib/minion_lib/primal_split.lua`. El
tiempo restante solo se mira para el genérico `modifier_stunned` y en aliados (`J.GetRemainStunTime`,
`jmz_func.lua:3151-3166`); en los 8 héroes de control revisados (Lion, Sand King, Tidehunter, Magnus, Enigma, Void,
Earthshaker, Shadow Shaman) no hay ningún uso de tiempo restante; en todo `BotLib/` solo Mirana lo usa. Positivo: Sand
King lanza Epicenter cuando todos los enemigos cercanos están desactivados (`hero_sand_king.lua:688-700`, `:724`) y
Magnus evita Skewer/Shockwave/Horn Toss sobre objetivos en Black Hole o Chrono (`hero_magnataur.lua:335-336`,
`:577-578`, `:708-709`): son los únicos signos de coordinación.

**Brecha y propuesta.** Dos piezas:
1. **Héroe/FunLib** (sin cerebro): sustituir `not J.IsDisabled(t)` por `J.DisableRestante(t) <= tAterrizaje + 0,15`,
   donde `DisableRestante` es el máximo tiempo restante entre los modificadores de una lista de disables duros, y
   `tAterrizaje` = cast point + distancia/velocidad del proyectil (o el retardo, para LSA/Fissure/Split Earth). Un
   solo cambio en `jmz_func.lua` (una función nueva y un reemplazo mecánico en los Consider*). Riesgo: si la lectura
   de modificadores enemigos no funciona, el bot se comporta igual que hoy (0 restante = libre) salvo con los
   booleanos; dejar el booleano como respaldo.
2. **Cerebro de equipo**: una **cola de disables por objetivo**. Cada bot con un disable listo lo declara en el plan
   (`{héroe, habilidad, duración, tAterrizaje}`); el plan ordena por objetivo (el foco del criterio 7): el de mayor
   duración y menor riesgo de fallo primero, y asigna a cada uno su **momento de lanzar** = fin del anterior −
   tAterrizaje. Un bot no lanza su disable al foco fuera de su turno salvo para interrumpir una canalización o un TP.
   Reservar 1 disable por pelea para interrumpir canalizaciones (`IsChanneling()` del enemigo). Riesgo: latencia (el
   plan corre por frame, los Consider cada 0,2 s): usar márgenes de 0,2-0,3 s; y que el bot espere su turno mientras
   el objetivo escapa: si el objetivo está libre y nadie lanza en 0,3 s, cualquiera puede lanzar.

---

## 5. Sinergias de ultis (combos)

**Principio [G].** Las ultis de control de área crean una ventana de 2-5 s donde los enemigos no se mueven; el valor
real lo pone el daño de área que cae **dentro** de esa ventana. Reglas: (1) el control va primero y el daño después,
nunca al revés; (2) dos controles de área no se tiran a la vez sobre el mismo grupo (se pierde uno; el segundo
alarga la ventana si cae al final del primero); (3) algunas ultis **se estorban**: Chronosphere congela a los propios
aliados que no sean Void (salvo el portador del Aghanim [G≈]); Reverse Polarity sobre un Black Hole saca a los
enemigos del agujero; Ravage o Echo Slam sobre unidades en Chrono no hacen nada nuevo; Macropyre/Epicenter/Ice Path
encajan con cualquier control. (4) Las ultis de daño de área (Echo Slam, Epicenter, Macropyre, Requiem, Midnight Pulse,
Freezing Field, Static Storm) solo valen si el grupo está junto y quieto.

Tabla de pares por tipo [G]:

| Rol A: control de área (inicia) | Duración ≈ [G≈] | Rol B: seguimiento ideal | No combina con |
|---|---|---|---|
| Black Hole (Enigma) | 4 s canal | Midnight Pulse, Macropyre, Epicenter, Echo Slam, Requiem, Freezing Field, Static Storm, Sonic Wave | RP, Vacuum, Skewer (sacan al enemigo), Chrono encima |
| Reverse Polarity (Magnus) | 2,75-3,75 s | Echo Slam, Ravage al final, Macropyre, Ball Lightning/Storm, daño físico de grupo (Empower) | Black Hole activo |
| Ravage (Tidehunter) | 2,4-2,8 s | Echo Slam, Epicenter, LSA y Fissure al final, Requiem | Chrono activo |
| Chronosphere (Void) | 4-5 s | Daño a distancia que no entra (Drow, Sniper, Medusa, Lina), Macropyre sobre el área | Aliados cuerpo a cuerpo que entran (quedan congelados), otro control encima |
| Echo Slam (Earthshaker) | instante, daño por unidad | Detrás de cualquier control (más unidades juntas = más daño) | Antes del control (dispersa nada, pero se desperdicia si están separados) |
| Vacuum + Wall (Dark Seer) | 0,4 s + muro | Black Hole, RP, Ravage, Echo Slam | — |
| Call (Axe) / Duel | 2-3,8 s | Daño de área sobre Axe, Echo Slam | — |
| Winter's Curse, Dream Coil, Static Storm | 3-6 s | Daño de área | — |

**API [API].** Ultis aliadas: nombre, `GetCooldownTimeRemaining()`, `IsFullyCastable()`, maná; si un aliado está
lanzando (`GetCurrentActiveAbility`); modificadores que deja el control sobre los enemigos
(`modifier_enigma_black_hole_pull`, `modifier_faceless_void_chronosphere_freeze`, etc., ya usados en OHA) y su tiempo
restante; posiciones de enemigos y `FindAoELocation(...)` para contar cuántos caben. **No se sabe:** BKB enemigo
listo; si un enemigo fuera de vista va a llegar.

**OHA hoy [C].** Cada ulti decide sola. Defensas parciales: Magnus no lanza RP sobre Chrono/Black Hole
(`hero_magnataur.lua:640-641`, `:760-761`, `:886-887`, con `J.IsLocationInChrono` y `J.IsLocationInBlackHole`,
`jmz_func.lua:5568-5608`); Enigma evita Malefice/Eidolons sobre Chrono (`hero_enigma.lua:368-369`, `:418`); Sand King
espera a que estén desactivados (criterio 4). Pero: Ravage cuenta como objetivo válido solo a quien **no** está
desactivado (`hero_tidehunter.lua:769`), así que no lo lanza sobre un grupo en Black Hole (bien) pero tampoco lo
encadena al final; Chronosphere no comprueba si hay aliados cuerpo a cuerpo dentro (`hero_faceless_void.lua:441-470`
solo mira enemigos); las ultis de daño no esperan al control de un aliado; nadie guarda su ulti para el combo.

**Brecha y propuesta.** **Cerebro de equipo** con una **tabla de combos** (datos, no código por héroe): para cada ulti,
su tipo (`control_area`, `daño_area`, `control_unico`, `salvar`), duración, radio y lista de incompatibilidades. Al
empezar una pelea, el plan elige el combo con las ultis aliadas listas: quién controla (el de mayor duración y mejor
posición) y quién sigue. Publica `combo = {iniciador, seguidores, ventana_inicio, ventana_fin}`:
- Los seguidores **retienen** su ulti de daño de área hasta que el control ha caído (modificador visible sobre ≥ 2
  enemigos) o hasta un tiempo límite; entonces la lanzan dentro de la ventana.
- Un segundo control de área solo se lanza en el último 0,5 s del primero.
- Void no lanza Chrono si hay aliados cuerpo a cuerpo (salvo él) en el radio; preferir el sitio donde están los
  enemigos y no los aliados (`FindAoELocation` con resta de aliados).
Implementación: la decisión «lanzar ya / esperar» queda en el `Consider<R>()` del héroe, que consulta el plan con una
función de FunLib (`Plan.PuedoLanzarUlti(bot, tipo)`), para no reescribir la lógica de apuntado de cada héroe. Riesgo:
retener una ulti y morir con ella. Poner siempre un tiempo límite (≈ 1,5 s) y liberar la retención si el bot baja de
40 % de vida.

---

## 6. Iniciación y follow-up

**Principio [G].** Quien inicia es el héroe con control de área + forma de entrar (Blink, Skewer, Ball, Charge, Shukuchi)
y, si es posible, aguante. Se inicia cuando el resto del equipo está **a distancia de seguir** (en 1-2 s pueden estar
pegando), no cuando están en la otra línea. Los seguidores no entran antes que el iniciador (si entran antes, el
enemigo se dispersa y la ulti de área pierde valor) y no se quedan atrás tras la iniciación (un iniciador solo muere en
3 s). El objetivo de la iniciación es el grupo (≥ 2-3 enemigos) o el soporte con salvada/control clave antes de que
reaccione. Con un buen iniciador y un buen combo se puede pelear con menos poder bruto; sin iniciación, se espera a que
inicie el enemigo y se contrainicia (Ravage/RP/Black Hole sobre quien entró).

**API [API].** `HasBlink(true)`, `item_blink` y su cooldown (el daño de héroe recibido pone el Blink en cooldown 3 s
[G]: `TimeSinceDamagedByAnyHero()`); distancias de los aliados al lugar; `GetExtrapolatedLocation(t)` de los enemigos
para apuntar; `FindAoELocation(true, true, lugar, rango, radio, tiempo, 0)` para cuántos caen; `IsCastingAbility()` del
iniciador para saber que entró.

**OHA hoy [C].** El iniciador no espera a nadie ni el equipo espera al iniciador: Magnus hace Blink+RP cuando
`J.IsInTeamFight` y ≥ 2 enemigos en el área (`hero_magnataur.lua:744-763`), es decir, cuando ya hay dos aliados en
ATTACK; el Blink del objeto lo decide `ability_item_usage_generic.lua:1448` sin plan. Los aliados entran a ATTACK por
la lógica de Valve, cada uno cuando quiere. Resultado esperado: o nadie inicia (todos esperan a `IsInTeamFight`) o se
inicia de uno en uno.

**Brecha y propuesta.** **Cerebro de equipo**: estado de pelea con fases `FORMAR → INICIAR → SEGUIR → LIMPIAR`.
- `FORMAR`: el plan elige objetivo (grupo enemigo visible) y un punto de reunión a ~1.200 de él; los modos llevan a los
  bots asignados allí; nadie ataca salvo que lo ataquen.
- `INICIAR`: cuando ≥ N aliados (N = enemigos visibles − 1, mínimo 3 en medio/final de partida) están a ≤ 900 del
  punto, el plan da la orden al iniciador (deseo alto en team_roam + permiso de ulti en su Consider).
- `SEGUIR`: al detectar la iniciación (modificador de control sobre enemigos o `IsCastingAbility` del iniciador), todos
  los seguidores pasan a atacar el foco (criterio 7) y lanzan según el combo (criterio 5).
- Contrainiciación: si un enemigo entra con blink/salto sobre nosotros, el plan prioriza control + foco sobre él.
Riesgo: el bot espera demasiado y el enemigo se va o inicia primero. Un tiempo límite por fase (≈ 6 s en FORMAR) y
abortar si `EvaluarPelea` cae.

---

## 7. Enfoque de objetivo (focus fire)

**Principio [G].** Matar un héroe en 2 s vale más que bajar a cinco al 50 %. El objetivo correcto es el que da más
valor por segundo de daño: (1) el que muere antes (vida efectiva baja, sin salvada, desactivado), (2) el que más
cambia la pelea si muere (soporte con salvada/control aún sin usar, el carry enemigo si es alcanzable y sin BKB), (3)
el que está más adelantado/aislado. No se persigue a un héroe con BKB activo o con salvada en curso (Shallow Grave,
False Promise, Aeon Disk), ni bajo su torre sin necesidad. Se cambia de objetivo cuando el foco se vuelve inalcanzable.

**API [API].** Vida, `GetArmor()`, `GetMagicResist()`, `GetActualIncomingDamage`; suma del daño estimado de los aliados
sobre cada enemigo (`J.GetTotalEstimatedDamageToTarget`, `jmz_func.lua:6121-6135`) → tiempo para matar; modificadores
de salvada (ya listados en OHA, p. ej. `hero_enigma.lua:670-675`); `IsMagicImmune()`, `IsAttackImmune()`; si el
enemigo es core (`J.IsCore` sobre enemigos usa su posición estimada); `SetTarget`/`GetTarget` para compartir.

**OHA hoy [C].** Cada bot elige su objetivo (`J.GetProperTarget`, `jmz_func.lua:335-357`, que es el `GetTarget` propio
o su objetivo de ataque). Hay piezas útiles (`J.IsAllyCanKill`, `X.IsAllysTarget`, `X.GetCanTogetherCount` en
`mode_team_roam_generic.lua:1068-1147`) pero se usan para creeps y últimos golpes. Los stuns eligen «el enemigo más
peligroso para mí» (Lion, `hero_lion.lua:575-604`) o el objetivo propio. No hay un foco de equipo.

**Brecha y propuesta.** **Cerebro de equipo**: en cada pelea, el plan calcula `foco` = argmin(tiempo para matar ×
factor de valor) entre enemigos visibles y alcanzables, con histéresis (no cambiar salvo que el nuevo sea ≥ 30 % mejor
o el actual se vuelva inmune). Lo publica; `team_roam` y las habilidades de un objetivo lo prefieren (bonificación en
su elección, no obligación, para no romper a los héroes que eligen por su cuenta). Riesgo: todo el equipo persigue al
foco mientras otro enemigo los destruye; limitar a enemigos a ≤ rango + 300 de la mayoría de aliados.

---

## 8. BKB y salvadas en las peleas

**Principio [G].** BKB (≈ 9 s [G≈]; en 7.3x ya no se acorta con el uso [G≈]) se activa **antes** de recibir el control
clave cuando el carry entra o cuando el iniciador enemigo aún tiene su ulti (contra un equipo que ya gastó sus
controles, no hace falta). Las salvadas (Glimmer, Force, Eul's, Lotus, Shallow Grave, False Promise, Ghost) se usan en
el aliado **que va a morir y vale la pena**, en el momento en que el daño ya viene (no antes: el enemigo cambia de
objetivo) y no en uno que ya está fuera de peligro. Eul's / Force también sirven para **sacar** a un enemigo de una
salvada o meterlo en la pelea, y Eul's sobre uno mismo esquiva proyectiles. Lotus devuelve disables de objetivo único.

**API [API].** Ítems propios y de aliados (`GetItemInSlot`, `FindItemSlot`, cooldown); proyectiles hacia un aliado
(`GetIncomingTrackingProjectiles()`); enemigos lanzando (`IsCastingAbility`, `GetAbilityTarget()` del enemigo [S:
verificar que da el objetivo en enemigos]); vida y daño estimado sobre el aliado. **No se sabe:** si el iniciador
enemigo tiene la ulti lista.

**OHA hoy [C].** Cada uno por su cuenta y bastante reactivo: BKB si hay enemigos a 1300 y está atacando o huyendo, y
algún motivo (rooted, silenciado, proyectil de habilidad, habilidad de objetivo viniendo, ≥ 3 enemigos a 800)
(`ability_item_usage_generic.lua:1342-1400`). Glimmer en aliado: si está a < 35 % + 5 % por enemigo, huyendo y dañado
(`:2598-2660`). No sabe si el iniciador enemigo ya gastó su ulti ni coordina dos salvadas sobre el mismo aliado.

**Brecha y propuesta.** **Cerebro de equipo** ligero: (a) registrar «control de área enemigo visto este combate» (por
los modificadores sobre aliados) para que el BKB defensivo no se active cuando la amenaza ya pasó; (b) **reservar**
salvadas: el plan asigna a cada portador de salvada un protegido (el core aliado más valioso cerca) y evita que dos
salvadas caigan sobre el mismo aliado en el mismo segundo (marca `salvado_hasta`). El momento exacto sigue en el
`ConsiderItemDesire` de cada objeto. Riesgo bajo; impacto medio.

---

## 9. Convertir una pelea ganada en objetivo

**Principio [G].** Una pelea ganada vale lo que se toma con ella. La ventana es el tiempo de reaparición enemigo menos
el viaje: con 2+ enemigos muertos y ≥ 30-40 s de reaparición, se toma lo más valioso **alcanzable dentro de la
ventana**: torre cercana → barracones (high ground) si quedan ≥ 30 s y están los 4-5 → Roshan si está vivo y la ventana
cubre ~60 s de Roshan (más rápido con más daño) → otra torre. No se entra en high ground en inferioridad numérica ni
sin Aegis o sin ventaja clara: los barracones tienen la torre T3/T4 cerca y el glifo enemigo (≈ 5 s de
invulnerabilidad de estructuras, cooldown ≈ 300 s [G≈]) hace perder segundos de la ventana: conviene forzarlo antes con
la línea de creeps. El Aegis (dura ≈ 5 min, reencarnación en ≈ 5 s [G≈]) es la licencia para el high ground: su
portador encabeza. Roshan reaparece en 8-11 min tras morir [API, comentario de `GetRoshanKillTime`] y en 7.3x cambia de
foso según el día y la noche [G].

**API [API].** `IsHeroAlive(pid)` y reaparición de los enemigos (o estimada por nivel); `GetGlyphCooldown()` es el del
**propio** equipo [API]; el glifo enemigo se infiere por el modificador `modifier_fountain_glyph` en sus torres
visibles (OHA ya lo mira en las propias, `jmz_func.lua:4718`); `GetRoshanKillTime()`, `J.IsRoshanAlive`, el lugar de
Roshan (`J.GetCurrentRoshanLocation`); `GetTower`/`GetBarracks`/`GetAncient` con su vida; `J.DoesTeamHaveAegis()`.

**OHA hoy [C].** El empuje sube con ventaja de héroes vivos, patrimonio y Aegis (`FunLib/aba_push.lua:330-366`: +0,3
con Aegis, bonus por `aAliveCount - eAliveCount`) y hay `groupPush` (`:315-328`). Pero no hay ventana de reaparición:
el empuje no sabe que tiene 40 s y no elige entre torre y Roshan; Roshan tiene su propio modo (mapa §8.3: su deseo casi
siempre MODERATE por un fallo de escala). Mapa §3.2: con +6.000 empuja con 4-5 bots juntos solo el 7-8 % del tiempo.

**Brecha y propuesta.** **Cerebro de equipo**: tras una pelea (≥ 2 enemigos muertos en 15 s, o `vivos_enemigos ≤
vivos_aliados − 2`), calcular la ventana `W = min(reaparición restante enemigos muertos) − 5 s` y elegir objetivo con
una tabla de valor/tiempo (torre ≈ 15-25 s con 4 héroes, barracones ≈ 20-30 s, Roshan ≈ 30-60 s según daño [S: medir
en partidas observadas]). Publicar `objetivo_equipo` y empujar `UpdatePushLaneDesires`/`UpdateRoshanDesire` en
`team_desires.lua` hacia él; los modos push/roshan ya existentes lo ejecutan. Cuando `W` se acaba, retirada ordenada
(no quedarse en high ground con los enemigos vivos). Riesgo: las funciones `Update*Desire` del equipo pueden competir
con los deseos que OHA pone por bot; la sonda de `team_desires.lua` debe decir cómo se combinan.

---

## 10. Cuándo NO pelear

**Principio [G].** Se evita pelear cuando: la ulti clave propia está en cooldown y la enemiga no (o no lo sabemos y la
vimos hace poco); el ítem decisivo llega en < 1 min (BKB del carry, Blink del iniciador); faltan 1-2 aliados que están
reapareciendo o farmeando lejos; la pelea es en la zona del enemigo sin visión; es de noche contra héroes de noche
(Night Stalker) o el enemigo tiene Aegis. En esos casos se farmea seguro, se empuja con creeps y se espera. Con
ventaja de patrimonio, no hace falta pelear en desventaja local: se presiona con la ventaja, no con riesgo.

**API [API].** Cooldowns aliados; oro propio y `GetNextItemPurchaseValue()` frente al coste del ítem clave
(`GetItemCost`); vivos; `GetTimeOfDay()`; `IsLocationVisible` / `IsRadiusVisible` del lugar; Aegis enemigo visible
(`FindItemSlot('item_aegis')` en un enemigo visto [S]). **No se sabe:** ultis enemigas (inferencia del criterio 1).

**OHA hoy [C].** No hay criterio de «esperar». Las peleas nacen de cada bot (team_roam con `#aliados >= #enemigos`,
`mode_team_roam_generic.lua:161`) y del modo ATTACK de Valve. Nada mira ultis ni ítems inminentes.

**Brecha y propuesta.** Es la otra cara de `EvaluarPelea`: el **cerebro de equipo** pone un estado `ESPERAR` cuando
`EvaluarPelea` sería positiva dentro de < 60 s (ulti propia vuelve, ítem clave casi comprado, aliado reaparece) pero no
ahora; en `ESPERAR` el plan baja los deseos de team_roam ofensivo y de push en zona enemiga, y deja farm y empuje con
creeps en líneas seguras. Riesgo: pasividad (justo el defecto actual de rematar lento). Que `ESPERAR` tenga duración
máxima y no se active con ventaja de vivos.

---

## 11. Defensa de base: prioridad absoluta

**Principio [G].** Perder barracones da megacreeps y perder el Ancient es perder la partida: ninguna ventaja compensa.
Con creeps o héroes enemigos en el high ground (T3, barracones, T4, Ancient), al menos los héroes necesarios vuelven
**aunque vayamos ganando**, con TP si hace falta, y el glifo se usa para ganar 5 s mientras llegan. La recompra está
para esto: si el Ancient o los barracones van a caer y no hay quien defienda, se recompra. Con megacreeps enemigos (los
nuestros barracones ya cayeron) la defensa de cada oleada es constante: 1-2 héroes con limpieza de oleada bastan; el
resto sigue con el plan.

**API [API].** `GetTower(team, TOWER_*_3)`, `GetBarracks`, `GetAncient(team)` y su vida (`GetHealth()/GetMaxHealth()`);
`GetNearbyLaneCreeps`/`GetUnitList(UNIT_LIST_ENEMY_CREEPS)` cerca de ellos (los nombres `upgraded`/`mega`, ya usados en
`aba_defend.lua:369-375`); `GetGlyphCooldown()` + `ActionImmediate_Glyph()`; `HasBuyback`, `GetBuybackCost`;
`GetIncomingTeleports`. Todo visible (nuestra base siempre tiene visión).

**OHA hoy [C].** `aba_defend.lua` tiene un modo pánico bueno (enemigos en high ground ≥ 2 o en el Ancient,
`:944-987`), pero lo anula antes el bloque `teamIsPushing` (`:915-937`; hallazgo 0); y cualquier enemigo visible a
1600 del bot baja la defensa a `VeryLow` (`:1045`). La amenaza solo de creeps entra si ya había amenaza activa
(`:1006-1013`). La recompra por Ancient no funciona (`ability_item_usage_generic.lua:569`, hallazgo 0); el glifo se
usa (`:8342-8371`, mapa §3.5).

**Brecha y propuesta.** Dos arreglos pequeños de **modo** y una regla de **cerebro**:
1. En `aba_defend.lua`, evaluar el pánico de base (high ground / Ancient / barracones bajo ataque) **antes** del bloque
   `teamIsPushing`, y que `teamIsPushing` solo apague la defensa de T1/T2. (Arreglar en la fuente TS: `aba_defend.lua`
   se genera de `typescript/`.)
2. `ability_item_usage_generic.lua:569`: `ancient:GetHealth() / ancient:GetMaxHealth() < 0.8`; y permitir recompra por
   base desde cualquier nivel.
3. **Cerebro de equipo**: regla dura «estructura de high ground bajo ataque y sin defensor en 1600» → asigna los 1-2
   héroes más cercanos o con TP a defender, con deseo 0,95, aunque el resto empuje; con héroes enemigos en la base,
   todos.
Riesgo: mover a todos a defender una oleada de creeps que 1 héroe limpia; graduar por peso de amenaza (ya existe
`WeightedEnemiesAroundLocation`).

---

## 12. Cerrar la partida

**Principio [G].** Con gran ventaja se cierra **juntos y con objetivos encadenados**: Roshan → Aegis → high ground de
una línea con los 5 → barracones → si los enemigos mueren, siguiente línea o Ancient. Entre asaltos, se farmea la
jungla enemiga y se empujan las líneas laterales con creeps (presión sin exponerse), y se vuelve a asaltar con la
siguiente ventana (pelea ganada o Aegis). Lo que no se hace: dispersarse por el mapa a farmear con +20.000 (regala
peleas pequeñas), o asaltar el high ground 3 contra 5. Megacreeps propios hacen el resto: tras tomar los barracones de
una línea, la presión es permanente.

**API [API].** Lo de los criterios 1 y 9; `GetLaneFrontAmount` / `GetLaneFrontLocation` para saber dónde están las
oleadas; `GetBarracks` enemigos vivos.

**OHA hoy [C].** Mapa §3.3 y §8.1: con +6.000 no farmea (`mode_farm_generic.lua:375`) y el empuje queda topado (0,82;
0,41 con 5 enemigos vivos y aliados ≤ enemigos; nadie empuja hasta que los cinco tienen nivel 6), con el cambio de
empuje del PR #11 apagado (`aba_push.lua:164`). Hay variantes `grupo` y `grupo_farm` en curso (commit 133fe3c). Mapa
§4: tarda 4-25 minutos de juego desde +10.000.

**Brecha y propuesta.** **Cerebro de equipo**: un estado `CERRAR` cuando ventaja de patrimonio > umbral (p. ej.
+10.000) o barracones enemigos caídos. En `CERRAR`: el plan alterna `ASALTO` (los 5 a una línea elegida por cercanía y
menos defensa visible, con Aegis si hay; usa la ventana del criterio 9) y `PREPARAR` (farm de jungla enemiga cercana y
empuje lateral con creeps, sin bajar de 3 juntos), y nunca deja el criterio 11. Riesgo: el que más pesa contra humanos
(asaltos sin ventana = pelea perdida bajo T3). Medir en serie A/B frente a la variante `grupo`.

---

## 13. Lista priorizada

Impacto esperado: **V** contra los bots de Valve (que se agrupan más cuando ganan, no usan glifo ni wards, mapa §4),
**H** contra humanos (amigos de Pedro en lobby). Coste: S (horas), M (1-2 sesiones), L (varias sesiones + medición).

| # | Criterio | Dónde | V | H | Coste | Por qué en este orden |
|---|---|---|---|---|---|---|
| 1 | Defensa de base: pánico antes de `teamIsPushing`, recompra por Ancient arreglada (crit. 11, arreglos 1-2) | modo + ítems | Alto | Alto | S | Son dos defectos concretos que explican «deja caer la base yendo por delante»; arreglo pequeño y medible |
| 2 | Encadenado de disables por tiempo restante, sin cerebro (crit. 4, pieza 1) | FunLib + reemplazo en Consider* | Medio | Alto | S-M | Un cambio mecánico en un sitio; mejora todas las peleas. Primero verificar que los modificadores enemigos se leen |
| 3 | `EvaluarPelea` en el cerebro (crit. 1), sustituyendo a `WeAreStronger` en retirada y team_roam | cerebro | Alto | Alto | M | Base de 2, 3, 6, 9, 10, 12; corrige que hoy ignore ultis, refuerzos y niebla |
| 4 | Convertir pelea ganada en objetivo con ventana de reaparición (crit. 9) | cerebro + `Update*Desire` | Alto | Alto | M | Ataca directamente el «no remata»; contra Valve, que no defiende con glifo, rinde mucho |
| 5 | Cerrar la partida: estado `CERRAR` con asalto/preparar (crit. 12) | cerebro | Alto | Medio | M | Complementa 4; reutiliza las variantes `grupo` en curso |
| 6 | Caza de aliado: salvar / ceder / contraatacar, sin llegar de uno en uno (crit. 2) | cerebro + team_roam | Medio | Alto | M | Los humanos cazan; Valve menos |
| 7 | Reagrupar y farmear tras perder (crit. 3), con stack del pos 5 | cerebro + farm | Medio | Alto | M | Evita la cadena de muertes y recupera oro; también arregla que no farmee con ventaja tras perder |
| 8 | Foco de equipo (crit. 7) | cerebro + team_roam | Medio | Medio | S-M | Barato una vez exista el estado de pelea |
| 9 | Iniciación y follow-up por fases (crit. 6) | cerebro + Consider del iniciador | Medio | Alto | L | Cambia la decisión `IsInTeamFight` de las ultis; delicado |
| 10 | Combos de ultis con tabla y retención (crit. 5) y cola de disables del cerebro (crit. 4, pieza 2) | cerebro + FunLib | Medio | Alto | L | Depende de 6 y 8; mucho valor contra humanos, menos contra Valve (que ya pierde la micro) |
| 11 | Cuándo no pelear (crit. 10) | cerebro | Bajo | Medio | S (con 3 hecho) | Riesgo de pasividad; solo tras medir 3-5 |
| 12 | BKB y reserva de salvadas (crit. 8) | cerebro ligero + ítems | Bajo | Medio | S-M | Mejora fina |

Verificaciones previas, baratas y sin modelos de pago (una partida observada con `--observar` cada una):
- que `GetModifierRemainingDuration` y `GetModifierList` funcionan sobre enemigos visibles, y los nombres de los
  modificadores de los stuns de los 8 héroes de control (prioridad 2);
- que `GetIncomingTeleports` incluye los TP enemigos, `GetRespawnTime` en enemigos muertos y `GetAbilityTarget` /
  `GetCurrentActiveAbility` en enemigos (prioridad 3 y 6);
- lo que conteste la sonda de `team_desires.lua` sobre si el plan se comparte entre el equipo y los bots (todo lo
  marcado «cerebro»).

## 14. Qué sale de dónde

- **Del conocimiento del juego [G]:** los principios de cada criterio, la tabla de combos, las duraciones y cooldowns
  con «≈» (a confirmar en los archivos de 7.41f), la regla de que los stuns se superponen sin sumar, el Blink que se
  corta con daño, el glifo, el Aegis y las ventanas de reaparición.
- **Del código [C]:** los hallazgos 0.1-0.3, los dos defectos de defensa y recompra, todo «OHA hoy», y que la
  coordinación existente se reduce a evitar Chrono/Black Hole (Magnus, Enigma) y a esperar disables (Sand King).
- **De la referencia del API [API]:** qué se puede y qué no se puede saber (cooldowns, recompra y niebla enemigos
  ocultos).
- **Supuestos [S]:** marcados en su sitio, cada uno con su forma de verificarlo.
