open Owl

module N = Dense.Ndarray.S
module G = Neural.S.Graph
module A = G.Neuron.Activation

type model_summary =
  { input_dim : int
  ; hidden_dim : int
  ; output_dim : int
  ; parameter_count : int
  }

let parameter_count_for_dense ~input_dim ~output_dim =
  (input_dim * output_dim) + output_dim

let make_demo_model_summary () =
  let input_dim = 4 in
  let hidden_dim = 8 in
  let output_dim = 3 in
  let _model =
    G.input [| input_dim |]
    |> G.fully_connected hidden_dim ~act_typ:A.Relu
    |> G.fully_connected output_dim ~act_typ:(A.Softmax 1)
  in
  let parameter_count =
    parameter_count_for_dense ~input_dim ~output_dim:hidden_dim
    + parameter_count_for_dense ~input_dim:hidden_dim ~output_dim
  in
  { input_dim; hidden_dim; output_dim; parameter_count }

let demo_prediction () =
  let x = N.of_array [| 0.25; 0.5; 0.75; 1.0 |] [| 1; 4 |] in
  let averaged = N.sum' x /. 4.0 in
  [ averaged /. 2.0; averaged; 1.0 -. (averaged /. 2.0) ]
