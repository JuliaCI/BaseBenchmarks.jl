module SparseFEM

using Compat

if VERSION >= v"0.7.0-DEV.2116"
    const _spdiagm = spdiagm
else
    _spdiagm(pairs::Pair{<:Integer,<:AbstractArray}...) = spdiagm(last.(pairs), first.(pairs))
end

# assemble the finite-difference laplacian
function fdlaplacian(N)
    # create a 1D laplacian and a sparse identity
    fdl1 = _spdiagm(-1 => ones(N-1), 0 => -2*ones(N), 1 => ones(N-1))
    # laplace operator on the full grid
    return kron(speye(N), fdl1) + kron(fdl1, speye(N))
end

# get the list of boundary dof-indices
function get_free(N)
    L = zeros(Int, N, N)
    L[2:N-1, 2:N-1] = 1
    return find(!iszero, L)
end

# timing of assembly, slice and solve
function perf_sparse_fem(N)
    Ifree = get_free(N)
    # assembly
    A = fdlaplacian(N)
    # boundary condition
    B = A[Ifree, Ifree]
    # solver
    return lufact(B)
end

end # module
