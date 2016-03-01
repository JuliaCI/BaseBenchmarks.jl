module LinAlgBenchmarks

using ..BaseBenchmarks: GROUPS
using ..RandUtils
using BenchmarkTools

const SIZES = (16, 512)
const MATS = (Matrix, Diagonal, Bidiagonal, Tridiagonal, SymTridiagonal, UpperTriangular, LowerTriangular)
const DIVMATS = filter(x -> !(in(x, (Bidiagonal, Tridiagonal, SymTridiagonal))), MATS)

typename{T}(::Type{T}) = string(T.name)
typename{M<:Matrix}(::Type{M}) = "Matrix"
typename{V<:Vector}(::Type{V}) = "Vector"

linalgmat(::Type{Matrix}, s) = randmat(s)
linalgmat(::Type{Diagonal}, s) = Diagonal(randvec(s))
linalgmat(::Type{Bidiagonal}, s) = Bidiagonal(randvec(s), randvec(s-1), true)
linalgmat(::Type{Tridiagonal}, s) = Tridiagonal(randvec(s-1), randvec(s), randvec(s-1))
linalgmat(::Type{SymTridiagonal}, s) = SymTridiagonal(randvec(s), randvec(s-1))
linalgmat(::Type{UpperTriangular}, s) = UpperTriangular(randmat(s))
linalgmat(::Type{LowerTriangular}, s) = LowerTriangular(randmat(s))

