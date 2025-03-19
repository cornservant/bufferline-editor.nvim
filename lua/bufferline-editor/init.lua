local M = {}

---@type bufferline-editor.buffers
local buffers = require("bufferline-editor.bufferline_adapter")

---@type bufferline-editor.config
M.config = {
    max_width = 120,
    max_height = 30,
}

---@type bufferline-editor.editor
M.editor = {
    buffer = nil,
    window = nil,
}

function M.setup(config)
    if type(config) == "table" then
        M.config = vim.tbl_deep_extend("force", M.config, config)
    end
end

---@output vim.api.keyset.win_config
local function window_config()
    local screen_width = vim.o.columns
    local screen_height = vim.o.lines
    local width = math.min(screen_width, M.config.max_width)
    local height = math.min(screen_height - 3, M.config.max_height)
    return {
        relative = "editor",
        border = "rounded",
        title = " Buffers ",
        title_pos = "center",
        row = (screen_height - height) / 2,
        col = (screen_width - width) / 2,
        width = width,
        height = height,
    }
end

---@param buf integer
local function short_buf_name(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return nil end

    local bufname = vim.api.nvim_buf_get_name(buf)

    if bufname == "" then
        return nil
    end

    local cwd = vim.loop.cwd()
    if cwd == nil then return nil end

    if vim.startswith(bufname, cwd) then
        return string.sub(bufname, #cwd + 2)
    else
        return bufname
    end
end

---@output boolean
function M.is_closed()
    M.validate()
    return M.editor.window == nil
end

function M.validate()
    if M.editor.window ~= nil and not vim.api.nvim_win_is_valid(M.editor.window) then
        M.editor.window = nil
    end

    if M.editor.buffer ~= nil and not vim.api.nvim_buf_is_valid(M.editor.buffer) then
        M.editor.buffer = nil
    end
end

function M.select_item()
    M.validate()
    if M.editor.buffer == nil then return end

    local filename = vim.api.nvim_get_current_line()
    local selected_buf = vim.fn.bufnr(filename)
    M.editor_close()
    if selected_buf ~= -1 and vim.api.nvim_buf_is_valid(selected_buf) then
        vim.api.nvim_set_current_buf(selected_buf)
    end
end


function M.editor_open()
    M.validate()
    if not M.is_closed() then return end

    local current_buffer = vim.api.nvim_get_current_buf()

    if M.editor.buffer == nil then
        M.editor.buffer = vim.api.nvim_create_buf(false, true)
        if M.editor.buffer == 0 then
            M.editor.buffer = nil
            vim.notify("bufferline-editor: could not create a buffer", vim.log.levels.ERROR)
            return
        end
    end

    local cfg = window_config()
    M.editor.window = vim.api.nvim_open_win(M.editor.buffer, true, cfg)

    if M.editor.window == 0 then
        vim.api.nvim_buf_delete(M.editor.buffer, { force = true })
        M.editor.window = nil
        vim.notify("bufferline-editor: could not create a window", vim.log.levels.ERROR)
        return
    end


    vim.keymap.set("n", "q", M.editor_close, { silent = true, buffer = M.editor.buffer })
    vim.keymap.set("n", "<esc>", M.editor_close, { silent = true, buffer = M.editor.buffer })
    vim.keymap.set("n", "<cr>", M.select_item, { silent = true, buffer = M.editor.buffer })

    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = M.editor.buffer,
        callback = function()
            buffers.apply_changes(M.editor)
        end,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = M.editor.buffer,
        callback = M.editor_close,
    })
    vim.api.nvim_create_autocmd("BufModifiedSet", {
        buffer = M.editor.buffer,
        callback = function()
            vim.o.modified = false
        end,
    })
    vim.api.nvim_create_autocmd("VimResized", {
        buffer = M.editor.buffer,
        callback = function()
            if M.editor.window ~= nil then
                vim.api.nvim_win_set_config(M.editor.window, window_config())
            end
        end,
    })

    M.render_ui(current_buffer)
end

function M.editor_close()
    M.validate()

    if M.editor.window ~= nil then
        vim.api.nvim_win_close(M.editor.window, true)
        M.editor.window = nil
    end

    if M.editor.buffer ~= nil then
        if vim.api.nvim_buf_is_valid(M.editor.buffer) then
            if vim.api.nvim_buf_get_changedtick(M.editor.buffer) > 0 then
                buffers.apply_changes(M.editor)
            end
            vim.api.nvim_buf_delete(M.editor.buffer, { force = true })
        end

        M.editor.buffer = nil
    end
end

function M.editor_toggle()
    M.validate()
    if M.is_closed() then
        M.editor_open()
    else
        M.editor_close()
    end
end

---@param current_buffer integer
---@output integer | nil
local function current_buffer_index(current_buffer)
    for index, buf in ipairs(buffers.items()) do
        if buf == current_buffer then
            return index
        end
    end
    return nil
end

---@param current_buffer? integer
function M.render_ui(current_buffer)
    local contents = {}

    for index, buf in ipairs(buffers.items()) do
        contents[index] = short_buf_name(buf) or ""
    end

    if M.editor.window == nil or M.editor.buffer == nil then
        return
    end

    vim.api.nvim_set_option_value("number", true, { win = M.editor.window })
    vim.api.nvim_buf_set_name(M.editor.buffer, "buffer_manager-menu")
    vim.api.nvim_buf_set_lines(M.editor.buffer, 0, #contents, false, contents)
    vim.api.nvim_buf_set_option(M.editor.buffer, "filetype", "buffer_manager")
    vim.api.nvim_buf_set_option(M.editor.buffer, "buftype", "acwrite")
    vim.api.nvim_buf_set_option(M.editor.buffer, "bufhidden", "delete")
    if current_buffer ~= nil then
        local buffer_idx = current_buffer_index(current_buffer)
        if buffer_idx ~= nil then
            vim.api.nvim_win_set_cursor(M.editor.window, {buffer_idx, 0})
        end
    end

    do -- NOTE: remove empty buffer from the undo history
        local undolevels = vim.api.nvim_get_option_value("undolevels", { buf = M.editor.buffer })
        vim.api.nvim_set_option_value("undolevels", -1, { buf = M.editor.buffer })
        vim.api.nvim_buf_set_lines(M.editor.buffer, 0, #contents, false, contents)
        vim.api.nvim_set_option_value("undolevels", undolevels, { buf = M.editor.buffer })
    end
end

return M
