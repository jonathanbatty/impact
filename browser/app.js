const $ = id => document.getElementById(id);
const labels = {code_type:'Coding system', phenotype_id:'Phenotype', ltc_id:'Long-term condition', body_system:'Body system', type:'Condition type', sex:'Sex'};
const codingSystemLabels = {
  cprd_aurum_medcodeid: 'CPRD Aurum medcodeid',
  cprd_gold_medcode: 'CPRD Gold medcode',
  emis_local: 'Local EMIS codes',
  icd10: 'UK ICD-10 (5th Edition)',
  icd10cm: 'US ICD-10-CM',
  icd10pcs: 'US ICD-10-PCS',
  icd9cm: 'US ICD-9-CM',
  icd9pcs: 'US ICD-9-PCS',
  opcs4: 'OPCS (4th Edition)',
  read_cleansed: 'Read (cleansed)',
  read_original: 'Read (original)',
  snomed_concept: 'SNOMED-CT Concept',
  snomed_description: 'SNOMED-CT Description'
};
const displayValue = (key, value) => {
  if (key === 'code_type') return codingSystemLabels[value] ?? value;
  if (['body_system', 'sex', 'type'].includes(key)) return value.charAt(0).toUpperCase() + value.slice(1);
  return value;
};
const columnLabels = {...labels, phenotype_name:'Phenotype', ltc_name:'Long-term condition', code:'Code', description:'Description'};
const filters = Object.fromEntries(Object.keys(labels).map(key => [key, []]));
let manifest, worker, request = 0, page = 1, pages = 1, count = 0, browse = false, timer, busy = false;
const format = n => n.toLocaleString('en-GB');
function element(tag, text, className) {const node = document.createElement(tag); if (text) node.textContent = text; if (className) node.className = className; return node;}
function readURL() {
  const params = new URLSearchParams(location.search);
  for (const key of Object.keys(filters)) filters[key] = params.getAll(key);
  $('search').value = params.get('q') || ''; $('exact').checked = params.get('exact') === '1';
  browse = params.get('all') === '1';
}
function saveURL() {
  const params = new URLSearchParams();
  for (const [key, values] of Object.entries(filters)) for (const value of values) params.append(key, value);
  if ($('search').value) params.set('q', $('search').value);
  if ($('exact').checked) params.set('exact','1');
  if (browse) params.set('all','1');
  history.replaceState(null,'',location.pathname + (params.size ? '?' + params : '') + location.hash);
}
function buildFilters() {
  $('filters').replaceChildren();
  for (const [key,label] of Object.entries(labels)) {
    const options = new Map();
    for (const p of manifest.partitions) {
      if (key === 'phenotype_id') options.set(p.id,p.name);
      else if (key === 'ltc_id') for (const [id,name] of Object.entries(p.ltcs)) options.set(id,name);
      else for (const value of key === 'code_type' ? p.systems : key === 'sex' ? p.sexes : [p[key]]) {
        const name = ['body_system', 'type', 'sex'].includes(key)
          ? value.charAt(0).toUpperCase() + value.slice(1)
          : displayValue(key,value);
        options.set(value,name);
      }
    }
    const details = element('details'); details.open = key === 'body_system' || filters[key].length > 0;
    const summary = element('summary',label + (filters[key].length ? ` (${filters[key].length})` : '')); details.append(summary);
    const search = element('input'); search.type = 'search'; search.placeholder = 'Find ' + label.toLowerCase(); search.setAttribute('aria-label','Find ' + label.toLowerCase()); details.append(search);
    const choices = element('div',null,'choices');
    for (const [value,name] of [...options].sort((a,b)=>a[1].localeCompare(b[1]))) {
      const option = element('label'); const input = element('input'); input.type = 'checkbox'; input.checked = filters[key].includes(value);
      input.addEventListener('change',()=> {filters[key] = input.checked ? [...filters[key],value] : filters[key].filter(v=>v!==value); summary.textContent=label+(filters[key].length ? ` (${filters[key].length})` : ''); run();});
      option.append(input,element('span',name || '(blank)')); option.dataset.search = (name+' '+value).toLowerCase(); choices.append(option);
    }
    search.addEventListener('input',()=> {for (const option of choices.children) option.hidden = !option.dataset.search.includes(search.value.toLowerCase());});
    details.append(choices); $('filters').append(details);
  }
}
function controls() {
  $('export').disabled = busy || !count; $('codes').disabled = busy || !count || filters.code_type.length !== 1;
  $('previous').disabled = busy || page <= 1; $('next').disabled = busy || page >= pages;
}
function invalidate() {request++; worker?.postMessage({type:'cancel',id:request}); busy=true; controls(); $('status').textContent='Updating results…';}
function run() {
  clearTimeout(timer); if (!manifest) return;
  saveURL(); request++; page=1; count=0; busy=true; controls(); $('retry').hidden=true; $('status').classList.remove('error');
  const active = browse || $('search').value.trim() || Object.values(filters).some(v=>v.length);
  $('share').hidden = !active;
  $('catalogue').hidden=!!active; $('table-panel').hidden=!active;
  if (!active) {
    worker.postMessage({type:'cancel',id:request}); busy=false;
    $('result-title').textContent='Explore by phenotype'; $('status').textContent='Choose a phenotype below, use the filters, or search the full codelist.'; return;
  }
  $('result-title').textContent='Matching codes'; $('status').textContent='Loading matching codelists…'; $('tbody').replaceChildren(); $('page-label').textContent='Loading…';
  worker.postMessage({type:'query',id:request,filters,query:$('search').value,exact:$('exact').checked,sort:$('sort').value,descending:$('descending').checked,page,size:Number($('size').value)});
}
function message({data}) {
  if (data.id !== request) return;
  if (data.type==='progress') {$('status').textContent=`Loading codelists: ${data.completed} of ${data.total}…`; return;}
  if (data.type==='error') {fail(data.message); return;}
  if (data.type==='export') {
    const link=element('a'); const url=URL.createObjectURL(data.blob); link.href=url;
    link.download=`impact-${data.distinct?'distinct-codes':'codelist'}-${manifest.sha256.slice(0,12)}.csv`; link.click(); setTimeout(()=>URL.revokeObjectURL(url),1000); busy=false; controls(); return;
  }
  if (data.type!=='result') return;
  count=data.count; page=data.page; pages=data.pages; busy=false;
  $('status').textContent=count ? `${format(count)} matching rows · exports include all matches` : 'No matching rows. Try a broader search or reset the filters.';
  $('page-label').textContent=`Page ${page} of ${format(pages)}`;
  const fragment=document.createDocumentFragment();
  for (const row of data.rows) {const tr=element('tr'); for (const key of displayColumns) {const td=element('td',displayValue(key,row[manifest.columns.indexOf(key)+1]) || '—',key==='code'?'code':null); tr.append(td);} fragment.append(tr);}
  $('tbody').replaceChildren(fragment); controls();
}
function fail(text) {busy=true; controls(); $('status').textContent=text; $('status').classList.add('error'); $('retry').hidden=false;}
const displayColumns=['code','description','code_type','ltc_name','phenotype_name','body_system','sex','type','ltc_id','phenotype_id'];
async function init() {
  try {
    const response=await fetch('./data/manifest.json',{cache:'no-cache'}); if(!response.ok) throw new Error('The codelist catalogue is unavailable. Build the browser data, or retry your connection.');
    manifest=await response.json();
    if (!('DecompressionStream' in window)) throw new Error('Please use a current version of Chrome, Edge, Firefox or Safari to open this browser.');
    worker=new Worker('./worker.js',{type:'module'}); worker.onmessage=message; worker.onerror=()=>fail('The search worker stopped. Reload the page to try again.'); worker.postMessage({type:'init',manifest});
    $('stats').replaceChildren();
    for(const [number,label] of [[manifest.rows,'code mappings'],[manifest.partitions.length,'phenotypes'],[new Set(manifest.partitions.flatMap(p=>Object.keys(p.ltcs))).size,'conditions'],[new Set(manifest.partitions.flatMap(p=>p.systems)).size,'coding systems']]) {const span=element('span'); span.append(element('strong',format(number)),document.createTextNode(label)); $('stats').append(span);}
    $('version').textContent='Source: master_codelist.csv · SHA-256 '+manifest.sha256;
    const tr=element('tr'); for (const key of displayColumns) {const th=element('th',key==='phenotype_id'?'Phenotype ID':key==='ltc_id'?'Condition ID':columnLabels[key]); th.scope='col';tr.append(th);} $('thead').replaceChildren(tr);
    $('catalogue').replaceChildren();
    for (const p of [...manifest.partitions].sort((a,b)=>a.name.localeCompare(b.name))) {const button=element('button',p.name,'phenotype'); button.append(element('span',`${p.body_system} · ${format(p.rows)} mappings`)); button.onclick=()=>{filters.phenotype_id=[p.id];buildFilters();run();}; $('catalogue').append(button);}
    readURL();buildFilters();run();
  }catch(error){fail(error.message);}
}
$('search').oninput=()=>{invalidate();clearTimeout(timer);timer=setTimeout(run,300);};
for(const id of ['exact','sort','descending','size']) $(id).onchange=run;
$('browse').onclick=()=>{browse=true;run();};
$('reset').onclick=()=>{for(const key of Object.keys(filters)) filters[key]=[];$('search').value='';$('exact').checked=false;browse=false;buildFilters();run();};
for(const [id,delta] of [['previous',-1],['next',1]]) $(id).onclick=()=>{page+=delta;busy=true;controls();worker.postMessage({type:'page',id:request,page,size:Number($('size').value)});};
for(const id of ['export','codes']) $(id).onclick=()=>{busy=true;controls();worker.postMessage({type:'export',id:request,distinct:id==='codes'});};
$('share').onclick=async()=>{saveURL();try{await navigator.clipboard.writeText(location.href);$('share').textContent='Link copied';setTimeout(()=>$('share').textContent='Copy link',1800);}catch{$('status').textContent='Copy the current address from your browser to share this selection.';}};
$('retry').onclick=()=>manifest&&worker?run():init();
window.onpopstate=()=>{readURL();buildFilters();run();};
init();
