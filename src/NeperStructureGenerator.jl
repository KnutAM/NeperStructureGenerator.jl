module NeperStructureGenerator


using TOML 
using Base.Filesystem

const tesselation_defaults = Dict(
    "id" => 1, # used as seed
    "n" => 10,
    "dim" => 2,
    "reg" => 0,
    "periodicity" => "none",
    "path" => Nothing
)

const meshing_defaults = Dict(
    "cl" => 0.5,
    "order" => 1,
    "elttype" => "tet",
    "path" => Nothing
)

"""
    name_from_dict(d::Dict)

Generate a string with the format `"<key1><value1>_<key2><value2>_..."` where
the keys are sorted.
"""
function name_from_dict(d::Dict)
    formatted_entries = []
    for key in sort(collect(keys(d)))
        key != "path" || continue
        key_str = string(key)
        value_str = string(d[key])
        value_str = replace(value_str, '.' => '-')
        formatted_entry = string(key_str, '_', value_str)
        push!(formatted_entries, formatted_entry)
    end
    result = join(formatted_entries, '_')
    return result
end

""" 
    generate_directory_name(parent_folder::String, tesselation_settings::Dict)

Args:
    parent_folder (String): Root directory
    tesselation_settings (Dict): Dictionary containing the tesselation parameters
"""
function generate_directory_name(parent_folder, tesselation_settings::Dict)
    return dir_name = joinpath(parent_folder, name_from_dict(tesselation_settings))
end

"""
    create_cmdargs(dict::Dict)

Create a string with the format `"-<key1> <value1> -<key2> <value2> ..."`.
The keys are not sorted.
"""
function create_cmdargs(dict::Dict)
    cmd = String[] #same as Vector{String}
    for (key, val) in dict
        key != "path" || continue
        push!(cmd,string("-", key))
        push!(cmd,string(val))
    end
    return cmd
end

"""
    create_toml_data(name::String, dict::Dict, file_path::String; custom::Bool = false)

Create or update a TOML file with mesh data.

If the `custom` flag is set to `true`, the `name` parameter is used as the mesh name. 
Otherwise, a mesh name based on the number of existing entries is generated. 
The function saves the tesselation information in the "TESSELATION" section and the 
mesh information in the "MESHES" section of the TOML file. The TOML file is located in 
the same directory as the provided `file_path`.

# Arguments
- `name::String`: Provides the name of the tesselation dictionary in the toml file for 
   tesselation and the path to the mesh file to infer the name for meshing.
- `dict::Dict`: Contains information about the tesselation or meshing parameters.
- `file_path::String`: Path to the tesselation or mesh file.
- `custom::Bool=false`: Is set to true if a custom mesh name was given.
"""
function create_toml_data(name:: String, dict::Dict, file_path::String; custom = false)
    println(name)
    println(dict)
    println(file_path)
    toml_path = dirname(file_path)
    relative_file_path = basename(file_path)
    toml_path = joinpath(toml_path, "input.toml")
    if isfile(toml_path)
        toml_data = TOML.parsefile(toml_path)
        num_keys = length(keys(toml_data["MESHES"]))
        if custom == true
            mesh_name = basename(name)
            mesh_name, ext = splitext(mesh_name)
        else
            mesh_name = "Mesh_" * string(num_keys + 1)
        end
        toml_data["MESHES"][mesh_name] = dict
        toml_data["MESHES"][mesh_name]["path"] = relative_file_path
        open(toml_path, "w") do file
            TOML.print(file, toml_data)
        end
    else
        toml_data = Dict(name => dict)
        toml_data[name]["path"] = relative_file_path
        toml_data["MESHES"] = Dict()
        open(toml_path, "w") do file
            TOML.print(file, toml_data)
        end
    end
end

