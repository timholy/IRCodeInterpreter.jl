using IRCodeInterpreter
using Documenter

DocMeta.setdocmeta!(IRCodeInterpreter, :DocTestSetup, :(using IRCodeInterpreter); recursive=true)

makedocs(;
    modules=[IRCodeInterpreter],
    authors="Tim Holy <tim.holy@gmail.com> and contributors",
    sitename="IRCodeInterpreter.jl",
    format=Documenter.HTML(;
        canonical="https://JuliaDebug.github.io/IRCodeInterpreter.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaDebug/IRCodeInterpreter.jl",
    devbranch="main",
)
