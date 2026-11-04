import {load,dist,mean,sd,corr,ols,kv} from "./lib.mjs";
const M=load();
const own=M.filter(m=>m.arm==="propio");
const pairs={};for(const m of M){(pairs[m.tag+"|"+m.side]??={})[m.arm]=m;}
const keys=Object.keys(pairs);
const inT=(l,a=0,b=600)=>{const t=+kv(l).t;return t>=a&&t<=b;};
console.log("== propio: LH linea, aciertos, suma lh+ en golpe_res, LH sin atribuir; acoso lines; shrapnel log vs obs; shr dist; away; attempts");
const aw=[],lhs=[],att=[];
for(const m of own){const L=m.lines;const res=L.filter(x=>x.includes("[bench] prop golpe_res ")&&inT(x));const ok=res.filter(x=>x.includes("ultimo_golpe acierto")).length;const sum=res.reduce((a,x)=>a+Number((x.match(/lh\+(\d+)/)||[0,0])[1]),0);
 const lh10=+m.linea.find(x=>+x.t>=600).lh;const ac=L.filter(x=>x.includes("[bench] prop acoso ")&&inT(x)).length;
 const hab=L.filter(x=>x.includes("[bench] prop habilidad ")&&x.includes("shrapnel")&&inT(x));const hd=hab.map(x=>+(x.match(/ a (\d+) \(alcance (\d+)/)||[0,NaN])[1]).filter(x=>!isNaN(x));const killcast=hab.filter(x=>/en la kill/.test(x)).length;
 const obsS=m.ev.filter(e=>e.kind==="cast"&&+e.pid===m.pid&&/shrapnel/.test(e.rest)&&e.t>=0&&e.t<=600).length;
 const habAll=L.filter(x=>x.includes("[bench] prop habilidad ")&&x.includes("shrapnel"));const hda=habAll.map(x=>+(x.match(/ a (\d+) \(alcance/)||[0,NaN])[1]).filter(x=>!isNaN(x));
 const est=L.filter(x=>x.includes("[bench] prop estado ")&&inT(x)).map(kv);const away=est.filter(k=>!["linea","preparar_golpe","ultimo_golpe","denegar"].includes(k.intencion)).length*2;
 const lastHitAtt=res.filter(x=>x.includes(" ultimo_golpe ")).length;
 aw.push(away);lhs.push(lh10);att.push(lastHitAtt);
 console.log(m.tag.padEnd(14),m.side,"LH",lh10,"aciertos",ok,`(${(100*ok/Math.max(lastHitAtt,1)).toFixed(0)}% de ${lastHitAtt})`,"sum lh+",sum,"sin atribuir",lh10-sum,"| acoso",ac,"| shr log",hab.length,"obs",obsS,"kill",killcast,"distMed",hd.length?mean(hd).toFixed(0):"-",">1000:",hd.filter(x=>x>1000).length+"/"+hd.length,"todaPartida",hda.filter(x=>x>1000).length+"/"+hda.length,"| away",away);}
console.log("corr away~LH (10)",corr(aw,lhs).toFixed(2),"(8 sin prueba)",corr(aw.slice(2),lhs.slice(2)).toFixed(2),"| corr attempts~LH 10",corr(att,lhs).toFixed(2),"8:",corr(att.slice(2),lhs.slice(2)).toFixed(2));
console.log("\n== dLH/30s (t 150..600) según shrapnel lanzado en la ventana");
for(const arm of ["propio","OHA"]){const rows=[];for(const m of M.filter(x=>x.arm===arm&&x.tag!=="prueba-control")){const casts=m.ev.filter(e=>e.kind==="cast"&&+e.pid===m.pid&&/shrapnel/.test(e.rest)).map(e=>e.t);for(let t=30;t<=600;t+=30){const A=m.snaps[t-30][m.pid],B=m.snaps[t][m.pid];rows.push({dl:B.lh-A.lh,c:casts.filter(c=>c>t-30&&c<=t).length,alive:A.alive&&B.alive,t});}}
 const w=rows.filter(r=>r.alive&&r.t>120);const a=w.filter(r=>r.c>0),b=w.filter(r=>r.c===0);console.log(arm,"con shr n",a.length,"dLH",mean(a.map(r=>r.dl)).toFixed(2),"| sin shr n",b.length,"dLH",mean(b.map(r=>r.dl)).toFixed(2),"corr",corr(w.map(r=>r.c),w.map(r=>r.dl)).toFixed(2));}
console.log("\n== OHA: dLH por modo dominante en ventana de 30 s y por posición");
const agg={};const pos={};
for(const m of M.filter(x=>x.arm==="OHA")){const modes=m.lines.filter(l=>l.includes("[bench] mode ")&&l.includes(`pid=${m.pid} `)).map(l=>{const q=l.match(/\[bench\] mode t=(-?\d+) pid=\d+ \S+ (\S+) /);return q?{t:+q[1],mode:q[2],alive:/alive=1/.test(l)}:null}).filter(Boolean);
 for(let t=30;t<=600;t+=30){const inw=modes.filter(x=>x.t>t-30&&x.t<=t);const c={};for(const x of inw)c[x.mode]=(c[x.mode]||0)+1;const dom=Object.entries(c).sort((a,b)=>b[1]-a[1])[0]?.[0];const A=m.snaps[t-30][m.pid],B=m.snaps[t][m.pid];const dl=B.lh-A.lh;const dg=Math.abs(B.x-B.y)/Math.SQRT2;
 (agg[dom]??={n:0,lh:0}).n++;agg[dom].lh+=dl;const anyFarm=c.FARM>0;const off=(dg>1000)&&(Math.abs(A.x-A.y)/Math.SQRT2>1000);const kk=off?"fuera_corredor":"corredor";(pos[kk]??={n:0,lh:0}).n++;pos[kk].lh+=dl;if(anyFarm){(pos.conFARM??={n:0,lh:0,lst:[]}).n++;pos.conFARM.lh+=dl;pos.conFARM.lst.push(`${m.tag}${m.side}@${t}:${B.x},${B.y}+${dl}`);}}}
console.log(Object.entries(agg).map(([k,v])=>`${k}: n=${v.n} dLH/30s=${(v.lh/v.n).toFixed(2)} total=${v.lh}`).join("\n"));console.log(JSON.stringify(pos,null,0).slice(0,1800));
console.log("\n== OHA think del Sniper");
for(const m of M.filter(x=>x.arm==="OHA").slice(0,4)){const th=m.lines.filter(l=>l.includes("[bench] think ")&&l.includes(`pid=${m.pid} `));console.log(m.tag,m.side,th.length,th.slice(0,2).map(x=>x.replace(/.*think /,"")).join(" | "));}
console.log("\n== distancia Sniper a rival mid y a enemigo más cercano (snapshots 60..600), hp medio");
function rival(m){const s={};for(let t=60;t<=300;t+=30)for(const p in m.snaps[t]){const h=m.snaps[t][p];if(h.team===m.team)continue;const near=Math.abs(h.x-h.y)/Math.SQRT2<900&&Math.hypot(h.x,h.y)<3500;s[p]=(s[p]||0)+(near?1:0);}return +Object.entries(s).sort((a,b)=>b[1]-a[1])[0][0];}
const R={};for(const m of M){const rv=rival(m);const dr=[],dn=[],hp=[],rhp=[];for(let t=60;t<=600;t+=30){const S=m.snaps[t];const a=S[m.pid];if(!a.alive)continue;hp.push(a.hp);const r=S[rv];if(r.alive){dr.push(dist(a,r));rhp.push(r.hp);}const en=Object.values(S).filter(h=>h.team!==m.team&&h.alive).map(h=>dist(a,h));dn.push(Math.min(...en));}
 const md=x=>{const y=[...x].sort((a,b)=>a-b);return y[Math.floor(y.length/2)];};
 const key=m.tag+"|"+m.side;(R[key]??={})[m.arm]={dr:md(dr),dn:md(dn),hp:mean(hp),rhp:mean(rhp),rlh:m.snaps[600][rv].lh,rd:m.snaps[600][rv].d,rk:m.snaps[600][rv].k};}
for(const k of keys){const p=R[k];console.log(k.padEnd(18),"medDistRival propio/OHA",p.propio.dr.toFixed(0),p.OHA.dr.toFixed(0),"medDistEnem",p.propio.dn.toFixed(0),p.OHA.dn.toFixed(0),"hp",p.propio.hp.toFixed(0),p.OHA.hp.toFixed(0),"rivalHp",p.propio.rhp.toFixed(0),p.OHA.rhp.toFixed(0),"rivalLH",p.propio.rlh,p.OHA.rlh,"rivalMuertes",p.propio.rd,p.OHA.rd);}
const a=x=>keys.map(k=>x(R[k]));
console.log("med dist rival propio",mean(a(p=>p.propio.dr)).toFixed(0),"OHA",mean(a(p=>p.OHA.dr)).toFixed(0),"| hp",mean(a(p=>p.propio.hp)).toFixed(0),mean(a(p=>p.OHA.hp)).toFixed(0),"| rivalHp",mean(a(p=>p.propio.rhp)).toFixed(0),mean(a(p=>p.OHA.rhp)).toFixed(0),"| rivalLH",mean(a(p=>p.propio.rlh)).toFixed(1),mean(a(p=>p.OHA.rlh)).toFixed(1),"| rivalMuertes",mean(a(p=>p.propio.rd)).toFixed(1),mean(a(p=>p.OHA.rd)).toFixed(1));
const dS=keys.map(k=>pairs[k].propio.snaps[600][pairs[k].propio.pid].lh-pairs[k].OHA.snaps[600][pairs[k].OHA.pid].lh);const dR=keys.map(k=>R[k].propio.rlh-R[k].OHA.rlh);console.log("dRivalLH",dR.join(" "),"corr con dSniperLH",corr(dS,dR).toFixed(2));
const dNW=keys.map(k=>pairs[k].propio.snaps[600][pairs[k].propio.pid].nw-pairs[k].OHA.snaps[600][pairs[k].OHA.pid].nw);const oK=keys.map(k=>pairs[k].OHA.snaps[600][pairs[k].OHA.pid].k);console.log("corr dNW ~ OHA kills",corr(dNW,oK).toFixed(2));
const idx=keys.map((k,i)=>i).filter(i=>oK[i]>=5);console.log("pares OHA>=5 kills",idx.map(i=>keys[i]),"dNW sum",idx.reduce((s,i)=>s+dNW[i],0),"total",dNW.reduce((a,b)=>a+b,0),"resto 7 media",mean(dNW.filter((_,i)=>!idx.includes(i))).toFixed(0),"resto 5 con habil",mean(keys.map((k,i)=>i).filter(i=>!idx.includes(i)&&i>=2).map(i=>dNW[i])).toFixed(0),"dLH resto5",keys.map((k,i)=>i).filter(i=>!idx.includes(i)&&i>=2).map(i=>dS[i]).join(" "));
console.log("\n== muerto (s, <=600) por modo alive=0 OHA, estado ausente propio");
for(const m of M){let dead;if(m.arm==="OHA"){dead=m.lines.filter(l=>l.includes("[bench] mode ")&&l.includes(`pid=${m.pid} `)&&/alive=0/.test(l)&&inT(l)).length*2;}else{const est=m.lines.filter(x=>x.includes("[bench] prop estado ")&&inT(x)).length*2;dead=600-est;}
 console.log(m.tag.padEnd(14),m.arm.padEnd(6),m.side,"muerto~",dead,"muertes",m.snaps[600][m.pid].d);}
