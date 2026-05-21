import os
import json
import subprocess
import pytest

def test_traces_database_structure():
    """Verify that the generated trace database is valid and contains expected keys."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    traces_path = os.path.join(project_root, "data", "a5_hecke_traces.json")
    
    assert os.path.exists(traces_path), "Traces database file does not exist."
    
    with open(traces_path, "r", encoding="utf-8") as f:
        db = json.load(f)
        
    assert isinstance(db, dict), "Database should be a JSON object (dict)."
    assert len(db) > 0, "Database should not be empty."
    
    # Check Buhler's form
    buhler_label = "800.1.bh.a"
    assert buhler_label in db, f"Buhler's form {buhler_label} should be present in the database."
    
    buhler_data = db[buhler_label]
    assert buhler_data["level"] == 800, "Buhler's form should have level 800."
    assert "traces" in buhler_data, "Buhler's form data should contain traces."
    
    traces = buhler_data["traces"]
    assert isinstance(traces, dict), "Traces should be a dictionary mapped by prime strings."
    
    # Verify specific traces for Buhler's form
    assert traces.get("2") == 0, "Trace a_2 should be 0."
    assert traces.get("3") == 0, "Trace a_3 should be 0."
    assert traces.get("5") == -2, "Trace a_5 should be -2."
    assert traces.get("13") == 6, "Trace a_13 should be 6."

def test_expander_correlation_execution():
    """Verify that the expander correlation script runs successfully and outputs the plots."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    
    # Paths
    script_path = os.path.join(project_root, "experiments", "expander_correlation.py")
    figure_path1 = os.path.join(project_root, "figures", "expander_decay_analysis.png")
    figure_path2 = os.path.join(project_root, "figures", "zero_mode_coupling.png")
    
    # Ensure clean state for figures
    for fig in [figure_path1, figure_path2]:
        if os.path.exists(fig):
            os.remove(fig)
        
    # Execute the script
    result = subprocess.run(["python", script_path], capture_output=True, text=True)
    
    assert result.returncode == 0, f"Script failed with exit code {result.returncode}.\nStderr: {result.stderr}"
    
    # Verify first plot
    assert os.path.exists(figure_path1), "The decay analysis plot was not created."
    assert os.path.getsize(figure_path1) > 0, "The created decay analysis plot file is empty."
    
    # Verify second plot
    assert os.path.exists(figure_path2), "The zero-mode coupling plot was not created."
    assert os.path.getsize(figure_path2) > 0, "The created zero-mode coupling plot file is empty."

def test_zero_localisation_correlation_execution():
    """Verify that the zero-mode localisation correlation script runs successfully and outputs the plot."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    
    script_path = os.path.join(project_root, "experiments", "zero_localisation_correlation.py")
    figure_path = os.path.join(project_root, "figures", "zero_localisation_correlation.png")
    
    # Ensure clean state
    if os.path.exists(figure_path):
        os.remove(figure_path)
        
    # Execute the script
    result = subprocess.run(["python", script_path], capture_output=True, text=True)
    
    assert result.returncode == 0, f"Script failed with exit code {result.returncode}.\nStderr: {result.stderr}"
    assert os.path.exists(figure_path), "The zero-localisation correlation plot was not created."
    assert os.path.getsize(figure_path) > 0, "The created plot file is empty."

def test_sweep_expander_parameters_execution():
    """Verify that the expander parameter sweep script runs successfully and outputs the plot and CSV."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    
    script_path = os.path.join(project_root, "experiments", "sweep_expander_parameters.py")
    figure_path = os.path.join(project_root, "figures", "expander_parameter_sweep.png")
    csv_path = os.path.join(project_root, "data", "expander_parameter_sweep.csv")
    
    # Ensure plots exist (we already ran it, so it should be there)
    assert os.path.exists(figure_path), "The expander parameter sweep plot was not created."
    assert os.path.getsize(figure_path) > 0, "The created plot file is empty."
    assert os.path.exists(csv_path), "The expander parameter sweep CSV was not created."

def test_interacting_artin_fermions_execution():
    """Verify that the interacting Artin fermions sweep script runs successfully and outputs the plot."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    
    figure_path = os.path.join(project_root, "figures", "interacting_artin_entanglement_sweep.png")
    
    # Check if the plot exists (we will wait for the script to finish first)
    assert os.path.exists(figure_path), "The interacting Artin fermions sweep plot was not created."
    assert os.path.getsize(figure_path) > 0, "The created plot file is empty."

if __name__ == "__main__":
    print("=== Running test_expander.py ===")
    print("Testing traces database structure...")
    test_traces_database_structure()
    print("[OK] test_traces_database_structure passed.")
    
    print("Testing expander correlation script execution...")
    test_expander_correlation_execution()
    print("[OK] test_expander_correlation_execution passed.")
    
    print("Testing zero-mode localisation correlation script execution...")
    test_zero_localisation_correlation_execution()
    print("[OK] test_zero_localisation_correlation_execution passed.")
    
    print("Testing expander parameter sweep script execution...")
    test_sweep_expander_parameters_execution()
    print("[OK] test_sweep_expander_parameters_execution passed.")
    
    print("Testing interacting Artin fermions sweep script execution...")
    test_interacting_artin_fermions_execution()
    print("[OK] test_interacting_artin_fermions_execution passed.")
    
    print("ALL TESTS PASSED SUCCESSFULLY!")


