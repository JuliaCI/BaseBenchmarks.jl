module SparseBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using SparseArrays
using LinearAlgebra

const SUITE = BenchmarkGroup(["array"])

#########
# index #
#########

# Note that some of the "logical" tests are commented
# out because they require resolution of JuliaLang/julia#14717.

g = addgroup!(SUITE, "index")

# vector #
#--------#

getspvec(s) = samesprand(s, inv(sqrt(s)))
getsplogvec(s) = samesprandbool(s, 1e-5)

let sizes = (10^3, 10^4, 10^5)
for s in sizes
    g["spvec", "array",   s] = @benchmarkable getindex(v, i) setup=(s=$s; v=getspvec(s); i=samerand(1:s, s))
    g["spvec", "integer", s] = @benchmarkable getindex(v, i) setup=(s=$s; v=getspvec(s); i=samerand(1:s))
    g["spvec", "range",   s] = @benchmarkable getindex(v, i) setup=(s=$s; v=getspvec(s); i=1:s)
    g["spvec", "logical", s] = @benchmarkable getindex(v, i) setup=(s=$s; v=getspvec(s); i=samerand(Bool, s))
    # g["spvec", "splogical", s, nnz(v), nnz(l)] = @benchmarkable getindex($v, $l) setup=(s=$s; v=getspvec(s); i=samerand(Bool, s); l=getsplogvec(s))
end
end

# matrix #
#--------#

getind(s) = samerand(1:s)
getmatrix(s) = samesprand(s, s, inv(sqrt(s)))
getvector(s) = samerand(1:s, s)
getlogvec(s) = samerand(Bool, s)
getsplogmat(s) = samesprandbool(s, s, 1e-5)
getsplogvec(s) = samesprandbool(s, 1, 1e-5)

let sizes = (10, 10^2, 10^3)
for s in sizes
    g["spmat", "col", "array", s] = @benchmarkable getindex(m, v, c) setup=(s=$s; m=getmatrix(s); v=getvector(s); c=getind(s))
    g["spmat", "col", "range", s] = @benchmarkable getindex(m, v, c) setup=(s=$s; m=getmatrix(s); v=1:s; c=getind(s))
    g["spmat", "col", "OneTo", s] = @benchmarkable getindex(m, v, c) setup=(s=$s; m=getmatrix(s); v=Base.OneTo(s); c=getind(s))
    g["spmat", "col", "logical", s] = @benchmarkable getindex(m, l, c) setup=(s=$s; m=getmatrix(s); l=getlogvec(s); c=getind(s))
    # g["spmat", "col", "splogical", s] = @benchmarkable getindex(m, sl, c) setup=(s=$s; m=getmatrix(s); sl=getsplogvec(s); c=getind(s))
end

for s in sizes
    g["spmat", "row", "array", s] = @benchmarkable getindex(m, r, v) setup=(s=$s; m=getmatrix(s); v=getvector(s); r=getind(s))
    g["spmat", "row", "range", s] = @benchmarkable getindex(m, r, v) setup=(s=$s; m=getmatrix(s); v=1:s; r=getind(s))
    g["spmat", "row", "OneTo", s] = @benchmarkable getindex(m, r, v) setup=(s=$s; m=getmatrix(s); v=Base.OneTo(s); r=getind(s))
    g["spmat", "row", "logical", s] = @benchmarkable getindex(m, r, l) setup=(s=$s; m=getmatrix(s); l=getlogvec(s); r=getind(s))
    # g["spmat", "row", "splogical", s] = @benchmarkable getindex(m, r, sl) setup=(s=$s; m=getmatrix(s); sl=getsplogvec(s); r=getind(s))
end

for s in sizes
    g["spmat", "array", s] = @benchmarkable getindex(m, v, v) setup=(s=$s; m=getmatrix(s); v=getvector(s))
    g["spmat", "integer", s] = @benchmarkable getindex(m, i, i) setup=(s=$s; m=getmatrix(s); i=getind(s))
    g["spmat", "range", s] = @benchmarkable getindex(m, 1:s, 1:s) setup=(s=$s; m=getmatrix(s))
    g["spmat", "OneTo", s] = @benchmarkable getindex(m, Base.OneTo(s), Base.OneTo(s)) setup=(s=$s; m=getmatrix(s))
    g["spmat", "logical", s] = @benchmarkable getindex(m, l, l) setup=(s=$s; m=getmatrix(s); l=getlogvec(s))
    g["spmat", "splogical", s] = @benchmarkable getindex(m, sl) setup=(s=$s; m=getmatrix(s); sl=getsplogmat(s))
