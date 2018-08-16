#######################
# recursive fibonacci #
#######################

perf_micro_fib(n) = n < 2 ? n : perf_micro_fib(n-1) + perf_micro_fib(n-2)

############
# parseint #
############

if VERSION >= v"0.7.0-DEV.3526"
    _parse16(s) = parse(Int64, s, base=16)
else
    _parse16(s) = parse(Int64, s, 16)
end

if VERSION >= v"0.7.0-DEV.4446"
    _hex(s) = string(s, base=16)
else
    _hex(s) = hex(s)
end


function perf_micro_parseint(t)
    local n, m
    for i=1:t
        n = rand(UInt32)
        s = _hex(n)
        m = UInt32(_parse16(s))
    end
    @assert m == n
    return n
end

##############
# mandelbrot #
##############

function mandel(z)
    c = z
    maxiter = 80
    for n = 1:maxiter
        if abs(z) > 2
            return n-1
        end
        z = z^2 + c
    end
    return maxiter
end

perf_micro_mandel() = [mandel(complex(r,i)) for i=-1.:.1:1., r=-2.0:.1:0.5]

#############
# quicksort #
#############

function quicksort!(a, lo, hi)
    i, j = lo, hi
    while i < hi
        pivot = a[(lo+hi)>>>1]
        while i <= j
            while a[i] < pivot; i += 1; end
            while a[j] > pivot; j -= 1; end
            if i <= j
                a[i], a[j] = a[j], a[i]
                i, j = i+1, j-1
            end
        end
        if lo < j; quicksort!(a,lo,j); end
        lo, j = i, hi
    end
    return a
end

perf_micro_quicksort(n) = quicksort!(rand(n), 1, n)

########
# πsum #
########

function perf_micro_pisum()
    sum = 0.0
    for j = 1:500
        sum = 0.0
        for k = 1:10000
            sum += 1.0/(k*k)
        end
    end
    return sum
end

###############
# randmatstat #
###############

if VERSION >= v"0.7.0-DEV.3204"
    _at_mul_b(A, B) = transpose(A)*B
else
    _at_mul_b(A, B) = At_mul_B(A, B)
end

if VERSION >= v"0.7.0-DEV.5238"
    # std in StatsBase instead of in Base
    function stdmean(x)
        n = length(x)
        m = mean(x)
        sqrt(sum(xi->abs2(xi - m), x) / (n - 1)) / m
    end
else
    stdmean(x) = std(x) / mean(x)
end

if VERSION < v"0.7.0-DEV.4591"
    _tr(x) = trace(x)
else
    _tr(x) = tr(x)
end
function perf_micro_randmatstat(t)
    n = 5
    v = zeros(t)
    w = zeros(t)
    for i=1:t
        a = randn(n,n)
        b = randn(n,n)
        c = randn(n,n)
        d = randn(n,n)
        P = [a b c d]
        Q = [a b; c d]
        v[i] = _tr(_at_mul_b(P,P)^4)
        w[i] = _tr(_at_mul_b(Q,Q)^4)
    end
    return (stdmean(v), stdmean(w))
end

##############
# randmatmul #
##############

perf_micro_randmatmul(t) = rand(t,t)*rand(t,t)


#################
# print_to_file #
#################

if VERSION > v"0.7.0-DEV.3026"
    using Printf
end

function perf_printfd(n)
    open("/dev/null", "w") do io
        for i = 1:n
            @printf(io, "%d %d\n", i, i + 1)
        end
    end
end
