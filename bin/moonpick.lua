local moonpick = require"moonpick"

local function validate_usage(args)
  bail = function()
    print "Usage: moonpick <file>, [file2, ..]"
    os.exit(1)
  end

  if #args == 0 then bail() end

  for _, a in ipairs(args) do
    if a:match('^%-') then
      bail()
    end
  end
end

local args = arg
validate_usage(args)

local errors = 0

for i = 1, #args do
  file = args[i]
  local inspections, err = moonpick.lint_file(file)
  if not inspections then
    errors = errors + 1
    print(file .. '\n')
    print(err)
  else
    if #inspections > 0 then
      print(file .. '\n')
      errors = errors + #inspections
      print(moonpick.format_inspections(inspections))
    end
  end
end

os.exit(errors > 0 and 1 or 0)
