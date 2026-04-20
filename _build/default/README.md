# rocq-owl-tactics

A small scaffold for experimenting with Rocq tactics backed by OCaml and the
Owl numerical/deep-learning ecosystem.

This project is intentionally a starting point rather than a finished tactic
suite. The goal is to give you a clean folder where all the moving parts are in
place:

- a Rocq plugin written in OCaml
- Owl linked into that plugin
- a Rocq theory file that loads the plugin
- a tiny Owl-backed smoke path that proves the integration works end to end

## What is implemented

The plugin currently provides three Ltac tactics:

```coq
From RocqOwlTactics Require Import OwlTactics.

Goal True.
  owl_model_info.
  owl_trace.
  owl_auto.
Qed.
```

1. `owl_model_info` prints a small Owl-backed neural model summary.
2. `owl_trace` scores a few candidate proof actions with Owl and prints the ranking.
3. `owl_auto` uses the same scores to try a small library of tactics in ranked order.

The current action library inside `owl_auto` is intentionally small:

- `assumption`
- `reflexivity`
- `exact I`
- `intro`

The decision step is now a tiny multilayer perceptron policy written on the Owl
side. It takes a hand-engineered feature vector for the current goal:

- number of hypotheses
- number of hypotheses whose type matches the goal exactly
- whether the goal is `True`
- whether the goal is an equality
- whether the goal is a product / `forall`

and returns a probability distribution over the action set above.

That keeps the example small, but it means the project now genuinely contains
one deep-learning-style decider between several tactics rather than only a
hard-coded ranking formula.

## Layout

- `src/owl_bridge.ml`: Owl-side helpers, including a tiny MLP tactic policy
- `src/owl_tactic_core.ml`: plugin-side OCaml tactic logic and goal feature extraction
- `src/g_owl_tactics.ml`: plugin entry point and Ltac registration
- `theories/OwlTactics.v`: the Rocq file that declares/loads the plugin
- `examples/demo.v`: a minimal example script
- `bin/owl_smoke.ml`: a tiny command-line smoke test for the Owl side

## Build

```sh
make
```

## Test

```sh
make test
```

You can also run the OCaml-side smoke test directly with:

```sh
dune exec ./bin/owl_smoke.exe
```

## Next steps for real tactics

The easiest next step is to keep Owl isolated behind `Owl_bridge` and grow the
action library in `owl_tactic_core.ml`:

1. Inspect the current goal and context from Rocq.
2. Extract a numerical feature representation.
3. Call an Owl model to score candidate actions.
4. Convert the selected action back into a Rocq tactic or proof search step.

Once that shape is stable, `g_owl_tactics.ml` is the right place to register
additional Ltac tactics or custom notation.

## Notes

- This scaffold targets the toolchain already installed in your current `opam`
  switch: Rocq 9.0.0, OCaml 4.14.1, and Owl 1.2.
- The current tactics are deliberately small and instructional. They are meant
  to prove out the Rocq/Owl integration path, not to compete with `auto`.
