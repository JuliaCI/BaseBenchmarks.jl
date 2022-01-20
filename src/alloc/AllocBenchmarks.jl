module AllocBenchmarks

using BenchmarkTools

const SUITE = BenchmarkGroup()

function perf_alloc_many_arrays()
    for _ in 1:10000000
        # global to ensure that this is heap allocated
        global a = []

        GC.safepoint()
        Threads.atomic_fence()
    end
end

function perf_alloc_many_strings()
    for i in 1:10000000
        # global to ensure that this is heap allocated
        global b = "hello $(i)"

        GC.safepoint()
        Threads.atomic_fence()
    end
end

# mutable to make it heap allocate
mutable struct Foo
    x::Int
    y::Int
end

function perf_alloc_many_structs()
    for i in 1:10000000
        # global to ensure that this is heap allocated
        global b = Foo(i, i+1)

        GC.safepoint()
        Threads.atomic_fence()
    end
end

function perf_grow_array()
    x = Vector{Int}()
    for i in 1:10000000
        push!(x, i)

        GC.safepoint()
        Threads.atomic_fence()
    end
end

SUITE["arrays"] = @benchmarkable perf_alloc_many_arrays()
SUITE["strings"] = @benchmarkable perf_alloc_many_strings()
SUITE["structs"] = @benchmarkable perf_alloc_many_structs()
SUITE["grow_array"] = @benchmarkable perf_grow_array()

end # module
