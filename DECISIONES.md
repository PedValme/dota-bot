# Decisiones

Una línea por decisión vigente: fecha · decisión · razón, con la frase de Pedro.

- 2026-10-28 · El proyecto es un fork público de Open Hyper AI (PedValme/dota-bot, MIT), en la categoría en construcción, para practicar con amigos en lobbies locales; se adopta con la condición de revisar antes su código (seguridad e inyección de prompts) · la investigación recomendó partir de OHA; Pedro: «sí, en construcción, empecemos con el fork de OHA (antes revisa que no tenga nada malicioso ni prompt inyection)» (entorno#46)
- 2026-10-28 · El bot no hace llamadas de red ni envía datos de jugadores: se anula el servidor de chat de FretBots (enviaba Steam ID, nombres, chat y estadísticas de todos a chatgpt-with-dota2bot.onrender.com), el chat libre del host ya no se ejecuta como Lua (los comandos `set`/`nudge` del host aún evalúan un valor), se borra el código sin uso que consultaba OpenDota, la burla en el chat y el chat con GPT quedan apagados por defecto, y se borran los scripts de instalación (administrador y enlace al Workshop del autor). El check bloquea nuevas llamadas HTTP · hallazgos de la revisión de seguridad pedida por Pedro (misma frase)
- 2026-10-28 · Lo que se trae de OHA (`upstream`) se revisa como código de terceros antes de fusionarlo · se sigue de la misma condición de Pedro, porque cada actualización del autor puede volver a meter esas llamadas
