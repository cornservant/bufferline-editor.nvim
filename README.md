bufferline-editor.nvim
======================

Buffer editor for [akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim).

- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)


## Requirements

- [akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim).

## Installation

```lua
-- lazy.nvim
{ 'exit91/bufferline-editor.nvim', dependencies = 'akinsho/bufferline.nvim' }
```

## Configuration

```lua
---@type bufferline-editor.config
opts = {
    max_width = 120,
    max_height = 30,
}
```
