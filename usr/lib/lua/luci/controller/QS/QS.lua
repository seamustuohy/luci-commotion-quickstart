module("luci.controller.QS.QS", package.seeall)

require "luci.model.uci"

function index()
   local uci = luci.model.uci.cursor()
   if uci:get('quickstart', 'options', 'complete') ~= 'true' then
	  entry({"QuickStart"}, call("main"), "Quick Start").dependent=false
   end
end

function main()
	-- if return values get them and pass them to return value parser
	setFileHandler()
	if luci.http.formvalue then
	  errorMsg = checkPage() 
	end
      --1) call uci parser, returning dict of pages
	local uci = luci.model.uci.cursor()
	local pageNo,lastPg = pages()
	--Create/clear a space for pageValues and populate with page
	local pageValues = {modules = {}, buttons = {}, page = {['pageNo'] = pageNo, ['lastPg'] = lastPg}}
	local pageContext = uci:get_all('quickstart', pageNo)
	-- iterate through the list of page content from the UCI file and run corresponding functions, populating a dictionary with the values required by each module
	local removeUpload = nil
	for i,x in pairs(pageContext) do
	   if i == 'modules' then
		  for _,z in ipairs(x) do
			 
			 pageValues.modules[z]=luci.controller.QS.QS[z .. "Renderer"]()
			 if type(pageValues.modules[z]) == 'table' and pageValues.modules[z]['upload'] then removeUpload = true end
		  end
	   elseif i == 'buttons' then
		  for _,z in ipairs(x) do
			 --Add buttons to page
			 pageValues.buttons[z]=true
		  end
	   else
		  pageValues[i]=x
	   end
	end
	if removeUpload == true and pageValues.modules.upload then
	   pageValues.modules.upload = nil
	end
	luci.template.render("QS/main/Quickstart", {pv=pageValues})
end


function logoRenderer()
   return 'true'
end

function checkPage()
   local returns = luci.http.formvalue()
   errors = parseSubmit(returns)
   return errors
end

function parseSubmit(returns)
	  --check for submission value
      local uci = luci.model.uci.cursor()
	  local submit = returns.submit
	  returns.submit = nil
	  if submit == 'next' then
		 local errors = {}
		 local modules = {}
		 --Run the return values through each module's parser and check for returns. Module Parser's only return errors. 
		 for kind,val in pairs(returns) do
			if kind == 'moduleName' then
			   if type(val) == 'table' then
				  for _, value in ipairs(val) do
					 errors[value]= luci.controller.QS.QS[value .. "Parser"](returns)
				  end
			   else if type(val) == 'string' then
					 errors[val]= luci.controller.QS.QS[val .. "Parser"](returns)
					end
			   end
			end
		 end
		 if next(errors) == nil then
			pages('next')
		 else
			return(errors)
		 end
	  elseif submit == 'back' then
		 pages('back')
	  elseif submit ~= nil then
		 --parse button functions to be run
		 return luci.controller.QS.QS[submit .. "Button"]()
	  end
end


function welcomeRenderer()
   num = commotionDaemon("numNetworks")
   return {['count'] = num}
end

function welcomeParser()
   return nil
end

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
   if next(errors) == nil then
	  return nil
   else
	  return errors
   end
end

function nearbyMeshRenderer()
   local networks = commotionDaemon('nearbyNetworks')
   return networks
end

function nearbyMeshParser(val)
   local uci = luci.model.uci.cursor()
   if val.nearbyMesh then
	  log(val.nearbyMesh)
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
   if luci.http.formvalue("config") then
	  file = luci.http.formvalue("config")
   elseif luci.http.formvalue("key") then
	  file = luci.http.formvalue("key")
   end
   error = ''
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

function keyCheck()
   --check if a key is required in the conf
   local confKeySum = uci:get('nodeConf', 'confInfo', 'key')
   log(string.len(confKeySum))
   if string.len(confKeySum) == 32 then
	  if luci.fs.isfile(keyLoc .. "network.keyring") then
		 local keyringSum = luci.sys.exec("md5sum " .. keyLoc .. "network.keyring" .. "| awk '{ print $1 }'")
		 if keyring ~= confKey then
			--TODO create value to pass if keyring key does not match network required key
		 end
	  else
		 --TODO cretae value to send if no keyring exists
	  end
   end
