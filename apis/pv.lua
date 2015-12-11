--[[ pv - persistent variable api ]]

function init(file)
  --assert(fs.exists(file),"file does not exist")
  assert(not fs.isDir(file),"cannot open a directory")
  local f = fs.open(file,"r")
  local proxy
  if f then
    proxy = textutils.unserialize(f.readAll())
    f.close()
  else
    proxy = {}
  end
  local out = {}
  setmetatable(out,{
    __index = function(t,k)
      if k == "_proxy" then return proxy end
      if rawget(proxy,k) then
        return rawget(proxy,k)
      else
        return
      end
    end,
    __newindex = function(t,k,v)
      assert(not (type(v) == "function"),"cannot store function")
      rawset(proxy, k, v)
      local f = fs.open(file,"w")
      f.write(textutils.serialize(proxy))
      f.close()
    end
  })
  return out
end
