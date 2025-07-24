#import "Basic";
#import "Compiler";
#import "Process";
#import "String";

#run
{
    w := compiler_create_workspace();
    if !w 
    {
        print("Workspace creation failed.\n");
        return;
    }

    options := get_build_options(); 
    args := options.compile_time_command_line;
    for arg : args
        print("%\n", arg);

    set_optimization(*options, .DEBUG);
    options.output_type = .EXECUTABLE; 
    options.backend =.X64; 
    options.output_executable_name = "itor";
    options.intermediate_path = join(#filepath, "build");
    options.output_path = join(#filepath, "build");
    
    set_build_options_dc(.{do_output=false});

    for arg : args
        if arg == 
        {
            case "release";
                set_optimization(*options, .OPTIMIZED);
                options.backend = .LLVM;
                options.array_bounds_check = .OFF; 
        }
    set_build_options(options, w);

    compiler_begin_intercept(w);
    
    add_build_file("main.jai", w);
    success := true;
    while true 
    {
        message := compiler_wait_for_message();
        if !message break;
        if message.kind == 
        {
            case .ERROR;
                success = false;
            case .COMPLETE;
                break;
        }
    }
    compiler_end_intercept(w);

    if !success
        return;
    run_command("cp", "-r", "res", "build/", working_directory=#filepath);
    run_command("build/itor", join(#filepath, "build"));
}



