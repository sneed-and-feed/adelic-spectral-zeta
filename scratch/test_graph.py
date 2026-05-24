import collections

d = 5
N = 2**(d-1)
print(f"N = {N}")

# Let's find the shortest path from each v to 0 using predecessors
# Predecessors of v: p1 = v/3, p2 = (v+1)/3
adj = {}
for v in range(N):
    p1 = (v * pow(3, -1, N)) % N
    p2 = ((v + 1) * pow(3, -1, N)) % N
    adj[v] = [p1, p2]

def v2(x):
    if x == 0: return d - 1
    count = 0
    while x % 2 == 0:
        count += 1
        x //= 2
    return count

for start in range(1, N):
    # BFS to find shortest path to 0
    queue = collections.deque([[start]])
    visited = {start}
    path = None
    while queue:
        curr_path = queue.popleft()
        curr = curr_path[-1]
        if curr == 0:
            path = curr_path
            break
        for nxt in adj[curr]:
            if nxt not in visited:
                visited.add(nxt)
                queue.append(curr_path + [nxt])
    
    path_str = " -> ".join(f"{x}(v2={v2(x)})" for x in path)
    print(f"Path from {start}: {path_str}")
