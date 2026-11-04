import {readFileSync} from 'node:fs';
for(const tag of ['fase1e-202611041549-1','fase1e-202611041627-3','fase1d-202611040539-1','fase1d-202611040618-3']){
 const raw=readFileSync(tag+'.log','latin1').split(/\r?\n/).filter(l=>l.includes('[bench] prop golpe'));
 const L=raw.map(l=>{const i=l.indexOf('[bench] prop ');const s=l.slice(i+13);const sp=s.split(' ');return {k:sp[0],t:+sp[1].slice(2),r:sp.slice(3).join(' ')}}).filter(x=>x.t>=0&&x.t<=600);
 const stat={};const dmg=[];let last=-999;
 const team=tag.endsWith('1')?'badguys':'goodguys';
 for(let i=0;i<L.length;i++){const x=L[i];if(x.k!=='golpe')continue;
  const m=x.r.match(/creep_([a-z]+)_([a-z]+)\S* vida (\d+) -> (-?\d+) al llegar en ([\d.]+)s/);const d=x.r.match(/(\d+)\s*$/);
  if(!m){continue}
  const res=(L.slice(i+1).find(y=>y.k==='golpe_res')||{}).r||'';
  const out=res.includes('reemplazado')?'reempl':res.includes('acierto')?'ok':res.includes('creep_vivo=true')?'vivo':'otro';
  const key=(m[1]==team?'LH ':'DN ')+m[2]+(+m[5]>0.6?' largo':' corto');
  stat[key]=stat[key]||{n:0};stat[key].n++;stat[key][out]=(stat[key][out]||0)+1;
  if(x.t-last>=90){dmg.push(Math.round(x.t)+':'+d[1]);last=x.t}
 }
 console.log('\n'+tag);for(const k of Object.keys(stat).sort())console.log(' ',k,JSON.stringify(stat[k]));console.log('  mi daño:',dmg.join(' '));
}
