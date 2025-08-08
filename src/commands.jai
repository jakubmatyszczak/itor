#import "File";

saveBufferToFile :: (using buffer : *Buffer) -> bool, string
{
    if path == ""
        return false, "Failed to save. Path empty.";
    file, success := file_open(path, true, false, true);
    if !success
        return false, "Failed to save. Could not open file for writing.";
    data : string;
    for *line : lines
        data = join(data, lineToString(line), "\n");
    if write_entire_file(path, data)
        return true, join("Saved file: ", path);
    else
        return false, join("Failed to save - error: ", path);
}

parseCommand :: (using buffer : *Buffer, command : string) -> bool, string
{
    interpretedCommand := command;
    if begins_with(command, "w ")
    {
        _, _, right := split_from_left(command, #char " ");
        buffer.path = join(get_working_directory(), "/", right);
        print("saving will be done to: %", path);
        interpretedCommand = "w";
    }
    if interpretedCommand ==
    {
        case "w";
            success, msg := saveBufferToFile(buffer);
            return success, msg;
        case "q";
            exit(0);
        case;
            return false, "";
    }
}

