import {load,dist,mean,sd,corr,ols,kv} from "./lib.mjs";
const M=load();
const pairs={};for(const m of M){(pairs[m.tag+"|"+m.side]??={})[m.arm]=m;}
const diag=s=>Math.abs(s.x-s.y)/Math.SQRT2;
function rivalMid(m){const scores={};for(let t=60;t<=300;t+=30){const s=m.snaps[t];for(const p in s){const h=s[p];if(h.team===m.team)continue;const near=diag(h)<900&&Math.hypot(h.x,h.y)<3500;(scores[h.pid]??={n:0,name:h.name}).n+=near?1:0;}}
 const arr=Object.entries(scores).sort((a,b)=>b[1].n-a[1].n);return {pid:+arr[0][0],name:arr[0][1].name,n:arr[0][1].n,second:arr[1][1].name+":"+arr[1][1].n};}
console.log("== rival mid por posición (snapshots en mid de 9, t60-300); resto del equipo y rival a t=600; torres/kills equipo a min10");
for(const k of Object.keys(pairs)){for(const arm of ["propio","OHA"]){const m=pairs[k][arm];const r=rivalMid(m);const s=m.snaps[600];const rv=s[r.pid];
 const ally=Object.values(s).filter(h=>h.team===m.team&&h.pid!==m.pid),en=Object.values(s).filter(h=>h.team!==m.team);
 const tl=m.lines.filter(l=>l.includes("timeline event=minute")).map(kv);const t10=tl.find(x=>+x.min===10);
 console.log(k.padEnd(18),arm.padEnd(6),"rival",r.name.padEnd(14),r.n+"/9",r.second.padEnd(18),"rival lh/nw/lvl/k/d",rv.lh,rv.nw,rv.lvl,rv.k,rv.d,"| aliados4 nw",ally.reduce((a,h)=>a+h.nw,0),"k",ally.reduce((a,h)=>a+h.k,0),"d",ally.reduce((a,h)=>a+h.d,0),"| enem5 nw",en.reduce((a,h)=>a+h.nw,0),"k",en.reduce((a,h)=>a+h.k,0),"d",en.reduce((a,h)=>a+h.d,0),"| torres mias/ene",m.team===2?t10?.rt:t10?.dt,m.team===2?t10?.dt:t10?.rt);}}