end


function setFileHandler()
   local uci = luci.model.uci.cursor()
   local sys = require "luci.sys"
   local fs = require "luci.fs"
   local keyLoc = "/usr/share/serval/"
   local configLoc = '/etc/config/'
   -- causes media files to be uploaded to their namesake in the /tmp/ dir.
   local fp
   luci.http.setfilehandler(
	  function(meta, chunk, eof)
		 if not fp then
			if meta and meta.name == "config" then			   
			   fp = io.open(configLoc .. "nodeConf", "w")
			elseif meta and meta.name == "key" then
			   fp = io.open(keyLoc .. "network.keyring", "w")
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


function configsRenderer()
--talk to daemon for configs
   local networks = commotionDaemon('configs')
   return networks
end

function configsParser()
   configFile = luci.http.formvalue("configFile")
   local returns = luci.sys.call("cp " .. "/usr/share/commotion/configs/" .. configFile .. " /etc/config/nodeConf")
   if returns ~= 0 then
	  return "Error parsing config file. Please choose another config file or find and upload correct config"
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

function meshDefaultsParser(val)
   --log(val)
end

function uploadConfButton()
   pages('next', 'uploadConf')
end

function preBuiltButton()
   pages('next', 'preBuilt')
end

function oneClickButton()
   pages('next', 'oneclick')
end


function tryNetworkButton()
   --sets chosen  network config from on router or through commotion daemon
   local uci = luci.model.uci.cursor()
   nearbyMesh = uci:get('quickstart', 'options', 'meshName')
   if luci.fs.isfile("/usr/share/commotion/configs/" .. nearbyMesh) then
	  log("WIN")
	  configFile = nearbyMesh
	  local returns = luci.sys.call("cp " .. "/usr/share/commotion/configs/" .. configFile .. " /etc/config/nodeConf")
	  if returns ~= 0 then
		 error = "Error parsing config file. Please choose another config file or find and upload correct config" 
		 return error 
	  end
   else
	  commotionDaemon('apply', nearbyMesh)
	  --TODO find out what data Josh can pass me to build a nodeConf
	  --log('the daemon now passes me config data like magic and I place it in a nodeConf')
   end
   pages("next")
end

function pages(command, next, skip)
   --manipulates the rendered pages for a user
	  local uci = luci.model.uci.cursor()
	  if not next then
		 local next = uci:get('quickstart', page, 'nxtPg') 
	  end
	  local lastPg = uci:get('quickstart', 'options', 'lastPg')
	  local page = uci:get('quickstart', 'options', 'pageNo')
   if command == 'next' then
	  if not skip then
		 uci:set('quickstart', 'options', 'lastPg', page)
	  end
	  uci:set('quickstart', 'options', 'pageNo', next)
	  uci:save('quickstart')
	  uci:commit('quickstart')
   elseif command == 'back' then
	  uci:set('quickstart', 'options', 'pageNo', lastPg)
	  uci:set('quickstart', 'options', 'lastPg', 'welcome')
	  uci:save('quickstart')
	  uci:commit('quickstart')
   end
end


function connectedNodesRenderer()
   return nil
end

function connectedNodesParser()
   if luci.http.formvalue("key") then
	  file = luci.http.formvalue("key")
   end
end

function settingPrefsRenderer()
   local uci = luci.model.uci.cursor()
   commotionDaemon("engage")
   pages('next', 'seeNetwork', 'skip')
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
10.10.0.142		YES		NO		NO		6		5]]
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

function connectedNodesParser()
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
		 { name="FreiFunk", config="false"},
		 { name="Big Bobs Mesh Network", config="false"},
		 { name="Viva la' Revolution", config="true"},
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
		 { name="Commotion", config="This is the commotion network"},
		 { name="RedHooks", config="Tidepool Pride WHAZZAP"},
		 { name="Ninux", config="This is teh Ninux network"},
		 { name="Byzantium", config="Byzantine network"},
		 { name="Funkfeuer", config="DAS da commotion network"},
		 { name="FreiFunk", config="This esta  the commotion network"},
		 { name="Big Bobs Mesh Network", config="This is noda the commotion network"},
		 { name="Viva la' Revolution", config="This is not the commotion network"},
	  }
	  return networks
   elseif request = 'apply' then
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