module("luci.controller.QS.buttons", package.seeall)

function index()
end

function networkSecuritySettings(modules)
   local QS = luci.controller.QS.QS
   local error = luci.controller.QS.QS.keyCheck()
   QS:log(error)
   return(modules)
end

function gatewayShare(modules)
   return modules
end

function keepGoing(modules)
   for i,x in ipairs(modules) do
	  if x == 'complete' then
		 rem = i
	  end
   end
   table.remove(modules, rem)

end

function back()
   return {}
end

function startOver()
   local QS = luci.controller.QS.QS
   QS.pages('next', "welcome")
   return {}
end


function netSec(modules)
   local QS = luci.controller.QS.QS
   local servald = false
   local wpa = false
   local upload = true
   if luci.fs.isfile("/etc/commotion/profiles.d/quickstartMesh") then
	  for line in io.lines("/etc/commotion/profiles.d/quickstartMesh") do
		 b,c = string.find(line,"^wpakey=.*")
		 d,e = string.find(line,"^servald=.*")
		 if b then
			wpa = string.sub(line,b+7,c)
		 end
		 if d then --I bet I could find an even more difficult set of variables to differentiate than b and d, but ill leave it at this :)
			serval = string.sub(line,d+8,e)
		 end
	  end
   end
   if serval==false and wpa==false then
	  QS.pages('next', 'naming')
	  return modules
   else
	  QS.pages('next', 'keyfilesAndSecurity')
	  return modules
   end
end

function makeItWork(modules)
   local QS = luci.controller.QS.QS
   luci.sys.call('cp /etc/commotion/profiles.d/defaultAP /etc/commotion/profiles.d/quickstartAP')
   luci.sys.call('cp /etc/commotion/profiles.d/defaultMesh /etc/commotion/profiles.d/quickstartMesh')
   QS.pages('next', 'makeItNaming')
   return(modules)
end


function noApplications(modules)
   local wpa = false
   local upload = true
   local uci = luci.model.uci.cursor()
   uci:set('quickstart', 'options', 'apps', 'true')
   uci:save('quickstart')
   uci:commit('quickstart')
   if luci.fs.isfile("/etc/commotion/profiles.d/quickstartMesh") then
	  for line in io.lines("/etc/commotion/profiles.d/quickstartMesh") do
		 b,c = string.find(line,"^wpakey=.*")
		 d,e = string.find(line,"^servald=.*")
		 if b then
			wpa = string.sub(line,b+7,c)
		 end
		 if d then --I bet I could find an even more difficult set of variables to differentiate than b and d, but ill leave it at this :)
			serval = string.sub(line,d+8,e)
		 end
	  end
   end
   if serval==false and wpa==false then
	  luci.controller.QS.QS.pages('next', 'naming')
	  return ({})
   else
	  luci.controller.QS.QS.pages('next', 'keyfilesAndSecurity')
	  return ({})
   end
end


function continueInsecure(modules)
   mod = luci.controller.QS.modules
   local file = "/etc/commotion/profiles.d/quickstartMesh"
   local find =  '^wpakey=.*'
   local replacement = "wpakey=false"
   repErr = mod.replaceLine(file, find, replacement)

   local find =  '^servald=.*'
   local replacement = "servald=false"
   repErr = mod.replaceLine(file, find, replacement)   

   luci.controller.QS.QS.pages('next', 'naming')
   return ({})
end

function noConfigUploaded(modules)
   luci.controller.QS.QS.log(modules)
   for i,x in ipairs(modules) do
	  if x == 'upload' then
		 rem = i
	  end
   end
   table.remove(modules, rem)
   luci.controller.QS.QS.pages('next', 'wifiSharing')
   return modules
end

function noSplash(modules)
   luci.controller.QS.QS.log(modules)
   for i,x in ipairs(modules) do
	  if x == 'splashPage' then
		 rem = i
	  end
   end
   table.remove(modules, rem)
   luci.controller.QS.QS.pages('next', 'meshApplications')
   return modules
end

function gatewayShareOff(modules)
   local uci = luci.model.uci.cursor()
   uci:foreach("olsrd", "LoadPlugin",
			   function(s)
				  olsrd = string.match(s.library, "^olsrd_dyn_gw.*")
				  if olsrd then
					 uci:delete("olsrd", s['.name'])
					 uci:save('olsrd')
					 uci:commit('olsrd')
				  end
			   end)
   luci.controller.QS.QS.pages('next', 'splashPage')
   return modules
end

function downloader(filename, name)
   local fp = io.open(filename, "r")
   if (fp) then
	  luci.http.prepare_content("application/force-download")
	  luci.http.header("Content-Disposition", "attachment; filename=" .. name)
	  e, es = luci.ltn12.pump.all(luci.ltn12.source.file(fp), luci.http.write)
	  fp:close()
   end
end

function checkKeyFile(modules)
   local val = luci.http.formvalue()
   if val.netSec_servald == 'true' then	  
	  --TODO Get rid of this test code for downloading
	  luci.sys.call("servald keyring add")
	  downloader("/etc/serval/serval.keyring", "serval.keyring")
   end
   return {}
end

function finish(modules)
   environment = luci.http.getenv("SERVER_NAME")
   if not environment then
	  environment = "thisnode"
   end
   luci.template.render("QS/module/applyreboot", {redirect_location=("http://" .. environment .. "/cgi-bin/luci/admin")})
   luci.http.close()
   return({'complete'}) 
end