// Diff stats
const keys=Object.keys(pairs);
const f=(m,fn)=>fn(m.snaps[600],m);
const allyNW=(s,m)=>Object.values(s).filter(h=>h.team===m.team&&h.pid!==m.pid).reduce((a,h)=>a+h.nw,0);
const enNW=(s,m)=>Object.values(s).filter(h=>h.team!==m.team).reduce((a,h)=>a+h.nw,0);
const allyK=(s,m)=>Object.values(s).filter(h=>h.team===m.team&&h.pid!==m.pid).reduce((a,h)=>a+h.k,0);
const enK=(s,m)=>Object.values(s).filter(h=>h.team!==m.team).reduce((a,h)=>a+h.k,0);
const sn=(s,m)=>s[m.pid];
const D={};for(const [n,fn] of Object.entries({snNW:(s,m)=>sn(s,m).nw,snLH:(s,m)=>sn(s,m).lh,snK:(s,m)=>sn(s,m).k,allyNW,enNW,allyK,enK})){D[n]=keys.map(k=>f(pairs[k].propio,fn)-f(pairs[k].OHA,fn));console.log(n,"dif propio-OHA:",D[n].join(" "),"media",mean(D[n]).toFixed(1),"sd",sd(D[n]).toFixed(1));}
console.log("corr dSniperNW~dAliadosNW",corr(D.snNW,D.allyNW).toFixed(2),"dSniperNW~dEnemNW",corr(D.snNW,D.enNW).toFixed(2),"dSnK~dAllyK",corr(D.snK,D.allyK).toFixed(2),"dSnK~dEnK",corr(D.snK,D.enK).toFixed(2),"dSnLH~dEnNW",corr(D.snLH,D.enNW).toFixed(2));
// OHA arm variance components
console.log("\n== OHA arm (política fija) varianza");
const oha=keys.map(k=>({k,tag:k.split("|")[0],side:k.split("|")[1],lh:pairs[k].OHA.snaps[600][pairs[k].OHA.pid].lh,nw:pairs[k].OHA.snaps[600][pairs[k].OHA.pid].nw,kills:pairs[k].OHA.snaps[600][pairs[k].OHA.pid].k}));
for(const v of ["lh","nw","kills"]){const a=oha.map(o=>o[v]);const tags=[...new Set(oha.map(o=>o.tag))];const within=tags.map(t=>{const x=oha.filter(o=>o.tag===t).map(o=>o[v]);return (x[0]-x[1])**2/2});const msw=mean(within);const bm=tags.map(t=>mean(oha.filter(o=>o.tag===t).map(o=>o[v])));const msb=2*sd(bm)**2;console.log(v,"valores",a.join(" "),"media",mean(a).toFixed(1),"sd total",sd(a).toFixed(1),"| MS dentro bloque (sd)",Math.sqrt(msw).toFixed(1),"MS entre bloques",Math.sqrt(msb).toFixed(1),"F",(msb/msw).toFixed(2),"| R media",mean(oha.filter(o=>o.side==='R').map(o=>o[v])).toFixed(1),"D media",mean(oha.filter(o=>o.side==='D').map(o=>o[v])).toFixed(1));}
const ownv=keys.map(k=>({k,lh:pairs[k].propio.snaps[600][pairs[k].propio.pid].lh,nw:pairs[k].propio.snaps[600][pairs[k].propio.pid].nw}));
console.log("propio lh",ownv.map(o=>o.lh).join(" "),"sd post-habil (8)",sd(ownv.slice(2).map(o=>o.lh)).toFixed(1),"nw sd8",sd(ownv.slice(2).map(o=>o.nw)).toFixed(0));
const dl=keys.map(k=>pairs[k].propio.snaps[600][pairs[k].propio.pid].lh-pairs[k].OHA.snaps[600][pairs[k].OHA.pid].lh).slice(2),dn=keys.map(k=>pairs[k].propio.snaps[600][pairs[k].propio.pid].nw-pairs[k].OHA.snaps[600][pairs[k].OHA.pid].nw).slice(2);
console.log("8 parejas con habilidades: dLH media",mean(dl).toFixed(1),"sd",sd(dl).toFixed(1),"IC95 +-",(2.365*sd(dl)/Math.sqrt(8)).toFixed(1)," dNW media",mean(dn).toFixed(0),"sd",sd(dn).toFixed(0),"IC95 +-",(2.365*sd(dn)/Math.sqrt(8)).toFixed(0));
const dl6=dl.slice(2),dn6=dn.slice(2);console.log("6 parejas combate: dLH",mean(dl6).toFixed(1),sd(dl6).toFixed(1),"IC",(2.571*sd(dl6)/Math.sqrt(6)).toFixed(1),"dNW",mean(dn6).toFixed(0),sd(dn6).toFixed(0),(2.571*sd(dn6)/Math.sqrt(6)).toFixed(0));
// positions & modes for both arms
console.log("\n== posición Sniper: snapshots t=30..600 (20): en corredor mid (<1000 de la diagonal, |pos|<4000) / fuera / muerto; dist media a origen; hp medio");
for(const m of M){let lane=0,base=0,off=0,dead=0;const out=[];for(let t=30;t<=600;t+=30){const s=m.snaps[t][m.pid];if(!s.alive){dead++;continue;}const R=Math.hypot(s.x,s.y);if(R>4000&&diag(s)<1000)base++;else if(diag(s)<1000)lane++;else {off++;out.push(t+":"+s.x+","+s.y);}}
 console.log(m.tag.padEnd(14),m.arm.padEnd(6),m.side,"lane",lane,"casaOalLejos",base,"fuera",off,"muerto",dead,out.slice(0,8).join(" "));}
