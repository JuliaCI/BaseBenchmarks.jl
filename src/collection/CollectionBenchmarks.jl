module CollectionBenchmarks

using BenchmarkTools
using Compat

# TODO: Remove once Compat has BitSet
if !isdefined(Base, :BitSet)
    const BitSet = IntSet
end

const SUITE = BenchmarkGroup()

const MT = MersenneTwister(0)

const iterlen = 1000
const ints = rand(MT, 1:iterlen, iterlen)
const strings = [randstring(MT, rand(MT, 1:30)) for i in 1:iterlen]
const anys = (shuffle!(MT, [ints; strings;])[1:iterlen])::Vector{Any}
const sortedints = sort(ints)

# random element, in the collections iff 2nd parameter is true
let anyshuffled = shuffle(MT, anys),
    filter = VERSION >= v"0.5.0" ? Iterators.filter : Base.filter
    d = Dict((Int,    true ) => first(filter(i->isa(i, Int),    anyshuffled))::Int,
             (String, true ) => first(filter(i->isa(i, String), anyshuffled))::String,
             (Int,    false) => first(filter(i->!in(i, ints), rand(MT, 1:iterlen) for _ in 1:typemax(Int)))::Int,
             (String, false) => randstring(MT, 40)::String)
    global randelt
    randelt(C, T, bool) = (T == Any && (T = Int); C === Dict ? (d[T, bool] => d[T, bool]) : d[T, bool])
end

const coll = Dict((Vector, Int)    => ints,
                  (Vector, String) => strings,
                  (Vector, Any)    => anys,
                  (Pair, Int)      => map(Pair, ints, ints),
                  (Pair, String)   => map(Pair, strings, strings),
                  (Pair, Any)      => map(Pair, anys, anys),
                  (BitSet, Int)    => BitSet(ints))

# return a collection that can serve to initialize a container C of type T
initcoll(C, T) = let initmap = Dict(Vector => Vector,
                                    Dict   => Pair,
                                    Set    => Vector,
                                    BitSet => Vector)
    coll[initmap[C], T]
end

for C in (Dict, Set),
        T in (Int, String, Any)
    coll[C, T] = C(initcoll(C, T))
end

@inline newcoll(::Type{C}, ::Type{T}) where {C,T} = C{T}()
@inline newcoll(::Type{Dict}, ::Type{T}) where {T} = Dict{T,T}()
@inline newcoll(::Type{BitSet}, ::Type{Int}) = BitSet()

askey(::Type, elt) = elt
askey(::Type{Dict}, elt) = first(elt)

objstr(T) = T === Int ? "Int" : T === Vector ? "Vector" : string(T)

function foreach_container(bench; T = (Int, String, Any), C = (Vector, Dict, Set, BitSet))
    for _C in C
        cstr = objstr(_C)
        for _T in T
            _C === BitSet && _T !== Int && continue
            c = coll[_C, _T]
            bench(_C, cstr, _T, objstr(_T), c)
        end
    end
end

function set_tolerance!(g, tol=0.25)
    for b in values(g)
        b.params.time_tolerance = tol
    end
end

##################
# Initialization #
##################

g = addgroup!(SUITE, "initialization", ["AbstractVector", "AbstractSet", "Associative"])

function perf_push!(c, elts)
    for e in elts
        push!(c, e)
    end
end

foreach_container(C = (Vector, Dict, Set)) do C, cstr, T, tstr, c
    g[cstr, tstr, "iterator"] = @benchmarkable $C($(initcoll(C, T)))
    g[cstr, tstr, "loop"]     = @benchmarkable perf_push!(newcoll($C, $T), $(initcoll(C, T)))
    g[cstr, tstr, "loop", "sizehint!"] =
        @benchmarkable perf_push!(sizehint!(newcoll($C, $T), iterlen), $(initcoll(C, T)))
end

g["BitSet", "Int", "unsorted", "iterator"]          = @benchmarkable BitSet($ints)
g["BitSet", "Int", "sorted",   "iterator"]          = @benchmarkable BitSet($sortedints)
g["BitSet", "Int", "unsorted", "loop"]              = @benchmarkable perf_push!(BitSet(), $ints)
g["BitSet", "Int", "sorted",   "loop"]              = @benchmarkable perf_push!(BitSet(), $sortedints)
g["BitSet", "Int", "unsorted", "loop", "sizehint!"] = @benchmarkable perf_push!(sizehint!(BitSet(), iterlen), $ints)
g["BitSet", "Int", "sorted",   "loop", "sizehint!"] = @benchmarkable perf_push!(sizehint!(BitSet(), iterlen), $sortedints)

set_tolerance!(g)

#############
# Iteration #
#############

g = addgroup!(SUITE, "iteration", ["AbstractVector", "AbstractSet", "Associative"])

