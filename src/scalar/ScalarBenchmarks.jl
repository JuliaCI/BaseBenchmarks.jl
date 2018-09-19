module ScalarBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

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
    fstmth["add", xstr] = @benchmarkable @fastmath($x + $(copy(x))) time_tolerance=0.40
    fstmth["sub", xstr] = @benchmarkable @fastmath($x - $(copy(x))) time_tolerance=0.40
    fstmth["mul", xstr] = @benchmarkable @fastmath($x * $(copy(x))) time_tolerance=0.40
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

for X in (INTS..., Char, Bool)
    x = X(1) # one(X) is not valid for X==Char
    xstr = string(X)
    for Y in (INTS..., Bool)
        VERSION < v"0.6" && Y == BigInt && continue
        tol = (X != Y || X == BigInt || Y == BigInt) ? 0.40 : 0.25
        arith["rem type", xstr, string(Y)] = @benchmarkable %($x, $Y) time_tolerance=tol
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

##############
# intfuncs   #
##############

g = addgroup!(SUITE, "intfuncs", ["prevpow2", "nextpow2"])

if VERSION <= v"0.7.0-beta2.195"
    __prevpow2(x) = prevpow2(x)
    __nextpow2(x) = nextpow2(x)
else
    __prevpow2(x) = prevpow(2, x)
    __nextpow2(x) = nextpow(2, x)
end


for T in INTS
    x = T[1, 2, 3, 4, 10, 100, 1024, 10000, 2^30, 2^30-1]
    if T == BigInt
        push!(x, big(2)^3000, big(2)^3000-1)
    end
    y = similar(x)
    tol = in(T, BIGNUMS) ? 0.40 : 0.25
    tstr = string(T)
    for funpow2 = (__prevpow2, __nextpow2), sgn = (+,)
        g[string(funpow2), tstr, string(sgn)] = @benchmarkable map!($funpow2, $y, $(sgn(x))) time_tolerance=tol
    end
end

end # module
