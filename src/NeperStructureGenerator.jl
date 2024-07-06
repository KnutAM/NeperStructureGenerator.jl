module NeperStructureGenerator

using TOML 

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
    create_toml_data(name::String, dict::Dict)

Args:
    name (String): Path to the tesselation or mesh file, whose parameters are to be saved in the toml file
    dict (Dict): Dictionary with the parameters of the tesselation or mesh

Returns:
    Logs the parameters of each individual tesselation file and the respective mesh files
"""
function create_toml_data(name:: String, dict::Dict, file_path::String)
    toml_path = dirname(file_path)
    toml_path = joinpath(toml_path, "input.toml")
    if isfile(toml_path)
        toml_data = TOML.parsefile(toml_path)
        num_keys = length(keys(toml_data["MESHES"]))
        for key in keys(toml_data["MESHES"])
            println(key)
        end
        mesh_name = "Mesh_" * string(num_keys)
        toml_data["MESHES"][mesh_name] = dict
        toml_data["MESHES"][mesh_name]["path"] = file_path
        open(toml_path, "w") do file
            TOML.print(file, toml_data)
        end
        for key in keys(toml_data["MESHES"])
            println(key)
        end
    else
        toml_data = Dict(name => dict)
        toml_data[name]["path"] = file_path
        toml_data["MESHES"] = Dict()
        open(toml_path, "w") do file
            TOML.print(file, toml_data)
        end
    end
end

"""
    neper_julia_tess(base_name::String, parent_folder::String, tesselation:: Dict)

Args:
    base_name (String): Name of the tesselation and orientation file
    parent_folder (String): Root directory
    tesselation (Dict): Dictionary containg the tesselation parameters

Returns: 
    Creates a tesselation with the respective orientation file according to the tesselation parameters
"""
function neper_julia_tess(;
    base_name = "crystal",
    parent_folder = pwd(),  
    tesselation = Dict())

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
    neper_julia_mesh(base_name::String, parent_folder::String, tesselation::Dict, meshing::Dict)

Args:
    base_name (String): Name of the tesselation and orientation file
    parent_folder (String): Root directory
    tesselation (Dict): Dictionary containg the tesselation parameters
    meshing (Dict): Dictionary containg the meshing parameters

Returns:
    Creates a mesh according to the meshing parameters for the tesselation specified in the tesselation parameters
"""
function neper_julia_mesh(;
    tess_name = Nothing,
    meshing = Dict(),
    custom_mesh_name = Nothing)

    isfile(tess_name)||error("Tesselation file $(tess_name) does not exist.")

    meshing_settings = merge(meshing_defaults, meshing)

    dir_name = dirname(tess_name)
    mesh_path = generate_directory_name(dir_name, meshing_settings) * ".msh"
    if custom_mesh_name !== Nothing
        create_toml_data(custom_mesh_name, meshing_settings, mesh_path)
    else
        create_toml_data(mesh_path, meshing_settings, mesh_path)
    end

    run(`neper -M $tess_name $(create_cmdargs(meshing_settings)) -o $mesh_path -format msh,inp`)
    return mesh_path
end

"""
    neper_julia_visualize(base_name::String, parent_folder::String, tesselation::Dict, meshing::Dict)

Args:
    base_name (String): Name of the tesselation and orientation file
    parent_folder (String): Root directory
    tesselation (Dict): Dictionary containg the tesselation parameters
    meshing (Dict): Dictionary containg the meshing parameters

Returns:
    Creates a visualization of the tesselation and the mesh if it exists
"""
function neper_julia_visualize_tess(;
    tess = Nothing)
    tess_file = Nothing
    if tess === Nothing 
        error("No tesselation provided.")
    end
    if isdir(tess)
        tessfiles = readdir(tess)
        tess_file = filter(file -> endswith(file, ".tess"), tessfiles)
        if length(tess_file) != 1
            error("More than one tesselation file in the given directory")
        else
            tess_file = joinpath(tess, tess_file[1])
        end
    elseif isfile(tess)
        tess_file = tess
    else
        error("Tesselation file does not exist.")
    end
    

    dir_name = dirname(tess_file)
    base_name_with_ext = basename(tess_file)
    base_name, ext = splitext(base_name_with_ext)
    file_name = joinpath(dir_name, base_name)
    run(`neper -V $tess_file -print $file_name`)
    end
end

function neper_julia_visadgrfsualize_mesh(;
    tess_name = Nothing,
    mesh_name = Nothing)

    if tess_name === Nothing && mesh_name === Nothing
        error("No tesselation and mesh files provided.")
    end
    if !isfile(tess_name) && !isfile(mesh_name)
        error("The provided tesselation and mesh files do not exist.")
    end
    if tess_name !== Nothing && isfile(tess_name)
        dir_name = dirname(tess_name)
        base_name_with_ext = basename(tess_name)
        base_name, ext = splitext(base_name_with_ext)
        file_name = joinpath(dir_name, base_name)
        run(`neper -V $tess_name -print $file_name`)
    end
    if (tess_name !== Nothing && isfile(tess_name)) && (mesh_name !== Nothing && isfile(mesh_name))
        dir_name = dirname(tess_name)
        base_name_with_ext = basename(mesh_name)
        base_name, ext = splitext(base_name_with_ext)
        file_name = joinpath(dir_name, base_name)
        run(`neper -V $tess_name,$mesh_name -print $file_name`)
    end
end

