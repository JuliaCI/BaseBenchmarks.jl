module ReinterpretBenchmarks

using BenchmarkTools

const SUITE = BenchmarkGroup()

@noinline function measure_reinterpret(::Type{T1}, x::T2) where {T1, T2}
    a = @noinline reinterpret(T1, x)
    b = @noinline reinterpret(T2, a)
    return a, b
end

function bench_reinterpret(::Type{T1}, x::T2, N=1000) where {T1, T2}
    for _ in 1:N
        global a, b = measure_reinterpret(T1, x)
        GC.safepoint()
        Threads.atomic_fence()
    end
end

# --- Packed Types ---------------------------------------
g = addgroup!(SUITE, "packed_types")

# Define extra primitive types for benchmarking
primitive type Int24 3 * 8 end
primitive type Int40 5 * 8 end
primitive type Int48 6 * 8 end
primitive type Int56 7 * 8 end

primitive type Int136 17 * 8 end
primitive type Int144 18 * 8 end

primitive type Int384 48 * 8 end
primitive type Int392 49 * 8 end
primitive type Int400 50 * 8 end

primitive type Int1024 128 * 8 end

for B in (3, 4, 6, 7, 17, 18, 48, 49, 50, 128)
    let T = eval(Symbol("Int$(B*8)"))
        g[B] = @benchmarkable bench_reinterpret($T, $(ntuple(i->UInt8(i), B)), 1000)
    end
end

function perf_reinterpret_()
    TUPLES = [
        (0x01, 1, 0x02),
        (1.0, 2, 3.0, 4, 5.0, 6, 7.0, 8, 9.0, 10, 11.10, 12, 13.0),
        (1, 0x0001, (0x01, 2, 0x01), 0x01, 1.0),
        ntuple(i->0x01, 100),
        ntuple(i->0x01, 228),
        (0x01, 1, 2, ntuple(i->0x01, 100),),
    ]
    for tup in TUPLES
        bench_normalization(tup)
    end
end

# SUITE["arrays"] = @benchmarkable perf_alloc_many_arrays()

end # module
