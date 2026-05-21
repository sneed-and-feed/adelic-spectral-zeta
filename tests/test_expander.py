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

if __name__ == "__main__":
    print("=== Running test_expander.py ===")
    print("Testing traces database structure...")
    test_traces_database_structure()
    print("[OK] test_traces_database_structure passed.")
    
    print("Testing expander correlation script execution...")
    test_expander_correlation_execution()
    print("[OK] test_expander_correlation_execution passed.")
    
    print("ALL TESTS PASSED SUCCESSFULLY!")

