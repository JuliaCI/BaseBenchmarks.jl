module JSONParse

# Adapted from http://www.mathworks.com/matlabcentral/fileexchange/23393
# Original BSD Licence, (c) 2011, François Glineur

function perf_parse_json(strng::AbstractString)
    pos = 1
    len = length(strng)

    function parse_object()
        parse_char('{')
        object = Dict{AbstractString, Any}()
        if next_char() != '}'
            while true
                str = parse_string()
                if isempty(str)
                    error("Name of value at position $pos cannot be empty")
                end
                parse_char(':')
                val = parse_value()
                object[str] = val
                if next_char() == '}'
                    break
                end
                parse_char(',')
            end
        end
        parse_char('}')
        return object
    end

    function parse_array()
        parse_char('[')
        object = Set()
        if next_char != ']'
            while true
                val = parse_value()
                push!(object, val)
                if next_char() == ']'
                    break
                end
                parse_char(',')
            end
        end
        parse_char(']')
        return object
    end

    function parse_char(c::Char)
        skip_whitespace()
        if pos > len || strng[pos] != c
            error("Expected $c at position $pos")
        else
            pos = pos + 1
            skip_whitespace()
        end
    end

    function next_char()
        skip_whitespace()
        if pos > len
            c = '\0'
        else
            c = strng[pos]
        end
    end

    function skip_whitespace()
        while pos <= len && isspace(strng[pos])
            pos = pos + 1
        end
    end

    function parse_string()
        if strng[pos] != '"'
            error("AbstractString starting with quotation expected at position $pos")
        else
            pos += 1
        end
        str = IOBuffer()
        while pos <= len
            nc = strng[pos]
            if nc == '"'
                pos += 1
                return String(take!(str))
            elseif nc == '\\'
                pos = pos + 1
                pos > len && break # goto error handling
                anc = strng[pos]
                if anc ==  '"'
                    write(str, "\"")
                    pos += 1
                elseif anc ==  '\\'
                    write(str, "\\")
                    pos += 1
                elseif anc ==  '/'
                    write(str, "/")
                    pos += 1
                elseif anc ==  'b'
                    write(str, "\b")
                    pos += 1
                elseif anc ==  'f'
                    write(str, "\f")
                    pos += 1
                elseif anc ==  'n'
                    write(str, "\n")
                    pos += 1
                elseif anc ==  'r'
                    write(str, "\r")
                    pos += 1
                elseif anc ==  't'
                    write(str, "\t")
                    pos += 1
                elseif anc == 'u'
                    pos + 4 > len && break # goto error handling
                    write(str, Char(parse(Int, strng[pos:pos+4], base=16)))
                    pos = pos + 5
                else # should rarely happen
                    write(str, anc)
                    pos = pos + 1
                end
            else # common case
                write(str, nc)
                pos = nextind(strng, pos)
            end
        end
        error("End of file while expecting end of string")
    end

    function parse_number()
        num_regex = r"^[\w]?[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?[\w]?"
        m = match(num_regex, strng[pos:min(len,pos+20)])
        if m === nothing
            error("Error reading number at position $pos")
        end
        delta = m.offset + length(m.match)
        pos = pos + delta -1
        return parse(Float64, m.match)
    end

    function parse_value()
        nc = strng[pos]
        if nc == '"'
            val = parse_string()
            return val
        elseif nc == '['
            val = parse_array()
            return val
        elseif nc == '{'
            val = parse_object()
            return val
        elseif nc == '-' || nc == '0' || nc == '1' || nc == '2' || nc == '3' || nc == '4' || nc == '5' || nc == '6' || nc == '7' || nc == '8' || nc == '9'
            val = parse_number()
            return val
        elseif nc == 't'
            if pos+3 <= len && strng[pos:pos+3] == "true"
                val = true
                pos = pos + 4
                return val
            end
        elseif nc == 'f'
            if pos+4 <= len && strng[pos:pos+4] == "false"
                val = false
                pos = pos + 5
                return val
            end
        elseif nc == 'n'
            if pos+3 <= len && strng[pos:pos+3] == "null"
                val = []
                pos = pos + 4
                return val
            end
        end
        error("Value expected at position $pos")
    end

    if pos <= len
        nc = next_char()
        if nc == '{'
            return parse_object()
        elseif nc ==  '['
            return parse_array()
        else
            error("Outer level structure must be an object or an array")
        end
    end
end

end # module
