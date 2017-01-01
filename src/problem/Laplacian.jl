module Laplacian

using Compat

import Compat: UTF8String, view

################################
# Sparse Matrix * Dense Vector #
################################

# https://github.com/JuliaLang/julia/issues/4707

# creates a sparse matrix from its diagonals and generates
# 1D derivatives via finite difference on a staggered grid
function ddx_spdiags(m)
    B = ones(m)*[-1 1]
    d = [0, 1]
    n = m + 1
    p = length(d)
    len = zeros(Int, p+1, 1)

    for k = 1:p
        len[k+1] = len[k] + length(max(1,1-d[k]):min(m,n-d[k]))
    end

    a = zeros(Int, len[p+1], 3)

    # Append new d[k]-th diagonal to compact form
    for k = 1:p
        i = max(1,1-d[k]):min(m,n-d[k])
        a[(len[k]+1):len[k+1],:] = [i i+d[k] B[i+(m>=n)*d[k],k]]
    end

    return sparse(a[:,1], a[:,2], a[:,3], m, n)
end

function laplace_sparse_matvec(n1, n2, n3)
    D1 = kron(speye(n3), kron(speye(n2), ddx_spdiags(n1)))
    D2 = kron(speye(n3), kron(ddx_spdiags(n2), speye(n1)))
    D3 = kron(ddx_spdiags(n3), kron(speye(n2), speye(n1)))
    D = [D1 D2 D3] # divergence from faces to cell-centers
    return D*D'
end

function perf_laplace_sparse_matvec(N)
    @assert isinteger(cbrt(N)) "input must have integer cbrt"
    n = Int(cbrt(N)) # makes output sizes match up with other perf_laplace benchmarks
    return laplace_sparse_matvec(n, n, n)
end

#####################
# Iterative Methods #
#####################

function perf_laplace_iter_devec(N)
    u = zeros(N, N)
    u[1, :] = 1
    Niter = 2^10
    dx2 = 0.1*0.1
    dy2 = dx2
    uout = copy(u)
    for iter = 1:Niter
        for i = 2:N-1
            for j = 2:N-1
                uout[i,j] = ((u[i-1, j] + u[i+1, j])*dy2 + (u[i, j-1] + u[i, j+1])*dx2) * (1 / (2*(dx2+dy2)))
            end
        end
        u, uout = uout, u
    end
    return u
end

function perf_laplace_iter_vec(N)
    u = zeros(N, N)
    u[1,:] = 1
    Niter = 2^10
    dx2 = dy2 = 0.1*0.1
    for i = 1:Niter
        @compat u[2:N-1, 2:N-1] .= ((u[1:N-2, 2:N-1] .+ u[3:N, 2:N-1]).*dy2 .+ (u[2:N-1, 1:N-2] .+ u[2:N-1, 3:N]).*dx2) .* (1 / (2*(dx2+dy2)))
    end
    return u
end

function perf_laplace_iter_sub(N)
    u = zeros(N, N)
    u[1,:] = 1
    Niter = 2^10
    dx2 = dy2 = 0.1*0.1
    u0 = view(u, 2:N-1, 2:N-1)
    u1 = view(u, 1:N-2, 2:N-1)
    u2 = view(u, 3:N,   2:N-1)
    u3 = view(u, 2:N-1, 1:N-2)
    u4 = view(u, 2:N-1, 3:N)
    for i = 1:Niter
        @compat u0 .= ((u1 .+ u2).*dy2 .+ (u3 .+ u4).*dx2) .* (1 / (2*(dx2+dy2)))
    end
    return u
end

end # module
