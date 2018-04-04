if VERSION >= v"0.7.0-DEV.1660"
    _maxind(A) = argmax(A).I
else
    _maxind(A) = CartesianIndices(Compat.axes(A))[argmax(A)].I
end

function perf_lucompletepivCopy!(A)
    n = size(A, 1)
    rowpiv=zeros(Int, n-1)
    colpiv=zeros(Int, n-1)
    for k = 1:n-1
        As = abs.(A[k:n, k:n])
        μ, λ = _maxind(As)
        μ += k-1; λ += k-1
        rowpiv[k] = μ
        A[[k,μ], 1:n] = A[[μ,k], 1:n]
        colpiv[k] = λ
        A[1:n, [k,λ]] = A[1:n, [λ,k]]
        if A[k,k] ≠ 0
            ρ = k+1:n
            A[ρ, k] = A[ρ, k]/A[k, k]
            A[ρ, ρ] = A[ρ, ρ] - A[ρ, k:k] * A[k:k, ρ]
        end
    end
    return (A, rowpiv, colpiv)
end

function perf_lucompletepivSub!(A)
    n = size(A, 1)
    rowpiv=zeros(Int, n-1)
    colpiv=zeros(Int, n-1)
    for k = 1:n-1
        As = abs.(view(A, k:n, k:n))
        μ, λ = _maxind(As)
        μ += k-1; λ += k-1
        rowpiv[k] = μ
        A[[k,μ], 1:n] = view(A, [μ,k], 1:n)
        colpiv[k] = λ
        A[1:n, [k,λ]] = view(A, 1:n, [λ,k])
        if A[k,k] ≠ 0
            ρ = k+1:n
            A[ρ, k] = view(A, ρ, k)/A[k, k]
            A[ρ, ρ] = view(A, ρ, ρ) - view(A, ρ, k:k) * view(A, k:k, ρ)
        end
    end
    return (A, rowpiv, colpiv)
end
