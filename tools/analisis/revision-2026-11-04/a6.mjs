import {load,dist,mean,sd,corr,ols,kv} from "./lib.mjs";
const M=load();
const own=M.filter(m=>m.arm==="propio");
const oha=M.filter(m=>m.arm==="OHA");
console.log("== Kills del Sniper: hp de la víctima en snapshot previo, dist, aliados cerca de la víctima, modo OHA en los 10 s previos");
for(const m of M){const ks=m.ev.filter(e=>e.kind==="kill"&&+e.kpid===m.pid&&e.t<=600&&m.snaps[0]?.[+e.vpid]&&+e.vpid>=0);
 for(const k of ks){const st=Math.floor(k.t/30)*30;const S=m.snaps[st];const v=S[+k.vpid],a=S[m.pid];const allies=Object.values(S).filter(h=>h.team===m.team&&h.pid!==m.pid&&h.alive&&dist(h,v)<1500).length;
  let mode="";if(m.arm==="OHA"){const ml=m.lines.filter(l=>l.includes("[bench] mode ")&&l.includes(`pid=${m.pid} `)).map(l=>l.match(/\[bench\] mode t=(-?\d+) pid=\d+ \S+ (\S+) /)).filter(q=>q&&+q[1]>=k.t-10&&+q[1]<=k.t).map(q=>q[2]);const c={};for(const x of ml)c[x]=(c[x]||0)+1;mode=Object.entries(c).map(([a,b])=>a+":"+b).join(",");}
  const ass=m.ev.filter(e=>e.kind==="cast"&&+e.pid===m.pid&&/assassinate/.test(e.rest)&&e.t>=k.t-6&&e.t<=k.t).length;
  console.log(m.tag.padEnd(14),m.arm.padEnd(6),m.side,k.t,k.victim.padEnd(14),"hpPrev",v.hp,"hace",k.t-st,"s dist",Math.round(dist(a,v)),"aliados<1500",allies,ass?"ASS":"",mode);}}
console.log("\n== Oportunidad a 30 s: pares enemigo vivo <1200 del Sniper vivo con hp<250, <400; t 60..600");
for(const m of M){let n250=0,n400=0,near=0;for(let t=60;t<=600;t+=30){const S=m.snaps[t];const a=S[m.pid];if(!a.alive)continue;for(const h of Object.values(S)){if(h.team===m.team||!h.alive)continue;if(dist(a,h)<1200){near++;if(h.hp<250)n250++;if(h.hp<400)n400++;}}}
 console.log(m.tag.padEnd(14),m.arm.padEnd(6),m.side,"cerca",near,"hp<400",n400,"hp<250",n250);}
