local function generateRandomString(length)
    length = length or math.random(8, 15)
    local charset = ""
    for i = 1, 255 do
        charset = charset .. string.char(i)
    end
    local str = ""
    for _=1, length do
        local randIndex = math.random(1, #charset)
        local randChar = charset:sub(randIndex, randIndex)
        str = str .. randChar
    end
    return str
end

local sGUI = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local ImageLabel = Instance.new("ImageLabel")
local uCorner = Instance.new("UICorner")
local ScrollingFrame = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")
local Template = Instance.new("Frame")
local uCorner_2 = Instance.new("UICorner")
local signalOne = Instance.new("Frame")
local uCorner_3 = Instance.new("UICorner")
local signalTwo = Instance.new("Frame")
local uCorner_4 = Instance.new("UICorner")
local Title = Instance.new("TextLabel")
local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
local Updated = Instance.new("TextLabel")
local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
local tFolder = Instance.new("Folder")
sGUI.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
sGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Main.Name = "Main"
Main.Parent = sGUI
Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.375388443, 0, 0.234393403, 0)
Main.Size = UDim2.new(0.248601615, 0, 0.530035317, 0)

local uInputService = game:GetService("UserInputService")
local function makeDraggable(Frame)
	local dragSpeed = 0.50
	local startPos, dragPos
	dragToggle = nil
	dragInput, dragStart = nil, nil
	local function updateInput(input)
		local Delta = input.Position - dragStart
		local Position =
			UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
		game:GetService("TweenService")
			:Create(Frame, TweenInfo.new(0.30), {
				Position = Position,
			})
			:Play()
	end

	Frame.InputBegan:Connect(function(input)
		if
			(input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
			and uInputService:GetFocusedTextBox() == nil
		then
			dragToggle = true
			dragStart = input.Position
			startPos = Frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragToggle = false
				end
			end)
		end
	end)

	Frame.InputChanged:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragInput = input
		end
	end)

	uInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragToggle then
			updateInput(input)
		end
	end)
end

makeDraggable(Main)

ImageLabel.Parent = Main
ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageLabel.BackgroundTransparency = 1.000
ImageLabel.BorderSizePixel = 0
ImageLabel.Position = UDim2.new(0.30250001, 0, 0.0177777782, 0)
ImageLabel.Size = UDim2.new(0.395000011, 0, 0.300000012, 0)
ImageLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"

uCorner.Parent = Main

ScrollingFrame.Parent = Main
ScrollingFrame.Active = true
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ScrollingFrame.BackgroundTransparency = 1.000
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.Position = UDim2.new(0.102499999, 0, 0.364444435, 0)
ScrollingFrame.Size = UDim2.new(0.795000017, 0, 0.555555582, 0)
ScrollingFrame.ScrollBarThickness = 4

UIListLayout.Parent = ScrollingFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

Template.Name = "Template"
Template.Parent = tFolder
Template.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Template.BorderSizePixel = 0
Template.Position = UDim2.new(0, 0, 1.22070318e-07, 0)
Template.Size = UDim2.new(0.940220177, 0, 0.0717, 0)

uCorner_2.Parent = Template

signalOne.Name = "signalOne"
signalOne.Parent = Template
signalOne.BackgroundColor3 = Color3.fromRGB(59, 234, 87)
signalOne.BorderSizePixel = 0
signalOne.Position = UDim2.new(0.877449453, 0, 0.0874652416, 0)
signalOne.Size = UDim2.new(0.102482893, 0, 0.218880758, 0)

uCorner_3.Parent = signalOne

signalTwo.Name = "signalTwo"
signalTwo.Parent = Template
signalTwo.BackgroundColor3 = Color3.fromRGB(59, 234, 87)
signalTwo.BorderSizePixel = 0
signalTwo.Size = UDim2.new(0.0310558993, 0, 1, 0)

uCorner_4.Parent = signalTwo

Title.Name = "Title"
Title.Parent = Template
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1.000
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0.0683230758, 0, 0, 0)
Title.Size = UDim2.new(0.762793183, 0, 0.385714293, 0)
Title.Font = Enum.Font.Ubuntu
Title.Text = "Exploit Name"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.TextSize = 14.000
Title.TextWrapped = true
Title.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint.Parent = Title
UITextSizeConstraint.MaxTextSize = 20

Updated.Name = "Updated"
Updated.Parent = Template
Updated.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Updated.BackgroundTransparency = 1.000
Updated.BorderSizePixel = 0
Updated.Position = UDim2.new(0.0683230758, 0, 0.514285862, 0)
Updated.Size = UDim2.new(0.762793124, 0, 0.385714293, 0)
Updated.Font = Enum.Font.Ubuntu
Updated.Text = "Last Updated"
Updated.TextColor3 = Color3.fromRGB(255, 255, 255)
Updated.TextScaled = true
Updated.TextSize = 14.000
Updated.TextWrapped = true
Updated.TextXAlignment = Enum.TextXAlignment.Left

UITextSizeConstraint_2.Parent = Updated
UITextSizeConstraint_2.MaxTextSize = 20
sGUI.Parent = game:GetService("CoreGui")
sGUI.Name = generateRandomString()

return Template
