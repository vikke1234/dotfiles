-- nvim-jdtls setup. This file runs automatically for every Java buffer.

-- Skip non-file buffers (e.g., Telescope preview buffers, netrw, etc.).
-- Otherwise jdtls starts against a preview buffer instead of the real file.
if vim.bo.buftype ~= "" then
	return
end
local filepath = vim.fn.expand("%:p")
if filepath == "" or vim.fn.filereadable(filepath) == 0 then
	return
end

local ok, jdtls = pcall(require, "jdtls")
if not ok then
	vim.notify("jdtls plugin not loaded yet", vim.log.levels.WARN)
	return
end

-- Locate the jdtls installation provided by Mason.
local mason_pkg = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
local launcher = vim.fn.glob(mason_pkg .. "/plugins/org.eclipse.equinox.launcher_*.jar")
if launcher == "" then
	vim.notify("jdtls launcher not found. Run :MasonInstall jdtls", vim.log.levels.WARN)
	return
end

-- Pick the right platform config directory.
local config_dir = mason_pkg .. "/config_linux"

-- Lombok agent (bundled with the Mason jdtls package). Required for jdtls to
-- understand Lombok-generated members (getters/setters/builders, etc.).
local lombok_jar = mason_pkg .. "/lombok.jar"

-- A unique workspace per project so jdtls keeps separate caches.
local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }
local root_dir = require("jdtls.setup").find_root(root_markers) or vim.fn.getcwd()
local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

-- Use the same completion capabilities as the rest of your LSP setup.
local capabilities = require("blink.cmp").get_lsp_capabilities()

-- Use Java 21 to run jdtls itself (system Java 25 is too new and breaks it).
-- The Gradle toolchain setting in build.gradle controls what JDK your project
-- compiles against — this only controls the jdtls server JVM.
local java_21 = "/usr/lib/jvm/java-21-temurin-jdk/bin/java"

local config = {
	cmd = {
		java_21,
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xmx1g",
		"-javaagent:" .. lombok_jar,
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",
		"-jar",
		launcher,
		"-configuration",
		config_dir,
		"-data",
		workspace_dir,
	},
	root_dir = root_dir,
	capabilities = capabilities,
	settings = {
		java = {
			format = {
				settings = {
					-- Eclipse formatter profile (keeps manual line wrapping, etc.)
					url = vim.uri_from_fname(vim.fn.stdpath("config") .. "/eclipse-java-formatter.xml"),
					profile = "nvim",
				},
			},
		},
	},
	init_options = {
		bundles = {},
	},
}

jdtls.start_or_attach(config)

-- :JdtRestart — fully stop the jdtls server and start it again, so changes to
-- this file or the formatter profile are actually reloaded. Reopening a buffer
-- only re-attaches to the existing (stale) server; it does not reload config.
vim.api.nvim_buf_create_user_command(0, "JdtRestart", function()
	for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
		client.stop(true)
	end
	-- Give the process a moment to exit before starting a fresh one.
	vim.defer_fn(function()
		vim.cmd("edit")
	end, 500)
end, { desc = "Restart the jdtls language server" })
