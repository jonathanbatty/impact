export function matches(row, columns, filters, query, exact) {
  for (const [key, values] of Object.entries(filters)) {
    if (values.length && !values.includes(row[columns.indexOf(key) + 1])) return false;
  }
  const code = row[columns.indexOf('code') + 1].toLowerCase();
  const description = row[columns.indexOf('description') + 1].toLowerCase();
  return !query || (exact ? code === query : code.includes(query) || description.includes(query));
}

export function toCSV(rows, columns, distinct = false) {
  const quote = value => '"' + String(value).replaceAll('"', '""') + '"';
  const codeIndex = columns.indexOf('code') + 1;
  const values = distinct ? [...new Set(rows.map(row => row[codeIndex]))].map(code => [code]) : rows.map(row => row.slice(1));
  return '\ufeff' + [distinct ? ['code'] : columns, ...values].map(row => row.map(quote).join(',')).join('\r\n') + '\r\n';
}

export function relevant(partition, filters) {
  const fields = {phenotype_id: [partition.id], ltc_id: Object.keys(partition.ltcs),
    body_system: [partition.body_system], type: [partition.type], sex: partition.sexes, code_type: partition.systems};
  return Object.entries(filters).every(([key, values]) => !values.length || values.some(value => fields[key].includes(value)));
}
