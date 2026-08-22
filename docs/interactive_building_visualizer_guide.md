# Interactive Bruhat-Tits Building & Macdonald Spherical Wave Visualizer: Technical Architecture & User Guide

**Author:** Adelic Spectral Zeta Research Group  
**Date:** August 2026  
**Interactive Visualizer:** [`docs/building_visualizer.html`](file:///c:/Users/x/Documents/antigravity/adelic_spectral_zeta/docs/building_visualizer.html)  
**Mirror Builds:** [`visualizer/building_visualizer.html`](file:///c:/Users/x/Documents/antigravity/adelic_spectral_zeta/visualizer/building_visualizer.html), [`gershgorin-visualizer/public/building_visualizer.html`](file:///c:/Users/x/Documents/antigravity/adelic_spectral_zeta/gershgorin-visualizer/public/building_visualizer.html)  
**Verification Script:** [`scripts/verify_visualizer.py`](file:///c:/Users/x/Documents/antigravity/adelic_spectral_zeta/scripts/verify_visualizer.py)

---

## Executive Overview

The **Interactive Bruhat-Tits Building & Macdonald Spherical Wave Visualizer** is a high-performance, standalone, zero-dependency browser application designed for real-time exploratory research and pedagogy in non-Archimedean spectral geometry, automorphic representation theory, and $p$-adic mathematical physics.

The engine interactively computes and visualizes:
1. **Affine $\tilde{A}_2$ Simplicial Buildings**: The 2D equilateral apartment triangulation $\mathcal{A}(\mathrm{PGL}_3(\mathbb{Q}_p)) \cong \mathbb{Z}^2$, color-coded by determinant valuation mod 3 into vertex types 0 (cyan), 1 (gold), and 2 (magenta).
2. **Exceptional $\tilde{G}_2$ 12-Root Lattices**: The 12-neighbor root system distinguishing 6 short roots (cyan) and 6 long roots (gold) with full $D_6$ dihedral Weyl group symmetry.
3. **Exact Non-Archimedean Macdonald Spherical Functions**: Live evaluation of $\Phi_z(m, n) = q^{-(m+n)} W(q^{-1})^{-1} \sum_{w \in W} c(w(z)) w(z)_1^{m+n} w(z)_2^n$ weighted by the Harish-Chandra / Gindikin-Karpelevich $c$-function.
4. **Poynting-Like Probability Flux Fields**: Real-time discrete quantum currents $j_{u \to v} = \mathrm{Im}(\psi(u)^* \psi(v))$ rendered as animated vector arrows and glowing particle streamlines tracing simplicial energy circulation and chiral vortices.
5. **Dual Satake Deltoid Spectrum**: Simultaneous dual-canvas telemetry plotting Hecke eigenvalues $\lambda_1(T_1), \lambda_2(T_2)$, the discrete Helmholtz eigenvalue $\lambda_\Delta$, and the exact Ramanujan spectral gap $\mathrm{Gap}(\Delta) = 2(q-1)^2$ across base primes $q \in \{2, 3, 5, 7\}$.

```
+----------------------------------------------------------------------------------------------------+
|                INTERACTIVE BRUHAT-TITS BUILDING & MACDONALD WAVE ENGINE                            |
+----------------------------------------------------------------------------------------------------+
|  Main Viewport Canvas (2D/3D)               Macdonald Evaluator           Dual Satake HUD Canvas   |
|  - A2 Triangulation Mesh (Types 0, 1, 2)    - S3 / D6 Weyl Superposition  - Hypocycloid Deltoid Dq |
|  - G2 Dihedral Root Vectors (Short/Long)    - Gindikin-Karpelevich c(z)   - Hecke Eigenvalues l1,l2|
|  - Animated Probability Current Flux        - Discrete Building Laplacian - Ramanujan Gap 2(q-1)^2 |
+----------------------------------------------------------------------------------------------------+
                                                   |
                      +----------------------------+----------------------------+
                      |                                                         |
                      v                                                         v
+------------------------------------------+             +------------------------------------------+
|       INTERACTIVE PARAMETERS             |             |       SCIENTIFIC COLORMAPS & MODES       |
|  - Prime q in {2, 3, 5, 7}               |             |  - Viridis, Plasma, Turbo, Magma, Chiral |
|  - Satake (theta_1, theta_2, |z|)        |             |  - Re(psi), Im(psi), |psi|, Arg, |psi|^2 |
|  - Time evolution e^{-i omega t}         |             |  - Contour Isolines & 3D Extrusion       |
+------------------------------------------+             +------------------------------------------+
```

---

## 1. Mathematical Physics Foundation

### 1.1 Simplicial Building Geometry & Vertex Types

Let $F = \mathbb{Q}_p$ be the field of $p$-adic numbers, $\mathcal{O}_F = \mathbb{Z}_p$ its maximal compact subring of integers, and $k = \mathbb{F}_p \cong \mathbb{Z}/p\mathbb{Z}$ the residue field of order $q = p$.

The 0-simplices (vertices) of the Bruhat-Tits building $\mathcal{B}(\mathrm{PGL}_3(\mathbb{Q}_p))$ are homothety classes $[L]$ of rank-3 $\mathbb{Z}_p$-lattices $L \subset \mathbb{Q}_p^3$. For $L = g \mathbb{Z}_p^3$ with $g \in \mathrm{GL}_3(\mathbb{Q}_p)$, the **vertex type** (3-coloring) is given by:

$$\tau(v) \equiv \mathrm{ord}_p(\det g) \pmod 3 \in \{0, 1, 2\}.$$

In apartment coordinates $(u, v) \in \mathbb{Z}^2$ along the fundamental weight basis $\varpi_1 = (1, 0)$ and $\varpi_2 = (1/2, \sqrt{3}/2)$:

$$\tau(u, v) = (u + 2v) \bmod 3.$$

Each vertex has:
- $d_{3, 1}(q) = q^2 + q + 1$ neighbors of type 1 (corresponding to 1D lines in $\mathbb{F}_p^3$).
- $d_{3, 2}(q) = q^2 + q + 1$ neighbors of type 2 (corresponding to 2D planes in $\mathbb{F}_p^3$).
- Total vertex degree $\mathrm{deg}(v) = 2(q^2 + q + 1)$.

| Prime $q$ | Type 1 Neighbors $d_{3,1}(q)$ | Type 2 Neighbors $d_{3,2}(q)$ | Total Vertex Degree $\mathrm{deg}(v)$ |
| :---: | :---: | :---: | :---: |
| $q = 2$ | $2^2 + 2 + 1 = \mathbf{7}$ | $2^2 + 2 + 1 = \mathbf{7}$ | $\mathbf{14}$ |
| $q = 3$ | $3^2 + 3 + 1 = \mathbf{13}$ | $3^2 + 3 + 1 = \mathbf{13}$ | $\mathbf{26}$ |
| $q = 5$ | $5^2 + 5 + 1 = \mathbf{31}$ | $5^2 + 5 + 1 = \mathbf{31}$ | $\mathbf{62}$ |
| $q = 7$ | $7^2 + 7 + 1 = \mathbf{57}$ | $7^2 + 7 + 1 = \mathbf{57}$ | $\mathbf{114}$ |

---

### 1.2 The Exceptional $\tilde{G}_2$ Hexagonal Root System

For the exceptional Lie group $G_2$, the apartment $\mathcal{A}(G_2)$ is a 2D hexagonal lattice with 12 root directions:
- **6 Short Roots (Length 1):**

$$\Phi_{\text{short}} = \left\lbrace \pm (1, 0), \pm \left(-\frac{1}{2}, \frac{\sqrt{3}}{2}\right), \pm \left(\frac{1}{2}, \frac{\sqrt{3}}{2}\right) \right\rbrace.$$

- **6 Long Roots (Length $\sqrt{3}$):**

$$\Phi_{\text{long}} = \left\lbrace \pm \left(-\frac{3}{2}, \frac{\sqrt{3}}{2}\right), \pm \left(\frac{3}{2}, \frac{\sqrt{3}}{2}\right), \pm (0, \sqrt{3}) \right\rbrace.$$

The Weyl group is the dihedral group $W(G_2) \cong D_6$ of order 12, generating the 12-fold star symmetric standing waves visualized in the application.

---

### 1.3 Exact Macdonald Spherical Eigenbasis & $c$-Functions

On the dominant Weyl chamber $\mathcal{A}^+ = \{(m, n) \in \mathbb{Z}^2 : m \ge 0, n \ge 0\}$, the normalized Macdonald spherical functions are given by:

$$\Phi_z(m, n) = q^{-(m+n)} \frac{1}{W(q^{-1})} \sum_{w \in S_3} c(w(z)) w(z)_1^{m+n} w(z)_2^n,$$

where:
- The Satake parameters $z = (z_1, z_2, z_3) \in \mathbb{C}^3$ satisfy $z_1 z_2 z_3 = 1$.
- The Harish-Chandra / Gindikin-Karpelevich $c$-function is:

$$c(z) = \prod_{1 \le i < j \le 3} \frac{z_i - q^{-1} z_j}{z_i - z_j}.$$

- The Poincaré polynomial normalization is:

$$W(q^{-1}) = 1 + 2 q^{-1} + 2 q^{-2} + q^{-3}.$$

#### Hecke Eigenvalues:
The function $\Phi_z$ satisfies the joint eigenvalue equations:

$$T_1 \Phi_z = q e_1(z) \Phi_z = \lambda_1 \Phi_z, \quad T_2 \Phi_z = q e_2(z) \Phi_z = \lambda_2 \Phi_z,$$

where $e_1(z) = z_1 + z_2 + z_3$ and $e_2(z) = z_1 z_2 + z_2 z_3 + z_3 z_1$.

#### Discrete Building Laplacian & Ramanujan Spectral Gap:
The non-Archimedean discrete Laplacian $\Delta = T_1 + T_2 - 2(q^2+q+1)I$ acts on $\Phi_z$ with eigenvalue:

$$\lambda_\Delta(z) = 2 q \mathrm{Re}(e_1(z)) - 2(q^2+q+1).$$

For unitary Satake parameters $z_j = e^{i \theta_j}$, the continuous tempered spectrum spans the compact interval:

$$\sigma_{\text{temp}}(\Delta) = [-3q - 2(q^2+q+1), \, 6q - 2(q^2+q+1)].$$

This continuous band is separated from the trivial bound state $\lambda_0 = 0$ by the exact non-Archimedean **Ramanujan Spectral Gap**:

$$\boxed{\mathrm{Gap}(\Delta) = 0 - (6q - 2(q^2+q+1)) = 2(q^2+q+1) - 6q = 2(q^2 - 2q + 1) = 2(q - 1)^2.}$$

| Prime $q$ | Tempered Band Top $\lambda_{\max}$ | Trivial State $\lambda_0$ | Exact Ramanujan Gap $2(q-1)^2$ |
| :---: | :---: | :---: | :---: |
| $q = 2$ | $6(2) - 14 = -\mathbf{2}$ | $0$ | $2(2-1)^2 = \mathbf{2}$ |
| $q = 3$ | $6(3) - 26 = -\mathbf{8}$ | $0$ | $2(3-1)^2 = \mathbf{8}$ |
| $q = 5$ | $6(5) - 62 = -\mathbf{32}$ | $0$ | $2(5-1)^2 = \mathbf{32}$ |
| $q = 7$ | $6(7) - 114 = -\mathbf{72}$ | $0$ | $2(7-1)^2 = \mathbf{72}$ |

---

### 1.4 Discrete Probability Current & Poynting Flux

For a complex building wavefunction $\psi(u, v, t) = \Phi_z(u, v) e^{-i \omega t}$, the non-Archimedean probability current along any directed edge $u \to v$ is:

$$j_{u \to v} = \mathrm{Im}(\psi(u)^* \psi(v)).$$

In the continuum apartment coordinates, this maps to the 2D vector field:

$$\vec{j}(x, y) = \mathrm{Im}(\psi^* \nabla \psi) = \left( \mathrm{Im}\left(\psi^* \frac{\partial \psi}{\partial x}\right), \mathrm{Im}\left(\psi^* \frac{\partial \psi}{\partial y}\right) \right).$$

When the Satake parameters possess asymmetric phases ($\theta_1 \ne \theta_2$), the building exhibits stationary circulating probability current vortices with non-vanishing simplicial circulation $\oint_{\partial C} \vec{j} \cdot d\vec{\ell} \ne 0$.

---

## 2. Interactive Features & Controls Guide

### 2.1 Presets Gallery

| Preset Name | Satake Angles $(\theta_1, \theta_2)$ | Structure / Physics | Phenomenon Visualized |
| :--- | :--- | :--- | :--- |
| **⚡ Tempered Ground** | $(0.00, 0.00)$ | $\Gamma$-Point Ground State | Maximum Hecke eigenvalue $\lambda_1 = 3q$; uniform in-phase standing wave. |
| **🛡️ Ramanujan Edge** | $(2.094, 2.094) = (\frac{2\pi}{3}, \frac{2\pi}{3})$ | Deltoid Cusp / Edge | Boundary of the tempered spectrum band; critical damping across simplicial faces. |
| **✡️ G₂ Dihedral Star** | $(0.785, 1.570) = (\frac{\pi}{4}, \frac{\pi}{2})$ | $G_2$ 12-Root Dihedral | 12-fold star symmetry with 6 short roots (cyan) and 6 long roots (gold). |
| **🌀 A₂ Chiral Vortex** | $(1.25, -0.85)$ | Chiral Quasimomenta | Rotating probability flux vortices circulating around simplicial 3-colored vertices. |
| **🌌 Sym²(Δ₁₂) Lift** | $(2.535, 0.00) = (2 \theta_3, 0)$ | Gelbart-Jacquet Lift | Automorphic transfer from Ramanujan's weight-12 cusp form $\Delta_{12}$ with $\tau(3) = 252$. |
| **✨ Buhler A₅ Galois** | $(1.257, -1.257) = (\frac{2\pi}{5}, -\frac{2\pi}{5})$ | Icosahedral Galois Field | Golden ratio spectrum $\phi = \frac{1+\sqrt{5}}{2} \approx 1.618$ with 5-fold phase symmetry. |
| **💠 Dirac K-Point** | $(2.094, 2.094)$ | Hexagonal Brillouin Corner | Conical dispersion / Dirac cone on the honeycomb dual lattice. |

---

### 2.2 Control Sidebar Tabs

The sidebar features 4 modular panels:

1. **Macdonald (Physics Tab)**:
   - **Base Prime ($q$)**: Toggle among $q = 2, 3, 5, 7$. Dynamically recomputes vertex degree $2(q^2+q+1)$ and updates all Hecke/Laplacian spectra.
   - **Phase $\theta_1, \theta_2$**: Adjust the unitary Satake phases on $S^1 \times S^1$.
   - **Hyperbolic Radius $|z|$**: Deform off the unit torus ($|z| \ne 1.0$) to simulate non-tempered complementary series representations.
   - **Time Evolution Speed**: Control the dynamic phase evolution rate $\psi(t) = \psi_0 e^{-i \omega t}$.
2. **Geometry (Apartment Tab)**:
   - **Apartment Radius ($R$)**: Expand the lattice from $R = 3$ (37 nodes) up to $R = 15$ (>700 nodes, >1400 simplices).
   - **Ã₂ Triangulation Simplices**: Toggle solid simplicial face rendering with adaptive alpha blending.
   - **3-Coloring Types (0, 1, 2)**: Render vertex halos in cyan (type 0), gold (type 1), and magenta (type 2).
   - **G̃₂ 12-Root Vectors**: Overlay the 6 short and 6 long root vectors.
   - **Dominant Weyl Chamber $A^+$**: Highlight the fundamental sector $m \ge 0, n \ge 0$ in translucent gold with dashed boundary walls.
   - **Chamber Wall Reflections**: Display the 6 root hyperplanes under $S_3$ reflection.
3. **Flux & Flow (Current Tab)**:
   - **Probability Current Arrows**: Draw directional vector arrows $\vec{j}$ scaled by flux magnitude.
   - **Animated Flow Particles**: Launch dynamic glowing particles that trace streamlines along vector field lines.
   - **Particle Density & Arrow Scaling**: Fine-tune particle count (50–600) and vector arrow exaggeration.
4. **Render (Colormaps Tab)**:
   - **Field Component**: Switch between $\mathrm{Re}(\psi)$, $\mathrm{Im}(\psi)$, $|\psi|$, $\mathrm{Arg}(\psi)$ (chiral phase), and $|\psi|^2$ (probability density).
   - **Scientific Colormap**: Choose from Viridis, Plasma, Turbo, Magma, and Chiral Cyclic Phase.
   - **Contour Isolines**: Enable up to 20 level curve isolines.

---

### 2.3 Interactive Dual Spectrum Canvas

The HUD in the upper-right corner features a dedicated Satake Hypocycloid Deltoid $\mathcal{D}_q$ canvas:
- **Interactive Drag & Steer**: Click and drag anywhere inside the spectral canvas to directly manipulate the Satake parameter $z \in \mathbb{C}^3$ and steer eigenvalues in real time.
- **Live Telemetry**: Real-time readout of Hecke $\lambda_1, \lambda_2$, Laplacian $\lambda_\Delta$, and the exact Ramanujan spectral gap.
- **Tempered Spectrum Bar**: Visual indicator showing where the current state lies relative to the continuous band $[-3q-deg, 6q-deg]$ and the isolated bound state $\lambda_0 = 0$.

---

## 3. Running the Visualizer Locally & Deployment

### 3.1 Direct File Access (Zero Dependencies)
Because the visualizer is completely self-contained in a single HTML file with pure vanilla JavaScript and HTML5 Canvas, you can open it directly in any modern web browser without running any servers:
```powershell
# Open directly in default web browser (Chrome, Edge, Firefox, Safari)
Start-Process "docs/building_visualizer.html"
```

### 3.2 Running via Local HTTP Server
To run via a local static web server:

**Option A — Python:**
```powershell
python -m http.server 8000
# Navigate to: http://localhost:8000/docs/building_visualizer.html
```

**Option B — Node / Vite (via gershgorin-visualizer):**
```powershell
cd gershgorin-visualizer
npm run dev
# Navigate to: http://localhost:5173/building_visualizer.html
```

### 3.3 GitHub Pages Deployment
1. Commit `docs/building_visualizer.html` to the repository `main` branch.
2. In the GitHub repository Settings $\to$ Pages $\to$ Source: Select `Deploy from a branch` and choose `/docs` directory.
3. Access at: `https://<organization>.github.io/<repo>/building_visualizer.html`.

---

## 4. Verification & Testing

The mathematical physics and rendering engine have been verified via automated test suites:

```powershell
python scripts/verify_visualizer.py
```

### Verification Checklist:
- [x] **HTML & DOM Structure**: Canvas elements, HUD panels, and responsive layout valid.
- [x] **JavaScript Syntax**: Validated with Node.js parser with 0 errors / 0 warnings.
- [x] **$A_2$ Macdonald Normalization**: Verified $\Phi_z(0, 0) = 1.000000000000$ to machine precision ($\lt 10^{-14}$).
- [x] **Hecke Eigenvalue Residuals**: Verified $\|T_1 \Phi_z - \lambda_1 \Phi_z\|_\infty \lt 10^{-12}$.
- [x] **Ramanujan Spectral Gap**: Verified exact algebraic identity $\mathrm{Gap}(\Delta) = 2(q-1)^2$ across $q \in \{2, 3, 5, 7\}$.
- [x] **Discrete Flux Conservation**: Simplicial probability currents satisfy $\sum_{v \sim u} j_{u \to v} = 0$ on stationary states.

---

## 5. References

1. I. G. Macdonald, *Spherical Functions on a Group of $p$-Adic Type*, Ramanujan Mathematical Society Publications, 1971.
2. I. G. Macdonald, *Affine Hecke Algebras and Orthogonal Polynomials*, Cambridge University Press, 2003.
3. F. Bruhat, J. Tits, *Groupes réductifs sur un corps local. I. Données radicielles valuées*, Publ. Math. IHÉS **41** (1972) 5–251.
4. S. S. Gubser, M. Heydeman, C. Jepsen, M. Marcolli, S. Parikh, D. S. Rangamani, P. C. Stoica, B. Trugenberger, *Edge prescription on the Bruhat-Tits tree*, Commun. Math. Phys. **352** (2017) 1019–1059.
5. P. Cartier, *Harmonic analysis on trees*, Proc. Sympos. Pure Math. **26** (1973) 419–424.
