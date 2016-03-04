module ScalarBenchmarks

using ..BaseBenchmarks: GROUPS
using BenchmarkTools

const INTS = (UInt, Int, BigInt)
const FLOATS = (Float32, Float64, BigFloat)
const REALS = (INTS..., FLOATS...)
const COMPS = map(R -> Complex{R}, REALS)
const NUMS = (REALS..., COMPS...)

const SCALAR_TIME = 1
const SCALAR_GC = true

##############
# predicates #
##############

g = addgroup!(GROUPS, "scalar predicate",  ["scalar", "predicate", "isinteger", "isinf",
                                            "isnan", "iseven", "isodd"])

for T in NUMS
    x = one(T)
    tstr = string(T)
    g["isequal", tstr]   = @benchmarkable(isequal($x, $x), $SCALAR_TIME)
    g["isless", tstr]    = @benchmarkable(isequal($x, $x), $SCALAR_TIME)
    g["isinteger", tstr] = @benchmarkable(isinteger($x), $SCALAR_TIME)
    g["isinf", tstr]     = @benchmarkable(isinf($x), $SCALAR_TIME)
    g["isfinite", tstr]  = @benchmarkable(isfinite($x), $SCALAR_TIME)
    g["isnan", tstr]     = @benchmarkable(isnan($x), $SCALAR_TIME)
end

for T in INTS
    x = one(T)
    tstr = string(T)
    g["iseven", tstr] = @benchmarkable(iseven($x), $SCALAR_TIME, $SCALAR_GC)
    g["isodd", tstr] = @benchmarkable(isodd($x), $SCALAR_TIME, $SCALAR_GC)
end

##############
# arithmetic #
##############

perf_fastmath_mul(a, b) = @fastmath a * b
perf_fastmath_div(a, b) = @fastmath a / b
perf_fastmath_add(a, b) = @fastmath a + b
perf_fastmath_sub(a, b) = @fastmath a - b

g = addgroup!(GROUPS, "scalar arithmetic",  ["scalar", "arithmetic", "fastmath"])

for Ti in NUMS, Tj in NUMS
    xi, xj = one(Ti), one(Tj)
    tistr, tjstr = string(Ti), string(Tj)
    g["scalar_add", tistr, tjstr] = @benchmarkable(+($xi, $xj), $SCALAR_TIME, $SCALAR_GC)
    g["scalar_sub", tistr, tjstr] = @benchmarkable(-($xi, $xj), $SCALAR_TIME, $SCALAR_GC)
    g["scalar_mul", tistr, tjstr] = @benchmarkable(*($xi, $xj), $SCALAR_TIME, $SCALAR_GC)
    g["scalar_div", tistr, tjstr] = @benchmarkable(/($xi, $xj), $SCALAR_TIME, $SCALAR_GC)
    g["scalar_fastmath_add", tistr, tjstr] = @benchmarkable(perf_fastmath_add($xi, $xj), $SCALAR_TIME, $SCALAR_GC)
    g["scalar_fastmath_sub", tistr, tjstr] = @benchmarkable(perf_fastmath_sub($xi, $xj), $SCALAR_TIME, $SCALAR_GC)
    g["scalar_fastmath_mul", tistr, tjstr] = @benchmarkable(perf_fastmath_mul($xi, $xj), $SCALAR_TIME, $SCALAR_GC)
    g["scalar_fastmath_div", tistr, tjstr] = @benchmarkable(perf_fastmath_div($xi, $xj), $SCALAR_TIME, $SCALAR_GC)
end

end # module
