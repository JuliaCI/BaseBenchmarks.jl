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
    vstr = typename(Vector)
    v = randvec(s)
    g["+", vstr, vstr, s] = @benchmarkable +($v, $v)
    g["-", vstr, vstr, s] = @benchmarkable -($v, $v)
    for M in MATS
        mstr = typename(M)
        m = linalgmat(M, s)
        g["*", mstr, vstr, s] = @benchmarkable *($m, $v)
        g["\\", mstr, vstr, s] = @benchmarkable \($m, $v)
        g["+", mstr, mstr, s] = @benchmarkable +($m, $m)
        g["-", mstr, mstr, s] = @benchmarkable -($m, $m)
        g["*", mstr, mstr, s] = @benchmarkable *($m, $m)
    end
    for M in DIVMATS
        mstr = typename(M)
        m = linalgmat(M, s)
        g["/", mstr, mstr, s] = @benchmarkable /($m, $m)
        g["\\", mstr, mstr, s] = @benchmarkable \($m, $m)
    end
end

##################
# factorizations #
##################

g = addgroup!(GROUPS, "factorization", ["array", "linalg", "factorization", "eig", "eigfact",
                                        "svd", "svdfact", "lu", "lufact", "qr", "qrfact",
                                        "schur", "schurfact", "chol", "cholfact"])

for M in (Matrix, Diagonal, Bidiagonal, SymTridiagonal, UpperTriangular, LowerTriangular)
    mstr = typename(M)
    for s in SIZES
        m = linalgmat(M, s)
        g["eig", mstr, s] = @benchmarkable eig($m)
        g["eigfact", mstr, s] = @benchmarkable eigfact($m)
    end
end

for M in (Matrix, Diagonal, Bidiagonal, UpperTriangular, LowerTriangular)
    mstr = typename(M)
    for s in SIZES
        m = linalgmat(M, s)
        g["svd", mstr, s] = @benchmarkable svd($m)
        g["svdfact", mstr, s] = @benchmarkable svdfact($m)
    end
end

for M in (Matrix, Tridiagonal)
    mstr = typename(M)
    for s in SIZES
        m = linalgmat(M, s)
        g["lu", mstr, s] = @benchmarkable lu($m)
        g["lufact", mstr, s] = @benchmarkable lufact($m)
    end
end

for s in SIZES
    mstr = typename(Matrix)
    m = randmat(s)
    arr = randmat(s)'*randmat(s)
    g["chol", mstr, s] = @benchmarkable chol($arr)
    g["cholfact", mstr, s] = @benchmarkable cholfact($arr)
    g["schur", mstr, s] = @benchmarkable schur($m)
    g["schurfact", mstr, s] = @benchmarkable schurfact($m)
    g["qr", mstr, s] = @benchmarkable qr($m)
    g["qrfact", mstr, s] = @benchmarkable qrfact($m)
end

########
# BLAS #
########

g = addgroup!(GROUPS, "blas", ["array", "linalg"])

s = 1024
C = Complex{Float64}
n = samerand()
cn = samerand(C)
v = randvec(s)
cv = randvec(C, s)
m = randmat(s)
cm = randmat(C, s)

g["dot", s]       = @benchmarkable BLAS.dot($s, $v, 1, $v, 1)
g["dotu", s]      = @benchmarkable BLAS.dotu($s, $cv, 1, $cv, 1)
g["dotc", s]      = @benchmarkable BLAS.dotc($s, $cv, 1, $cv, 1)
g["blascopy!", s] = @benchmarkable BLAS.blascopy!($s, $v, 1, $v, 1)
g["nrm2", s]      = @benchmarkable BLAS.nrm2($s, $v, 1)
g["asum", s]      = @benchmarkable BLAS.asum($s, $v, 1)
g["axpy!", s]     = @benchmarkable BLAS.axpy!($n, $v, fill!($v, $n))
g["scal!", s]     = @benchmarkable BLAS.scal!($s, $n, fill!($v, $n), 1)
g["scal", s]      = @benchmarkable BLAS.scal($s, $n, $v, 1)
g["ger!", s]      = @benchmarkable BLAS.ger!($n, $v, $v, fill!($m, $n))
g["syr!", s]      = @benchmarkable BLAS.syr!('U', 1.0, $v, fill!($m, $n))
g["syrk!", s]     = @benchmarkable BLAS.syrk!('U', 'N', $n, $m, $n, fill!($m, $n))
g["syrk", s]      = @benchmarkable BLAS.syrk('U', 'N', $n, $m)
g["her!", s]      = @benchmarkable BLAS.her!('U', $n, $cv, fill!($cm, $cn))
g["herk!", s]     = @benchmarkable BLAS.herk!('U', 'N', $n, $cm, $n, fill!($cm, $cn))
g["herk", s]      = @benchmarkable BLAS.herk('U', 'N', $n, $cm)
g["gbmv!", s]     = @benchmarkable BLAS.gbmv!('N', $s, 1, 1, $n, $m, $v, $n, fill!($v, $n))
g["gbmv", s]      = @benchmarkable BLAS.gbmv('N', $s, 1, 1, $n, $m, $v)
g["sbmv!", s]     = @benchmarkable BLAS.sbmv!('U', $s-1, $n, $m, $v, $n, fill!($v, $n))
g["sbmv", s]      = @benchmarkable BLAS.sbmv('U', $s-1, $n, $m, $v)
g["gemm!", s]     = @benchmarkable BLAS.gemm!('N', 'N', $n, $m, $m, $n, fill!($m, $n))
g["gemm", s]      = @benchmarkable BLAS.gemm('N', 'N', $n, $m, $m)
g["gemv!", s]     = @benchmarkable BLAS.gemv!('N', $n, $m, $v, $n, fill!($v, $n))
g["gemv", s]      = @benchmarkable BLAS.gemv('N', $n, $m, $v)
g["symm!", s]     = @benchmarkable BLAS.symm!('L', 'U', $n, $m, $m, $n, fill!($m, $n))
g["symm", s]      = @benchmarkable BLAS.symm('L', 'U', $n, $m, $m)
g["symv!", s]     = @benchmarkable BLAS.symv!('U', $n, $m, $v, $n, fill!($v, $n))
g["symv", s]      = @benchmarkable BLAS.symv('U', $n, $m, $v)
g["trmm!", s]     = @benchmarkable BLAS.trmm!('L', 'U', 'N', 'N', $n, $m, fill!($m, $n))
g["trmm", s]      = @benchmarkable BLAS.trmm('L', 'U', 'N', 'N', $n, $m, $m)
g["trsm!", s]     = @benchmarkable BLAS.trsm!('L', 'U', 'N', 'N', $n, $m, fill!($m, $n))
g["trsm", s]      = @benchmarkable BLAS.trsm('L', 'U', 'N', 'N', $n, $m, $m)
g["trmv!", s]     = @benchmarkable BLAS.trmv!('L', 'N', 'U', $m, fill!($v, $n))
g["trmv", s]      = @benchmarkable BLAS.trmv('L', 'N', 'U', $m, $v)
g["trsv!", s]     = @benchmarkable BLAS.trsv!('U', 'N', 'N', $m, fill!($v, $n))
g["trsv", s]      = @benchmarkable BLAS.trsv('U', 'N', 'N', $m, $v)

end # module
