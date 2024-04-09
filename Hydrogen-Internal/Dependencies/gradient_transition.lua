local transitionDuration = 2.5
local transitionTime = 0

local function gradientTransition(startColors, endColors, UIGradient_Instance)
	while transitionTime < transitionDuration do
		local t = math.abs(transitionTime / transitionDuration)
		local lerpedColorSequence = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(
				startColors.Keypoints[1].Value.R * (1 - t) + endColors.Keypoints[1].Value.R * t,
				startColors.Keypoints[1].Value.G * (1 - t) + endColors.Keypoints[1].Value.G * t,
				startColors.Keypoints[1].Value.B * (1 - t) + endColors.Keypoints[1].Value.B * t
				)),
			ColorSequenceKeypoint.new(1, Color3.new(
				startColors.Keypoints[2].Value.R * (1 - t) + endColors.Keypoints[2].Value.R * t,
				startColors.Keypoints[2].Value.G * (1 - t) + endColors.Keypoints[2].Value.G * t,
				startColors.Keypoints[2].Value.B * (1 - t) + endColors.Keypoints[2].Value.B * t
				))
		})
		UIGradient_Instance.Color = lerpedColorSequence
		task.wait(0.01) -- Adjust the delay to control the smoothness of the transition
		transitionTime += 0.01
	end
	UIGradient_Instance.Color = endColors
	transitionTime = 0
end
