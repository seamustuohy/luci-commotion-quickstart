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

