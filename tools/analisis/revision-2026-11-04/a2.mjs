import {load,dist,mean,sd,corr,ols,kv} from "./lib.mjs";
const M=load();
const pairs={};for(const m of M){(pairs[m.tag+"|"+m.side]??={})[m.arm]=m;}
const groups={all10:Object.keys(pairs),con_habil8:Object.keys(pairs).filter(k=>!k.startsWith("prueba")),combate6:Object.keys(pairs).filter(k=>/fase1[cde]/.test(k))};
for(const [g,keys] of Object.entries(groups)){console.log("\n== gap mean propio-OHA por minuto,",g);
 let rows=[];for(let t=60;t<=600;t+=60){const dl=keys.map(k=>pairs[k].propio.snaps[t][pairs[k].propio.pid].lh-pairs[k].OHA.snaps[t][pairs[k].OHA.pid].lh);const dn=keys.map(k=>pairs[k].propio.snaps[t][pairs[k].propio.pid].nw-pairs[k].OHA.snaps[t][pairs[k].OHA.pid].nw);const dv=keys.map(k=>pairs[k].propio.snaps[t][pairs[k].propio.pid].lvl-pairs[k].OHA.snaps[t][pairs[k].OHA.pid].lvl);rows.push(`${t/60}: LH ${mean(dl).toFixed(1)} NW ${mean(dn).toFixed(0)} lvl ${mean(dv).toFixed(1)}`);}
 console.log(rows.join("\n"));}
console.log("\n== Gap LH per pair at min 2,4,5,6,8,10 (propio-OHA)");
for(const k of Object.keys(pairs)){const p=pairs[k];const r=[120,240,300,360,480,600].map(t=>{const a=p.propio.snaps[t][p.propio.pid],b=p.OHA.snaps[t][p.OHA.pid];return `${a.lh-b.lh}/${a.nw-b.nw}/${a.lvl-b.lvl}`});console.log(k.padEnd(18),r.join("  "));}
console.log("\n== kills by Sniper, t<=600");
for(const m of M){const kills=m.ev.filter(e=>e.kind==="kill"&&+e.kpid===m.pid&&e.t<=600&&+e.vteam!==m.team);
 const deaths=m.ev.filter(e=>e.kind==="kill"&&+e.vpid===m.pid&&e.victim==="sniper"&&e.t<=600);
 const casts=m.ev.filter(e=>e.kind==="cast"&&+e.pid===m.pid&&e.t<=600);
 const d=kills.map(k=>{const ass=casts.filter(c=>/assassinate/.test(c.rest)&&c.t>=k.t-6&&c.t<=k.t).length;const shr=casts.filter(c=>/shrapnel/.test(c.rest)&&c.t>=k.t-8&&c.t<=k.t).length;const s=m.snaps[Math.floor(k.t/30)*30]?.[m.pid];return `${k.t}s ${k.victim}${ass?" ASS":""}${shr?" shr":""}@(${s?.x},${s?.y})`});
 console.log(m.tag.padEnd(14),m.arm.padEnd(6),m.side,"K:",d.join("; ")||"-", "| muertes:",deaths.map(x=>`${x.t}s por ${x.killer}`).join(", ")||"-");}
console.log("\n== casts t<=600 (obs) shrapnel, assassinate, take_aim, runes bounty/otros, sum");
for(const m of M){const c=m.ev.filter(e=>e.kind==="cast"&&+e.pid===m.pid&&e.t>=0&&e.t<=600);const cnt={};for(const e of c){const nm=e.rest.split(" ")[2];cnt[nm]=(cnt[nm]||0)+1;}
 const runes=m.ev.filter(e=>e.kind==="rune"&&+e.pid===m.pid&&e.t<=600).map(e=>e.rune);
 const lf=m.linea.find(x=>+x.t>=600);
 console.log(m.tag.padEnd(14),m.arm.padEnd(6),m.side,"shr",cnt.sniper_shrapnel||0,"ass",cnt.sniper_assassinate||0,"aim",cnt.sniper_take_aim||0,"runes",runes.join(",")||"-","| otros",Object.entries(cnt).filter(([k])=>!/sniper_|power_treads|courier/.test(k)).map(([k,v])=>k+":"+v).join(" "));}
console.log("\n== items t=600");
for(const m of M){const s=m.snaps[600][m.pid];console.log(m.tag.padEnd(14),m.arm.padEnd(6),m.side,s.items.replace(/\d+:/g,""));}
console.log("\n== learn order (primeros 12)");
for(const m of M.filter(m=>m.tag==="fase1e")){console.log(m.arm,m.side,m.ev.filter(e=>e.kind==="learn"&&+e.pid===m.pid).slice(0,12).map(e=>e.rest.split(" ")[2].replace("sniper_","")).join(" "));}
