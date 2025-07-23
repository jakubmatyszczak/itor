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
    for 0..25
        array_add(*lines, sprint("Sraka od dupaka % \t kuj.śćęrwó", it));

    last_time := seconds_since_init();
    quit := false;
    while !quit 
    {
        drawFrame();

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
                                cursor.y -= 1;
                            case #char "J";
                                cursor.y += 1;
                            case #char "H";
                                cursor.x -= 1;
                            case #char "L";
                                cursor.x += 1;
                        }
            }
                        
              // case .DRAG_AND_DROP_FILES;
              //   for dropped_files free(it);
              //   array_reset(*dropped_files);
              //   for event.files array_add(*dropped_files, copy_string(it));
        }
        if cursor.y < 0 cursor.y = 0;
        if cursor.x < 0 cursor.x = 0;
    }
}

current_theme: s32 = xx Default_Themes.Default;
my_theme: Overall_Theme;  // This gets filled out by calling the Theme_Proc for current_theme.
lines : [..]string;
cursor : Vector2;

draw_rect :: (pos : Vector2, size : Vector2, color : Vector4)
{
    Simp.immediate_quad(pos.x, pos.y, pos.x + size.x, pos.y + size.y, color);
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
    // 'k' is some resolution-adjusting unit of distance. Right now it is
    // 1/10 of the screen height, so, 108 pixels at 1920x1080.

    bg := Vector4.{0.019, 0.207, 0.161, 1.}; 
    fg := brighten(bg, 0.25);
    Simp.clear_render_target(bg.x, bg.y, bg.z, 1.);
    rect := get_rect(0, 0, 800, 600);
    
    origin := Vector2.{50, 600-50};
    charSize := Vector2.{xx Simp.get_character_width_in_pixels(font, cast(*u8)"M", 0), xx font.default_line_spacing};
    nCharactersLineNumber : s64 = xx log(cast(float)lines.count);
    textOriginX := origin.x + nCharactersLineNumber * charSize.x + 12; //accounts for line number
    for lines {
        lineOriginY := origin.y + it_index * -charSize.y;

        lineNumber : string = sprint("%", formatInt(it_index, minimum_digits=nCharactersLineNumber, padding=#char" "));
        trimmed := trim_right(it, " \t\r\n");
        Simp.draw_text(font, xx origin.x, xx lineOriginY, lineNumber, fg);
        Simp.draw_text(font, xx textOriginX, xx lineOriginY, trimmed, fg);
    }
    
    cursor_pos := .{textOriginX, origin.y} + .{cursor.x * charSize.x, -cursor.y * charSize.y};
    lineHighlighColor := brighten(fg, 0.1);
    lineHighlighColor.w = 0.1;
    cursorColor := brighten(fg, 0.5);
    cursorColor.w = 0.1;

    Simp.set_shader_for_color(true);
    draw_rect(origin + .{0., charSize.y}, .{textOriginX - origin.x, -600.}, lineHighlighColor);
    draw_rect(.{origin.x - 2, cursor_pos.y - 2}, .{800., charSize.y}, lineHighlighColor);
    draw_rect(cursor_pos - .{2, 2}, charSize, cursorColor);
    

    draw_rect(.{0., 0.}, .{800., charSize.y}, fg);
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
    font = Simp.get_font_at_size("./", "FiraCode-Regular.ttf", pixel_height);
    assert(font != null);
}

