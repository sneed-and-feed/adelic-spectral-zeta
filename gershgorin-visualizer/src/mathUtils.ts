import numeric from 'numeric';
import type { Complex, GershgorinDisk } from './types';

export function computeGershgorinDisks(matrix: number[][]): GershgorinDisk[] {
  const n = matrix.length;
  const disks: GershgorinDisk[] = [];
  
  for (let i = 0; i < n; i++) {
    let radius = 0;
    for (let j = 0; j < n; j++) {
      if (i !== j) {
        radius += Math.abs(matrix[i][j]);
      }
    }
    disks.push({
      center: { x: matrix[i][i], y: 0 },
      radius,
      row: i
    });
  }
  return disks;
}

export function computeEigenvalues(matrix: number[][]): Complex[] {
  if (matrix.length === 0) return [];
  try {
    const eig = numeric.eig(matrix);
    const n = matrix.length;
    const eigenvalues: Complex[] = [];
    
    for (let i = 0; i < n; i++) {
      const real = eig.lambda.x[i];
      const imag = eig.lambda.y ? eig.lambda.y[i] : 0;
      eigenvalues.push({ x: real, y: imag });
    }
    return eigenvalues;
  } catch (e) {
    console.error("Eigenvalue computation failed", e);
    return [];
  }
}

export function parseMatrix(input: string): number[][] | null {
  try {
    // Attempt to parse as JSON array of arrays
    if (input.trim().startsWith('[')) {
      const parsed = JSON.parse(input);
      if (Array.isArray(parsed) && parsed.every(row => Array.isArray(row))) {
        return parsed as number[][];
      }
    }
    
    // Parse as CSV/TSV or space-separated
    const rows = input.trim().split('\n');
    const matrix = rows.map(row => 
      row.trim().split(/[\s,]+/).map(val => parseFloat(val))
    );
    
    // Validate
    const n = matrix.length;
    for (let row of matrix) {
      if (row.length !== n) return null; // Must be square
      if (row.some(val => isNaN(val))) return null; // Must be valid numbers
    }
    
    return matrix;
  } catch (e) {
    return null;
  }
}

export function formatMatrix(matrix: number[][]): string {
  return matrix.map(row => row.map(v => v.toFixed(2).padStart(8, ' ')).join(' ')).join('\n');
}
