import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {matches, relevant, toCSV} from './query.js';

const columns=['phenotype_id','code_type','code','description'];
const rows=[[0,'P','snomed','99999999999999999999','Café, "quoted"\nline'],[1,'P','read','00123','Asthma'],[2,'P','read','00123','Asthma']];
assert.equal(matches(rows[0],columns,{},'99999999999999999999',true),true);
assert.equal(matches(rows[1],columns,{code_type:['snomed']},'',false),false);
assert.equal(matches(rows[1],columns,{},'asthma',false),true);
assert.equal(matches(rows[1],columns,{},'001',true),false);
assert.equal(toCSV(rows,columns).split('"00123"').length,3);
assert.ok(toCSV(rows,columns).includes('"Café, ""quoted""\nline"'));
assert.equal(toCSV(rows.slice(1),columns,true),'\ufeff"code"\r\n"00123"\r\n');
assert.equal(relevant({id:'P',ltcs:{L:'Condition'},body_system:'body',type:'physical',sexes:['either'],systems:['read']},{code_type:['read'],ltc_id:['L']}),true);

// Exercise the actual worker, including gzip decoding, pagination and complete exports.
const manifest=JSON.parse(await readFile(new URL('./data/manifest.json',import.meta.url)));
globalThis.self=globalThis;
let requests=0;
globalThis.fetch=async(path,{signal})=>{requests++; if(signal.aborted) throw new Error('aborted'); return new Response(await readFile(new URL(path,import.meta.url)));};
await import('./worker.js');
await self.onmessage({data:{type:'init',manifest}});
const send=async message=>{
  let response;
  globalThis.postMessage=value=>{if(value.type!=='progress') response=value;};
  await self.onmessage({data:message});
  assert.notEqual(response?.type,'error',response?.message);
  return response;
};
const base={type:'query',id:1,filters:{},query:'',exact:false,sort:'source',descending:false,page:1,size:50};
let result=await send(base);
assert.equal(result.count,manifest.rows); assert.equal(result.rows.length,50); assert.equal(requests,manifest.partitions.length);
result=await send({...base,type:'page',page:2}); assert.equal(result.rows[0][0],50);
result=await send({...base,id:2,query:'I21.4',exact:true});
assert.ok(result.count>0); assert.ok(result.rows.every(row=>row[manifest.columns.indexOf('code')+1].toLowerCase()==='i21.4'));
assert.equal(requests,manifest.partitions.length,'Repeated queries should use the cache');
const exported=await send({type:'export',id:2});
assert.equal((await exported.blob.text()).split('\r\n').length-2,result.count);
result=await send({...base,id:3,query:'NO-MATCH-UNLIKELY-STRING'}); assert.equal(result.count,0);
await send({type:'cancel',id:4}); assert.equal(await send({type:'page',id:3,page:1,size:50}),undefined);
console.log('Query, export, worker pagination, cache and stale-result checks passed.');