end
end

for b in values(g)
    b.params.time_tolerance = 0.3
end

######################
# transpose (#14631) #
######################

g = addgroup!(SUITE, "transpose", ["adjoint"])

for s in ((600, 600),
          (600, 400),
          (20000, 20000),
          (20000, 10000))
    g["transpose", s] = @benchmarkable transpose(m) setup=(m=samesprand($s[1], $s[2], 0.01))
    g["transpose!", s] = @benchmarkable transpose!(mt, m) setup=(m=samesprand($s[1], $s[2], 0.01); mt=copy(transpose(m)))
    g["adjoint", s] = @benchmarkable adjoint(cm) setup=(m=samesprand($s[1], $s[2], 0.01); cm=m + m*im)
    g["adjoint!", s] = @benchmarkable adjoint!(cmt, cm) setup=(m=samesprand($s[1], $s[2], 0.01); cm=m + m*im; cmt=copy(transpose(cm)))
end

for b in values(g)
    b.params.time_tolerance = 0.3
end

##############
# arithmetic #
##############

g = addgroup!(SUITE, "arithmetic")

# unary minus, julialang repo issue #19503 / fix #19530
g["unary minus", (600, 600)] = @benchmarkable -m setup=(m=samesprand(600, 600, 0.01))
g["unary minus", (20000, 20000)] = @benchmarkable -m setup=(m=samesprand(20000, 20000, 0.01))

for b in values(g)
    b.params.time_tolerance = 0.3
end

################
# constructors #
################
g = addgroup!(SUITE, "constructors")

const UPLO = :U
let sizes = (10, 10^2, 10^3)
for s in sizes
    nz = floor(Int, 1e-4*s*s)
    getI() = samerand(1:s, nz)
    getJ() = samerand(1:s, nz)
    getV() = randvec(nz)
    g["IV", s] = @benchmarkable sparsevec(I, V) setup=(I=$getI(); V=$getV())
    g["IJV", s] = @benchmarkable sparse(I, J, V) setup=(I=$getI(); J=$getJ(); V=$getV())
    g["Diagonal", s] = @benchmarkable sparse(D) setup=(D=Diagonal(randvec($s)))
    g["Bidiagonal", s] = @benchmarkable sparse(B) setup=(B=Bidiagonal(randvec($s), randvec($s-1), UPLO))
    g["Tridiagonal", s] = @benchmarkable sparse(T) setup=(T=Tridiagonal(randvec($s-1), randvec($s), randvec($s-1)))
    g["SymTridiagonal", s] = @benchmarkable sparse(ST) setup=(ST=SymTridiagonal(randvec($s), randvec($s-1)))
end
end

#########################
# matrix multiplication #
#########################

g = addgroup!(SUITE, "matmul")

# mixed sparse-dense matmul #
#---------------------------#

using LinearAlgebra: *, mul!

function allocmats_ds(m, k, n, nnzc, T)
    densemat, sparsemat = samerand(T, m, k), samesprand(T, k, n, nnzc/k)
    tdensemat = transpose!(similar(densemat, reverse(size(densemat))), densemat)
    tsparsemat = transpose!(similar(sparsemat, reverse(size(sparsemat))), sparsemat)
    destmat = similar(densemat, m, n)
    return destmat, densemat, sparsemat, tdensemat, tsparsemat
end

function allocmats_sd(m, k, n, nnzc, T)
    densemat, sparsemat = samerand(T, k, m), samesprand(T, n, k, nnzc/n)
    tdensemat = transpose!(similar(densemat, reverse(size(densemat))), densemat)
    tsparsemat = transpose!(similar(sparsemat, reverse(size(sparsemat))), sparsemat)
    destmat = similar(densemat, n, m)
    return destmat, densemat, sparsemat, tdensemat, tsparsemat
end

getsizes(om, ok, on, s) = map(x -> Int(s*x), (om, ok, on))

