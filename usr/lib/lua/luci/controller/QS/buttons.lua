module("luci.controller.QS.buttons", package.seeall)

function index()
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

function quitter()
   local QS = luci.controller.QS.QS
   local uci = luci.model.uci.cursor()
   QS.log("Really, my quick start is not good enough for you eh? Well, you gotta do what you gotta do.")
   uci:set('quickstart', 'options', 'complete', 'true')
   uci:save('quickstart')
   uci:commit('quickstart')
   luci.http.redirect("http://"..luci.http.getenv("SERVER_NAME").."/cgi-bin/luci/")
   return {}
end

function finish(modules)
   --luci.controller.QS.QS.log(modules)
   mod = {}
   for i,x in pairs(modules) do
	  table.insert(mod, x)
   end
   table.insert(mod, 'complete')
   --luci.controller.QS.QS.log(mod)
   return mod
end

