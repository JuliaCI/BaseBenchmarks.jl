module ScalarBenchmarks

import ..BaseBenchmarks
using ..BenchmarkTrackers

##############
# predicates #
##############

@track BaseBenchmarks.TRACKER "scalar predicate" begin
    @setup begin
        Rs = (UInt8, UInt16, UInt32, UInt64, UInt128,
              Int8, Int16, Int32, Int64, Int128, BigInt,
              Float16, Float32, Float64, BigFloat)
        Cs = map(R -> Complex{R}, Rs)
        Ts = (Rs..., Cs...)
    end
    @benchmarks begin
        [(:isequal, string(Ti), string(Tj)) => isequal(one(Ti), one(Tj)) for Ti in Ts, Tj in Ts]
        [(:isinteger, string(T)) => isinteger(one(T)) for T in Ts]
        [(:isinf, string(T)) => isinf(one(T)) for T in Ts]
        [(:isfinite, string(T)) => isfinite(one(T)) for T in Ts]
        [(:isnan, string(T)) => isnan(one(T)) for T in Ts]
        [(:iseven, string(T)) => iseven(one(T)) for T in Ts]
        [(:isodd, string(T)) => isodd(one(T)) for T in Ts]
    end
    @tags "scalar" "predicate" "isinteger" "isinf" "isnan" "iseven" "isodd" "slow"
end

end # module