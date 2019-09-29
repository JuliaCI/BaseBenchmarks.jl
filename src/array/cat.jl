issquare(A) = size(A, 1) == size(A, 2) && ndims(A) == 2

perf_hvcat(A, B) =  [A B; B A]

function perf_hvcat_setind(A, B)
    @assert issquare(A) && size(A) == size(B)
    n = size(A, 1)
    C = Matrix{Float64}(undef, 2n, 2n)
    C[1:n, 1:n] = A
    C[1:n, (n+1):end] = B
    C[(n+1):end, 1:n] = B
    C[(n+1):end, (n+1):end] = A
end

perf_hcat(A, B) = [A B B A]

function perf_hcat_setind(A, B)
    @assert issquare(A) && size(A) == size(B)
    n = size(A, 1)
    C = Matrix{Float64}(undef, n, 4n)
    C[:, 1:n] = A
    C[:, (n+1):2n] = B
    C[:, (2n+1):3n] = B
    C[:, (3n+1):end] = A
    return C
end

perf_vcat(A, B) = [A; B; B; A]

function perf_vcat_setind(A, B)
    @assert issquare(A) && size(A) == size(B)
    n = size(A, 1)
    C = Matrix{Float64}(undef, 4n, n)
    C[1:n, :] = A
    C[(n+1):2n, :] = B
    C[(2n+1):3n, :] = B
    C[(3n+1):4n, :] = A
    return C
end

function perf_catnd(n)
    A = samerand(1, n, n, 1)
    B = samerand(1, n, n)
    return cat(A, B, B, A; dims = 3)
end

function perf_catnd_setind(n)
    A = samerand(1, n, n, 1)
    B = samerand(1, n, n)
    C = Array{Float64}(undef, 1, n, 4n, 1)
    C[1, :, 1:n, 1] = A
    C[1, :, (n+1):2n, 1] = B
    C[1, :, (2n+1):3n, 1] = B
    C[1, :, (3n+1):4n, 1] = A
    return C
end

function perf_cat_4467()
    a, b, c, d, e = 1.0, 2.0, 3.0, 4.0, 5
    return [a, b, c, d, e]
end
