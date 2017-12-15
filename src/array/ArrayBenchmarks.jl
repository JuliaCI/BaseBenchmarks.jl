module ArrayBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup()

#############################################################################
# basic array-math reduction-like functions

afloat = samerand(10^3)
aint = samerand(Int, 10^3)
acomplex = samerand(Complex{Float64}, 10^3)
g = addgroup!(SUITE, "reductions", ["sum", "array", "reduce"])
norm1(x) = norm(x, 1)
norminf(x) = norm(x, Inf)
perf_reduce(x) = reduce((x,y) -> x + 2y, real(zero(eltype(x))), x)
perf_mapreduce(x) = mapreduce(x -> real(x)+imag(x), (x,y) -> x + 2y, real(zero(eltype(x))), x)
for a in (afloat, aint)
    for fun in (sum, norm, norm1, norminf, mean, var, perf_reduce, perf_mapreduce)
        g[string(fun), string(eltype(a))] = @benchmarkable $fun($a)
    end
    g["sumabs2", string(eltype(a))] = @benchmarkable sum(abs2, $a)
    g["sumabs", string(eltype(a))] = @benchmarkable sum(abs, $a)
    g["maxabs", string(eltype(a))] = @benchmarkable maximum(abs, $a)
end

#############################################################################

############
# indexing #
############

# #10525 #
#--------#

include("sumindex.jl")

σ = 500
A3d = samerand(11,11,11)
S3d = view(A3d, 1:10, 1:10, 1:10)
arrays = (makearrays(Int32, σ, σ)..., makearrays(Float32, σ, σ)..., trues(σ, σ), A3d, S3d)
ranges = (1:10^5, 10^5:-1:1, 1.0:1e5, linspace(1,2,10^4))
arrays_iter = map(x -> (x, string(typeof(x))), arrays)
ranges_iter = map(x -> (x, repr(x)), ranges)
g = addgroup!(SUITE, "index", ["sum", "simd"])

for (A, str) in (arrays_iter..., ranges_iter...)
    g["sumelt", str]             = @benchmarkable perf_sumelt($A)
    g["sumelt_boundscheck", str] = @benchmarkable perf_sumelt_boundscheck($A)
    g["sumeach", str]            = @benchmarkable perf_sumeach($A)
    g["sumlinear", str]          = @benchmarkable perf_sumlinear($A)
    g["sumcartesian", str]       = @benchmarkable perf_sumcartesian($A)
    g["sumeach_view", str]       = @benchmarkable perf_sumeach_view($A)
    g["sumlinear_view", str]     = @benchmarkable perf_sumlinear_view($A)
    g["sumcartesian_view", str]  = @benchmarkable perf_sumcartesian_view($A)
    if ndims(A) == 2
        g["mapr_access", str]    = @benchmarkable perf_mapr_access($A, B, zz, n) setup = begin B, zz, n = setup_mapr_access($A) end #20517
    end
    if ndims(A) <= 2
        g["sumcolon", str]       = @benchmarkable perf_sumcolon($A)
        g["sumrange", str]       = @benchmarkable perf_sumrange($A)
        g["sumlogical", str]     = @benchmarkable perf_sumlogical($A)
        g["sumvector", str]      = @benchmarkable perf_sumvector($A)
        g["sumcolon_view", str]  = @benchmarkable perf_sumcolon_view($A)
        g["sumrange_view", str]  = @benchmarkable perf_sumrange_view($A)
        g["sumlogical_view", str]= @benchmarkable perf_sumlogical_view($A)
        g["sumvector_view", str] = @benchmarkable perf_sumvector_view($A)
    end
end
g["sub2ind"] = @benchmarkable perf_sub2ind((1000,1000,1000), 1:1000, 1:1000, 1:1000)
g["ind2sub"] = @benchmarkable perf_ind2sub((100,100,10), 1:10^5)
g["sum", "3darray"] = @benchmarkable sum($A3d)
g["sum", "3dsubarray"] = @benchmarkable sum($S3d)

for b in values(g)
    b.params.time_tolerance = 0.50
end


# #18774 #
#--------#
include("generate_kernel.jl")

nmax = 6  # maximum dimensionality is nmax + 1
# get path to current directory and append file name to it
fname = joinpath(dirname(@__FILE__), "hdindexing.jl")
make_stencil(fname, nmax)  # generate source file
include("hdindexing.jl")

