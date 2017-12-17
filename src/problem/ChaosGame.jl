module ChaosGameFractals

# Create chaosgame-like fractals
# Translated from https://github.com/python/performance/blob/2ebc46c24c5f816234d8026698470476a3c59d2e/performance/benchmarks/bm_chaos.py
# to Julia
# Original Copyright (C) 2005 Carl Friedrich Bolz

if VERSION >= v"0.7.0-DEV.3052"
    using Printf
end

const DEFAULT_THICKNESS = 0.25
const DEFAULT_WIDTH = 256
const DEFAULT_HEIGHT = 256
const DEFAULT_ITERATIONS = 500000 # 100x more iterations than Python
const DEFAULT_RNG_SEED = 1234

###########
# GVector #
###########

struct GVector{T <: Number}
    x::T
    y::T
    z::T
end

GVector(x=0.0, y=0.0, z=0.0) = GVector(x, y, z)

Base.abs(u::GVector) = sqrt(u.x^2 + u.y^2 + u.z^2)
dist(u::GVector, v::GVector) = sqrt((u.x - v.x)^2 +
                                    (u.y - v.y)^2 +
                                    (u.z - v.z)^2)
Base.:+(u::GVector, v::GVector) = GVector(u.x + v.x, u.y + v.y, u.z + v.z)
Base.:-(u::GVector, v::GVector) = u + (v * -1)
Base.:*(u::GVector, n::Number)= GVector(u.x * n, u.y * n, u.z * n)

function linear_combination(u::GVector, v::GVector, l1, l2=1-l1)
    return GVector(u.x * l1 + v.x * l2,
                   u.y * l1 + v.y * l2,
                   u.z * l1 + v.z * l2,)
end

Base.show(io::IO, u::GVector) = print(io, "<", u.x, ", ", u.y, ", ", u.z, ">")

function getknots(points::Vector{V}, degree::Int) where V <: GVector
    knots = [zeros(Int, degree); 1:(length(points) - degree)]
    append!(knots, fill(length(points) - degree, degree))
    return knots
end


##########
# Spline #
##########

struct Spline{T}
    knots::Vector{Int}
    points::Vector{GVector{T}}
    degree::Int
    d::Vector{GVector{T}}
end

function Spline(points, degree=3, knots = getknots(points, degree))
    if length(points) >  length(knots) - degree + 1
        throw(ArgumentError("too many control points"))
    elseif length(points) < length(knots) - degree + 1
        throw(ArgumentError("not enough control points"))
    elseif any(i -> knots[i] < knots[i-1], 2:length(knots))
        throw(ArgumentError("knots not strictly increasing"))
    end
    Spline(knots, points, degree, similar(points))
end

Base.length(s::Spline) = length(s.points)
getdomain(s::Spline) = s.knots[s.degree], s.knots[length(s.knots) - s.degree + 1]

function Base.getindex(s::Spline, u::Number)
    dom = getdomain(s)
    I = dom[2] - 1
    for ii in (s.degree - 1):(length(s.knots) - s.degree - 1)
        if u >= s.knots[ii + 1] && u < s.knots[ii + 2]
            I = ii
            break
        end
    end
    return I
end

function (s::Spline)(u::Number)
    dom = getdomain(s)
    if u < dom[1] || u > dom[2]
        throw(ArgumentError("Function value not in domain"))
    elseif u == dom[1]
        return s.points[1]
    elseif u == dom[2]
        return s.points[end]
    end
    I = getindex(s, u)
    @inbounds for ii in 0:s.degree
        s.d[ii+1] = s.points[I - s.degree + ii + 2]
    end
    U = s.knots
    @inbounds for ik in 1:s.degree
        for ii in (I - s.degree + ik + 1):(I + 1)
            ua = U[ii + s.degree - ik + 1]
            ub = U[ii]
            co1 = (ua - u) / (ua - ub)
            co2 = (u - ub) / (ua - ub)
            index = ii - I + s.degree - ik - 1
            s.d[index+1] = linear_combination(s.d[index+1], s.d[index + 2], co1, co2)
        end
    end
    return s.d[1]
end

#############
# ChaosGame #
#############

struct ChaosGame{T <: Number}
    splines::Vector{Spline{T}}
    thickness::T
    minx::T
    miny::T
    maxx::T
    maxy::T
    height::T
    width::T
    num_trafos::Vector{Int}
    num_total::Int
end

