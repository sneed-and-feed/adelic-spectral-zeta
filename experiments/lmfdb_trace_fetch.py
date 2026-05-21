import os
import json
import urllib.request
import urllib.error

def get_primes(n):
    """Generate a list of prime numbers up to n."""
    sieve = [True] * (n + 1)
    for p in range(2, int(n**0.5) + 1):
        if sieve[p]:
            for i in range(p*p, n + 1, p):
                sieve[i] = False
    return [p for p in range(2, n + 1) if sieve[p]]

def main():
    print("=" * 70)
    print("LMFDB A5 WEIGHT-1 TRACE FETCHER")
    print("=" * 70)
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    
    cache_path = os.path.join(project_root, "data", "lmfdb_a5_newforms.json")
    output_path = os.path.join(project_root, "data", "a5_hecke_traces.json")
    
    # 1. Attempt API query
    url = "https://www.lmfdb.org/api/mf_newforms/?weight=1&projective_image=A5&_format=json&_pagesize=100&_offset=0"
    data = None
    
    print(f"Querying LMFDB API: {url}")
    try:
        req = urllib.request.Request(
            url, 
            headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
        )
        with urllib.request.urlopen(req, timeout=10) as response:
            content = response.read()
            # Check if we got HTML instead of JSON (which indicates reCAPTCHA challenge page)
            if content.strip().startswith(b"<!doctype html>") or b"<html" in content[:200].lower():
                print("[WARNING] API request returned HTML/reCAPTCHA challenge. Falling back to local cache.")
            else:
                data = json.loads(content.decode("utf-8"))
                print("[OK] Successfully fetched live data from LMFDB API.")
    except Exception as e:
        print(f"[WARNING] API request failed: {e}. Falling back to local cache.")
        
    # 2. Fallback to local cache if needed
    if data is None:
        if os.path.exists(cache_path):
            print(f"Loading local cache from: {cache_path}")
            with open(cache_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            print("[OK] Successfully loaded cached data.")
        else:
            raise FileNotFoundError(f"Local cache file not found at {cache_path} and API was unavailable.")
            
    # 3. Process the forms and extract traces at prime indices
    newforms = data.get("data", [])
    print(f"Processing {len(newforms)} forms...")
    
    # We generate primes up to 2000, since traces array is of length 2000
    primes = get_primes(2000)
    
    processed_db = {}
    for form in newforms:
        label = form.get("label")
        level = form.get("level")
        traces = form.get("traces", [])
        
        if not label or not level or not traces:
            continue
            
        # Map prime numbers p to traces[p-1]
        prime_traces = {}
        for p in primes:
            if p - 1 < len(traces):
                # Save as string key for JSON compatibility
                prime_traces[str(p)] = int(traces[p-1])
                
        processed_db[label] = {
            "level": int(level),
            "traces": prime_traces
        }
        
    # 4. Save processed database
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(processed_db, f, indent=2)
        
    print(f"[SUCCESS] Processed traces database saved to: {output_path}")
    print(f"Total forms stored: {len(processed_db)}")
    
    # Print some statistics
    levels = [item["level"] for item in processed_db.values()]
    print(f"Level range: {min(levels)} to {max(levels)}")
    
    # Spot-check Buhler's level 800 form
    buhler_label = "800.1.bh.a"
    if buhler_label in processed_db:
        print(f"\nSpot-check Buhler's form ({buhler_label}):")
        buhler_traces = processed_db[buhler_label]["traces"]
        for p in [2, 3, 5, 7, 11, 13]:
            print(f"  p = {p:<2} -> a_p = {buhler_traces.get(str(p))}")
            
    print("=" * 70)

if __name__ == "__main__":
    main()
