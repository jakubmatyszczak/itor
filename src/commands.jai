#import "File";

parseCommand :: (using buffer : *Buffer, command : string) -> bool, string
{
    if command ==
    {
        case "w";
            if path == ""
                return false, "Save Failed, File Path not set";
            file, success := file_open(path, true, false, true);
            if !success
                return false, join("Save Failed, Count not open file: ", path);
            data : string;
            for *line : lines
                data = join(data, lineToString(line), "\n");
            return write_entire_file(path, data), join("File:", path,  " saved.");
        case "q";
            exit(0);
        case;
            return false, "";
    }
        
}

