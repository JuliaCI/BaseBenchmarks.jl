module ArrayBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools

const SUITE = BenchmarkGroup()

using LinearAlgebra
using Statistics

#############################################################################
# basic array-math reduction-like functions

getafloat() = samerand(10^3)
getaint() = samerand(Int, 10^3)
getacomplex() = samerand(Complex{Float64}, 10^3)

g = addgroup!(SUITE, "reductions", ["sum", "array", "reduce"])
norm1(x) = norm(x, 1)
norminf(x) = norm(x, Inf)
perf_reduce(x) = reduce((x,y) -> x + 2y, x; init=real(zero(eltype(x))))
perf_mapreduce(x) = mapreduce(x -> real(x)+imag(x), (x,y) -> x + 2y, x; init=real(zero(eltype(x))))
for geta in (getafloat, getaint)
    a = geta()
    for fun in (sum, norm, norm1, norminf, mean, perf_reduce, perf_mapreduce)
        g[string(fun), string(eltype(a))] = @benchmarkable $fun(a) setup=(a=$geta())
    end
    g["sumabs2", string(eltype(a))] = @benchmarkable sum(abs2, a) setup=(a=$geta())
    g["sumabs", string(eltype(a))] = @benchmarkable sum(abs, a) setup=(a=$geta())
    g["maxabs", string(eltype(a))] = @benchmarkable maximum(abs, a) setup=(a=$geta())
end

#############################################################################

############
# indexing #
############

# #10525 #
#--------#

include("sumindex.jl")

g = addgroup!(SUITE, "index", ["sum", "simd"])
const σ = 500
let nint32 = makearrays(Int32, σ, σ, 0)::Int,
    nfloat32 = makearrays(Float32, σ, σ, 0)::Int,
    ranges = (1:10^5, 10^5:-1:1, 1.0:1e5, range(1, stop=2, length=10^4)),
    ntotal = 4 + nint32 + nfloat32 + length(ranges)
    function getarray(i)
        (i <= nint32) && return makearrays(Int32, σ, σ, i)
        i -= nint32
        (i <= nfloat32) && return makearrays(Float32, σ, σ, i)
        i -= nfloat32
        ((i -= 1) == 0) && return trues(σ, σ)
        A3d = samerand(11,11,11)
        ((i -= 1) == 0) && return A3d
        ((i -= 1) == 0) && return view(A3d, 1:10, 1:10, 1:10)
        ((i -= 1) == 0) && return reinterpret(Int32, A3d)  # half-size, no fields
        return ranges[i]
    end
    for i = 1:ntotal
        A = getarray(i)
        str = A isa AbstractRange ? repr(A) : string(typeof(A))
        g["sumelt", str]             = @benchmarkable perf_sumelt(A) setup=(A=$getarray($i))
        g["sumelt_boundscheck", str] = @benchmarkable perf_sumelt_boundscheck(A) setup=(A=$getarray($i))
        g["sumeach", str]            = @benchmarkable perf_sumeach(A) setup=(A=$getarray($i))
        g["sumlinear", str]          = @benchmarkable perf_sumlinear(A) setup=(A=$getarray($i))
        g["sumcartesian", str]       = @benchmarkable perf_sumcartesian(A) setup=(A=$getarray($i))
        g["sumeach_view", str]       = @benchmarkable perf_sumeach_view(A) setup=(A=$getarray($i))
        g["sumlinear_view", str]     = @benchmarkable perf_sumlinear_view(A) setup=(A=$getarray($i))
        g["sumcartesian_view", str]  = @benchmarkable perf_sumcartesian_view(A) setup=(A=$getarray($i))
        if ndims(A) == 2
            g["mapr_access", str]    = @benchmarkable perf_mapr_access(A, B, zz, n) setup = begin
                A = $getarray($i)
                B, zz, n = setup_mapr_access(A) #20517
            end
        end
        if ndims(A) <= 2
            g["sumcolon", str]       = @benchmarkable perf_sumcolon(A) setup=(A=$getarray($i))
            g["sumrange", str]       = @benchmarkable perf_sumrange(A) setup=(A=$getarray($i))
            g["sumlogical", str]     = @benchmarkable perf_sumlogical(A) setup=(A=$getarray($i))
            g["sumvector", str]      = @benchmarkable perf_sumvector(A) setup=(A=$getarray($i))
            g["sumcolon_view", str]  = @benchmarkable perf_sumcolon_view(A) setup=(A=$getarray($i))
            g["sumrange_view", str]  = @benchmarkable perf_sumrange_view(A) setup=(A=$getarray($i))
            g["sumlogical_view", str]= @benchmarkable perf_sumlogical_view(A) setup=(A=$getarray($i))
            g["sumvector_view", str] = @benchmarkable perf_sumvector_view(A) setup=(A=$getarray($i))
        end
    end
