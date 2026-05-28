def check_connectivity(d):
    V = 1 << (d - 1)
    visited = [False] * V
    queue = [0]
    visited[0] = True
    inv_3 = None
    for i in range(V):
        if (3 * i) % V == 1:
            inv_3 = i
            break
    if inv_3 is None:
        inv_3 = 1  # For V = 1 (d = 2)
    while queue:
        curr = queue.pop(0)
        neighbors = [
            (3 * curr) % V,
            (3 * curr - 1) % V,
            (inv_3 * curr) % V,
            (inv_3 * (curr + 1)) % V
        ]
        for n in neighbors:
            if not visited[n]:
                visited[n] = True
                queue.append(n)
    return all(visited)

for d in range(2, 13):
    print(f"Depth {d}: connected? {check_connectivity(d)}")
