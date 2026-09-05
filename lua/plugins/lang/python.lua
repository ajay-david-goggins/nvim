-- =============================================================================
-- lang/python.lua · DAP setup now lives in the mason-nvim-dap "python"
-- handler in plugins/mason.lua — that's the guaranteed-correct-timing
-- hook (fires exactly when mason-nvim-dap processes the debugpy source),
-- unlike a FileType/VeryLazy autocmd racing against mason-nvim-dap's own
-- eager load. Nothing left here.
-- =============================================================================
return {}
