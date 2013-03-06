module("luci.controller.QS.modules", package.seeall)
   --to have a html page render you must return a value or it wont.

function welcomeRenderer()
   return 'true'
end

function adminPasswordRenderer()
   return true
end

function adminPasswordParser()
   local p1 = val.basicInfo_pwd1
   local p2 = val.basicInfo_pwd2 
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
end
-- ####modules TODO####
-- upload
--accessPoint
--secAccessPoint
--splashPage
--networkSecurity
--nodeNaming
--neighborhood
--yourNetwork
--finalCountdown

function basicInfoRenderer()
   --check current node_name and return it as nodename
   local uci = luci.model.uci.cursor()
   local changable = uci:get('nodeConf', 'confInfo', 'changableName')
   if changable == 'true' then
	  local nodeName = uci:get('nodeConf', 'confInfo', 'name')
	  if nodeName then
		 return {['name'] = nodeName}
	  end
   else
	  return {['name'] = 'static'}
   end
end

function basicInfoParser(val)
   local errors = {}
   local uci = luci.model.uci.cursor()
   if val.basicInfo_nodeName then
	  if val.basicInfo_nodeName == '' then
		 errors['node_name'] = "Please enter a node name"
	  else
		 uci:set('nodeConf', 'confInfo', 'name', val.basicInfo_nodeName)
		 uci:save('nodeConf')
		 uci:commit('nodeConf')
	  end
   end
   --This next(errors) checks to see if there are items in the errors function
   if next(errors) == nil then
	  return nil
   else
	  return errors
   end
end

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

function connectedNodesRenderer()
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
   --TODO actually create meaning text for this section. 
   if neighbors <= 4 then
	  meaning = neighborText[neighbors+1]
   else
	  meaning = neighborText[6]
   end
end
return {['neighbors'] = neighbors, ['meaning'] = meaning}
end

