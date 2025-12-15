{
  normal = {
    # staying on the homerow baby
    h = "no_op";
    j = "move_char_left"; # was h
    k = "move_visual_line_down"; # was j
    l = "move_visual_line_up"; # was k
    "ø" = "move_char_right"; # was l

    # delete + change non yanking, plus cut
    d = "delete_selection_noyank";
    D = "delete_selection";
    c = "change_selection_noyank";

    # increment (because tmux uses ctrl+a)
    "C-a" = "no_op";
    "C-b" = "increment";

    # noob keys
    home = "no_op";
    end = "no_op";
    pageup = "no_op";
    pagedown = "no_op";

    g = {
      e = "no_op"; # default: goto_last_line
      G = "goto_last_line";

      # staying on the homerow baby -> jklø
      h = "no_op"; # default: goto_line_start
      j = "goto_line_start";
      "ø" = "goto_line_end";
      k = "move_line_down";
      l = "move_line_up";
    };

    z = {
      # staying on the homerow baby -> jklø
      j = "no_op";
      k = "scroll_down";
      l = "scroll_up";

      # disable noob keys + old hjkl movements
      down = "no_op"; # default: scroll_down
      up = "no_op"; # default: scroll_up
      pagedown = "no_op"; # default: page_down
      pageup = "no_op"; # default: page_up
    };

    "C-w" = {
      # staying on the homerow baby -> jklø
      h = "no_op"; # default: jump_view_left
      j = "jump_view_left";
      k = "jump_view_down";
      l = "jump_view_up";
      "ø" = "jump_view_right";

      # staying on the homerow baby -> jklø (swap views)
      H = "no_op"; # default: swap_view_left
      J = "swap_view_left";
      K = "swap_view_down";
      L = "swap_view_up";
      "Ø" = "swap_view_right";

      # disable noob keys + old hjkl movements
      left = "no_op"; # default: jump_view_left
      down = "no_op"; # default: jump_view_down
      up = "no_op"; # default: jump_view_up
      right = "no_op"; # default: jump_view_right
      "C-h" = "no_op"; # default: jump_view_left
      "C-j" = "no_op"; # default: jump_view_down
      "C-k" = "no_op"; # default: jump_view_up
      "C-l" = "no_op"; # default: jump_view_right
    };
  };

  insert = {
    up = "no_op"; # default: move_line_up
    down = "no_op"; # default: move_line_down
    left = "no_op"; # default: move_char_left
    right = "no_op"; # default: move_char_right
    pageup = "no_op"; # default: page_up
    pagedown = "no_op"; # default: page_down
    home = "no_op"; # default: goto_line_start
    end = "no_op"; # default: goto_line_end_newline
  };
}
