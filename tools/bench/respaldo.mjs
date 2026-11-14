// Copies the bench's observer logs (bench/observaciones/, ignored by git) to a backup folder outside the repository. Pedro asked for it
// as a script of its own, not inside the orchestrator (DECISIONES 2026-11-14), after the logs before p4r2 were lost: a junction to this
// folder inside a temporary worktree was deleted with it.
//
//   node tools/bench/respaldo.mjs [--destino <folder>]
//
// Run it after each batch. It only adds: a file is copied when the backup lacks it or has a different size; nothing is ever deleted or
// overwritten with a smaller file. Default destination: F:\respaldo-dota-bot\observaciones (the HDD, apart from the system SSD), or
// the DOTABOT_RESPALDO environment variable.
import { copyFileSync, existsSync, mkdirSync, readdirSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const source = join(root, "bench", "observaciones");
const i = process.argv.indexOf("--destino");
const dest = i > 0 ? process.argv[i + 1] : process.env.DOTABOT_RESPALDO || "F:\\respaldo-dota-bot\\observaciones";

if (!dest) throw new Error("--destino: falta la carpeta");
const drive = dest.match(/^[A-Za-z]:\\/);
if (drive && !existsSync(drive[0])) {
  console.error(`No existe la unidad ${drive[0]}: no copio nada.`);
  process.exit(1);
}
if (resolve(dest).toLowerCase().startsWith(root.toLowerCase())) {
  console.error("El respaldo no puede estar dentro del repositorio.");
  process.exit(1);
}
if (!existsSync(source)) {
  console.error(`No existe ${source}.`);
  process.exit(1);
}
mkdirSync(dest, { recursive: true });

let copied = 0, same = 0, kept = 0;
for (const f of readdirSync(source)) {
  const from = join(source, f);
  if (!statSync(from).isFile()) continue;
  const to = join(dest, f);
  const size = statSync(from).size;
  if (existsSync(to)) {
    const old = statSync(to).size;
    if (old === size) { same++; continue; }
    if (old > size) { kept++; continue; } // never replace a larger backup with a smaller file
  }
  copyFileSync(from, to);
  copied++;
}
const total = readdirSync(dest).length;
console.log(`Respaldo en ${dest}: ${copied} copiados, ${same} ya estaban${kept ? `, ${kept} con copia mayor que se conserva` : ""}; ${total} archivos en el respaldo.`);
