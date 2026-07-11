module GlobalsBenchmarks

# Benchmarks for accessing global variables from compiled code: typed globals
# (with a declared type), untyped globals, and `const` bindings as a baseline.
# The loop kernels pair reads with a store to a global so that the accesses
# cannot simply be hoisted out of the benchmark loop.

using BenchmarkTools

const SUITE = BenchmarkGroup(["global", "binding", "typed", "untyped"])

global typed_f64::Float64 = 1.5
global typed_int::Int = 3
global untyped = 1.5
const constval = 1.5

for k in 1:16
    @eval global $(Symbol(:m, k))::Float64 = $(Float64(k))
end

# 1 typed read + 1 typed write per iteration
function perf_read_typed(n)
    s = 0.0
    for i in 1:n
        s += typed_f64
        global typed_int = 1
    end
    return s
end

# read-modify-write of a typed global (includes re-boxing the stored value)
function perf_rmw_typed(n)
    for i in 1:n
        global typed_f64 += 1.0
    end
    return typed_f64
end

# store of a constant (the box is a compile-time constant)
function perf_write_const(n)
    for i in 1:n
        global typed_f64 = 1.5
    end
    return nothing
end

# store of a varying value (includes per-iteration boxing)
function perf_write_varying(n)
    for i in 1:n
        global typed_int = i
    end
    return nothing
end

# many distinct globals accessed per iteration: 16 typed reads + 1 typed write
@eval function perf_many_globals(n)
    s = 0.0
    for i in 1:n
        s += $(Expr(:call, :+, [Symbol(:m, k) for k in 1:16]...))
        global m1 = 1.0
    end
    return s
end

# 1 untyped read (type-asserted) + 1 typed write per iteration
function perf_read_untyped(n)
    s = 0.0
    for i in 1:n
        s += untyped::Float64
        global typed_int = 1
    end
    return s
end

# baseline: 1 const read + 1 typed write per iteration
function perf_read_const(n)
    s = 0.0
    for i in 1:n
        s += constval
        global typed_int = 1
    end
    return s
end

SUITE["read_typed"]    = @benchmarkable perf_read_typed(10_000)
SUITE["rmw_typed"]     = @benchmarkable perf_rmw_typed(10_000)
SUITE["write_const"]   = @benchmarkable perf_write_const(10_000)
SUITE["write_varying"] = @benchmarkable perf_write_varying(10_000)
SUITE["many_globals"]  = @benchmarkable perf_many_globals(2_000)
SUITE["read_untyped"]  = @benchmarkable perf_read_untyped(10_000)
SUITE["read_const"]    = @benchmarkable perf_read_const(10_000)

@static if isdefined(Base, :swapglobal!)
    # swapglobal! on a typed global
    function perf_swap_typed(n)
        local old = 0.0
        for i in 1:n
            old = swapglobal!(@__MODULE__, :typed_f64, 2.5)
        end
        return old
    end
    SUITE["swap_typed"] = @benchmarkable perf_swap_typed(10_000)
end

end # module
