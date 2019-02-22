-- Pop open a callgrind_annotate instance, assuming its where we think it is
local args = {...}
local outf = assert(io.open(table.remove(args), 'w'))
assert(#args > 0, "Not enough arguments!")
print('Running: callgrind_annotate '..table.concat(args))
local cg = io.popen('../install/valgrind/bin/callgrind_annotate '
	..table.concat(args), 'r')

-- Skip over the header data first
-- Separater starts with '---'
local seps = 6
repeat
	local l = cg:read '*l'
	if l:sub(1,3) == '---' then seps = seps - 1 end
until seps == 0

-- Do we care about stuff from source file X?
local function dowecare(s)
	if s == '???' then return end
	if s:sub(1,1) == '/' then
		if s:match '^/projects' then
			return dowecare(s:match '/parallel%-elfutils/(.+)')
		else return end
	end
	if s:match '^install/boost' then return end
	return true
end

-- Now read in the lovely data
local data,skipped = {},{}
for l in cg:lines() do
	if #l == 0 then break end
	local cnt,src,sym = l:match '^%s*([%d,]+)%s+([^%s:]+):(.+)$'
	assert(cnt, "Invalid match on "..l)

	cnt = assert(tonumber(cnt:gsub(',',''), 10))
	assert(cnt > 0)

	local obj
	if sym:sub(-1) == ']' then
		sym,obj = sym:match '^(.+)%s+%[(.-)%]$'
	end

	if dowecare(src) then
		if obj then
			data[obj] = data[obj] or {}
			data[obj][sym] = true
		else
			skipped[sym] = true
		end
	end
end
assert(cg:close())

-- Pre-process the skipped symbol list
do
	local ord = {}
	for s in pairs(skipped) do ord[#ord+1] = s end
	table.sort(ord)
	if #ord > 0 then
		outf:write('Skipped '..#ord..' symbols that had no binary attached.\n')
	end
	skipped = ord
end	

-- Gather the real list of symbols for each object file
local allsyms = {}
for obj in pairs(data) do
	local p = io.popen('nm -pC '..obj, 'r')
	local ss = {}
	for l in p:lines '*l' do
		local ty,sym = l:match '^%x*%s+(%a)%s+(.+)$'
		if not ty then
			error('Failed nm match: '..l)
		end
		if ty == 't' or ty == 'T' then ss[sym] = true end
	end
	assert(p:close())
	allsyms[obj] = ss
end

-- Compare the two, and gather the final coverage data
local objs = {}
for obj in pairs(data) do
	local o = {}
	local all,seen = allsyms[obj], data[obj]
	o.call,o.cseen,o.cmissing = 0,0,0
	o.uncovered,o.extra = {},{}

	for s in pairs(all) do
		o.call = o.call + 1
		if seen[s] then o.cseen = o.cseen + 1
		else table.insert(o.uncovered, s) end
	end
	for s in pairs(seen) do
		if not all[s] then
			o.cmissing = o.cmissing + 1
			table.insert(o.extra, s)
		end
	end
	table.sort(o.uncovered)
	table.sort(o.extra)

	o.name = obj:match '/([^/]-%.?s?o?)[%.%d]*$'
	assert(not objs[o.name], "Duplicate reduced object name "..o.name)
	objs[o.name] = o
end
allsyms,data = nil,nil	-- Let Lua GC

-- Stabilize the output, sort the pieces by the binary names
local oorder = {}
for n,o in pairs(objs) do table.insert(oorder, n) end
table.sort(oorder)
for i,n in ipairs(oorder) do oorder[i] = objs[n] end
objs = oorder	-- Let Lua GC again, kind of.

-- Pretty-print the heading with the general stats
outf:write '\n'
do
	local namelen, missedlen = 0,0
	for _,o in ipairs(objs) do
		namelen = math.max(namelen, #o.name)
		missedlen = math.max(missedlen, math.ceil(math.log10(o.call-o.cseen)))
	end
	missedlen = missedlen + 1
	local fmt = "%"..namelen.."s:% 5.1f%%, missed % "..missedlen.."d, extraneous %d\n"
	for _,o in ipairs(objs) do
		outf:write(fmt:format(o.name,o.cseen/o.call*100,o.call-o.cseen,o.cmissing))
	end
end

-- Print a stanza with the "extraneous" symbols, header-scope
if #skipped > 0 then
	outf:write '\n'
	outf:write('Skipped '..#skipped..' symbols that nm did not report:\n')
	for _,s in ipairs(skipped) do outf:write('  ',s,'\n') end
end

-- Print a stanza for each object file, showing the problems and such
for _,o in ipairs(objs) do
	outf:write '\n'
	outf:write('Missed '..#o.uncovered..' symbols in '..o.name..':\n')
	for _,s in ipairs(o.uncovered) do outf:write('  ',s,'\n') end
	outf:write('Could not find '..#o.extra..' symbols from '..o.name..':\n')
	for _,s in ipairs(o.extra) do outf:write('  ',s,'\n') end
end

outf:close()
