local M = {};

---@param line string
---@return integer | nil
function M.get_buf_by_line(line)
    local buf = nil
    local buf_str = string.match(line, "^ *%d+")
    if buf_str ~= nil then
        buf = 0 + buf_str
    else
        -- fallback strategy
        buf = vim.fn.bufnr(line)
        if buf == -1 then return nil end
    end

    return buf
end

return M;
