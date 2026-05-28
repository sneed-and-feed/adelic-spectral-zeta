import React, { useState } from 'react';
import { parseMatrix, formatMatrix } from './mathUtils';

interface MatrixInputProps {
  onMatrixChange: (matrix: number[][]) => void;
}

const PRESETS = {
  'Random 3x3': [
    [5, 1, 0.5],
    [0.2, 4, -1],
    [-0.5, 2, -6]
  ],
  'Diagonally Dominant': [
    [10, -2, 1, 0],
    [1, 8, -3, 2],
    [0.5, 1, 12, -4],
    [-1, -1, 2, -9]
  ],
  'Graph Laplacian (Star)': [
    [4, -1, -1, -1, -1],
    [-1, 1, 0, 0, 0],
    [-1, 0, 1, 0, 0],
    [-1, 0, 0, 1, 0],
    [-1, 0, 0, 0, 1]
  ],
  'Qwen Small Weight Block': [
    [0.23, -0.15, 0.08, -0.02, 0.11],
    [-0.05, 0.42, -0.12, 0.04, -0.09],
    [0.18, 0.03, -0.21, -0.15, 0.07],
    [-0.01, 0.19, -0.06, 0.35, -0.18],
    [0.12, -0.08, 0.15, -0.07, 0.29]
  ]
};

export const MatrixInput: React.FC<MatrixInputProps> = ({ onMatrixChange }) => {
  const [text, setText] = useState<string>(formatMatrix(PRESETS['Random 3x3']));
  const [error, setError] = useState<string | null>(null);

  React.useEffect(() => {
    const matrix = parseMatrix(text);
    if (matrix) {
      setError(null);
      onMatrixChange(matrix);
    } else {
      setError("Invalid matrix format. Must be a square matrix of numbers.");
    }
  }, [text]);

  const loadPreset = (presetKey: keyof typeof PRESETS) => {
    const m = PRESETS[presetKey];
    setText(formatMatrix(m));
    setError(null);
    onMatrixChange(m);
  };

  return (
    <div className="matrix-input-container">
      <div className="input-header">
        <h2>Matrix Input</h2>
      </div>
      
      <p className="input-help">
        Enter a square matrix (CSV, space-separated, or JSON array of arrays).
      </p>

      <div className="preset-buttons">
        {(Object.keys(PRESETS) as Array<keyof typeof PRESETS>).map(preset => (
          <button key={preset} onClick={() => loadPreset(preset)} className="preset-btn">
            {preset}
          </button>
        ))}
      </div>

      <textarea
        className={`matrix-textarea ${error ? 'error' : ''}`}
        value={text}
        onChange={e => setText(e.target.value)}
        rows={8}
      />
      
      {error && <div className="error-message">{error}</div>}
      
    </div>
  );
};
