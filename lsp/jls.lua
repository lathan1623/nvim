local function setup_diagnostics(client, bufnr)
	-- JLS diagnostics are compile-based. Replace Neovim's request-on-every-change
	-- behavior with the same debounced schedule used by nvim-jls.
	client.server_capabilities.diagnosticProvider = nil

	local group = vim.api.nvim_create_augroup("JlsDiagnostics_" .. bufnr, { clear = true })
	local namespace = vim.lsp.diagnostic.get_namespace(client.id)
	local timer = vim.uv.new_timer()

	local function request_diagnostics()
		client:request("textDocument/diagnostic", {
			textDocument = vim.lsp.util.make_text_document_params(bufnr),
		}, function(err, result)
			if err or not result or result.kind ~= "full" then
				return
			end

			local diagnostics = {}
			for _, diagnostic in ipairs(result.items or {}) do
				table.insert(diagnostics, {
					lnum = diagnostic.range.start.line,
					end_lnum = diagnostic.range["end"].line,
					col = diagnostic.range.start.character,
					end_col = diagnostic.range["end"].character,
					severity = diagnostic.severity,
					message = diagnostic.message,
					source = diagnostic.source,
					code = diagnostic.code,
				})
			end

			vim.diagnostic.set(namespace, bufnr, diagnostics)
		end, bufnr)
	end

	vim.api.nvim_create_autocmd("TextChanged", {
		group = group,
		buffer = bufnr,
		callback = function()
			timer:stop()
			timer:start(500, 0, vim.schedule_wrap(request_diagnostics))
		end,
	})

	vim.api.nvim_create_autocmd({ "InsertLeave", "BufWritePost" }, {
		group = group,
		buffer = bufnr,
		callback = request_diagnostics,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		buffer = bufnr,
		callback = request_diagnostics,
	})

	request_diagnostics()

	vim.api.nvim_create_autocmd("LspDetach", {
		group = group,
		buffer = bufnr,
		once = true,
		callback = function(event)
			if event.data.client_id == client.id then
				if not timer:is_closing() then
					timer:stop()
					timer:close()
				end
				pcall(vim.api.nvim_del_augroup_by_id, group)
			end
		end,
	})
end

return {
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/jls" },
	filetypes = { "java" },
	root_markers = {
		"pom.xml",
		"build.gradle",
		"build.gradle.kts",
		"settings.gradle",
		"settings.gradle.kts",
		"WORKSPACE",
		"WORKSPACE.bazel",
		".git",
	},
	on_attach = setup_diagnostics,
}
