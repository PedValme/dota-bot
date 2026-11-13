# Fase 2: los cinco héroes propios

Base: `trabajo/bot-propio.md` (fase 2, firmada el 2026-11-03). Pedro, 2026-11-13: «empecemos con la fase 2, y pruebo una vez que
tengamos un equipo completo». Héroes: Luna (1), Sniper (2), Dragon Knight (3), Lion (4) y Lich (5) (DECISIONES 2026-11-13).
Se borra cuando la fase 2 se cierre.

## Tamaño
Grande: varias sesiones. Cada paso deja el check verde y el bot por defecto sin cambios (todo tras la variante).

## Pasos
1. **Base común** (esta sesión):
   - `control_completo` acepta una lista de héroes; la variante `control_equipo` del banco los pone a los cinco.
   - Registro de héroes (`propio/heroes.lua`): por héroe, su módulo de habilidades, orden de niveles, objetos de salida, compras,
     perfil de build, posición y rol. `linea.lua`, `compras.lua` y `build.lua` leen de ahí; el Sniper pasa a él sin cambiar
     su juego.
   - Línea por posición: 1 y 5 en la segura, 2 en mid, 3 y 4 en la difícil.
2. **Los cuatro héroes**: módulo de habilidades con la interfaz del Sniper (`Finish`, `Harass`, `KillCast`, `KillBurst`,
   `FightCast`, `Aim`), orden de niveles y build. Cada uno en sus propios archivos.
3. **Rol de apoyo** (4 y 5): no quitar últimos golpes a un núcleo aliado cerca; acosar con habilidades y quedarse junto al
   núcleo de su línea.
4. **Humo** del equipo propio contra el equipo de OHA, en el min 12 y en el min 25 (autorizados, DECISIONES 2026-11-04 y
   2026-11-05): que ninguno se quede quieto, muera en bucle o dé errores, y el marcador frente a OHA.
5. **Juega Pedro** contra el equipo completo.

Fuera de este plan: dejar de cargar los reemplazos de la API de OHA (`aba_global_overrides`) y el cerebro de equipo (fase 3).

## Avance
- 2026-11-13: plan escrito; paso 1 en curso.
