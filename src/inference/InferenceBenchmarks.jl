"""
    "inference" => InferenceBenchmarks

Defines a benchmark suite for Julia-level compilation pipeline.
Note that this benchmark suite is only available for Julia 1.8 and higher.

This benchmark group `"inference"` is composed of the following subgroups:
- `"allinference"`: benchmarks the overall Julia-level compilation pipeline for a static call graph
- `"abstract interpretation"`: benchmarks abstract interpretation for a static call graph (without optimization)
- `"optimization"`: benchmarks optimization passes applied for a single call frame
"""
module InferenceBenchmarks

# InferenceBenchmarker
# ====================
# this new `AbstractInterpreter` satisfies the minimum interface requirements and manages
# its cache independently in a way it is totally separated from the native code cache
# managed by the runtime system: this allows us to profile Julia-level inference reliably
# without being influenced by previous trials or some native execution

using BenchmarkTools, InteractiveUtils

const CC = Core.Compiler

import .CC:
    may_optimize, may_compress, may_discard_trees, InferenceParams,  OptimizationParams,
    get_world_counter, get_inference_cache, code_cache, # get, getindex, haskey, setindex!
    nothing
using Core:
    MethodInstance, CodeInstance, MethodTable, MethodMatch, SimpleVector, Typeof
using .CC:
    AbstractInterpreter, NativeInterpreter, WorldRange, WorldView, InferenceResult,
    InferenceState, OptimizationState,
    _methods_by_ftype, specialize_method, unwrap_unionall, rewrap_unionall, widenconst,
    typeinf, optimize

struct InferenceBenchmarkerCache
    dict::IdDict{MethodInstance,CodeInstance}
end
struct InferenceBenchmarker <: AbstractInterpreter
    world::UInt
    inf_params::InferenceParams
    opt_params::OptimizationParams
    optimize::Bool
    compress::Bool
    discard_trees::Bool
    inf_cache::Vector{InferenceResult}
    code_cache::InferenceBenchmarkerCache
    function InferenceBenchmarker(
        world::UInt = get_world_counter();
        inf_params::InferenceParams = InferenceParams(),
        opt_params::OptimizationParams = OptimizationParams(),
        optimize::Bool = true,
        compress::Bool = true,
        discard_trees::Bool = true,
        inf_cache::Vector{InferenceResult} = InferenceResult[],
        code_cache::InferenceBenchmarkerCache = InferenceBenchmarkerCache(IdDict{MethodInstance,CodeInstance}()),
        )
        return new(
            world,
            inf_params,
            opt_params,
            optimize,
            compress,
            discard_trees,
            inf_cache,
            code_cache)
    end
end

CC.may_optimize(interp::InferenceBenchmarker) = interp.optimize
CC.may_compress(interp::InferenceBenchmarker) = interp.compress
CC.may_discard_trees(interp::InferenceBenchmarker) = interp.discard_trees
CC.InferenceParams(interp::InferenceBenchmarker) = interp.inf_params
CC.OptimizationParams(interp::InferenceBenchmarker) = interp.opt_params
CC.get_world_counter(interp::InferenceBenchmarker) = interp.world
CC.get_inference_cache(interp::InferenceBenchmarker) = interp.inf_cache
CC.code_cache(interp::InferenceBenchmarker) = WorldView(interp.code_cache, WorldRange(get_world_counter(interp)))
CC.get(wvc::WorldView{<:InferenceBenchmarkerCache}, mi::MethodInstance, default) = get(wvc.cache.dict, mi, default)
CC.getindex(wvc::WorldView{<:InferenceBenchmarkerCache}, mi::MethodInstance) = getindex(wvc.cache.dict, mi)
CC.haskey(wvc::WorldView{<:InferenceBenchmarkerCache}, mi::MethodInstance) = haskey(wvc.cache.dict, mi)
CC.setindex!(wvc::WorldView{<:InferenceBenchmarkerCache}, ci::CodeInstance, mi::MethodInstance) = setindex!(wvc.cache.dict, ci, mi)

function inf_gf_by_type!(interp::InferenceBenchmarker, @nospecialize(tt::Type{<:Tuple}); kwargs...)
    match = _which(tt; world=get_world_counter(interp))
    return inf_method_signature!(interp, match.method, match.spec_types, match.sparams; kwargs...)
end

@static if VERSION ≥ v"1.10.0-DEV.96"
    using Base: _which
