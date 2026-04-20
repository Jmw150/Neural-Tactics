# rocq-owl-tactics

`rocq-owl-tactics` is a Rocq plugin written in OCaml that uses Owl to choose
between a small set of proof tactics.

The project is still intentionally compact and instructional, but it is no
longer just a linkage scaffold. It now contains a concrete end-to-end tactic
selection loop:

- a Rocq plugin written in OCaml
- Owl linked into that plugin
- a small neural policy model built on the Owl side
- Rocq-side feature extraction from the current goal and context
- tactic ranking and execution inside Rocq

## What Is Implemented

The plugin currently provides three Ltac tactics:

```coq
From RocqOwlTactics Require Import OwlTactics.

Goal True.
  owl_model_info.
  owl_trace.
  owl_auto.
Qed.
```

1. `owl_model_info` prints a summary of the Owl-backed policy model.
2. `owl_trace` scores a few candidate proof actions and prints the ranking.
3. `owl_auto` uses the same ranking to try tactics in predicted order.

The current action library inside `owl_auto` is intentionally small:

- `assumption`
- `reflexivity`
- `exact I`
- `intro`

The decision step is a tiny multilayer perceptron policy written on the Owl
side. It takes a hand-engineered feature vector for the current goal:

- number of hypotheses
- number of hypotheses whose type matches the goal exactly
- whether the goal is `True`
- whether the goal is an equality
- whether the goal is a product / `forall`

and returns a probability distribution over the action set above.

This keeps the example small enough to read, while still making the project a
real demonstration of one deep-learning-style decider between several tactics
instead of only a hard-coded ranking formula.

## Current Behavior

The current learned policy is intentionally modest. It does not attempt general
proof search. Instead, it focuses on a very small action space that is easy to
inspect:

- `assumption`
- `reflexivity`
- `exact I`
- `intro`

That is enough to show the whole path:

1. inspect a Rocq goal
2. featurize the proof state
3. score candidate actions with Owl
4. rank tactics by model output
5. try them inside Rocq

## Layout

- `src/owl_bridge.ml`: Owl-side helpers, including the tiny MLP tactic policy
- `src/owl_tactic_core.ml`: plugin-side goal analysis, action ranking, and tactic execution
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

## Why This Project Exists

The main purpose of this repository is to make the Rocq/OCaml/Owl integration
story concrete in the smallest possible useful example.

It is a good fit for:

- experimenting with learned tactic selection
- prototyping proof-state feature extraction
- growing a tactic library around a model-based ranking step
- teaching how a proof assistant plugin can call into numerical code

## Next Steps For Real Tactics

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
  to prove out a neural tactic-selection path, not to compete with `auto`.
