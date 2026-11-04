import { readFileSync, readdirSync } from "node:fs";
export const dir = "C:/Proyectos/dota-bot/bench/observaciones";
export const TAGS = ["prueba-control","fase1","fase1c","fase1d","fase1e"];
const kv = (line) => Object.fromEntries([...line.matchAll(/(\w+)=(\S+)/g)].map((m) => [m[1], m[2]]));
export { kv };
export function load() {
  const out = [];
  for (const tag of TAGS) {
    const files = readdirSync(dir).filter(f => f.startsWith(tag+"-") && f.endsWith(".log")).sort();
    for (const f of files) {
      const lines = readFileSync(dir+"/"+f,"latin1").split(/\r?\n/);
      const linea = lines.filter(l=>l.includes("[bench] linea ")).map(kv);
      const pid = Number(linea[0].pid), team = Number(linea[0].team), arm = linea[0].control==="true"?"propio":"OHA";
      const snaps = {}; // t -> pid -> obj
      const ev = [];
      for (const l of lines) {
        const m = l.match(/\[dotabench\] obs t=(-?\d+) (\w+) (.*)$/);
        if (!m) continue;
        const t = Number(m[1]), kind = m[2], rest = m[3];
        if (kind==="hero") {
          const o = kv(rest); const name = rest.split(" ")[2];
          const h = {t, pid:+o.pid, team:+o.team, name, lvl:+o.lvl, gold:+o.gold, nw:+o.nw, lh:+o.lh, dn:+o.dn, k:+o.k, d:+o.d, a:+o.a, alive:+o.alive, x:+o.x, y:+o.y, hp:+o.hp, mp:+o.mp, items:o.items};
          (snaps[t] ??= {})[h.pid]=h;
        } else ev.push({t, kind, rest, ...kv(rest)});
      }
      out.push({f, tag, arm, team, pid, lines, linea, snaps, ev, side: team===2?"R":"D"});
    }
  }
  return out;
}
export const dist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
export const mean=a=>a.reduce((x,y)=>x+y,0)/a.length;
export const sd=a=>{const m=mean(a);return Math.sqrt(a.reduce((s,x)=>s+(x-m)**2,0)/(a.length-1));};
export function corr(a,b){const ma=mean(a),mb=mean(b);let s=0,sa=0,sb=0;for(let i=0;i<a.length;i++){s+=(a[i]-ma)*(b[i]-mb);sa+=(a[i]-ma)**2;sb+=(b[i]-mb)**2;}return s/Math.sqrt(sa*sb);}
// OLS with intercept toggle
export function ols(X,y){const n=X[0].length;const A=Array.from({length:n},()=>Array(n+1).fill(0));for(let r=0;r<X.length;r++){for(let i=0;i<n;i++){for(let j=0;j<n;j++)A[i][j]+=X[r][i]*X[r][j];A[i][n]+=X[r][i]*y[r];}}
for(let i=0;i<n;i++){let p=i;for(let k=i+1;k<n;k++)if(Math.abs(A[k][i])>Math.abs(A[p][i]))p=k;[A[i],A[p]]=[A[p],A[i]];for(let k=0;k<n;k++){if(k===i)continue;const f=A[k][i]/A[i][i];for(let j=i;j<=n;j++)A[k][j]-=f*A[i][j];}}
return A.map((r,i)=>r[n]/r[i]);}