end
g["sub2ind"] = @benchmarkable perf_sub2ind((1000,1000,1000), 1:1000, 1:1000, 1:1000)
g["ind2sub"] = @benchmarkable perf_ind2sub((100,100,10), 1:10^5)
g["sum", "3darray"] = @benchmarkable sum(A3d) setup=(A3d=samerand(11,11,11))
g["sum", "3dsubarray"] = @benchmarkable sum(S3d) setup=(A3d=samerand(11,11,11); S3d=view(A3d, 1:10, 1:10, 1:10))

for b in values(g)
    b.params.time_tolerance = 0.50
end


# #18774 #
#--------#
include("generate_kernel.jl")

const nmax = 6  # maximum dimensionality is nmax + 1
# get path to tempdir and append file name to it
mktempdir() do dir
    fname = joinpath(dir, "hdindexing.jl")
    make_stencil(fname, nmax)  # generate source file
    include(fname)
end

const npts_dir = [10000, 80, 20, 12, 9, 6]  # number of points in each direction
for i = 1:nmax
  str = string(i+1, "d")
  # perf_hdindexing is defined in the generated source file hdindexing.jl
  g[str] = @benchmarkable perf_hdindexing5(u_i, u_ip1) setup=begin
      dims_vec = zeros(Int, $i+1)
      fill!(dims_vec, npts_dir[$i])
      dims_vec[end] = 2  # last dimension must be 2
      u_i = samerand(dims_vec...)
      u_ip1 = zeros(dims_vec...)
  end
end




# #10301 #
#--------#

include("revloadindex.jl")

g = addgroup!(SUITE, "reverse", ["index", "fill!"])

g["rev_load_slow!"]    = @benchmarkable perf_rev_load_slow!(fill!(v, n)) setup=(v=samerand(10^6); n=samerand())
g["rev_load_fast!"]    = @benchmarkable perf_rev_load_fast!(fill!(v, n)) setup=(v=samerand(10^6); n=samerand())
g["rev_loadmul_slow!"] = @benchmarkable perf_rev_loadmul_slow!(fill!(v, n), v) setup=(v=samerand(10^6); n=samerand())
g["rev_loadmul_fast!"] = @benchmarkable perf_rev_loadmul_fast!(fill!(v, n), v) setup=(v=samerand(10^6); n=samerand())


# #9622 #
#-------#

perf_setindex!(A, val, inds) = setindex!(A, val, inds...)

g = addgroup!(SUITE, "setindex!", ["index"])

for nd in (1, 2, 3, 4, 5)
    g["setindex!", nd] = @benchmarkable perf_setindex!(fill!(A, y), y, i) setup=begin
        A = samerand(Float64, ntuple(one, $nd)...)
        y = one(eltype(A))
        i = length(A)
    end
end

###############################
# SubArray (views vs. copies) #
###############################

# LU factorization with complete pivoting. These functions deliberately allocate
# a lot of temprorary arrays by working on vectors instead of looping through
# the elements of the matrix. Both a view (SubArray) version and a copy version
# are provided.

include("subarray.jl")

g = addgroup!(SUITE, "subarray", ["lucompletepiv", "gramschmidt"])

for s in (100, 250, 500, 1000)
    g["lucompletepivCopy!", s] = @benchmarkable perf_lucompletepivCopy!(fill!(m, n)) setup=begin
        n = samerand()
        m = samerand($s, $s)
    end
    g["lucompletepivSub!", s]  = @benchmarkable perf_lucompletepivSub!(fill!(m, n)) setup=begin
        n = samerand()
        m = samerand($s, $s)
    end
end

# Gram-Schmidt orthonormalization, using views to operate on matrix slices.

for s in (100, 250, 500, 1000)
    g["gramschmidt!", s] = @benchmarkable perf_gramschmidt!(fill!(m, n)) setup=begin
        n = samerand()
        m = samerand($s, $s)
    end
end

#################
# concatenation #
#################

include("cat.jl")

g = addgroup!(SUITE, "cat", ["index"])

