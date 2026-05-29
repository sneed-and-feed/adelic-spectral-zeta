import sys

# Prevent pytest from hanging on Windows machines without native Triton/XLA compiler wheels
collect_ignore = []
if sys.platform == "win32":
    collect_ignore.extend(["test_ultrametric.py", "test_ultrametric_jax.py"])
