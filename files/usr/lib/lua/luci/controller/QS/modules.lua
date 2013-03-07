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

function adminPasswordParser()
   errors = {}
   local p1 = val.adminPassword_pwd1
   local p2 = val.adminPassword_pwd2 
   if p1 or p2 then
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
   QS = luci.controller.QS.QS
   for line in io.lines("/usr/share/commotion/configs/Commotion") do
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
   local val = luci.http.formvalue()
   if val.accessPoint_nodeName then
	  if val.accessPoint_nodeName == '' then
		 errors['node_name'] = "Please enter a node name"
	  else
		 local SSID = val.accessPoint_nodeName
		 local file = "/usr/share/commotion/configs/Commotion"
		 local find =  "^ssid=.*"
		 local replacement = 'ssid='..SSID
		 replaceLine(file, find, replacement)
	  end
   end
   if next(errors) ~= nil then
	  return errors
   end
   
end

function secAccessPointRenderer()
   for line in io.lines("/usr/share/commotion/configs/Commotion") do
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
   local val = luci.http.formvalue()
   if val.secAccessPoint_nodeName then
	  if val.secAccessPoint_nodeName == '' then
		 errors['node_name'] = "Please enter a node name"
	  else
		 local SSID = val.secAccessPoint_nodeName
		 local file = "/usr/share/commotion/configs/Commotion"
		 local find =  "^ssid=.*"
		 local replacement = "ssid="..SSID
		 replaceLine(file, find, replacement)
	  end
   end
   local p1 = val.secAccessPoint_pwd1
   local p2 = val.secAccessPoint_pwd2 
   if p1 or p2 then
	  if p1 == p2 then
		 if p1 == '' then
			errors['pw'] = "Please enter a password"
		 else   
		 local file = "/usr/share/commotion/configs/Commotion"
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

function replaceLine(fn, find, replacement)
   --Function for replacing values in non-uci config files
   --replaceLine(File Name, search string, replacement text)


   if luci.sys.call('grep -q '..find..' '..fn) == 1 then
	  repl = [["]]..replacement..[["]]
	  luci.sys.call([[awk '/]]..find..[[/{f=1}END{ if (!f) {print ]]..repl..[[}}1' ]]..fn..[[ > /tmp/config.test]])
	  --TODO need a way of getting this awk to manipulate the file in place and not go to the /tmp/config.test file
   else
	  luci.sys.call('sed -i s/'..find..'/'..replacement..'/g '..fn) --This replaces a line in line but returns nothing if thing is not found
   end 
	  --luci.sys.call("mv /tmp/config.test " .. fn.."01") -- This works ...TODO get the below working
	  --luci.sys.call("sleep 1")
	  --luci.sys.call("mv /tmp/config.test " .. fn) -- This only prints the missing line WTF
				  

   --luci.sys.call('mv '..fn..'02'..fn)
end


function splashPageRenderer()
   return 'true'
end

function splashPageParser()
   if luci.http.formvaluetable("cptv") then
	  captive = luci.http.formvaluetable("cptv")
   end
   local fs = require "nixio.fs"
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
end


function finalCountdownRenderer()
   QS = luci.controller.QS.QS
   QS.pages('next', 'setupComplete', 'skip')
   return 'true'
end

function neighborhoodRenderer()
   --TODO this is mostly stolen from olsrd.lua. Just need to parse the file to get the number of neighbors
   -- TODO switch this rawdata call out with one below
   --local rawdata = luci.sys.httpget("http://127.0.0.1:2006/neighbors")
   --TODO remove the false raw data below and implement the one above... just like the other comment says.
   local rawdata = [[Table: Neighbors
IP address		SYM		MPR		MPRS	Will.	2 Hop Neighbors
10.10.0.152		YES		NO		NO		6		0
5.10.0.152		YES		NO		NO		6		34
10.2.0.152		YES		NO		NO		6		1
10.10.0.142		YES		NO		NO		6		5 ]]
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



-- ####modules TODO####
--networkSecurity
--nodeNaming
--yourNetwork


function nearbyMeshRenderer()
   QS = luci.controller.QS.QS
   local networks = QS.commotionDaemon('nearbyNetworks')
   if networks == nil then
	  networks = 'none'
   end
   return networks
