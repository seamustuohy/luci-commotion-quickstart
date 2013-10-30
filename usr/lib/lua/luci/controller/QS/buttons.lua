module("luci.controller.QS.buttons", package.seeall)

function index()
end

function networkSecuritySettings(modules)
   --local debug = require "luci.commotion.debugger"
   --debug.log(modules)
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
   --local debug = require "luci.commotion.debugger"
   --debug.log(modules)
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
   --local debug = require "luci.commotion.debugger"
   --debug.log(modules)
   mod = {}
   for i,x in pairs(modules) do
	  table.insert(mod, x)
   end
   table.insert(mod, 'complete')
   --debug.log(mod)
   return mod
end

