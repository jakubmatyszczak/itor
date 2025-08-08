#import "GetRect";
#import "Window_Creation";
#import "Basic";
#import "String";
#import "System";
#import "Math";
#import "Unicode";
Simp :: #import "Simp";
Input :: #import "Input";
#import "File";

#load "commands.jai";

window: Window_Type;

current_time : float64;

ItorMode :: enum
{
    NORMAL;
    INSERT;
    COMMAND;
}
mode := ItorMode.NORMAL;
newMode := ItorMode.NORMAL;
command : string;
commandResult : string;

renderTargetBg : *Simp.Texture;
renderTargetText : *Simp.Texture;
// targetOverlay : *Simp.Texture; // text coloring??

fillBufferFromFile :: (buf : *Buffer, filepath : string) -> bool, string
{
    fileData, success := read_entire_file(filepath);
    defer free(fileData);
    if !success
        return false, join("Could not read file: ", filepath);
    thereIsMore := true;
    line, rest : string;
    rest = fileData;
    while thereIsMore
    {
        thereIsMore, line, rest = split_from_left(rest, #char "\n");
        if thereIsMore
            array_add(*buf.lines, stringToLine(line));
        else
        {
            if rest.count == 0
                array_add(*buf.lines, stringToLine(""));
            else
                array_add(*buf.lines, stringToLine(rest));
        }
    }
    buf.path = filepath;
    return true, join("Opened file: ", filepath);
}

main :: ()
{
    args := get_command_line_arguments();
    print("cwd: %\n", get_working_directory());
    print("exe: %\n", get_path_of_running_executable());
    for arg : args 
    {
        if it_index == 0  continue;
        filepath := arg;
        if !is_absolute_path(arg)
            filepath = join(get_working_directory(), "/", arg); 
        success, msg := fillBufferFromFile(*b1, filepath);
        if !success
            array_add(cast(*[..]string)*b1.lines, "");
        break;
    }

    window = create_window(800, 600, "itor");
    Simp.set_render_target(window);
    renderTargetBg = Simp.texture_create_render_target(800, 600, .RGBA8);
    renderTargetText = Simp.texture_create_render_target(800, 600, .RGBA8);

    fontInit();
    ui_init();

    last_time := seconds_since_init();
    quit := false;
    charSize := Vector2i.{Simp.get_character_width_in_pixels(font, cast(*u8)"M", 0), font.default_line_spacing};
    b1.size = .{400, 400};
    b1.charSize = charSize;

    while !quit 
    {
        drawFrame();

        input = 0;
        inputSpecial = false;
        dCursor = .{};
        dt := cast(float)(current_time - last_time);
        last_time = current_time;


        Input.update_window_events();
        for Input.get_window_resizes()
        {
            free(renderTargetBg);
            free(renderTargetText);
            renderTargetBg = Simp.texture_create_render_target(it.width, it.height, .RGBA8);
            renderTargetText = Simp.texture_create_render_target(it.width, it.height, .RGBA8);
            Simp.update_window(it.window);
            b1.size.x = it.width - b1.origin.x;
            b1.size.y = it.height - b1.origin.y;
        }
        processInput(Input.events_this_frame);

        sleep_milliseconds(16);
    }
}

current_theme: s32 = xx Default_Themes.Default;
my_theme: Overall_Theme;  // This gets filled out by calling the Theme_Proc for current_theme.

dCursor : Vector2i;
screenOrigin : Vector2i = .{0, 0};
experiment := false;
b1 : Buffer;
input : u8;
inputSpecial : bool = false;

draw_rect :: (pos : Vector2i, size : Vector2i, color : Vector4)
{
    Simp.immediate_quad(cast(float)pos.x, cast(float)pos.y, cast(float)(pos.x + size.x), cast(float)(pos.y + size.y), color);
}
drawFrame :: ()
{
    proc := default_theme_procs[current_theme];
    my_theme = proc();
    set_default_theme(my_theme);  // Just in case we don't explicitly pass themes sometimes...!

    bg_col := my_theme.background_color;

    x, y, width, height := get_dimensions(window, true);
    ui_per_frame_update(window, width, height, current_time);

    button_theme := my_theme.button_theme;
    button_theme.font = font;
    button_theme.enable_variable_frame_thickness = true;

    Simp.set_render_target(window);
    Simp.set_shader_for_images(renderTargetBg);
    Simp.immediate_quad(0, 0, xx renderTargetBg.width, xx renderTargetBg.height, .{1, 1, 1, 1,});
    Simp.set_shader_for_images(renderTargetText);
    Simp.immediate_quad(0, 0, xx renderTargetBg.width, xx renderTargetBg.height, .{1, 1, 1, 1,});

    computeBufferView(*b1, dCursor, input);

    Simp.swap_buffers(window);
}

font : *Simp.Dynamic_Font;
working_directory_set := false;
fontInit :: ()
{
    if !working_directory_set {
        // So that we can load our font, set to path of running executable.
        path := path_strip_filename(get_path_of_running_executable());
        set_working_directory(path);

        working_directory_set = true;
    }

    pixel_height := 24;
    font = Simp.get_font_at_size("./res", "FiraCode-Regular.ttf", pixel_height);
    assert(font != null);
}
lineToString :: (line : *Line) -> string
{
    str : string;
    str.count = line.count;
    str.data = line.data.data;
    return str;
}
stringToLine :: (str : string) -> Line
{
    line : Line;
    line.count = str.count;
    memcpy(line.data.data, str.data, str.count);
    return line;
}
line_slice :: (line : *Line, index : s64) -> Line
{
    newLine := Line.{count = line.count - index};
    memcpy(newLine.data.data, *line.data.data[index], line.count - index);
    return newLine;
}
line_replaceWithString :: (line : *Line, str : string)
{
    assert(str.count <= Line.maxLen);
    line.count = str.count;
    memcpy(line.data.data, str.data, line.count);
}
line_insertChar :: (line : *Line, index : s64, char : u8)
{
    assert(index < Line.maxLen);
    assert(line.count < Line.maxLen);
    tmp : Line;
    memcpy(*tmp.data.data[index], *line.data.data[index], line.count-index);
    memcpy(*line.data.data[index+1], *tmp.data.data[index], line.count-index);
    line.data[index] = char;
    line.count += 1;
}
line_removeChar :: (line : *Line, index : s64)
{
    assert(index < Line.maxLen);
    if line.count == 0
        return;
    memcpy(*line.data.data[index], *line.data.data[index+1], line.count-index);
    line.count -= 1;
}
operator += :: (l1 : *Line, l2 : *Line)
{
    preLen := l1.count;
    l1.count += l2.count;
    if l1.count > Line.maxLen
        l1.count = Line.maxLen;
    memcpy(*l1.data.data[preLen], l2.data.data, l1.count - preLen);

}
Line :: struct
{
    maxLen :: 128;
    count : s64;
    data : [maxLen]u8;
}
Buffer :: struct
{
    origin : Vector2i;
    size : Vector2i;
    
    charSize : Vector2i;
    viewMargin :: 5;

    viewOriginCh : Vector2i;
    cursor : Vector2i;
    cursorWannaBeX : s64;
    
    path : string;

    lines : [..]Line;
}
to_string :: (input : *u8) -> string
{
    str : string;
    str.count = 1;
    str.data = input;
    return str;
}
computeBufferView :: (using buffer : *Buffer, dCursor :  Vector2i, input: u8)
{
    bg : Vector4 = .{0.019, 0.207, 0.161, 1.}; 
    fg : Vector4 = brighten(bg, 0.25);
    hl : Vector4 = brighten(fg, 0.25);

    lineNumberWidthCh : s64 = xx log(cast(float)lines.count);
    if lineNumberWidthCh < 3
        lineNumberWidthCh = 3;
    lineNumberWidthPx : s64 = lineNumberWidthCh * charSize.x;
    viewSizeCh : Vector2i = size / charSize - .{lineNumberWidthCh, 1}; // padding for status bar on bottom
    textOrigin : Vector2i = origin + .{0, size.y} + .{ lineNumberWidthPx,  -charSize.y};

    if dCursor.y != 0 && cursorWannaBeX < cursor.x
        cursorWannaBeX = cursor.x;
    cursor += dCursor;
    cursor.y = clamp(cursor.y, 0, lines.count - 1);
    line : *Line  = *lines.data[cursor.y];
    
    if dCursor.x != 0
        cursorWannaBeX = cursor.x;
    if cursorWannaBeX > cursor.x
        cursor.x = cursorWannaBeX;
    cursor.x = clamp(cursor.x, 0, line.count);
    cursor.y = clamp(cursor.y, 0, lines.count);

    cursorLocalCh : Vector2i = cursor - viewOriginCh;
    // compute screen movement Y
    if cursorLocalCh.y < viewMargin
        viewOriginCh.y -= viewMargin - cursorLocalCh.y;
    if cursorLocalCh.y > viewSizeCh.y - viewMargin
        viewOriginCh.y += cursorLocalCh.y - (viewSizeCh.y - viewMargin);

    // compute screen movement X
    if cursorLocalCh.x < viewMargin
        viewOriginCh.x -= viewMargin - cursorLocalCh.x;
    if cursorLocalCh.x > viewSizeCh.x - viewMargin
        viewOriginCh.x += cursorLocalCh.x - (viewSizeCh.x - viewMargin);
    
    viewOriginCh.y = clamp(viewOriginCh.y, 0, lines.count);
    viewOriginCh.x = clamp(viewOriginCh.x, 0, lines[cursor.y].count);

    cursorLocalCh = cursor - viewOriginCh;

    // edit
    if input != 0 && mode == .COMMAND
    {
        if input == 0x08 // handle backspace
            command = slice(command, 0, command.count - 1);
        else if input == #char "\n" //handle newline
        {
            success : bool;
            success, commandResult = parseCommand(buffer, command);
            command =  "";
            newMode = .NORMAL;
        }
        else
            command = join(command, to_string(*input));
    }
    if input != 0 && mode == .INSERT
    {
        if line.count == 0 && !inputSpecial 
        {
            line_insertChar(line, 0, input);
            cursor.x = 1;
            cursorWannaBeX = cursor.x;
        }
        else
        {
            if input == 0x08 // handle backspace
            {
                if cursor.x > 0
                {
                    line_removeChar(line, cursor.x-1);
                    cursor.x -= 1;
                    cursorWannaBeX -= 1;
                }
                else if line.count == 0 && lines.count > 0
                    array_ordered_remove_by_index(*lines, cursor.y);
                else if cursor.y > 0
                {
                    cursor.x = lines[cursor.y-1].count;
                    cursorWannaBeX = cursor.x;
                    lines[cursor.y-1] += line;
                    array_ordered_remove_by_index(*lines, cursor.y);
                    cursor.y -= 1;
                }
                    
            }
            else if input == 0x7F // handle delete
            {
                if cursor.x < line.count
                    line_removeChar(line, cursor.x);
                if line.count == 0 && lines.count > 0
                    array_ordered_remove_by_index(*lines, cursor.y);
            }
            else if input == #char "\n" //handle newline
            {
                array_insert_at(*lines, line_slice(line, cursor.x), cursor.y+1);
                line = *lines[cursor.y]; //in case lines grows and get new mem from system
                line.count -= (line.count - cursor.x);

                line = *lines[cursor.y+1];
                cursor.y += 1;
                cursor.x = 0;
                cursorWannaBeX = 0;
            }
            else // any regular character
            {
                line_insertChar(line, cursor.x, input);
                cursor.x += 1;
            }
        }
    }
    if lines.count == 0
        array_add(*lines, stringToLine(""));

    // draw text
    Simp.set_render_target(renderTargetText);
    Simp.clear_render_target(0., 0., 0., 0.);
    for lines
    {
        if it_index < viewOriginCh.y || it_index >= viewOriginCh.y + viewSizeCh.y
            continue;
        lineYCh := it_index - viewOriginCh.y;
        lineOrigin := textOrigin - .{0, lineYCh * charSize.y};
        trimmed := slice(lineToString(*it), viewOriginCh.x, viewSizeCh.x);
        Simp.draw_text(font, lineOrigin.x, lineOrigin.y, trimmed, fg); // should use slice and only write part of string that is in view
        
        lineOrigin.x = textOrigin.x - lineNumberWidthPx;
        lineNumber : string = sprint("%", formatInt(it_index, minimum_digits=lineNumberWidthCh, padding=#char" "));
        Simp.draw_text(font, lineOrigin.x, lineOrigin.y, lineNumber, bg);
    }

    // draw background
    Simp.set_render_target(renderTargetBg);
    Simp.clear_render_target(bg.x, bg.y, bg.z, 1.);
    Simp.set_shader_for_color(true);
    draw_rect(origin, .{lineNumberWidthPx, size.y}, fg);

    // draw line numbers

    // draw cursor
    cursorClr := fg * .{1, 1, 1, 0.2};
    offset := -charSize / 10; 
    draw_rect(textOrigin + offset + cursorLocalCh * .{charSize.x, -charSize.y}, charSize, cursorClr);

    //line highlight
    draw_rect(textOrigin + offset + .{0, cursorLocalCh.y * -charSize.y}, .{size.x - lineNumberWidthPx, charSize.y}, cursorClr);

    // draw bar
    draw_rect(origin, .{size.x, charSize.y - 2}, fg);
    coordsString := tprint("C: % | R: %", cursor.x, cursor.y);
    modeString : string;
    if mode == 
    {
        case ItorMode.NORMAL;
            modeString = commandResult;
            if commandResult.count == 0
                modeString = "NORMAL";

        case ItorMode.INSERT;
            modeString = "INSERT";
        case ItorMode.COMMAND;
            modeString = join("COMMAND:", command);
            commandCursorOrigin := Vector2i.{origin.x + Simp.prepare_text(font, modeString), origin.y + 2};
            draw_rect(commandCursorOrigin, charSize - .{0, 6}, bg);
    }
    Simp.draw_text(font, origin.x , origin.y + 4, modeString, bg);
    Simp.draw_text(font, origin.x + size.x - Simp.prepare_text(font, coordsString) - 2,  origin.y + 2, coordsString, bg);
}

processInput :: (events: [..]Input.Event)
{
    for event : events
    {
        if event.type == .QUIT
            exit(0);
        getrect_handle_event(event);

        if #complete mode ==
        {
            case ItorMode.NORMAL;
                processInputNormal(event);
            case ItorMode.INSERT;
                processInputInsert(event);
            case ItorMode.COMMAND;
                processInputCommand(event);
        }
    }
    mode = newMode;
}
processInputNormal :: (event : Input.Event)
{
    kc := event.key_code;
    if event.type != .KEYBOARD || !event.key_pressed
        return;
    if kc == 
    {
        case .ARROW_UP; #through;
        case #char "K";
            dCursor.y = -1;
        case .ARROW_DOWN; #through;
        case #char "J";
            dCursor.y = 1;
        case .ARROW_LEFT; #through;
        case #char "H";
            dCursor.x = -1;
        case .ARROW_RIGHT; #through;
        case #char "L";
            dCursor.x = 1;
        case #char "I";
            newMode = ItorMode.INSERT;
        case #char ":";
            newMode = ItorMode.COMMAND;
        case .PAGE_UP;
            dCursor.y = -10;
        case .PAGE_DOWN;
            dCursor.y = +10;
    }
}
processInputInsert :: (event : Input.Event)
{
    if event.type == 
    {
        case .KEYBOARD;
        {
            if !event.key_pressed
                return;
            if event.key_code == 
            {
                case .ESCAPE;
                    newMode = ItorMode.NORMAL;
                case .ENTER;
                    input = #char "\n";
                    inputSpecial = true;
                case .BACKSPACE;
                    input = 0x08;
                    inputSpecial = true;
                case .DELETE;
                    input = 0x7F;
                    inputSpecial = true;
                case .ARROW_UP;
                    dCursor.y = -1;
                case .ARROW_DOWN;
                    dCursor.y = +1;
                case .ARROW_LEFT;
                    dCursor.x = -1;
                case .ARROW_RIGHT;
                    dCursor.x = +1;
                case .PAGE_UP;
                    dCursor.y = -10;
                case .PAGE_DOWN;
                    dCursor.y = +10;
            }
        }
        case .TEXT_INPUT;
            input = character_utf32_to_utf8(event.utf32).data[0];
            inputSpecial = false;
    }
}
processInputCommand :: (event : Input.Event)
{
    if event.type == 
    {
        case .KEYBOARD;
        {
            if !event.key_pressed
                return;
            if event.key_code == 
            {
                case .ESCAPE;
                    newMode = ItorMode.NORMAL;
                    command = "";
                case .ENTER;
                    input = #char "\n";
                    inputSpecial = true;
                case .BACKSPACE;
                    input = 0x08;
                    inputSpecial = true;
                case .DELETE;
                    input = 0x7F;
                    inputSpecial = true;
            }
        }
        case .TEXT_INPUT;
            input = character_utf32_to_utf8(event.utf32).data[0];
            inputSpecial = false;
    }
}

Vector2i :: struct
{
    x : s64;
    y : s64;
}
operator + :: (a: Vector2i, b: Vector2i) -> Vector2i
{
    return .{a.x + b.x, a.y + b.y};
}
operator - :: (a: Vector2i, b: Vector2i) -> Vector2i
{
    return .{a.x - b.x, a.y - b.y};
}
operator - :: (a: Vector2i) -> Vector2i
{
    return .{-a.x, -a.y};
}
operator -= :: (a: *Vector2i, b: Vector2i)
{
    a.x -= b.x;
    a.y -= b.y;
}
operator * :: (a: Vector2i, b: Vector2i) -> Vector2i
{
    return .{a.x * b.x, a.y * b.y};
}
operator * :: (a: Vector2i, b: float) -> Vector2i #symmetric
{
    return .{cast(s64)(a.x * b), cast(s64)(a.y * b)};
}
operator / :: (a: Vector2i, b: Vector2i) -> Vector2i
{
    return .{a.x / b.x, a.y / b.y};
}
operator / :: (a: Vector2i, b: float) -> Vector2i #symmetric
{
    return .{cast(s64)(a.x / b), cast(s64)(a.y / b)};
}
operator != :: (a: Vector2i, b: s64) -> bool #symmetric
{
    return (a.x != b || a.y != b);
}
clamp :: (val: s64, min: s64, max: s64) -> s64
{
    if val < min
        return min;
    if val > max
        return max;
    return val;
}

