{
  normal = {
    ################################
    # Normal mode – Movement
    ################################
    h = "no_op";        # default: move_char_left
    j = "no_op";        # default: move_visual_line_down
    k = "no_op";        # default: move_visual_line_up
    l = "no_op";        # default: move_char_right
    w = "no_op";        # default: move_next_word_start
    b = "no_op";        # default: move_prev_word_start
    e = "no_op";        # default: move_next_word_end
    W = "no_op";        # default: move_next_long_word_start
    B = "no_op";        # default: move_prev_long_word_start
    E = "no_op";        # default: move_next_long_word_end
    t = "no_op";        # default: find_till_char
    f = "no_op";        # default: find_next_char
    T = "no_op";        # default: till_prev_char
    F = "no_op";        # default: find_prev_char
    G = "no_op";        # default: goto_line
    "A-." = "no_op";    # default: repeat_last_motion
    home = "no_op";     # default: goto_line_start
    end = "no_op";      # default: goto_line_end
    "C-b" = "no_op";    # default: page_up
    pageup = "no_op";   # default: page_up
    "C-f" = "no_op";    # default: page_down
    pagedown = "no_op"; # default: page_down
    "C-u" = "no_op";    # default: page_cursor_half_up
    "C-d" = "no_op";    # default: page_cursor_half_down
    "C-i" = "no_op";    # default: jump_forward
    "C-o" = "no_op";    # default: jump_backward
    "C-s" = "no_op";    # default: save_selection

    ################################
    # Normal mode – Changes
    ################################
    r = "no_op";        # default: replace
    R = "no_op";        # default: replace_with_yanked
    "~" = "no_op";      # default: switch_case
    "`" = "no_op";      # default: switch_to_lowercase
    "A-`" = "no_op";    # default: switch_to_uppercase
    i = "no_op";        # default: insert_mode
    a = "no_op";        # default: append_mode
    I = "no_op";        # default: insert_at_line_start
    A = "no_op";        # default: insert_at_line_end
    o = "no_op";        # default: open_below
    O = "no_op";        # default: open_above
    "." = "no_op";      # default: repeat last insert (no explicit command)
    u = "no_op";        # default: undo
    U = "no_op";        # default: redo
    "A-u" = "no_op";    # default: earlier
    "A-U" = "no_op";    # default: later
    y = "no_op";        # default: yank
    p = "no_op";        # default: paste_after
    P = "no_op";        # default: paste_before
    "\"" = "no_op";     # default: select_register
    ">" = "no_op";      # default: indent
    "<" = "no_op";      # default: unindent
    "=" = "no_op";      # default: format_selections
    d = "no_op";        # default: delete_selection
    "A-d" = "no_op";    # default: delete_selection_noyank
    c = "no_op";        # default: change_selection
    "A-c" = "no_op";    # default: change_selection_noyank
    "C-a" = "no_op";    # default: increment
    "C-x" = "no_op";    # default: decrement
    Q = "no_op";        # default: record_macro
    q = "no_op";        # default: replay_macro

    ################################
    # Normal mode – Shell
    ################################
    "|" = "no_op";      # default: shell_pipe
    "A-|" = "no_op";    # default: shell_pipe_to
    "!" = "no_op";      # default: shell_insert_output
    "A-!" = "no_op";    # default: shell_append_output
    "$" = "no_op";      # default: shell_keep_pipe

    ################################
    # Normal mode – Selection manipulation
    ################################
    s = "no_op";          # default: select_regex
    S = "no_op";          # default: split_selection
    "A-s" = "no_op";      # default: split_selection_on_newline
    "A-minus" = "no_op";  # default: merge_selections
    "A-_" = "no_op";      # default: merge_consecutive_selections
    "&" = "no_op";        # default: align_selections
    "_" = "no_op";        # default: trim_selections
    ";" = "no_op";        # default: collapse_selection
    "A-;" = "no_op";      # default: flip_selections
    "A-:" = "no_op";      # default: ensure_selections_forward
    "," = "no_op";        # default: keep_primary_selection
    "A-," = "no_op";      # default: remove_primary_selection
    C = "no_op";          # default: copy_selection_on_next_line
    "A-C" = "no_op";      # default: copy_selection_on_prev_line
    "(" = "no_op";        # default: rotate_selections_backward
    ")" = "no_op";        # default: rotate_selections_forward
    "A-(" = "no_op";      # default: rotate_selection_contents_backward
    "A-)" = "no_op";      # default: rotate_selection_contents_forward
    "%" = "no_op";        # default: select_all
    x = "no_op";          # default: extend_line_below
    X = "no_op";          # default: extend_to_line_bounds
    "A-x" = "no_op";      # default: shrink_to_line_bounds
    J = "no_op";          # default: join_selections
    "A-J" = "no_op";      # default: join_selections_space
    K = "no_op";          # default: keep_selections
    "A-K" = "no_op";      # default: remove_selections
    "C-c" = "no_op";      # default: toggle_comments
    "A-o" = "no_op";      # default: expand_selection
    "A-up" = "no_op";     # default: expand_selection
    "A-i" = "no_op";      # default: shrink_selection
    "A-down" = "no_op";   # default: shrink_selection
    "A-p" = "no_op";      # default: select_prev_sibling
    "A-left" = "no_op";   # default: select_prev_sibling
    "A-n" = "no_op";      # default: select_next_sibling
    "A-right" = "no_op";  # default: select_next_sibling
    "A-a" = "no_op";      # default: select_all_siblings
    "A-I" = "no_op";      # default: select_all_children
    "A-S-down" = "no_op"; # default: select_all_children
    "A-e" = "no_op";      # default: move_parent_node_end
    "A-b" = "no_op";      # default: move_parent_node_start

    ################################
    # Normal mode – Search
    ################################
    "/" = "no_op";       # default: search
    "?" = "no_op";       # default: rsearch
    n = "no_op";         # default: search_next
    N = "no_op";         # default: search_prev
    "*" = "no_op";       # default: search_selection_detect_word_boundaries
    "A-*" = "no_op";     # default: search_selection

    ################################
    # Normal mode – Minor mode entry
    ################################
    v = "no_op";         # default: select_mode
    g = "no_op";         # default: goto mode (minor mode enter, N/A command)
    m = "no_op";         # default: match mode (minor mode enter, N/A command)
    ":" = "no_op";       # default: command_mode
    z = "no_op";         # default: view mode (minor mode enter, N/A command)
    Z = "no_op";         # default: sticky view mode (minor mode enter, N/A command)
    "C-w" = "no_op";     # default: window mode (minor mode enter, N/A command)
    space = "no_op";     # default: space mode (minor mode enter, N/A command)

    ################################
    # View mode – [keys.normal.z]
    ################################
    z = {
      z = "no_op";        # default: align_view_center
      c = "no_op";        # default: align_view_center
      t = "no_op";        # default: align_view_top
      b = "no_op";        # default: align_view_bottom
      m = "no_op";        # default: align_view_middle
      j = "no_op";        # default: scroll_down
      down = "no_op";     # default: scroll_down
      k = "no_op";        # default: scroll_up
      up = "no_op";       # default: scroll_up
      "C-f" = "no_op";    # default: page_down
      pagedown = "no_op"; # default: page_down
      "C-b" = "no_op";    # default: page_up
      pageup = "no_op";   # default: page_up
      "C-u" = "no_op";    # default: page_cursor_half_up
      "C-d" = "no_op";    # default: page_cursor_half_down
    };

    ################################
    # Goto mode – [keys.normal.g]
    ################################
    g = {
      g = "no_op";        # default: goto_file_start
      "|" = "no_op";      # default: goto_column
      e = "no_op";        # default: goto_last_line
      f = "no_op";        # default: goto_file
      h = "no_op";        # default: goto_line_start
      l = "no_op";        # default: goto_line_end
      s = "no_op";        # default: goto_first_nonwhitespace
      t = "no_op";        # default: goto_window_top
      c = "no_op";        # default: goto_window_center
      b = "no_op";        # default: goto_window_bottom
      d = "no_op";        # default: goto_definition
      y = "no_op";        # default: goto_type_definition
      r = "no_op";        # default: goto_reference
      i = "no_op";        # default: goto_implementation
      a = "no_op";        # default: goto_last_accessed_file
      m = "no_op";        # default: goto_last_modified_file
      n = "no_op";        # default: goto_next_buffer
      p = "no_op";        # default: goto_previous_buffer
      "." = "no_op";      # default: goto_last_modification
      j = "no_op";        # default: move_line_down
      k = "no_op";        # default: move_line_up
      w = "no_op";        # default: goto_word
    };

    ################################
    # Match mode – [keys.normal.m]
    ################################
    m = {
      m = "no_op";        # default: match_brackets
      s = "no_op";        # default: surround_add
      r = "no_op";        # default: surround_replace
      d = "no_op";        # default: surround_delete
      a = "no_op";        # default: select_textobject_around
      i = "no_op";        # default: select_textobject_inner
    };

    ################################
    # Window mode – [keys.normal."C-w"]
    ################################
    "C-w" = {
      w = "no_op";        # default: rotate_view
      "C-w" = "no_op";    # default: rotate_view
      v = "no_op";        # default: vsplit
      "C-v" = "no_op";    # default: vsplit
      s = "no_op";        # default: hsplit
      "C-s" = "no_op";    # default: hsplit
      f = "no_op";        # default: goto_file (horizontal)
      F = "no_op";        # default: goto_file (vertical)
      h = "no_op";        # default: jump_view_left
      "C-h" = "no_op";    # default: jump_view_left
      left = "no_op";     # default: jump_view_left
      j = "no_op";        # default: jump_view_down
      "C-j" = "no_op";    # default: jump_view_down
      down = "no_op";     # default: jump_view_down
      k = "no_op";        # default: jump_view_up
      "C-k" = "no_op";    # default: jump_view_up
      up = "no_op";       # default: jump_view_up
      l = "no_op";        # default: jump_view_right
      "C-l" = "no_op";    # default: jump_view_right
      right = "no_op";    # default: jump_view_right
      q = "no_op";        # default: wclose
      "C-q" = "no_op";    # default: wclose
      o = "no_op";        # default: wonly
      "C-o" = "no_op";    # default: wonly
      H = "no_op";        # default: swap_view_left
      J = "no_op";        # default: swap_view_down
      K = "no_op";        # default: swap_view_up
      L = "no_op";        # default: swap_view_right
    };

    ################################
    # Space mode – [keys.normal.space]
    ################################
    space = {
      f = "no_op";        # default: file_picker
      F = "no_op";        # default: file_picker_in_current_directory
      b = "no_op";        # default: buffer_picker
      j = "no_op";        # default: jumplist_picker
      g = "no_op";        # default: changed_file_picker
      G = "no_op";        # default: debug (experimental, N/A)
      k = "no_op";        # default: hover
      s = "no_op";        # default: symbol_picker
      S = "no_op";        # default: workspace_symbol_picker
      d = "no_op";        # default: diagnostics_picker
      D = "no_op";        # default: workspace_diagnostics_picker
      r = "no_op";        # default: rename_symbol
      a = "no_op";        # default: code_action
      h = "no_op";        # default: select_references_to_symbol_under_cursor
      "'" = "no_op";      # default: last_picker
      w = "no_op";        # default: window mode (enter window minor mode)
      c = "no_op";        # default: toggle_comments
      C = "no_op";        # default: toggle_block_comments
      "A-c" = "no_op";    # default: toggle_line_comments
      p = "no_op";        # default: paste_clipboard_after
      P = "no_op";        # default: paste_clipboard_before
      y = "no_op";        # default: yank_to_clipboard
      Y = "no_op";        # default: yank_main_selection_to_clipboard
      R = "no_op";        # default: replace_selections_with_clipboard
      "/" = "no_op";      # default: global_search
      "?" = "no_op";      # default: command_palette
    };

    ################################
    # Unimpaired – [keys.normal["]"]], [keys.normal["["]]
    ################################
    "]" = {
      d = "no_op";        # default: goto_next_diag
      D = "no_op";        # default: goto_last_diag
      f = "no_op";        # default: goto_next_function
      t = "no_op";        # default: goto_next_class
      a = "no_op";        # default: goto_next_parameter
      c = "no_op";        # default: goto_next_comment
      T = "no_op";        # default: goto_next_test
      p = "no_op";        # default: goto_next_paragraph
      g = "no_op";        # default: goto_next_change
      G = "no_op";        # default: goto_last_change
      space = "no_op";    # default: add_newline_below
    };

    "[" = {
      d = "no_op";        # default: goto_prev_diag
      D = "no_op";        # default: goto_first_diag
      f = "no_op";        # default: goto_prev_function
      t = "no_op";        # default: goto_prev_class
      a = "no_op";        # default: goto_prev_parameter
      c = "no_op";        # default: goto_prev_comment
      T = "no_op";        # default: goto_prev_test
      p = "no_op";        # default: goto_prev_paragraph
      g = "no_op";        # default: goto_prev_change
      G = "no_op";        # default: goto_first_change
      space = "no_op";    # default: add_newline_above
    };
  };

  insert = {
    ################################
    # Insert mode – core bindings
    ################################
    esc = "no_op";        # default: normal_mode
    "C-s" = "no_op";      # default: commit_undo_checkpoint
    "C-x" = "no_op";      # default: completion
    "C-r" = "no_op";      # default: insert_register
    "C-w" = "no_op";      # default: delete_word_backward
    "A-backspace" = "no_op"; # default: delete_word_backward
    "A-d" = "no_op";      # default: delete_word_forward
    "A-del" = "no_op";    # default: delete_word_forward
    "C-u" = "no_op";      # default: kill_to_line_start
    "C-k" = "no_op";      # default: kill_to_line_end
    "C-h" = "no_op";      # default: delete_char_backward
    backspace = "no_op";  # default: delete_char_backward
    "S-backspace" = "no_op"; # default: delete_char_backward
    "C-d" = "no_op";      # default: delete_char_forward
    del = "no_op";        # default: delete_char_forward
    "C-j" = "no_op";      # default: insert_newline
    ret = "no_op";        # default: insert_newline

    ################################
    # Insert mode – non-recommended navigation bindings
    ################################
    up = "no_op";         # default: move_line_up
    down = "no_op";       # default: move_line_down
    left = "no_op";       # default: move_char_left
    right = "no_op";      # default: move_char_right
    pageup = "no_op";     # default: page_up
    pagedown = "no_op";   # default: page_down
    home = "no_op";       # default: goto_line_start
    end = "no_op";        # default: goto_line_end_newline
  };

  # Note: Select / extend mode "echoes" normal mode with extend-variants of
  # movement/goto commands; Helix doesn't publish a separate full table of
  # those commands. If you *also* want to neuter select mode explicitly, you
  # can add a `select = { ... }` attrset here with your own `no_op` mappings.
}
