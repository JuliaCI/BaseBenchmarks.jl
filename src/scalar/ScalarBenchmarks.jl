module ScalarBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

import Compat: UTF8String, view

const SUITE = BenchmarkGroup()

const INTS = (UInt, Int, BigInt)
const FLOATS = (Float32, Float64, BigFloat)
const REALS = (INTS..., FLOATS...)
const COMPS = map(R -> Complex{R}, REALS)
const NUMS = (REALS..., COMPS...)
const BIGNUMS = (BigInt, BigFloat, Complex{BigInt}, Complex{BigFloat})

##############
# predicates #
##############

g = addgroup!(SUITE, "predicate", ["isinteger", "isinf", "isnan", "iseven", "isodd"])

for T in NUMS
    x = one(T)
    tstr = string(T)
    tol = in(T, BIGNUMS) ? 0.40 : 0.25
    g["isequal", tstr]   = @benchmarkable isequal($x, $x) time_tolerance=tol
    g["isinteger", tstr] = @benchmarkable isinteger($x) time_tolerance=tol
    g["isinf", tstr]     = @benchmarkable isinf($x) time_tolerance=tol
    g["isfinite", tstr]  = @benchmarkable isfinite($x) time_tolerance=tol
    g["isnan", tstr]     = @benchmarkable isnan($x) time_tolerance=tol
end

for T in REALS
    x = one(T)
    tstr = string(T)
    tol = in(T, BIGNUMS) ? 0.40 : 0.25
    g["isless", tstr] = @benchmarkable isless($x, $x) time_tolerance=tol
end

for T in INTS
    x = one(T)
    tstr = string(T)
    tol = in(T, BIGNUMS) ? 0.40 : 0.25
    g["iseven", tstr] = @benchmarkable iseven($x) time_tolerance=tol
    g["isodd", tstr]  = @benchmarkable isodd($x) time_tolerance=tol
end

##############
# arithmetic #
##############

arith = addgroup!(SUITE, "arithmetic")
fstmth = addgroup!(SUITE, "fastmath", ["arithmetic"])

for X in NUMS
    x = one(X)
    xstr = string(X)
    isbignum = in(X, BIGNUMS)
    fstmth["add", xstr] = @benchmarkable @fastmath($x * $(copy(x))) time_tolerance=0.40
    fstmth["sub", xstr] = @benchmarkable @fastmath($x - $(copy(x))) time_tolerance=0.40
    fstmth["mul", xstr] = @benchmarkable @fastmath($x + $(copy(x))) time_tolerance=0.40
    fstmth["div", xstr] = @benchmarkable @fastmath($x / $(copy(x))) time_tolerance=0.40
    for Y in NUMS
        y = one(Y)
        ystr = string(Y)
        tol = (X != Y || isbignum) ? 0.50 : 0.25
        arith["add", xstr, ystr] = @benchmarkable +($x, $y) time_tolerance=tol
        arith["sub", xstr, ystr] = @benchmarkable -($x, $y) time_tolerance=tol
        arith["mul", xstr, ystr] = @benchmarkable *($x, $y) time_tolerance=tol
        arith["div", xstr, ystr] = @benchmarkable /($x, $y) time_tolerance=tol
    end
end

#############
# iteration #
#############

function perf_iterate_indexed(n, v)
    s = 0
    for i = 1:n
        for j = 1:1
            @inbounds k = v[j]
            s += k
        end
    end
    s
end

function perf_iterate_in(n, v)
    s = 0
    for i = 1:n
        for k in v
            s += k
        end
    end
    s
end

g = addgroup!(SUITE, "iteration", ["indexed", "in"])

g["indexed"] = @benchmarkable perf_iterate_indexed(10^5, 3) time_tolerance=0.25
g["in"]      = @benchmarkable perf_iterate_in(10^5, 3) time_tolerance=0.25


g = addgroup!(SUITE, "floatexp")

g["ldexp","norm -> norm",       "Float64"] = @benchmarkable ldexp(1.7,  10)
g["ldexp","norm -> norm",       "Float32"] = @benchmarkable ldexp(1.7f0,10)
g["ldexp","norm -> subnorm",    "Float64"] = @benchmarkable ldexp(1.7,  -1028)
g["ldexp","norm -> subnorm",    "Float32"] = @benchmarkable ldexp(1.7f0,-128)
g["ldexp","norm -> inf",        "Float64"] = @benchmarkable ldexp(1.7,  1028)
g["ldexp","norm -> inf",        "Float32"] = @benchmarkable ldexp(1.7f0,128)
g["ldexp","subnorm -> norm",    "Float64"] = @benchmarkable ldexp(1.7e-310, 100)
g["ldexp","subnorm -> norm",    "Float32"] = @benchmarkable ldexp(1.7f-40,  100)
g["ldexp","subnorm -> subnorm", "Float64"] = @benchmarkable ldexp(1.7e-310,-3)
g["ldexp","subnorm -> subnorm", "Float32"] = @benchmarkable ldexp(1.7f-40, -3)
g["ldexp","inf -> inf",        "Float64"] = @benchmarkable ldexp(Inf,  10)
g["ldexp","inf -> inf",        "Float32"] = @benchmarkable ldexp(Inf32,10)

g["frexp","norm",    "Float64"] = @benchmarkable frexp(1.7)
g["frexp","norm",    "Float32"] = @benchmarkable frexp(1.7f0)
g["frexp","subnorm", "Float64"] = @benchmarkable frexp(1.7e-310)
g["frexp","subnorm", "Float32"] = @benchmarkable frexp(1.7f-40)
g["frexp","inf", "Float64"] = @benchmarkable frexp(Inf)
g["frexp","inf", "Float32"] = @benchmarkable frexp(Inf32)

g["exponent","norm",    "Float64"] = @benchmarkable exponent(1.7)
g["exponent","norm",    "Float32"] = @benchmarkable exponent(1.7f0)
g["exponent","subnorm", "Float64"] = @benchmarkable exponent(1.7e-310)
g["exponent","subnorm", "Float32"] = @benchmarkable exponent(1.7f-40)

g["significand","norm",    "Float64"] = @benchmarkable significand(1.7)
g["significand","norm",    "Float32"] = @benchmarkable significand(1.7f0)
g["significand","subnorm", "Float64"] = @benchmarkable significand(1.7e-310)
g["significand","subnorm", "Float32"] = @benchmarkable significand(1.7f-40)



end # module
