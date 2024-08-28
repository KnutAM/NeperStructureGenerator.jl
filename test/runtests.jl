using NeperStructureGenerator
using Test

const clean = true

@testset "neper installed" begin
    version = mktempdir() do dir
        logfile = joinpath(dir, "tmp.log")
        redirect_stdio(;stdout = logfile) do 
            run(`neper --version`)
        end
        open(logfile, "r") do io
            readline(io)
        end
    end
    println(version)
end

@testset "NeperStructureGenerator.jl" begin
    # Write your tests here.
    tess1 = NeperStructureGenerator.tesselate()
    @test isfile(tess1)

    mesh1 = NeperStructureGenerator.mesh(tess_path = tess1) 
    @test isfile(mesh1)

    mesh2 = NeperStructureGenerator.mesh(tess_path = tess1, custom_mesh_name = "TestMesh") 
    @test isfile(mesh2)

    NeperStructureGenerator.visualize_directory("ALL_FOTOS", "dim_2_id_1_n_10_periodicity_none_reg_0")
    @test isdir("ALL_FOTOS")

    if clean
        tess_dir = dirname(tess1)
        rm(tess_dir, recursive = true) 
        @test !isdir(tess_dir)  

        rm("ALL_FOTOS", recursive = true)
        @test !isdir("ALL_FOTOS")  

    end
    
end


# Test creates a tesselation, mesh and visualitzation from that
# if veverything has passed, clean up all the test files
# Add option (clean) to maybe keep the test files

