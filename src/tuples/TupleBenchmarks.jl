module TupleBenchmarks

import ..BaseBenchmarks
using ..BenchmarkTrackers
using ..RandUtils


###############
# issue #5274 #
###############

immutable TupleWrapper{N, T}
    data::NTuple{N, T}
end

Base.eltype{N,T}(::TupleWrapper{N,T}) = T
Base.length{N,T}(::TupleWrapper{N,T}) = N

function get_index(n::NTuple, i::Int)
    @inbounds v = n[i]
    return v
end

function get_index(n::TupleWrapper, i::Int)
    @inbounds v = n.data[i]
    return v
end

function sum_tuple{N, T}(n::Union{NTuple{N, T}, TupleWrapper{N, T}})
    s = zero(T)
    for i in 1:N
        s += get_index(n, i)
    end
    return s
end


TUPLE_SUM_SIZES = (3, 8, 30, 60)
TUPLE_SUM_TYPES = (Float32, Float64)

@track BaseBenchmarks.TRACKER "tuple indexing" begin
    @setup begin
        tuples = [((samerand(T, i)...)) for i in TUPLE_SUM_SIZES, T in TUPLE_SUM_TYPES]
        tuple_wrappers = [TupleWrapper((samerand(T, i)...)) for i in TUPLE_SUM_SIZES, T in TUPLE_SUM_TYPES]
    end
    @benchmarks begin
        [(:sumelt, "TupleWrapper", length(t_wrap), eltype(t_wrap)) => sum_tuple(t_wrap) for t_wrap in tuple_wrappers]
        [(:sumelt, "NTuple", length(t), eltype(t)) => sum_tuple(t) for t in tuples]
    end
    @tags "tuple" "indexing" "sum"
end

end # module
