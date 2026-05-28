import React, { useState } from 'react';
import type { Complex, GershgorinDisk } from './types';

interface ComplexPlanePlotProps {
  disks: GershgorinDisk[];
  eigenvalues: Complex[];
}

export const ComplexPlanePlot: React.FC<ComplexPlanePlotProps> = ({ disks, eigenvalues }) => {
  const [hoveredDisk, setHoveredDisk] = useState<number | null>(null);

  if (disks.length === 0) {
    return (
      <div className="empty-plot">
        <p>Enter a matrix to see the visualization.</p>
      </div>
    );
  }

  // Calculate bounding box
  let minX = 0, maxX = 0, minY = 0, maxY = 0;

  disks.forEach(d => {
    minX = Math.min(minX, d.center.x - d.radius);
    maxX = Math.max(maxX, d.center.x + d.radius);
    minY = Math.min(minY, d.center.y - d.radius);
    maxY = Math.max(maxY, d.center.y + d.radius);
  });

  eigenvalues.forEach(e => {
    minX = Math.min(minX, e.x);
    maxX = Math.max(maxX, e.x);
    minY = Math.min(minY, e.y);
    maxY = Math.max(maxY, e.y);
  });

  // Add padding
  const paddingX = Math.max((maxX - minX) * 0.15, 1);
  const paddingY = Math.max((maxY - minY) * 0.15, 1);
  
  minX -= paddingX;
  maxX += paddingX;
  minY -= paddingY;
  maxY += paddingY;

  // Make it square (1:1 aspect ratio) so circles aren't ellipses
  const width = maxX - minX;
  const height = maxY - minY;
  const size = Math.max(width, height);
  
  const midX = (minX + maxX) / 2;
  const midY = (minY + maxY) / 2;
  
  const viewBoxMinX = midX - size / 2;
  const viewBoxMaxX = midX + size / 2;
  const viewBoxMinY = midY - size / 2;
  const viewBoxMaxY = midY + size / 2;

  // Elegant Colors based on #C4A6D1
  const colors = [
    '#C4A6D1', '#9D7BB0', '#E5CFF5', '#866496', '#D1B4E0',
    '#A98BC2', '#F1E0FA', '#745285', '#BDA1CA', '#C8ACD6'
  ];

  return (
    <div className="plot-container">
      <svg 
        viewBox={`${viewBoxMinX} ${viewBoxMinY} ${size} ${size}`} 
        className="complex-plane-svg"
        preserveAspectRatio="xMidYMid meet"
      >
        <defs>
          <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur stdDeviation="0.015" result="blur" />
            <feComposite in="SourceGraphic" in2="blur" operator="over" />
          </filter>
          
          {colors.map((color, i) => (
            <radialGradient key={`grad-${i}`} id={`disk-grad-${i}`} cx="50%" cy="50%" r="50%">
              <stop offset="0%" stopColor={color} stopOpacity="0.15" />
              <stop offset="80%" stopColor={color} stopOpacity="0.35" />
              <stop offset="100%" stopColor={color} stopOpacity="0.65" />
            </radialGradient>
          ))}
        </defs>

        <g transform={`scale(1, -1)`}>
          {/* Grid lines / Axes */}
          <line x1={viewBoxMinX} y1={0} x2={viewBoxMaxX} y2={0} className="axis" />
          <line x1={0} y1={-viewBoxMaxY} x2={0} y2={-viewBoxMinY} className="axis" />
          
          {/* Disks */}
          {disks.map((d, i) => {
            const isHovered = hoveredDisk === i;
            return (
              <circle
                key={`disk-${i}`}
                cx={d.center.x}
                cy={-d.center.y}
                r={Math.max(d.radius, 0.001)}
                className={`disk ${isHovered ? 'hovered' : ''}`}
                style={{
                  fill: `url(#disk-grad-${i % colors.length})`,
                  stroke: colors[i % colors.length],
                  strokeWidth: isHovered ? size * 0.006 : size * 0.0035,
                  filter: isHovered ? 'url(#glow)' : 'none',
                  transition: 'all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1)'
                }}
                onMouseEnter={() => setHoveredDisk(i)}
                onMouseLeave={() => setHoveredDisk(null)}
              >
                <title>Row {i + 1}&#10;Center: {d.center.x.toFixed(2)}&#10;Radius: {d.radius.toFixed(2)}</title>
              </circle>
            );
          })}

          {/* Eigenvalues */}
          {eigenvalues.map((e, i) => (
            <circle
              key={`eig-${i}`}
              cx={e.x}
              cy={-e.y}
              r={size * 0.012}
              className="eigenvalue"
              style={{
                fill: '#ffffff',
                stroke: '#C4A6D1',
                strokeWidth: size * 0.003,
                filter: 'url(#glow)'
              }}
            >
              <title>Eigenvalue: {e.x.toFixed(3)} {e.y >= 0 ? '+' : ''}{e.y ? e.y.toFixed(3) + 'i' : ''}</title>
            </circle>
          ))}
        </g>
      </svg>
      <div className="legend">
        <div className="legend-item"><span className="swatch eig-swatch"></span> Eigenvalues</div>
        <div className="legend-item"><span className="swatch disk-swatch"></span> Gershgorin Disks</div>
      </div>
    </div>
  );
};
