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
            return file_write(*file, join(..lines)), join("File:", path,  " saved.");
    }
        
}