"""
    check_mesh_args(file_path::String, new_mesh_dict::Dict, force::Bool = false)

Check if there already is a mesh with the same name and or same arguments.

If the `force` flag is set to `true`, overwriting of meshes is enabled.

# Arguments
- `file_path::String`: Path to the mesh file.
- `new_mesh_dictdict::Dict`: Contains the parameters of the new mesh.
- `force::Bool=false`: Enables and disables overwriting of meshes.
"""
function check_mesh_args(file_path::String, new_mesh_dict::Dict, force::Bool = false)
    mesh_name = basename(file_path)
    mesh_name, ext = splitext(mesh_name)
    toml_path = dirname(file_path)
    toml_path = joinpath(toml_path, "input.toml")
    if isfile(toml_path)
        toml_data = TOML.parsefile(toml_path)
        meshes = toml_data["MESHES"]
        for(key, mesh_dict) in meshes
            same_name = false
            same_args = false
            if key == mesh_name
                same_name = true
            end
            if check_dicts_equal(mesh_dict, new_mesh_dict)
                same_args = true
            end
            if !force
                if same_name && same_args
                    error("""\nThe requested mesh already exists ('$key') with the same 
                    name and arguments for this tesselation. Choose a unique mesh name or 
                    set force to true to overwrite the exisiting mesh.\n""")
                elseif !same_name && same_args
                    error("""\nThe requested mesh already exists under a different name 
                    ('$key') with the same arguments for this tesselation.
                    Set force to true to still create the mesh.\n""")
                elseif same_name && !same_args
                    error("""\nA mesh with the same custom mesh name ('$key'), but 
                    different arguments already exists.
                    Choose a unique mesh name or set force to true to overwrite the 
                    existing mesh.\n""")
                end
            else
                if same_name && same_args
                    println("""\nWARNING: The requested mesh already exists ('$key') with 
                    the same name and arguments for this tesselation.
                    Overwriting existing mesh because force is set to true.\n""")
                elseif !same_name && same_args
                    println("""\nWARNING: The requested mesh already exists under a 
                    different name ('$key') with the same arguments for this tesselation.
                    Still creating the mesh because force is set to true.\n""")
                elseif same_name && !same_args
                    println("""\nWARNING: A mesh with the same custom mesh name ('$key'), 
                    but different arguments already exists.
                    Overwriting existing mesh because force is set to true.\n""")
                end
            end
        end
    else
        error("The input.toml file does not exist.")
    end
end

"""
    check_dicts_equal(dict::Dict, new_dict::Dict)

Returns `true` if the values of the keys in `new_dict` match the values of the keys 
in `dict`
"""
function check_dicts_equal(dict::Dict, new_dict::Dict)
    for k in keys(new_dict)
        if k == "path" # Comparison based on arguments, not the path
            continue
        end
        if get(dict, k, nothing) != new_dict[k]
            return false
        end
    end
    return true
end

"""
    tesselate(; base_name::String = "crystal", parent_folder::String = pwd(), 
                tesselation::Dict = Dict())

Creates a tesselation with the respective orientation file according to the tesselation 
parameters. Returns the path to the created tesselation file.

# Arguments
- `base_name::String="crystal"`: Name of the tesselation and orientation file.
- `parent_folder::String=pwd()`: Root directory.
- `tesselation::Dict=Dict()`: Dictionary containg the tesselation parameters.
"""
function tesselate(; base_name::String = "crystal", parent_folder::String = pwd(), 
    tesselation::Dict = Dict())

    tesselation_settings = merge(tesselation_defaults, tesselation)
    dir_name = generate_directory_name(parent_folder, tesselation_settings)
    isdir(dir_name) || mkdir(dir_name)

    file_name = joinpath(dir_name, base_name)
    relative_file_path = relpath(file_name, parent_folder) * ".tess"
    args=create_cmdargs(tesselation_settings)
    create_toml_data("TESSELATION", tesselation_settings, relative_file_path)
    run(`neper -T $args -o $relative_file_path -format tess,ori -oridescriptor rodrigues:active`)

    return relative_file_path
end


"""
    mesh(; tess_path::String = Nothing, meshing::Dict = Dict(), 
    custom_mesh_name::String = Nothing, force::Bool = false)

Creates and saves a mesh for the the provided tesselation file according to the meshing 
parameters. Returns the path to the mesh file.

If the `force` flag is set to `true`, overwriting of meshes is enabled. A custom mesh 
name can be given in the `custom_mesh_name` argument.

# Arguments
- `tess_path::String=Nothing`: Path to the tesselation file.
- `meshing::Dict=Dict()`: Dictionary containg the meshing parameters.
- `custom_mesh_name::String=Nothing`: Custom given mesh name.
- `force::Bool=false`: Enables and disables overwriting of meshes.
"""
function mesh(; tess_path::String = Nothing, meshing::Dict = Dict(), 
    custom_mesh_name::String = Nothing, force::Bool = false)

    isfile(tess_path)||error("Tesselation file $(tess_path) does not exist.")

    meshing_settings = merge(meshing_defaults, meshing)
    dir_name = dirname(tess_path)

    if custom_mesh_name !== Nothing
        mesh_path = joinpath(dir_name, custom_mesh_name) * ".msh"
        check_mesh_args(mesh_path, meshing_settings, force)
        create_toml_data(mesh_path, meshing_settings, mesh_path, custom = true)
    else
        mesh_path = generate_directory_name(dir_name, meshing_settings) * ".msh"
        check_mesh_args(mesh_path, meshing_settings, force)
        create_toml_data(mesh_path, meshing_settings, mesh_path)
    end

    run(`neper -M $tess_path $(create_cmdargs(meshing_settings)) -o $mesh_path -format msh,inp`)
    return mesh_path
