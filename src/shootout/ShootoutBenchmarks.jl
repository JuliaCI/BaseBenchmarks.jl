module ShootoutBenchmarks

# This module contains the Julia implementations of the benchmarks used by the
# Computer Language Benchmarks Game (http://benchmarksgame.alioth.debian.org/),
# previously known as the Great Computer Language Shootout.
#
# See https://github.com/JuliaLang/julia/issues/660 for details.

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools

using Printf

const SUITE = BenchmarkGroup(["example", "regex", "pi", "π", "tree"])
const SHOOTOUT_DATA_PATH = joinpath(dirname(@__FILE__), "data")

##################################################
# Allocate and deallocate many many binary trees #
##################################################

include("binary_trees.jl")
SUITE["binary_trees"] = @benchmarkable perf_binary_trees(10)

###########################################
# Indexed-access to tiny integer-sequence #
###########################################

include("fannkuch.jl")
SUITE["fannkuch"] = @benchmarkable perf_fannkuch(7)

###########################################
# Generate and write random DNA sequences #
###########################################

include("fasta.jl")
SUITE["fasta"] = @benchmarkable perf_fasta(100)

#############################################
# Hashtable update and k-nucleotide strings #
#############################################

include("k_nucleotide.jl")
SUITE["k_nucleotide"] = @benchmarkable perf_k_nucleotide()

################################################
# Generate Mandelbrot set portable bitmap file #
################################################

include("mandelbrot.jl")
SUITE["mandelbrot"] = @benchmarkable perf_mandelbrot(200)

################################################
# Search for solutions to shape packing puzzle #
################################################

include("meteor_contest.jl")
SUITE["meteor_contest"] = @benchmarkable perf_meteor_contest()

######################################
# Double-precision N-body simulation #
######################################

include("nbody.jl")
include("nbody_vec.jl")
SUITE["nbody"] = @benchmarkable NBody.perf_nbody()
SUITE["nbody_vec"] = @benchmarkable NBodyVec.perf_nbody_vec()

############################################
# Streaming arbitrary-precision arithmetic #
############################################

include("pidigits.jl")
SUITE["pidigits"] = @benchmarkable perf_pidigits(1000)

#############################################################
# Match DNA 8-mers and substitute nucleotides for IUB codes #
#############################################################

include("regex_dna.jl")
SUITE["regex_dna"] = @benchmarkable perf_regex_dna()

#######################################################
# Read DNA sequences - write their reverse-complement #
#######################################################

include("revcomp.jl")
SUITE["revcomp"] = @benchmarkable perf_revcomp() time_tolerance=0.25

#####################################
# Eigenvalue using the power method #
#####################################

include("spectralnorm.jl")
SUITE["spectralnorm"] = @benchmarkable perf_spectralnorm()

end # module
