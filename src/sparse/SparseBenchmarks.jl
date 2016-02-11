module SparseBenchmarks

import ..BaseBenchmarks
using ..BenchmarkTrackers
using ..RandUtils

samesprand(args...) = sprand(MersenneTwister(1), args...)
samesprandbool(args...) = sprandbool(MersenneTwister(1), args...)

############
# indexing #
############

# Note that some of the code related to the "sparse logical" tests is commented
# out because it requires resolution of JuliaLang/julia#14717.

# vector #
#--------#

@track BaseBenchmarks.TRACKER "sparse vector indexing" begin
    @setup begin
        lens = (10^3, 10^4, 10^5)
        if VERSION < v"0.5.0-dev+763"
            vectors = map(n -> samesprand(n, 1, inv(sqrt(n))), lens)
            splogvecs = map(n -> samesprandbool(n, 1, 1e-5), lens)
        else
            vectors = map(n -> samesprand(n, inv(sqrt(n))), lens)
            splogvecs = map(n -> samesprandbool(n, 1e-5), lens)
        end
        iter = zip(lens, vectors)
        splog_iter = zip(lens, vectors, splogvecs)
    end
    @benchmarks begin
        [("array", n, nnz(V)) => getindex(V, samerand(1:n, n)) for (n, V) in iter]
        [("integer", n, nnz(V)) => getindex(V, samerand(1:n)) for (n, V) in iter]
        [("range", n, nnz(V)) => getindex(V, 1:n) for (n, V) in iter]
        [("dense logical", n, nnz(V)) => getindex(V, samerand(Bool, n)) for (n, V) in iter]
        # [("sparse logical", n, nnz(V), nnz(L)) => getindex(V, L) for (n, V, L) in splogiter]
    end
    @tags "sparse" "indexing" "array" "getindex" "vector"
end

# matrix #
#--------#

let
    lens = (10, 10^2, 10^3)
    inds = map(n -> samerand(1:n), lens)
    matrices = map(n -> samesprand(n, n, inv(sqrt(n))), lens)
    vectors = map(n -> samerand(1:n, n), lens)
    logvecs = map(n -> samerand(Bool, n), lens)
    # splogvecs = map(n -> samesprandbool(n, 1e-5), lens)
    splogmats = map(n -> samesprandbool(n, n, 1e-5), lens)

    iter = zip(lens, matrices, inds)
    arr_iter = zip(lens, matrices, vectors, inds)
    log_iter = zip(lens, matrices, logvecs, inds)
    # splogvec_iter = zip(lens, matrices, splogvecs, inds)
    splogmat_iter = zip(lens, matrices, splogmats, inds)

    @track BaseBenchmarks.TRACKER "sparse matrix row indexing" begin
        @benchmarks begin
            [("array", n, nnz(A), c) => getindex(A, V, c) for (n, A, V, c) in arr_iter]
            [("range", n, nnz(A), c) => getindex(A, 1:n, c) for (n, A, c) in iter]
            [("dense logical", n, nnz(A), c) => getindex(A, L, c) for (n, A, L, c) in log_iter]
            # [("sparse logical", n, nnz(A), nnz(L), c) => getindex(A, L, c) for (n, A, L, c) in splogvec_iter]
        end
        @tags "sparse" "indexing" "array" "getindex" "matrix" "row"
    end

    @track BaseBenchmarks.TRACKER  "sparse matrix column indexing" begin
        @benchmarks begin
            [("array", n, nnz(A), r) => getindex(A, r, V) for (n, A, V, r) in arr_iter]
            [("range", n, nnz(A), r) => getindex(A, r, 1:n) for (n, A, r) in iter]
            [("dense logical", n, nnz(A), r) => getindex(A, r, L) for (n, A, L, r) in log_iter]
            # [("sparse logical", n, nnz(A), nnz(L), r) => getindex(A, r, L) for (n, A, L, r) in splogvec_iter]
        end
        @tags "sparse" "indexing" "array" "getindex" "matrix" "column"
    end

    @track BaseBenchmarks.TRACKER "sparse matrix row + column indexing" begin
        @benchmarks  begin
            [("array", n, nnz(A)) => getindex(A, V, V) for (n, A, V, r) in arr_iter]
            [("integer", n, nnz(A), r) => getindex(A, r, r) for (n, A, r) in iter]
            [("range", n, nnz(A)) => getindex(A, 1:n, 1:n) for (n, A, r) in iter]
            [("dense logical", n, nnz(A)) => getindex(A, L, L) for (n, A, L, r) in log_iter]
            [("sparse logical", n, nnz(A), nnz(L)) => getindex(A, L) for (n, A, L, r) in splogmat_iter]
        end
        @tags "sparse" "indexing" "array" "getindex" "matrix" "row" "column"
    end
end

######################
# transpose (#14631) #
######################

@track BaseBenchmarks.TRACKER "sparse matrix transpose" begin
    @setup begin
        small_sqr = samesprand(600, 600, 0.01)
        small_rct = samesprand(600, 400, 0.01)
        large_sqr = samesprand(20000, 20000, 0.01)
        large_rct = samesprand(20000, 10000, 0.01)
        spmats = (small_sqr, small_rct, large_sqr, large_rct)
        complex_spmats = map(A -> A + A*im, spmats)
    end
    @benchmarks begin
        [(:transpose, size(A)) => transpose(A) for A in spmats]
        [(:transpose!, size(A)) => transpose!(A.', A) for A in spmats]
        [(:ctranspose, size(A)) => ctranspose(A) for A in complex_spmats]
        [(:ctranspose!, size(A)) => ctranspose!(A.', A) for A in complex_spmats]
    end
    @tags "sparse" "array" "ctranspose" "transpose" "matrix"
end

end # module
