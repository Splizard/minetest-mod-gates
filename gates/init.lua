-- gates
-- By Splizard
-- Forum post: https://forum.minetest.net/viewtopic.php?f=11&t=896

-- Quick documentation about the API
-- =================================:
--
-- Create new gate:
--
-- gates.register_gate(yourmod:gate, {
--     #shared node options go here
--
--	   description = "A Gate",
--     groups = {choppy=2,dig_immediate=2},
--     drop = "yourmod:gate", #Without this you can pick up open gates
--   
--     only_placer_can_open = false, #if true only the player who placed the gate can open it
--     open_on_rightclick = true, #open the gate when rightclicked.              
--
-- },
-- {
--     #open gate options go here
--
--     tile_images = {'open_gate.png'}, 
--	   walkable = false,
--     drawtype = "plantlike",
-- },
-- {
--     #closed gate options go here
--
--     tile_images = {'closed_gate_top.png','closed_gate_bottom.png','closed_gate_sides.png'}, 
--	   walkable = true,
-- },
-- })
--
gates = {}


--
-- Api functions
--

function gates.register_gate(name, def, open, closed)
	if name ~= nil then
		--Creates two nodes, open and closed node
		for i,v in pairs(def) do open[i] = v end
		
		for i,v in pairs(def) do closed[i] = v end
	
		local name_open = name.."_open"
		
		local open_gate = function(pos, node)
			minetest.swap_node(pos, {name=name_open, param2=node.param2})
		end
		
		local close_gate = function(pos, node)
			players = minetest.get_objects_inside_radius({y=pos.y-1, x=pos.x, z=pos.z}, 0.9)
			if #players > 0 then return end
			minetest.swap_node(pos, {name=name, param2=node.param2})
		end
		
		local function check_player_priv(pos, player)
			if not def.only_placer_can_open then
				return true
			end
			local meta = minetest.get_meta(pos)
			local pn = player:get_player_name()
			return meta:get_string("gates_owner") == pn
		end
		
		local on_right_click = function(pos, node, puncher)
			if not check_player_priv(pos, puncher) then
				return
			end
		
			if node.param2 then
				local playerpos = puncher:getpos()
				local dir = {x = pos.x - playerpos.x, y = pos.y - playerpos.y, z = pos.z - playerpos.z}
				local param = minetest.dir_to_facedir(dir)
				if node.param2 == 0 and param == 2 then node.param2 = 2 end
				if node.param2 == 2 and param == 0 then node.param2 = 0 end
				if node.param2 == 1 and param == 3 then node.param2 = 3 end
				if node.param2 == 3 and param == 1 then node.param2 = 1 end
			end
			
			if node.name == name then
				open_gate(pos, node)
			elseif node.name == name_open then
				close_gate(pos, node)
			end
			
			 --handle gates above this one
			local lpos = {x=pos.x, y=pos.y, z=pos.z}
			while true do
				lpos.y = lpos.y + 1
				local lnode = minetest.env:get_node(lpos)
				lnode.param2 = node.param2
				if lnode.name == node.name then
					if node.name == name then
						open_gate(lpos, lnode)
					elseif node.name == name_open then
						close_gate(lpos, lnode)
					end
				elseif lnode.name == name_open then
					if node.name == name then
						open_gate(lpos, lnode)
					elseif node.name == name_open then
						close_gate(lpos, lnode)
					end
				else
					break
				end
			end
		
			 --handle gates below this one
			local lpos = {x=pos.x, y=pos.y, z=pos.z}
			while true do
				lpos.y = lpos.y - 1
				local lnode = minetest.env:get_node(lpos)
				lnode.param2 = node.param2
				if lnode.name == node.name then
					if node.name == name then
						open_gate(lpos, lnode)
					elseif node.name == name_open then
						close_gate(lpos, lnode)
					end
				elseif lnode.name == name_open then
					if node.name == name then
						open_gate(lpos, lnode)
					elseif node.name == name_open then
						close_gate(lpos, lnode)
					end
				else break
				end
			end
		end
		
		if def.open_on_rightclick then
			open.on_rightclick = on_right_click
			closed.on_rightclick = on_right_click
		end
		
		if def.only_placer_can_open then
			closed.after_place_node = function(pos, placer, itemstack, pointed_thing)
				local pn = placer:get_player_name()
				local meta = minetest.get_meta(pos)
				meta:set_string("gates_owner", pn)
				meta:set_string("infotext", "Owned by "..pn)
			end
		end
		
		minetest.register_node(name.."_open", open)
		minetest.register_node(name, closed)
	else
		minetest.log(LOGLEVEL_ERROR,"GATES: in function \"gates.register_gate\": missing node name!")
	end
end

gates.register_node = function(name, shared, open, closed, mode)
	gates.register_gate(name, shared, open, closed)
	if mode then
		minetest.log(LOGLEVEL_INFO,"GATES: in function \"gates.register_node\": 'mode' depreciated!")
	end
end
