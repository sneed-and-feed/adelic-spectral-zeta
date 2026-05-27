def get_trace_elements(d):
    N_half = 1 << (d - 2)
    N = 1 << (d - 1)
    elements = []
    for x in range(N_half):
        y = (x + N_half) % N
        # Check if Adj x y
        adj1 = (y == (3 * x) % N)
        adj2 = (y == (3 * x - 1) % N)
        adj3 = (x == (3 * y) % N)
        adj4 = (x == (3 * y - 1) % N)
        if adj1 or adj2 or adj3 or adj4:
            elements.append(x)
            print(f"x={x}, adj1={adj1}, adj2={adj2}, adj3={adj3}, adj4={adj4}")
    print(f"Total for d={d}: {len(elements)}")

for d in range(3, 7):
    get_trace_elements(d)
