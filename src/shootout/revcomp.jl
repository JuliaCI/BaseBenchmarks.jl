# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# Contributed by David Campbell

# FIXME(davekong) Is there support in Julia for doing more efficient IO and
# handling of byte arrays?

const revcompdata = Dict(
   'A'=> 'T', 'a'=> 'T',
   'C'=> 'G', 'c'=> 'G',
   'G'=> 'C', 'g'=> 'C',
   'T'=> 'A', 't'=> 'A',
   'U'=> 'A', 'u'=> 'A',
   'M'=> 'K', 'm'=> 'K',
   'R'=> 'Y', 'r'=> 'Y',
   'W'=> 'W', 'w'=> 'W',
   'S'=> 'S', 's'=> 'S',
   'Y'=> 'R', 'y'=> 'R',
   'K'=> 'M', 'k'=> 'M',
   'V'=> 'B', 'v'=> 'B',
   'H'=> 'D', 'h'=> 'D',
   'D'=> 'H', 'd'=> 'H',
   'B'=> 'V', 'b'=> 'V',
   'N'=> 'N', 'n'=> 'N',
)

function print_buff(b)
    br = reverse(b)
    l = length(br)
    for i = 1:60:l
        if i+59 > l
            write(br[i:end]); println()
        else
            write(br[i:i+59]); println()
        end
    end
end

function perf_revcomp()
    infile= joinpath(SHOOTOUT_DATA_PATH, "revcomp-input.txt")
    open(infile, "r") do input
        buff = UInt8[]
        while true
            line = codeunits(readline(input))
            if isempty(line)
    #            print_buff(buff)
                return
            elseif line[1] == UInt8('>')
    #            print_buff(buff)
                buff = UInt8[]
    #            write(line)
            else
                l = length(line)-1
                let line = line # Workaround for julia#15276
                    append!(buff, [UInt8(revcompdata[Char(line[i])]) for i=1:l])
                end
            end
        end
    end
end
