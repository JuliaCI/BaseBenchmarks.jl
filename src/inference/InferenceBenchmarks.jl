"""
    "inference" => InferenceBenchmarks

Defines a benchmark suite for Julia-level compilation pipeline.
Note that this benchmark suite is only available for Julia 1.8 and higher.

This benchmark group `"inference"` is composed of the following subgroups:
- `"inference"`: benchmarks the overall Julia-level compilation pipeline per each static call
- `"abstract interpretation"`: benchmarks abstract interpretation per each static call (without optimization)
- `"optimization"`: benchmarks optimization passes applied per a single call frame
"""
module InferenceBenchmarks

using BenchmarkTools, InteractiveUtils

const CC = Core.Compiler

import .CC:
    may_optimize, may_compress, may_discard_trees, InferenceParams,  OptimizationParams,
    get_world_counter, get_inference_cache, code_cache, # get, getindex, haskey, setindex!
    nothing
import Core:
    MethodInstance, CodeInstance, MethodMatch, SimpleVector, Typeof
import .CC:
    AbstractInterpreter, NativeInterpreter, WorldRange, WorldView, InferenceResult,
    InferenceState, OptimizationState,
    _methods_by_ftype, specialize_method, unwrap_unionall, rewrap_unionall, widenconst,
    typeinf, optimize

struct InferenceBenchmarkerCache
    dict::IdDict{MethodInstance,CodeInstance}
end
struct InferenceBenchmarker <: AbstractInterpreter
    native::NativeInterpreter
    optimize::Bool
    compress::Bool
    discard_trees::Bool
    cache::InferenceBenchmarkerCache
    function InferenceBenchmarker(
        world::UInt = get_world_counter();
        inf_params::InferenceParams = InferenceParams(),
        opt_params::OptimizationParams = OptimizationParams(),
        optimize::Bool = true,
        compress::Bool = true,
        discard_trees::Bool = true,
        cache::InferenceBenchmarkerCache = InferenceBenchmarkerCache(IdDict{MethodInstance,CodeInstance}()),
        )
        native = NativeInterpreter(world; inf_params, opt_params)
        new(native, optimize, compress, discard_trees, cache)
    end
end

CC.may_optimize(interp::InferenceBenchmarker) = interp.optimize
CC.may_compress(interp::InferenceBenchmarker) = interp.compress
CC.may_discard_trees(interp::InferenceBenchmarker) = interp.discard_trees
CC.InferenceParams(interp::InferenceBenchmarker) = InferenceParams(interp.native)
CC.OptimizationParams(interp::InferenceBenchmarker) = OptimizationParams(interp.native)
CC.get_world_counter(interp::InferenceBenchmarker) = get_world_counter(interp.native)
CC.get_inference_cache(interp::InferenceBenchmarker) = get_inference_cache(interp.native)
CC.code_cache(interp::InferenceBenchmarker) = WorldView(interp.cache, WorldRange(get_world_counter(interp)))
CC.get(wvc::WorldView{<:InferenceBenchmarkerCache}, mi::MethodInstance, default) = get(wvc.cache.dict, mi, default)
CC.getindex(wvc::WorldView{<:InferenceBenchmarkerCache}, mi::MethodInstance) = getindex(wvc.cache.dict, mi)
CC.haskey(wvc::WorldView{<:InferenceBenchmarkerCache}, mi::MethodInstance) = haskey(wvc.cache.dict, mi)
CC.setindex!(wvc::WorldView{<:InferenceBenchmarkerCache}, ci::CodeInstance, mi::MethodInstance) = setindex!(wvc.cache.dict, ci, mi)

function inf_gf_by_type!(interp::InferenceBenchmarker, @nospecialize(tt::Type{<:Tuple}); kwargs...)
    mm = get_single_method_match(tt, InferenceParams(interp).MAX_METHODS, get_world_counter(interp))
    return inf_method_signature!(interp, mm.method, mm.spec_types, mm.sparams; kwargs...)
end