foreach_container() do C, cstr, T, tstr, c
    g[cstr, tstr, "start"] = @benchmarkable start($c)
    g[cstr, tstr, "next"]  = @benchmarkable next($c, $(start(c)))
    g[cstr, tstr, "done"]  = @benchmarkable done($c, $(start(c)))
end

set_tolerance!(g)

############
# Deletion #
############

g = addgroup!(SUITE, "deletion", ["AbstractVector", "AbstractSet", "Associative"])

function perf_pop!(c)
    while !isempty(c)
        pop!(c)
    end
end

pred(::Type{C}, ::Type{Any})    where {C} = x -> isa(askey(C, x), Int)
pred(::Type{C}, ::Type{String}) where {C} = x -> Int(askey(C, x)[1]) < 90
pred(::Type{C}, ::Type{Int})    where {C} = x -> iseven(askey(C, x))

foreach_container() do C, cstr, T, tstr, c
    if VERSION >= v"0.7.0-" || C !== Dict
        g[cstr, tstr, "pop!"] = @benchmarkable perf_pop!(d) setup=(d=copy($c)) evals=1
    end
    C === BitSet && return
    if VERSION >= v"0.7.0-" || C !== Dict
        g[cstr, tstr, "filter!"] = @benchmarkable filter!($(pred(C, T)), d) setup=(d=copy($c)) evals=1
        g[cstr, tstr, "filter"] =  @benchmarkable filter( $(pred(C, T)), $c)
    end
end

set_tolerance!(g)

#####################
# Queries & Updates #
#####################

g = addgroup!(SUITE, "queries & updates", ["AbstractVector", "AbstractSet", "Associative"])

foreach_container() do C, cstr, T, tstr, c
    if T === Int # seems unnecessary to run those with all types
        g[cstr, tstr, "length"] = @benchmarkable length($c) # probably useful only for BitSet
        g[cstr, tstr, "first"]  = @benchmarkable first($c)
        if C in (Vector, BitSet)
            g[cstr, tstr, "last"] = @benchmarkable last($c)
        end
    end
    eltin, eltout = randelt(C, T, true), randelt(C, T, false)
    g[cstr, tstr, "in", "true"]  = @benchmarkable in($eltin, $c)
    g[cstr, tstr, "in", "false"] = @benchmarkable in($eltout, $c)
    if C === Vector
        g[cstr, tstr, "getindex"]  = @benchmarkable $c[$(iterlen÷2)]
        g[cstr, tstr, "setindex!"] = @benchmarkable d[$(iterlen÷2)] = $eltout setup=(d=copy($c))
    elseif C === Dict
        keyin  = askey(C, eltin)
        keyout = askey(C, eltout)
        g[cstr, tstr, "getindex"]               = @benchmarkable $c[$keyin]
        g[cstr, tstr, "setindex!", "overwrite"] = @benchmarkable d[$keyin]  = $keyout setup=(d=copy($c))
        g[cstr, tstr, "setindex!", "new"]       = @benchmarkable d[$keyout] = $keyout setup=(d=copy($c)) evals=1
    end
    if C === Vector
        g[cstr, tstr, "push!"] = @benchmarkable push!(d, $eltout) setup=(d=copy($c))
    else
        g[cstr, tstr, "push!", "overwrite"] = @benchmarkable push!(d, $eltin)             setup=(d=copy($c))
        g[cstr, tstr, "push!", "new"]       = @benchmarkable push!(d, $eltout)            setup=(d=copy($c)) evals=1
        # despite the `evals=1` parameter, this gets evaluated more than once, leading to a KeyError
        # g[cstr, tstr, "pop!",  "specified"] = @benchmarkable  pop!(d, $(askey(C, eltin))) setup=(d=copy($c)) evals=1
        # so we add a push!
        g[cstr, tstr, "pop!",  "specified"] = @benchmarkable  pop!(push!(d, $eltin), $(askey(C, eltin))) setup=(d=copy($c))

    end
    if C !== Dict || VERSION >= v"0.7.0-"
        # same remark as above, we need to push! a value to avoid ending up with an empty container
        g[cstr, tstr, "pop!", "unspecified"] = @benchmarkable push!(d, pop!(d)) setup=(d=copy($c))
    end
end

set_tolerance!(g)

##################
# Set operations #
##################

g = addgroup!(SUITE, "set operations", ["AbstractSet", "Array"])
const newints = [rand(MT, ints, 10); rand(MT, 1:iterlen, 10); rand(MT, iterlen:2iterlen, 10);]

