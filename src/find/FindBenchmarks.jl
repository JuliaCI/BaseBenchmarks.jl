module FindBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools, Statistics

const SUITE = BenchmarkGroup()

########################
# findall              #
########################

g = addgroup!(SUITE, "findall")

const VEC_LENGTH = 1000

for (name, x) in (("50-50", Vector{Bool}(samerand(Bool, VEC_LENGTH))),
                  ("10-90", Vector{Bool}(samerand(VEC_LENGTH) .> .9)),
                  ("90-10", Vector{Bool}(samerand(VEC_LENGTH) .> .1)))
    # the inputs are random bit patterns; see `@benchmarkable_reshuffled`
    g[string(typeof(x)), name] = @benchmarkable_reshuffled x findall($x)

    bx = BitArray(x)
    g[string(typeof(bx)), name] = @benchmarkable_reshuffled bx findall($bx)
end


ispos(x) = x > 0

for T in (Bool, Int8, Int, UInt8, UInt, Float32, Float64)
    y = samerand(T, VEC_LENGTH)
    g["ispos", string(typeof(y))] = @benchmarkable findall($ispos, $y)

    # vary the proportion of returned elements (i.e size of returned array)
    ps = [0.5, 0.8, 0.95, 0.99]
    qs = quantile(y, ps)
    for (p, q) in zip(ps, qs)
        g["> q$p", string(typeof(y))] = @benchmarkable findall($(x -> x > q), $y)
    end
end


########################
# findnext/findprev    #
########################

gn = addgroup!(SUITE, "findnext")
gp = addgroup!(SUITE, "findprev")

const VEC_LENGTH = 1000

function perf_findnext(x)
    s = findfirst(x)
    while s !== nothing
        s = findnext(x, nextind(x, s))
    end
    s
end

function perf_findprev(x)
    s = findlast(x)
    while s !== nothing
        s = findprev(x, prevind(x, s))
    end
    s
end

function perf_findnext(pred, x)
    s = findfirst(pred, x)
    while s !== nothing
        s = findnext(pred, x, nextind(x, s))
    end
    s
end

function perf_findprev(pred, x)
    s = findlast(pred, x)
    while s !== nothing
        s = findprev(pred, x, prevind(x, s))
    end
    s
end

for (name, x) in (("50-50", samerand(Bool, VEC_LENGTH)),
                  ("10-90", samerand(VEC_LENGTH) .> .9),
                  ("90-10", samerand(VEC_LENGTH) .> .1))
    bx = BitArray(x)

    gn[string(typeof(x)), name] = @benchmarkable_reshuffled x perf_findnext($x)
    gn[string(typeof(bx)), name] = @benchmarkable_reshuffled bx perf_findnext($bx)

    gp[string(typeof(x)), name] = @benchmarkable_reshuffled x perf_findprev($x)
    gp[string(typeof(bx)), name] = @benchmarkable_reshuffled bx perf_findprev($bx)
end

for T in (Bool, Int8, Int, UInt8, UInt, Float32, Float64)
    y = samerand(T, VEC_LENGTH)
    # `ispos` is a coin flip for the signed types and Bool, and (nearly) always true otherwise
    coinflip = T in (Bool, Int8, Int)
    gn["ispos", string(typeof(y))] = @benchmarkable_reshuffled_if coinflip y perf_findnext($ispos, $y)
    gp["ispos", string(typeof(y))] = @benchmarkable_reshuffled_if coinflip y perf_findprev($ispos, $y)
end

end
