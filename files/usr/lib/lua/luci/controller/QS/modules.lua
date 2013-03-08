module("luci.controller.QS.modules", package.seeall)
   --to have a html page render you must return a value or it wont.

function index()
   --This function is required for LuCI
   --we don't need to define any pages in this file
end
function welcomeRenderer()
   return 'true'
end

function adminPasswordRenderer()
   return true
end

function adminPasswordParser(val)
   errors = {}
   local p1 = val.adminPassword_pwd1
   local p2 = val.adminPassword_pwd2 
   if p1 or p2 then
	  luci.controller.QS.QS.log(p1 .. ":PzASSWORD")
	  if p1 == p2 then
		 if p1 == '' then
			errors['pw'] = "Please enter a password"
		 else   
			luci.sys.user.setpasswd("root", p1)
		 end
	  else
		 errors['pw'] = "Given password confirmation did not match, password not changed!"
	  end
   end
   if next(errors) ~= nil then
	  return errors
   end
end

function accessPointRenderer()
      if not luci.fs.isfile("/etc/commotion/profiles.d/quickstartAP") then
	  luci.sys.call('cp /etc/commotion/profiles.d/default /etc/commotion/profiles.d/quickstartAP') 
   end
   for line in io.lines("/etc/commotion/profiles.d/quickstartAP") do
	  b,c = string.find(line,"^ssid=.*")
	  if b then
		 SSID = string.sub(line,b+5,c)
	  end
   end
   if SSID then
	  return {['name'] = SSID}
   else
	  return{['name'] = "Something Awesome Here"}
   end
end

function accessPointParser()
   errors = {}
   QS = luci.controller.QS.QS
   local val = luci.http.formvalue()
   if val.accessPoint_nodeName then
	  if val.accessPoint_nodeName == '' then
		 errors['node_name'] = "Please enter a node name"
	  else
		 local SSID = val.accessPoint_nodeName
		 local file = "/etc/commotion/profiles.d/quickstartAP"
		 local find =  "^ssid=.*"
		 local replacement = 'ssid='..SSID
		 replaceLine(file, find, replacement)
		 QS.interface('quickstartAP')
	  end
   end
   if next(errors) ~= nil then
	  return errors
   end
   
end

function secAccessPointRenderer()
   if not luci.fs.isfile("/etc/commotion/profiles.d/quickstartSec") then  
	  luci.sys.call("cp /etc/commotion/profiles.d/default /etc/commotion/profiles.d/quickstartSec") 
   end
   for line in io.lines("/etc/commotion/profiles.d/quickstartSec") do
	  b,c = string.find(line,"^ssid=.*")
	  if b then
		 SSID = string.sub(line,b+5,c)
	  end
   end
   if SSID then
	  return {['name'] = SSID}
   else
	  return{['name'] = "Something Awesome Here"}
   end
end

function secAccessPointParser()
   errors = {}
   QS = luci.controller.QS.QS
   local val = luci.http.formvalue()
   if val.secAccessPoint_nodeName then
	  if val.secAccessPoint_nodeName == '' then
		 errors['node_name'] = "Please enter a node name"
	  else
		 local SSID = val.secAccessPoint_nodeName
		 local file = "/etc/commotion/profiles.d/quickstartSec"
		 local find =  "^ssid=.*"
		 local replacement = "ssid="..SSID
		 replaceLine(file, find, replacement)
		 QS.interface('quickstartSec')
	  end
   end
   local p1 = val.secAccessPoint_pwd1
   local p2 = val.secAccessPoint_pwd2 
   if p1 or p2 then
	  if p1 == p2 then
		 if p1 == '' then
			errors['pw'] = "Please enter a password"
		 else   
		 local file = "/etc/commotion/profiles.d/quickstartSec"
		 local find =  '^wpakey=.*'
		 local replacement = "wpakey="..p1
		 replaceLine(file, find, replacement)
		 end
	  else
		 errors['pw'] = "Given password confirmation did not match, password not changed!"
	  end
   end
   if next(errors) ~= nil then
	  return errors
   end
end

function splashPageRenderer()
   return 'true'
end

function applicationsParser()
end

function splashPageParser()
   if luci.http.formvaluetable("cptv") then
	  captive = luci.http.formvaluetable("cptv")
   end
   errors = {}
   local fs = require "nixio.fs"
   local uci = luci.model.uci.cursor()
   local splashtextfile = "/usr/lib/luci-splash/splashtext.html"
   for i,x in pairs(captive) do
	  if i == "main" then
		 if x == "" then
			main = ""
		 else
			main = ("<p>" .. x .. "</p>")
		 end
	  elseif i == "title" then
		 if x == "" then
			title = ""
		 else
			title = ("<h1>" .. x .. "</h1>")
		 end
	  elseif i == "home" then
		 uci_values = 1
		 uci:set('luci_splash', 'general', 'homepage', x)
	  elseif i == "time" then
		 uci_values = 1
		 uci:set('luci_splash', 'general', 'leasetime', x)
	  end
   end
   data = (title .. main)

   if data == "" then
	  errors['cptv'] = "Please fill out text for your captive portal."
	  fs.unlink(splashtextfile)
   else
	  fs.writefile(splashtextfile, data:gsub("\r\n", "\n"))
   end
   if uci_values then
	  uci:save('luci_splash')
	  uci:commit('luci_splash')
   end
   if next(errors) ~= nil then
	  return errors
   end