function get_single_method_match(@nospecialize(tt), lim, world)
    mms = _methods_by_ftype(tt, lim, world)
    isa(mms, Bool) && error("unable to find matching method for $(tt)")
    filter!(mm::MethodMatch->mm.spec_types===tt, mms)
    length(mms) == 1 || error("unable to find single target method for $(tt)")
    return first(mms)::MethodMatch
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
function inf_call(@nospecialize(f), @nospecialize(types = Tuple{});
                  interp = InferenceBenchmarker(),
                  run_optimizer = true)
    ft = Typeof(f)
    if isa(types, Type)
        u = unwrap_unionall(types)
        tt = rewrap_unionall(Tuple{ft, u.parameters...}, types)
    else
        tt = Tuple{ft, types...}
    end
    return inf_gf_by_type!(interp, tt; run_optimizer)
end

macro abs_call(ex0...)
    return InteractiveUtils.gen_call_with_extracted_types_and_kwargs(__module__, :abs_call, ex0)
end
function abs_call(@nospecialize(f), @nospecialize(types = Tuple{});
                  interp = InferenceBenchmarker(; optimize = false))
    return inf_call(f, types; interp)
end

macro opt_call(ex0...)
    return InteractiveUtils.gen_call_with_extracted_types_and_kwargs(__module__, :opt_call, ex0)
end
function opt_call(@nospecialize(f), @nospecialize(types = Tuple{});
                  interp = InferenceBenchmarker())
    frame = inf_call(f, types; interp, run_optimizer = false)
    return function ()
        params = OptimizationParams(interp)
        opt = OptimizationState(frame, params, interp)
        optimize(interp, opt, params, frame.result)
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

const SUITE = BenchmarkGroup()

# TODO add TTFP?

let g = addgroup!(SUITE, "abstract interpretation")
    g["sin(42)"] = @benchmarkable (@abs_call sin(42))
    g["rand(Float64)"] = @benchmarkable (@abs_call rand(Float64))
    g["println(::QuoteNode)"] = @benchmarkable (abs_call(println, (QuoteNode,)))
    g["abstract_call_gf_by_type"] = @benchmarkable abs_call(
        CC.abstract_call_gf_by_type, (NativeInterpreter,Any,CC.ArgInfo,Any,InferenceState,Int))
    g["construct_ssa!"] = @benchmarkable abs_call(CC.construct_ssa!, (Core.CodeInfo,CC.IRCode,CC.DomTree,Vector{CC.SlotInfo},Vector{Any}))
    g["domsort_ssa!"] = @benchmarkable abs_call(CC.domsort_ssa!, (CC.IRCode,CC.DomTree))
    tune_benchmarks!(g)
end

let g = addgroup!(SUITE, "optimization")
    g["sin(42)"] = @benchmarkable f() (setup = (f = @opt_call sin(42)))
    g["rand(Float64)"] = @benchmarkable f() (setup = (f = @opt_call rand(Float64)))
    g["println(::QuoteNode)"] = @benchmarkable f() (setup = (f = opt_call(println, (QuoteNode,))))
    g["abstract_call_gf_by_type"] = @benchmarkable f() (setup = (f = opt_call(CC.abstract_call_gf_by_type, (NativeInterpreter,Any,CC.ArgInfo,Any,InferenceState,Int))))
    g["construct_ssa!"] = @benchmarkable f() (setup = (f = opt_call(CC.construct_ssa!, (Core.CodeInfo,CC.IRCode,CC.DomTree,Vector{CC.SlotInfo},Vector{Any}))))
    g["domsort_ssa!"] = @benchmarkable f() (setup = (f = opt_call(CC.domsort_ssa!, (CC.IRCode,CC.DomTree))))
    tune_benchmarks!(g)
end

let g = addgroup!(SUITE, "inference")
    g["sin(42)"] = @benchmarkable (@inf_call sin(42))
    g["rand(Float64)"] = @benchmarkable (@inf_call rand(Float64))
    g["println(::QuoteNode)"] = @benchmarkable (inf_call(println, (QuoteNode,)))
    g["abstract_call_gf_by_type"] = @benchmarkable inf_call(
        CC.abstract_call_gf_by_type, (NativeInterpreter,Any,CC.ArgInfo,Any,InferenceState,Int))
    g["construct_ssa!"] = @benchmarkable inf_call(CC.construct_ssa!, (Core.CodeInfo,CC.IRCode,CC.DomTree,Vector{CC.SlotInfo},Vector{Any}))
    g["domsort_ssa!"] = @benchmarkable inf_call(CC.domsort_ssa!, (CC.IRCode,CC.DomTree))
    tune_benchmarks!(g)
end

end # module InferenceBenchmarks
