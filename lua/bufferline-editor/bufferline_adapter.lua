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
            local buf = vim.fn.bufnr(line)
            if buf == -1 then return nil end
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
        if vim.api.nvim_buf_is_valid(buf) then
            if vim.api.nvim_buf_get_option(buf, "modified") then
                local name = vim.api.nvim_buf_get_name(buf)
                vim.notify("Cannot close buffer " .. buf .. " (" .. name .. ") due to unsaved changes", vim.log.levels.WARN)
            else
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
