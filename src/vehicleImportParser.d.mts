export type VehicleImportRow = { site_id: string; plate: string; brand: string; model: string; vehicle_group: string };
export type VehicleImportResult = { rows: VehicleImportRow[]; logs: string[]; invalid: number; duplicates: number; headerIndex: number };
export function parseVehicleImport(lines: unknown[][], siteId: string, groups: string[]): VehicleImportResult;
