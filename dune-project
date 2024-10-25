(lang dune 3.17)

(name pagetalk)

(source
 (github tmattio/pagetalk))

(authors "Thibaut Mattio <thibaut.mattio@gmail.com>")

(maintainers "Thibaut Mattio <thibaut.mattio@gmail.com>")

(license ISC)

(package
 (name pagetalk)
 (synopsis
  "Lightweight, self-hosted commenting system for static websites and blogs")
 (description
  "PageTalk is a lightweight, self-hosted commenting system for static websites and blogs. It provides a simple JavaScript client that can be embedded in any webpage and a moderation dashboard for managing comments.")
 (depends ocaml dune dream))

(dialect
 (name eml)
 (implementation
  (extension eml)
  (preprocess
   (run %{bin:dream_eml} %{input-file} --workspace %{workspace_root}
    --stdout))))
