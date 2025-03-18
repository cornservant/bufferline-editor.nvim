---@class bufferline-editor.editor
---@field buffer integer | nil
---@field window integer | nil

---@class bufferline-editor.buffers
---@field items fun(): integer[]
---@field count fun(): integer
---@field apply_changes fun(editor: bufferline-editor.editor)
---
---@class bufferline-editor.config
