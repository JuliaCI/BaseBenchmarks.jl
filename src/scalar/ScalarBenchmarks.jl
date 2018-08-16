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

#######
# exp #
#######

g = addgroup!(SUITE, "floatexp")

g["ldexp", "norm -> norm",       "Float64"] = @benchmarkable ldexp($(1.7), $(10))
g["ldexp", "norm -> norm",       "Float32"] = @benchmarkable ldexp($(1.7f0), $(10))
g["ldexp", "norm -> subnorm",    "Float64"] = @benchmarkable ldexp($(1.7), $(-1028))
g["ldexp", "norm -> subnorm",    "Float32"] = @benchmarkable ldexp($(1.7f0), $(-128))
g["ldexp", "norm -> inf",        "Float64"] = @benchmarkable ldexp($(1.7), $(1028))
g["ldexp", "norm -> inf",        "Float32"] = @benchmarkable ldexp($(1.7f0), $(128))
g["ldexp", "subnorm -> norm",    "Float64"] = @benchmarkable ldexp($(1.7e-310), $(100))
g["ldexp", "subnorm -> norm",    "Float32"] = @benchmarkable ldexp($(1.7f-40), $(100))
g["ldexp", "subnorm -> subnorm", "Float64"] = @benchmarkable ldexp($(1.7e-310), $(-3))
g["ldexp", "subnorm -> subnorm", "Float32"] = @benchmarkable ldexp($(1.7f-40), $(-3))
g["ldexp", "inf -> inf",         "Float64"] = @benchmarkable ldexp($(Inf), $(10))
g["ldexp", "inf -> inf",         "Float32"] = @benchmarkable ldexp($(Inf32), $(10))

g["frexp", "norm",    "Float64"] = @benchmarkable frexp($(1.7))
g["frexp", "norm",    "Float32"] = @benchmarkable frexp($(1.7f0))
g["frexp", "subnorm", "Float64"] = @benchmarkable frexp($(1.7e-310))
g["frexp", "subnorm", "Float32"] = @benchmarkable frexp($(1.7f-40))
g["frexp", "inf",     "Float64"] = @benchmarkable frexp($(Inf))
g["frexp", "inf",     "Float32"] = @benchmarkable frexp($(Inf32))

g["exponent", "norm",    "Float64"] = @benchmarkable exponent($(1.7))
g["exponent", "norm",    "Float32"] = @benchmarkable exponent($(1.7f0))
g["exponent", "subnorm", "Float64"] = @benchmarkable exponent($(1.7e-310))
g["exponent", "subnorm", "Float32"] = @benchmarkable exponent($(1.7f-40))

g["significand", "norm",    "Float64"] = @benchmarkable significand($(1.7))
g["significand", "norm",    "Float32"] = @benchmarkable significand($(1.7f0))
g["significand", "subnorm", "Float64"] = @benchmarkable significand($(1.7e-310))
g["significand", "subnorm", "Float32"] = @benchmarkable significand($(1.7f-40))

g["exp", "normal path, k = 2",              "Float64"] = @benchmarkable exp($(1.5))
g["exp", "fast path, k = 1",                "Float64"] = @benchmarkable exp($(0.5))
g["exp", "no agument reduction, k = 9",     "Float64"] = @benchmarkable exp($(0.1))
g["exp", "small argument path",             "Float64"] = @benchmarkable exp($(2.0^-30))
g["exp", "normal path -> small, k = -1045", "Float64"] = @benchmarkable exp($(-724.0))
g["exp", "overflow",                        "Float64"] = @benchmarkable exp($(900.0))
g["exp", "underflow",                       "Float64"] = @benchmarkable exp($(-900.0))

g["exp", "normal path, k = 2",              "Float32"] = @benchmarkable exp($(1f5))
g["exp", "fast path, k = 1",                "Float32"] = @benchmarkable exp($(0f5))
g["exp", "no agument reduction, k = 9",     "Float32"] = @benchmarkable exp($(0f1))
g["exp", "small argument path",             "Float32"] = @benchmarkable exp($(2f0^-15))
g["exp", "normal path -> small, k = -1045", "Float32"] = @benchmarkable exp($(-724f0))
g["exp", "overflow",                        "Float32"] = @benchmarkable exp($(150f0))
g["exp", "underflow",                       "Float32"] = @benchmarkable exp($(-150f0))

g["exp10", "no agument reduction, k = 1",     "Float64"] = @benchmarkable exp10($(0.25))
g["exp10", "direct approx, k = 0",            "Float64"] = @benchmarkable exp10($(0.01))
g["exp10", "taylor expansion",                "Float32"] = @benchmarkable exp10($(2f0^-35))
g["exp10", "agument reduction, k = 2",        "Float64"] = @benchmarkable exp10($(0.5))
g["exp10", "agument reduction, k = 83",       "Float64"] = @benchmarkable exp10($(25.0))
g["exp10", "normal path -> small, k = -1075", "Float64"] = @benchmarkable exp10($(-323.6))
g["exp10", "overflow",                        "Float64"] = @benchmarkable exp10($(400.0))
g["exp10", "underflow",                       "Float64"] = @benchmarkable exp10($(-400.0))

g["exp10", "no agument reduction, k = 1",    "Float32"] = @benchmarkable exp10($(0.25f0))
g["exp10", "direct approx, k = 0",           "Float32"] = @benchmarkable exp10($(0.01f0))
g["exp10", "taylor expansion",               "Float32"] = @benchmarkable exp10($(2f0^-25))
g["exp10", "agument reduction, k = 2",       "Float32"] = @benchmarkable exp10($(0.5f0))
g["exp10", "agument reduction, k = 83",      "Float32"] = @benchmarkable exp10($(25.0f0))
g["exp10", "normal path -> small, k = -150", "Float32"] = @benchmarkable exp10($(-45.5f0))
g["exp10", "overflow",                       "Float32"] = @benchmarkable exp10($(100f0))
g["exp10", "underflow",                      "Float32"] = @benchmarkable exp10($(-100f0))

for b in values(g)
    b.params.time_tolerance = 0.40
end

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

##########
# mod2pi #
##########
g = addgroup!(SUITE, "mod2pi")