function ChaosGame(splines, thickness=0.1)
    minx = minimum(p.x for spl in splines for p in spl.points)
    miny = minimum(p.y for spl in splines for p in spl.points)
    maxx = maximum(p.x for spl in splines for p in spl.points)
    maxy = maximum(p.y for spl in splines for p in spl.points)
    height = maxy - miny
    width = maxx - minx
    num_trafos = Int[]
    maxlen = thickness * width / height
    for spl in splines
        len = 0
        curr = spl(0)
        for i in 1:999
            last = curr
            t = 1 / 999 * i
            curr = spl(t)
            len += dist(curr, last)
        end
        push!(num_trafos, max(1, trunc(Int, len / maxlen * 1.5)))
    end
    num_total = sum(num_trafos)
    return ChaosGame(splines, thickness, minx, miny, maxx, maxy, height, width, num_trafos, num_total)
end

function transform_point(point::GVector, game::ChaosGame, trafo = get_random_trafo(game))
    x = (point.x - game.minx) / game.width
    y = (point.y - game.miny) / game.height
    first_trafo = trafo[1] + 1
    start, stop = getdomain(game.splines[first_trafo])

    len = stop - start
    seg_len = len / game.num_trafos[first_trafo]
    t = start + seg_len * trafo[2] + seg_len * x
    basepoint = game.splines[first_trafo](t)
    if t + 1/50000 > stop
        neighbour = game.splines[first_trafo](t - 1/50000)
        derivative = neighbour - basepoint
    else
        neighbour = game.splines[first_trafo](t + 1/50000)
        derivative = basepoint - neighbour
    end

    if abs(derivative) != 0
        fact = 1 / abs(derivative) * (y - 0.5) * game.thickness
        basepoint = GVector(basepoint.x + derivative.y * fact,
                            basepoint.y - derivative.x * fact,
                            basepoint.z)
    end
    return truncate(basepoint, game)
end

function get_random_trafo(game::ChaosGame)
    r = rand(0:game.num_total)
    l = 0
    for i in 0:(length(game.num_trafos)-1)
        if r >= l && r < l + game.num_trafos[i+1]
            return i, rand(0:game.num_trafos[i+1]-1)
        end
        l += game.num_trafos[i+1]
    end
    return length(game.num_trafos) - 1, rand(0:game.num_trafos[end] - 1)
end

function Base.truncate(u::GVector, game::ChaosGame)
    GVector(clamp(u.x, game.minx, game.maxx),
            clamp(u.y, game.miny, game.maxy),
            u.z)
end

function create_image_chaos(game::ChaosGame, w = DEFAULT_HEIGHT,
                            h = DEFAULT_WIDTH, iterations = DEFAULT_ITERATIONS;
                            filename = nothing, seed=DEFAULT_RNG_SEED)
    srand(seed)
    im = ones(Int, h, w)
    point = GVector((game.maxx + game.minx) / 2, (game.maxy + game.miny) / 2, 0.0)
    for _ in 1:iterations
        point = transform_point(point, game)

        x = (point.x - game.minx) / game.width * w
        y = (point.y - game.miny) / game.height * h
        xi = trunc(Int, x)
        yi = trunc(Int, y)
        xi == w && (xi -= 1)
        yi == h && (yi -= 1)
        im[h - yi, xi + 1] = 0
    end

    if filename != nothing
        write_ppm(im, filename)
    end
    return im
end

function write_ppm(im, filename::String)
    magic = "P6\n"
    maxval = 255
    h, w = size(im)

    open(filename, "w") do f
        write(f, magic)
        write(f, @sprintf "%i %i\n%i\n" w h maxval)
        for j in 1:w, i in 1:h
            c = round(Int, im[i, j] * 255)
            write(f, UInt8(c), UInt8(c), UInt8(c))
        end
    end
end

const splines = [
        Spline([
            GVector(1.597350, 3.304460, 0.000000),
            GVector(1.575810, 4.123260, 0.000000),
            GVector(1.313210, 5.288350, 0.000000),
            GVector(1.618900, 5.329910, 0.000000),
            GVector(2.889940, 5.502700, 0.000000),
            GVector(2.373060, 4.381830, 0.000000),
            GVector(1.662000, 4.360280, 0.000000)],
            3, [0, 0, 0, 1, 1, 1, 2, 2, 2]),
        Spline([
            GVector(2.804500, 4.017350, 0.000000),
            GVector(2.550500, 3.525230, 0.000000),
            GVector(1.979010, 2.620360, 0.000000),
            GVector(1.979010, 2.620360, 0.000000)],
            3, [0, 0, 0, 1, 1, 1]),
        Spline([
            GVector(2.001670, 4.011320, 0.000000),
            GVector(2.335040, 3.312830, 0.000000),
            GVector(2.366800, 3.233460, 0.000000),
            GVector(2.366800, 3.233460, 0.000000)],
            3, [0, 0, 0, 1, 1, 1])
    ]


const game = ChaosGame(splines)

perf_chaos() = create_image_chaos(game)

end
