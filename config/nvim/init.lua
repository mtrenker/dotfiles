if vim.fn.has("nvim-0.12") == 0 then
  error("This configuration requires Neovim 0.12 or newer")
end

require("config.options")

local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazy_commit = "85c7ff3711b730b4030d03144f6db6375044ae82" -- v11.17.5
if not vim.uv.fs_stat(lazy_path) then
  -- Public plugin downloads should not require the user's GitHub SSH identity.
  -- Explicit :443 avoids the shared Git HTTPS-to-SSH rewrite.
  local output = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=v11.17.5", "--single-branch",
    "https://github.com:443/folke/lazy.nvim.git", lazy_path,
  })
  if vim.v.shell_error ~= 0 then
    error("lazy.nvim clone failed: " .. output)
  end
  output = vim.fn.system({ "git", "-C", lazy_path, "checkout", "--detach", lazy_commit })
  if vim.v.shell_error ~= 0 then
    error("lazy.nvim checkout failed: " .. output)
  end
end
vim.opt.rtp:prepend(lazy_path)

require("lazy").setup("plugins", {
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  git = { url_format = "https://github.com:443/%s.git" },
  checker = { enabled = false },
  change_detection = { notify = false },
})