end

######## Depreceated
function get_unique_path(base_path::AbstractString)
    if !isfile(base_path)
        return base_path  
    end
    
    dir, name = splitpath(base_path)
    name, ext = splitext(name)
    
    suffix = 1
    while true
        new_path = joinpath(dir, "$(name)_v$suffix$ext")
        if !isfile(new_path)
            return new_path  
        end
        suffix += 1
    end
end


"""
    visualize_directory(output_dir::String, visualization_dir::String)

Creates visualizations for the tesselation and all meshes within the `visualization_dir` 
directory and saves it to the `output_dir` directory.
"""
function visualize_directory(output_dir::String, visualization_dir::String)
    NeperStructureGenerator.visualize_tesselation(output_dir, visualization_dir)
    NeperStructureGenerator.visualize_mesh(output_dir, visualization_dir)
end

"""
    visualize_tesselation(output_dir::String, tess_dir::String)

Creates a visualizations for the tesselation in the `tess_dir` directory and saves it to 
the `output_dir` directory.
"""
function visualize_tesselation(output_dir::String, tess_dir::String)

    tess_dir = dirname(tess_dir)
    isdir(output_dir) || mkdir(output_dir)
    tess_file = Nothing
    tessfiles = readdir(tess_dir)
    tess_file = filter(file -> endswith(file, ".tess"), tessfiles)
    if length(tess_file) > 1
        error("More than one tesselation file in the given directory")
    elseif length(tess_file) == 0
        error("No tesselation file in the given directory")
    else
        tess_file = joinpath(tess_dir, tess_file[1])
    end
    base_name_with_ext = basename(tess_file)
    base_name, ext = splitext(base_name_with_ext)
    file_name = joinpath(output_dir, base_name) #base_name
    run(`neper -V $tess_file -print $file_name`)
end

"""
    visualize_mesh(output_dir::String, mesh_dir::String; mesh_name::String = Nothing)


Creates a visualizations for all meshes in the `mesh_dir` directory and saves it to 
the `output_dir` directory.

In order to only visualize a certain mesh within the `mesh_dir` directory, specify a 
`mesh_name`.
"""
function visualize_mesh(output_dir::String, mesh_dir::String; mesh_name::String = Nothing)

    mesh_dir = dirname(mesh_dir)
    isdir(output_dir) || mkdir(output_dir)

    # find toml file
    toml_path= Nothing
    files = readdir(mesh_dir)
    toml_path = filter(file -> endswith(file, ".toml"), files)
    if length(toml_path) > 1
        error("More than one toml file in the given directory.")
    elseif length(toml_path) == 0
        error("No toml file in the given directory.")
    else
        toml_path = joinpath(mesh_dir, toml_path[1])
    end

    # read toml file and extract path of given mesh name and path of corresponding tess
    toml_data = TOML.parsefile(toml_path)
    meshes = toml_data["MESHES"]
    tesselation = toml_data["TESSELATION"]
    if haskey(tesselation, "path")
        tess_path = tesselation["path"]
        tess_path = joinpath(mesh_dir, tess_path)
    else
        error("Tesselation file does not exist.")
    end
    if mesh_name !== Nothing
        if haskey(meshes, mesh_name)
            mesh = meshes[mesh_name]
            mesh_path = mesh["path"]
            mesh_path = joinpath(mesh_dir, mesh_path)
        else
            error("No mesh named $mesh_name in directory $mesh_dir")
        end
        base_name_with_ext = basename(mesh_path)
        base_name, ext = splitext(base_name_with_ext)
        file_name = joinpath(output_dir, base_name)

        run(`neper -V $tess_path,$mesh_path -print $file_name`)
    else
        for (key, dict) in meshes
            mesh_path = dict["path"]
            mesh_path = joinpath(mesh_dir, mesh_path)
            base_name_with_ext = basename(mesh_path)
            base_name, ext = splitext(base_name_with_ext)
            file_name = joinpath(output_dir, base_name)
            run(`neper -V $tess_path,$mesh_path -print $file_name`)
        end
    end

end

end



