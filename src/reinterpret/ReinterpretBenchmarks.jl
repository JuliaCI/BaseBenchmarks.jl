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
struct Int0 end
primitive type Int24 3 * 8 end

primitive type Int136 17 * 8 end

primitive type Int384 48 * 8 end
primitive type Int392 49 * 8 end

primitive type Int1024 128 * 8 end

for B in (0, 1, 2, 3, 8, 16, 17, 48, 49, 128)
    let T = eval(Symbol("Int$(B*8)"))
        g[B] = @benchmarkable bench_reinterpret($T, $(ntuple(i->UInt8(i), B)))
    end
end

g = addgroup!(SUITE, "padded_types")

primitive type Int80 10 * 8 end
primitive type Int232 29 * 8 end
primitive type Int800 100 * 8 end
primitive type Int832 104 * 8 end
primitive type Int936 117 * 8 end
primitive type Int1824 228 * 8 end

for tup in [
        (0x01, 1, 0x02),
        (1, 0x0001, (0x01, 2, 0x01), 0x01, 1.0),
        (0x01, 1, 2, ntuple(i->0x01, 100),),
    ]
    B1 = sizeof(tup)
    B2 = Base.packedsize(typeof(tup))
    T2 = eval(Symbol("Int$(B2*8)"))
    g[B2, B1] = @benchmarkable bench_reinterpret($T2, $(tup))
end

g = addgroup!(SUITE, "mixed_tuples")

for tup in [
        ((), (((), ())), ()),
        (1.0, 2, 3.0, 4, 5.0, 6, 7.0, 8, 9.0, 10, 11.10, 12, 13.0),
        ntuple(i->(isodd(i) ? Int32(i) : Float32(i)), 25),
        ntuple(i->(isodd(i) ? true : i % UInt8), 228),
    ]
    B1 = sizeof(tup)
    B2 = Base.packedsize(typeof(tup))
    T2 = eval(Symbol("Int$(B2*8)"))
    g[B2, B1] = @benchmarkable bench_reinterpret($T2, $(tup))
end

g = addgroup!(SUITE, "padded_to_padded")

for (tup, T2) in [
        # Empty tuples:
        ((), (((), ())), ()) => Tuple{Tuple{Tuple{}, Tuple{}}, Tuple{}, Tuple{Tuple{}}},
        # Same padding, different positions:
        (0x01, 1, 0x02) => Tuple{Int32, Int16, Int32},
        (0x01, 1, 2, ntuple(i->0x01, 100),) => Tuple{UInt64, UInt8, Int64, NTuple{100,Int8}},
        # small padding to big
        (1, 0x0001, (0x01, 2, 0x01), 0x01, 1.0) =>
            Tuple{Int16, Int8, Int64, Int8, Int64, Int64, Int8},
        # inverse: big padding to small
        (0x0000, 0x01, 0x0000000000000002, 0x03, 0x0000000000000004, 0x0000000000000005, 0x06) =>
            Tuple{Int64, UInt16, Tuple{UInt8, Int64, UInt8}, UInt8, Float64},
        # exactly the same padding positions, just different types:
        (0x01, 1, 0x02) => Tuple{Int8, Float64, Int8},
    ]
    p = Base.packedsize(typeof(tup))
    B1 = sizeof(tup)
    B2 = sizeof(T2)
    g[p, B2, B1] = @benchmarkable bench_reinterpret($T2, $(tup))
end

end # module
