s=read(joinpath(@__DIR__,"driver.jl"),String);m=match(r"(?s)function mix64\(x::UInt64\).*?\nend",s);m===nothing && error("gate hash function missing");include_string(Main,m.match)
cases=((71001,1,1,0xb03cd15aeb1ee504),(71001,1234,500,0x30d5777e93828f8c),(71100,700000,1000,0x87541945dc4f9833),(70001,42,200,0x3e0fa6134cd2ea95))
for (seed,id,t,expected) in cases
 key=(UInt64(seed)<<40)⊻(UInt64(id)<<10)⊻UInt64(t);mix64(key)==expected || error("gate hash differs from independent Python fixture")
end
println("PASS: four Julia gate hash results match independent Python fixtures")
