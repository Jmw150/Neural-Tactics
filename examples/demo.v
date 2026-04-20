From RocqOwlTactics Require Import OwlTactics.

Goal True.
  owl_model_info.
  owl_trace.
  owl_auto.
Qed.

Goal forall P : Prop, P -> P.
  owl_trace.
  owl_auto.
  owl_auto.
  owl_auto.
Qed.

Goal 2 = 2.
  owl_trace.
  owl_auto.
Qed.
