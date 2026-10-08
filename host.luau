--!strict
-- The `diff` lens: unified diff from `jj diff --git` / `jj show --git` as
-- summary badges and one collapsible diff per file.

local ui = tern.ui

local MAX_FILES = 200 -- files shown before the rest fold into "… N more"
local MAX_FILE_LINES = 2000 -- lines kept per file
local OPEN_FILES = 8 -- files after this many start collapsed
local OPEN_LINES = 300 -- files longer than this start collapsed
local HEADER_LINES = 12 -- `jj show` description lines kept above the files

type File = {
	path: string,
	from: string?,
	kind: string,
	adds: number,
	dels: number,
	binary: boolean,
	hunk: boolean, -- inside a hunk, so +/- lines count
	body: boolean, -- past the metadata, so lines are kept
	total: number,
	lines: { string },
}
type State = {
	head: { string },
	files: { File },
	cur: File?,
}

local KINDS: { [string]: { sym: string, style: string } } = {
	added = { sym = "A", style = "success" },
	deleted = { sym = "D", style = "error" },
	renamed = { sym = "R", style = "info" },
	modified = { sym = "M", style = "warning" },
}

local function starts(s: string, prefix: string): boolean
	return string.sub(s, 1, #prefix) == prefix
end

local function badges(state: State): { Node }
	local adds, dels = 0, 0
	for _, f in state.files do
		adds += f.adds
		dels += f.dels
	end
	local n = #state.files
	return {
		ui.badge(n .. (if n == 1 then " file" else " files"), "muted"),
		ui.badge("+" .. adds, "success"),
		ui.badge("−" .. dels, "error"),
	}
end

local function file_section(f: File, collapsed: boolean): Node
	local kind = KINDS[f.kind]
	local head: { Span | string } = { ui.span(kind.sym .. " ", kind.style .. " strong"), ui.span(f.path, "mono") }
	if f.from then
		table.insert(head, ui.span("  from " .. f.from, "muted"))
	end
	table.insert(head, ui.span("  +" .. f.adds, "success"))
	table.insert(head, ui.span(" −" .. f.dels, "error"))

	local body: { Node } = {}
	if f.binary then
		table.insert(body, ui.text({ ui.span("Binary file", "muted") }))
	elseif #f.lines > 0 then
		table.insert(body, ui.diff(table.concat(f.lines, "\n"), f.path))
		if f.total > #f.lines then
			table.insert(body, ui.overflow(f.total - #f.lines))
		end
	end

	local node = ui.section(head, body)
	local p: { [string]: any } = node.p or {}
	p.key = "file:" .. f.path
	p.collapsible = true
	p.collapsed = collapsed
	node.p = p
	return node
end

local function view(state: State): Node?
	if #state.files == 0 then
		return nil -- not a diff we can read: raw output
	end
	local children: { Node } = {}
	if #state.head > 0 then
		local lines: { Node } = {}
		for _, l in state.head do
			table.insert(lines, ui.text({ ui.span(l, "muted") }))
		end
		table.insert(children, ui.lines(lines))
	end
	table.insert(children, ui.row(badges(state)))
	for i, f in state.files do
		if i > MAX_FILES then
			table.insert(children, ui.overflow(#state.files - MAX_FILES))
			break
		end
		table.insert(children, file_section(f, i > OPEN_FILES or f.total > OPEN_LINES))
	end
	return ui.col(children)
end

tern.lens.define("diff", {
	open = function(_run: LensRun, _cx: EffectCx): State
		return { head = {}, files = {}, cur = nil }
	end,

	line = function(state: State, l: LensLine)
		local text = l.text

		local a, b = string.match(text, "^diff %-%-git a/(.-) b/(.+)$")
		if a and b then
			local f: File = {
				path = b,
				from = if a ~= b then a else nil,
				kind = "modified",
				adds = 0,
				dels = 0,
				binary = false,
				hunk = false,
				body = false,
				total = 0,
				lines = {},
			}
			table.insert(state.files, f)
			state.cur = f
			return
		end

		local f = state.cur
		if not f then
			-- `jj show` prints the commit header before the first file.
			if #state.head < HEADER_LINES and text ~= "" then
				table.insert(state.head, text)
			end
			return
		end

		if starts(text, "new file mode") then
			f.kind = "added"
		elseif starts(text, "deleted file mode") then
			f.kind = "deleted"
		elseif starts(text, "rename from ") then
			f.kind = "renamed"
		elseif starts(text, "Binary files") or starts(text, "GIT binary patch") then
			f.binary = true
		end

		if starts(text, "@@") then
			f.hunk = true
			f.body = true
		elseif starts(text, "--- ") and not f.hunk then
			f.body = true
		elseif f.hunk then
			local c = string.sub(text, 1, 1)
			if c == "+" then
				f.adds += 1
			elseif c == "-" then
				f.dels += 1
			end
		end

		if f.body then
			f.total += 1
			if #f.lines < MAX_FILE_LINES then
				table.insert(f.lines, text)
			end
		end
	end,

	finish = function(_state: State, _status: number?) end,

	view = view,
})
