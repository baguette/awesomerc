local shell = {}

local awful = require "awful"


function shell.wrap(f)
    return function(...)
        local arg = {...}
        local cmdln = table.concat(arg, " ")

        return f(cmdln)
    end
end


shell.exec = shell.wrap(awful.spawn.with_shell)
shell.read = awful.spawn.easy_async_with_shell

-- Run a command only if it's not already running by the current user
function shell.exec_once(cmd, needle)
    local findme = needle or cmd
    local firstspace = findme:find(" ")
    if firstspace then
        findme = cmd:sub(0, firstspace-1)
    end

    local USER = os.getenv "USER"
    local pgrep = table.concat({"pgrep","-u",USER,"-a","-f",findme}, " ")

    return shell.read(pgrep, function(out, err, res, rc)
        if res == "exit" and rc ~= 0 then
            return shell.exec("exec",cmd)
        end
    end)
end


shell.promise = {}

local function make_promiser(f)
    return function(...)
        local n = select('#', ...)
        local args = {...}
        return function()
            return f(unpack(args, 1, n))
        end
    end
end

shell.promise._prototype = {
    __index = function(t, k)
        if not shell[k] then
            return nil
        end

        local promiser = make_promiser(shell[k])
        t[k] = promiser

        return promiser
    end
}
setmetatable(shell.promise, shell.promise._prototype)


return shell
