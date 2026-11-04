import {load,dist,mean,sd,kv} from "./lib.mjs";
const M=load();
console.log("== torres <=600");
let tot={};
for(const m of M){const tw=m.ev.filter(e=>e.kind==="kill"&&e.t<=600&&/tower/.test(e.victim));const ene=tw.filter(e=>+e.vteam!==m.team),mine=tw.filter(e=>+e.vteam===m.team);
 (tot[m.arm]??={ene:0,mine:0,bySniper:0});tot[m.arm].ene+=ene.length;tot[m.arm].mine+=mine.length;tot[m.arm].bySniper+=ene.filter(e=>+e.kpid===m.pid).length;
 console.log(m.tag.padEnd(14),m.arm.padEnd(6),m.side,"enemigas:",ene.map(e=>`${e.t}:${e.victim.replace(/npc_dota_(good|bad)guys_/,"")}<${e.killer.replace(/npc_dota_/,"")}`).join(" ")||"-","| propias:",mine.map(e=>`${e.t}:${e.victim.replace(/npc_dota_(good|bad)guys_/,"")}`).join(" ")||"-");}
console.log(tot);
console.log("\n== kills OHA/propio: aliados vivos a <1500 del Sniper en el snapshot siguiente; enemigos a <1500");
const res={};
for(const m of M){const ks=m.ev.filter(e=>e.kind==="kill"&&+e.kpid===m.pid&&e.t<=600&&+e.vpid>=0&&m.snaps[0]?.[+e.vpid]);
 for(const k of ks){const st=Math.ceil(k.t/30)*30;const S=m.snaps[st]||m.snaps[st-30];const a=S[m.pid];const allies=Object.values(S).filter(h=>h.team===m.team&&h.pid!==m.pid&&h.alive&&dist(h,a)<1500).length;(res[m.arm]??=[]).push(allies);}}
for(const arm in res)console.log(arm,"n",res[arm].length,"aliados media",mean(res[arm]).toFixed(2),"con >=1",res[arm].filter(x=>x>=1).length);
console.log("\n== cerca<1200 con hp<400 sumas 8 parejas con habilidades");
for(const arm of ["propio","OHA"]){let near=0,lo=0;const rh=[];for(const m of M.filter(x=>x.arm===arm&&x.tag!=="prueba-control")){for(let t=60;t<=600;t+=30){const S=m.snaps[t];const a=S[m.pid];if(!a.alive)continue;for(const h of Object.values(S)){if(h.team===m.team||!h.alive)continue;if(dist(a,h)<1200){near++;if(h.hp<400)lo++;rh.push(h.hp);}}}}console.log(arm,"cerca",near,"hp<400",lo,"hp media enemigos cerca",mean(rh).toFixed(0));}
console.log("\n== ATTACK s OHA vs acosar+matar+rematar s propio (t<=600) ");
for(const m of M.filter(x=>x.tag!=="prueba-control")){if(m.arm==="OHA"){const n=m.lines.filter(l=>l.includes("[bench] mode ")&&l.includes(`pid=${m.pid} `)&&/ ATTACK /.test(l)&&+kv(l).t>=0&&+kv(l).t<=600).length*2;console.log(m.tag,m.arm,m.side,"ATTACK",n);}else{const e=m.lines.filter(x=>x.includes("[bench] prop estado ")).map(kv).filter(x=>+x.t>=0&&+x.t<=600);console.log(m.tag,m.arm,m.side,"acosar/matar/rotar/rematar",e.filter(x=>/acosar|matar|rotar|rematar/.test(x.intencion)).length*2);}}
console.log("\n== think OHA Sniper todas");
for(const m of M.filter(x=>x.arm==="OHA")){const th=m.lines.filter(l=>l.includes("[bench] think ")&&l.includes(`pid=${m.pid} `)).map(kv).filter(x=>+x.t<=600);console.log(m.tag,m.side,th.map(x=>x.por_s).join(","));}
