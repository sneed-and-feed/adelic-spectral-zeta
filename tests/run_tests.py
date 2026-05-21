import subprocess
import os

print("=== Adélic Spectral Triple Verification Runner ===")

# Run the simulation script
script_path = "simulation.py"
print(f"Executing {script_path}...")
result = subprocess.run(["python", script_path], capture_output=True, text=True)

# Print output
print("\n--- Simulation Output ---")
print(result.stdout)

if result.stderr:
    print("\n--- Simulation Errors ---")
    print(result.stderr)

# Check files
output_dir = "C:/Users/x/.gemini/antigravity/scratch/adelic_spectral_zeta"
expected_files = [
    "phase1_eigenvalues.png",
    "phase2_regularization.txt",
    "phase3_metric_inflation.png",
    "phase3_telemetry.txt"
]

print("\n--- Output Verification ---")
success = True
for f in expected_files:
    full_path = os.path.join(output_dir, f)
    if os.path.exists(full_path):
        print(f"[OK] Created file: {f} (Size: {os.path.getsize(full_path)} bytes)")
    else:
        print(f"[FAIL] Missing file: {f}")
        success = False

if success and result.returncode == 0:
    print("\nALL PHASES COMPLETED AND VERIFIED SUCCESSFULLY!")
else:
    print("\nVERIFICATION FAILED. CHECK ERRORS ABOVE.")
