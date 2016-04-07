module ScalarBenchmarks

using ..BaseBenchmarks: SUITE
using BenchmarkTools

const INTS = (UInt, Int, BigInt)
const FLOATS = (Float32, Float64, BigFloat)
const REALS = (INTS..., FLOATS...)
const COMPS = map(R -> Complex{R}, REALS)
const NUMS = (REALS..., COMPS...)

##############
# predicates #
##############

g = newgroup!(SUITE, "scalar predicate",  ["scalar", "predicate", "isinteger", "isinf",
                                            "isnan", "iseven", "isodd"])

for T in NUMS
    x = one(T)
    tstr = string(T)
    g["isequal", tstr]   = @benchmarkable isequal($x, $x)
    g["isless", tstr]    = @benchmarkable isequal($x, $x)
    g["isinteger", tstr] = @benchmarkable isinteger($x)
    g["isinf", tstr]     = @benchmarkable isinf($x)
    g["isfinite", tstr]  = @benchmarkable isfinite($x)
    g["isnan", tstr]     = @benchmarkable isnan($x)
end

for T in INTS
    x = one(T)
    tstr = string(T)
    g["iseven", tstr] = @benchmarkable iseven($x)
    g["isodd", tstr] = @benchmarkable isodd($x)
end

##############
# arithmetic #
##############

g = newgroup!(SUITE, "scalar arithmetic",  ["scalar", "arithmetic", "fastmath"])

for Ti in NUMS, Tj in NUMS
    xi, xj = one(Ti), one(Tj)
    tistr, tjstr = string(Ti), string(Tj)
    g["scalar_add", tistr, tjstr] = @benchmarkable +($xi, $xj)
    g["scalar_sub", tistr, tjstr] = @benchmarkable -($xi, $xj)
    g["scalar_mul", tistr, tjstr] = @benchmarkable *($xi, $xj)
    g["scalar_div", tistr, tjstr] = @benchmarkable /($xi, $xj)
    g["scalar_fastmath_add", tistr, tjstr] = @benchmarkable @fastmath a * b
    g["scalar_fastmath_sub", tistr, tjstr] = @benchmarkable @fastmath a / b
    g["scalar_fastmath_mul", tistr, tjstr] = @benchmarkable @fastmath a + b
    g["scalar_fastmath_div", tistr, tjstr] = @benchmarkable @fastmath a - b
end

end # module
