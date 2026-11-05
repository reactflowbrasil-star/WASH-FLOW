const clean = value => String(value ?? '').trim();
const normalize = value => clean(value).normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]/g, '');
const validPlate = value => {
 const plate = clean(value).toUpperCase().replace(/[^A-Z0-9]/g, '');
 return /^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$/.test(plate) || /^[A-Z]{3}[0-9]{4}$/.test(plate) ? plate : '';
};
const aliases = {
 plate: ['placa', 'plate', 'matricula', 'registration'],
 brand: ['marca', 'brand', 'fabricante'],
 model: ['modelo', 'model', 'veiculo', 'vehicle'],
 group: ['grupo', 'group', 'categoria', 'category']
};
export function parseVehicleImport(lines, siteId, groups) {
 if (!Array.isArray(lines) || lines.length === 0) throw new Error('A primeira planilha está vazia.');
 let headerIndex = -1;
 let columns = { plate: -1, brand: -1, model: -1, group: -1 };
 for (let i = 0; i < Math.min(lines.length, 5); i++) {
  const cells = lines[i].map(normalize);
  const found = {};
  for (const key of Object.keys(aliases)) found[key] = cells.findIndex(cell => aliases[key].includes(cell));
  if (found.plate >= 0) { headerIndex = i; columns = found; break; }
 }
 const logs = [
  'Linhas lidas: ' + lines.length,
  headerIndex >= 0 ? 'Cabeçalho reconhecido na linha ' + (headerIndex + 1) : 'Cabeçalho não identificado; procurando placas em todas as colunas.'
 ];
 const unique = new Map();
 let invalid = 0, duplicates = 0;
 lines.forEach((line, index) => {
  if (!Array.isArray(line) || line.every(cell => clean(cell) === '')) return;
  const cells = line.map(clean);
  if (index === headerIndex) return;
  let plate = '', plateIndex = -1;
  if (headerIndex >= 0 && columns.plate >= 0) {
   plate = validPlate(cells[columns.plate]);
   plateIndex = columns.plate;
  }
  if (!plate) {
   for (let column = 0; column < cells.length; column++) {
    const candidate = validPlate(cells[column]);
    if (candidate) { plate = candidate; plateIndex = column; break; }
   }
  }
  if (!plate) {
   invalid++;
   logs.push('Linha ' + (index + 1) + ': placa não identificada | ' + cells.join(' | '));
   return;
  }
  const value = (key, offset) => headerIndex >= 0 && columns[key] >= 0 ? cells[columns[key]] : cells[plateIndex + offset] || '';
  const brand = value('brand', 1) || 'Desconhecida';
  const model = value('model', 2) || 'Desconhecido';
  const rawGroup = (value('group', 3) || 'AM').toUpperCase();
  const group = groups.includes(rawGroup) ? rawGroup : 'AM';
  if (rawGroup !== group) logs.push('Linha ' + (index + 1) + ': grupo "' + rawGroup + '" não reconhecido; aplicado AM.');
  if (unique.has(plate)) duplicates++;
  unique.set(plate, { site_id: siteId, plate, brand, model, vehicle_group: group });
  logs.push('IMPORTADO: ' + plate + ' | ' + brand + ' | ' + model + ' | ' + group);
 });
 const rows = [...unique.values()];
 return { rows, logs, invalid, duplicates, headerIndex };
}
