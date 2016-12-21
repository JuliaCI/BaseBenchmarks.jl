module CompatUtils

export @dotcompat

# work around lack of Compat support for .= (Compat.jl issue #285)
if VERSION < v"0.5.0-dev+5575" #17510
    macro dotcompat(ex)
        if Meta.isexpr(ex, :comparison, 3) && ex.args[2] == :.=
            :(copy!($(esc(ex.args[1])), $(esc(ex.args[3]))))
        else
            esc(ex)
        end
    end
else
    macro dotcompat(ex)
        esc(ex)
    end
end

end
