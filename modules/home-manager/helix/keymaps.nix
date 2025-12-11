{
  normal = {
    # staying on the homerow baby
    h = "no_op";
    j = "move_char_left"; # was h
    k = "move_visual_line_down"; # was j
    l = "move_visual_line_up"; # was k
    "ø" = "move_char_right"; # was l

    # Repeat last motion key
    "A-." = "no_op";
    ";" = "repeat_last_motion";  # default: collapse_selection

    # delete + change non yanking, plus cut
    d = "delete_selection_noyank";
    c = "change_selection_noyank";
    x = "delete_selection"; # cut
    X = "change_selection"; # cut+insert

    # increment (because tmux uses ctrl+a)
    "C-a" = "no_op";
    "C-b" = "increment";

    # flip macro bindings
    q = "record_macro";  # default: replay_macro
    Q = "replay_macro";  # default: record_macro

    # disable - not actively used.
    home = "no_op";
    end = "no_op";
    pageup = "no_op";
    pagedown = "no_op";
    "`" = "no_op";
    "A-`" = "no_op";
    "." = "no_op";
    "A-u" = "no_op";
    "A-U" = "no_op";
    "\"" = "no_op";
    "A-d" = "no_op";
    "A-c" = "no_op";
    # not gonna use the shell stuff EVER
    "|" = "no_op";
    "A-|" = "no_op";
    "!" = "no_op";
    "A-!" = "no_op";
    "$" = "no_op";
  };
}
