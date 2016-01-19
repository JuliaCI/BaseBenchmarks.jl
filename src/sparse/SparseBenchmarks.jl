module SparseBenchmarks

import BaseBenchmarks
using BenchmarkTrackers, BaseBenchmarks.samerand

samesprand(args...) = sprand(MersenneTwister(1), args...)
samesprandbool(args...) = sprandbool(MersenneTwister(1), args...)

############
# indexing #
############

# Note that the below tests tagged "sparse logical" are commented out because
# they require find(::SparseVector) to be defined; see JuliaLang/julia#14717.

# vector #
#--------#

@track BaseBenchmarks.TRACKER begin
    @setup begin
        lens = (10^3, 10^4, 10^5)
        vectors = map(n -> samesprand(n, inv(sqrt(n))), lens)
        iter = zip(lens, vectors)
        splogvecs = map(n -> samesprandbool(n, 1e-5), lens)
        splogiter = zip(lens, vectors, splogvecs)
    end
    @benchmarks "sparse vector indexing" begin
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
    splogvecs = map(n -> samesprandbool(n, 1e-5), lens)
    splogmats = map(n -> samesprandbool(n, n, 1e-5), lens)

    iter = zip(lens, matrices, inds)
    arr_iter = zip(lens, matrices, vectors, inds)
    log_iter = zip(lens, matrices, logvecs, inds)
    splogvec_iter = zip(lens, matrices, splogvecs, inds)
    splogmat_iter = zip(lens, matrices, splogmats, inds)

    @track BaseBenchmarks.TRACKER begin
        @benchmarks "sparse matrix row indexing" begin
            [("array", n, nnz(A), c) => getindex(A, V, c) for (n, A, V, c) in arr_iter]
            [("range", n, nnz(A), c) => getindex(A, 1:n, c) for (n, A, c) in iter]
            [("dense logical", n, nnz(A), c) => getindex(A, L, c) for (n, A, L, c) in log_iter]
            # [("sparse logical", n, nnz(A), nnz(L), c) => getindex(A, L, c) for (n, A, L, c) in splog_iter]
        end
        @tags "sparse" "indexing" "array" "getindex" "matrix" "row"
    end

    @track BaseBenchmarks.TRACKER begin
        @benchmarks "sparse matrix column indexing" begin
            [("array", n, nnz(A), r) => getindex(A, r, V) for (n, A, V, r) in arr_iter]
            [("range", n, nnz(A), r) => getindex(A, r, 1:n) for (n, A, r) in iter]
            [("dense logical", n, nnz(A), r) => getindex(A, r, L) for (n, A, L, r) in log_iter]
            # [("sparse logical", n, nnz(A), nnz(L), r) => getindex(A, r, L) for (n, A, L, r) in splog_iter]
        end
        @tags "sparse" "indexing" "array" "getindex" "matrix" "column"
    end

    @track BaseBenchmarks.TRACKER begin
        @benchmarks "sparse matrix row + column indexing" begin
            [("array", n, nnz(A)) => getindex(A, V, V) for (n, A, V, r) in arr_iter]
            [("integer", n, nnz(A), r) => getindex(A, r, r) for (n, A, r) in iter]
            [("range", n, nnz(A)) => getindex(A, 1:n, 1:n) for (n, A, r) in iter]
            [("dense logical", n, nnz(A)) => getindex(A, L, L) for (n, A, L, r) in log_iter]
            [("sparse logical", n, nnz(A), nnz(L)) => getindex(A, L) for (n, A, L, r) in splogmat_iter]
        end
        @tags "sparse" "indexing" "array" "getindex" "matrix" "row" "column"
    end
end


end # module