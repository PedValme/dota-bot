import {load,dist,mean,sd,corr,ols} from "./lib.mjs";
const M=load();
console.log("match arm side | t=300 lvl lh dn nw k d a | t=600 lvl lh dn nw gold k d a alive x y | linea@600 lh nw t");
for(const m of M){const s5=m.snaps[300]?.[m.pid],s10=m.snaps[600]?.[m.pid];const l10=m.linea.find(x=>+x.t>=600);
console.log(m.tag.padEnd(14),m.arm.padEnd(6),m.side,"|",s5.lvl,s5.lh,s5.dn,s5.nw,s5.k,s5.d,s5.a,"|",s10.lvl,s10.lh,s10.dn,s10.nw,s10.gold,s10.k,s10.d,s10.a,s10.alive,s10.x,s10.y,"|",l10.lh,l10.nw,l10.t);}
// panel regression all 10 heroes, 30 s deltas, t 0..600
const X=[],y=[];
for(const m of M){for(let t=30;t<=600;t+=30){const a=m.snaps[t-30],b=m.snaps[t];if(!a||!b)continue;for(const p in b){if(!a[p])continue;const A=a[p],B=b[p];X.push([1,B.lh-A.lh,B.dn-A.dn,B.k-A.k,B.a-A.a,B.d-A.d]);y.push(B.nw-A.nw);}}}
const c=ols(X,y);console.log("panel all heroes dNW/30s: intercept(passive/30s),LH,DN,K,A,D",c.map(v=>v.toFixed(1)).join(" "),"n",y.length);
// sniper only
const X2=[],y2=[];for(const m of M){for(let t=30;t<=600;t+=30){const A=m.snaps[t-30]?.[m.pid],B=m.snaps[t]?.[m.pid];if(!A||!B)continue;X2.push([1,B.lh-A.lh,B.dn-A.dn,B.k-A.k,B.a-A.a,B.d-A.d]);y2.push(B.nw-A.nw);}}
const c2=ols(X2,y2);console.log("panel sniper only:",c2.map(v=>v.toFixed(1)).join(" "),"n",y2.length);
const C=c;
console.log("\nGap decomposition per pair at t=600 using panel coefs (all heroes):");
const pairs={};for(const m of M){(pairs[m.tag+"|"+m.side]??={})[m.arm]=m;}
let tot={nw:0,lh:0,k:0,a:0,d:0,dn:0,res:0};
for(const [k,p] of Object.entries(pairs)){const a=p.propio.snaps[600][p.propio.pid],b=p.OHA.snaps[600][p.OHA.pid];
const dnw=a.nw-b.nw;const parts={lh:C[1]*(a.lh-b.lh),dn:C[2]*(a.dn-b.dn),k:C[3]*(a.k-b.k),a:C[4]*(a.a-b.a),d:C[5]*(a.d-b.d)};const res=dnw-Object.values(parts).reduce((x,y)=>x+y,0);
for(const q in parts)tot[q]+=parts[q];tot.nw+=dnw;tot.res+=res;
console.log(k.padEnd(18),"dNW",dnw,"| dLH",a.lh-b.lh,"->",parts.lh.toFixed(0),"| dK",a.k-b.k,"->",parts.k.toFixed(0),"| dA",a.a-b.a,"->",parts.a.toFixed(0),"| dD",a.d-b.d,"->",parts.d.toFixed(0),"| dDN",a.dn-b.dn,"->",parts.dn.toFixed(0),"| resid",res.toFixed(0),"| dLvl",a.lvl-b.lvl);}
console.log("sum/10:",Object.fromEntries(Object.entries(tot).map(([k,v])=>[k,(v/10).toFixed(0)])));
