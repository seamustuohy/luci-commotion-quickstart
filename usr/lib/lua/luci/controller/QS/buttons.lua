module("luci.controller.QS.buttons", package.seeall)

function index()
    pineapple = "pineapple"
end

function tryNetwork()
   QS = luci.controller.QS.QS
   --sets chosen  network config from on router or through commotion daemon
   local uci = luci.model.uci.cursor()
   nearbyMesh = uci:get('quickstart', 'options', 'meshName')
   if nearbyMesh == uci:get('nodeConf', 'confInfo', 'name') then
	  QS.commotionDaemon('apply', nearbyMesh)
	  --TODO find out what data Josh can pass me to build a nodeConf
	  --log('the daemon now passes me config data like magic and I place it in a nodeConf')
   elseif luci.fs.isfile("/usr/share/commotion/configs/" .. nearbyMesh) then
	  configFile = nearbyMesh
	  local returns = luci.sys.call("cp " .. "/usr/share/commotion/configs/" .. configFile .. " /etc/config/nodeConf")
	  if returns ~= 0 then
		 error = "Error parsing config file. Please choose another config file or find and upload correct config" 
		 return error 
	  end
	  QS.commotionDaemon('apply', 'nodeConf')
   end
   pages("next")
end
