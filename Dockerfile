FROM python:3.10-slim

WORKDIR /app

# Copy dependency files
COPY pyproject.toml /app/

# Install dependencies (using uv for speed, or falling back to pip)
RUN pip install --no-cache-dir uv && \
    uv pip install --system -e .

# Copy source code
COPY . /app/

# Default command
CMD ["python", "-c", "import adelic_spectral_zeta; print('adelic_spectral_zeta installed successfully.')"]
