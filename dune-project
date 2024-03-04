(lang dune 3.14)

(name blog)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name")

(maintainers "Maintainer Name")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name blog)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends
   ocaml
   dune
   yocaml
   yocaml_unix
   yocaml_yaml
   yocaml_jingoo
   yocaml_syndication
   yocaml_markdown
   yocaml_mustache)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
