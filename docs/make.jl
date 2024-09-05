using NeperStructureGenerator
using Documenter

DocMeta.setdocmeta!(NeperStructureGenerator, :DocTestSetup, :(using NeperStructureGenerator); recursive=true)

makedocs(;
    modules=[NeperStructureGenerator],
    authors="Said Harb",
    sitename="NeperStructureGenerator.jl",
    format=Documenter.HTML(;
        canonical="https://KnutAM.github.io/NeperStructureGenerator.jl",
        edit_link="main",
        assets=String[],
        repolink = "https://github.com/KnutAM/NeperStructureGenerator.jl.git"
    ),
    repo = "https://github.com/KnutAM/NeperStructureGenerator.jl.git",
    pages=[
        "Home" => "index.md",
        "API" => "API.md",
        "Internals" => "devdocs.md",
        "Examples" => "examples.md"
    ],
)

deploydocs(;
    repo="https://github.com/KnutAM/NeperStructureGenerator.jl.git",
    devbranch="main",
)
