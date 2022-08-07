module SortBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using StatsBase: sample
using UnitTestDesign: all_pairs
using Base.Order
using Random

SUITE = BenchmarkGroup()

#=
Benchmarked:

Various bitwidths (1-128)
Various types (Integer, floating point, char)
Many input orderings
Forward and reverse sorting
Mutating and nonmutating
partialsort
sortperm
lengths 1—6_572_799

Not yet benchmarked:

Nonuniform distributions
Highly uniform distributions
Collections of runs (e.g. ascending saw, descending saw)
Pathological input orders
Non isbits types
By and lt orders
Lengths greater than 6_572_799
=#

# Ways of constructing an interestingly ordered input vector
ascending(x, len) = sample(x, len, replace=false, ordered=true)
descending(x, len) = reverse!(sample(x, len, replace=false, ordered=true))
unique(f; n, len) = x -> rand(f(x, n), len)
exchanges(f; n, len) = x -> begin
    res = f(x, len)
    for _ in 1:n
        i, j = rand(eachindex(res), 2)
        res[i], res[j] = res[j], res[i]
    end
    res
end
random_prepended(f; n, len) = x -> begin
    res = f(x, len)
    for i in firstindex(res):min(lastindex(res), firstindex(res) + n - 1)
        j = rand(i:lastindex(res))
        res[i], res[j] = res[j], res[i]
    end
    res
end
random_appended(f; n, len) = x -> begin
    res = f(x, len)
    for i in lastindex(res):-1:max(firstindex(res), lastindex(res) - n + 1)
        j = rand(firstindex(res):i)
        res[i], res[j] = res[j], res[i]
    end
    res
end
unmodified(f; n, len) = x -> f(x, len)

function make!(suite, len, func, partial_target, rev, source, input_order_root, input_order_modifier, n_func)
    rough_len = len <= lens[length(lens) ÷ 3] ? "small" : len <= lens[length(lens) * 2 ÷ 3] ? "medium" : "large"
    kwrev = isempty(rev) ? () : (rev=true,)
    n = min(len, max(1, n_func(len)))
    sfunc = string(func)
    if rough_len == "large"
        input_order_name = "rand"
        setup = :(rand($source, $len))
    else
        if input_order_root == rand && input_order_modifier ∈ [exchanges, random_prepended, random_appended]
            input_order_modifier = unmodified
        end
        if input_order_modifier == unique && n == 1
            input_order_root = rand
        end
        input_order_name = (input_order_modifier == unmodified ? "$input_order_root" : "$input_order_root with $n $input_order_modifier")
        order = isempty(rev) ? Forward : Reverse

        generator = input_order_modifier(input_order_root; n, len)
        deck = decks[source]
        setup = :($generator($deck))
    end

    ix = if endswith(sfunc, "sortperm!")
        (randperm(len),)
    else () end

    partial = if startswith(sfunc, "partial")
        vals = [1, n, len-n+1, len]
        lo, hi = extrema(partial_target)
        ((lo == hi ? vals[lo] : (vals[lo]:vals[hi])),)
    else () end

    expr = :(@benchmarkable $func($ix..., x, $partial...; $kwrev...) setup=(x = $setup))
    endswith(sfunc, '!') && push!(expr.args, :(evals = 1))

    suite[len, rough_len, sfunc, input_order_name, rev...] = eval(expr)
end

lens = round.(Int, 1.303483 .^ (1:30) .^ 1.2)
sources = [Float64, Float32, Float16, Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128, 1:10, 1:100, 1:1000, 1:10_000, 1:100_000, Char, Bool]
decks = Dict([s => sort!(rand(s, 3lens[length(lens) * 2 ÷ 3])) for s in sources])

# Axes of the combinatorial combination
g = addgroup!(SUITE, "quick")
for (len, func, partial_target, rev, source, input_order_root, n_func) in all_pairs(
        lens,
        [sort, sort!, sortperm, partialsort],
        [1:2, 2:2],
        [(), ("rev",)],
        [Float64, Float32, Int16, Int64, Int128, UInt8, UInt32, UInt64, 1:10, 1:10_000],
        [rand, ascending],
        [_->4, len->len÷4])
    make!(g, len, func, partial_target, rev, source, input_order_root, unmodified, n_func)
end

g = addgroup!(SUITE, "full")
for (len, func, partial_target, rev, source, input_order_root, input_order_modifier, n_func) in all_pairs(
        lens,
        [sort, sort!, sortperm, sortperm!, partialsort, partialsort!, partialsortperm, partialsortperm!, issorted],
        [1:1, 1:2, 1:3, 1:4, 2:2, 2:3, 2:4, 3:3, 3:4, 4:4],
        [(), ("rev",)],
        sources,
        [rand, ascending, descending],
        [unmodified, unique, exchanges, random_prepended, random_appended],
        [_->1, _->4, _->20, len->len÷20, len->len÷4, identity])
    make!(g, len, func, partial_target, rev, source, input_order_root, input_order_modifier, n_func)
end

end # module
