import {readFileSync} from 'node:fs';
const tags=['fase1e-202611041549-1','fase1e-202611041627-3','fase1d-202611040539-1','fase1d-202611040618-3'];
for(const tag of tags){
 const L=readFileSync(tag+'.log','latin1').split(/\r?\n/).map(l=>{const m=l.match(/\[bench\] prop (\S+) t=(-?[\d.]+) pid=\d+ (.*)/);return m?{k:m[1],t:+m[2],r:m[3]}:null}).filter(x=>x&&x.t>=0&&x.t<=600);
 console.log('\n=='+tag);
 // pair golpe -> next golpe_res
 const stat={};let dmgT=[];
 for(let i=0;i<L.length;i++){const x=L[i];if(x.k!=='golpe')continue;
  const m=x.r.match(/creep_(\w+?)_(\w+) vida (\d+) -> (-?\d+) al llegar en ([\d.]+)s .*mi daño (\d+)/);if(!m)continue;
  let res=null;for(let j=i+1;j<L.length;j++){if(L[j].k==='golpe_res'){res=L[j].r;break}}
  const kind=res&&res.startsWith('denegar')?'den':'lh';const out=!res?'?':res.includes('reemplazado')?'reempl':res.includes('acierto')?'ok':res.includes('creep_vivo=true')?'vivo':'otro';
  const late=+m[5]>0.6?'tLand>0.6':'tLand<=0.6';
  const key=`${kind} ${m[2]} ${late}`;stat[key]=stat[key]||{};stat[key][out]=(stat[key][out]||0)+1;
  if(Math.floor(x.t/120)!==dmgT.length-1&&dmgT.length<=Math.floor(x.t/120))dmgT.push(`${Math.round(x.t)}s:${m[6]}`);
 }
 for(const k of Object.keys(stat).sort())console.log(k,JSON.stringify(stat[k]));
 console.log('mi daño:',dmgT.join(' '));
 // estado by minute: mana mean; seconds with heroes_e>0 and hp
 const mana=Array(11).fill(0),n=Array(11).fill(0);const hp=Array(11).fill(0);
 for(const x of L.filter(x=>x.k==='estado')){const mm=x.r.match(/vida=([\d.]+) mana=([\d.]+)/);const i=Math.min(10,Math.floor(x.t/60));mana[i]+=+mm[2];hp[i]+=+mm[1];n[i]++}
 console.log('mana x min:',mana.map((v,i)=>(v/(n[i]||1)).toFixed(2)).join(' '));
 console.log('vida x min:',hp.map((v,i)=>(v/(n[i]||1)).toFixed(2)).join(' '));
 // retreat reasons
 const rs={};let prev=null;for(const x of L.filter(x=>x.k==='decision')){if(prev&&/intencion=(retirada|retirada_fuente|salir_de_torre|soltar_aggro)/.test(prev.r)){const w=(prev.r.match(/intencion=(\S+) motivo=(\S+)/)||[]);const key=w[1]+':'+w[2];rs[key]=(rs[key]||0)+(x.t-prev.t)}prev=x}
 console.log('seg por motivo:',Object.entries(rs).sort((a,b)=>b[1]-a[1]).map(([k,v])=>k+'='+v.toFixed(0)).join(' '));
 const sh=L.filter(x=>x.k==='habilidad'&&x.r.startsWith('shrapnel')).map(x=>{const m=x.r.match(/ a (\d+) /);const mm=x.r.match(/maná (\d+)/);return [Math.round(x.t),m&&+m[1],mm&&+mm[1]]});
 console.log('shrapnel t,dist,mana:',JSON.stringify(sh));
 console.log('acosos:',L.filter(x=>x.k==='acoso').length,'tiempo chase', L.filter(x=>x.k==='persecucion').length);
}
