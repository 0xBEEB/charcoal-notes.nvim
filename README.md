# charcoal-notes.nvim
by Briar Schreiber <briarrose@mailbox.org>

A neovim plugin for taking notes that is inspired by Obsidian Notes.

This plugin provides a seamless Neovim interface for a simple bash script backend that handles note creation, linking, and indexing. It's designed for those who are comfortable in the terminal and want a lightweight, extensible, and plain-text-based system for their notes. This plugin adds features like linking, backlinks, tags, and fzf searches without the need for a full GUI app.

## Philosophy
* Unix Philosophy: The backend is a simple Bash script that leverages core utilities like find, grep, and awk
* Plain Text: Your notes are just Markdown files in a directory
* Low Friction: Adding notes is quick and easy and integrates into a vim like workflow

## Requirements
* Neovim
* Bash
* Core utilities: `find`, `grep`, `sed`, `awk`
* fzf: (Optional) If you want to launch the script interactively outside of Neovim
* ripgrep (rg): (Optional) For faster note search
* ibhagwan/fzf-lua: Required Neovim plugin for the UI

## Installation
Install using your favorite plugin manager. Here is an example using Lazy.

```lua
return {
  "0xBEEB/charcoal-notes.nvim",
  dependencies = { "ibhagwan/fzf-lua" },
  ft = { "markdown" },
  cmd = {
    "CharcoalEdit",
    "CharcoalBacklnks",
    "CharcoalLinks",
    "CharcoalTags",
    "CharcoalIndex",
    "CharcoalInsertLink",
    "CharcoalGotoLink",
  },
  config = function(_, opts)
    require("charcoal-notes").setup(opts)

    -- Key Mappings
    vim.keymap.set("n", "<leader>nb", "<cmd>CharcoalBacklinks<cr>", { silent = true, desc = "Notes: Show Backlinks" })
    vim.keymap.set("n", "<leader>nl", "<cmd>CharcoalLinks<cr>", { silent = true, desc = "Notes: Show Outgoing Links" })
    vim.keymap.set("n", "<leader>ni", "<cmd>CharcoalIndex<cr>", { silent = true, desc = "Notes: Re-index Repository" })
    vim.keymap.set("n", "<leader>nn", "<cmd>CharcoalEdit<cr>", { silent = true, desc = "Notes: Edit Note" })
    vim.keymap.set("n", "<leader>nt", "<cmd>CharcoalTags<cr>", { silent = true, desc = "Notes: Search Tags" })
    vim.keymap.set("n", "<leader>nk", "<cmd>CharcoalInsertLink<cr>", { silent = true, desc = "Notes: Insert Link" })
    vim.keymap.set("n", "gf", "<cmd>CharcoalGotoLink<cr>", { silent = true, desc = "Goto File (wikilink aware)" })
    vim.keymap.set("i", "<C-l>", "<cmd>CharcoalInsertLink<cr>", { silent = true, desc = "Notes: Insert Link" })
  end
}
```

## Usage

### Commands
The plugin exposes several Ex-commands for you to use and map:

| Command | Description |
| ------- | ------- |
| :CharcoalEdit | Interactively find a note with fzf. If no match is found, it creates a new note with the entered name. |
| :CharcoalBacklinks | Show all backlinks for the current note in an fzf window. |
| :CharcoalLinks | Show all outgoing links from the current note in an fzf window. |
| :CharcoalTags | Show a list of all tags. Selecting a tag will show all notes with that tag. |
| :CharcoalInsertLink | Interactively select a note to insert as a `[[wikilink]]` at the cursor position. Works in Normal and Insert modes. |
| :CharcoalIndex | Manualy trigger a full re-index of the entire note repository. |

## Local script
Adding the bash script to your path will allow you to work with your notes outside of Neovim as well. This will allow you to quickly create new repositories from the command line, launch straight into a fuzzy finder launcher for your notes from anywhere, and pipe the note command output to any tool you would like. For example, git hooks could be added to index your note repo.

## Note Management
* **Create a repository:** by creating a `.charcoal` directory in the root of the repository. Then put an empty file called `index` in that `.charcoal` directory.
* **Add the script to your path:** You can also create a repository by running the `charcoal-notes init` at the location of the new repository, if you have added the script to your path.
* **Set a default repository:** You can set the environment variable `NOTES_DIR` to use a default notes repository no matter where you are in the filesystem. However, if you have a local notes dir that you are within, then it will use that.
* **Folders:** You can organize notes in folders simply by using `/` in the note name. eg. `MyDir/MyNote`.
* **Automatic Indexing:** The plugin automatically re-indexes notes when you save them or delete them from within Neovim, so backlinks and tags are always up-to-date. For file operations outside of Neovim you may need to run `:CharcoalIndex` manually.
