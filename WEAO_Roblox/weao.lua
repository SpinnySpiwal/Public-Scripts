local function generateRandomString(length)
	length = length or math.random(8, 15)
	local charset = ""
	for i = 1, 255 do
		charset = charset .. string.char(i)
	end
	local str = ""
	for _ = 1, length do
		local randIndex = math.random(1, #charset)
		local randChar = charset:sub(randIndex, randIndex)
		str = str .. randChar
	end
	return str
end

local a, b = pcall(function()
	game:GetService("CoreGui"):FindFirstChild(getgenv().weaoName):Destroy()
	getgenv().weaoName = nil
end)

local Template, ScrollingFrame, ImageLabel, sGUI, tFolder = loadstring(game:HttpGet("https://github.com/SpinnySpiwal/Public-Scripts/blob/main/WEAO_Roblox/ui.lua?raw=true"))()
local hRequest = (http and http.request or http_request) or request
local req = hRequest({
	Url = "https://whatexpsare.online/api/status",
	Method = "GET",
})

local getasset = getcustomasset
local isfolder = isfolder or is_folder
local makefolder = makefolder or make_folder or createfolder or create_folder

if not isfolder("WhatExploitsAreOnline") then
	local icon = hRequest({
		Url = "https://github.com/SpinnySpiwal/Public-Scripts/blob/main/WEAO_Roblox/assets/logo.png?raw=true",
		Method = "GET",
	})

	makefolder("WhatExploitsAreOnline")
	writefile("WhatExploitsAreOnline/Logo.png", icon.Body)
end

local Body = game:GetService("HttpService"):JSONDecode(req.Body)
ImageLabel.Image = getasset("./WhatExploitsAreOnline/Logo.png")

local Template_Clone = Template:Clone()
Template_Clone.Parent = ScrollingFrame

task.spawn(function()
	while wait(10) do
		for _, v in pairs(tFolder:GetChildren()) do if v.Name ~= "Template" the v:Destroy() end
		for _, exploitInfo in next, Body do
			local isUpdated = exploitInfo.updateStatus == "updated"
			if isUpdated ~= nil and exploitInfo ~= "ROBLOX" then
				Template_Clone = Template:Clone()
				Template_Clone.Visible = true
				Template_Clone.Parent = ScrollingFrame
			end

			Template_Clone.Visible = true
			Template_Clone.Name = generateRandomString()

			Template_Clone:FindFirstChild("signalOne").BackgroundColor3 = (
				isUpdated and Color3.fromRGB(59, 234, 87) or Color3.fromRGB(237, 58, 71)
			)
			Template_Clone:FindFirstChild("signalTwo").BackgroundColor3 = (
				isUpdated and Color3.fromRGB(59, 234, 87) or Color3.fromRGB(237, 58, 71)
			)

			Template_Clone:FindFirstChild("Title").Text = exploitInfo.title
				.. " - "
				.. ((exploitInfo.version ~= "null" and exploitInfo.version ~= nil) and exploitInfo.version or "Unknown")
			local tClone = Template_Clone:FindFirstChild("Updated")

			tClone.Text = tostring(exploitInfo.updatedDate):gsub("-", "/")
			tClone.Text = tClone.Text .. isUpdated and " - Working" or " - Not Working"
		end
	end
end)

for _, Inst in next, sGUI:GetChildren() do
	Inst.Name = generateRandomString()
end

local uInputService = game:GetService("UserInputService")

uInputService.InputBegan:Connect(function(x)
	if x.KeyCode == Enum.KeyCode.RightShift then
		sGUI.Enabled = not sGUI.Enabled
	end
end)
