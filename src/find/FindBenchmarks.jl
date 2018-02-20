module FindBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup()

########################
# findall              #
########################

g = addgroup!(SUITE, "findall")

const VEC_LENGTH = 1000

for (name, x) in (("50-50", Vector{Bool}(samerand(Bool, VEC_LENGTH))),
                  ("10-90", Vector{Bool}(samerand(VEC_LENGTH) .> .9)),
                  ("90-10", Vector{Bool}(samerand(VEC_LENGTH) .> .1)))
    g[string(typeof(x)), name] = @benchmarkable findall($x)

    bx = BitArray(x)
    g[string(typeof(bx)), name] = @benchmarkable findall($bx)

    if VERSION < v"0.7.0-DEV.4017"
        gx = (v for v in x)
        g[string(typeof(gx)), name] = @benchmarkable findall($gx)
    end
end


ispos(x) = x > 0

for T in (Bool, Int8, Int, UInt8, UInt, Float32, Float64)
    y = samerand(T, VEC_LENGTH)
    g["ispos", string(typeof(y))] = @benchmarkable findall($ispos, $y)

    if VERSION < v"0.7.0-DEV.4017"
        gy = (v for v in y)
        g["ispos", string(typeof(gy))] = @benchmarkable findall($ispos, $gy)
    end
end

########################
# findnext/findprev    #
########################

gn = addgroup!(SUITE, "findnext")
gp = addgroup!(SUITE, "findprev")

const VEC_LENGTH = 1000

if VERSION < v"0.7.0-DEV.3399"

    function perf_findnext(x)
        s = findnext(x, first(linearindices(x)))
        while s > 0
            s = findnext(x, nextind(x, s))
        end
        s
    end

    function perf_findprev(x)
        s = findprev(x, last(linearindices(x)))
        while s > 0
            s = findprev(x, prevind(x, s))
        end
        s
    end

    function perf_findnext(pred, x)
        s = findnext(pred, x, first(linearindices(x)))
        while s > 0
            s = findnext(pred, x, nextind(x, s))
        end
        s
    end

    function perf_findprev(pred, x)
        s = findprev(pred, x, last(linearindices(x)))
        while s > 0
            s = findprev(pred, x, prevind(x, s))
        end
        s
    end

else

    function perf_findnext(x)
        s = findnext(x, first(linearindices(x)))
        while s !== nothing
            s = findnext(x, nextind(x, s))
        end
        s
    end

    function perf_findprev(x)
        s = findprev(x, last(linearindices(x)))
        while s !== nothing
            s = findprev(x, prevind(x, s))
        end
        s
    end

    function perf_findnext(pred, x)
        s = findnext(pred, x, first(linearindices(x)))
        while s !== nothing
            s = findnext(pred, x, nextind(x, s))
        end
        s
    end

    function perf_findprev(pred, x)
        s = findprev(pred, x, last(linearindices(x)))
        while s !== nothing
            s = findprev(pred, x, prevind(x, s))
        end
        s
    end

end

for (name, x) in (("50-50", samerand(Bool, VEC_LENGTH)),
                  ("10-90", samerand(VEC_LENGTH) .> .9),
                  ("90-10", samerand(VEC_LENGTH) .> .1))
    bx = BitArray(x)

    gn[string(typeof(x)), name] = @benchmarkable perf_findnext($x)
    gn[string(typeof(bx)), name] = @benchmarkable perf_findnext($bx)

    gp[string(typeof(x)), name] = @benchmarkable perf_findprev($x)
    gp[string(typeof(bx)), name] = @benchmarkable perf_findprev($bx)
end

for T in (Bool, Int8, Int, UInt8, UInt, Float32, Float64)
    y = samerand(T, VEC_LENGTH)
    gn["ispos", string(typeof(y))] = @benchmarkable perf_findnext($ispos, $y)
    gp["ispos", string(typeof(y))] = @benchmarkable perf_findprev($ispos, $y)
end

end