# -π/4 <= x <= π/4
g["no reduction", "zero", "Float64"] = @benchmarkable mod2pi($(0.0))
g["no reduction", "positive argument", "Float64"] = @benchmarkable mod2pi($(pi/6))
g["no reduction", "negative argument", "Float64"] = @benchmarkable mod2pi($(-pi/6))
# -2π/4 <= x <= 2π/4
g["no reduction", "positive argument", "Float64"] = @benchmarkable mod2pi($(2*pi/4-0.1))
g["no reduction", "negative argument", "Float64"] = @benchmarkable mod2pi($(-2*pi/4+0.1))
g["no reduction", "positive argument", "Float64"] = @benchmarkable mod2pi($(2*pi/4))
g["no reduction", "negative argument", "Float64"] = @benchmarkable mod2pi($(-2*pi/4))
# -3π/4 <= x <= 3π/4
g["no reduction", "positive argument", "Float64"] = @benchmarkable mod2pi($(3*pi/4-0.1))
g["no reduction", "negative argument", "Float64"] = @benchmarkable mod2pi($(-3*pi/4+0.1))
# -4π/4 <= x <= 4π/4
g["no reduction", "positive argument", "Float64"] = @benchmarkable mod2pi($(pi-0.1))
g["no reduction", "negative argument", "Float64"] = @benchmarkable mod2pi($(-pi+0.1))
g["no reduction", "positive argument", "Float64"] = @benchmarkable mod2pi($(Float64(pi)))
g["no reduction", "negative argument", "Float64"] = @benchmarkable mod2pi($(Float64(-pi)))
# -5π/4 <= x <= 5π/4
g["argument reduction (easy) abs(x) < 5π/4", "positive argument", "Float64"] = @benchmarkable mod2pi($(5*pi/4-0.1))
g["argument reduction (easy) abs(x) < 5π/4", "negative argument", "Float64"] = @benchmarkable mod2pi($(-5*pi/4+0.1))
# -6π/4 <= x <= 6π/4
g["argument reduction (easy) abs(x) < 6π/4", "positive argument", "Float64"] = @benchmarkable mod2pi($(6*pi/4-0.1))
g["argument reduction (easy) abs(x) < 6π/4", "negative argument", "Float64"] = @benchmarkable mod2pi($(-6*pi/4+0.1))
g["argument reduction (hard) abs(x) < 6π/4", "positive argument", "Float64"] = @benchmarkable mod2pi($(6*pi/4))
g["argument reduction (hard) abs(x) < 6π/4", "negative argument", "Float64"] = @benchmarkable mod2pi($(-6*pi/4))
# -7π/4 <= x <= 7π/4
g["argument reduction (easy) abs(x) < 7π/4", "positive argument", "Float64"] = @benchmarkable mod2pi($(7*pi/4-0.1))
g["argument reduction (easy) abs(x) < 7π/4", "negative argument", "Float64"] = @benchmarkable mod2pi($(-7*pi/4+0.1))
# -8π/4 <= x <= 8π/4
g["argument reduction (easy) abs(x) < 8π/4", "positive argument", "Float64"] = @benchmarkable mod2pi($(2*pi-0.1))
g["argument reduction (easy) abs(x) < 8π/4", "negative argument", "Float64"] = @benchmarkable mod2pi($(-2*pi+0.1))
g["argument reduction (hard) abs(x) < 8π/4", "positive argument", "Float64"] = @benchmarkable mod2pi($(2*pi))
g["argument reduction (hard) abs(x) < 8π/4", "negative argument", "Float64"] = @benchmarkable mod2pi($(-2*pi))
# -9π/4 <= x <= 9π/4
g["argument reduction (easy) abs(x) < 9π/4", "positive argument", "Float64"] = @benchmarkable mod2pi($(9*pi/4-0.1))
g["argument reduction (easy) abs(x) < 9π/4", "negative argument", "Float64"] = @benchmarkable mod2pi($(-9*pi/4+0.1))
# -2.0^20π/2 <= x <= 2.0^20π/2
g["argument reduction (easy) abs(x) < 2.0^20π/4", "positive argument", "Float64"] = @benchmarkable mod2pi($(2.0^10*pi/4-0.1))
g["argument reduction (easy) abs(x) < 2.0^20π/4", "negative argument", "Float64"] = @benchmarkable mod2pi($(-2.0^10*pi/4+0.1))
# abs(x) >= 2.0^20π/2
# idx < 0
g["argument reduction (easy) abs(x) > 2.0^20*π/2", "positive argument", "Float64"] = @benchmarkable mod2pi($(2.0^30*pi/4-0.1))
g["argument reduction (easy) abs(x) > 2.0^20*π/2", "negative argument", "Float64"] = @benchmarkable mod2pi($(-2.0^30*pi/4+0.1))
# idx > 0
g["argument reduction (easy) abs(x) > 2.0^20*π/2", "positive argument", "Float64"] = @benchmarkable mod2pi($(2.0^80*pi/4-1.2))
g["argument reduction (easy) abs(x) > 2.0^20*π/2", "negative argument", "Float64"] = @benchmarkable mod2pi($(-2.0^80*pi/4+1.2))

# trig benchmarks

# The benchmark groups below benchmark trig functions in Base. Numeri-
# cal evaluation of trig functions consists of two steps: argument re-
# duction followed by evaluation of a polynomial on the reduced argu-
# ment. Below, "no reduction" means that the kernel functions are cal-
# led directly, "argument reduction (easy)" means that we are using
# the two coefficient Cody-Waite method, "argument reduction (hard)"
# means that we are using a more precise but more expensive Cody-Waite
# scheme, and "argument reduction (paynehanek)" means that we are us-
# ing the expensive Payne-Hanek scheme for large values. "(hard)"
# values are either around integer multiples of pi/2 or for the medium
# size arguments 9pi/4 <= |x| <= 2.0^20π/2. (paynehanek) vales are for
# |x| >= 2.0^20π/2. The tags "sin_kernel" and "cos_kernel" refer to
# the actual polynomial being used. "z_kernel" evaluates a polynomial
# that approximates z∈{sin, cos} on the interval of x's such that
# |x| <= pi/4.

