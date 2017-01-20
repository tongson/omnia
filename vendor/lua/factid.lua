-- Module for gathering system "facts"
-- @module factid
local string = string
local util = require"cimicida"
local sysstat = require"posix.sys.stat"
local dirent = require"posix.dirent"
local lib = require"lib"
local cmd = lib.cmd
local factid = require"factidC"
local qhttp = require"qhttp"
local return_false = { __index = function() return false end }
local ipairs, pairs, tonumber, next, setmetatable = ipairs, pairs, tonumber, next, setmetatable
local ENV = {}
_ENV = ENV

--- Deduce the distro ID from /etc/os-release or /etc/*release.
-- @return the id as a string (STRING)
function factid.osfamily ()
    local id
    if sysstat.stat("/etc/os-release") then
        id = util.match_from_file("/etc/os-release", [[^ID_LIKE=[%p]*(%w+)[%p]*]])
            or util.match_from_file("/etc/os-release", [[^ID=[%p]*(%w+)[%p]*]])
    elseif sysstat.stat("/etc/openwrt_release") then
        id = "openwrt"
    else
        id = "unknown"
    end
    return id
end

--- Deduce the distro NAME from /etc/os-release or /etc/*release.
-- @return the name as a string (STRING)
function factid.operatingsystem ()
    local name
    if sysstat.stat("/etc/os-release") then
        name = util.match_from_file("/etc/os-release", [[^NAME[%s]*=[%s%p]*([%w]+)]])
    elseif sysstat.stat("/etc/openwrt_release") then
        name = "OpenWRT"
    else
        name = "unknown"
    end
    return name
end

--- Gather ...
-- Requires Linux sysfs support.
-- @return partitions as a partition name and size pair (TABLE)
function factid.partitions ()
    local partitions = {}
    local sysfs = sysstat.stat("/sys/block")
    if not sysfs or sysstat.S_ISDIR(sysfs.st_mode) == 0 then
        return nil, "factid.partitions: No sysfs support detected."
    end
    for partition in dirent.files("/sys/block/") do
        if not string.find(partition, "^%.") then
            local size = tonumber(util.fopen("/sys/block/" .. partition .. "/size" ))
            partitions[partition] = size*512
        end
    end
    if not next(partitions) then
        return nil, "factid.partitions: posix.dirent failed."
    end
    return partitions
end

function factid.interfaces ()
    local ifs = {}
    for _, y in ipairs(factid.ifaddrs()) do
        if y.ipv4 then
            ifs[y.interface] = {}
            ifs[y.interface]["ipv4"] = y.ipv4
        elseif y.ipv6 then
            ifs[y.interface]["ipv6"] = y.ipv6
        end
    end
    return ifs
end

function factid.aws_instance_id ()
    local ok, err = qhttp.get("169.254.169.254", "/latest/meta-data/instance-id")
    ok = lib.ln_to_tbl(ok)
    if ok then
        return ok[#ok]
    else
        return nil, err
    end
end

-- WORK IN PROGRESS
function factid.gather ()
    local fact = {}
    fact.version = "0.1.0"

    do
        local hostname = factid.hostname()
        fact.hostname = setmetatable({}, return_false)
        fact.hostname.string = hostname
        fact.hostname[hostname] = true
    end

    do
        local uniqueid = factid.hostid()
        fact.uniqueid = setmetatable({}, return_false)
        fact.uniqueid.string = uniqueid
        fact.uniqueid[uniqueid] = true
    end

    do
        local timezone = factid.timezone()
        fact.timezone = setmetatable({}, return_false)
        fact.timezone.string = timezone
        fact.timezone[timezone] = true
    end

    do
        local procs = factid.sysconf().procs
        procs = tonumber(procs)
        fact.physicalprocessorcount = setmetatable({}, return_false)
        fact.physicalprocessorcount.number = procs
        fact.physicalprocessorcount[procs] = true
    end

    do
        local osfamily = factid.osfamily()
        fact.osfamily = setmetatable({}, return_false)
        fact.osfamily.string = osfamily
        fact.osfamily[osfamily] = true
    end

    do
        local operatingsystem = factid.operatingsystem()
        fact.operatingsystem = setmetatable({}, return_false)
        fact.operatingsystem.string = operatingsystem
        fact.operatingsystem[operatingsystem] = true
    end

    do
        local uname = factid.uname()
        local kernel = uname.sysname
        fact.kernel = setmetatable({}, return_false)
        fact.kernel.string = kernel
        fact.kernel[kernel] = true
        local architecture = uname.machine
        fact.architecture = setmetatable({}, return_false)
        fact.architecture.string = architecture
        fact.architecture[architecture] = true
        -- kernel version information are strings
        local v1, v2, v3 = string.match(uname.release, "(%d+).(%d+).(%d+)")
        kernelmajversion = string.format("%d.%d", v1, v2)
        fact.kernelmajversion = setmetatable({}, return_false)
        fact.kernelmajversion.string = kernelmajversion
        fact.kernelmajversion[kernelmajversion] = true
        kernelrelease = uname.release
        fact.kernelrelease = setmetatable({}, return_false)
        fact.kernelrelease.string = kernelrelease
        fact.kernelrelease[kernelrelease] = true
        kernelversion = string.format("%d.%d.%d", v1, v2, v3)
        fact.kernelversion = setmetatable({}, return_false)
        fact.kernelversion.string = kernelversion
        fact.kernelversion[kernelversion] = true
    end

    do
        -- uptime table values are integers
        -- fields: days, hours, totalseconds, totalminutes
        local uptime = factid.uptime()
        fact.uptime = {}
        fact.uptime.days = setmetatable({}, return_false)
        fact.uptime.days.number = uptime.days
        fact.uptime.days[uptime.days] = true
        fact.uptime.hours = setmetatable({}, return_false)
        fact.uptime.hours.number = uptime.hours
        fact.uptime.hours[uptime.hours] = true
        fact.uptime.totalseconds = setmetatable({}, return_false)
        fact.uptime.totalseconds.number = uptime.totalseconds
        fact.uptime.totalseconds[uptime.totalseconds] = true
        fact.uptime.totalminutes = setmetatable({}, return_false)
        fact.uptime.totalminutes.number = uptime.totalminutes
        fact.uptime.totalminutes[uptime.totalminutes] = true
    end

    do
        -- string, number table
        -- { sda = 500000 }
        local partitions = factid.partitions()
        if partitions then
            fact.partitions = {}
            fact.partitions.table = partitions
            for p, s in pairs(partitions) do
                fact.partitions[p] = setmetatable({}, return_false)
                fact.partitions[p][s] = true
            end
        end
    end

    do
        -- string, string table
        -- fields: ipv4, ipv6 default outgoing
        local ipaddress = factid.ipaddress()
        fact.ipaddress = {}
        fact.ipaddress.table = ipaddress
        for p, i in pairs(ipaddress) do
            fact.ipaddress[p] = setmetatable({}, return_false)
            fact.ipaddress[p][i] = true
        end
    end

    do
        -- string, number table
        -- fields: mem_unit, freehigh, freeswap, totalswap, bufferram, sharedram, freeram, totalram
        local memory = factid.mem()
        fact.memory = {}
        fact.memory.table = memory
        for k, v in pairs(memory) do
            fact.memory[k] = setmetatable({}, return_false)
            fact.memory[k][v] = true
        end
    end

    do
        -- { eth0 = {ipv4=, ipv6=} }
        local interfaces = factid.interfaces()
        fact.interfaces = {}
        fact.interfaces.table = interfaces
        for interface, prototbl in pairs(interfaces) do
            fact.interfaces[interface] = {}
            for proto, ip in pairs(prototbl) do
                fact.interfaces[interface][proto] = setmetatable({}, return_false)
                fact.interfaces[interface][proto][ip] = true
            end
        end
    end

    do
        local id = factid.aws_instance_id() or factid.hostname()
        fact.aws_instance_id = setmetatable({}, return_false)
        fact.aws_instance_id.string = id
        fact.aws_instance_id[id] = true
    end

    -- { dir, type, freq, opts, passno, fsname }
    -- fact.mounts = factid.mount()
    return fact
end

return factid