else
    function _which(@nospecialize(tt::Type);
        method_table::Union{Nothing,MethodTable,Core.Compiler.MethodTableView}=nothing,
        world::UInt=get_world_counter(),
        raise::Bool=false)
        if method_table === nothing
            table = Core.Compiler.InternalMethodTable(world)
        elseif isa(method_table, MethodTable)
            table = Core.Compiler.OverlayMethodTable(world, method_table)
        else
            table = method_table
        end
        match, = Core.Compiler.findsup(tt, table)
        if match === nothing
            raise && error("no unique matching method found for the specified argument types")
            return nothing
        end
        return match
    end
end

inf_method!(interp::InferenceBenchmarker, m::Method; kwargs...) =
    inf_method_signature!(interp, m, m.sig, method_sparams(m); kwargs...)
function method_sparams(m::Method)
    s = TypeVar[]
    sig = m.sig
    while isa(sig, UnionAll)
        push!(s, sig.var)
        sig = sig.body
    end
    return svec(s...)
end
inf_method_signature!(interp::InferenceBenchmarker, m::Method, @nospecialize(atype), sparams::SimpleVector; kwargs...) =
    inf_method_instance!(interp, specialize_method(m, atype, sparams)::MethodInstance; kwargs...)

function inf_method_instance!(interp::InferenceBenchmarker, mi::MethodInstance;
                              run_optimizer::Bool = true)
    result = InferenceResult(mi)
    frame = InferenceState(result, #=cache=# run_optimizer ? :global : :no, interp)::InferenceState
    typeinf(interp, frame)
    return frame
end

macro inf_call(ex0...)
    return InteractiveUtils.gen_call_with_extracted_types_and_kwargs(__module__, :inf_call, ex0)
end
function inf_call(@nospecialize(f), @nospecialize(types = Base.default_tt(f));
                  interp = InferenceBenchmarker(),
                  run_optimizer = true,
                  is_errorneous = false)
    ft = Typeof(f)
    if isa(types, Type)
        u = unwrap_unionall(types)
        tt = rewrap_unionall(Tuple{ft, u.parameters...}, types)
    else
        tt = Tuple{ft, types...}
    end
    frame = inf_gf_by_type!(interp, tt; run_optimizer)
    checkop = is_errorneous ? (===) : (!==)
    @assert checkop(frame.bestguess, Union{}) "invalid inference benchmark found"
    return frame
end

macro abs_call(ex0...)
    return InteractiveUtils.gen_call_with_extracted_types_and_kwargs(__module__, :abs_call, ex0)
end
function abs_call(@nospecialize(f), @nospecialize(types = Base.default_tt(f));
                  interp = InferenceBenchmarker(; optimize = false),
                  is_errorneous = false)
    return inf_call(f, types; interp, is_errorneous)
end

macro opt_call(ex0...)
    return InteractiveUtils.gen_call_with_extracted_types_and_kwargs(__module__, :opt_call, ex0)
end
function opt_call(@nospecialize(f), @nospecialize(types = Base.default_tt(f));
                  interp = InferenceBenchmarker(),
                  is_errorneous = false)
    frame = inf_call(f, types; interp, run_optimizer = false, is_errorneous)
    return function ()
        # `optimize` may modify these objects, so stash the pre-optimization states
        src, stmt_info = copy(frame.src), copy(frame.stmt_info)
        params = OptimizationParams(interp)
        opt = OptimizationState(frame, params, interp)
        optimize(interp, opt, params, frame.result)
        frame.src, frame.stmt_info = src, stmt_info
    end
end

function tune_benchmarks!(
    g::BenchmarkGroup;
    seconds=30,
    gcsample=true,
    )
    for v in values(g)
        v.params.seconds = seconds
        v.params.gcsample = gcsample
        v.params.evals = 1 # `setup` must be functional
    end
end

# "inference" benchmark targets
# =============================

# TODO add TTFP?
# XXX some targets below really depends on the compiler implementation itself
# (e.g. `abstract_call_gf_by_type`) and thus a bit more unreliable --  ideally
# we want to replace them with other functions that have the similar characteristics
# but whose call graph are orthogonal to the Julia's compiler implementation

using REPL
broadcasting(xs, x) = findall(>(x), abs.(xs))
let # check the compilation behavior for a function with lots of local variables
    # (where the sparse state management is critical to get a reasonable performance)
    # see https://github.com/JuliaLang/julia/pull/45276
    n = 10000
    ex = Expr(:block)
    var = gensym()
    push!(ex.args, :($var = x))
    for _ = 1:n
        newvar = gensym()
        push!(ex.args, :($newvar = $var + 1))
        var = newvar
    end
    @eval global function many_local_vars(x)
        $ex
    end
end
let # benchmark the performance benefit of `CachedMethodTable`
    # see https://github.com/JuliaLang/julia/pull/46535
    n = 100
    ex = Expr(:block)
    var = gensym()
    push!(ex.args, :(y = sum(x)))
    for i = 1:n
        push!(ex.args, :(x .= $(Float64(i))))
        push!(ex.args, :(y += sum(x)))
    end
    push!(ex.args, :(return y))
    @eval global function many_method_matches(x)
        $ex
    end
end
let # check the performance benefit of concrete evaluation
    param = 1000
    ex = Expr(:block)
    var = gensym()
    push!(ex.args, :($var = x))
    for _ = 1:param
        newvar = gensym()
        push!(ex.args, :($newvar = sin($var)))
        var = newvar
    end
    @eval let
        sins(x) = $ex
        global many_const_calls() = sins(42)
    end
end
# check the performance benefit of caching `GlobalRef`-lookup result
# see https://github.com/JuliaLang/julia/pull/46729
using Core.Intrinsics: add_int
const ONE = 1
@eval function many_global_refs(x)
    z = 0
    $([:(z = add_int(x, add_int(z, ONE))) for _ = 1:10000]...)
    return add_int(z, ONE)
end
strangesum(::Vector{Float64}) = error("this should not be called")
strangesum(x::AbstractArray) = sum(x)
let # check performance of invoke call handling
    n = 100
    ex = Expr(:block)
    var = gensym()
    push!(ex.args, :(y = sum(x)))
    for i = 1:n
        push!(ex.args, :(y += Base.@invoke strangesum(x::AbstractArray)))
    end
    push!(ex.args, :(return y))
    @eval global function many_invoke_calls(x)
        $ex
    end
end
import Base.Experimental: @opaque
let # check performance of opaque closure handling
    n = 100
    ex = Expr(:block)
    var = gensym()
    push!(ex.args, :(y = sum(x)))
    for i = 1:n
        push!(ex.args, :(oc = @inline @opaque (i, x, y) -> begin
            x .= Float64(i)
            y += sum(x)
        end))
        push!(ex.args, :(oc($i, x, y)))
    end
    push!(ex.args, :(return y))
    @eval global function many_opaque_closures(x)
        $ex
    end
end

const SUITE = BenchmarkGroup()

let g = addgroup!(SUITE, "abstract interpretation")
    g["sin(42)"] = @benchmarkable (@abs_call sin(42))
    g["rand(Float64)"] = @benchmarkable (@abs_call rand(Float64))
    g["println(::QuoteNode)"] = @benchmarkable (abs_call(println, (QuoteNode,)))
    g["broadcasting"] = @benchmarkable abs_call(broadcasting, (Vector{Float64},Float64))
    g["REPL.REPLCompletions.completions"] = @benchmarkable abs_call(
        REPL.REPLCompletions.completions, (String,Int))
    g["Base.init_stdio(::Ptr{Cvoid})"] = @benchmarkable abs_call(Base.init_stdio, (Ptr{Cvoid},))
    g["abstract_call_gf_by_type"] = @benchmarkable abs_call(CC.abstract_call_gf_by_type,
        # https://github.com/JuliaLang/julia/pull/46966
        @static if isdefined(CC, :StmtInfo)
            (NativeInterpreter,Any,CC.ArgInfo,CC.StmtInfo,Any,InferenceState,Int)
        else
            (NativeInterpreter,Any,CC.ArgInfo,Any,InferenceState,Int)
        end)
    g["construct_ssa!"] = @benchmarkable abs_call(CC.construct_ssa!, (Core.CodeInfo,CC.IRCode,CC.DomTree,Vector{CC.SlotInfo},Vector{Any}))
    g["domsort_ssa!"] = @benchmarkable abs_call(CC.domsort_ssa!, (CC.IRCode,CC.DomTree))
    g["many_local_vars"] = @benchmarkable abs_call(many_local_vars, (Int,))
    g["many_method_matches"] = @benchmarkable abs_call(many_method_matches, (Vector{Float64},))
    g["many_const_calls"] = @benchmarkable abs_call(many_const_calls)
    g["many_global_refs"] = @benchmarkable abs_call(many_global_refs, (Int,))
    g["many_invoke_calls"] = @benchmarkable abs_call(many_invoke_calls, (Vector{Float64},))
    g["many_opaque_closures"] = @benchmarkable abs_call(many_opaque_closures, (Vector{Float64},))
    tune_benchmarks!(g)
end

let g = addgroup!(SUITE, "optimization")
    g["sin(42)"] = @benchmarkable f() (setup = (f = @opt_call sin(42)))
    g["rand(Float64)"] = @benchmarkable f() (setup = (f = @opt_call rand(Float64)))
    g["println(::QuoteNode)"] = @benchmarkable f() (setup = (f = opt_call(println, (QuoteNode,))))
    g["broadcasting"] = @benchmarkable f() (setup = (f = opt_call(broadcasting, (Vector{Float64},Float64))))
    g["REPL.REPLCompletions.completions"] = @benchmarkable f() (setup = (f = opt_call(
        REPL.REPLCompletions.completions, (String,Int))))
    g["Base.init_stdio(::Ptr{Cvoid})"] = @benchmarkable f() (setup = (f = opt_call(Base.init_stdio, (Ptr{Cvoid},))))
    g["abstract_call_gf_by_type"] = @benchmarkable f() (setup = (f = opt_call(CC.abstract_call_gf_by_type,
        # https://github.com/JuliaLang/julia/pull/46966
        @static if isdefined(CC, :StmtInfo)
            (NativeInterpreter,Any,CC.ArgInfo,CC.StmtInfo,Any,InferenceState,Int)
        else
            (NativeInterpreter,Any,CC.ArgInfo,Any,InferenceState,Int)
        end)))
    g["construct_ssa!"] = @benchmarkable f() (setup = (f = opt_call(CC.construct_ssa!, (Core.CodeInfo,CC.IRCode,CC.DomTree,Vector{CC.SlotInfo},Vector{Any}))))
    g["domsort_ssa!"] = @benchmarkable f() (setup = (f = opt_call(CC.domsort_ssa!, (CC.IRCode,CC.DomTree))))
    g["many_local_vars"] = @benchmarkable f() (setup = (f = opt_call(many_local_vars, (Int,))))
    g["many_method_matches"] = @benchmarkable f() (setup = (f = opt_call(many_method_matches, (Vector{Float64},))))
    g["many_const_calls"] = @benchmarkable f() (setup = (f = opt_call(many_const_calls)))
    g["many_global_refs"] = @benchmarkable f() (setup = (f = opt_call(many_global_refs, (Int,))))
    g["many_invoke_calls"] = @benchmarkable f() (setup = (f = opt_call(many_invoke_calls, (Vector{Float64},))))
    g["many_opaque_closures"] = @benchmarkable f() (setup = (f = opt_call(many_opaque_closures, (Vector{Float64},))))
    tune_benchmarks!(g)
end

let g = addgroup!(SUITE, "allinference")
    g["sin(42)"] = @benchmarkable (@inf_call sin(42))
    g["rand(Float64)"] = @benchmarkable (@inf_call rand(Float64))
    g["println(::QuoteNode)"] = @benchmarkable (inf_call(println, (QuoteNode,)))
    g["broadcasting"] = @benchmarkable inf_call(broadcasting, (Vector{Float64},Float64))
    g["REPL.REPLCompletions.completions"] = @benchmarkable inf_call(
        REPL.REPLCompletions.completions, (String,Int))
    g["Base.init_stdio(::Ptr{Cvoid})"] = @benchmarkable inf_call(Base.init_stdio, (Ptr{Cvoid},))
    g["abstract_call_gf_by_type"] = @benchmarkable inf_call(CC.abstract_call_gf_by_type,
        # https://github.com/JuliaLang/julia/pull/46966
        @static if isdefined(CC, :StmtInfo)
            (NativeInterpreter,Any,CC.ArgInfo,CC.StmtInfo,Any,InferenceState,Int)
        else
            (NativeInterpreter,Any,CC.ArgInfo,Any,InferenceState,Int)
        end)
    g["construct_ssa!"] = @benchmarkable inf_call(CC.construct_ssa!, (Core.CodeInfo,CC.IRCode,CC.DomTree,Vector{CC.SlotInfo},Vector{Any}))
    g["domsort_ssa!"] = @benchmarkable inf_call(CC.domsort_ssa!, (CC.IRCode,CC.DomTree))
    g["many_local_vars"] = @benchmarkable inf_call(many_local_vars, (Int,))
    g["many_method_matches"] = @benchmarkable inf_call(many_method_matches, (Vector{Float64},))
    g["many_const_calls"] = @benchmarkable inf_call(many_const_calls)
    g["many_global_refs"] = @benchmarkable inf_call(many_global_refs, (Int,))
    g["many_invoke_calls"] = @benchmarkable inf_call(many_invoke_calls, (Vector{Float64},))
    g["many_opaque_closures"] = @benchmarkable inf_call(many_opaque_closures, (Vector{Float64},))
    tune_benchmarks!(g)
end

end # module InferenceBenchmarks
