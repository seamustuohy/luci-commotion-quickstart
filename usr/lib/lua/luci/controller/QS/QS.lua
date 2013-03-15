module("luci.controller.QS.QS", package.seeall)

require "luci.model.uci"
require "luci.controller.QS.buttons"
require "luci.controller.QS.modules"

function index()
   local uci = luci.model.uci.cursor()
   if uci:get('quickstart', 'options', 'complete') ~= 'true' then
	  entry({"QuickStart"}, call("main"), "Quick Start").dependent=false
   end
   
end

function main()
	-- if return values get them and pass them to return value parser
	setFileHandler()
	check = luci.http.formvalue()
	if next(check) ~= nil then
	   errorMsg = checkPage()
	end
     --1) call uci parser, returning dict of pages
	local uci = luci.model.uci.cursor()
	local pageNo,lastPg = pages('get')
	--Create/clear a space for pageValues and populate with page
	local pageValues = {modules = {}, buttons = {}, page = {['pageNo'] = pageNo, ['lastPg'] = lastPg}}
	local pageContext = uci:get_all('quickstart', pageNo)
	-- iterate through the list of page content from the UCI file and run corresponding functions, populating a dictionary with the values required by each module
	local removeUpload = nil
	for i,x in pairs(pageContext) do
	   if i == 'modules' then
		  for _,z in ipairs(x) do
			 -- Check for renderer function and run if it exists
			 for i,x in pairs(luci.controller.QS.modules) do
				if i == (z .. "Renderer") then
				   pageValues.modules[z]=luci.controller.QS.modules[z .. "Renderer"]()
				   if type(pageValues.modules[z]) == 'table' and pageValues.modules[z]['upload'] then
					  removeUpload = true
				   end
				end
			 end
		  end
	   elseif i == 'buttons' then
		  for _,z in ipairs(x) do
			 button = string.split(z, ",|")
			 --Add buttons to page
			 pageValues.buttons[button]=true
		  end
	   else
		  pageValues[i]=x
	   end
	end
	if errorMsg then
	   pageValues['errorMsg'] = errorMsg
	   -- log(pageValues.errorMsg)
	end
	if removeUpload == true and pageValues.modules.upload then
	   pageValues.modules.upload = nil
	end
	luci.template.render("QS/main/Quickstart", {pv=pageValues})
end

function string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

function pages(command, next, skip)
   --manipulates the rendered pages for a user
   local uci = luci.model.uci.cursor()
   local page = uci:get('quickstart', 'options', 'pageNo')
   local lastPg = uci:get('quickstart', 'options', 'lastPg')
   if next == 'back' then
	  uci:set('quickstart', 'options', 'pageNo', lastPg)
	  uci:set('quickstart', 'options', 'lastPg', 'welcome')
	  uci:save('quickstart')
	  uci:commit('quickstart')
   elseif command == 'next' then
	  if skip == nil then
		 uci:set('quickstart', 'options', 'lastPg', page)
	  end
	  nextExist =  uci:get('quickstart',  next)
	  if nextExist then
		 uci:set('quickstart', 'options', 'pageNo', next)
		 uci:save('quickstart')
		 uci:commit('quickstart')
	  end
   elseif command == 'get' then
	  return page,lastPg
   end
end

function wirelessController(profiles)
   local uci = luci.model.uci.cursor()
   --This function creates interfaces in \etc\config\wireless and then uses 'wifi' to set a temporary network file. It passes back a dictionary of mesh and ap interfaces to use.
   dev = {}
   uci:foreach("wireless", "wifi-device",
			   function(s)
				  table.insert(dev, s['.name'])
			   end)

   --Create interfaces
   for devNum,device in ipairs(dev) do
	  --Make sure wireless devices are on... because it starts them disabled for some reason
	  disabled = uci:get('wireless', device, 'disabled')
	  if disabled then
		 disabledTrue = uci:delete('wireless', device, 'disabled')
	  end
   end
   uci:save('wireless')
   uci:commit('wireless')
   devNum = 1
   for profNum, prof in ipairs(profiles) do
	  if luci.fs.isfile("/etc/commotion/profiles.d/"..prof[2]) then
		 if prof[1] == 'mesh' then
			uci:section('wireless', 'wifi-iface', prof[2], {device=dev[devNum], network=prof[1], ssid='commotion', mode='adhoc'})
			uci:section('network', 'interface', prof[1], {proto="commotion", profile=prof[2]})
		 else
			uci:section('wireless', 'wifi-iface', prof[2], {device=dev[devNum], network=prof[1], ssid='commotion', mode='ap'})
			uci:section('network', 'interface', prof[1], {proto="commotion", profile=prof[2]})
		 end
 		 if dev[devNum+1] then
			devNum = devNum +1
		 end
	  end
   end
   uci:save('wireless')
   uci:commit('wireless')
   uci:save('network')
   uci:commit('network')
