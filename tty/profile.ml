let rec string_contains ~sub_str = function
  | "" -> sub_str = "" (* the empty string contains itself *)
  | s ->
      String.starts_with ~prefix:sub_str s
      || string_contains ~sub_str (String.sub s 1 (String.length s - 1))

type t = No_color | ANSI | ANSI256 | True_color

let from_env () =
  let term = Sys.getenv_opt "TERM" in
  let color_term = Sys.getenv_opt "COLORTERM" in
  let term_program = Sys.getenv_opt "TERM_PROGRAM" in

  let is_screen =
    match term with
    | Some term -> String.starts_with ~prefix:"screen" term
    | None -> false
  in

  let is_tmux = match term_program with Some "tmux" -> true | _ -> false in

  let is_term sub_str =
    term |> Option.map (string_contains ~sub_str) |> Option.value ~default:false
  in
  let is_256color = is_term "256color" in
  let is_color = is_term "color" in
  let is_ansi = is_term "ansi" in

  match (term, color_term) with
  | _, Some "true" -> ANSI256
  | _, Some "truecolor" when is_screen && not is_tmux -> ANSI256
  | _, Some "truecolor" -> True_color
  | Some ("xterm-kitty" | "wezterm"), _ -> True_color
  | Some "linux", _ -> ANSI
  | Some _, _ when is_256color -> ANSI256
  | Some _, _ when is_color || is_ansi -> ANSI
  | _ -> No_color

let default = from_env ()

let convert profile color =
  match (color, profile) with
  | _, No_color -> Color.no_color
  | Color.No_color, _ -> Color.no_color
  | Color.ANSI _, _ -> color
  | Color.ANSI256 _, ANSI -> color
  | Color.ANSI256 _, _ -> color
  | Color.RGB _, ANSI -> color
  | Color.RGB _, ANSI256 -> color
  | Color.RGB _, True_color -> color
