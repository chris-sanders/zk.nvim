local M = {}

local function coroutine_callback(func)
  local co = coroutine.running()
  local callback = function(...)
    coroutine.resume(co, ...)
  end
  func(callback)
  return coroutine.yield()
end

local function coroutinify(func)
  return function(...)
    local args = {...}
    return coroutine_callback(
      function(cb)
        table.insert(args, cb)
        func(unpack(args))
      end
    )
  end
end

local fs_write = coroutinify(vim.loop.fs_write)

local function get_lines_from_file(file)
  local t = {}
  for v in file:lines() do
    table.insert(t, v)
  end
  return t
end

-- contents can be either a table with tostring()able items, or a function that
-- can be called repeatedly for values. The latter can use coroutines for async
-- behavior.
function M.call(contents, fzf_cli_args)
  if not coroutine.running() then
    error("Please run function in a coroutine")
  end
  local command = "fzf"
  local fifotmpname = vim.fn.tempname()
  local outputtmpname = vim.fn.tempname()

  if contents then
    if type(contents) == "string" then
      command = string.format("%s | %s", contents, command)
    else
      command = command .. " < " .. vim.fn.shellescape(fifotmpname)
    end
  end

  if fzf_cli_args then
    command = command .. " " .. fzf_cli_args
  end

  command = command .. " > " .. vim.fn.shellescape(outputtmpname)

  vim.fn.system({"mkfifo", fifotmpname})
  local fd
  local done_state = false

  local function on_done()
    if type(contents) == "string" then
      return
    end
    if done_state then
      return
    end
    done_state = true
    vim.loop.fs_close(fd)
  end

  local co = coroutine.running()
  vim.fn.termopen(
    command,
    {
      on_exit = function()
        local f = io.open(outputtmpname)
        local output = get_lines_from_file(f)
        f:close()
        on_done()
        vim.fn.delete(fifotmpname)
        vim.fn.delete(outputtmpname)
        local ret
        if #output == 0 then
          ret = nil
        else
          ret = output
        end
        coroutine.resume(co, ret)
      end
    }
  )
  vim.cmd [[set ft=fzf]]
  vim.cmd [[startinsert]]

  if type(contents) == "string" then
    goto wait_for_fzf
  end

  fd = vim.loop.fs_open(fifotmpname, "w", 0)

  -- this part runs in the background, when the user has selected, it will
  -- error out, but that doesn't matter so we just break out of the loop.
  coroutine.wrap(
    function()
      if contents then
        if type(contents) == "table" then
          for _, v in ipairs(contents) do
            local err, bytes = fs_write(fd, tostring(v) .. "\n", -1)
            if err then
              error(err)
            end
          end
          on_done()
        else
          contents(
            function(usrval, cb)
              if done_state then
                return
              end
              if usrval == nil then
                on_done()
                cb(nil)
                return
              end
              vim.loop.fs_write(
                fd,
                tostring(usrval) .. "\n",
                -1,
                function(err, bytes)
                  if err then
                    cb(err)
                    on_done()
                    return
                  end

                  cb(nil)
                end
              )
            end,
            fd
          )
        end
      end
    end
  )()

  ::wait_for_fzf::

  return coroutine.yield()
end

return M
