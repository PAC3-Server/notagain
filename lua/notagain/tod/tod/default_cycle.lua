-- edit me!

local night = 
{	
	["sun_angles"] = Angle(-90, 45, 0),
	["moon_angles"] = -Angle(-90, 45, 0),
	["world_light_multiplier"] = 0,
	
	["color_brightness"] = 0,
	["color_contrast"] = 1,
	["color_saturation"] = 0.75,
	["color_multiply"] = Vector(-0.017, -0.005, 0.02),
	["color_add"] = Vector(0, 0, 0),
	
	["fog_start"] = 0,
	["fog_end"] = 14000,
	["fog_max_density"] = 0.25,
	["fog_color"] = Vector(0.25, 0.20, 0.30),
	
	["shadow_angles"] = Angle(-90, 45, 0),
	["shadow_color"] = Vector(0, 0, 0),
	
	["star_intensity"] = 1,
	
	["bloom_passes"] = 1,
	["bloom_color"] = Vector(1, 1, 1),
	["bloom_width"] = 1,
	["bloom_saturation"] = 1,
	["bloom_height"] = 1,
	["bloom_darken"] = 0,
	["bloom_multiply"] = 0,
	
	["sharpen_contrast"] = 0,
	["sharpen_distance"] = 0,
	
	["sky_topcolor"] = Vector(0, 0, 0),
	["sky_bottomcolor"] = Vector(0, 0, 0),
	["sky_fadebias"] = 1,
	["sky_sunsize"] = 0,
	["sky_sunnormal"] = Vector(0.4, 0, 0.01),
	["sky_suncolor"] = Vector(0.2, 0.1, 0),
	["sky_duskscale"] = 1,
	["sky_duskintensity"] = 1,
	["sky_duskcolor"] = Vector(0, 0, 0),
	["sky_starscale"] = 2,
	["sky_starfade"] = 1,
	["sky_starspeed"] = 0.005,
	["sky_hdrscale"] = 0.66,
}

local dusk = 
{
	["sun_angles"] = Angle(0, 45, 0),
	["moon_angles"] = -Angle(45, 45, 0),
	["world_light_multiplier"] = 0.53,
	
	["color_brightness"] = 0,
	["color_contrast"] = 1,
	["color_saturation"] = 1.1,
	["color_multiply"] = Vector(0.017, 0.005, -0.02),
	["color_add"] = Vector(0, 0, 0),
	
	["fog_start"] = 0,
	["fog_end"] = 10000,
	["fog_max_density"] = 1,
	["fog_color"] = Vector(1, 0.85, 0.6), 
	
	["shadow_angles"] = Angle(0, 45, 0),
	["shadow_color"] = Vector(0, 0, 0),
	
	["star_intensity"] = 0,
	
	["bloom_passes"] = 3,
	["bloom_color"] = Vector(1, 1, 1),
	["bloom_width"] = 5,
	["bloom_height"] = 5,
	["bloom_saturation"] = 0.25,
	["bloom_darken"] = 1,
	["bloom_multiply"] = 0,
	
	["sharpen_contrast"] = 0,
	["sharpen_distance"] = 0,
	
	["sky_topcolor"] = Vector(1, 1, 1),
	["sky_bottomcolor"] = Vector(1, 1, 1)*0,
	["sky_fadebias"] = 1,
	["sky_sunsize"] = 2,
	["sky_sunnormal"] = Vector(0, 0, 0),
	["sky_suncolor"] = Vector(0.5, 0.1, 0),
	["sky_duskscale"] = 7,
	["sky_duskintensity"] = 5,
	["sky_duskcolor"] = Vector(1, 0.2, 0),
	["sky_starscale"] = 0.5,
	["sky_starfade"] = 1,
	["sky_starspeed"] = 0.01,
	["sky_hdrscale"] = 0.66,
}

local day = 
{
	["sun_angles"] = Angle(90, 45, 0),
	["moon_angles"] = -Angle(90, 45, 0),
	["world_light_multiplier"] = 1,
	
	["color_brightness"] = 0,
	["color_contrast"] = 1,
	["color_saturation"] = 1,
	["color_multiply"] = Vector(0,0,0),
	["color_add"] = Vector(0, 0, 0),
	
	["fog_start"] = 0,
	["fog_end"] = 30000,
	["fog_max_density"] = -1,
	["fog_color"] = Vector(1,1,1), 
	
	["shadow_angles"] = Angle(0, 45, 0),
	["shadow_color"] = Vector(0, 0, 0),
	
	["star_intensity"] = 0,
	
	["bloom_passes"] = 3,
	["bloom_color"] = Vector(1, 1, 1),
	["bloom_width"] = 5,
	["bloom_height"] = 5,
	["bloom_saturation"] = 0.25,
	["bloom_darken"] = 1,
	["bloom_multiply"] = 0,
	
	["sharpen_contrast"] = 0,
	["sharpen_distance"] = 0,
	
	["sky_topcolor"] = Vector(0.125, 0.5, 1),
	["sky_bottomcolor"] = Vector(0.8, 1, 1),
	["sky_fadebias"] = 0.25,
	["sky_sunsize"] = 1,
	["sky_sunnormal"] = Vector(0, 0, 0),
	["sky_suncolor"] = Vector(0.2, 0.1, 0),
	["sky_duskscale"] = 0,
	["sky_duskintensity"] = -1,
	["sky_duskcolor"] = Vector(1, 0.2, 0),
	["sky_starscale"] = 0.5,
	["sky_starfade"] = 1,
	["sky_starspeed"] = 0.01,
	["sky_hdrscale"] = 0.66,
}

local dawn = 
{
	["sun_angles"] = Angle(90*2, 45, 0),
	["moon_angles"] = -Angle(90*2, 45, 0),
	["world_light_multiplier"] = 0.53,
	
	["color_brightness"] = 0,
	["color_contrast"] = 1,
	["color_saturation"] = 0.9,
	["color_multiply"] = Vector(0.017, -0.075, 0.01),
	["color_add"] = Vector(0, 0, 0),
	
	["fog_start"] = 0,
	["fog_end"] = 10000,
	["fog_max_density"] = -1,
	["fog_color"] = Vector(1,1,1), 
	
	["shadow_angles"] = Angle(0, 45, 0),
	["shadow_color"] = Vector(0, 0, 0),
	
	["star_intensity"] = 0,
	
	["bloom_passes"] = 3,
	["bloom_color"] = Vector(1, 1, 1),
	["bloom_width"] = 5,
	["bloom_height"] = 5,
	["bloom_saturation"] = 0.25,
	["bloom_darken"] = 1,
	["bloom_multiply"] = 0,
	
	["sharpen_contrast"] = 0,
	["sharpen_distance"] = 0,
	
	["sky_topcolor"] = Vector(1, 0.25, 1) * 0.25,
	["sky_bottomcolor"] = Vector(1, 0.5, 0.25),
	["sky_fadebias"] = 0,
	["sky_sunsize"] = 1,
	["sky_sunnormal"] = Vector(0, 0, 0),
	["sky_suncolor"] = Vector(0.2, 0.1, 0),
	["sky_duskscale"] = 2,
	["sky_duskintensity"] = 5,
	["sky_duskcolor"] = Vector(1, 0.1, 0.5),
	["sky_starscale"] = 0.5,
	["sky_starfade"] = 100,
	["sky_starspeed"] = 0.01,
	["sky_hdrscale"] = 0.66,
}

-- repeat to make the configs last longer
tod.SetConfigCycle(
	night, night, night, night, night, night, night, 
	dusk, 
	day,day,day,day,day, day, 
	dawn, 
	night, night
)