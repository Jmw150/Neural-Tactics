let plugin_name = "rocq-owl-tactics.plugin"

let () =
  Mltop.add_known_module plugin_name

let () =
  Ltac_plugin.Tacentries.ml_tactic_extend
    ~plugin:plugin_name
    ~name:"owl_model_info"
    ~local:false
    Ltac_plugin.Tacentries.MLTyNil
    Owl_tactic_core.owl_model_info_tactic

let () =
  Ltac_plugin.Tacentries.ml_tactic_extend
    ~plugin:plugin_name
    ~name:"owl_trace"
    ~local:false
    Ltac_plugin.Tacentries.MLTyNil
    Owl_tactic_core.owl_trace_tactic

let () =
  Ltac_plugin.Tacentries.ml_tactic_extend
    ~plugin:plugin_name
    ~name:"owl_auto"
    ~local:false
    Ltac_plugin.Tacentries.MLTyNil
    Owl_tactic_core.owl_auto_tactic
