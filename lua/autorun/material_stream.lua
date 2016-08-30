lib_materialstream = lib_materialstream or {}

local lib = lib_materialstream
local runSide, eSERVER, eCLIENT = {}, 0, 1
local function getSide() local i = 0 if ( CLIENT == true ) then i = 1 end return i end

lib.register_materials = {}
lib.materials = {}

function lib.register_material( url, id, param, dimension )
	table.insert( lib.register_materials, { url = url, id = id, param = param, dimension = dimension } )
end

include( "material_stream_registry.lua" )

runSide[eCLIENT] = function()
	function lib.get_renderobj()
		return lib_materialstream.client_renderobj and lib_materialstream.client_renderobj:IsValid() and lib_materialstream.client_renderobj
	end
	
	function lib.setup_renderobj()
		lib_materialstream.client_renderobj = vgui.Create( "HTML" )
		
		local ro = lib_materialstream.client_renderobj
		ro:SetPos( 0, 0 )
		ro:SetSize( 10, 10 )
		ro:SetVisible( false )
		
		return ro
	end
	
	function lib.generate_materials()
		lib.register_materials = {}
		lib.materials = {}
		
		if ( #lib.register_materials > 0 ) then
			local url = lib.register_materials[#lib.materials + 1]
			
			if (!url) then return end
			lib.process_url( url.url, url.id, url.param, url.dimension )
		end
	end
	
	function lib.process_url( url, id, param, dimension )
		lib.get_renderobj():OpenURL( url )
	
		local function proc( _, _, _, _ )
			timer.Simple( 1, function()
				local stream_material = lib.get_renderobj():GetHTMLMaterial()
			
				local stream_material_d =
				{
					["$basetexture"] = stream_material:GetName(),
					["$basetexturetransform"] = "center 0 0 scale " .. dimension.x .. " " .. dimension.y .. " rotate 0 translate 0 0",
				}
				
				lib.materials[id] = CreateMaterial( "material_stream_" .. id, "VertexLitGeneric", stream_material_d )
				
				local next_url = lib.register_materials[#lib.materials + 1]
				
				if (!next_url) then return end
				lib.process_url( next_url.next_url, url.id, next_url.param )
			end )
		end )
	
		http.Fetch( url, proc, proc )	
	end
	
	local ro = lib.get_renderobj()
	if ( ro ) then ro:Close() end
end

hook.Add( "InitPostEntity", "lib_materialstream exec side", function()
	side[getSide()]()
end )