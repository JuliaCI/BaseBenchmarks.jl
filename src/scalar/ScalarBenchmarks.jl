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


function perf_13786(k::Float64,τ::Float64,twopiN::Float64)
    W = getW(k,twopiN)
    y = 1.00-k*τ
    sqy = y>0.0 ? sqrt(y) : 0.0
    tof::Float64 = sqy * (W*y + τ)
    return tof
end

function getW(k::Float64,twopiN::Float64)
    local sqrt2l= sqrt(2.0)
    local K2c0  = 0.7542472332656508
    local K2c1 = -0.2
    local K2c2 = 0.08081220356417687
    local K2c3 = -0.031746031746031744
    local K2c4  = 0.012244273267299524
    local K2c5 = -2.0/429.0
    local K2c6 = 8.0 * sqrt(2.0)/6435.0
    local K2c7 = -8.0/12155.0
    local K2c8 = 8.0*sqrt(2.0)/46189.0
    local k00 =0.3535533905932738
    local k02  =3.00*k00*0.25
    local k03  =-2.00/3.0
    local k04  =15.0*sqrt(2.0)/128.0
    local k05  =-2.0/5.0
    local k06  =35.0*sqrt(2.0)/512.0
    local k07  =-8/35.0
    local k08  =315.0*sqrt(2.0)/8192.0
    local twopi = 2.0*π

    W = 0.0

    @fastmath begin
        if k<=-0.02
            t2 = (k*k)
            t3 = acos(t2 - 1.0)
            t4 = 2.0 - t2
            t6 = twopi - t3   + twopiN
            t5 = 1.0/t4
            W  = (t6 * sqrt(t5) - k)*t5
        elseif (k>=0.02) & (k < (sqrt2l-0.02+twopiN))
            t2 = (k*k)
            t3 = acos(t2 - 1.00)
            t4 = 2.00 - t2
            t6 = (t3  + twopiN)
            t5 = 1.00/t4
            W  = (t6 * sqrt(t5) - k)*t5
        elseif k<0.02 # then!series to k ~= 0 improve convergence
            xt = twopiN+π
            t2 = k*k
            t3 = t2*k
            t4 = t2*t2
            t5 = t4*k
            t6 = t3*t3
            t7 = t5*t2
            t8 = t4*t4
            W  = xt*k00 - k + (xt*k02)*t2 + k03*t3 + (xt*k04)*t4 + k05*t5 + (xt*k06)*t6  + k07*t7 + (xt*k08)*t8
        elseif (k> (sqrt2l-0.02) && k< (sqrt2l+0.02))
            xt = k-sqrt2l
            t2 = xt*xt
            t3 = t2*xt
            t4 = t3*xt
            t5 = t4*xt
            t6 = t5*xt
            t7 = t6*xt
            t8 = t7*xt
            W  = K2c0 + K2c1*k + K2c2*t2 + K2c3*t3 + K2c4*t4 + K2c5*t5 + K2c6*t6 + K2c7*t7 + K2c8*t8
        elseif k >= (sqrt2l+0.02)
            t7 = (k+1.0) * (k-1.00)
            t3 = log(t7 + sqrt(t7*t7-1.0))
            t4 = t7-1.0
            t5 = 1.0/t4
            W  = (-t3 * sqrt(t5) + k)*t5
        end
    end

    return W
end

fstmth["13786"] = @benchmarkable perf_13786(0.4, 0.5, 0.0)

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
