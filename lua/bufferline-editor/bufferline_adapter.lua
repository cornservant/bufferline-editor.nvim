local state = require("bufferline.state")

---@output integer[]
local function items()
    return vim.tbl_map(function(component)
        return component.id
    end, state.components)
end

---@output integer
local function count()
    return #state.components
end

---@param editor bufferline-editor.editor
local function apply_changes(editor)
    if editor.buffer == nil then return end

    local lines = vim.api.nvim_buf_get_lines(editor.buffer, 0, -1, true)
    local old_components = state.components
    local new_components = vim.tbl_filter(function(cmp) return cmp ~= nil end,
        vim.tbl_map(function(line)
            local buf_str = string.match(line, "^ *%d+")
            if buf_str == nil then return nil end
            local buf = 0 + buf_str
            for i, cmp in pairs(old_components) do
                if cmp.id == buf then
                    table.remove(old_components, i)
                    return cmp
                end
            end
            return nil
        end, lines))

    for _, cmp in pairs(old_components) do
        local buf = cmp.id
        local name = vim.api.nvim_buf_get_name(buf)
        if vim.api.nvim_buf_is_valid(buf) then
            local modified = vim.api.nvim_get_option_value("modified", { buf = buf })
            if modified then
                vim.notify("Cannot close buffer " .. buf .. " (" .. name .. ") due to unsaved changes", vim.log.levels.WARN)
            else
                -- BUG: cannot doesn't delete buffer from floating window
                -- https://github.com/neovim/neovim/issues/20315
                vim.api.nvim_buf_delete(buf, {})
            end
        end
    end

    local custom_sort = vim.tbl_map(function(cmp) return cmp.id end, new_components)

    state.custom_sort = custom_sort
end

---@type bufferline-editor.buffers
local M = {
    items = items,
    count = count,
    apply_changes = apply_changes,
}

return M
