Declare ML Module "rocq-owl-tactics.plugin".

(**
  This file is intentionally small.

  It acts as the Rocq-facing entry point for the OCaml plugin.  The plugin
  currently proves integration by printing Owl-backed model information when the
  plugin loads, which lets us check that Rocq can call into Owl-backed OCaml
  code successfully.
*)