end

function checkPage()
   local returns = luci.http.formvalue()
   errors = parseSubmit(returns)
   return errors
end

function parseSubmit(returns)
   --check for submission value
   local uci = luci.model.uci.cursor()
   local submit = nil
   for i,x in pairs(returns) do
	  match = i:match("%d%:(.*)")
	  if match ~= nil then
		 button = match
	  end
   end
   local errors = {}
   local modules = {}
   --Run the return values through each module's parser and check for returns. Module Parser's only return errors.
   for kind,val in pairs(returns) do
	  if kind == 'moduleName' then
		 if type(val) == 'table' then
			for _, value in ipairs(val) do
			   table.insert(modules, value)
			end
		 elseif type(val) == 'string' then
			table.insert(modules, val)
		 end
	  end
   end
   buttonFound = 0
   for i,x in pairs(luci.controller.QS.buttons) do
	  if i == (button) then
		 buttonFound = 1
		 modules = luci.controller.QS.buttons[button](modules)
		 errors = runParser(modules)
	  end
   end
   if buttonFound == 0 then
	  errors = runParser(modules)
   end
   if  next(errors) == nil then
	  --check if button does it own paging, or if it refers to a page
	  testButton = uci:get('quickstart',  button)
	  if testButton ~= nil or 'back' then
		 pages('next', button)
	  end
   else
	  return(errors)
   end
end
	  
function runParser(modules)
   --Check for Parser function and run if it exists
   errors = {}
   local returns = luci.http.formvalue()
   --log(returns)
   if modules then
	  for _,value in ipairs(modules) do
		 for i,x in pairs(luci.controller.QS.modules) do
			if i == (value .. "Parser") then
			   --log(value)
			   errors[value]= luci.controller.QS.modules[value .. "Parser"](returns)
			end
		 end
	  end
   end
   log(errors)
   return(errors)
end
      
function keyCheck()
   local uci = luci.model.uci.cursor()
   --check if a key is required in a config file and compare the current key to it.
   local confKeySum = uci:get('nodeConf', 'confInfo', 'key')
   --log(string.len(confKeySum))
   if string.len(confKeySum) == 32 then
	  if luci.fs.isfile(keyLoc .. "network.keyring") then
		 local keyringSum = luci.sys.exec("md5sum " .. keyLoc .. "network.keyring" .. "| awk '{ print $1 }'")
		 if keyring ~= confKey then
			return "error: key does not match"
		 end
	  else
		 --TODO cretae value to send if no keyring exists
		 return "keyring does not exist"
	  end
   else

	  return "no keyring"
   end
end

function updateKey()
   local uci = luci.model.uci.cursor()
   servalKey = luci.sys.exec('SERVALINSTANCE_PATH=/etc/commotion/keys.d/mdp servald keyring list |grep -o "^[A-F0-9]*"')
   uci:foreach("olsrd", "LoadPlugin",
			   function(s)
				  --this function only works if there is some sid already in the olsr_mdp config stanza
				  if s.sid then
					 uci:set("olsrd", s['.name'], "sid", servalKey)
				  end
			   end)
   uci:commit("olsrd")
   uci:save("olsrd")
end


function setFileHandler()
   local sys = require "luci.sys"
   local fs = require "luci.fs"
   local keyLoc = "/etc/commotion/keys.d/mdp/"
   local configLoc = '/etc/commotion/profiles.d/'
   -- causes media files to be uploaded to their namesake in the /tmp/ dir.
   local fp
   luci.http.setfilehandler(
	  function(meta, chunk, eof)
		 if not fp then
			if meta and meta.name == "config" then			   
			   fp = io.open(configLoc .. "quickstartMesh", "w")
			elseif meta and meta.name == "key" then
			   fp = io.open(keyLoc .. "serval.keyring", "w")
			   updateKey()
			end
			if chunk then
			   fp:write(chunk)
			end
			if eof then
			   fp:close()
			end
		 end
	  end)
