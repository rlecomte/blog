open Yocaml

let destination = "_build/bundle/"
let css_destination = into destination "public/css"

let track_binary_update = Build.watch Sys.argv.(0)

let article_destination file =
  let fname = basename file |> into "public/articles" in
  replace_extension fname "html"
;;

let articles =
  process_files [ "articles/" ] (with_extension "md") (fun file ->
    let open Build in
    let target = article_destination file |> into destination in
    create_file
      target
      (track_binary_update
      >>> Yocaml_yaml.read_file_with_metadata (module Metadata.Article) file
      >>> Yocaml_markdown.content_to_html ()
      >>> Yocaml_mustache.apply_as_template
            (module Metadata.Article)
            "templates/article.html"
      >>> Yocaml_mustache.apply_as_template
            (module Metadata.Article)
            "templates/layout.html"
      >>^ Stdlib.snd))
;;

let index =
  let open Build in
  let* articles =
    collection
      (read_child_files "articles/" (with_extension "md"))
      (fun source ->
        track_binary_update
        >>> Yocaml_yaml.read_file_with_metadata
              (module Metadata.Article)
              source
        >>^ fun (x, _) -> x, article_destination source)
      (fun x (meta, content) ->
        x
        |> Metadata.Articles.make
             ?title:(Metadata.Page.title meta)
             ?description:(Metadata.Page.description meta)
        |> Metadata.Articles.sort_articles_by_date
        |> fun x -> x, content)
  in
  create_file
    (into destination "index.html")
    (track_binary_update
    >>> Yocaml_yaml.read_file_with_metadata (module Metadata.Page) "index.md"
    >>> Yocaml_markdown.content_to_html ()
    >>> articles
    >>> Yocaml_mustache.apply_as_template
          (module Metadata.Articles)
          "templates/list.html"
    >>> Yocaml_mustache.apply_as_template
          (module Metadata.Articles)
          "templates/layout.html"
    >>^ Stdlib.snd)
;;

let css =
  process_files [ "css/" ] (with_extension "css") (fun file ->
    Build.copy_file file ~into:css_destination)
;;

let program = css >> articles >> index
