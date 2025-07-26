#import "GetRect";
#import "Window_Creation";
#import "Basic";
#import "String";
#import "System";
#import "Math";
#import "Unicode";
Simp :: #import "Simp";
Input :: #import "Input";

window: Window_Type;

current_time : float64;

main :: ()
{
    window = create_window(800, 600, "itor");
    Simp.set_render_target(window);

    fontInit();
    ui_init();
    array_add(*lines, sprint("Sraka od dupaka"));
    array_add(*lines, sprint("Sraka od dupaka"));
    array_add(*lines, sprint("Sraka od dupaka dluga linia, Sraka od dupaka dluga linia, Sraka od dupaka dluga linia"));
    array_add(*lines, sprint("Sraka od dupaka"));
    array_add(*lines, sprint("Sraka od dupaka"));
    array_add(*lines, sprint("Sraka od dupaka dluga linia"));
    for 0..25
        array_add(*lines, sprint("Sraka od dupaka %", it));

    last_time := seconds_since_init();
    quit := false;
    while !quit 
    {
        drawFrame();

        dCursor = .{};

        dt := cast(float)(current_time - last_time);
        last_time = current_time;

        Input.update_window_events();

        for Input.get_window_resizes()
            Simp.update_window(it.window);

        for event: Input.events_this_frame
        {
            if event.type == .QUIT
                quit = true;

            getrect_handle_event(event);

            if event.type == 
            {
                case .KEYBOARD;
                    if event.key_pressed
                        if event.key_code ==
                        {
                            case .ESCAPE;
                                active_widget_deactivate_all();
                            case #char "K";
                                dCursor.y = -1;
                            case #char "J";
                                dCursor.y = 1;
                            case #char "H";
                                dCursor.x = -1;
                            case #char "L";
                                dCursor.x = 1;
                        }
            }
                        
              // case .DRAG_AND_DROP_FILES;
              //   for dropped_files free(it);
              //   array_reset(*dropped_files);
              //   for event.files array_add(*dropped_files, copy_string(it));
        }
    }
}

current_theme: s32 = xx Default_Themes.Default;
my_theme: Overall_Theme;  // This gets filled out by calling the Theme_Proc for current_theme.
lines : [..]string;

dCursor : Vector2i;
cursor : Vector2i;
cursorWannaBeX : s64;
screenOrigin : Vector2i = .{0, 0};

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
    Simp.clear_render_target(bg_col.x, bg_col.y, bg_col.z, 1);

    x, y, width, height := get_dimensions(window, true);
    ui_per_frame_update(window, width, height, current_time);

    button_theme := my_theme.button_theme;
    button_theme.font = font;
    button_theme.enable_variable_frame_thickness = true;

    red := Vector4.{1.0, 0, 0, 1};
    bg := Vector4.{0.019, 0.207, 0.161, 1.}; 
    fg := brighten(bg, 0.25);
    Simp.clear_render_target(bg.x, bg.y, bg.z, 1.);
    
    origin := Vector2i.{0, 600-50};
    charSize := Vector2i.{Simp.get_character_width_in_pixels(font, cast(*u8)"M", 0), font.default_line_spacing};
    nCharactersLineNumber : s64 = xx log(cast(float)lines.count);
    lineNumberWidthPx : s64 = (nCharactersLineNumber + 1) * charSize.x;
    textOriginX := origin.x + lineNumberWidthPx; //accounts for line number

    // setup
    nCharactersOnScreen : s64 = xx (800. / charSize.x) - nCharactersLineNumber - cast(s64)(cast(float)origin.x / charSize.x);
    nCharactersMargin : s64 = 5;
    nLinesOnScreen : s64 = xx (600. / charSize.y) - 1;
    nLinesMargin : s64 = 5;
    cursorScreen : Vector2i = cursor - screenOrigin;
    cursor += dCursor;
    
    // first deal with cursor.y
    if cursor.y < 0 cursor.y = 0;
    if cursor.y > xx lines.count cursor.y = xx lines.count;

    if cursorScreen.y < 0
        screenOrigin.y += cursorScreen.y;
    if cursorScreen.y > nLinesOnScreen - nLinesMargin
    {
        diff := cursorScreen.y - (nLinesOnScreen - nLinesMargin);
        screenOrigin.y += diff;
    }

    if screenOrigin.y < 0
        screenOrigin.y = 0;
    if cursor.y >= lines.count-1
        cursor.y = lines.count-1;
    cursorScreen.y = cursor.y - screenOrigin.y;

    // now do X
    if cursor.x < 0
        cursor.x = 0;
    if cursor.x > lines[cursor.y].count-1
        cursor.x = lines[cursor.y].count-1;
    
    if dCursor.x != 0
        cursorWannaBeX = cursor.x;
    if cursor.x < cursorWannaBeX
    {
        if cursorWannaBeX < lines[cursor.y].count
            cursor.x = cursorWannaBeX;
        else
            cursor.x = lines[cursor.y].count - 1;
    }

    // goint to the right
    if cursorScreen.x > nCharactersOnScreen - nCharactersMargin
    {
        diff := cursorScreen.x - (nCharactersOnScreen - nCharactersMargin);
        screenOrigin.x += diff;
    }
    //goint to the left
    if cursorScreen.x < nCharactersMargin 
        screenOrigin.x += (cursorScreen.x - nCharactersMargin);

    if screenOrigin.x < 0
        screenOrigin.x = 0;
    if cursorScreen.x < 0
        cursorScreen.x = 0;
        
    textOriginX -= screenOrigin.x * charSize.x;
    for lines
    {
        if it_index < screenOrigin.y || it_index > screenOrigin.y + nLinesOnScreen
            continue;
        lineOriginY := origin.y + (it_index - screenOrigin.y) * -charSize.y;
        trimmed := trim_right(it, " \t\r\n");
        Simp.draw_text(font, xx textOriginX, xx lineOriginY, trimmed, fg); // should use slice and only write part of string that is in view
    }
    Simp.set_shader_for_color(true);
    draw_rect(origin + .{0, charSize.y}, .{lineNumberWidthPx, -600}, bg); // overwrite existing text with lineNumber Rect
    for lines
    {
        if it_index < screenOrigin.y || it_index > screenOrigin.y + nLinesOnScreen
            continue;
        lineOriginY := origin.y + (it_index - screenOrigin.y) * -charSize.y;
        lineNumber : string = sprint("%", formatInt(it_index, minimum_digits=nCharactersLineNumber, padding=#char" "));
        Simp.draw_text(font, xx origin.x, xx lineOriginY, lineNumber, fg);
    }
    
    cursor_pos := .{textOriginX, origin.y} + .{cursor.x * charSize.x, -cursorScreen.y * charSize.y};
    lineHighlighColor := brighten(fg, 0.1);
    lineHighlighColor.w = 0.1;
    cursorColor := brighten(fg, 0.5);
    cursorColor.w = 0.1;

    Simp.set_shader_for_color(true);
    draw_rect(origin + .{0, charSize.y}, .{lineNumberWidthPx, -600}, lineHighlighColor); //line number color
    draw_rect(.{origin.x - 2, cursor_pos.y - 2}, .{800, charSize.y}, lineHighlighColor); //line highlight
    draw_rect(cursor_pos - .{2, 2}, charSize, cursorColor); //cursor highlight

    //bottom bar
    draw_rect(.{0, 0}, .{800, charSize.y}, fg);
    coordsString := sprint("C: % | R: %", cursor.x, cursor.y);
    Simp.draw_text(font, 800 - Simp.prepare_text(font, coordsString) - 2, 2, coordsString, bg);

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
