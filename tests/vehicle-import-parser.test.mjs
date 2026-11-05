import test from 'node:test';
import assert from 'node:assert/strict';
import { parseVehicleImport } from '../src/vehicleImportParser.mjs';

const groups = ['AM','B','BS','EA','CA','SU','SV','CG','G1','G2','AT'];

test('recognizes headers with arbitrary column order and accent', () => {
 const result = parseVehicleImport([
  ['Grupo','Modelo','Placa','Marca'],
  ['AM','Corolla','BHZ7A01','Toyota'],
  ['SU','Compass','BHZ7B02','Jeep']
 ], 'site-1', groups);
 assert.equal(result.rows.length, 2);
 assert.equal(result.rows[0].plate, 'BHZ7A01');
 assert.equal(result.rows[0].brand, 'Toyota');
 assert.equal(result.rows[0].model, 'Corolla');
 assert.equal(result.rows[0].vehicle_group, 'AM');
});

test('finds Mercosul and legacy plates anywhere without importing header text', () => {
 const result = parseVehicleImport([
  ['Placa','Marca','Modelo','Grupo'],
  ['prefixo','Toyota','Corolla','AM','BHZ7A01'],
  ['dados','Fiat','Strada','BS','ABC1234']
 ], 'site-1', groups);
 assert.deepEqual(result.rows.map(row => row.plate), ['BHZ7A01','ABC1234']);
});

test('rejects invalid first-column fallback and reports invalid rows', () => {
 const result = parseVehicleImport([
  ['Placa','Marca','Modelo','Grupo'],
  ['sem placa','Toyota','Corolla','AM'],
  ['XYZ','Fiat','Uno','B']
 ], 'site-1', groups);
 assert.equal(result.invalid, 2);
 assert.equal(result.rows.length, 0);
});

test('consolidates duplicate plates and keeps the last row', () => {
 const result = parseVehicleImport([
  ['Placa','Marca','Modelo','Grupo'],
  ['BHZ7A01','Toyota','Corolla','AM'],
  ['BHZ7A01','Honda','Civic','B']
 ], 'site-1', groups);
 assert.equal(result.rows.length, 1);
 assert.equal(result.duplicates, 1);
 assert.equal(result.rows[0].brand, 'Honda');
});

test('normalizes unknown groups to AM and preserves tenant id', () => {
 const result = parseVehicleImport([['BHZ7A01','Toyota','Corolla','INVALID']], 'tenant-x', groups);
 assert.equal(result.rows[0].vehicle_group, 'AM');
 assert.equal(result.rows[0].site_id, 'tenant-x');
 assert.ok(result.logs.some(line => line.includes('grupo "INVALID"')));
});

test('throws for empty sheets and sheets without valid plates', () => {
 assert.throws(() => parseVehicleImport([], 'site-1', groups), /vazia/);
 assert.throws(() => parseVehicleImport([['Placa'],['abc']], 'site-1', groups), /Nenhuma placa válida/);
});
