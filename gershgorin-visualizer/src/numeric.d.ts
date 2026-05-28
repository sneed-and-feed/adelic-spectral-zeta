declare module 'numeric' {
  export function eig(matrix: number[][]): {
    lambda: { x: number[], y?: number[] },
    E: { x: number[][], y?: number[][] }
  };
}
