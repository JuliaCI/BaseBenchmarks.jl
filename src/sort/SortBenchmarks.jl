module SortBenchmarks

import BaseBenchmarks
using BenchmarkTrackers

const LIST_SIZE = 50000
const LISTS = (
    (:ascending, collect(1:LIST_SIZE)),
    (:descending, collect(LIST_SIZE:-1:1)),
    (:ones, ones(LIST_SIZE)),
    (:random, BaseBenchmarks.samerand(LIST_SIZE))
)

const SORT_PREFIX = "sort"

#####################################
# QuickSort/MergeSort/InsertionSort #
#####################################

for (tag, T) in (("quicksort", QuickSort), ("mergesort", MergeSort), ("insertionsort", InsertionSort))

    # sort/sort! #
    #------------#
    @track BaseBenchmarks.TRACKER begin
        @benchmarks SORT_PREFIX begin
            [(:sort, tag, kind) => sort(list; alg = T) for (kind, list) in LISTS]
            [(:sort_rev, tag, kind) => sort(list; alg = T, rev = true) for (kind, list) in LISTS]
            [(:sort!, tag, kind) => sort!(copy(list); alg = T) for (kind, list) in LISTS]
            [(:sort!_rev, tag, kind) => sort!(copy(list); alg = T, rev = true) for (kind, list) in LISTS]
        end
        @tags SORT_PREFIX "sort!" tag
    end

    # sortperm/sortperm! #
    #--------------------#
    @track BaseBenchmarks.TRACKER begin
        @benchmarks SORT_PREFIX begin
            [(:sortperm, tag, kind) => sort(list; alg = T) for (kind, list) in LISTS]
            [(:sortperm_rev, tag, kind) => sort(list; alg = T, rev = true) for (kind, list) in LISTS]
            [(:sortperm!, tag, kind) => sort!(copy(list); alg = T) for (kind, list) in LISTS]
            [(:sortperm!_rev, tag, kind) => sort!(copy(list); alg = T, rev = true) for (kind, list) in LISTS]
        end
        @tags SORT_PREFIX "sort!" "sortperm" "sortperm!" tag
    end
end

############
# issorted #
############

@track BaseBenchmarks.TRACKER begin
    @benchmarks SORT_PREFIX begin
        [(:issorted, kind) => issorted(list) for (kind, list) in LISTS]
        [(:issorted_rev, kind) => issorted(list; rev = true) for (kind, list) in LISTS]
    end
    @tags SORT_PREFIX "issorted"
end

end # module
