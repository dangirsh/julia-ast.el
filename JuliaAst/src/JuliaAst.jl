module JuliaAst

using MacroTools: postwalk

export clean_sexpr

"""
Return a new Expr with all line annotations converted from:

:(#= <file_name>:<line_num> =#)

to

:(:line_annotation, <file_name>, <line_num>)

which is easier to work with from Emacs.
"""
@noinline function emacsify_line_annotations(expr::Expr)

    function convert(lnn::LineNumberNode)
        Expr(:line_annotation,
             string(lnn.file), lnn.line)
    end

    postwalk(x -> x isa LineNumberNode ? convert(x) : x, expr)
end

"""
Return a new Expr with all assignment :(=) nodes replaced as :assign.

Emacs has issues reading symbols with parentheses in them.
"""
@noinline function emacsify_assignment_nodes(expr::Expr)

    convert(x::Expr) = Expr(:assign, x.args...)

    is_assignment_node(x::Expr) = x.head == :(=)
    is_assignment_node(x) = false

    postwalk(x -> is_assignment_node(x) ? convert(x) : x, expr)
end


clean_sexpr_impl(ex) = sprint(io -> show(io, ex))

function clean_sexpr_impl(ex::Expr)
    head = clean_sexpr_impl(ex.head)
    args = join([clean_sexpr_impl(arg) for arg = ex.args], " ")
    "($head $args)"
end

function clean_sexpr(ex::Expr)
    ex = emacsify_line_annotations(ex)
    ex = emacsify_assignment_nodes(ex)
    clean_sexpr_impl(ex)
end

function clean_sexpr(julia_code::String)
    ex = Meta.parse(julia_code)
    clean_sexpr(ex)
end

end
