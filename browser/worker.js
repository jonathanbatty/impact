import {matches, toCSV, relevant} from './query.js';
let manifest, latest = 0, result = [], resultId = 0;
const cache = new Map();
let activeController;
async function load(partition, signal) {
  if (cache.has(partition.file)) return cache.get(partition.file);
  const response = await fetch('./data/' + partition.file, {signal});
  if (!response.ok) throw new Error('A codelist file could not be loaded. Check your connection and retry.');
  const bytes = new Uint8Array(await response.arrayBuffer());
  // Hosts may serve .gz with or without Content-Encoding. Handle both.
  const stream = new Blob([bytes]).stream();
  const decoded = bytes[0] === 31 && bytes[1] === 139 ? stream.pipeThrough(new DecompressionStream('gzip')) : stream;
  const rows = await new Response(decoded).json();
  cache.set(partition.file, rows);
  return rows;
}
function page(message) {
  const pages = Math.max(1, Math.ceil(result.length / message.size));
  const number = Math.min(Math.max(1, message.page), pages);
  postMessage({type:'result', id: message.id, count:result.length, page:number, pages,
    rows:result.slice((number - 1) * message.size, number * message.size)});
}
self.onmessage = async ({data: message}) => {
  if (message.type === 'init') {manifest = message.manifest; return;}
  if (message.type === 'cancel') {latest = message.id; resultId = 0; activeController?.abort(); result = []; return;}
  if (message.type === 'page') {if (message.id === resultId) page(message); return;}
  if (message.type === 'export') {
    if (message.id !== resultId) return;
    const blob = new Blob([toCSV(result, manifest.columns, message.distinct)], {type:'text/csv;charset=utf-8'});
    postMessage({type:'export', id:message.id, blob, distinct:message.distinct}); return;
  }
  if (message.type !== 'query') return;
  latest = message.id;
  resultId = 0;
  activeController?.abort();
  const controller = new AbortController(); activeController = controller;
  const partitions = manifest.partitions.filter(p => relevant(p, message.filters));
  let cursor = 0, completed = 0;
  try {
    await Promise.all(Array.from({length:Math.min(6, partitions.length)}, async () => {
      while (cursor < partitions.length) {
        const partition = partitions[cursor++];
        if (latest !== message.id) return;
        await load(partition, controller.signal);
        if (latest === message.id) postMessage({type:'progress', id:message.id, completed:++completed, total:partitions.length});
      }
    }));
    if (latest !== message.id) return;
    const query = message.query.trim().toLowerCase();
    result = partitions.flatMap(p => cache.get(p.file)).filter(row => matches(row, manifest.columns, message.filters, query, message.exact));
    const sort = ['code', 'description', 'ltc_name', 'code_type'].includes(message.sort) ? message.sort : 'code';
    const index = manifest.columns.indexOf(sort) + 1;
    const direction = message.descending ? -1 : 1;
    result.sort((a,b) => direction * (a[index] < b[index] ? -1 : a[index] > b[index] ? 1 : a[0]-b[0]));
    resultId = message.id;
    page(message);
  } catch (error) {
    controller.abort();
    if (latest === message.id) postMessage({type:'error', id:message.id, message:error.message});
  }
};
