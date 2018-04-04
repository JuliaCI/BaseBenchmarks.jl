module SparseFEM

using Compat

if VERSION >= v"0.7.0-DEV.3389"
    using SparseArrays
end
if VERSION >= v"0.7.0-DEV.3449"
    using LinearAlgebra
end

# assemble the finite-difference laplacian
function fdlaplacian(N)
    # create a 1D laplacian and a sparse identity
    fdl1 = spdiagm(-1 => ones(N-1), 0 => -2*ones(N), 1 => ones(N-1))
    # laplace operator on the full grid
    I_N = sparse(1.0I, N, N)
    return kron(I_N, fdl1) + kron(fdl1, I_N)
end

# get the list of boundary dof-indices
function get_free(N)
    L = zeros(Int, N, N)
    L[2:N-1, 2:N-1] .= 1
    return findall(!iszero, L)
end

# timing of assembly, slice and solve
function perf_sparse_fem(N)
    Ifree = [LinearIndices((N, N))[i] for i in get_free(N)]
    # assembly
    A = fdlaplacian(N)
    # boundary condition
    B = A[Ifree, Ifree]
    # solver
    return lufact(B)
end

end # module
