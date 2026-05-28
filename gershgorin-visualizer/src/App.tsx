import { useState, useEffect, useMemo } from 'react';
import { MatrixInput } from './MatrixInput';
import { ComplexPlanePlot } from './ComplexPlanePlot';
import { computeGershgorinDisks, computeEigenvalues } from './mathUtils';
import type { Complex, GershgorinDisk } from './types';
import './index.css';

function App() {
  const [baseMatrix, setBaseMatrix] = useState<number[][]>([]);
  const [perturbation, setPerturbation] = useState<number>(1.0);
  
  const matrix = useMemo(() => {
    if (baseMatrix.length === 0) return [];
    return baseMatrix.map((row, i) => 
      row.map((val, j) => i === j ? val : val * perturbation)
    );
  }, [baseMatrix, perturbation]);

  const disks = useMemo(() => computeGershgorinDisks(matrix), [matrix]);
  const eigenvalues = useMemo(() => computeEigenvalues(matrix), [matrix]);

  return (
    <>
      <header className="app-header">
        <h1>Gershgorin Visualizer</h1>
        <p className="subtitle">
          Interactive localization of eigenvalues via the Gershgorin circle theorem. 
          Analyze matrix perturbations, diagonal dominance, and applications in spectral graph theory.
        </p>
      </header>
      
      <main className="app-main">
        <aside className="left-panel">
          <div className="glass-panel" style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            <MatrixInput onMatrixChange={setBaseMatrix} />
            
            <div className="perturbation-control">
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                <label style={{ color: 'var(--primary)', fontWeight: 600 }}>Off-diagonal Perturbation</label>
                <span style={{ color: 'var(--text-main)' }}>{perturbation.toFixed(2)}x</span>
              </div>
              <input 
                type="range" 
                min="0" 
                max="3" 
                step="0.05" 
                value={perturbation}
                onChange={(e) => setPerturbation(parseFloat(e.target.value))}
                className="slider"
              />
              <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginTop: '0.5rem' }}>
                Scales off-diagonal elements. Watch how the disks grow/shrink and the eigenvalues respond!
              </p>
            </div>
          </div>
        </aside>
        
        <section className="right-panel">
          <div className="glass-panel" style={{ flex: 1 }}>
            <ComplexPlanePlot disks={disks} eigenvalues={eigenvalues} />
          </div>
        </section>
      </main>
    </>
  );
}

export default App;
