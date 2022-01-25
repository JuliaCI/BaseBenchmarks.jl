module AllocBenchmarks

using BenchmarkTools

const SUITE = BenchmarkGroup()

function perf_alloc_many_arrays()
    for _ in 1:10000
        # global to ensure that this is heap allocated
        global a = [[] for _ in 1:1000]

        GC.safepoint()
        Threads.atomic_fence()
    end
end

function perf_alloc_many_strings()
    for i in 1:10000
        # global to ensure that this is heap allocated
        global b = ["hello $(j)" for j in 1:1000]

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
    for i in 1:10000
        # global to ensure that this is heap allocated
        global b = [Foo(i, j) for j in 1:1000]

        GC.safepoint()
        Threads.atomic_fence()
    end
end

function perf_grow_array()
    global x = Vector{Int}()
    for i in 1:10000
        for j in 1:1000
            push!(x, j)
        end

        GC.safepoint()
        Threads.atomic_fence()
    end
end

SUITE["arrays"] = @benchmarkable perf_alloc_many_arrays()
SUITE["strings"] = @benchmarkable perf_alloc_many_strings()
SUITE["structs"] = @benchmarkable perf_alloc_many_structs()
SUITE["grow_array"] = @benchmarkable perf_grow_array()

end # module
