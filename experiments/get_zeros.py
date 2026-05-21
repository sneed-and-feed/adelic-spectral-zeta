import requests

url = "https://www.lmfdb.org/api/lfunc_lfunctions/"
query = {
    "degree": 4,
    "conductor": 1,
    "_format": "json"
}

try:
    response = requests.get(url, params=query)
    print("Status:", response.status_code)
    try:
        data = response.json()
        print("Keys:", data.keys() if hasattr(data, 'keys') else type(data))
        if "data" in data:
            for item in data["data"]:
                print(item.get("label"), item.get("zeros")[:5] if item.get("zeros") else None)
        else:
            print("Response:", str(data)[:500])
    except Exception as e:
        print("Error parsing JSON:", e)
        print("Response text:", response.text[:500])
except Exception as e:
    print("Error:", e)
