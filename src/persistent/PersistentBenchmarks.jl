module CollectionBenchmarks

using BenchmarkTools
using Random
using StableRNGs

import Base: PersistentDict, ImmutableDict

using BenchmarkTools
using Random
using StableRNGs

const SUITE = BenchmarkGroup()

const RNG = StableRNG(1)

function create(::Type{Dict}, values::Vector{Pair{K,V}}) where {Dict, K, V}
    dict = Dict{K,V}()
    for p in values
        dict = Dict(dict, p)
    end
    dict
end

mutable struct Key{T}
    k::T
end

g = addgroup!(SUITE, "initialization", ["Associative", "persistent"])

for N in (256, 512, 1024, 2048)
    ints = [i=>i for i in 1:N]
    mints = [Key(i)=>i for i in 1:N]
    g["ImmutableDict", "Int=>Int", N] = @benchmarkable create(ImmutableDict, $ints)
    g["PersistentDict", "Int=>Int", N] = @benchmarkable create(PersistentDict, $ints)
    g["ImmutableDict", "Key{Int}=>Int", N] = @benchmarkable create(ImmutableDict, $mints)
    g["PersistentDict", "Key{Int}=>Int", N] = @benchmarkable create(PersistentDict, $mints)
end

end