end

function nearbyMeshParser(val)
   local uci = luci.model.uci.cursor()
   if val.nearbyMesh then
	  uci:set('quickstart', 'options', 'meshName', val.nearbyMesh)
	  uci:save('quickstart')
	  uci:commit('quickstart')
   else
	  error  = "Please choose a network if you would like to continue." 
	  return error
   end
end

function oneClickRenderer()
   luci.sys.call("cp /usr/share/commotion/configs/Commotion /etc/config/nodeConf")
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
	  --Add error checking for configs in for version 3 when we have an actual development cycle
	  --error = "Please upload a setting file."
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
		 --TODO swap out commented correct line for line below
		 if luci.sys.call("pwd") == '1' then
			--elseif luci.sys.call("servald keyring list") == '1' then
			error = 'The file uploaded is either not a proper keyring or has a pin that is required to access the key within. If you do not think that your keyring has a pin please upload a proper servald keyring for your network key. If your keyring is pin protected, please click continue below.'
		 end
	  end
   end
   if error ~= '' then
	  return error
   end
end

function configReqsRenderer()
   local uci = luci.model.uci.cursor()
   --TODO see if a serval key is used on the config and tell view to display key upload
   --TODO The following is NOT where the wpa password will be, get correct info from Josh
   if uci:get('nodeConf', 'confInfo', 'password') then
	  --TODO tell view to display the wpa password viewer
   end
   --TODO if none are needed then tell page to skip itself and go to the loading page
      return {['name'] = 'static'}
end

function configReqsParser()
   local error = {}
   error['servalKey'] = keyCheck()
end

function configsRenderer()
   QS = luci.controller.QS.QS
--talk to daemon for configs
   local networks = QS.commotionDaemon('configs')
   return networks
end

function configsParser(val)
   if val.configFile then
	  configFile = val.configFile
	  local returns = luci.sys.call("cp " .. "/usr/share/commotion/configs/" .. configFile .. " /etc/config/nodeConf")
	  if returns ~= 0 then
		 return "Error parsing config file. Please choose another config file or find and upload correct config"
	  end
   else
	  error = "Please choose a settings file"
	  return error
   end
end

function meshDefaultsRenderer()
   --set defaults with upload turned off by default
   defaults = {types = {}, upload = true, routing={}}
   local securityLanguage ={
	  "This network is insecure",
	  "This network is somewhat secure",
	  "This network is moderately secure",
	  "This network is secure against casual attackers",
	  "This network has adequate security for most needs"}

   local uci = luci.model.uci.cursor()
   --SECURITY 
   security = uci:get_list('nodeConf', 'defaults', 'sec')
   local secCounter = 0
   for _,x in ipairs(security) do
	  secCounter = secCounter +1
	  defaults.types[x] = uci:get('documentation', 'security', x)
   end
   defaults['secMsg'] = securityLanguage[secCounter/2]
   routing = uci:get('nodeConf', 'defaults', 'routing')
   defaults['routing'][routing] = uci:get('documentation', 'routing', 'OLSRd')
   
   --If an key is required add uploader
   if defaults.types['wpa_none'] then
	  defaults['upload'] = nil
	  defaults['uploadTitle'] = "a key for this network here"
   end
   return defaults
end

function connectedNodesParser()
   if luci.http.formvalue("key") then
	  file = luci.http.formvalue("key")
   end
end

function settingPrefsRenderer()
   QS = luci.controller.QS.QS
   local uci = luci.model.uci.cursor()
   QS.commotionDaemon("engage")
   QS.pages('next', 'seeNetwork', 'skip')
   time = 120
   --TODO figure our where the daemon will pull the ssid from
   name = uci:get('nodeConf', 'confInfo', 'name')
   return {['time'] = time, ['name'] = name}
end

function completeRenderer()
   local uci = luci.model.uci.cursor()
   uci:set('quickstart', 'options', 'complete', 'true')
   uci:save('quickstart')
   uci:commit('quickstart')
   luci.http.redirect("/cgi-bin/luci/admin")
   do return end
end


