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
    @tags "scalar" "predicate" "isinteger" "isinf" "isnan" "iseven" "isodd" "slow"
end

end # module