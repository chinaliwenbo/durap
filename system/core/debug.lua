-- Copyright (C) 2013 MaMa

local strhelper = require "helper.string"

local setmetatable = setmetatable
local error = error
local concat = table.concat
local getinfo = debug.getinfo
local io_open = io.open
local unpack = unpack
local time = ngx.localtime
local type = type

local ngx_log = ngx.log
local ngx_err = ngx.ERR


module(...)

DEBUG = 1
INFO = 2
NOTICE = 3
WARN = 4
ERR = 5

local level_str = {
    'DEBUG',
    'INFO',
    'NOTICE',
    'WARN',
    'ERR'
}

local mt = { __index = _M }

function init(self, log_level, request, apppath)
    return setmetatable({
        request = request,
        log_level = log_level,
        log_file = apppath .. "logs/error.log"
    }, mt)
end

local function _log(self, log)
    local file = self.log_file

    local fp, err = io_open(file, "a")
    if not fp then
        ngx_log(ngx_err, "failed to open file: ", file, "; error: ", err)
        return
    end

    local ok, err = fp:write(log, "\n")
    if not ok then
        ngx_log(ngx_err, "failed to write log file, log: ", log)
        return
    end

    fp:close()
end

function log(self, log_level, ...)
    local level = self.log_level
    if log_level < level then
        return
    end

    local args = { ... }
    for i = 1, #args do
        if args[i] == nil then
            args[i] = "nil"
        elseif type(args[i]) == "table" then
            args[i] = "is a table"
        end
    end

    local info = getinfo(2)
    local request = self.request
    local log_vars = {
        time(),
        "[" .. level_str[log_level] .. "]",
        info.short_src .. ":" .. info.currentline,
        "called by function:" .. (info.name or "main"),
        concat(args, ", "),
        "request: " .. request.request_uri,
        "host: " .. request.host
    }

    return _log(self, concat(log_vars, ", "))
end

local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)
