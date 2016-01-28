module ScalarBenchmarks

import ..BaseBenchmarks
using ..BenchmarkTrackers

const INTS = (UInt, Int, BigInt)
const FLOATS = (Float32, Float64, BigFloat)
const REALS = (INTS..., FLOATS...)
const COMPS = map(R -> Complex{R}, REALS)
const NUMS = (REALS..., COMPS...)

##############
# predicates #
##############

@track BaseBenchmarks.TRACKER "scalar predicate" begin
    @benchmarks begin
        [(:isequal, string(T)) => isequal(one(T), one(T)) for T in NUMS]
        [(:isless, string(T)) => isequal(one(T), one(T)) for T in NUMS]
        [(:isinteger, string(T)) => isinteger(one(T)) for T in NUMS]
        [(:isinf, string(T)) => isinf(one(T)) for T in NUMS]
        [(:isfinite, string(T)) => isfinite(one(T)) for T in NUMS]
        [(:isnan, string(T)) => isnan(one(T)) for T in NUMS]
        [(:iseven, string(T)) => iseven(one(T)) for T in INTS]
        [(:isodd, string(T)) => isodd(one(T)) for T in INTS]
    end
    @constraints gc=>false
    @tags "scalar" "predicate" "isinteger" "isinf" "isnan" "iseven" "isodd"
end

##############
# arithmetic #
##############

perf_fastmath_mul(a, b) = @fastmath a * b
perf_fastmath_div(a, b) = @fastmath a / b
perf_fastmath_add(a, b) = @fastmath a + b
perf_fastmath_sub(a, b) = @fastmath a - b

@track BaseBenchmarks.TRACKER "scalar arithmetic" begin
    @benchmarks begin
        [(:scalar_add, string(Ti), string(Tj)) => +(one(Ti), one(Tj)) for Ti in NUMS, Tj in NUMS]
        [(:scalar_sub, string(Ti), string(Tj)) => -(one(Ti), one(Tj)) for Ti in NUMS, Tj in NUMS]
        [(:scalar_mul, string(Ti), string(Tj)) => *(one(Ti), one(Tj)) for Ti in NUMS, Tj in NUMS]
        [(:scalar_div, string(Ti), string(Tj)) => /(one(Ti), one(Tj)) for Ti in NUMS, Tj in NUMS]
        [(:scalar_fastmath_add, string(Ti), string(Tj)) => perf_fastmath_add(one(Ti), one(Tj)) for Ti in NUMS, Tj in NUMS]
        [(:scalar_fastmath_sub, string(Ti), string(Tj)) => perf_fastmath_sub(one(Ti), one(Tj)) for Ti in NUMS, Tj in NUMS]
        [(:scalar_fastmath_mul, string(Ti), string(Tj)) => perf_fastmath_mul(one(Ti), one(Tj)) for Ti in NUMS, Tj in NUMS]
        [(:scalar_fastmath_div, string(Ti), string(Tj)) => perf_fastmath_div(one(Ti), one(Tj)) for Ti in NUMS, Tj in NUMS]
    end
    @constraints seconds=>1 gc=>false
    @tags "scalar" "arithmetic" "fastmath"
end

end # module