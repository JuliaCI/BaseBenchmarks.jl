module ShootoutBenchmarks

# This module contains the Julia implementations of the benchmarks used by the
# Computer Language Benchmarks Game (http://benchmarksgame.alioth.debian.org/),
# previously known as the Great Computer Language Shootout.
#
# See https://github.com/JuliaLang/julia/issues/660 for details.

using ..BaseBenchmarks: SUITE
using BenchmarkTools
using Compat

const SHOOTOUT_DATA_PATH = joinpath(Pkg.dir("BaseBenchmarks"), "src", "shootout", "data")

##################################################
# Allocate and deallocate many many binary trees #
##################################################

include("binary_trees.jl")

g = newgroup!(SUITE, "shootout binary_trees", ["shootout", "trees"])

g["binary_trees"] = @benchmarkable perf_binary_trees(10)

###########################################
# Indexed-access to tiny integer-sequence #
###########################################

include("fannkuch.jl")

g = newgroup!(SUITE, "shootout fannkuch", ["shootout", "fannkuch"])

g["fannkuch"] = @benchmarkable perf_fannkuch(7)

###########################################
# Generate and write random DNA sequences #
###########################################

include("fasta.jl")

g = newgroup!(SUITE, "shootout fasta", ["shootout", "fasta"])

g["fasta"] = @benchmarkable perf_fasta(100)

#############################################
# Hashtable update and k-nucleotide strings #
#############################################

include("k_nucleotide.jl")

g = newgroup!(SUITE, "shootout k_nucleotide", ["shootout", "k_nucleotide"])

g["k_nucleotide"] = @benchmarkable perf_k_nucleotide()

################################################
# Generate Mandelbrot set portable bitmap file #
################################################

include("mandelbrot.jl")

g = newgroup!(SUITE, "shootout mandelbrot", ["shootout", "mandelbrot"])

g["mandelbrot"] = @benchmarkable perf_mandelbrot(200)

################################################
# Search for solutions to shape packing puzzle #
################################################

include("meteor_contest.jl")

g = newgroup!(SUITE, "shootout meteor_contest", ["shootout", "meteor_contest"])

g["meteor_contest"] = @benchmarkable perf_meteor_contest()

######################################
# Double-precision N-body simulation #
######################################

include("nbody.jl")
include("nbody_vec.jl")

g = newgroup!(SUITE, "shootout nbody_vec", ["shootout", "nbody", "nbody_vec"])

g["nbody"] = @benchmarkable NBody.perf_nbody()
g["nbody_vec"] = @benchmarkable NBodyVec.perf_nbody_vec()

############################################
# Streaming arbitrary-precision arithmetic #
############################################

include("pidigits.jl")

g = newgroup!(SUITE, "shootout pidigits", ["shootout", "pidigits", "pi", "π"])

g[:pidigits] = @benchmarkable perf_pidigits(1000)

#############################################################
# Match DNA 8-mers and substitute nucleotides for IUB codes #
#############################################################

include("regex_dna.jl")

g = newgroup!(SUITE, "shootout regex_dna", ["shootout", "regex_dna", "regex"])

g["regex_dna"] = @benchmarkable perf_regex_dna()

#######################################################
# Read DNA sequences - write their reverse-complement #
#######################################################

include("revcomp.jl")

g = newgroup!(SUITE, "shootout revcomp", ["shootout", "revcomp"])

g["revcomp"] = @benchmarkable perf_revcomp()

#####################################
# Eigenvalue using the power method #
#####################################

include("spectralnorm.jl")

g = newgroup!(SUITE, "shootout spectralnorm", ["shootout", "spectralnorm"])

g["spectralnorm"] = @benchmarkable perf_spectralnorm()

end # module
