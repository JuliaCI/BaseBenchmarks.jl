module ShootoutBenchmarks

# This module contains the Julia implementations of the benchmarks used by the
# Computer Language Benchmarks Game (http://benchmarksgame.alioth.debian.org/),
# previously known as the Great Computer Language Shootout.
#
# See https://github.com/JuliaLang/julia/issues/660 for details.

import BaseBenchmarks
using BenchmarkTrackers

const SHOOTOUT_PREFIX = "shootout"
const SHOOTOUT_DATA_PATH = joinpath(Pkg.dir("BaseBenchmarks"), "src", "shootout", "data")

##################################################
# Allocate and deallocate many many binary trees #
##################################################

include("binary_trees.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks SHOOTOUT_PREFIX begin
        (:binary_trees,) => perf_binary_trees(10)
    end
    @tags SHOOTOUT_PREFIX "trees"
end

###########################################
# Indexed-access to tiny integer-sequence #
###########################################

include("fannkuch.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks SHOOTOUT_PREFIX begin
        (:fannkuch,) => perf_fannkuch(7)
    end
    @tags SHOOTOUT_PREFIX "fannkuch"
end

###########################################
# Generate and write random DNA sequences #
###########################################

include("fasta.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks SHOOTOUT_PREFIX begin
        (:fasta,) => perf_fasta(100)
    end
    @tags SHOOTOUT_PREFIX "fasta"
end

#############################################
# Hashtable update and k-nucleotide strings #
#############################################

include("k_nucleotide.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks SHOOTOUT_PREFIX begin
        (:k_nucleotide,) => perf_k_nucleotide()
    end
    @tags SHOOTOUT_PREFIX "k_nucleotide"
end


################################################
# Generate Mandelbrot set portable bitmap file #
################################################

include("mandelbrot.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks SHOOTOUT_PREFIX begin
        (:mandelbrot,) => perf_mandelbrot(200)
    end
    @tags SHOOTOUT_PREFIX "mandelbrot"
end


################################################
# Search for solutions to shape packing puzzle #
################################################

include("meteor_contest.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks SHOOTOUT_PREFIX begin
        (:meteor_contest,) => perf_meteor_contest()
    end
    @tags SHOOTOUT_PREFIX "meteor_contest"
end

######################################
# Double-precision N-body simulation #
######################################

include("nbody.jl")
include("nbody_vec.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks SHOOTOUT_PREFIX begin
        (:nbody,) => NBody.perf_nbody()
        (:nbody_vec,) => NBodyVec.perf_nbody_vec()
    end
    @tags SHOOTOUT_PREFIX "nbody" "nbody_vec"
end

############################################
# Streaming arbitrary-precision arithmetic #
############################################

include("pidigits.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks SHOOTOUT_PREFIX begin
        (:pidigits,) => perf_pidigits(1000)
    end
    @tags SHOOTOUT_PREFIX "pidigits" "pi" "π"
end

#############################################################
# Match DNA 8-mers and substitute nucleotides for IUB codes #
#############################################################

include("regex_dna.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks SHOOTOUT_PREFIX begin
        (:regex_dna,) => perf_regex_dna()
    end
    @tags SHOOTOUT_PREFIX "regex_dna" "regex"
end

#######################################################
# Read DNA sequences - write their reverse-complement #
#######################################################

include("revcomp.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks SHOOTOUT_PREFIX begin
        (:revcomp,) => perf_revcomp()
    end
    @tags SHOOTOUT_PREFIX "revcomp"
end


#####################################
# Eigenvalue using the power method #
#####################################

include("spectralnorm.jl")

@track BaseBenchmarks.TRACKER begin
    @benchmarks SHOOTOUT_PREFIX begin
        (:spectralnorm,) => perf_spectralnorm()
    end
    @tags SHOOTOUT_PREFIX "spectralnorm"
end

end # module