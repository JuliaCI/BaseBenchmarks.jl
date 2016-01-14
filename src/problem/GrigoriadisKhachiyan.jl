module GrigoriadisKhachiyan

import BaseBenchmarks

# Code from Dilys Thomas <dilys@cs.stanford.edu>

function myunifskew(n)
    A = zeros(n, n)
    for i=1:n
        for j=1:i-1
            temp=BaseBenchmarks.samerand()
            if (temp < 0.5)
                temp = BaseBenchmarks.samerand()
                A[i,j]= temp
                A[j,i]= -A[i,j]
            else
                temp = BaseBenchmarks.samerand()
                A[j,i]= temp
                A[i,j]= -A[j,i]
            end
        end
    end
    return A
end

function perf_gk(n, myeps)
    A = myunifskew(n)
    g = length(myeps)
    iteration = zeros(g)
    times = zeros(g)

    for KK = 1:g
        eps = myeps[KK]
        e, X, U = ones(n), zeros(n), zeros(n)
        t, stop, iter = 0, 0, 0
        p = e./n
        epse = eps .* e
        csum = zeros(n)

        while(stop != 1)
            t = t+1
            iter = t

            for i=1:n
                csum[i] = sum(p[1:i])
            end

            marker = BaseBenchmarks.samerand()

            k = 1
            for i = 2:n
                if csum[i-1] <= marker && marker <= csum[i]
                    k=i
                    break
                end
            end

            X[k] += 1

            for i=1:n
                U[i] += A[i,k]
            end

            s = sum(p[1:n] .* exp((eps/2)*A[1:n,k]))

            for i=1:n
                p[i]=(p[i]*exp((eps/2)*A[i,k])) / s
            end

            u = U ./ t

            true_count = 0
            for i=1:n
                if u[i] <= epse[i]
                    true_count += 1
                end
            end

            if true_count == n
                stop = 1
            end
        end

        times[KK] = 0
        iteration[KK] = iter
        x = X/t
        etx=sum(x)
        AX = A*X
        Ax = A*x
        error=abs(AX)-abs(U)
        Axepse = 0

        for i=1:n
            if Ax[i]<=epse[i]
                Axepse = Axepse+1
            end
        end

        errorlmt = 0

        for i=1:n
            if error[i]<1e-8
                errorlmt = errorlmt+1
            end
        end
    end
end

end # module
