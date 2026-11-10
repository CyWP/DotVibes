-- LSP: nvim-lspconfig. Servers resolve from PATH — install tools however you
-- like (pip install --user, cargo, chocolatey, your dotfiles...). Missing
-- tool = that LSP just doesn't start, no errors.
return {
  "neovim/nvim-lspconfig",
  dependencies = { "saghen/blink.cmp" },
  config = function()
    vim.lsp.enable({ "ruff", "basedpyright", "clangd" })

    -- How/where diagnostics (the highlighted code bits) and their messages show
    vim.diagnostic.config({
      underline = true, -- squiggly underline on the code
      virtual_text = { -- message shown after the line
        spacing = 4, -- gap between code and message
        prefix = "●",
      },
      signs = true, -- gutter icon with severity color
      severity_sort = true,
      update_in_insert = false, -- don't flash diagnostics while typing
    })

    -- Point the python tooling at an arbitrary interpreter/env, live.
    -- Usage:  :PythonEnv            -> fuzzy-pick an interpreter
    --         :PythonEnv 3dml       -> env by name (micromamba/conda)
    --         :PythonEnv /path/bin/python  -> explicit path
    --         :PythonEnv .venv      -> relative to current project root
    -- For a persistent per-project choice, commit a `pyrightconfig.json`:
    --   { "pythonPath": "/absolute/path/to/env/bin/python" }
    local function find_python(dir)
      if not dir or dir == "" then
        return nil
      end
      dir = vim.fs.normalize(dir)
      local fs = vim.uv.fs_stat
      local info = fs(dir)
      if not info then
        return nil
      end
      if info.type == "file" then
        return dir -- explicit path to an interpreter
      end
      for _, name in ipairs({ "python", "python3" }) do
        if fs(vim.fs.joinpath(dir, "bin", name)) then
          return vim.fs.joinpath(dir, "bin", name)
        end
      end
      return nil
    end

    local function python_candidates()
      local cands = {}
      -- mamba/conda env roots (micromamba, conda, mamba)
      local roots = { vim.env.MAMBA_ROOT_PREFIX, "~/.micromamba", "~/miniforge3", "~/miniconda3", "~/anaconda3" }
      for _, root in ipairs(roots) do
        root = root and vim.fs.normalize(root .. "/envs") or nil
        if root then
          local d = vim.fs.dir(root)
          local names = {}
          if type(d) == "table" then -- 0.13+ table form
            for _, e in ipairs(d) do
              names[#names + 1] = (type(e) == "table" and e.name or e)
            end
          else -- older iterator form
            for name in d do
              names[#names + 1] = name
            end
          end
          for _, env in ipairs(names) do
            cands[#cands + 1] = find_python(vim.fs.joinpath(root, env))
          end
        end
      end
      -- project-local virtualenv
      local cwd = vim.uv.cwd()
      cands[#cands + 1] = find_python(vim.fs.joinpath(cwd, ".venv"))
      cands[#cands + 1] = "/usr/bin/python3"
      return vim.tbl_filter(function(p) return p ~= nil end, cands)
    end

    local function env_name(path)
      -- ~/.micromamba/envs/3dml/bin/python -> "3dml"
      local name = vim.fs.basename(vim.fs.dirname(vim.fs.dirname(path)))
      return (name == "bin" or name == "usr") and "" or name
    end

    local function set_python_path(path)
      -- write through to the config store as well: basedpyright queries the
      -- client's live `workspace/configuration` (section "python") for this
      -- value, and future attaches (restarts, new buffers) should inherit it
      -- too. Attached clients additionally get a didChangeConfiguration push.
      vim.lsp.config("basedpyright", {
        settings = { python = { pythonPath = path } },
      })
      for _, client in ipairs(vim.lsp.get_clients({ name = "basedpyright", buffer = 0 })) do
        local settings = client.settings or client.config.settings or {}
        settings.python = vim.tbl_deep_extend("force", settings.python or {}, { pythonPath = path })
        client.settings = settings
        client:notify("workspace/didChangeConfiguration", { settings = client.settings })
      end
      vim.notify(
        ("basedpyright pythonPath set (session-wide, until nvim restarts): %s"):format(path),
        vim.log.levels.INFO
      )
    end

    vim.api.nvim_create_user_command("PythonEnv", function(opts)
      local arg = opts.args
      if arg ~= "" then
        local path = find_python(arg) or find_python(vim.fs.normalize(arg))
        if not path then
          -- treat the arg as an env *name*, e.g. `:PythonEnv 3dml`
          for _, p in ipairs(python_candidates()) do
            if env_name(p) == arg then
              path = p
              break
            end
          end
        end
        if not path and vim.fn.executable(arg) == 1 then
          path = arg
        end
        if not path then
          vim.notify(("No python found at %q"):format(arg), vim.log.levels.ERROR)
          return
        end
        vim.notify("Python interpreter: " .. path)
        set_python_path(path)
      else
        vim.ui.select(python_candidates(), {
          prompt = "Python interpreter",
          format_item = function(p)
            local home = (p:gsub("/bin/python[0-9.]*$", ""))
            return ("%s → %s"):format(vim.fs.basename(home), p)
          end,
        }, function(choice)
          if choice then
            vim.notify("Python interpreter: " .. choice)
            set_python_path(choice)
          end
        end)
      end
    end, {
      desc = "Point basedpyright at an arbitrary python interpreter/env",
      nargs = "?",
      complete = function(arg)
        local cands = python_candidates()
        if arg ~= "" then
          cands = vim.tbl_filter(function(p)
            return p:find(arg, 1, true) ~= nil
          end, cands)
        end
        return cands
      end,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      desc = "LSP actions",
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
          return
        end
        -- Ruff is a linter/formatter: keep hover for basedpyright only
        if client.name == "ruff" and client.server_capabilities then
          client.server_capabilities.hoverProvider = false
        end

        local map = vim.keymap.set
        map("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })
        map("n", "gD", vim.lsp.buf.declaration, { buffer = args.buf, desc = "Go to declaration" })
        map("n", "gI", vim.lsp.buf.implementation, { buffer = args.buf, desc = "Go to implementation" })
        map("n", "gl", vim.diagnostic.open_float, { buffer = args.buf, desc = "Line diagnostics" })
        map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { buffer = args.buf, desc = "Next diagnostic" })
        map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { buffer = args.buf, desc = "Prev diagnostic" })
      end,
    })
  end,
}