npts_dir = [10000, 80, 20, 12, 9, 6]  # number of points in each direction
for i=1:nmax
  dims_vec = zeros(Int, i+1)
  fill!(dims_vec, npts_dir[i])
  dims_vec[end] = 2  # last dimension must be 2
  u_i = samerand(dims_vec...)
  u_ip1 = zeros(dims_vec...)

  str = string(i+1, "d")

  # perf_hdindexing is defined in the generated source file hdindexing.jl
  g[str] = @benchmarkable perf_hdindexing5($u_i, $u_ip1)
end




# #10301 #
#--------#

include("revloadindex.jl")

v = samerand(10^6)
n = samerand()

g = addgroup!(SUITE, "reverse", ["index", "fill!"])

g["rev_load_slow!"]    = @benchmarkable perf_rev_load_slow!(fill!($v, $n))
g["rev_load_fast!"]    = @benchmarkable perf_rev_load_fast!(fill!($v, $n))
g["rev_loadmul_slow!"] = @benchmarkable perf_rev_loadmul_slow!(fill!($v, $n), $v)
g["rev_loadmul_fast!"] = @benchmarkable perf_rev_loadmul_fast!(fill!($v, $n), $v)

# #9622 #
#-------#

perf_setindex!(A, val, inds) = setindex!(A, val, inds...)

g = addgroup!(SUITE, "setindex!", ["index"])

for s in (1, 2, 3, 4, 5)
    A = samerand(Float64, ntuple(one, s)...)
    y = one(eltype(A))
    i = length(A)
    g["setindex!", ndims(A)] = @benchmarkable perf_setindex!(fill!($A, $y), $y, $i)
end

###############################
# SubArray (views vs. copies) #
###############################

# LU factorization with complete pivoting. These functions deliberately allocate
# a lot of temprorary arrays by working on vectors instead of looping through
# the elements of the matrix. Both a view (SubArray) version and a copy version
# are provided.

include("subarray.jl")

n = samerand()

g = addgroup!(SUITE, "subarray", ["lucompletepiv"])

for s in (100, 250, 500, 1000)
    m = samerand(s, s)
    g["lucompletepivCopy!", s] = @benchmarkable perf_lucompletepivCopy!(fill!($m, $n))
    g["lucompletepivSub!", s]  = @benchmarkable perf_lucompletepivSub!(fill!($m, $n))
end

#################
# concatenation #
#################

include("cat.jl")

g = addgroup!(SUITE, "cat", ["index"])

for s in (5, 500)
    A = samerand(s, s)
    g["hvcat", s]        = @benchmarkable perf_hvcat($A, $A)
    g["hcat", s]         = @benchmarkable perf_hcat($A, $A)
    g["vcat", s]         = @benchmarkable perf_vcat($A, $A)
    g["catnd", s]        = @benchmarkable perf_catnd($s)
    g["hvcat_setind", s] = @benchmarkable perf_hvcat_setind($A, $A)
    g["hcat_setind", s]  = @benchmarkable perf_hcat_setind($A, $A)
    g["vcat_setind", s]  = @benchmarkable perf_vcat_setind($A, $A)
    g["catnd_setind", s] = @benchmarkable perf_catnd_setind($s)
end

############################
# in-place growth (#13977) #
############################

function perf_push_multiple!(collection, items)
    for item in items
        push!(collection, item)
    end
    return collection
end

g = addgroup!(SUITE, "growth", ["push!", "append!", "prepend!"])

for s in (8, 256, 2048)
    v = samerand(s)
    g["push_single!", s]   = @benchmarkable push!(x, samerand())       setup=(x = copy($v))
    g["push_multiple!", s] = @benchmarkable perf_push_multiple!(x, $v) setup=(x = copy($v))
    g["append!", s]        = @benchmarkable append!(x, $v)             setup=(x = copy($v))
    g["prerend!", s]       = @benchmarkable prepend!(x, $v)            setup=(x = copy($v))
end

##########################
# comprehension (#13401) #
##########################

perf_compr_collect(X) = [x for x in X]
perf_compr_iter(X) = [sin(x) + x^2 - 3 for x in X]
perf_compr_index(X) = [sin(X[i]) + (X[i])^2 - 3 for i in eachindex(X)]

ls = linspace(0,1,10^7)
rg = 0.0:(10.0^(-7)):1.0
arr = collect(ls)

g = addgroup!(SUITE, "comprehension", ["iteration", "index", "linspace", "collect", "range"])

for X in (ls, rg, arr)
    T = string(typeof(X))
    g["collect", T] = @benchmarkable collect($X)
    g["comprehension_collect", T]   = @benchmarkable perf_compr_collect($X)
    g["comprehension_iteration", T] = @benchmarkable perf_compr_iter($X)
    g["comprehension_indexing", T]  = @benchmarkable perf_compr_index($X) time_tolerance=0.30
