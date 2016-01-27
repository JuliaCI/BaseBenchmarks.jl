function perf_rev_load_slow!(x)
    n = size(x, 1)
    for i = (n - 1):-1:1
        x[i] = x[i + 1]
    end
    return x
end

function perf_rev_load_fast!(x)
    n = size(x, 1)
    x_ = x[n]
    for i = (n - 1):-1:1
        x_ = x[i] = x_
    end
    return x
end

function perf_rev_loadmul_slow!(x, c)
    n = size(x, 1)
    for i = (n - 1):-1:1
        x[i] = c[i + 1] * x[i + 1]
    end
    return x
end

function perf_rev_loadmul_fast!(x, c)
    n = size(x, 1)
    x_ = x[n]
    for i = (n - 1):-1:1
        x_ = x[i] = c[i + 1] * x_
    end
    return x
end
