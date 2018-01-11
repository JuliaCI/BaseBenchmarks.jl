# generate simple for loops for all dimensions

function generate_loops(Nmax, npts)
# Nmax is the maximum number of dimensions
# npts is the number of points in the stencil (used to figure out the name of
# the kernel to call)
# prefix is prepended to the file name

  str = ""
  for i=1:Nmax
    str_tmp = generateLoops(i, npts)
    str *= str_tmp
  end

  return str
end


function generateLoops(N, npts)
# generate a function that does N nested for loops

  np1 = N + 1
  str = ""
  str *= "function perf_hdindexing$npts(u_i::AbstractArray{T, $np1}, u_ip1::AbstractArray{T, $np1}) where T\n"

  indent = "  "

  # generate loop bounds
  for i=1:N
    varname = string("d", i, "min")
    varname2 = string("d", i, "max")
    idx = N - i + 1
    str *= indent*varname*" = 3\n"
    str *= indent*varname2*" = size(u_i, $idx) - 2\n"
  end

  str *= "\n"
  # generate loops
  for i=1:N
    varname = string("d", i)
    varname_min = string("d", i, "min")
    varname_max = string("d", i, "max")

    str *= indent*"for "*varname*" = "*varname_min*":"*varname_max*"\n"
    indent *= "  "
  end

  # generate body
  str_inner = ""
  str_inner *= indent*"idx = ("
  for i=1:N
    idx = N - i + 1  # indices are reversed
    varname = "d$idx"
    str_inner *= varname*", "
  end

  # remove trailing space and comma
  if N > 1
    str_inner = str_inner[1:end-2]
  end
  str_inner *= ")\n"
  str *= str_inner

  # call kernel
  str *= indent*"kernel$npts(idx, u_i, u_ip1)\n"

  # end loops
  for i=1:N
    indent = indent[1:end-2]
    str *= indent*"end\n"
  end

  str *= "\n"
  str *= indent*"return nothing\n"
  indent = indent[1:end-2]
  str *= "end\n"

  return str
end





#generate_loops(6, 5)