end

###############################
# BoolArray/BitArray (#13946) #
###############################

function perf_bool_load!(result, a, b)
    for i in eachindex(result)
        result[i] = a[i] != b
    end
    return result
end

function perf_true_load!(result)
    for i in eachindex(result)
        result[i] = true
    end
    return result
end

n, range = 10^6, -3:3
a, b = samerand(range, n), samerand(range)

boolarr = Vector{Bool}(uninitialized, n)
if VERSION >= v"0.7.0-DEV.2687"
    bitarr = BitArray(uninitialized, n)
else
    bitarr = BitArray(n)
end

g = addgroup!(SUITE, "bool", ["index", "bitarray", "fill!"])

g["bitarray_bool_load!"]  = @benchmarkable perf_bool_load!($bitarr, $a, $b)
g["boolarray_bool_load!"] = @benchmarkable perf_bool_load!($boolarr, $a, $b)
g["bitarray_true_load!"]  = @benchmarkable perf_true_load!($bitarr)
g["boolarray_true_load!"] = @benchmarkable perf_true_load!($boolarr)
g["bitarray_true_fill!"]  = @benchmarkable fill!($bitarr, true)
g["boolarray_true_fill!"] = @benchmarkable fill!($boolarr, true)


####################################
# Float to Int conversion (#18954) #
####################################

function perf_convert!(a, x)
    for i=1:length(x)
        a[i] = x[i]
    end
    return a
end

x_int = rand(1:1000000,100,100)
x_float = 1.0 * x_int
x_complex = x_float .+ 0.0im

g = addgroup!(SUITE, "convert", ["Int"])
g["Int", "Float64"] = @benchmarkable  perf_convert!($x_int, $x_float)
g["Float64", "Int"] = @benchmarkable  perf_convert!($x_float, $x_int)
g["Complex{Float64}", "Int"] = @benchmarkable  perf_convert!($x_complex, $x_int)
g["Int", "Complex{Float64}"] = @benchmarkable  perf_convert!($x_int, $x_complex)


################
# == and isequal
################

x_range = 1:10_000
x_vec = collect(x_range)

g = addgroup!(SUITE, "equality", ["==", "isequal"])

# Only test cases which do not short-circuit, else performance
# depends too much on the data
for x in (x_range, x_vec, Int16.(x_range), Float64.(x_range), Float32.(x_range))
    g["==", string(typeof(x))] = @benchmarkable $x == $(copy(x))
    g["isequal", string(typeof(x))] = @benchmarkable isequal($x, $(copy(x)))

    g["==", string(typeof(x_vec), " == ", typeof(x))] =
        @benchmarkable $x_vec == $x
    g["isequal", string(typeof(x_vec), " isequal ", typeof(x))] =
        @benchmarkable isequal($x_vec, $x)
end

x_bool = fill(false, 10_000)
x_bitarray = falses(10_000)
g["==", "Vector{Bool}"] = @benchmarkable $x_bool == $(copy(x_bool))
g["isequal", "Vector{Bool}"] = @benchmarkable isequal($x_bool, $(copy(x_bool)))
g["==", "BitArray"] = @benchmarkable $x_bitarray == $(copy(x_bitarray))
g["isequal", "BitArray"] = @benchmarkable isequal($x_bitarray, $(copy(x_bitarray)))

###########
# any & all
###########

x_false = fill(false, 10_000)
x_true = fill(true, 10_000)

g = addgroup!(SUITE, "any/all", ["any", "all"])

# Only test cases which do not short-circuit, else performance
# depends too much on the data
g["any", "Vector{Bool}"] = @benchmarkable any($x_false)
g["all", "Vector{Bool}"] = @benchmarkable all($x_true)
g["any", "BitArray"] = @benchmarkable any($(BitArray(x_false)))
g["all", "BitArray"] = @benchmarkable all($(BitArray(x_true)))

x_range = 1:10_000
for x in (x_range, collect(x_range), Int16.(x_range), Float64.(x_range), Float32.(x_range))
    g["any", string(typeof(x))] = @benchmarkable any(v -> v < 0, $x)
    g["all", string(typeof(x))] = @benchmarkable all(v -> v > 0, $x)

    gen = (xi for xi in x)
    g["any", string(typeof(x), " generator")] = @benchmarkable any(v -> v < 0, $gen)
    g["all", string(typeof(x), " generator")] = @benchmarkable all(v -> v > 0, $gen)
end

end # module