console.log("\n== decisiones start matar/rotar toda la partida: x y daño propio con 0 aliados");
for(const m of own){const st=m.lines.filter(l=>l.includes("[bench] prop decision ")&&/intencion=(matar|rotar)/.test(l)&&/\(x\d/.test(l)).map(l=>{const q=l.match(/motivo=(\S+) vida (\d+), .* en 4s (\d+) \(x([\d.]+), (\d+) aliados\) a (\d+)/);return q&&{t:+kv(l).t,v:q[1],hp:+q[2],dmg:+q[3],x:+q[4],al:+q[5],d:+q[6]};}).filter(Boolean);
 const s0=st.filter(x=>x.al===0);console.log(m.tag,m.side,"starts",st.length,"<=600:",st.filter(x=>x.t<=600).length,"hp mediana",st.map(x=>x.hp).sort((a,b)=>a-b)[Math.floor(st.length/2)],"dmg solo (min/mean/max)",s0.length?[Math.min(...s0.map(x=>x.dmg)),mean(s0.map(x=>x.dmg)).toFixed(0),Math.max(...s0.map(x=>x.dmg))].join("/"):"-","kills por persec",m.lines.filter(l=>l.includes("[bench] prop persecucion ")&&/kills\+1/.test(l)).length,"kills tot",m.linea.at(-1).kills);}
console.log("\n== OHA primera Shrapnel; LH entonces; LH/min antes y después hasta 600");
for(const m of oha){const c=m.ev.filter(e=>e.kind==="cast"&&+e.pid===m.pid&&/shrapnel/.test(e.rest)&&e.t>=0).map(e=>e.t)[0];const st=Math.floor(c/30)*30;const lh=m.snaps[st][m.pid].lh;const lh10=m.snaps[600][m.pid].lh;console.log(m.tag,m.side,"1a shr",c,"LH",lh,"antes/min",(lh/(st/60)).toFixed(1),"después/min",((lh10-lh)/((600-st)/60)).toFixed(1));}
for(const m of own.slice(2)){const c=m.ev.filter(e=>e.kind==="cast"&&+e.pid===m.pid&&/shrapnel/.test(e.rest)&&e.t>=0).map(e=>e.t)[0];console.log("propio",m.tag,m.side,"1a shr",c);}
console.log("\n== Shrapnel toda partida fase1e D");
{const m=own.find(x=>x.tag==="fase1e"&&x.side==="D");const hab=m.lines.filter(x=>x.includes("[bench] prop habilidad ")&&x.includes("shrapnel"));const d=hab.map(x=>({t:+kv(x).t,d:+(x.match(/ a (\d+) \(alcance (\d+)/)||[0,NaN])[1],r:(x.match(/alcance (\d+)/)||[])[1],tg:(x.match(/shrapnel: (\S+)/)||[])[1]}));console.log("n",d.length,"media todos",mean(d.filter(x=>!isNaN(x.d)).map(x=>x.d)).toFixed(0),"<=600 n",d.filter(x=>x.t<=600).length,"media<=600",mean(d.filter(x=>x.t<=600&&!isNaN(x.d)).map(x=>x.d)).toFixed(0),"alcance",d[1]?.r);console.log(d.filter(x=>x.t<=600).map(x=>x.t.toFixed(0)+":"+x.tg+"@"+x.d).join(" "));
 // estado first 2 minutes hp
 const est=m.lines.filter(x=>x.includes("[bench] prop estado ")).map(kv).filter(x=>+x.t>=-5&&+x.t<=200);console.log(est.filter((x,i)=>i%5===0).map(x=>`${(+x.t).toFixed(0)}:${x.intencion}:${x.vida}`).join(" "));
 console.log(m.ev.filter(e=>e.kind==="cast"&&+e.pid===m.pid&&/flask|tango/.test(e.rest)&&e.t<=600).map(e=>e.t+":"+e.rest.split(" ")[2]).join(" "));}
console.log("\n== fase1d D retirada desglose");
{const m=own.find(x=>x.tag==="fase1d"&&x.side==="D");const dec=m.lines.filter(x=>x.includes("[bench] prop decision ")&&/intencion=retirada/.test(x)&&+kv(x).t>=0&&+kv(x).t<=600);const c={};for(const l of dec){const r=(l.match(/motivo=(\S+)/)||[])[1];c[r]=(c[r]||0)+1;}console.log(c);
 const est=m.lines.filter(x=>x.includes("[bench] prop estado ")).map(kv).filter(x=>+x.t>=0&&+x.t<=600);const ret=est.filter(x=>x.intencion==="retirada");console.log("retirada s",ret.length*2,"vida>0.6",ret.filter(x=>+x.vida>0.6).length*2,"heroes_e>0",ret.filter(x=>+x.heroes_e>0).length*2);}
console.log("\n== runa secuencia fase1d D");
{const m=own.find(x=>x.tag==="fase1d"&&x.side==="D");const dec=m.lines.filter(x=>x.includes("[bench] prop decision ")&&/intencion=(runa|ir_a_runa)/.test(x)).map(l=>l.replace(/.*decision /,""));console.log(dec.slice(0,14).join("\n"));
 const r=M.find(x=>x===m).ev.filter(e=>e.kind==="rune"&&e.t<=660&&e.t>=350);console.log(r.map(e=>e.t+":"+e.rest).join(" | "));}
console.log("\n== muertes fase1c propio");
for(const m of own.filter(x=>x.tag==="fase1c")){const ds=m.ev.filter(e=>e.kind==="kill"&&e.victim==="sniper"&&e.t<=600);for(const d of ds){const est=m.lines.filter(x=>x.includes("[bench] prop estado ")).map(kv).filter(x=>+x.t>=d.t-10&&+x.t<=d.t+1);console.log(m.side,d.t,"por",d.killer,est.map(x=>`${(+x.t).toFixed(0)}:${x.intencion}:${x.vida}:c${x.creeps_e}:h${x.heroes_e}:d${x["daño3s"]||""}`).join(" "));}}
