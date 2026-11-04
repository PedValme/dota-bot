import {load,dist,mean,sd,corr,ols,kv} from "./lib.mjs";
const M=load();
const own=M.filter(m=>m.arm==="propio");
console.log("== propio: persecucion/matar/rotar por partida. t<=600 y partida entera");
for(const m of own){const dec=m.lines.filter(l=>l.includes("[bench] prop decision ")).map(l=>({t:+kv(l).t,i:kv(l).intencion,l}));
 const matar=dec.filter(d=>d.i==="matar"||d.i==="rotar");
 const per=m.lines.filter(l=>l.includes("[bench] prop persecucion ")).map(l=>({t:+kv(l).t,txt:l.replace(/.*persecucion t=\S+ pid=\d+ /,"")}));
 const p10=per.filter(p=>p.t<=600);
 const reasons={};for(const p of per){const r=(p.txt.match(/motivo=(\S+)/)||[])[1];reasons[r]=(reasons[r]||0)+1;}
 const est=m.lines.filter(l=>l.includes("[bench] prop estado ")).map(kv).filter(x=>+x.t>=0&&+x.t<=600);
 const heNear=est.filter(x=>+x.heroes_e>0).length*2;
 const final=+m.linea.at(-1).t;
 console.log(m.tag.padEnd(14),m.side,"persec<=600:",p10.length,"total:",per.length,"finalMin",(final/60).toFixed(0),"| s con heroe enemigo <1500 (<=600):",heNear,"| motivos:",JSON.stringify(reasons));
 for(const p of p10)console.log("    ",p.t.toFixed(0),p.txt);
}
console.log("\n== primeras decisiones matar/rotar (start) <=600 con daño");
for(const m of own){const st=m.lines.filter(l=>l.includes("[bench] prop decision ")&&/intencion=(matar|rotar)/.test(l)&&/x\d/.test(l));
 for(const l of st.filter(l=>+kv(l).t<=600))console.log(m.tag,m.side,l.replace(/.*decision /,"").slice(0,140));}
console.log("\n== muertes enemigas t<=600: quién, distancia del Sniper en snapshot anterior");
for(const m of M){const de=m.ev.filter(e=>e.kind==="kill"&&+e.vteam!==m.team&&+e.vpid>=0&&e.t<=600&&m.snaps[0]?.[+e.vpid]);
 let mine=0,near=0,far=0,otherNearList=[];for(const e of de){const snapT=Math.floor(e.t/30)*30;const S=m.snaps[snapT];if(!S)continue;const a=S[m.pid],v=S[+e.vpid];const d=dist(a,v);if(+e.kpid===m.pid)mine++;else if(d<1500&&a.alive){near++;otherNearList.push(e.t+":"+e.victim+"<"+e.killer+"@"+Math.round(d));}else far++;}
 console.log(m.tag.padEnd(14),m.arm.padEnd(6),m.side,"total",de.length,"del Sniper",mine,"otro a<1500",near,"lejos",far, otherNearList.join(" "));}
console.log("\n== buy MoM/lance/broadsword timing OHA vs primera kill");
for(const m of M.filter(m=>m.arm==="OHA")){const b=m.ev.filter(e=>e.kind==="buy"&&+e.pid===m.pid&&e.t<=650).map(e=>e.t+":"+e.rest.split(" ")[2].replace("item_","")+"");
 const fk=m.ev.filter(e=>e.kind==="kill"&&+e.kpid===m.pid&&+e.vpid>=0).map(e=>e.t)[0];
 console.log(m.tag,m.side,"1a kill",fk,b.filter(x=>/mask|lifesteal|morbid|quarter|broad|lance|ogre|staff|robe|mithril|hyper|gloves|blade/.test(x)).join(" "));}
console.log("\n== buy propio");
for(const m of own.filter(m=>m.tag!=="prueba-control")){const b=m.ev.filter(e=>e.kind==="buy"&&+e.pid===m.pid&&e.t<=600).map(e=>e.t+":"+e.rest.split(" ")[2].replace("item_","")+"");console.log(m.tag,m.side,b.join(" "));}
console.log("\n== runas propio partida entera (rune events) y decisiones runa/ir_a_runa");
for(const m of own){const r=m.ev.filter(e=>e.kind==="rune"&&+e.pid===m.pid);const dec=m.lines.filter(l=>l.includes("[bench] prop decision ")&&/intencion=(runa|ir_a_runa)/.test(l)).map(kv);console.log(m.tag,m.side,"rune events",r.length,"decisiones runa",dec.filter(x=>x.intencion==="runa").length,"ir_a_runa",dec.filter(x=>x.intencion==="ir_a_runa").length, "tp casts total",m.ev.filter(e=>e.kind==="cast"&&+e.pid===m.pid&&/tpscroll/.test(e.rest)).length);}
console.log("\n== runas OHA Sniper t<=600 y TP");
for(const m of M.filter(m=>m.arm==="OHA")){const r=m.ev.filter(e=>e.kind==="rune"&&+e.pid===m.pid&&e.t<=600);console.log(m.tag,m.side,r.map(e=>e.t+":"+e.rune).join(" ")||"-","TP<=600",m.ev.filter(e=>e.kind==="cast"&&+e.pid===m.pid&&/tpscroll/.test(e.rest)&&e.t<=600).map(e=>e.t).join(","));}
