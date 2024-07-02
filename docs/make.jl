using JuliaIRCodeInterpreter
using Documenter

DocMeta.setdocmeta!(JuliaIRCodeInterpreter, :DocTestSetup, :(using JuliaIRCodeInterpreter); recursive=true)

makedocs(;
    modules=[JuliaIRCodeInterpreter],
    authors="Tim Holy <tim.holy@gmail.com> and contributors",
    sitename="JuliaIRCodeInterpreter.jl",
    format=Documenter.HTML(;
        canonical="https://JuliaDebug.github.io/JuliaIRCodeInterpreter.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaDebug/JuliaIRCodeInterpreter.jl",
    devbranch="main",
)
