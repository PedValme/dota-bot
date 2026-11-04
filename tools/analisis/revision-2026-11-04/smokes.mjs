import { readFileSync, readdirSync } from "node:fs";
const root="C:/Proyectos/dota-bot/"; const dir=root+"bench/observaciones/";
const csv=readFileSync(root+"bench/series.csv","utf8").split(/\r?\n/); const h=csv[0].split(",");
const tags=["prueba-control","fase1","fase1c","fase1d","fase1e"];
const kv=l=>Object.fromEntries([...l.matchAll(/(\w+)=(\S+)/g)].map(m=>[m[1],m[2]]));
const ts=l=>{const m=l.match(/^(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)/);return m?(+m[3])*3600+(+m[4])*60+(+m[5]):null};
const rows=[];
for(const tag of tags){
 for(const f of readdirSync(dir).filter(f=>f.startsWith(tag+"-")&&f.endsWith(".log")).sort()){
  const n=+f.match(/-(\d+)\.log$/)[1];
  const row=csv.slice(1).map(l=>l.split(",")).filter(r=>r[h.indexOf("etiqueta")]===tag&&+r[h.indexOf("partida")]===n).pop();
  const L=readFileSync(dir+f,"latin1").split(/\r?\n/);
  const t0=ts(L[0]);
  const hero=L.filter(l=>/obs t=-?\d+ hero /.test(l));
  const get=(name,t)=>{const m=hero.find(l=>l.includes(`obs t=${t} hero`)&&new RegExp(` ${name} lvl=`).test(l));return m?kv(m):null};
  const s5=get("sniper",300), s10=get("sniper",600);
  const team=s10?.team;
  const line=L.find(l=>/\[bench\] linea t=(6\d\d)/.test(l)); const wall10=line?ts(line)-t0:null;
  const lastTs=ts(L.filter(l=>ts(l)!==null).pop()); 
  const clk=L.find(l=>/obs t=0 /.test(l)); const wall0=clk?ts(clk)-t0:null;
  const l660=L.find(l=>/obs t=66\d /.test(l)); const wall11=l660?ts(l660)-t0:null;
  // mid band occupancy of enemies between 120 and 600
  const inMid=(x,y)=>Math.abs(x-y)<1100&&Math.abs(x)<3500&&Math.abs(y)<3500;
  const occ={};
  for(const l of hero){const k=kv(l);const t=+k.t;if(t<120||t>600||k.team===team)continue;const nm=l.match(/team=\d+ (\w+) lvl/)[1];occ[nm]=(occ[nm]||0)+(inMid(+k.x,+k.y)&&k.alive==="1"?1:0);}
  const rival=Object.entries(occ).sort((a,b)=>b[1]-a[1]);
  const sniOcc=hero.filter(l=>/ sniper lvl=/.test(l)).map(kv).filter(k=>+k.t>=120&&+k.t<=600);
  const sniMid=sniOcc.filter(k=>inMid(+k.x,+k.y)).length/sniOcc.length;
  const kills=L.filter(l=>/obs t=\d+ kill /.test(l)).map(kv).filter(k=>+k.t<=600);
  const skills=kills.filter(k=>k.killer==="sniper"&&+k.vpid>0);
  const sdeath=kills.filter(k=>k.victim==="sniper");
  const r=rival[0]?.[0]; const r10=r?get(r,600):null;
  rows.push({tag,n,arm:row?.[h.indexOf("variante")]==="control_sniper"?"P":"O",side:team==="2"?"R":"D",lh5:+s5?.lh,lh10:+s10?.lh,dn10:+s10?.dn,nw10:+s10?.nw,lvl10:+s10?.lvl,sk:skills.length,victims:skills.map(k=>k.victim+"@"+k.t).join(","),sd:sdeath.length,sdby:sdeath.map(k=>k.killer+"@"+k.t).join(","),rival:rival.slice(0,3).map(([a,b])=>a+":"+b).join(" "),rlh:+r10?.lh,rnw:+r10?.nw,sniMid:+sniMid.toFixed(2),wall0,wall10,wall11,mins:+row?.[h.indexOf("minutos")],wallEnd:lastTs-t0});
 }
}
for(const r of rows)console.log(r.tag,r.n,r.arm,r.side,"lh5",r.lh5,"lh10",r.lh10,"dn",r.dn10,"nw",r.nw10,"lvl",r.lvl10,"k",r.sk,"d",r.sd,"mid%",r.sniMid,"| rival",r.rival,"rlh",r.rlh,"rnw",r.rnw,"| wall0",r.wall0,"w10",r.wall10,"w11",r.wall11,"end",r.wallEnd,"min",r.mins);
console.log("\nKILLS");for(const r of rows)if(r.sk||r.sd)console.log(r.tag,r.n,r.arm,r.side,"K:",r.victims,"D:",r.sdby);
const sd=a=>{const m=a.reduce((x,y)=>x+y,0)/a.length;return [m,Math.sqrt(a.reduce((s,x)=>s+(x-m)**2,0)/(a.length-1))]};
const pairs=[];for(const tag of tags.slice(1))for(const side of "RD"){const P=rows.find(r=>r.tag===tag&&r.arm==="P"&&r.side===side),O=rows.find(r=>r.tag===tag&&r.arm==="O"&&r.side===side);pairs.push({tag,side,dl:P.lh10-O.lh10,dn:P.nw10-O.nw10,dl5:(P.lh10-P.lh5)-(O.lh10-O.lh5),dlv:P.lvl10-O.lvl10,dd:P.sd-O.sd,dk:P.sk-O.sk,dr:(P.lh10-P.rlh)-(O.lh10-O.rlh),P,O});}
console.log("\nPAIRS");for(const p of pairs)console.log(p.tag,p.side,"dLH",p.dl,"dNW",p.dn,"dLvl",p.dlv,"dK",p.dk,"dD",p.dd);
for(const k of ["dl","dn","dlv"]){console.log(k,sd(pairs.map(p=>p[k])).map(x=>+x.toFixed(2)))}
const P=rows.filter(r=>r.arm==="P"&&r.tag!=="prueba-control"),O=rows.filter(r=>r.arm==="O"&&r.tag!=="prueba-control");
for(const k of ["lh10","nw10","sk","sd","lvl10"])console.log(k,"P",sd(P.map(r=>r[k])).map(x=>+x.toFixed(1)),"O",sd(O.map(r=>r[k])).map(x=>+x.toFixed(1)));
const a=P.map(r=>r.lh10),b=pairs.map(p=>p.O.lh10),c=pairs.map(p=>p.P.lh10);const m=x=>x.reduce((s,y)=>s+y,0)/x.length;const cov=c.reduce((s,x,i)=>s+(x-m(c))*(b[i]-m(b)),0)/(c.length-1);console.log("r LH arms",(cov/(sd(c)[1]*sd(b)[1])).toFixed(2));
// OHA, same draw across sides
console.log("OHA R-D same draw", tags.slice(1).map(t=>rows.find(r=>r.tag===t&&r.arm==="O"&&r.side==="R").lh10-rows.find(r=>r.tag===t&&r.arm==="O"&&r.side==="D").lh10));
console.log("kills pct NW: regress OHA nw on k",O.map(r=>[r.sk,r.nw10].join(":")).join(" "));
console.log("P",P.map(r=>[r.sk,r.nw10].join(":")).join(" "));
