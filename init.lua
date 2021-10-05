-- _OSVERSION = "Good Enough BootLoader"; -- For FreeLoader recognize the bootloader.
local oefi = ...;
if _G.require then
  return io.stderr:write("Already running an system.\n");
end

local FOUND_OSSES = {};
local screen = component.list("screen",true)();
for address in component.list("screen",true) do
  if #component.invoke(address, "getKeyboards") > 1 then
    screen = address;
  end
end
local gpu = component.list("gpu",true)();
local minWidth = 50;
local minHeight = 16;
local w,h;
if gpu then
  gpu = component.proxy(gpu);
  gpu.bind(screen);
  w,h = minWidth,minHeight;
  gpu.setResolution(w,h);
  gpu.setBackground(0x000000);
  gpu.setForeground(0xFFFFFF);
  gpu.fill(1,1,w,h," ");
  gpu.set(1,1,"Welcome to GEBL!");
end
local function read(address, path)
  local proxy = component.proxy(address);
  local fd = proxy.open(path);
  local buffer = "";
  repeat
    local data = proxy.read(fd, math.huge);
    buffer = buffer .. (data or "");
  until not data;
  proxy.close(fd);
  return buffer;
end
local function isBootable(address, path)
  return not table.pack(load(read(address, path)))[2];
end
local function split(str, sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   str:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

local legacyStr = (function()
  if oefi then return " (Legacy)" else return "";end
end)();
local function findOefiVer(address)
  if not oefi then return {} end;
  local detected = {};
  local bootables = oefi.getApplications();
  for _,os in ipairs(bootables) do
    local isGEBL = (function()
      if read(os.drive, os.path):match("--[[GEBL EFI]]") then return true;end
    end)();
    if os.drive == address and not isGEBL then detected[#detected+1] = os;end;
  end
  return detected;
end

for address in component.list("filesystem",true) do
  local proxy = component.proxy(address);
  if proxy.exists("/boot/GEBL.conf") then
    local conf = read(address, "/boot/GEBL.conf");
    local config = {name="Unknown"..legacyStr,start="/init.lua",args="",address=address,uefi=false};
    for _,v in pairs(split(conf, "\n")) do
      local name,value = table.unpack(split(v, "="));
      if name == "NAME" then
        config.name = value;
      elseif name == "START" then
        config.start = value;
      elseif name == "ARGS" then
        config.args = value;
      end
    end
    local oefiVers = findOefiVer(address);
    for _,oefiVer in ipairs(oefiVers) do
      local realPathSplit = split(oefiVer.path,"/");
      local removedDot = split(realPathSplit[#realPathSplit],".")[1];
      FOUND_OSSES[#FOUND_OSSES+1] = {name = config.name.." (OEFI "..removedDot..")",start=oefiVer.path,args=config.args,address=address,uefi=true};
    end
    config.name = config.name..legacyStr;
    FOUND_OSSES[#FOUND_OSSES+1] = config;
  elseif proxy.exists("/init.lua") then
    local oefiVers = findOefiVer(address);
    for _,oefiVer in ipairs(oefiVers) do
      local realPathSplit = split(oefiVer.path,"/");
      local removedDot = split(realPathSplit[#realPathSplit],".")[1]; 
      FOUND_OSSES[#FOUND_OSSES+1] = {name="Unknown (OEFI "..removedDot..")",start=oefiVer.path,args="",address=address,uefi=true};
    end
    FOUND_OSSES[#FOUND_OSSES+1] = {name="Unknown"..legacyStr,start="/init.lua",args="",address=address,uefi=false};
  else
    local root = proxy.list("/");
    local bootable
    for _,f in ipairs(root) do
      if not proxy.isDirectory("/"..f) then
        if isBootable(address, "/"..f) then
          bootable = "/"..f;
          gpu.set(1,1,f);
          break;
        end
      end
    end
    if bootable then
      local oefiVers = findOefiVer(address);
      for _,oefiVer in ipairs(oefiVers) do
        local realPathSplit = split(oefiVer.path,"/");
        local removedDot = split(realPathSplit[#realPathSplit])[1];
        FOUND_OSSES[#FOUND_OSSES+1] = {name="Unknown (OEFI "..removedDot..")",start=oefiVer.path,args="",address=address,uefi=true};
      end
      FOUND_OSSES[#FOUND_OSSES+1] = {name="Unknown"..legacyStr,start=bootable,args="",address=address,uefi=false};
    end
  end
end

if not gpu then error("No gpu found!");end;
gpu.fill(1,1,w,h," ");

local function loados(i)
  local os = FOUND_OSSES[i];
  if os.uefi then
    _G.oefi = oefi;
    gpu.set(1,1,"Asking UEFI to load "..os.name.."...");
    return oefi.execOEFIApp(os.address,os.start,split(os.args or "", " "));
  end
  _G.oefi = nil; -- Legacy = inverse of OEFI
  gpu.set(1,1,"Loading "..os.name.."...");
  computer.getBootAddress = function() return os.address;end;
  local code = load(read(os.address, os.start), "="..os.start);
  gpu.set(1,2,"Executing...");
  if table.pack(code)[2] then
    error(table.pack(code)[2]);
  end
  return code(table.unpack(split(os.args or "", " ")));
end
local controls = {up = 200, down = 208, enter = 28, edit = 101};
local length = #FOUND_OSSES;
if length == 1 then
  gpu.fill(1,1,w,h," ");
  return loados(1);
end
local selected = 1;
local str = "Good Enough BootLoader 1.0";
local border_chars = { -- Zorya BIOS border_chars
  "┌", "─", "┐", "│", "└", "┘"
}
while true do
  gpu.set(gpu.getResolution()/2-str:len()/2, 1, str);
  for i,os in ipairs(FOUND_OSSES) do
    if i == selected then
      gpu.setBackground(0xFFFFFF);
      gpu.setForeground(0x000000);
      gpu.set(2,i+2,os.name or "[no name]".."/"..os.start);
      gpu.setBackground(0x000000);
      gpu.setForeground(0xFFFFFF);
    else
      gpu.set(2,i+2,os.name or "[no name]");
    end
  end

  gpu.set(1,2,border_chars[1]);
  gpu.fill(2,2,w-2,1,border_chars[2]);
  gpu.set(w,2,border_chars[3]);
  
  gpu.fill(1,3,1,h-4,border_chars[4]);
  gpu.fill(w,3,1,h-4,border_chars[4]);

  gpu.set(1,h-2,border_chars[5]);
  gpu.fill(2,h-2,w-2,1,border_chars[2]);
  gpu.set(w,h-2,border_chars[6]);
  
  gpu.set(1,h-1,"Use ↑ or ↓ key to select the highlighted entry.");
  gpu.set(1,h,"Use ENTER to boot into the highlighted entry.");
  local name,_,_,key = computer.pullSignal();
  if name == "key_down" then 
    if key == controls.up then
      if selected-1 < 1 then
        selected = 1;
      else
        selected = selected - 1;
      end
    elseif key == controls.down then
      if selected+1 > length then
        selected = 1;
      else
        selected = selected + 1;
      end
    elseif key == controls.enter then
      gpu.fill(1,1,w,h," ");
      return loados(selected);
    elseif key == controls.edit then
      
    end
  end
end