function linalgmat(::Type{Hermitian}, s)
    A = randmat(s)
    A = A + im*A
    return Hermitian(A + A')
end

############################
# matrix/vector arithmetic #
############################

g = addgroup!(GROUPS, "linalg arithmetic", ["array", "linalg", "arithmetic"])

for s in SIZES
    v = typename(Vector)
    g["+", v, v, s] = @benchmarkable +(randvec($s), randvec($s))
    g["-", v, v, s] = @benchmarkable -(randvec($s), randvec($s))
    for M in MATS
        m = typename(M)
        g["*", m, v, s] = @benchmarkable *(linalgmat($M, $s), randvec($s))
        g["\\", m, v, s] = @benchmarkable \(linalgmat($M, $s), randvec($s))
        g["+", m, m, s] = @benchmarkable +(linalgmat($M, $s), linalgmat($M, $s))
        g["-", m, m, s] = @benchmarkable -(linalgmat($M, $s), linalgmat($M, $s))
        g["*", m, m, s] = @benchmarkable *(linalgmat($M, $s), linalgmat($M, $s))
    end
    for M in DIVMATS
        m = typename(M)
        g["/", m, m, s] = @benchmarkable /(linalgmat($M, $s), linalgmat($M, $s))
        g["\\", m, m, s] = @benchmarkable \(linalgmat($M, $s), linalgmat($M, $s))
    end
end

##################
# factorizations #
##################

g = addgroup!(GROUPS, "factorization eig", ["array", "linalg", "factorization", "eig", "eigfact"])

for M in (Matrix, Diagonal, Bidiagonal, SymTridiagonal, UpperTriangular, LowerTriangular)
    m = typename(M)
    for s in SIZES
        g["eig", m, s] = @benchmarkable eig(linalgmat($M, $s))
        g["eigfact", m, s] = @benchmarkable eigfact(linalgmat($M, $s))
    end
end

g = addgroup!(GROUPS, "factorization svd", ["array", "linalg", "factorization", "svd", "svdfact"])

for M in (Matrix, Diagonal, Bidiagonal, UpperTriangular, LowerTriangular)
    m = typename(M)
    for s in SIZES
        g["svd", m, s] = @benchmarkable svd(linalgmat($M, $s))
        g["svdfact", m, s] = @benchmarkable svdfact(linalgmat($M, $s))
    end
end

g = addgroup!(GROUPS, "factorization lu", ["array", "linalg", "factorization", "lu", "lufact"])

for M in (Matrix, Tridiagonal)
    m = typename(M)
    for s in SIZES
        g["lu", m, s] = @benchmarkable lu(linalgmat($M, $s))
        g["lufact", m, s] = @benchmarkable lufact(linalgmat($M, $s))
    end
end

g = addgroup!(GROUPS, "factorization qr", ["array", "linalg", "factorization", "qr", "qrfact"])

for s in SIZES
    m = typename(Matrix)
    g["qr", m, s] = @benchmarkable qr(randmat($s))
    g["qrfact", m, s] = @benchmarkable qrfact(randmat($s))
end

g = addgroup!(GROUPS, "factorization schur", ["array", "linalg", "factorization", "schur", "schurfact"])

for s in SIZES
    m = typename(Matrix)
    g["schur", m, s] = @benchmarkable schur(randmat($s))
    g["schurfact", m, s] = @benchmarkable schurfact(randmat($s))
end

g = addgroup!(GROUPS, "factorization chol", ["array", "linalg", "factorization", "chol", "cholfact"])

for s in SIZES
    m = typename(Matrix)
    arr = randmat(s)'*randmat(s)
    g["chol", m, s] = @benchmarkable chol(copy($arr))
    g["cholfact", m, s] = @benchmarkable cholfact(copy($arr))
end

########
# BLAS #
########

g = addgroup!(GROUPS, "blas", ["array", "linalg"])

s = 1024
C = Complex{Float64}

g["dot", s]       = @benchmarkable BLAS.dot($s, randvec($s), 1, randvec($s), 1)
g["dotu", s]      = @benchmarkable BLAS.dotu($s, randvec($C, $s), 1, randvec($C, $s), 1)
g["dotc", s]      = @benchmarkable BLAS.dotc($s, randvec($C, $s), 1, randvec($C, $s), 1)
g["blascopy!", s] = @benchmarkable BLAS.blascopy!($s, randvec($s), 1, randvec($s), 1)
g["nrm2", s]      = @benchmarkable BLAS.nrm2($s, randvec($s), 1)
g["asum", s]      = @benchmarkable BLAS.asum($s, randvec($s), 1)
g["axpy!", s]     = @benchmarkable BLAS.axpy!(samerand(), randvec($s), randvec($s))
g["scal!", s]     = @benchmarkable BLAS.scal!($s, samerand(), randvec($s), 1)
g["scal", s]      = @benchmarkable BLAS.scal($s, samerand(), randvec($s), 1)
g["ger!", s]      = @benchmarkable BLAS.ger!(samerand(), randvec($s), randvec($s), randmat($s))
g["syr!", s]      = @benchmarkable BLAS.syr!('U', 1.0, randvec($s), randmat($s))
g["syrk!", s]     = @benchmarkable BLAS.syrk!('U', 'N', samerand(), randmat($s), samerand(), randmat($s))
g["syrk", s]      = @benchmarkable BLAS.syrk('U', 'N', samerand(), randmat($s))
g["her!", s]      = @benchmarkable BLAS.her!('U', samerand(), randvec($C, $s), randmat($C, $s))
g["herk!", s]     = @benchmarkable BLAS.herk!('U', 'N', samerand(), randmat($C, $s), samerand(), randmat($C, $s))
g["herk", s]      = @benchmarkable BLAS.herk('U', 'N', samerand(), randmat($C, $s))
g["gbmv!", s]     = @benchmarkable BLAS.gbmv!('N', $s, 1, 1, samerand(), randmat($s), randvec($s), samerand(), randvec($s))
g["gbmv", s]      = @benchmarkable BLAS.gbmv('N', $s, 1, 1, samerand(), randmat($s), randvec($s))
g["sbmv!", s]     = @benchmarkable BLAS.sbmv!('U', $s-1, samerand(), randmat($s), randvec($s), samerand(), randvec($s))
g["sbmv", s]      = @benchmarkable BLAS.sbmv('U', $s-1, samerand(), randmat($s), randvec($s))
g["gemm!", s]     = @benchmarkable BLAS.gemm!('N', 'N', samerand(), randmat($s), randmat($s), samerand(), randmat($s))
g["gemm", s]      = @benchmarkable BLAS.gemm('N', 'N', samerand(), randmat($s), randmat($s))
g["gemv!", s]     = @benchmarkable BLAS.gemv!('N', samerand(), randmat($s), randvec($s), samerand(), randvec($s))
g["gemv", s]      = @benchmarkable BLAS.gemv('N', samerand(), randmat($s), randvec($s))
g["symm!", s]     = @benchmarkable BLAS.symm!('L', 'U', samerand(), randmat($s), randmat($s), samerand(), randmat($s))
g["symm", s]      = @benchmarkable BLAS.symm('L', 'U', samerand(), randmat($s), randmat($s))
g["symv!", s]     = @benchmarkable BLAS.symv!('U', samerand(), randmat($s), randvec($s), samerand(), randvec($s))
g["symv", s]      = @benchmarkable BLAS.symv('U', samerand(), randmat($s), randvec($s))
g["trmm!", s]     = @benchmarkable BLAS.trmm!('L', 'U', 'N', 'N', samerand(), randmat($s), randmat($s))
g["trmm", s]      = @benchmarkable BLAS.trmm('L', 'U', 'N', 'N', samerand(), randmat($s), randmat($s))
g["trsm!", s]     = @benchmarkable BLAS.trsm!('L', 'U', 'N', 'N', samerand(), randmat($s), randmat($s))
g["trsm", s]      = @benchmarkable BLAS.trsm('L', 'U', 'N', 'N', samerand(), randmat($s), randmat($s))
g["trmv!", s]     = @benchmarkable BLAS.trmv!('L', 'N', 'U', randmat($s), randvec($s))
g["trmv", s]      = @benchmarkable BLAS.trmv('L', 'N', 'U', randmat($s), randvec($s))
g["trsv!", s]     = @benchmarkable BLAS.trsv!('U', 'N', 'N', randmat($s), randvec($s))
g["trsv", s]      = @benchmarkable BLAS.trsv('U', 'N', 'N', randmat($s), randvec($s))


end # module
