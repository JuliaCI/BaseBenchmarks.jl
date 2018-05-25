module Laplace3D

# This is a simple 7 point stencil on a 3D grid. It is bandwidth-bound. The code
# doesn't handle corner cases at the grid edges, so each dimension must be 4n+2
# for SSE or 8n+2 for AVX.

using Base.Cartesian
using Base.Threads

if VERSION >= v"0.7.0-DEV.3052"
    using Printf
end

const SIXTH = 1.0f0/6.0f0
const ERROR_TOL = 0.00001

function stencil3d(u::Array{Float32,3}, k_1::Int64, k_2::Int64, k_3::Int64)
    return (u[k_1-1, k_2,   k_3  ] + u[k_1+1, k_2,   k_3] +
            u[k_1,   k_2-1, k_3  ] + u[k_1,   k_2+1, k_3] +
            u[k_1,   k_2,   k_3-1] + u[k_1,   k_2,   k_3+1]) * SIXTH
end

function l3d_orig(u1::Array{Float32,3}, u3::Array{Float32,3},
                  nx::Int64, ny::Int64, nz::Int64)
    @nloops 3 k u1 begin
        if @nany 3 d->(k_d == 1 || k_d == size(u1, d))
            @inbounds (@nref 3 u3 k) = (@nref 3 u1 k)
        else
            @inbounds (@nref 3 u3 k) = stencil3d(u1, k_1, k_2, k_3)
        end
    end
end

# @threads 'call' form
function l3d_threadfun(u1, u3, nx, ny, nz)
    tid = threadid()
    tnz, rem = divrem(nz-2, nthreads())
    z_start = 2 + ((tid-1) * tnz)
    z_end = z_start + tnz - 1
    if tid <= rem
        z_start = z_start + tid - 1
        z_end = z_end + tid
    else
        z_start = z_start + rem
        z_end = z_end + rem
    end

    for k_3 = z_start:z_end
        for k_2 = 2:ny-1
            @simd for k_1 = 2:nx-1
                @inbounds u3[k_1, k_2, k_3] = stencil3d(u1, k_1, k_2, k_3)
            end
        end
    end
end

# @threads 'for' form
function l3d_threadfor(u1, u3, nx, ny, nz)
    @threads for k_3=2:nz-1
        for k_2 = 2:ny-1
            @simd for k_1 = 2:nx-1
                @inbounds u3[k_1, k_2, k_3] = stencil3d(u1, k_1, k_2, k_3)
            end
        end
    end
end

function perf_laplace3d(nx=290, ny=290, nz=290; verify=false)
    u1 = Array{Float32,3}(undef, nx, ny, nz)
    u3 = Array{Float32,3}(undef, nx, ny, nz)
    @nloops 3 k u1 begin
        if @nany 3 d->(k_d == 1 || k_d == size(u1, d))
            (@nref 3 u3 k) = (@nref 3 u1 k) = 1.0
        else
            (@nref 3 u1 k) = 0.0
        end
    end
    l3d_threadfor(u1, u3, nx, ny, nz)
    if verify
        u1_orig = Array{Float32,3}(undef, nx, ny, nz)
        u3_orig = Array{Float32,3}(undef, nx, ny, nz)
        @nloops 3 k u1_orig begin
            if @nany 3 d->(k_d == 1 || k_d == size(u1_orig, d))
                (@nref 3 u3_orig k) = (@nref 3 u1_orig k) = 1.0
            else
                (@nref 3 u1_orig k) = 0.0
            end
        end
        l3d_orig(u1_orig, u3_orig, nx, ny, nz)
        @nloops 3 k u1 begin
            if abs((@nref 3 u1 k) - (@nref 3 u1_orig k)) > ERROR_TOL
                error(@sprintf("Verify error: %f - %f [%d, %d, %d]\n",
                      (@nref 3 u1 k), (@nref 3 u1_orig k), k_1, k_2, k_3))
            end
        end
    end
end

end # module
