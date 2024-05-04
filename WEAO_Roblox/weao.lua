local a, b = pcall(function()
	game:GetService("CoreGui"):FindFirstChild("WhatExploitsAreOnline"):Destroy()
end)

local Template = loadstring(game:HttpGet("https://github.com/SpinnySpiwal/Public-Scripts/blob/main/WEAO_Roblox/ui.lua?raw=true"))()

local hRequest = (http and http.request or http_request) or request
local req = hRequest({
	Url = "https://whatexpsare.online/api/status",
	Method = "GET",
})

local getasset = getcustomasset or getsynasset
local isfolder = isfolder or syn_isfolder or is_folder
local makefolder = makefolder or make_folder or createfolder or create_folder

if not isfolder("WhatExploitsAreOnline") then
	local icon = hRequest({
		Url = "https://github.com/SpinnySpiwal/Public-Scripts/blob/main/WEAO_Roblox/assets/logo.png?raw=true",
		Method = "GET"
	});

	makefolder("WhatExploitsAreOnline")
	writefile("WhatExploitsAreOnline/Logo.png", icon.Body)
end

local Body = game:GetService("HttpService"):JSONDecode(req.Body)
ImageLabel.Image = getasset("./WhatExploitsAreOnline/Logo.png")

Template.Visible = false
local Template_Clone = Template:Clone()
Template_Clone.Parent = ScrollingFrame

for _, v in next, Body do
	local isUpdated = v.updateStatus == "updated"
	if isUpdated ~= nil and v ~= "ROBLOX" then
		Template_Clone = Template:Clone()
		Template_Clone.Visible = true
		Template_Clone.Parent = ScrollingFrame
	end

	Template_Clone.Visible = true
	Template_Clone.Name = tostring(i2)
	Template_Clone:FindFirstChild("Signal").BackgroundColor3 = (
		isUpdated and Color3.fromRGB(59, 234, 87) or Color3.fromRGB(237, 58, 71)
	)

	Template_Clone:FindFirstChild("Signal2").BackgroundColor3 = (
		isUpdated and Color3.fromRGB(59, 234, 87) or Color3.fromRGB(237, 58, 71)
	)

	Template_Clone:FindFirstChild("Title").Text = v.title
		.. " - "
		.. ((v.version ~= "null" and v.version ~= nil) and v.version or "Unknown")
	if isUpdated then
		local tClone = Template_Clone:FindFirstChild("Updated")
		tClone.Text = tostring(v.updatedDate):gsub("-", "/")
		tClone.Text = Template_Clone:FindFirstChild("Updated").Text .. " - Working"
	else
		local tClone = Template_Clone:FindFirstChild("Updated")
		tClone.Text = tostring(v.updatedDate):gsub("-", "/")
		tClone.Text = Template_Clone:FindFirstChild("Updated").Text .. " - Not Working"
	end
end

for i, v in next, game:GetService("CoreGui").WhatExploitsAreOnline:GetChildren() do
	v.Name = game:GetService("HttpService"):GenerateGUID()
end

game:GetService("UserInputService").InputBegan:Connect(function(x)
	if x.KeyCode == Enum.KeyCode.RightShift then
		sGUI.Enabled = not sGUI.Enabled
	end
end)