#######
# sin #
#######
arg_string(::Type{Float32}) = "Float32"
arg_string(::Type{Float64}) = "Float64"
g = addgroup!(SUITE, "sin")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    # -π/4 <= x <= π/4
    g["no reduction", "zero", _arg_string] = @benchmarkable sin($(T(0.0)))
    g["no reduction", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(T(pi)/6))
    g["no reduction", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(-T(pi)/6))
    # -2π/4 <= x <= 2π/4
    g["argument reduction (easy) abs(x) < 2π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable sin($(2*T(pi)/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 2π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable sin($(-2*T(pi)/4+T(0.1)))
    g["argument reduction (hard) abs(x) < 2π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable sin($(2*T(pi)/4))
    g["argument reduction (hard) abs(x) < 2π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable sin($(-2*T(pi)/4))
    # -3π/4 <= x <= 3π/4
    g["argument reduction (easy) abs(x) < 3π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable sin($(3*T(pi)/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 3π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable sin($(-3*T(pi)/4+T(0.1)))
    # -4π/4 <= x <= 4π/4
    g["argument reduction (easy) abs(x) < 4π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(T(pi)-T(0.1)))
    g["argument reduction (easy) abs(x) < 4π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(-T(pi)+T(0.1)))
    g["argument reduction (hard) abs(x) < 4π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(T(pi)))
    g["argument reduction (hard) abs(x) < 4π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(-T(pi)))
    # -5π/4 <= x <= 5π/4
    g["argument reduction (easy) abs(x) < 5π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(5*T(pi)/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 5π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(-5*T(pi)/4+T(0.1)))
    # -6π/4 <= x <= 6π/4
    g["argument reduction (easy) abs(x) < 6π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable sin($(6*T(pi)/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 6π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable sin($(-6*T(pi)/4+T(0.1)))
    g["argument reduction (hard) abs(x) < 6π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable sin($(6*T(pi)/4))
    g["argument reduction (hard) abs(x) < 6π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable sin($(-6*T(pi)/4))
    # -7π/4 <= x <= 7π/4
    g["argument reduction (easy) abs(x) < 7π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(7*T(pi)/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 7π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(-7*T(pi)/4+T(0.1)))
    # -8π/4 <= x <= 8π/4
    g["argument reduction (easy) abs(x) < 8π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(2*T(pi)-T(0.1)))
    g["argument reduction (easy) abs(x) < 8π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(-2*T(pi)+T(0.1)))
    g["argument reduction (hard) abs(x) < 8π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(2*T(pi)))
    g["argument reduction (hard) abs(x) < 8π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(-2*T(pi)))
    # -9π/4 <= x <= 9π/4
    g["argument reduction (easy) abs(x) < 9π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(9*T(pi)/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 9π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(-9*T(pi)/4+T(0.1)))
    # -2.0^20π/2 <= x <= 2.0^20π/2
    g["argument reduction (easy) abs(x) < 2.0^20π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(T(2.0)^10*T(pi)/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 2.0^20π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(-T(2.0)^10*T(pi)/4+T(0.1)))
    # abs(x) >= 2.0^20π/2
    # idx < 0
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(T(2.0)^30*T(pi)/4-T(0.1)))
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable sin($(-T(2.0)^30*T(pi)/4+T(0.1)))
    # idx > 0
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable sin($(T(2.0)^80*T(pi)/4-1.2))
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable sin($(-T(2.0)^80*T(pi)/4+1.2))
end

#######
# cos #
#######

g = addgroup!(SUITE, "cos")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    # -π/4 <= x <= π/4
    g["no reduction", "zero", _arg_string] = @benchmarkable cos($(0.0))
    g["no reduction", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(pi/6))
    g["no reduction", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(-pi/6))
    # -2π/4 <= x <= 2π/4
    g["argument reduction (easy) abs(x) < 2π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable cos($(2*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 2π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable cos($(-2*pi/4+T(0.1)))
    g["argument reduction (hard) abs(x) < 2π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable cos($(2*pi/4))
    g["argument reduction (hard) abs(x) < 2π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable cos($(-2*pi/4))
    # -3π/4 <= x <= 3π/4
    g["argument reduction (easy) abs(x) < 3π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable cos($(3*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 3π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable cos($(-3*pi/4+T(0.1)))
    # -4π/4 <= x <= 4π/4
    g["argument reduction (easy) abs(x) < 4π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(pi-T(0.1)))
    g["argument reduction (easy) abs(x) < 4π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(-pi+T(0.1)))
    g["argument reduction (hard) abs(x) < 4π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(T(pi)))
    g["argument reduction (hard) abs(x) < 4π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(T(-pi)))
    # -5π/4 <= x <= 5π/4
    g["argument reduction (easy) abs(x) < 5π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(5*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 5π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(-5*pi/4+T(0.1)))
    # -6π/4 <= x <= 6π/4
    g["argument reduction (easy) abs(x) < 6π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable cos($(6*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 6π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable cos($(-6*pi/4+T(0.1)))
    g["argument reduction (hard) abs(x) < 6π/4", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable cos($(6*pi/4))
    g["argument reduction (hard) abs(x) < 6π/4", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable cos($(-6*pi/4))
    # -7π/4 <= x <= 7π/4
    g["argument reduction (easy) abs(x) < 7π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(7*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 7π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(-7*pi/4+T(0.1)))
    # -8π/4 <= x <= 8π/4
    g["argument reduction (easy) abs(x) < 8π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(2*pi-T(0.1)))
    g["argument reduction (easy) abs(x) < 8π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(-2*pi+T(0.1)))
    g["argument reduction (hard) abs(x) < 8π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(2*pi))
    g["argument reduction (hard) abs(x) < 8π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(-2*pi))
    # -9π/4 <= x <= 9π/4
    g["argument reduction (easy) abs(x) < 9π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(9*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 9π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(-9*pi/4+T(0.1)))
    # -2.0^20π/2 <= x <= 2.0^20π/2
    g["argument reduction (easy) abs(x) < 2.0^20π/4", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(T(2.0)^10*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 2.0^20π/4", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(-T(2.0)^10*pi/4+T(0.1)))
    # abs(x) >= 2.0^20π/2
    # idx < 0
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "positive argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(T(2.0)^30*pi/4-T(0.1)))
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "negative argument", _arg_string, "cos_kernel"] = @benchmarkable cos($(-T(2.0)^30*pi/4+T(0.1)))
    # idx > 0
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "positive argument", _arg_string, "sin_kernel"] = @benchmarkable cos($(T(2.0)^80*pi/4-1.2))
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "negative argument", _arg_string, "sin_kernel"] = @benchmarkable cos($(-T(2.0)^80*pi/4+1.2))
end

##########
# sincos #
##########
if VERSION >= v"0.7.0-DEV.337"
g = addgroup!(SUITE, "sincos")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    # -π/4 <= x <= π/4
    g["no reduction", "zero", _arg_string] = @benchmarkable sincos($(0.0))
    g["no reduction", "positive argument", _arg_string] = @benchmarkable sincos($(pi/6))
    g["no reduction", "negative argument", _arg_string] = @benchmarkable sincos($(-pi/6))
    # -2π/4 <= x <= 2π/4
    g["argument reduction (easy) abs(x) < 2π/4", "positive argument", _arg_string] = @benchmarkable sincos($(2*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 2π/4", "negative argument", _arg_string] = @benchmarkable sincos($(-2*pi/4+T(0.1)))
    g["argument reduction (hard) abs(x) < 2π/4", "positive argument", _arg_string] = @benchmarkable sincos($(2*pi/4))
    g["argument reduction (hard) abs(x) < 2π/4", "negative argument", _arg_string] = @benchmarkable sincos($(-2*pi/4))
    # -3π/4 <= x <= 3π/4
    g["argument reduction (easy) abs(x) < 3π/4", "positive argument", _arg_string] = @benchmarkable sincos($(3*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 3π/4", "negative argument", _arg_string] = @benchmarkable sincos($(-3*pi/4+T(0.1)))
    # -4π/4 <= x <= 4π/4
    g["argument reduction (easy) abs(x) < 4π/4", "positive argument", _arg_string] = @benchmarkable sincos($(pi-T(0.1)))
    g["argument reduction (easy) abs(x) < 4π/4", "negative argument", _arg_string] = @benchmarkable sincos($(-pi+T(0.1)))
    g["argument reduction (hard) abs(x) < 4π/4", "positive argument", _arg_string] = @benchmarkable sincos($(T(pi)))
    g["argument reduction (hard) abs(x) < 4π/4", "negative argument", _arg_string] = @benchmarkable sincos($(T(-pi)))
    # -5π/4 <= x <= 5π/4
    g["argument reduction (easy) abs(x) < 5π/4", "positive argument", _arg_string] = @benchmarkable sincos($(5*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 5π/4", "negative argument", _arg_string] = @benchmarkable sincos($(-5*pi/4+T(0.1)))
    # -6π/4 <= x <= 6π/4
    g["argument reduction (easy) abs(x) < 6π/4", "positive argument", _arg_string] = @benchmarkable sincos($(6*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 6π/4", "negative argument", _arg_string] = @benchmarkable sincos($(-6*pi/4+T(0.1)))
    g["argument reduction (hard) abs(x) < 6π/4", "positive argument", _arg_string] = @benchmarkable sincos($(6*pi/4))
    g["argument reduction (hard) abs(x) < 6π/4", "negative argument", _arg_string] = @benchmarkable sincos($(-6*pi/4))
    # -7π/4 <= x <= 7π/4
    g["argument reduction (easy) abs(x) < 7π/4", "positive argument", _arg_string] = @benchmarkable sincos($(7*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 7π/4", "negative argument", _arg_string] = @benchmarkable sincos($(-7*pi/4+T(0.1)))
    # -8π/4 <= x <= 8π/4
    g["argument reduction (easy) abs(x) < 8π/4", "positive argument", _arg_string] = @benchmarkable sincos($(2*pi-T(0.1)))
    g["argument reduction (easy) abs(x) < 8π/4", "negative argument", _arg_string] = @benchmarkable sincos($(-2*pi+T(0.1)))
    g["argument reduction (hard) abs(x) < 8π/4", "positive argument", _arg_string] = @benchmarkable sincos($(2*pi))
    g["argument reduction (hard) abs(x) < 8π/4", "negative argument", _arg_string] = @benchmarkable sincos($(-2*pi))
    # -9π/4 <= x <= 9π/4
    g["argument reduction (easy) abs(x) < 9π/4", "positive argument", _arg_string] = @benchmarkable sincos($(9*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 9π/4", "negative argument", _arg_string] = @benchmarkable sincos($(-9*pi/4+T(0.1)))
    # -2.0^20π/2 <= x <= 2.0^20π/2
    g["argument reduction (easy) abs(x) < 2.0^20π/4", "positive argument", _arg_string] = @benchmarkable sincos($(T(2.0)^10*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 2.0^20π/4", "negative argument", _arg_string] = @benchmarkable sincos($(-T(2.0)^10*pi/4+T(0.1)))
    # abs(x) >= 2.0^20π/2
    # idx < 0
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "positive argument", _arg_string] = @benchmarkable sincos($(T(2.0)^30*pi/4-T(0.1)))
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "negative argument", _arg_string] = @benchmarkable sincos($(-T(2.0)^30*pi/4+T(0.1)))
    # idx > 0
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "positive argument", _arg_string] = @benchmarkable sincos($(T(2.0)^80*pi/4-1.2))
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "negative argument", _arg_string] = @benchmarkable sincos($(-T(2.0)^80*pi/4+1.2))
end
end

########
# tan #
########

g = addgroup!(SUITE, "tan")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["zero", _arg_string] = @benchmarkable tan($(zero(T)))
    g["very small", "positive argument", _arg_string] = @benchmarkable tan($(nextfloat(zero(T))))
    g["very small", "negative argument", _arg_string] = @benchmarkable tan($(prevfloat(zero(T))))
    g["small", "positive argument", _arg_string] = @benchmarkable tan($(prevfloat(sqrt(eps(T))/2)))
    g["small", "negative argument", _arg_string] = @benchmarkable tan($(nextfloat(-sqrt(eps(T))/2)))
    g["medium", "positive argument", _arg_string] = @benchmarkable tan($T(0.6743))
    g["medium", "negative argument", _arg_string] = @benchmarkable tan($T(-0.6743))
    g["large", "positive argument", _arg_string] = @benchmarkable tan($T(0.6745))
    g["large", "negative argument", _arg_string] = @benchmarkable tan($T(-0.6745))
    g["large", "positive argument", _arg_string] = @benchmarkable tan($T(2.5))
    g["large", "negative argument", _arg_string] = @benchmarkable tan($T(-2.5))
end

############
# rem_pio2 #
############

g = addgroup!(SUITE, "rem_pio2")
const _rem = try
    hasmethod(Base.Math.ieee754_rem_pio2, Tuple{Float64})
    Base.Math.ieee754_rem_pio2
catch
    Base.Math.rem_pio2_kernel
end

for T in (Float64, )# (Float32, Float64) add Float32 later
    _arg_string = arg_string(T)
    # -2π/4 <= x <= 2π/4
    g["argument reduction (easy) abs(x) < 2π/4", "positive argument", _arg_string] = @benchmarkable _rem($(2*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 2π/4", "negative argument", _arg_string] = @benchmarkable _rem($(-2*pi/4+T(0.1)))
    g["argument reduction (hard) abs(x) < 2π/4", "positive argument", _arg_string] = @benchmarkable _rem($(2*pi/4))
    g["argument reduction (hard) abs(x) < 2π/4", "negative argument", _arg_string] = @benchmarkable _rem($(-2*pi/4))
    # -3π/4 <= x <= 3π/4
    g["argument reduction (easy) abs(x) < 3π/4", "positive argument", _arg_string] = @benchmarkable _rem($(3*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 3π/4", "negative argument", _arg_string] = @benchmarkable _rem($(-3*pi/4+T(0.1)))
    # -4π/4 <= x <= 4π/4
    g["argument reduction (easy) abs(x) < 4π/4", "positive argument", _arg_string] = @benchmarkable _rem($(pi-T(0.1)))
    g["argument reduction (easy) abs(x) < 4π/4", "negative argument", _arg_string] = @benchmarkable _rem($(-pi+T(0.1)))
    g["argument reduction (hard) abs(x) < 4π/4", "positive argument", _arg_string] = @benchmarkable _rem($(Float64(pi)))
    g["argument reduction (hard) abs(x) < 4π/4", "negative argument", _arg_string] = @benchmarkable _rem($(Float64(-pi)))
    # -5π/4 <= x <= 5π/4
    g["argument reduction (easy) abs(x) < 5π/4", "positive argument", _arg_string] = @benchmarkable _rem($(5*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 5π/4", "negative argument", _arg_string] = @benchmarkable _rem($(-5*pi/4+T(0.1)))
    # -6π/4 <= x <= 6π/4
    g["argument reduction (easy) abs(x) < 6π/4", "positive argument", _arg_string] = @benchmarkable _rem($(6*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 6π/4", "negative argument", _arg_string] = @benchmarkable _rem($(-6*pi/4+T(0.1)))
    g["argument reduction (hard) abs(x) < 6π/4", "positive argument", _arg_string] = @benchmarkable _rem($(6*pi/4))
    g["argument reduction (hard) abs(x) < 6π/4", "negative argument", _arg_string] = @benchmarkable _rem($(-6*pi/4))
    # -7π/4 <= x <= 7π/4
    g["argument reduction (easy) abs(x) < 7π/4", "positive argument", _arg_string] = @benchmarkable _rem($(7*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 7π/4", "negative argument", _arg_string] = @benchmarkable _rem($(-7*pi/4+T(0.1)))
    # -8π/4 <= x <= 8π/4
    g["argument reduction (easy) abs(x) < 8π/4", "positive argument", _arg_string] = @benchmarkable _rem($(2*pi-T(0.1)))
    g["argument reduction (easy) abs(x) < 8π/4", "negative argument", _arg_string] = @benchmarkable _rem($(-2*pi+T(0.1)))
    g["argument reduction (hard) abs(x) < 8π/4", "positive argument", _arg_string] = @benchmarkable _rem($(2*pi))
    g["argument reduction (hard) abs(x) < 8π/4", "negative argument", _arg_string] = @benchmarkable _rem($(-2*pi))
    # -9π/4 <= x <= 9π/4
    g["argument reduction (easy) abs(x) < 9π/4", "positive argument", _arg_string] = @benchmarkable _rem($(9*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 9π/4", "negative argument", _arg_string] = @benchmarkable _rem($(-9*pi/4+T(0.1)))
    # -2.0^20π/2 <= x <= 2.0^20π/2
    g["argument reduction (easy) abs(x) < 2.0^20π/4", "positive argument", _arg_string] = @benchmarkable _rem($(T(2.0)^10*pi/4-T(0.1)))
    g["argument reduction (easy) abs(x) < 2.0^20π/4", "negative argument", _arg_string] = @benchmarkable _rem($(-T(2.0)^10*pi/4+T(0.1)))
    # abs(x) >= 2.0^20π/2
    # idx < 0
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "positive argument", _arg_string] = @benchmarkable _rem($(T(2.0)^30*pi/4-T(0.1)))
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "negative argument", _arg_string] = @benchmarkable _rem($(-T(2.0)^30*pi/4+T(0.1)))
    # idx > 0
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "positive argument", _arg_string] = @benchmarkable _rem($(T(2.0)^80*pi/4-1.2))
    g["argument reduction (paynehanek) abs(x) > 2.0^20*π/2", "negative argument", _arg_string] = @benchmarkable _rem($(-T(2.0)^80*pi/4+1.2))
end

########
# asin #
########

g = addgroup!(SUITE, "asin")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["zero", _arg_string] = @benchmarkable asin($(zero(T)))
    g["small", "positive argument", _arg_string] = @benchmarkable asin($(nextfloat(zero(T))))
    g["small", "negative argument", _arg_string] = @benchmarkable asin($(prevfloat(zero(T))))
    g["one", "positive argument", _arg_string] = @benchmarkable asin($(one(T)))
    g["one", "negative argument", _arg_string] = @benchmarkable asin($(-one(T)))
    g["abs(x) < 0.5", "positive argument", _arg_string] = @benchmarkable asin($(T(0.45)))
    g["abs(x) < 0.5", "negative argument", _arg_string] = @benchmarkable asin($(T(-0.45)))
    g["0.5 <= abs(x) < 0.975", "positive argument", _arg_string] = @benchmarkable asin($(T(0.6)))
    g["0.5 <= abs(x) < 0.975", "negative argument", _arg_string] = @benchmarkable asin($T(-0.6))
    if T == Float64
        g["0.975 <= abs(x) < 1.0", "positive argument", _arg_string] = @benchmarkable asin($(0.98))
        g["0.975 <= abs(x) < 1.0", "negative argument", _arg_string] = @benchmarkable asin($(-0.98))
    end
end

########
# acos #
########

g = addgroup!(SUITE, "acos")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["zero", _arg_string] = @benchmarkable acos($(zero(T)))
    g["small", "positive argument", _arg_string] = @benchmarkable acos($(nextfloat(zero(T))))
    g["small", "negative argument", _arg_string] = @benchmarkable acos($(prevfloat(zero(T))))
    g["one", "positive argument", _arg_string] = @benchmarkable acos($(one(T)))
    g["one", "negative argument", _arg_string] = @benchmarkable acos($(-one(T)))
    g["abs(x) < 0.5", "positive argument", _arg_string] = @benchmarkable acos($(T(0.45)))
    g["abs(x) < 0.5", "negative argument", _arg_string] = @benchmarkable acos($(T(-0.45)))
    g["0.5 <= abs(x) < 1", "positive argument", _arg_string] = @benchmarkable acos($(T(0.6)))
    g["0.5 <= abs(x) < 1", "negative argument", _arg_string] = @benchmarkable acos($T(-0.6))
end

########
# atan #
########

# Before calculating atan(x) a range reduction is performed. The various inter-
# vals below are chosen such that all branches of the reduction and evaluation
# phases are reached and benchmarked.

g = addgroup!(SUITE, "atan")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["zero", _arg_string] = @benchmarkable atan($(zero(T)))
    g["very small", "positive argument", _arg_string] = @benchmarkable atan($(nextfloat(zero(T))))
    g["very small", "negative argument", _arg_string] = @benchmarkable atan($(prevfloat(zero(T))))
    g["very large", "positive argument", _arg_string] = @benchmarkable atan($(T(2.0)^67))
    g["very large", "negative argument", _arg_string] = @benchmarkable atan($(-T(2.0)^67))
    g["0 <= abs(x) < 7/16", "positive argument", _arg_string] = @benchmarkable atan($(T(6/16)))
    g["0 <= abs(x) < 7/16", "negative argument", _arg_string] = @benchmarkable atan($(-T(6/16)))
    g["7/16 <= abs(x) < 11/16", "positive argument", _arg_string] = @benchmarkable atan($(T(10/16)))
    g["7/16 <= abs(x) < 11/16", "negative argument", _arg_string] = @benchmarkable atan($(-T(10/16)))
    g["11/16 <= abs(x) < 19/16", "positive argument", _arg_string] = @benchmarkable atan($(T(18/16)))
    g["11/16 <= abs(x) < 19/16", "negative argument", _arg_string] = @benchmarkable atan($(-T(18/16)))
    g["19/16 <= abs(x) < 39/16", "positive argument", _arg_string] = @benchmarkable atan($(T(38/16)))
    g["19/16 <= abs(x) < 39/16", "negative argument", _arg_string] = @benchmarkable atan($(-T(38/16)))
    g["39/16 <= abs(x) < 2^66", "positive argument", _arg_string] = @benchmarkable atan($(T(50/16)))
    g["39/16 <= abs(x) < 2^66", "negative argument", _arg_string] = @benchmarkable atan($(-T(50/16)))
end

#########
# atan2 #
#########

g = addgroup!(SUITE, "atan2")
if VERSION < v"0.7.0-alpha.44"
    Base.atan(x, y) = atan2(x,y)
end   
for T in (Float32, Float64)
    # when referring to y and x we refer to y and x in atan(y, x)
    _arg_string = arg_string(T)
    r = T(randn())
    absr = abs(r)
    # x is one
    g["x one", _arg_string] = @benchmarkable atan($(T(r)), $(one(T)))
    # y zero
    g["y zero", "y positive", "x positive", _arg_string] = @benchmarkable atan($(T(r)), $(one(T)))
    g["y zero", "y positive", "x positive", _arg_string] = @benchmarkable atan($(zero(T)), $absr)
    g["y zero", "y negative", "x positive", _arg_string] = @benchmarkable atan($(-zero(T)), $absr)
    g["y zero", "y positive", "x negative", _arg_string] = @benchmarkable atan($(zero(T)), $(-absr))
    g["y zero", "y negative", "x negative", _arg_string] = @benchmarkable atan($(-zero(T)), $(-absr))
    # x zero and y not zero
    g["x zero", "y positive", _arg_string] = @benchmarkable atan($(one(T)), $(zero(T)))
    g["x zero", "y negative", _arg_string] = @benchmarkable atan($(-one(T)), $(zero(T)))
    # isinf(x) == true && isinf(y) == true
    g["y infinite", "y positive", "x infinite", "x positive", _arg_string] = @benchmarkable atan($(T(Inf)), $(T(Inf)))
    g["y infinite", "y negative", "x infinite", "x positive", _arg_string] = @benchmarkable atan($(-T(Inf)), $(T(Inf)))
    g["y infinite", "y positive", "x infinite", "x negative", _arg_string] = @benchmarkable atan($(T(Inf)), $(-T(Inf)))
    g["y infinite", "y negative", "x infinite", "x negative", _arg_string] = @benchmarkable atan($(-T(Inf)), $(-T(Inf)))
    # isinf(x) == true && isinf(y) == false
    # m in 0 through 3 are different cases explained in the atan code
    g["y finite", "y positive", "x infinite", "x positive", _arg_string] = @benchmarkable atan($(absr), $(T(Inf))) # m == 0
    g["y finite", "y negative", "x infinite", "x positive", _arg_string] = @benchmarkable atan($(-absr), $(T(Inf))) # m == 1
    g["y finite", "y positive", "x infinite", "x negative", _arg_string] = @benchmarkable atan($(absr), $(-T(Inf))) # m == 2
    g["y finite", "y negative", "x infinite", "x negative", _arg_string] = @benchmarkable atan($(-absr), $(-T(Inf))) # m == 3
    # isinf(y) == true && isinf(x) == false
    g["y infinite", "y positive", "x finite", "x positive", _arg_string] = @benchmarkable atan($(T(Inf)), $(absr))
    g["y infinite", "y negative", "x finite", "x positive", _arg_string] = @benchmarkable atan($(-T(Inf)), $(absr))
    g["y infinite", "y positive", "x finite", "x negative", _arg_string] = @benchmarkable atan($(T(Inf)), $(-absr))
    g["y infinite", "y negative", "x finite", "x negative", _arg_string] = @benchmarkable atan($(-T(Inf)), $(-absr))
    # |y/x| above high threshold
    atanpi = T(1.5707963267948966)
    g["abs(y/x) high", "y positive", "x positive", _arg_string] = @benchmarkable atan($(T(2.0^61)), $(T(1.0)))
    g["abs(y/x) high", "y negative", "x positive", _arg_string] = @benchmarkable atan($(-T(2.0^61)), $(T(1.0)))
    g["abs(y/x) high", "y positive", "x negative", _arg_string] = @benchmarkable atan($(T(2.0^61)), $(-T(1.0)))
    g["abs(y/x) high", "y negative", "x negative", _arg_string] = @benchmarkable atan($(-T(2.0^61)), $(-T(1.0)))
    g["abs(y/x) high", "y infinite", "y negative", "x finite", "x negative", _arg_string] = @benchmarkable atan($(-T(Inf)), $(-absr))
    # |y|/x between 0 and low threshold
    g["abs(y/x) small", "y positive", "x positive", _arg_string] = @benchmarkable atan($(T(2.0^-61)), $(T(1.0)))
    g["abs(y/x) small", "y positive", "x negative", _arg_string] = @benchmarkable atan($(T(2.0^-61)), $(-T(1.0)))
    # y/x is "safe" ("arbitrary values", just need to hit the branch)
    _ATAN2_PI_LO(::Type{Float32}) = -8.7422776573f-08
    _ATAN2_PI_LO(::Type{Float64}) = 1.2246467991473531772E-16
    g["abs(y/x) safe (small)", "y positive", "x positive", _arg_string] = @benchmarkable atan($(T(5.0)), $(T(2.5)))
    g["abs(y/x) safe (small)", "y negative", "x positive", _arg_string] = @benchmarkable atan($(-T(5.0)), $(T(2.5)))
    g["abs(y/x) safe (small)", "y positive", "x negative", _arg_string] = @benchmarkable atan($(T(5.0)), $(-T(2.5)))
    g["abs(y/x) safe (small)", "y negative", "x negative", _arg_string] = @benchmarkable atan($(-T(5.0)), $(-T(2.5)))
    g["abs(y/x) safe (large)", "y positive", "x positive", _arg_string] = @benchmarkable atan($(T(1235.2341234)), $(T(2.5)))
    g["abs(y/x) safe (large)", "y negative", "x positive", _arg_string] = @benchmarkable atan($(-T(1235.2341234)), $(T(2.5)))
    g["abs(y/x) safe (large)", "y positive", "x negative", _arg_string] = @benchmarkable atan($(T(1235.2341234)), $(-T(2.5)))
    g["abs(y/x) safe (large)", "y negative", "x negative", _arg_string] = @benchmarkable atan($(-T(1235.2341234)), $(-T(2.5)))
end

########
# sinh #
########

g = addgroup!(SUITE, "sinh")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["zero", _arg_string] = @benchmarkable sinh($(zero(T)))
    g["very small", "positive argument", _arg_string] = @benchmarkable sinh($(nextfloat(zero(T))))
    g["very small", "negative argument", _arg_string] = @benchmarkable sinh($(prevfloat(zero(T))))
    g["very large", "positive argument", _arg_string] = @benchmarkable sinh($(T(1000)))
    g["very large", "negative argument", _arg_string] = @benchmarkable sinh($(-T(1000)))
end
g["0 <= abs(x) < 2f-12", "positive argument", "Float32"] = @benchmarkable sinh($(prevfloat(2f-12)))
g["0 <= abs(x) < 2f-12", "negative argument", "Float32"] = @benchmarkable sinh($(nextfloat(-2f-12)))
g["2f-12 <= abs(x) < 9f0", "positive argument", "Float32"] = @benchmarkable sinh($(5f0))
g["2f-12 <= abs(x) < 9f0", "negative argument", "Float32"] = @benchmarkable sinh($(-5f0))
g["9f0 <= abs(x) < 88.72283f0", "positive argument", "Float32"] = @benchmarkable sinh($(22f0))
g["9f0 <= abs(x) < 88.72283f0", "negative argument", "Float32"] = @benchmarkable sinh($(-22f0))
g["0 <= abs(x) < 2.0^-28", "positive argument", "Float64"] = @benchmarkable sinh($(prevfloat(2.0^-28)))
g["0 <= abs(x) < 2.0^-28", "negative argument", "Float64"] = @benchmarkable sinh($(nextfloat(-2.0^-28)))
g["2.0^-28 <= abs(x) < 22.0", "positive argument", "Float64"] = @benchmarkable sinh($(5.0))
g["2.0^-28 <= abs(x) < 22.0", "negative argument", "Float64"] = @benchmarkable sinh($(-5.0))
g["22.0 <= abs(x) < 709.7822265633563", "positive argument", "Float64"] = @benchmarkable sinh($(30.0))
g["22.0 <= abs(x) < 709.7822265633563", "negative argument", "Float64"] = @benchmarkable sinh($(-30.0))

########
# cosh #
########

g = addgroup!(SUITE, "cosh")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["zero", _arg_string] = @benchmarkable cosh($(zero(T)))
    g["very small", "positive argument", _arg_string] = @benchmarkable cosh($(nextfloat(zero(T))))
    g["very small", "negative argument", _arg_string] = @benchmarkable cosh($(prevfloat(zero(T))))
    g["very large", "positive argument", _arg_string] = @benchmarkable cosh($(T(1000)))
    g["very large", "negative argument", _arg_string] = @benchmarkable cosh($(-T(1000)))
end
g["0 <= abs(x) < 0.00024414062f0", "positive argument", "Float32"] = @benchmarkable cosh($(prevfloat(0.00024414062f0)))
g["0 <= abs(x) < 0.00024414062f0", "negative argument", "Float32"] = @benchmarkable cosh($(nextfloat(-0.00024414062f0)))
g["0.00024414062f0 <= abs(x) < 9f0", "positive argument", "Float32"] = @benchmarkable cosh($(5f0))
g["0.00024414062f0 <= abs(x) < 9f0", "negative argument", "Float32"] = @benchmarkable cosh($(-5f0))
g["9f0 <= abs(x) < 88.72283f0", "positive argument", "Float32"] = @benchmarkable cosh($(22f0))
g["9f0 <= abs(x) < 88.72283f0", "negative argument", "Float32"] = @benchmarkable cosh($(-22f0))
g["0 <= abs(x) < 2.7755602085408512e-17", "positive argument", "Float64"] = @benchmarkable cosh($(prevfloat(2.7755602085408512e-17)))
g["0 <= abs(x) < 2.7755602085408512e-17", "negative argument", "Float64"] = @benchmarkable cosh($(nextfloat(-2.7755602085408512e-17)))
g["2.7755602085408512e-17 <= abs(x) < 22.0", "positive argument", "Float64"] = @benchmarkable cosh($(5.0))
g["2.7755602085408512e-17 <= abs(x) < 22.0", "negative argument", "Float64"] = @benchmarkable cosh($(-5.0))
g["22.0 <= abs(x) < 709.7822265633563", "positive argument", "Float64"] = @benchmarkable cosh($(30.0))
g["22.0 <= abs(x) < 709.7822265633563", "negative argument", "Float64"] = @benchmarkable cosh($(-30.0))

########
# tanh #
########

g = addgroup!(SUITE, "tanh")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["zero", _arg_string] = @benchmarkable tanh($(zero(T)))
    g["very small", "positive argument", _arg_string] = @benchmarkable tanh($(nextfloat(zero(T))))
    g["very small", "negative argument", _arg_string] = @benchmarkable tanh($(prevfloat(zero(T))))
    g["very large", "positive argument", _arg_string] = @benchmarkable tanh($(T(2.0)^67))
    g["very large", "negative argument", _arg_string] = @benchmarkable tanh($(-T(2.0)^67))
end
g["0 <= abs(x) < 2f0^-12", "positive argument", "Float32"] = @benchmarkable tanh($(prevfloat(2f0^-12)))
g["0 <= abs(x) < 2f0^-12", "negative argument", "Float32"] = @benchmarkable tanh($(nextfloat(-2f0^-12)))
g["2f0^-12 <= abs(x) < 1f0", "positive argument", "Float32"] = @benchmarkable tanh($(0.5f0))
g["2f0^-12 <= abs(x) < 1f0", "negative argument", "Float32"] = @benchmarkable tanh($(-0.5f0))
g["1f0 <= abs(x) < 9f0", "positive argument", "Float32"] = @benchmarkable tanh($(8f0))
g["1f0 <= abs(x) < 9f0", "negative argument", "Float32"] = @benchmarkable tanh($(-8f0))
g["0 <= abs(x) < 2.0^-28", "positive argument", "Float64"] = @benchmarkable tanh($(prevfloat(2.0^-28)))
g["0 <= abs(x) < 2.0^-28", "negative argument", "Float64"] = @benchmarkable tanh($(nextfloat(-2.0^-28)))
g["2.0^-28 <= abs(x) < 1.0", "positive argument", "Float64"] = @benchmarkable tanh($(0.5))
g["2.0^-28 <= abs(x) < 1.0", "negative argument", "Float64"] = @benchmarkable tanh($(-0.5))
g["1.0 <= abs(x) < 22.0", "positive argument", "Float64"] = @benchmarkable tanh($(14.0))
g["1.0 <= abs(x) < 22.0", "negative argument", "Float64"] = @benchmarkable tanh($(-14.0))


#########
# asinh #
#########

g = addgroup!(SUITE, "asinh")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["zero", _arg_string] = @benchmarkable asinh($(zero(T)))
    g["very small", "positive argument", _arg_string] = @benchmarkable asinh($(nextfloat(zero(T))))
    g["very small", "negative argument", _arg_string] = @benchmarkable asinh($(prevfloat(zero(T))))
    g["very large", "positive argument", _arg_string] = @benchmarkable asinh($(T(2)^28))
    g["very large", "negative argument", _arg_string] = @benchmarkable asinh($(-T(2)^28))
    g["0 <= abs(x) < 2^-28", "positive argument", _arg_string] = @benchmarkable asinh($(T(2)^-28))
    g["0 <= abs(x) < 2^-28", "negative argument", _arg_string] = @benchmarkable asinh($(-T(2)^-28))
    g["2^-28 <= abs(x) < 2", "positive argument", _arg_string] = @benchmarkable asinh($(T(1.5)))
    g["2^-28 <= abs(x) < 2", "negative argument", _arg_string] = @benchmarkable asinh($(-T(1.5)))
    g["2 <= abs(x) < 2^28", "positive argument", _arg_string] = @benchmarkable asinh($(T(1000)))
    g["2 <= abs(x) < 2^28", "negative argument", _arg_string] = @benchmarkable asinh($(-T(1000)))
end

#########
# acosh #
#########

g = addgroup!(SUITE, "acosh")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["one", _arg_string] = @benchmarkable acosh($(one(T)))
    g["very large", "positive argument", _arg_string] = @benchmarkable acosh($(T(2.0)^28))
    g["1 <= abs(x) < 2", "positive argument", _arg_string] = @benchmarkable acosh($(T(1.5)))
    g["2 <= abs(x) < 2^28", "positive argument", _arg_string] = @benchmarkable acosh($(T(1000)))
end

#########
# atanh #
#########

g = addgroup!(SUITE, "atanh")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["zero", _arg_string] = @benchmarkable atanh($(zero(T)))
    g["one", _arg_string] = @benchmarkable atanh($(one(T)))
    g["very small", "positive argument", _arg_string] = @benchmarkable atanh($(nextfloat(zero(T))))
    g["very small", "negative argument", _arg_string] = @benchmarkable atanh($(prevfloat(zero(T))))
    g["2^-28 <= abs(x) < 0.5", "positive argument", _arg_string] = @benchmarkable atanh($(T(0.25)))
    g["2^-28 <= abs(x) < 0.5", "negative argument", _arg_string] = @benchmarkable atanh($(-T(0.25)))
    g["0.5 <= abs(x) < 1", "positive argument", _arg_string] = @benchmarkable atanh($(T(0.75)))
    g["0.5 <= abs(x) < 1", "negative argument", _arg_string] = @benchmarkable atanh($(-T(0.75)))
end

#########
# cbrt #
#########

g = addgroup!(SUITE, "cbrt")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["zero", _arg_string] = @benchmarkable cbrt($(zero(T)))
    g["one", _arg_string] = @benchmarkable cbrt($(one(T)))
    g["very small", "positive argument", _arg_string] = @benchmarkable cbrt($(nextfloat(zero(T))))
    g["very small", "negative argument", _arg_string] = @benchmarkable cbrt($(prevfloat(zero(T))))
    g["small", "positive argument", _arg_string] = @benchmarkable cbrt($(T(0.25)))
    g["small", "negative argument", _arg_string] = @benchmarkable cbrt($(-T(0.25)))
    g["medium", "positive argument", _arg_string] = @benchmarkable cbrt($(T(95.75)))
    g["medium", "negative argument", _arg_string] = @benchmarkable cbrt($(-T(95.75)))
    g["large", "positive argument", _arg_string] = @benchmarkable cbrt($(T(3.0)^84))
    g["large", "negative argument", _arg_string] = @benchmarkable cbrt($(-T(3.0)^84))
end
#########
# exp2 #
#########

g = addgroup!(SUITE, "exp2")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["zero", _arg_string] = @benchmarkable exp2($(zero(T)))
    g["one", _arg_string] = @benchmarkable exp2($(one(T)))
    g["very small", "positive argument", _arg_string] = @benchmarkable exp2($(nextfloat(zero(T))))
    g["very small", "negative argument", _arg_string] = @benchmarkable exp2($(prevfloat(zero(T))))
    g["small", "positive argument", _arg_string] = @benchmarkable exp2($(T(0.25)))
    g["small", "negative argument", _arg_string] = @benchmarkable exp2($(-T(0.25)))
    g["2pow3", "positive argument", _arg_string] = @benchmarkable exp2($(T(2)^3))
    g["2pow3", "negative argument", _arg_string] = @benchmarkable exp2($(-T(2)^3))
    g["2pow35", "positive argument", _arg_string] = @benchmarkable exp2($(T(2.0)^35))
    g["2pow35", "negative argument", _arg_string] = @benchmarkable exp2($(-T(2.0)^35))
end
g["2pow1023", "positive argument", Float64] = @benchmarkable exp2($((2.0)^1023))
g["2pow1023", "negative argument", Float64] = @benchmarkable exp2($(-(2.0)^1023))
g["2pow127", "positive argument", Float32] = @benchmarkable exp2($((2.0f0)^127))
g["2pow127", "negative argument", Float32] = @benchmarkable exp2($(-(2.0f0)^127))

#########
# expm1 #
#########

g = addgroup!(SUITE, "expm1")
for T in (Float32, Float64)
    _arg_string = arg_string(T)
    g["zero", _arg_string] = @benchmarkable expm1($(zero(T)))
    g["one", _arg_string] = @benchmarkable expm1($(one(T)))
    g["very small", "positive argument", _arg_string] = @benchmarkable expm1($(nextfloat(zero(T))))
    g["very small", "negative argument", _arg_string] = @benchmarkable expm1($(prevfloat(zero(T))))
    g["small", "positive argument", _arg_string] = @benchmarkable expm1($(T(0.25)))
    g["small", "negative argument", _arg_string] = @benchmarkable expm1($(-T(0.25)))
    g["medium", "positive argument", _arg_string] = @benchmarkable expm1($(T(95.75)))
    g["medium", "negative argument", _arg_string] = @benchmarkable expm1($(-T(95.75)))
    g["large", "positive argument", _arg_string] = @benchmarkable expm1($(T(2.0)^20))
    g["large", "negative argument", _arg_string] = @benchmarkable expm1($(-T(2.0)^20))
    g["large", "positive argument", _arg_string] = @benchmarkable expm1($(T(2.0)^40))
    g["large", "negative argument", _arg_string] = @benchmarkable expm1($(-T(2.0)^40))
end

g["huge", "positive argument", "Float64"] = @benchmarkable expm1($(-56.0*0.6931471805599453-10))
g["arg reduction I", "positive argument", "Float64"] = @benchmarkable expm1($(0.5*0.6931471805599453+0.1))
g["arg reduction I", "negative argument", "Float64"] = @benchmarkable expm1($(0.5*0.6931471805599453+0.1))
g["arg reduction II", "positive argument", "Float64"] = @benchmarkable expm1($(1.5*0.6931471805599453-0.1))
g["arg reduction II", "negative argument", "Float64"] = @benchmarkable expm1($(1.5*0.6931471805599453-0.1))
g["huge", "positive argument", "Float3"] = @benchmarkable expm1($(-18.714973f0-10f0))
g["arg reduction I", "positive argument", "Float32"] = @benchmarkable expm1($(0.5f0*0.6931472f0+0.1f0))
g["arg reduction I", "negative argument", "Float32"] = @benchmarkable expm1($(0.5f0*0.6931472f0+0.1f0))
g["arg reduction II", "positive argument", "Float32"] = @benchmarkable expm1($(1.5f0*0.6931472f0-0.1f0))
g["arg reduction II", "negative argument", "Float32"] = @benchmarkable expm1($(1.5f0*0.6931472f0-0.1f0))

end # module