end


function neighborhoodRenderer()
   local rawdata = luci.sys.httpget("http://127.0.0.1:2006/neighbors")
   local tables = luci.util.split(luci.util.trim(rawdata), nil, nil, nil)
   neighbors = 0
   for i,x in ipairs(tables) do
	  if string.find(x, "^%d+%.%d+%.%d+%.%d+") then
		 neighbors = neighbors + 1
	  elseif string.find(x, "^%x+%:%x+%:%x+%:%x+%:%x+%:%x+%:%x+%:%x+") then
		 neighbors = neighbors + 1
	  end
	  neighborText = {
		 "You have no neighbors. Please give the router a minute or two to talk to its neighboring nodes. We will refresh this page automatically every few seconds. If after a minute or two you still have no neighbors it could be because you are using a custom configuration that does not allow your node to connect to its neighbors, or you just may not be near any other nodes. If you would like to keep this configuration anyway please click 'Finish', else, click 'Start Over' to begin again.",
		 "You have one neighbor. This could mean that you are on the edges of a network, or that your node is in a location that is not being reached by neighboring nodes like a basement or behind a wall or dense foliage. If you would like to keep this configuration please click 'Finish', else, click 'Start Over' to begin again.",
		 "You have two neighbors. This could mean that you are on the edges of a network, or that your node is in a location that is not being reached by neighboring nodes like a basement or behind a wall or dense foliage. If you would like to keep this configuration please click 'Finish', else, click 'Start Over' to begin again.",
		 "You have three neighbors. If you would like to keep this configuration please click 'Finish', else, click 'Start Over' to begin again.",
		 "You have four neighbors. If you would like to keep this configuration please click 'Finish', else, click 'Start Over' to begin again.",
		 "You have many neighbors. If you would like to keep this configuration please click 'Finish', else, click 'Start Over' to begin again."}
	  if neighbors <= 4 then
		 meaning = neighborText[neighbors+1]
	  else
		 meaning = neighborText[6]
	  end
   end
   return {['meaning'] = meaning}
end

function nodeNamingRenderer()
   local uci = luci.model.uci.cursor()
   --get hostname from system file
   uci:foreach("system", "system",
			   function(s)
				  if s.hostname then
					 hostname = s.hostname
				  end
			   end)
   if not luci.fs.isfile("/etc/commotion/profiles.d/quickstartMesh") then
	  luci.sys.call('cp /etc/commotion/profiles.d/default /etc/commotion/profiles.d/quickstartMesh') 
   end
   for line in io.lines("/etc/commotion/profiles.d/quickstartMesh") do
	  b,c = string.find(line,"^ssid=.*")
	  if b then
		 netName = string.sub(line,b+5,c)
	  end
   end
   if netName and hostname then
	  return {['name'] = netName, ['net'] = hostname}
   else
	  return{['name'] = "Something Awesome Here", ['net'] = "Something even better here"}
   end
end

function nodeNamingPointParser()
   errors = {}
   QS = luci.controller.QS.QS
   local val = luci.http.formvalue()
   if val.nodeNaming_nodeName then
	  if val.nodeNaming_nodeName == '' then
		 errors['node_name'] = "Please enter a node name"
	  else
		 local SSID = val.accessPoint_nodeName
		 local file = "/etc/commotion/profiles.d/quickstartMesh"
		 local find =  "^ssid=.*"
		 local replacement = 'ssid='..SSID
		 replaceLine(file, find, replacement)
		 QS.interface('quickstartMesh')
	  end
   end
   if val.nodeNaming_netName == '' then
	  errors['net_name'] = "Please enter a network name"
   else
	  uci:foreach("system", "system",
				  function(s)
					 if s.hostname then
						host = true
					 end
					 if host == true then
						host = false
						uci:set("system", s['.name'], "hostname", val.accessPoint_netName)
					 end
				  end)
   end
   if next(errors) ~= nil then
	  return errors
   end
end