foreach_container(C = (BitSet, Set, Vector), T = (Int,)) do C, cstr, T, tstr, c
    g[cstr, tstr, "union"]     = @benchmarkable union($c)
    g[cstr, tstr, "intersect"] = @benchmarkable intersect($c)
    g[cstr, tstr, "symdiff"]   = @benchmarkable symdiff($c)
    for C2 in (BitSet, Set, Vector)
        c2 = C2(newints)
        c2str = objstr(C2)
        g[cstr, tstr, "union",     c2str] = @benchmarkable union($c, $c2)
        g[cstr, tstr, "intersect", c2str] = @benchmarkable intersect($c, $c2)
        g[cstr, tstr, "symdiff",   c2str] = @benchmarkable symdiff($c, $c2)
        g[cstr, tstr, "setdiff",   c2str] = @benchmarkable setdiff($c, $c2)

        g[cstr, tstr, "union", c2str, c2str]     = @benchmarkable union($c, $c2, $c2)
        g[cstr, tstr, "intersect", c2str, c2str] = @benchmarkable intersect($c, $c2, $c2)
        g[cstr, tstr, "symdiff", c2str, c2str]   = @benchmarkable symdiff($c, $c2, $c2)

        if C === BitSet && C2 === BitSet
            g[cstr, tstr, "intersect!", c2str] = @benchmarkable intersect!(d, $c2) setup=(d=copy($c)) evals=1
        end
        if C === BitSet
            g[cstr, tstr, "symdiff!",   c2str] = @benchmarkable symdiff!(d, $c2)   setup=(d=copy($c)) evals=1
        end
        if C in (BitSet, Set)
            g[cstr, tstr, "setdiff!",   c2str] = @benchmarkable setdiff!(d, $c2)   setup=(d=copy($c)) evals=1
            g[cstr, tstr, "union!",     c2str] = @benchmarkable union!(d, $c2)     setup=(d=copy($c)) evals=1
        end
        g[cstr, tstr, "⊆", c2str] = @benchmarkable ⊆($c, $c2)
    end
    C === Vector && return
    empty = newcoll(C, Int)
    c2  = C(newints)
    g[cstr,    tstr, "<",  cstr]   = @benchmarkable <($c, $c2)
    g["empty", tstr, "<",  cstr]   = @benchmarkable <($empty, $c)
    g["empty", tstr, "⊆",  cstr]   = @benchmarkable ⊆($empty, $c)
    g[cstr,    tstr, "⊆",  "self"] = @benchmarkable ⊆($c, $c)
    g[cstr,    tstr, "==", cstr]   = @benchmarkable ==($c, $c2)
    g[cstr,    tstr, "==", "self"] = @benchmarkable ==($c, $c)
end

# test BitSet with very large values
const small, big = BitSet(2), BitSet(2^18)
g["BitSet", "Int", "union!",     "big"]   = @benchmarkable union!(b, $small)     setup=(b=BitSet(2^18)) evals=1
g["BitSet", "Int", "union!",     "small"] = @benchmarkable union!(s, $big)       setup=(s=BitSet(2))    evals=1
g["BitSet", "Int", "intersect!", "big"]   = @benchmarkable intersect!(b, $small) setup=(b=BitSet(2^18)) evals=1
g["BitSet", "Int", "intersect!", "small"] = @benchmarkable intersect!(s, $big)   setup=(s=BitSet(2))    evals=1
g["BitSet", "Int", "setdiff!",   "big"]   = @benchmarkable setdiff!(b, $small)   setup=(b=BitSet(2^18)) evals=1
g["BitSet", "Int", "setdiff!",   "small"] = @benchmarkable setdiff!(s, $big)     setup=(s=BitSet(2))    evals=1
g["BitSet", "Int", "symdiff!",   "big"]   = @benchmarkable symdiff!(b, $small)   setup=(b=BitSet(2^18)) evals=1
g["BitSet", "Int", "symdiff!",   "small"] = @benchmarkable symdiff!(s, $big)     setup=(s=BitSet(2))    evals=1

set_tolerance!(g)

#############################################
# Optimizations for types with "few" values #
#############################################

# cf. issue #20903 and PR #21964
g = addgroup!(SUITE, "optimizations", ["Dict", "Set", "BitSet", "Vector"])

for T in (Nothing, Bool, Int8, UInt16)
    local v
    v::Vector{T} = T === Nothing ? Vector{Nothing}(100000) :
                                   rand(MT, one(T):typemax(T), 100000)
    tstr = string(T)
    g["Dict", "abstract", tstr] = @benchmarkable Dict($(map(Pair, v, v)))
    g["Dict", "concrete", tstr] = @benchmarkable Dict{$T,$T}($(map(Pair, v, v)))
    g["Set",  "abstract", tstr] = @benchmarkable Set($v)
    g["Set",  "concrete", tstr] = @benchmarkable Set{$T}($v)
    if T === Nothing
        g["Vector", "abstract", tstr] = @benchmarkable Vector($v)
        g["Vector", "concrete", tstr] = @benchmarkable Vector{$T}($v)
    elseif T !== Bool && (!(T <: Unsigned) || VERSION >= v"0.7.0-")
        # there is a bug on 0.6, will probably get fixed on v6.2, cf. #24365
        g["BitSet", tstr] = @benchmarkable BitSet($v)
    end
end

set_tolerance!(g)

end # module