end

function commotionDaemon(request, value)
--TODO have this function make Ubus calls to the commotion daemon instead of pass back dummy variables
--This if statement FAKES grabbing nearby mesh networks from the commotion daemon
   errors = {}
   --TODO UBUS uncomment
   --load ubus module
   if request == 'nearbyNetworks' then
	  local networks = {
		 { name="Commotion", config="true"},
		 { name="RedHooks", config="true"},
		 { name="Ninux", config="false"},
		 { name="Byzantium", config="true"},
		 { name="Funkfeuer", config="false"},
		 { name="FreiFunk", config="false"}
	  }
	  return networks
   elseif request == "numNetworks" then
	  local networks = {
		 { name="Commotion", config="true"},
		 { name="RedHooks", config="true"},
		 { name="Ninux", config="false"},
		 { name="Byzantium", config="true"},
		 { name="Funkfeuer", config="false"},
		 { name="FreiFunk", config="false"},
		 { name="Big Bobs Mesh Network", config="false"},
		 { name="Viva la' Revolution", config="true"},
	  }
	  count = 0
	  for _ in pairs(networks) do
		 count = count +1
	  end
	  return count
   elseif request == 'configs' then
	  local networks = {
		 { name="Secure Commotion Backhul", config="In a hierarchical telecommunications network the backhaul portion of the network comprises the intermediate links between the core network, or backbone network and the small subnetworks at the edge of the entire hierarchical network.", file="secBH"},
		 { name="Open Commotion Backhaul", config="In a hierarchical telecommunications network the backhaul portion of the network comprises the intermediate links between the core network, or backbone network and the small subnetworks at the edge of the entire hierarchical network.", file="openBH"},
		 { name="Secure Commotion Access Point", config="In computer networking, a wireless access point (AP) is a device that allows wireless devices to connect to a wired network using Wi-Fi, or related standards. The AP usually connects to a router (via a wired network) if it's a standalone device, or is part of a router itself.", file="secAP"},
		 { name="Open Commotion Access Point", config="In computer networking, a wireless access point (AP) is a device that allows wireless devices to connect to a wired network using Wi-Fi, or related standards. The AP usually connects to a router (via a wired network) if it's a standalone device, or is part of a router itself.", file="openAP"},
		 { name="Secure Commotion Gateway", config="A wireless gateway is a computer networking device that routes packets from a wireless LAN to another network, typically a wired WAN. Wireless gateways combine the functions of a wireless access point, a router, and often provide firewall functions as well. This converged device saves desk space and simplifies wiring by replacing two electronic devices with one.", file="secGW"},
		 { name="Open Commotion Access Gateway", config="A wireless gateway is a computer networking device that routes packets from a wireless LAN to another network, typically a wired WAN. Wireless gateways combine the functions of a wireless access point, a router, and often provide firewall functions as well. This converged device saves desk space and simplifies wiring by replacing two electronic devices with one.", file="openGW"},
	  }
	  return networks
   elseif request == 'apply' then
	  if not value then
		 value = uci:get('quickstart', 'options', 'meshName')
	  end
	  --TODO ubus calls to commotion daemon telling it what seen network to apply
   --TODO figure out what josh needs me to do to try to apply to an existing network, also we need to get info for configReqs page on what the network requires so we can get that from the user.
   elseif request == 'I NEED A CONFIG JOSH' then
	  return nil
   elseif request == 'engage' then
	  --TODO incorporate the final ubus add/select sections ehre
   end
end


function log(msg)
   if (type(msg) == "table") then
	  for key, val in pairs(msg) do
		 if type(key) == 'boolean' then
			log('{')
			log(tostring(key))
			log(':')
			log(val)
			log('}')
		 elseif type(val) == 'boolean' then
			log('{')
			log(key)
			log(':')
			log(tostring(val))
			log('}')
		 else
			log('{')
			log(key)
			log(':')
			log(val)
			log('}')
		 end
	  end
   else
	  luci.sys.exec("logger -t luci " .. msg)
   end
end