function yourNetworkRenderer()
   if luci.fs.isfile("/etc/commotion/profiles.d/quickstartAP") then
	  for line in io.lines("/etc/commotion/profiles.d/quickstartAP") do
		 b,c = string.find(line,"^ssid=.*")
		 if b then
			apName = string.sub(line,b+5,c)
		 end
	  end
   elseif luci.fs.isfile("/etc/commotion/profiles.d/quickstartSec") then
	  for line in io.lines("/etc/commotion/profiles.d/quickstartSec") do
		 b,c = string.find(line,"^ssid=.*")
		 if b then
			apName = string.sub(line,b+5,c)
		 end
	  end
	  --TODO PUT AN ELSE STATEMTN FOR NOT FOUND HERE though there shoudl totally be a found... mabey an error
   end
   local nodeStuff = nodeNamingRenderer()
   local meshName = nodeStuff['name']
   local nodeName = nodeStuff['net'] 
   return {['meshName'] = meshName, ['nodeName'] = nodeName, ['apName'] = apName}

end

function namingRenderer()
   return true
end

function networkSecurityRenderer()
   local servald = true
   local wpa = true
   local upload = true
   if luci.fs.isfile("/etc/commotion/profiles.d/quickstartMesh") then
	  for line in io.lines("/etc/commotion/profiles.d/quickstartMesh") do
		 b,c = string.find(line,"^wpakey=.*")
		 d,e = string.find(line,"^servald=.*")
		 if b then
			wpa = string.sub(line,b+7,c)
		 end
		 if d then --I bet I could find an even more difficult set of variables to differentiate than b and d, but ill leave it at this :)
			servald = string.sub(line,d+8,e)
			luci.controller.QS.QS.log('servald = '..servald)
		 end
	  end
   end
   if servald=='true' then
	  return {['wpakey'] = wpa, ['servald'] = servald}
   else
	  return {upload = true, ['wpakey'] = wpa}
   end
end

function networkSecurityParser()
   errors = {}
   QS = luci.controller.QS.QS
   local val = luci.http.formvalue()
   if val.nodeNaming_nodeName then
	  if val.nodeNaming_nodeName == '' then
		 errors['node_name'] = "Please enter a node name"
	  else
		 local SSID = val.accessPoint_nodeName
		 local file = "/etc/commotion/profiles.d/quickstartMesh"
		 local find =  "^ssid=.*"
		 local replacement = 'ssid='..SSID
		 replaceLine(file, find, replacement)
		 QS.interface('quickstartMesh')
	  end
   end   
   if next(errors) ~= nil then
	  return errors
   end
end


function uploadRenderer()
   --creates an uploader based upon the fileType of the page config
   local uci = luci.model.uci.cursor()
   local page = uci:get('quickstart', 'options', 'pageNo')
   local fileType = uci:get('quickstart', page, 'fileType')
   --TODO check uploader module to see if it needs any values
   if fileType == 'config' then
   fileInstructions="and submit a config file from your own computer. You will be able to customize this configuration once it has been applied to the node."
   elseif fileType == 'key' then
	  fileInstructions="and submit a key file from your own computer. This will allow your node to talk to any network with the same key file"
   end   
   return {['fileType']=fileType, ['fileInstructions']=fileInstructions}
end


function uploadParser()
   --Parses uploaded data 
   local uci = luci.model.uci.cursor()
      error = ''
   if luci.http.formvalue("config") ~= '' then
	  file = luci.http.formvalue("config")
   elseif luci.http.formvalue("config") == '' then
	  error = "Please upload a setting file."
   elseif luci.http.formvalue("key") ~= '' then
	  file = luci.http.formvalue("key")
   end
   if file then
	  if luci.http.formvalue("config") then
		 --check that each file is actually the file type that we are looking for!!!
		 if not uci:get('nodeConf', 'confInfo', 'name') then
			error = 'This file is not a configuration file. Please check the file and upload a working config file or go back and choose a pre-built config'
		 end
	  elseif luci.http.formvalue("key") then
		 if luci.sys.call("pwd") == '1' then
			elseif luci.sys.call("servald keyring list") == '1' then
			error = 'The file uploaded is either not a proper keyring or has a pin that is required to access the key within. If you do not think that your keyring has a pin please upload a proper servald keyring for your network key. If your keyring is pin protected, please click continue below.'
		 end
	  end
   end
   if error ~= '' then
	  return error
   end
end

function replaceLine(fn, find, replacement)
   --Function for replacing values in non-uci config files
   --replaceLine(File Name, search string, replacement text)
   if luci.sys.call('grep -q '..find..' '..fn) == 1 then
	  repl = [["]]..replacement..[["]]
	  luci.sys.call([[awk '/]]..find..[[/{f=1}END{ if (!f) {print ]]..repl..[[}}1' ]]..fn..[[ > /tmp/config.test]])
   else
	  luci.sys.call('sed -i s/'..find..'/'..replacement..'/g '..fn)
   end 
   luci.sys.call("mv /tmp/config.test " .. fn)
end