for s in (5, 500)
    g["hvcat", s]        = @benchmarkable perf_hvcat(A, A) setup=(A=samerand($s, $s))
    g["hcat", s]         = @benchmarkable perf_hcat(A, A) setup=(A=samerand($s, $s))
    g["vcat", s]         = @benchmarkable perf_vcat(A, A) setup=(A=samerand($s, $s))
    g["catnd", s]        = @benchmarkable perf_catnd($s)
    g["hvcat_setind", s] = @benchmarkable perf_hvcat_setind(A, A) setup=(A=samerand($s, $s))
    g["hcat_setind", s]  = @benchmarkable perf_hcat_setind(A, A) setup=(A=samerand($s, $s))
    g["vcat_setind", s]  = @benchmarkable perf_vcat_setind(A, A) setup=(A=samerand($s, $s))
    g["catnd_setind", s] = @benchmarkable perf_catnd_setind($s)
end

g["4467"] = @benchmarkable perf_cat_4467()

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
    g["push_single!", s]   = @benchmarkable push!(x, y)     setup=(x=samerand($s); y=samerand())
    g["push_multiple!", s] = @benchmarkable perf_push_multiple!(x, vs) setup=(x=samerand($s); vs=copy(x))
    g["append!", s]        = @benchmarkable append!(x, vs)             setup=(x=samerand($s); vs=copy(x))
    g["prerend!", s]       = @benchmarkable prepend!(x, vs)            setup=(x=samerand($s); vs=copy(x))
end

##########################
# comprehension (#13401) #
##########################

perf_compr_collect(X) = [x for x in X]
perf_compr_iter(X) = [sin(x) + x^2 - 3 for x in X]
perf_compr_index(X) = [sin(X[i]) + (X[i])^2 - 3 for i in eachindex(X)]

getls() = range(0, stop=1, length=10^7)
getrg() = 0.0:(10.0^(-7)):1.0
getarr() = collect(getls())

g = addgroup!(SUITE, "comprehension", ["iteration", "index", "collect", "range"])

for getX in (getls, getrg, getarr)
    T = string(typeof(getX()))
    g["collect", T] = @benchmarkable collect(X) setup=(X=$getX())
    g["comprehension_collect", T]   = @benchmarkable perf_compr_collect(X) setup=(X=$getX())
    g["comprehension_iteration", T] = @benchmarkable perf_compr_iter(X) setup=(X=$getX())
    g["comprehension_indexing", T]  = @benchmarkable perf_compr_index(X) setup=(X=$getX()) time_tolerance=0.30
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

g = addgroup!(SUITE, "bool", ["index", "bitarray", "fill!"])

let n = 10^6, vals = -3:3
    ab(n) = samerand(vals, n), samerand(vals)
    g["bitarray_bool_load!"]  = @benchmarkable perf_bool_load!(bitarr, a, b) setup=((a,b)=$ab($n); bitarr=BitArray(undef,$n))
    g["boolarray_bool_load!"] = @benchmarkable perf_bool_load!(boolarr, a, b) setup=((a,b)=$ab($n); boolarr=Vector{Bool}(undef, $n))
    g["bitarray_true_load!"]  = @benchmarkable perf_true_load!(bitarr) setup=(bitarr=BitArray(undef,$n))
    g["boolarray_true_load!"] = @benchmarkable perf_true_load!(boolarr) setup=(boolarr=Vector{Bool}(undef, $n))
    g["bitarray_true_fill!"]  = @benchmarkable fill!(bitarr, true) setup=(bitarr=BitArray(undef,$n))
    g["boolarray_true_fill!"] = @benchmarkable fill!(boolarr, true) setup=(boolarr=Vector{Bool}(undef, $n))
end


####################################
# Float to Int conversion (#18954) #
####################################

function perf_convert!(a, x)
    for i = 1:length(x)
        a[i] = x[i]
    end
    return a
end

g = addgroup!(SUITE, "convert", ["Int"])
g["Int", "Float64"] = @benchmarkable  perf_convert!(x_int, x_float) setup=(x_int=samerand(1:1000000,100,100); x_float=1.0x_int)
g["Float64", "Int"] = @benchmarkable  perf_convert!(x_float, x_int) setup=(x_int=samerand(1:1000000,100,100); x_float=1.0x_int)
g["Complex{Float64}", "Int"] = @benchmarkable  perf_convert!(x_complex, x_int) setup=(x_int=samerand(1:1000000,100,100); x_float=1.0x_int; x_complex=x_float .+ 0.0im)
g["Int", "Complex{Float64}"] = @benchmarkable  perf_convert!(x_int, x_complex) setup=(x_int=samerand(1:1000000,100,100); x_float=1.0x_int; x_complex=x_float .+ 0.0im)


################
# == and isequal
################

g = addgroup!(SUITE, "equality", ["==", "isequal"])

