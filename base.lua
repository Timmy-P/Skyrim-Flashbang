local ThisModPath = ModPath

--[[File Path]]
local ThisOGG = ThisModPath.."sounds/heyyou.ogg"
local ThisTexture = "meme"

if blt.xaudio then
	blt.xaudio.setup()
else
	return
end

if not io.file_is_readable(ThisOGG) then
	return
end
local anti_spam = 0 --Debugging value
local ThisModIds = Idstring(ThisModPath):key()
local __Name = function(__id)
	return "BADMEMES_"..Idstring(tostring(__id).."::"..ThisModIds):key()
end

local XAudioBuffer = __Name("XAudioBuffer")
local XAudioSource = __Name("XAudioSource")
local _GName = __Name("_G")
_G[_GName] = _G[_GName] or {}
local ThisBitmap = __Name("ThisBitmap")
_G[ThisBitmap] = _G[ThisBitmap] or nil

local function is_FlashBMemes()
	return type(FlashBMemes) == "table" and type(FlashBMemes.Options) == "table" and type(FlashBMemes.Options.GetValue) == "function"
end

local function __ply_ogg()
	if io.file_is_readable(ThisOGG) then
		local __is_FlashBMemes = is_FlashBMemes()
		local __volume_start = __is_FlashBMemes and FlashBMemes.Options:GetValue("__volume_start") or 1
		local this_buffer = XAudio.Buffer:new(ThisOGG)
		local this_source = XAudio.UnitSource:new(XAudio.PLAYER)
		this_source:set_buffer(this_buffer)
		this_source:play()
		this_source:set_volume(__volume_start)
		_G[_GName][XAudioBuffer] = this_buffer
		_G[_GName][XAudioSource] = this_source
	end
	return
end

local function __end_ogg()
	if _G[_GName][XAudioSource] then
		--_G[_GName][XAudioSource]:close(true)
		--_G[_GName][XAudioSource] = nil
		_G[_GName][XAudioSource]:stop()
	end
	if _G[_GName][XAudioBuffer] then
		--_G[_GName][XAudioBuffer]:close(true)
		--_G[_GName][XAudioBuffer] = nil
		--_G[_GName][XAudioBuffer]:pause()
	end
	return
end

local function __ply_pic()
	if _G[ThisBitmap] then
		_G[ThisBitmap]:goto_frame(1)
		_G[ThisBitmap]:play()
		_G[ThisBitmap]:set_visible(true)
	end
	return
end

local function __end_pic()
	if _G[ThisBitmap] then
		_G[ThisBitmap]:set_visible(false)
		_G[ThisBitmap]:rewind()
		_G[ThisBitmap]:pause()
	end
	return
end

if CoreEnvironmentControllerManager then
	Hooks:PostHook(CoreEnvironmentControllerManager, "set_flashbang", __Name("set_flashbang"), function(self, duration)
		__end_ogg()
		__ply_ogg()
		__ply_pic()
		--managers.chat:_receive_message(managers.chat.GAME, "de_banger", "Flashed for " .. duration, Color(255, 0, 170, 255) / 255)
	end)
	Hooks:PostHook(CoreEnvironmentControllerManager, "_handle_screenflash", __Name("_handle_screenflash"), function(self, flashbang_value)
		--Debug solution to see the flashbang value
		--This function is called, like, a lot of times per second. This is a quick and dirty solution to print to chat once every 10 function calls
		--[[
		anti_spam = anti_spam + 1
		if anti_spam % 10 == 0 then
			managers.chat:_receive_message(managers.chat.GAME, "de_banger", "bang_val = ".. flashbang_value, Color(255, 0, 170, 255) / 255)
		end]]--

		--flashbang_value is tied to the opacity of the screen flash effect, I've found. Being lazy and just plugging it into the alpha
		--of the bitmap worked for me. Non-zero check is needed so avoid nil values.
		if flashbang_value >= 0 then
			_G[ThisBitmap]:set_alpha(flashbang_value)
			--Making sure not to override user preference on volume
			if flashbang_value < FlashBMemes.Options:GetValue("__volume_start") or flashbang_value < 1 then
				_G[_GName][XAudioSource]:set_volume(flashbang_value)
			end
			
			--Setting volume on a closed XAudio Source just crashes due to indexing a nil value. I instead disabled instances that
			--call the function that does so and instead just replay the audio as usual with little issue.
			--I'm keeping this here in case something props up in the future, or if you're reading this code and want to improve
			--it, this might be a good place to start. (Nexqua, I'm in your walls.)
			--if _G[_GName][XAudioSource]:close() == false then
				--_G[_GName][XAudioSource]:set_volume(flashbang_value)
			--end
		end
		
	end)
end
--is_closed() was just there this whole time I'm so sorry-
if PlayerDamage then
	Hooks:PostHook(PlayerDamage, "update", __Name("update"), function(self)
		if _G[_GName][XAudioSource]:is_closed ~= true _G[_GName][XAudioSource] and not _G[_GName][XAudioSource]:is_active() then
			--__end_ogg()
			__end_pic()
		end
	end)
	Hooks:PostHook(PlayerDamage, "_stop_tinnitus", __Name("_stop_tinnitus"), function(self)
		--__end_ogg()
		__end_pic()
	end)
	Hooks:PreHook(PlayerDamage, "pre_destroy", __Name("pre_destroy"), function(self)
		--__end_ogg()
		__end_pic()
	end)
end

if HUDManager then
	Hooks:PostHook(HUDManager, "_player_hud_layout", __Name("_player_hud_layout"), function(self)
		local name1 = __Name("name1")
		local panel1 = __Name("panel1")
		local bitmap1 = __Name("bitmap1")
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
		self[panel1] = self[panel1] or hud and hud.panel or self._ws:panel({name = name1})
		self[bitmap1] = self[panel1]:video({
			video = "meme",
			loop = true,
			alpha = 1
		})
		self[bitmap1]:set_size(self[panel1]:w(), self[panel1]:h())
		self[bitmap1]:set_visible(false)
		_G[ThisBitmap] = self[bitmap1]
	end)
end