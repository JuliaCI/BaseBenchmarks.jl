# generate the spatial kernel for an n-dimensional wave equation solver
include("generate_loops.jl")

# This function generates code to solve the n-dimensional
# constant coefficient wave equation in first order form, for dimensions 1
# to maxdim.  It uses 4th order accuate finite difference stencils.
# The function perf_hdindexing5 loops over all dimensions and calls the
# function kernel5 to evaluate the stencils at each point.  Dispatch on the
# array dimension ties the n different solvers together.
function make_stencil(fname, maxdim)
# generate kernels and loops for arrays of dimension 2 to maxdim + 1 and write
# to file named fname

  stencil = ["1/12", "-2/3", "0", "2/3", "-1/12"]
  neq = 2  # number of equations

  npts = length(stencil)
  nghost = div(npts, 2)

  str = generate_kernel(maxdim, stencil, neq)
  str *= "\n"
  str *= generate_loops(maxdim, npts)

  f = open(fname, "w")
  println(f, str)
  close(f)

end


function generate_kernel(maxdim, stencil, neq)
# maxdim is maximum dimension
# stencil is the stencil (vector of strings that are the coefficients)
# neq is the number of equations
# prefix is prepended to the file name
  npts = length(stencil)

  str = ""
  for i=1:maxdim
    func_sig = getKernelSignature(i, npts)
    str *= func_sig*"\n"

    func_prologue = getKernelPrologue(i)
    func_prologue = indentString(2, func_prologue)
    str *= func_prologue*"\n"

    func_body = generate_body(i, stencil, neq)
    func_body = indentString(2, func_body)
    str *= func_body*"\n"

    func_end = getKernelEpilogue()
    str *= func_end*"\n"

  end

  return str
end

function generate_body(maxdim, stencil, neq)
# writes to file kernel_dim_npts
# neq is the number of equations in the system

  npts = length(stencil)
  order = npts - 1
  second_line_indent = " "^8

  str = ""


  for eq=1:neq  # loop over equations in the system
    for dim=1:maxdim
      var_name = string("u", dim, dim, "_", eq)
      stencil_dim = getStencil(maxdim, stencil, dim, eq, second_line_indent)
      str *= string(var_name, " = ", stencil_dim)*"\n"

    end

    # sum the results into the receiving arrays
    kernel_assembly = getKernelAssembly(maxdim, eq, neq - eq + 1)
    str *= kernel_assembly*"\n"
  end

  return str

end


function getStencil(maxdim::Integer, stencil, dim::Integer, src_eq::Integer,
                    second_line_indent::String="")

# Generates a string that multiplies the given stencil coefficients by
#   the corresponding values from an array called u_i.
# The stencil coefficients are list from lowest index to highest index
#   maxdim is the number of indices the array u_i has
# The indices are named d1 through dn.
# dim is the dimension of u_i upon which to apply the array.
# Each term of the stencil is put on its own line.  second_line_indent
# is the string prepended to all lines except the first to indent them

# the src_eq an dest_eq are the equation indices for the right hand side
#   and left hand side arrays, and is the final index

# the stencil array is expected to be an array of strings
# the strings are enclosed in parenthesis before multiplication
# great pains are taken to ensure alignment of all terms of the stencil

# the returned string is of the form:
#    udd = stencil calculation...

  npts = length(stencil)
  stencil_startoffset = -div(npts - 1, 2)
  stencil_endoffset = div(npts - 1, 2)
  stencil_offsets = stencil_startoffset:stencil_endoffset

  # figure out maximum size of a stencil coefficient
  max_coeff_len = 0
  for i=1:npts
    len_i = length(stencil[i])
    if len_i > max_coeff_len
      max_coeff_len = len_i
    end
  end


  str = ""

  # index names are d1 through dmaxdim
  for pt=1:npts

    if pt == 1
      indentlevel = ""
    else
      indentlevel = second_line_indent
    end

    stencil_pt = stencil[pt]
    stencil_pt_len = length(stencil_pt)
    stencil_offset = stencil_offsets[pt]

    padding = max_coeff_len - stencil_pt_len
    coeff_str = string( " "^padding, "(", stencil_pt, ")")

    str_pt = indentlevel*coeff_str*"*u_i[ "

    # insert all indices before dim
    for i=1:(dim-1)
      idx_i = "d$i"
      str_pt = str_pt*idx_i*", "
    end

    # insert index dim and modifier

    # figure out if this should be a plus or minus
    stencil_offset_inner = abs(stencil_offset)
    if stencil_offset < 0
      mod_str = "d$dim - $stencil_offset_inner, "
    elseif stencil_offset > 0
      mod_str = "d$dim + $stencil_offset_inner, "
    else  # stencil_offset == 0
      mod_str = "d$dim    , "
    end

    # apply the index dim and modifier
    str_pt *= mod_str


    # insert all indices after dim
    for i=(dim+1):maxdim
      idx_i = "d$i"
      str_pt *= idx_i*", "
    end

    # remove last comma and space
    str_pt = str_pt[1:end-2]

    # close bracket
    str_pt = str_pt*", $src_eq"*"]"


    # figure out whether or not to add a plus sign for another term
    if pt != npts
      mod_str = " +\n"
    else
      mod_str = "\n"
    end

    str *= str_pt*mod_str

  end  # end loop over npts

  return str

end

function getKernelAssembly(maxdim::Integer, src_eq::Integer, dest_eq::Integer)
# sums the terms from each dimension into the receiving array
# src_eq tells which equation the terms come from, dest_eq tells which
# equation they are summed into

  second_line_indent = " "^(12 + 4*maxdim)
  # write receiving location
  str = "u_ip1[ "
  for i=1:maxdim
    str *= "d$i, "
  end

  str *= string(dest_eq, "] = ")
  # remove final comma and space, add close brack
#  str = str[1:end-2]
#  str *= "] = "

  # multiply stencil in each direction by grid spacing square
  for i=1:maxdim
    delta_name = string("delta_", i, "2")
    stencil_fac_name = string("u", i, i, "_", src_eq)
    str *= delta_name*"*"*stencil_fac_name*" + "

    if ((i % 3) == 0) && i != maxdim
      str *= "\n"*second_line_indent
    end

  end

  # remove last " + "
  str = str[1:end-3]
  str *= "\n"


  return str
end

function getKernelSignature(dim::Integer, npts::Integer)
# get the function signature

  kernel_name = string("kernel", npts)
  array_typetag = string("::AbstractArray{T,", dim+1, "}")

  str = string("function ", kernel_name, "(idx, ")
  str *= string("u_i", array_typetag, ", u_ip1", array_typetag, ") where T\n")

  return str
end

function getKernelPrologue(maxdim::Integer)
# unpack all the variables

  str = ""

  for i=1:maxdim
    varname = "d$i"
    str *= string(varname, " = idx[", i, "]\n")
  end

  str *= "\n"

  for i=1:maxdim
    varname = string("delta_", i, "2")
#    fieldname = string("deltax_invs2[", i, "]")
    str *= string(varname, " = ", "0.5", "\n")
  end

  str *= "\n"


  return str
end

function getKernelEpilogue()
  # get the return and end statement

  str = "  return nothing\n"
  str *= "end"

  return str
end

function indentString(indent::Integer, str::String)
# indent all lines of a string a certain number of spaces
  indent_str = " "^indent
  newline_indent = "\n"*indent_str
  str = indent_str*str
  str = replace(str, "\n" => newline_indent)

  return str
end