# Only test cases which do not short-circuit, else performance
# depends too much on the data
let x_range = 1:10_000
    for getx in (() -> x_range,
              () -> collect(x_range),
              () -> Int16.(x_range),
              () -> Float64.(x_range),
              () -> Float32.(x_range))
        x = getx()
        g["==", string(typeof(x))] = @benchmarkable x == y setup=(x=$getx(); y=copy(x))
        g["isequal", string(typeof(x))] = @benchmarkable isequal(x, y) setup=(x=$getx(); y=copy(x))

        x_vec = collect(x)
        g["==", string(typeof(x_vec), " == ", typeof(x))] =
            @benchmarkable x_vec == x setup=(x=$getx(); x_vec=collect(x))
        g["isequal", string(typeof(x_vec), " isequal ", typeof(x))] =
            @benchmarkable isequal(x_vec, x) setup=(x=$getx(); x_vec=collect(x))
    end
end

g["==", "Vector{Bool}"] = @benchmarkable x == y setup=(x=fill(false, 10_000); y=copy(x))
g["isequal", "Vector{Bool}"] = @benchmarkable isequal(x, y) setup=(x=fill(false, 10_000); y=copy(x))
g["==", "BitArray"] = @benchmarkable x == y setup=(x=falses(10_000); y=copy(x))
g["isequal", "BitArray"] = @benchmarkable isequal(x, y) setup=(x=fill(false, 10_000); y=copy(x))

###########
# any & all
###########

getx_false() = fill(false, 10_000)
getx_true() = fill(true, 10_000)

g = addgroup!(SUITE, "any/all", ["any", "all"])

# Only test cases which do not short-circuit, else performance
# depends too much on the data
g["any", "Vector{Bool}"] = @benchmarkable any(x) setup=(x=getx_false())
g["all", "Vector{Bool}"] = @benchmarkable all(x) setup=(x=getx_true())
g["any", "BitArray"] = @benchmarkable any(x) setup=(x=BitArray(getx_false()))
g["all", "BitArray"] = @benchmarkable all(x) setup=(x=BitArray(getx_true()))

let x_range = 1:10_000
    for getx in (() -> x_range,
                 () -> collect(x_range),
                 () -> Int16.(x_range),
                 () -> Float64.(x_range),
                 () -> Float32.(x_range))
        x = getx()
        g["any", string(typeof(x))] = @benchmarkable any(v -> v < 0, x) setup=(x=$getx())
        g["all", string(typeof(x))] = @benchmarkable all(v -> v > 0, x) setup=(x=$getx())

        g["any", string(typeof(x), " generator")] = @benchmarkable any(v -> v < 0, gen) setup=(gen=(xi for xi in $getx()))
        g["all", string(typeof(x), " generator")] = @benchmarkable all(v -> v > 0, gen) setup=(gen=(xi for xi in $getx()))
    end
end

###########
# accumulate
###########

g = addgroup!(SUITE, "accumulate", ["accumulate","cumsum"])

g["accumulate", "Float64"] = @benchmarkable accumulate(+, a) setup=(a=getafloat())
g["accumulate", "Int"] = @benchmarkable accumulate(+, a) setup=(a=getaint())

g["cumsum", "Float64"] = @benchmarkable cumsum(a) setup=(a=getafloat())
g["cumsum", "Int"] = @benchmarkable cumsum(a) setup=(a=getaint())

g["accumulate!", "Float64"] = @benchmarkable accumulate!(+, res, a) setup=(a=getafloat(); res=similar(a))
g["accumulate!", "Int"] = @benchmarkable accumulate!(+, res, a) setup=(a=getaint(); res=similar(a))

g["cumsum!", "Float64"] = @benchmarkable cumsum!(res, a) setup=(a=getafloat(); res=similar(a))
g["cumsum!", "Int"] = @benchmarkable cumsum!(res, a) setup=(aint=getaint(); a=aint.÷length(aint); res=similar(a))

getmfloat() = samerand(10^3,10^3)
g["cumsum", "Float64", "dim1"] = @benchmarkable cumsum(mfloat, dims=1) setup=(mfloat=getmfloat())
g["cumsum", "Float64", "dim2"] = @benchmarkable cumsum(mfloat, dims=2) setup=(mfloat=getmfloat())

g["cumsum!", "Float64", "dim1"] = @benchmarkable cumsum!(res, mfloat, dims=1) setup=(mfloat=getmfloat(); res=similar(mfloat))
g["cumsum!", "Float64", "dim2"] = @benchmarkable cumsum!(res, mfloat, dims=2) setup=(mfloat=getmfloat(); res=similar(mfloat))

#############################################
# Performance of heterogenous tuples #39035 #
#############################################

perf_het_tuple() = b = [1, 2.0]

SUITE["perf heterogenous tuple"] = @benchmarkable perf_het_tuple()

end # module
