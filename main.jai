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
    charSize := Vector2i.{Simp.get_character_width_in_pixels(font, cast(*u8)"M", 0), font.default_line_spacing};
    b1 = .{ origin = .{0, 0}, size = .{400, 400}, charSize = charSize, lines = lines};
    while !quit 
    {
        drawFrame();

        dCursor = .{};

        dt := cast(float)(current_time - last_time);
        last_time = current_time;

        Input.update_window_events();

        for Input.get_window_resizes()
        {
            Simp.update_window(it.window);
            b1.size.x = it.width - b1.origin.x;
            b1.size.y = it.height - b1.origin.y;
        }

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
                            case #char "Q";
                                experiment = !experiment;
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
experiment := false;
b1 : Buffer;

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

    computeBufferView(*b1, dCursor);

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
Buffer :: struct
{
    origin : Vector2i;
    size : Vector2i;
    
    charSize : Vector2i;
    viewMargin :: 5;

    viewOriginCh : Vector2i;
    cursor : Vector2i;
    cursorWannaBeX : s64;
    
    lines : []string;
}
computeBufferView :: (using buffer : *Buffer, dCursor :  Vector2i)
{
    bg : Vector4 = .{0.019, 0.207, 0.161, 1.}; 
    fg : Vector4 = brighten(bg, 0.25);
    hl : Vector4 = brighten(fg, 0.25);

    lineNumberWidthCh : s64 = xx log(cast(float)lines.count);
    lineNumberWidthPx : s64 = lineNumberWidthCh * charSize.x;
    viewSizeCh : Vector2i = size / charSize - .{lineNumberWidthCh, 1}; // padding for status bar on bottom
    textOrigin : Vector2i = origin + .{0, size.y} + .{ lineNumberWidthPx,  -charSize.y};

    if dCursor.y != 0 && cursorWannaBeX < cursor.x
        cursorWannaBeX = cursor.x;
    cursor += dCursor;
    cursor.y = clamp(cursor.y, 0, lines.count - 1);
    line := lines[cursor.y];
    
    if dCursor.x != 0
        cursorWannaBeX = cursor.x;
    if cursorWannaBeX > cursor.x
        cursor.x = cursorWannaBeX;
    cursor.x = clamp(cursor.x, 0, line.count - 1);

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

    // draw text
    for lines
    {
        if it_index < viewOriginCh.y || it_index > viewOriginCh.y + viewSizeCh.y
            continue;
        lineYCh := it_index - viewOriginCh.y;
        lineOrigin := textOrigin - .{0, lineYCh * charSize.y};
        trimmed := slice(it, viewOriginCh.x, viewSizeCh.x);
        Simp.draw_text(font, lineOrigin.x, lineOrigin.y, trimmed, fg); // should use slice and only write part of string that is in view
    }

    // draw line numbers
    Simp.set_shader_for_color(true);
    draw_rect(origin, .{lineNumberWidthPx, size.y}, fg);
    for lines
    {
        lineOrigin := textOrigin - .{lineNumberWidthPx, it_index * charSize.y} ;
        lineNumber : string = sprint("%", formatInt(it_index, minimum_digits=lineNumberWidthCh, padding=#char" "));
        Simp.draw_text(font, lineOrigin.x, lineOrigin.y, lineNumber, bg);
    }

    // draw cursor
    Simp.set_shader_for_color(true);
    cursorClr := fg * .{1, 1, 1, 0.2};
    offset := -charSize / 10; 
    draw_rect(textOrigin + offset + cursorLocalCh * .{charSize.x, -charSize.y}, charSize, cursorClr);

    //line highlight
    draw_rect(textOrigin + offset + .{0, cursorLocalCh.y * -charSize.y}, .{size.x - lineNumberWidthPx, charSize.y}, cursorClr);

    // draw bar
    draw_rect(origin, .{size.x, charSize.y}, fg);
    coordsString := sprint("C: % | R: %", cursor.x, cursor.y);
    Simp.draw_text(font, origin.x , origin.y + 2, "EXPERIMENT", bg);
    Simp.draw_text(font, origin.x + size.x - Simp.prepare_text(font, coordsString) - 2,  origin.y + 2, coordsString, bg);
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
