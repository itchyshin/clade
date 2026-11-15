# Independent check of the fixed key layout and SplitMix64 low-bit balance.
M=(1<<64)-1
def mix(x):
 z=(x+0x9e3779b97f4a7c15)&M
 z=((z^(z>>30))*0xbf58476d1ce4e5b9)&M
 z=((z^(z>>27))*0x94d049bb133111eb)&M
 return (z^(z>>31))&M
keys=[(seed<<40)^(agent<<10)^tick for seed in range(71001,71006) for agent in range(1,201) for tick in range(1,101)]
assert len(keys)==len(set(keys));n=sum(mix(k)&1==0 for k in keys);assert abs(n/len(keys)-.5)<.01
print(f'PASS: {len(keys)} distinct seed/agent/tick keys; {n/len(keys):.5f} hash blocks on the synthetic grid.')
