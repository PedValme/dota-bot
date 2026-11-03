# Prueba de control completo (un héroe, una línea)

Objetivo (DECISIONES 2026-11-03): saber si podemos controlar de verdad un héroe sin que Valve ni OHA se metan, y
cuánto cuesta que juegue bien su línea. Se borra al cerrar la prueba.

## Montaje
- Sniper en mid del lado de dota-bot (`orquestador.mjs --mid sniper`); el rival de mid sale del sorteo (el motor nunca
  da el mismo héroe a los dos equipos).
- Variante `control_sniper`: `Think()` propio en `bots/bot_generic.lua` solo para ese héroe
  (`bots/FunLib/propio/`); OHA no decide nada suyo: las funciones de habilidades, objetos, mensajero, recompra,
  niveles y compras devuelven sin hacer nada para él, y cuentan cuántas veces las llama el motor.
- Variante `base_sniper`: el mismo Sniper con OHA, y el mismo registro de línea. Mismos héroes y lados por bloque.
- El héroe propio: va a su línea detrás de sus creeps, predice la vida de cada creep (proyectiles en vuelo, golpes
  cuerpo a cuerpo, torres) y pega una sola vez en el momento justo, deniega, se retira por vida, torre o daño enemigo
  estimado y vuelve. Compra tango, salvia y ramas; usa la salvia y el tango; sube habilidades con la build de Valve
  (`bot_builds.txt`). No lanza habilidades ni pelea. Cada decisión, al registro con su motivo (`[bench] prop`).

## Criterios de aceptación (partidas de humo observadas, no serie)
1. Control: con la variante, el héroe no tiene modo activo de OHA, y el registro dice qué funciones llama aún el motor.
2. Lo básico: un golpe por orden sin cortar el amago; muerte prevista del creep frente a la real (aciertos y fallos
   en el registro); se retira y llega a la torre; funciona en Radiant y en Dire.
3. Cuánto falta: últimos golpes, denegaciones y patrimonio en los min 5 y 10 frente a `base_sniper` (`[bench] linea`).
4. Peso: tiempo por `Think` y llamadas por segundo iguales a los demás bots.

## Tareas
- [ ] Código: `FunLib/propio/` (control, línea, registro de línea), ganchos en OHA, variantes y `--mid`.
- [ ] Revisión del cambio del banco por un subagente.
- [ ] Humo: 1 bloque (4 partidas: dos variantes por dos lados), observado.
- [ ] Lectura y entrada en MEDICIONES; diseño del bot propio para la firma de Pedro.
