let () =
  let header = Logs_fmt.pp_header in
  let () = Logs.set_reporter Logs_fmt.(reporter ~pp_header:header ()) in
  let () = Logs.set_level (Some Logs.Debug) in
  Yocaml_unix.execute Blog.program
