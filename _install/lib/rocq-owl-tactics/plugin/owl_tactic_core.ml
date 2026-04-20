open Pp
open Proofview
open Proofview.Notations

type candidate_action =
  | TryAssumption
  | TryReflexivity
  | TryExactTrue
  | TryIntro

type scored_action =
  { action : candidate_action
  ; score : float
  }

let format_float_list xs =
  String.concat ", " (List.map (Printf.sprintf "%.4f") xs)

let action_name = function
  | TryAssumption -> "assumption"
  | TryReflexivity -> "reflexivity"
  | TryExactTrue -> "exact I"
  | TryIntro -> "intro"

let owl_model_message () =
  let summary = Owl_bridge.make_demo_model_summary () in
  let prediction = Owl_bridge.demo_prediction () in
  Printf.sprintf
    "Owl demo model ready: input=%d hidden=%d output=%d params=%d sample=[%s]"
    summary.input_dim
    summary.hidden_dim
    summary.output_dim
    summary.parameter_count
    (format_float_list prediction)

let show_owl_model_info () =
  Feedback.msg_notice (str (owl_model_message ()))

let owl_model_info_tactic =
  tclUNIT () >>= fun () ->
  let () = show_owl_model_info () in
  tclUNIT ()

let hypothesis_count env =
  Environ.ids_of_named_context_val (Environ.named_context_val env)
  |> Names.Id.Set.cardinal

let goal_is_true env sigma concl =
  EConstr.is_lib_ref env sigma "core.True.type" concl

let goal_is_equality env sigma concl =
  match EConstr.kind sigma concl with
  | Constr.App (head, _args) -> EConstr.is_lib_ref env sigma "core.eq.type" head
  | _ -> false

let goal_is_product sigma concl =
  match EConstr.kind sigma concl with
  | Constr.Prod _ -> true
  | _ -> false

let matching_hypothesis_count sigma env concl =
  let rec loop ctx count =
    match Environ.match_named_context_val ctx with
    | None -> count
    | Some (decl, rest) ->
      let count =
        match decl with
        | Context.Named.Declaration.LocalAssum (_, ty) ->
          if EConstr.eq_constr sigma (EConstr.of_constr ty) concl then count + 1 else count
        | Context.Named.Declaration.LocalDef (_, _, ty) ->
          if EConstr.eq_constr sigma (EConstr.of_constr ty) concl then count + 1 else count
      in
      loop rest count
  in
  loop (Environ.named_context_val env) 0

let score_actions ~hyp_count ~matches_goal ~is_true ~is_equality ~is_product =
  let open Owl in
  let x =
    Mat.of_arrays
      [|
        [|
          float_of_int hyp_count;
          float_of_int matches_goal;
          if is_true then 1.0 else 0.0;
          if is_equality then 1.0 else 0.0;
          if is_product then 1.0 else 0.0;
        |];
      |]
  in
  let w =
    Mat.of_arrays
      [|
        [| 0.35; 0.00; 0.00; 0.00 |];
        [| 1.80; 0.20; 0.10; -0.20 |];
        [| 0.00; 0.00; 2.20; -0.40 |];
        [| 0.10; 2.40; -0.30; -0.20 |];
        [| -0.10; -0.20; -0.20; 2.50 |];
      |]
  in
  let b = Mat.of_arrays [| [| 0.10; 0.05; 0.05; 0.05 |] |] in
  let scores = Mat.(softmax (dot x w + b)) in
  let score i = Mat.get scores 0 i in
  [ { action = TryAssumption; score = score 0 }
  ; { action = TryReflexivity; score = score 1 }
  ; { action = TryExactTrue; score = score 2 }
  ; { action = TryIntro; score = score 3 }
  ]

let ranked_actions env sigma concl =
  let scored =
    score_actions
      ~hyp_count:(hypothesis_count env)
      ~matches_goal:(matching_hypothesis_count sigma env concl)
      ~is_true:(goal_is_true env sigma concl)
      ~is_equality:(goal_is_equality env sigma concl)
      ~is_product:(goal_is_product sigma concl)
  in
  List.sort (fun a b -> Float.compare b.score a.score) scored

let scored_actions_message actions =
  let pieces =
    List.map
      (fun item -> Printf.sprintf "%s=%.3f" (action_name item.action) item.score)
      actions
  in
  "owl action scores: " ^ String.concat ", " pieces

let tactic_for_action = function
  | TryAssumption -> Tactics.assumption
  | TryReflexivity -> Tactics.reflexivity
  | TryExactTrue ->
    Tacticals.pf_constr_of_global (Rocqlib.lib_ref "core.True.I")
    >>= fun c -> Tactics.exact_no_check c
  | TryIntro -> Tactics.intro

let rec first_success = function
  | [] -> Tacticals.tclZEROMSG (str "owl_auto could not solve the goal with its current action set.")
  | item :: rest ->
    Tacticals.tclORELSE0 (tactic_for_action item.action) (first_success rest)

let owl_trace_tactic =
  Goal.enter begin fun gl ->
    let env = Goal.env gl in
    let sigma = Goal.sigma gl in
    let concl = Goal.concl gl in
    let actions = ranked_actions env sigma concl in
    Feedback.msg_notice (str (scored_actions_message actions));
    tclUNIT ()
  end

let owl_auto_tactic =
  Goal.enter begin fun gl ->
    let env = Goal.env gl in
    let sigma = Goal.sigma gl in
    let concl = Goal.concl gl in
    let actions = ranked_actions env sigma concl in
    Feedback.msg_notice (str (scored_actions_message actions));
    first_success actions
  end
