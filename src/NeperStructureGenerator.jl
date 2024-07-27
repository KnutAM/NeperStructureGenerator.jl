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
    create_toml_data(name::String, dict::Dict)

Args:
    name (String): Path to the tesselation or mesh file, whose parameters are to be saved in the toml file
    dict (Dict): Dictionary with the parameters of the tesselation or mesh

Returns:
    Logs the parameters of each individual tesselation file and the respective mesh files
"""
function create_toml_data(name:: String, dict::Dict, file_path::String; custom = false)
    toml_path = dirname(file_path)
    toml_path = joinpath(toml_path, "input.toml")
    if isfile(toml_path)
        toml_data = TOML.parsefile(toml_path)
        num_keys = length(keys(toml_data["MESHES"]))
        if custom == true
            mesh_name = basename(name)
            mesh_name, ext = splitext(mesh_name)
        else
            mesh_name = "Mesh_" * string(num_keys)
        end
        toml_data["MESHES"][mesh_name] = dict
        toml_data["MESHES"][mesh_name]["path"] = file_path
        open(toml_path, "w") do file
            TOML.print(file, toml_data)
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

function check_mesh_args(file_path, new_mesh_dict)
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
            if same_name && same_args
                error("The requested mesh already exists ('$key') with the same name and arguments for this tesselation.")
            elseif !same_name && same_args
                error("The requested mesh already exists under a different name ('$key') with the same arguments for this tesselation.")
            elseif same_name && !same_args
                error("A mesh with the same custom mesh name already exists ('$key') with different arguments.")
            end
        end
    else
        error("The input.toml file does not exist.")
    end
end

function check_dicts_equal(dict, new_dict)
    """
    dict: Existing dict ("Already has "path" key)
    new_dict: New dict (Does not have "path" key yet)
    """
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
    tesselate(base_name::String, parent_folder::String, tesselation:: Dict)

Args:
    base_name (String): Name of the tesselation and orientation file
    parent_folder (String): Root directory
    tesselation (Dict): Dictionary containg the tesselation parameters

Returns: 
    Creates a tesselation with the respective orientation file according to the tesselation parameters
"""
function tesselate(;
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
    mesh(base_name::String, parent_folder::String, tesselation::Dict, meshing::Dict)

Args:
    base_name (String): Name of the tesselation and orientation file
    parent_folder (String): Root directory
    tesselation (Dict): Dictionary containg the tesselation parameters
    meshing (Dict): Dictionary containg the meshing parameters

Returns:
    Creates a mesh according to the meshing parameters for the tesselation specified in the tesselation parameters
"""
function mesh(;
    tess_path = Nothing,
    meshing = Dict(),
    custom_mesh_name = Nothing)

    isfile(tess_path)||error("Tesselation file $(tess_path) does not exist.")

    meshing_settings = merge(meshing_defaults, meshing)
    dir_name = dirname(tess_path)

    if custom_mesh_name !== Nothing
        mesh_path = joinpath(dir_name, custom_mesh_name) * ".msh"
        check_mesh_args(mesh_path, meshing_settings)
        create_toml_data(mesh_path, meshing_settings, mesh_path, custom = true)
    else
        mesh_path = generate_directory_name(dir_name, meshing_settings) * ".msh"
        check_mesh_args(mesh_path, meshing_settings)
        create_toml_data(mesh_path, meshing_settings, mesh_path)
    end

    run(`neper -M $tess_path $(create_cmdargs(meshing_settings)) -o $mesh_path -format msh,inp`)
    return mesh_path
end

function get_unique_path(base_path::AbstractString)
######## Depreceated
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

function visualize_directory(args...)
  #  visualize_tesselation(args...) good way to forward arguments
 # basically two line function
    

    # search for directories 
    directories = filter(isdir, readdir(directory_path))

    # filter directories with input.toml file
    matching_directories = String[]
    for dir in directories
        input_toml_path = joinpath(directory_path, dir, "input.toml")
        if isfile(input_toml_path)
            push!(matching_directories, joinpath(directory_path, dir))
        end
    end

    # visualize the contents
    # CASE 1: Directory was given
    if length(matching_directories) == 0
        files_dir = readdir(directory_path)
        if "input.toml" in files_dir
            NeperStructureGenerator.visualize_tesselation(tess_path = directory_path)
            NeperStructureGenerator.visualize_mesh(mesh_dir = directory_path, visualize_all = true)
        end
    # CASE 2: No directory was given, therefore pwd() is the directory‚ 
    else
        for dir in matching_directories
            NeperStructureGenerator.visualize_tesselation(tess_path = dir)
            NeperStructureGenerator.visualize_mesh(mesh_dir = dir, visualize_all = true)
        
        end
    end
end


"""
    neper_julia_visualize(tess::String)

Args:
    tess: path to tesselation file or directory containing tesselation

Returns:
    Creates a visualization of the tesselation
"""
function visualize_tesselation(;
    tess_path = Nothing)
    tess_file = Nothing
    if tess_path === Nothing 
        error("No tesselation provided.")
    end
    if isdir(tess_path)
        tessfiles = readdir(tess_path)
        tess_file = filter(file -> endswith(file, ".tess"), tessfiles)
        if length(tess_file) != 1
            error("More than one tesselation file in the given directory")
        else
            tess_file = joinpath(tess_path, tess_file[1])
        end
    elseif isfile(tess_path)
        tess_file = tess_path
    else
        error("Tesselation file does not exist.")
    end
    dir_name = dirname(tess_file)
    base_name_with_ext = basename(tess_file)
    base_name, ext = splitext(base_name_with_ext)
    file_name = joinpath(dir_name, base_name) #base_name
    # If the part that is commented out is included, the files are stored in the respective folders instead of pwd()
    
    run(`neper -V $tess_file -print $file_name`)
end

# """
# give dir with mesh name (toml)
# or give mesh path directly

# mesh_dir: path to directory containing meshes 
# """
function visualize_mesh(;
    mesh_dir = Nothing,
    mesh_name = Nothing,
    mesh_file = Nothing,
    visualize_all = false)

    # Check input arguments
    if mesh_dir === Nothing && mesh_file === Nothing && mesh_name === Nothing
        error("No mesh directory or mesh file provided.")
    elseif  mesh_dir === Nothing && mesh_file === Nothing && mesh_name !== Nothing
        error("No mesh directory provided for mesh $mesh_name.")
    elseif mesh_dir === Nothing && mesh_file !== Nothing && mesh_name === Nothing
        if !isfile(mesh_file)
            error("Given mesh file $mesh_file does not exist")
        end
    elseif mesh_dir !== Nothing && mesh_file !== Nothing && mesh_name === Nothing
        println("Ignoring mesh directory $mesh_dir, because mesh file was given and no mesh name was given.")
    elseif mesh_dir === Nothing && mesh_file !== Nothing && mesh_name !== Nothing
        println("Ignoring mesh name $mesh_name, because mesh file was given and no mesh directory was given")
    elseif visualize_all == true && mesh_name !== Nothing && mesh_dir !== Nothing
        println("Ignoring mesh name, because visualize_all is set to true, therefore all meshes are visualized")
    end
    # CASE 1: Mesh directory given and mesh name given -> visualize that specific mesh
    toml_path= Nothing

    if (mesh_dir !== Nothing && mesh_name !== Nothing) || (mesh_dir !== Nothing && visualize_all == true)

        # find toml file in given directory
        files = readdir(mesh_dir)
        toml_path = filter(file -> endswith(file, ".toml"), files)
        if length(toml_path) != 1
            error("More than one toml file in the given directory.")
        else
            toml_path = joinpath(mesh_dir, toml_path[1])
        end

        # read toml file and extract path of given mesh name and path of corresponding tess
        toml_data = TOML.parsefile(toml_path)
        meshes = toml_data["MESHES"]
        tesselation = toml_data["TESSELATION"]
        if haskey(tesselation, "path")
            tess_path = tesselation["path"]
        else
            error("Tesselation file does not exist.")
        end
        if visualize_all == false
            if haskey(meshes, mesh_name)
                mesh = meshes[mesh_name]
                mesh_path = mesh["path"]
            else
                error("No mesh named $mesh_name in directory $mesh_dir")
            end

            base_name_with_ext = basename(mesh_path)
            base_name, ext = splitext(base_name_with_ext)
            file_name = joinpath(mesh_dir, base_name) #base_name #
            # If the part that is commented out is included, the files are stored in the respective folders instead of pwd()

            run(`neper -V $tess_path,$mesh_path -print $file_name`)
        else
            for (key, dict) in meshes
                mesh_path = dict["path"]
                base_name_with_ext = basename(mesh_path)
                base_name, ext = splitext(base_name_with_ext)
                file_name = joinpath(mesh_dir, base_name) # base_name #
                # If the part that is commented out is included, the files are stored in the respective folders instead of pwd()
                run(`neper -V $tess_path,$mesh_path -print $file_name`)
            end
        end
    end

    # CASE 2: Mesh file path given -> visualize that specific mesh
    toml_path = Nothing
    if mesh_file !== Nothing

        # find toml file in directory of given file
        mesh_dir = dirname(mesh_file)
        files = readdir(mesh_dir)
        toml_path = filter(file -> endswith(file, ".toml"), files)
        if length(toml_path) != 1
            error("More than one toml file in the given directory.")
        else
            toml_path = joinpath(mesh_dir, toml_path[1])
        end

        # read toml file and extract path of given of corresponding tess
        toml_data = TOML.parsefile(toml_path)
        tesselation = toml_data["TESSELATION"]
        if haskey(tesselation, "path")
            tess_path = tesselation["path"]
        else
            error("Tesselation file does not exist.")
        end

        base_name_with_ext = basename(mesh_file)
        base_name, ext = splitext(base_name_with_ext)
        file_name = joinpath(mesh_dir, base_name) #base_name
        # If the part that is commented out is included, the files are stored in the respective folders instead of pwd()
        run(`neper -V $tess_path,$mesh_file -print $file_name`)
    end
end

end



