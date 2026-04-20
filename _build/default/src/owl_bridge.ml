open Owl

module Mat = Dense.Matrix.D
module N = Dense.Ndarray.S
module G = Neural.S.Graph
module A = G.Neuron.Activation

type model_summary =
  { input_dim : int
  ; hidden_dim : int
  ; output_dim : int
  ; parameter_count : int
  ; action_labels : string list
  }

type tactic_features =
  { hypothesis_count : int
  ; matching_hypothesis_count : int
  ; goal_is_true : bool
  ; goal_is_equality : bool
  ; goal_is_product : bool
  }

let action_labels = [ "assumption"; "reflexivity"; "exact I"; "intro" ]

let input_dim = 5
let hidden_dim = 8
let output_dim = 4

let parameter_count_for_dense ~input_dim ~output_dim =
  (input_dim * output_dim) + output_dim

let make_demo_model_summary () =
  let _model =
    G.input [| input_dim |]
    |> G.fully_connected hidden_dim ~act_typ:A.Relu
    |> G.fully_connected output_dim ~act_typ:(A.Softmax 1)
  in
  let parameter_count =
    parameter_count_for_dense ~input_dim ~output_dim:hidden_dim
    + parameter_count_for_dense ~input_dim:hidden_dim ~output_dim
  in
  { input_dim; hidden_dim; output_dim; parameter_count; action_labels }

let relu m = Mat.map (fun x -> if x > 0.0 then x else 0.0) m

let softmax_row m =
  let cols = Mat.col_num m in
  let max_score = ref (Mat.get m 0 0) in
  for j = 1 to cols - 1 do
    let v = Mat.get m 0 j in
    if v > !max_score then max_score := v
  done;
  let exps = Array.init cols (fun j -> exp (Mat.get m 0 j -. !max_score)) in
  let total = Array.fold_left ( +. ) 0.0 exps in
  Mat.of_arrays [| Array.map (fun x -> x /. total) exps |]

let features_to_row features =
  Mat.of_arrays
    [|
      [|
        float_of_int features.hypothesis_count;
        float_of_int features.matching_hypothesis_count;
        if features.goal_is_true then 1.0 else 0.0;
        if features.goal_is_equality then 1.0 else 0.0;
        if features.goal_is_product then 1.0 else 0.0;
      |];
    |]

let w1 =
  Mat.of_arrays
    [|
      [| 0.40; 0.25; -0.10; 0.10; 0.15; 0.20; -0.20; 0.05 |];
      [| 2.20; -0.25; -0.20; 0.10; -0.30; 0.15; -0.20; -0.10 |];
      [| -0.30; -0.10; 2.60; -0.20; -0.15; 0.10; 0.15; -0.20 |];
      [| -0.20; 2.50; -0.10; 0.15; -0.20; -0.15; 0.10; -0.15 |];
      [| 0.10; -0.15; -0.20; 2.40; 0.20; -0.20; 0.10; 0.10 |];
    |]

let b1 =
  Mat.of_arrays
    [| [| 0.05; 0.10; 0.05; 0.05; 0.00; 0.00; 0.00; 0.00 |] |]

let w2 =
  Mat.of_arrays
    [|
      [| 1.80; -1.00; -1.20; -0.80 |];
      [| -0.80; 2.40; -1.20; -0.60 |];
      [| -0.90; -0.70; 2.80; -0.90 |];
      [| -0.80; -0.60; -0.70; 2.60 |];
      [| 0.15; 0.10; 0.10; 0.05 |];
      [| 0.20; 0.10; 0.10; 0.10 |];
      [| 0.05; 0.10; 0.05; 0.10 |];
      [| 0.05; 0.05; 0.05; 0.05 |];
    |]

let b2 =
  Mat.of_arrays [| [| 0.10; 0.05; 0.05; 0.05 |] |]

let predict_action_scores features =
  let x = features_to_row features in
  let hidden = relu Mat.(dot x w1 + b1) in
  let logits = Mat.(dot hidden w2 + b2) in
  let probabilities = softmax_row logits in
  List.mapi (fun i label -> (label, Mat.get probabilities 0 i)) action_labels

let demo_prediction () =
  predict_action_scores
    { hypothesis_count = 2
    ; matching_hypothesis_count = 1
    ; goal_is_true = false
    ; goal_is_equality = false
    ; goal_is_product = false
    }

let format_prediction prediction =
  String.concat
    ", "
    (List.map (fun (label, score) -> Printf.sprintf "%s=%.4f" label score) prediction)

let predicted_best_action features =
  match predict_action_scores features with
  | [] -> failwith "empty action set"
  | first :: rest ->
    List.fold_left
      (fun best candidate ->
        if snd candidate > snd best then candidate else best)
      first
      rest