for (om, ok, on) in (# order of matmul dimensions m, k, and n
        (10^2, 10^2, 10^2),  # dense square * sparse square -> dense square
        (10^1, 10^1, 10^3),  # dense square * sparse short -> dense short
        (10^2, 10^2, 10^1),  # dense square * sparse tall -> dense tall
        (10^1, 10^3, 10^3),  # dense short * sparse square -> dense short
        (10^1, 10^2, 10^3),  # dense short * sparse short -> dense short
        (10^1, 10^3, 10^2),  # dense short * sparse tall -> dense short
        (10^3, 10^1, 10^1),  # dense tall * sparse square -> dense tall
        (10^2, 10^1, 10^2),  # dense tall * sparse short -> dense square
        ) # the preceding descriptions apply to dense-sparse matmul without
          # any transpositions. other cases are described below
    #
    # the transpose and adjoint variants share kernel code
    # the in-place and out-of-place variants share kernel code
    # so exercise the different variants in different ways
    #
    # for A[t|c]_mul_B[t|c][!]([dense,], dense, sparse) kernels,
    # the dense matrix is m-by-k, or k-by-m for A(c|t) operations
    # the sparse matrix is k-by-n, or n-by-k for B(c|t) operations
    # and the (dense) destination matrix is m-by-n in any case
    # the sparse matrix has approximately 10 entries per column
    #
    # # out-of-place dense-sparse ops, transpose variants, i.e. A[t]_mul_B[t](dense, sparse)
    m, k, n = getsizes(om, ok, on, 1/2)
    g["A_mul_B",   "dense $(m)x$(k), sparse $(k)x$(n) -> dense $(m)x$(n)"] = @benchmarkable *(densemat, sparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 4, Float64)
    end
    g["A_mul_Bt",  "dense $(m)x$(k), sparse $(n)x$(k) -> dense $(m)x$(n)"] = @benchmarkable *(densemat, ttsparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 4, Float64)
        ttsparsemat = Transpose(tsparsemat)
    end
    g["At_mul_B",  "dense $(k)x$(m), sparse $(k)x$(n) -> dense $(m)x$(n)"] = @benchmarkable *(ttdensemat, sparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 4, Float64)
        ttdensemat = Transpose(tdensemat)
    end
    g["At_mul_Bt", "dense $(k)x$(m), sparse $(n)x$(k) -> dense $(m)x$(n)"] = @benchmarkable *(ttdensemat, ttsparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 4, Float64)
        ttdensemat = Transpose(tdensemat)
        ttsparsemat = Transpose(tsparsemat)
    end
    # in-place dense-sparse -> dense ops, transpose variants, i.e. A[t]_mul[t]!(dense, dense, sparse)
    m, k, n = getsizes(om, ok, on, 4)
    g["A_mul_B!",   "dense $(m)x$(k), sparse $(k)x$(n) -> dense $(m)x$(n)"] = @benchmarkable mul!(destmat, densemat, sparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 12, Float64)
    end
    g["A_mul_Bt!",  "dense $(m)x$(k), sparse $(n)x$(k) -> dense $(m)x$(n)"] = @benchmarkable mul!(destmat, densemat, ttsparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 12, Float64)
        ttsparsemat = Transpose(tsparsemat)
    end
    g["At_mul_B!",  "dense $(k)x$(m), sparse $(k)x$(n) -> dense $(m)x$(n)"] = @benchmarkable mul!(destmat, ttdensemat, sparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 12, Float64)
        ttdensemat = Transpose(tdensemat)
    end
    g["At_mul_Bt!", "dense $(k)x$(m), sparse $(n)x$(k) -> dense $(m)x$(n)"] = @benchmarkable mul!(destmat, ttdensemat, ttsparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 12, Float64)
        ttdensemat = Transpose(tdensemat)
        ttsparsemat = Transpose(tsparsemat)
    end
    # out-of-place dense-sparse ops, adjoint variants, i.e. A[c]_mul_B[c](dense, sparse)
    m, k, n = getsizes(om, ok, on, 1/2)
    g["A_mul_Bc",  "dense $(m)x$(k), sparse $(n)x$(k) -> dense $(m)x$(n)"] = @benchmarkable *(densemat, atsparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 4, ComplexF64)
        atsparsemat = Adjoint(tsparsemat)
    end
    g["Ac_mul_B",  "dense $(k)x$(m), sparse $(k)x$(n) -> dense $(m)x$(n)"] = @benchmarkable *(atdensemat, sparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 4, ComplexF64)
        atdensemat = Adjoint(tdensemat)
    end
    g["Ac_mul_Bc", "dense $(k)x$(m), sparse $(n)x$(k) -> dense $(m)x$(n)"] = @benchmarkable *(atdensemat, atsparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 4, ComplexF64)
        atdensemat = Adjoint(tdensemat)
        atsparsemat = Adjoint(tsparsemat)
    end
    # in-place dense-sparse -> dense ops, adjoint variants, i.e. A[c]_mul[c]!(dense, dense, sparse)
    m, k, n = getsizes(om, ok, on, 2)
    g["A_mul_Bc!",  "dense $(m)x$(k), sparse $(n)x$(k) -> dense $(m)x$(n)"] = @benchmarkable mul!(destmat, densemat, atsparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 8, ComplexF64)
        atsparsemat = Adjoint(tsparsemat)
    end
    g["Ac_mul_B!",  "dense $(k)x$(m), sparse $(k)x$(n) -> dense $(m)x$(n)"] = @benchmarkable mul!(destmat, atdensemat, sparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 8, ComplexF64)
        atdensemat = Adjoint(tdensemat)
    end
    g["Ac_mul_Bc!", "dense $(k)x$(m), sparse $(n)x$(k) -> dense $(m)x$(n)"] = @benchmarkable mul!(destmat, atdensemat, atsparsemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_ds($m, $k, $n, 8, ComplexF64)
        atdensemat = Adjoint(tdensemat)
        atsparsemat = Adjoint(tsparsemat)
    end
    #
    # for A[t|c]_mul_B[t|c][!]([dense,], sparse, dense) kernels,
    # the sparse matrix is n-by-k, or k-by-n for B(c|t) operations
    # the dense matrix is k-by-m, or m-by-k for A(c|t) operations
    # and the (dense) destination matrix is n-by-m in any case
    # the sparse matrix has approximately 10 entries per column
    #
    # out-of-place sparse-dense ops, transpose variants, i.e. A[t]_mul_B[t](sparse, dense)
    m, k, n = getsizes(om, ok, on, 1/2)
    g["A_mul_B",   "sparse $(n)x$(k), dense $(k)x$(m) -> dense $(n)x$(m)"] = @benchmarkable *(sparsemat, densemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 4, ComplexF64)
    end
    g["A_mul_Bt",  "sparse $(n)x$(k), dense $(m)x$(k) -> dense $(n)x$(m)"] = @benchmarkable *(sparsemat, ttdensemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 4, ComplexF64)
        ttdensemat = Transpose(tdensemat)
    end
    g["At_mul_B",  "sparse $(k)x$(n), dense $(k)x$(m) -> dense $(n)x$(m)"] = @benchmarkable *(ttsparsemat, densemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 4, ComplexF64)
        ttsparsemat = Transpose(tsparsemat)
    end
    g["At_mul_Bt", "sparse $(k)x$(n), dense $(m)x$(k) -> dense $(n)x$(m)"] = @benchmarkable *(ttsparsemat, ttdensemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 4, ComplexF64)
        ttdensemat = Transpose(tdensemat)
        ttsparsemat = Transpose(tsparsemat)
    end
    # in-place sparse-dense -> dense ops, transpose variants, i.e. A[t|c]_mul_B[t|c]!(dense, sparse, dense)
    m, k, n = getsizes(om, ok, on, 4)
    g["A_mul_B!",   "sparse $(n)x$(k), dense $(k)x$(m) -> dense $(n)x$(m)"] = @benchmarkable mul!(destmat, sparsemat, densemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 12, ComplexF64)
    end
    g["A_mul_Bt!",  "sparse $(n)x$(k), dense $(m)x$(k) -> dense $(n)x$(m)"] = @benchmarkable mul!(destmat, sparsemat, ttdensemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 12, ComplexF64)
        ttdensemat = Transpose(tdensemat)
    end
    g["At_mul_B!",  "sparse $(k)x$(n), dense $(k)x$(m) -> dense $(n)x$(m)"] = @benchmarkable mul!(destmat, ttsparsemat, densemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 12, ComplexF64)
        ttsparsemat = Transpose(tsparsemat)
    end
    g["At_mul_Bt!", "sparse $(k)x$(n), dense $(m)x$(k) -> dense $(n)x$(m)"] = @benchmarkable mul!(destmat, ttsparsemat, ttdensemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 12, ComplexF64)
        ttdensemat = Transpose(tdensemat)
        ttsparsemat = Transpose(tsparsemat)
    end
    # out-of-place sparse-dense ops, adjoint variants, i.e. A[c]_mul_B[c](sparse, dense)
    m, k, n = getsizes(om, ok, on, 1/2)
    g["A_mul_Bc",  "sparse $(n)x$(k), dense $(m)x$(k) -> dense $(n)x$(m)"] = @benchmarkable *(sparsemat, atdensemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 4, ComplexF64)
        atdensemat = Adjoint(tdensemat)
    end
    g["Ac_mul_B",  "sparse $(k)x$(n), dense $(k)x$(m) -> dense $(n)x$(m)"] = @benchmarkable *(atsparsemat, densemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 4, ComplexF64)
        atsparsemat = Adjoint(tsparsemat)
    end
    g["Ac_mul_Bc", "sparse $(k)x$(n), dense $(m)x$(k) -> dense $(n)x$(m)"] = @benchmarkable *(atsparsemat, atdensemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 4, ComplexF64)
        atdensemat = Adjoint(tdensemat)
        atsparsemat = Adjoint(tsparsemat)
    end
    # in-place sparse-dense -> dense ops, adjoint variants, i.e. A[t|c]_mul_B[t|c]!(dense, sparse, dense)
    m, k, n = getsizes(om, ok, on, 2)
    g["A_mul_Bc!",  "sparse $(n)x$(k), dense $(m)x$(k) -> dense $(n)x$(m)"] = @benchmarkable mul!(destmat, sparsemat, atdensemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 8, ComplexF64)
        atdensemat = Adjoint(tdensemat)
    end
    g["Ac_mul_B!",  "sparse $(k)x$(n), dense $(k)x$(m) -> dense $(n)x$(m)"] = @benchmarkable mul!(destmat, atsparsemat, densemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 8, ComplexF64)
        atsparsemat = Adjoint(tsparsemat)
    end
    g["Ac_mul_Bc!", "sparse $(k)x$(n), dense $(m)x$(k) -> dense $(n)x$(m)"] = @benchmarkable mul!(destmat, atsparsemat, atdensemat) setup=begin
        destmat, densemat, sparsemat, tdensemat, tsparsemat = allocmats_sd($m, $k, $n, 8, ComplexF64)
        atdensemat = Adjoint(tdensemat)
        atsparsemat = Adjoint(tsparsemat)
    end
end

for b in values(g)
    b.params.time_tolerance = 0.3
end


#################
# sparse matvec #
#################
g = addgroup!(SUITE, "sparse matvec")
g["non-adjoint"] = @benchmarkable A * B setup=begin
    B = randn(100000, 100)
    A = sprand(100000, 100000, 0.00001)
end
g["adjoint"] = @benchmarkable A' * B setup=begin
    B = randn(100000, 100)
    A = sprand(100000, 100000, 0.00001)
end

#################
# sparse solves #
#################
g = addgroup!(SUITE, "sparse solves")
# Problem similar to issue #30288
let m = 10000, n = 9000
    getA() = spdiagm(0 => fill(2.0, m),
                    -1 => fill(1.0, m - 1),
                     1 => fill(1.0, m - 1),
                   360 => fill(1.0, m - 360))[:, 1:n]
    getAtA() = (A=getA(); A'A)
    getb()   = ones(m)
    getB()   = ones(m, 2)
    getAtb() = getA()'getb()
    getAtB() = getA()'getB()

    g["least squares (default), vector rhs"] = @benchmarkable A\b setup=(A=$getA(); b=$getb())
    g["least squares (default), matrix rhs"] = @benchmarkable A\B setup=(A=$getA(); B=$getB())
    g["least squares (qr), vector rhs"] = @benchmarkable qr(A)\b setup=(A=$getA(); b=$getb())
    g["least squares (qr), matrix rhs"] = @benchmarkable qr(A)\B setup=(A=$getA(); B=$getB())
    g["square system (default), vector rhs"] = @benchmarkable AtA\Atb setup=(AtA=$getAtA(); Atb=$getAtb())
    g["square system (default), matrix rhs"] = @benchmarkable AtA\AtB setup=(AtA=$getAtA(); AtB=$getAtB())
    g["square system (ldlt), vector rhs"] = @benchmarkable ldlt(AtA)\Atb setup=(AtA=$getAtA(); Atb=$getAtb())
    g["square system (ldlt), matrix rhs"] = @benchmarkable ldlt(AtA)\AtB setup=(AtA=$getAtA(); AtB=$getAtB())
    g["square system (lu), vector rhs"] = @benchmarkable lu(AtA)\Atb setup=(AtA=$getAtA(); Atb=$getAtb())
    g["square system (lu), matrix rhs"] = @benchmarkable lu(AtA)\AtB setup=(AtA=$getAtA(); AtB=$getAtB())
end

end # module
