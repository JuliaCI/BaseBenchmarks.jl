module RandUtils

using Random
using StableRNGs
using SparseArrays
using BenchmarkTools

samerand(args...) = rand(StableRNG(1), args...)
samesprand(args...) = sprand(StableRNG(1), args...)

samesprandbool(args...) = sprand(StableRNG(1), Bool, args...)

samerandstring(n) = randstring(StableRNG(1), n)

randvec(T, n) = samerand(T, n)
randvec(n) = samerand(n)

randmat(T, n) = samerand(T, n, n)
randmat(n) = samerand(n, n)

const RESHUFFLE_RNG = StableRNG(2)

# One permutation for all arrays, so that their elements stay paired up.
function reshuffle!(xs...)
    p = randperm(RESHUFFLE_RNG, length(first(xs)))
    foreach(x -> permute!(x, p), xs)
end

"""
    @benchmarkable_reshuffled x ex
    @benchmarkable_reshuffled (x, y, ...) ex

`@benchmarkable ex` for a benchmark whose branches depend on the random contents of the
arrays `x, y, ...`, which `ex` uses as `\$x`. The benchmark gets private copies of them,
permuted in place (all with the same permutation) before every evaluation (`evals=1`).

With the same input in every sample, the branch predictor learns the input's branch pattern
across samples: AMD Zen 5 learns patterns of tens of thousands of branches. The timing then
depends on whether a given code layout lets it do so, and unrelated codegen changes show up
as large regressions or improvements.
"""
macro benchmarkable_reshuffled(xs, ex)
    vars = Meta.isexpr(xs, :tuple) ? xs.args : [xs]
    copies = [:($v = copy($v)) for v in vars]
    setup = Expr(:call, reshuffle!, (Expr(:$, v) for v in vars)...)
    bench = Expr(:macrocall, var"@benchmarkable", __source__, ex,
                 Expr(:(=), :setup, setup), Expr(:(=), :evals, 1))
    return esc(Expr(:let, Expr(:block, copies...), bench))
end

"""
    @benchmarkable_reshuffled_if cond xs ex

`@benchmarkable_reshuffled xs ex` if `cond` is true, and `@benchmarkable ex` otherwise.
"""
macro benchmarkable_reshuffled_if(cond, xs, ex)
    reshuffled = Expr(:macrocall, GlobalRef(@__MODULE__, Symbol("@benchmarkable_reshuffled")),
                      __source__, xs, ex)
    plain = Expr(:macrocall, GlobalRef(BenchmarkTools, Symbol("@benchmarkable")), __source__, ex)
    return esc(:($cond ? $reshuffled : $plain))
end

export samerand, samesprand, samesprandbool, samerandstring, randvec, randmat, StableRNGs,
       @benchmarkable_reshuffled, @benchmarkable_reshuffled_if

end
