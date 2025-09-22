local ui = {}

local uis = game:GetService('UserInputService')
local txtservice = game:GetService('TextService')
local ts = game:GetService('TweenService')
local rs = game:GetService('RunService')
local hs = game:GetService('HttpService')

local HttpService = game:GetService("HttpService")
local ENABLE_TRACEBACK = false
local Signal = {}
do
	Signal.__index = Signal
	Signal.ClassName = "Signal"
    --[=[
        Returns whether a class is a signal
        @param value any
        @return boolean
    ]=]
	function Signal.isSignal(value)
		return type(value) == "table" and getmetatable(value) == Signal
	end
    --[=[
        Constructs a new signal.
        @return Signal<T>
    ]=]
	function Signal.new()
		local self = setmetatable({}, Signal)
		self._bindableEvent = Instance.new("BindableEvent")
		self._argMap = {}
		self._source = ENABLE_TRACEBACK and debug.traceback() or ""

		self._bindableEvent.Event:Connect(function(key)
			self._argMap[key] = nil
			if (not self._bindableEvent) and (not next(self._argMap)) then
				self._argMap = nil
			end
		end)
		return self
	end
    --[=[
        Fire the event with the given arguments. All handlers will be invoked. Handlers follow
        @param ... T -- Variable arguments to pass to handler
    ]=]
	function Signal:Fire(...)
		if not self._bindableEvent then
			warn(("Signal is already destroyed. %s"):format(self._source))
			return
		end
		local args = table.pack(...)
		local key = HttpService:GenerateGUID(false)
		self._argMap[key] = args
		self._bindableEvent:Fire(key)
	end
    --[=[
        Connect a new handler to the event. Returns a connection object that can be disconnected.
        @param handler (... T) -> () -- Function handler called when `:Fire(...)` is called
        @return RBXScriptConnection
    ]=]
	function Signal:Connect(handler)
		if not (type(handler) == "function") then
			error(("connect(%s)"):format(typeof(handler)), 2)
		end
		return self._bindableEvent.Event:Connect(function(key)
			local args = self._argMap[key]
			if args then
				handler(table.unpack(args, 1, args.n))
			else
				error("Missing arg data, probably due to reentrance.")
			end
		end)
	end
    --[=[
        Wait for fire to be called, and return the arguments it was given.
        @yields
        @return T
    ]=]
	function Signal:Wait()
		local key = self._bindableEvent.Event:Wait()
		local args = self._argMap[key]
		if args then
			return table.unpack(args, 1, args.n)
		else
			error("Missing arg data, probably due to reentrance.")
			return nil
		end
	end
    --[=[
        Disconnects all connected events to the signal. Voids the signal as unusable.
        Sets the metatable to nil.
    ]=]
	function Signal:Destroy()
		if self._bindableEvent then
			self._bindableEvent:Destroy()
			self._bindableEvent = nil
		end
		setmetatable(self, nil)
	end
end

local Connections = {}

local function Tween(frame,time,style,direction,props)
	local a = ts:Create(frame,TweenInfo.new(time,Enum.EasingStyle[style],Enum.EasingDirection[direction]),props)
	a:Play()
	return a
end
local function formatTable(t)
	local t = t or {}
	local new = {}
	for i,v in pairs(t) do
		new[tostring(i):lower()] = v
	end
	return new
end
local function create(className,options)
	local options = options or {}
	local inst = Instance.new(className)
	for i,v in pairs(options) do
		inst[i] = v
	end
	return inst
end
local function TabInsert(t,v)
	if not table.find(t,v) then
		table.insert(t,v)
	end
end
local function TabRemove(t,v)
	local a = table.find(t,v)
	if a then
		table.remove(t,a)
	end
end
local function Dragify(frame,frame2)
	local frame2 = frame2 or frame
	local dragging = false 
	local dragInput 
	local dragStart 
	local startPos 
	local function update(input) 
		local delta = input.Position - dragStart 
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end 
	frame2.InputBegan:Connect(function(input) 
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
			dragging = true 
			dragStart = input.Position 
			startPos = frame.Position 
			input.Changed:Connect(function() 
				if input.UserInputState == Enum.UserInputState.End then 
					dragging = false 
				end 
			end) 
		end 
	end) 
	frame2.InputChanged:Connect(function(input) 
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then 
			dragInput = input 
		end 
	end)
	uis.InputChanged:Connect(function(input) 
		if input == dragInput and dragging then 
			update(input) 
		end 
	end)
end
local function SetupFrame(frame,options)
	local options = formatTable(options)
	local uiCorner,stroke,list,pad
	if options.corner then
		local cornerOptions = formatTable(options.corner)
		uiCorner = create('UICorner',{
			Parent = frame,
			CornerRadius = cornerOptions.radius or UDim.new(),
		})
	end
	if options.stroke then
		local strokeOptions = formatTable(options.stroke)
		stroke = create('UIStroke',{
			Name = 'Stroke',
			Parent = frame,
			Thickness = 1,
			Transparency = 0,
			Color = strokeOptions.Color or Color3.fromRGB(40,40,40), -- ps it doesnt even change
			LineJoinMode = 'Round',
			ApplyStrokeMode = 'Contextual'
		})
	end
	if options.list then
		local listOptions = formatTable(options.list)
		list = create('UIListLayout',{
			Parent = frame,
			Padding = listOptions.pad or UDim.new(),
			FillDirection = listOptions.direction or 'Vertical',
			HorizontalAlignment = listOptions.horizontalalignment or 'Left',
			SortOrder = listOptions.order or 'LayoutOrder',
			VerticalAlignment = listOptions.verticalalignment or 'Top',
		})
	end
	if options.pad then
		local padOptions = formatTable(options.pad)
		pad = create('UIPadding',{
			Parent = frame,
			PaddingBottom = padOptions.bottom or UDim.new(),
			PaddingTop = padOptions.top or UDim.new(),
			PaddingRight = padOptions.right or UDim.new(),
			PaddingLeft = padOptions.left or UDim.new(),
		})
	end
	return uiCorner,stroke,list,pad
end
local function CreateElement(element) -- aka create holder
	local holder = element._holder
	local elementHolder = create('Frame',{
		Name = #holder:GetChildren()-(element._settingMenu and 0 or 3),
		Parent = holder,
		Size = UDim2.new(1,0,0,15),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = holder.ZIndex+1,
	})
	local holder = create('Frame',{
		Name = 'Holder',
		Parent = elementHolder,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = element._holderPosition or UDim2.new(0,80,0,0),
		Size = element._holderSize or UDim2.new(0,100,1,0),
		ZIndex = elementHolder.ZIndex+1,
	})
	SetupFrame(holder,{
		List = {Pad = UDim.new(0,5),Direction = 'Horizontal',horizontalalignment = 'Right',verticalalignment = 'Top'},
	})
	return holder
end
local function CreateSlider(frame,options)
	local options = formatTable(options)
	local side = options.side or 'X'
	local offset = side == 'Y' and 36 or 0

	local min = options.min or 0
	local max = options.max or 100
	local default = options.default or 0
	local float = options.float or 1

	local set = options.set or function() end


	local button = create('Frame',{
		Parent = frame,
		Name = 'Button',
		BackgroundTransparency = 1,
		Position = UDim2.new(),
		Size = UDim2.new(1,0,1,0),
		ZIndex = frame.ZIndex+1,
	})

	local function slide(input)
		local x = (input.Position[side]-frame.AbsolutePosition[side])/frame.AbsoluteSize[side]

		local value = ((max-min)*x)+min
		value = math.floor(value*(1/float))/(1/float)
		value = math.clamp(value,min,max)
		set(value)
	end
	set(default)
	local sliding = false
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = true
			slide(input)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = false
			slide(input)
		end
	end)
	uis.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and sliding then
			slide(input)
		end
	end)
	return button
end
local function CreateInput(textlabel,options)
	local textbox = create('TextBox',{
		Parent = textlabel.Parent,
		ClearTextOnFocus = false,
		Font = textlabel.Font,
		FontFace = textlabel.FontFace,
		LineHeight = textlabel.LineHeight,
		Position = textlabel.Position,
		Size = textlabel.Size,
		Text = textlabel.Text,
		TextColor3 = textlabel.TextColor3,
		TextScaled = textlabel.TextScaled,
		TextSize = textlabel.TextSize,
		Name = textlabel.Name,
		ZIndex = textlabel.ZIndex,
		BackgroundTransparency = textlabel.BackgroundTransparency,
		TextTransparency = textlabel.TextTransparency,
		TextXAlignment = textlabel.TextXAlignment,
		BorderSizePixel = textlabel.BorderSizePixel,
	})
	textlabel:Destroy()
	local options = formatTable(options)
	local callback = options.callback or function() end
	if options.focuses then
		textbox.Focused:Connect(function()
			callback(false,textbox.Text)
		end)
		textbox.FocusLost:Connect(function(a,b)
			callback(true,textbox.Text,a,b)
		end)
	else
		textbox:GetPropertyChangedSignal('Text'):Connect(function()
			callback(textbox.Text)
		end)
	end
	return textbox
end
-- im master of sphagetti code when it comes to uis LOL

local Elements = {}
Elements.__index = Elements

local function CombineTables(t,t2)
	local t3 = {}
	for i,v in pairs(t) do
		t3[i] = v
	end
	for i,v in pairs(t2) do
		t3[i] = v
	end

	return setmetatable(t3,Elements)
end
local Segment = {} -- i have no clue how to call it srry
Segment.__index = Segment
function Segment:CreateSegment(options)
	local options = formatTable(options)
	local holder = CreateElement(self)

	local elementsClass = {_holder = holder,_window = self._window,_sector = self._sector,_tabSector = self._tabSector,_segment = true}
	if options.name then
		elementsClass._title = true
		create('TextLabel',{
			Name = 'Title',
			Parent = holder.Parent,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 12),
			ZIndex = holder.ZIndex+1,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 12.000,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = options.name or ''
		})
	end
	return setmetatable(elementsClass,Elements)
end

function Elements:Colorpicker(options)
	local options = formatTable(options)
	local mainHolder = self._holder
	if not self._segment then
		mainHolder = CreateElement(self)
	end
	if not mainHolder.Parent:FindFirstChild('Title') then
		create('TextLabel',{
			Name = 'Title',
			Parent = mainHolder.Parent,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 12),
			ZIndex = mainHolder.ZIndex+1,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 12.000,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = options.name or ''
		})
	end
	local sector = self._tabSector
	local zindexadd = 300+300*#sector:GetChildren()
	local colorpickerIcon = create('ImageLabel',{
		Parent = mainHolder,
		Name = (10-#mainHolder:GetChildren()),
		BackgroundTransparency = 1.000,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 46, 0, 0),
		Size = UDim2.new(0, 15, 0, 15),
		ZIndex = mainHolder.ZIndex+1,
		Image = "http://www.roblox.com/asset/?id=14259665095",
		ImageColor3 = Color3.fromRGB(200, 200, 200),
		SliceScale = 4.000,
	})
	local scroll = self._tabSector
	local scrollY = scroll.CanvasSize.Y.Offset
	
	local edgeX = scroll.AbsolutePosition.X+scroll.AbsoluteSize.X
	local sizex = 125
	local offset = 15

	local posX = ((colorpickerIcon.AbsolutePosition.X+offset >= edgeX or colorpickerIcon.AbsolutePosition.X+offset+sizex >= edgeX) and -(sizex+offset) or offset+(colorpickerIcon.AbsoluteSize.X/2))
	local posY = math.clamp(colorpickerIcon.AbsolutePosition.Y-60,scroll.AbsolutePosition.Y,scroll.AbsolutePosition.Y+scrollY)

	local colorpickerFrame = create('Frame',{
		Name = 'ColorpickerFrame',
		Parent = colorpickerIcon,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, posX, 0, posY-colorpickerIcon.AbsolutePosition.Y+2),
		Size = UDim2.new(0, sizex, 0, 135),
		ZIndex = zindexadd+1,
		Visible = false,
	})
	SetupFrame(colorpickerFrame,{corner = {radius = UDim.new(0,4)},stroke = {}})
	local button = create('TextButton',{
		Parent = colorpickerIcon,
		Size = UDim2.new(1,0,1,0),
		TextTransparency = 1,
		BackgroundTransparency = 1,
		ZIndex = zindexadd+1
	})
	button.MouseButton1Down:Connect(function()
		colorpickerFrame.Visible = not colorpickerFrame.Visible
	end)
	
	scroll:GetPropertyChangedSignal('CanvasSize'):Connect(function()
		scrollY = scroll.CanvasSize.Y.Offset
		posY = math.clamp(colorpickerIcon.AbsolutePosition.Y-60,scroll.AbsolutePosition.Y,scroll.AbsolutePosition.Y+scrollY)
		colorpickerFrame.Position = UDim2.new(0, posX, 0, posY-colorpickerIcon.AbsolutePosition.Y+2)
	end)
	
	-- 5 fucking frames 3 textlables and 1 image i fucking hate colorpicker i made
	local mainColorpicker = create('Frame',{
		Name = 'Colorpicker',
		Parent = colorpickerFrame,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 5, 0, 5),
		Size = UDim2.new(0, 100, 0, 90),
		ZIndex = zindexadd+2,
	})
	SetupFrame(mainColorpicker,{Corner = {radius = UDim.new(0,4)}})
	local image = create('ImageLabel',{
		ZIndex = zindexadd+3,
		Parent = mainColorpicker,
		Image = 'rbxassetid://4155801252',
		Size = UDim2.new(1,0,1,0)
	})

	local hue = create('Frame',{
		Name = 'Hue',
		Parent = colorpickerFrame,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 5, 0, 100),
		Size = UDim2.new(0, 115, 0, 11),
		ZIndex = zindexadd+2,
	})
	SetupFrame(hue,{corner = {radius = UDim.new(0,4)}})
	create('UIGradient',{
		Parent = hue,
		Enabled = true,
		Rotation = 0,
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), 
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)), 
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), 
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)), 
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)), 
			ColorSequenceKeypoint.new(0.82, Color3.fromRGB(255, 0, 255)), 
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
		}
	})
	local alpha = create('ImageLabel',{
		Name = 'Alpha',
		Parent = colorpickerFrame,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 110, 0, 5),
		Size = UDim2.new(0, 10, 0, 90),
		ZIndex = zindexadd+2,
		Image = "rbxassetid://14248403322",
	})


	local alphaslideFrame = create('Frame',{
		BackgroundTransparency = 1,
		Parent = alpha,
		Size = UDim2.new(1,0,1,-2)
	})
	local alphapicker = create('Frame',{
		Parent = alphaslideFrame,
		BorderSizePixel = 1,
		Size = UDim2.new(1,-2,0,2),
		Position = UDim2.new(0,1,0,0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = zindexadd+4
	})

	local hueslideFrame = create('Frame',{
		BackgroundTransparency = 1,
		Parent = hue,
		Size = UDim2.new(1,-2,1,0)
	})
	local huepicker = create('Frame',{
		Parent = hueslideFrame,
		BorderSizePixel = 1,
		Size = UDim2.new(0,2,1,-2),
		Position = UDim2.new(0,0,0,1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = zindexadd+4
	})

	local colorpickerSlide = create('Frame',{
		Parent = mainColorpicker,
		Name = 'SlideFrame',
		Size = UDim2.new(1,-3,1,-3),
		Position = UDim2.new(0,1,0,1),
		BackgroundTransparency = 1,
	})
	local colorpointer = create('Frame',{
		Parent = colorpickerSlide,
		Name = 'Picker',
		Size = UDim2.new(0,6,0,6),
		Position = UDim2.new(),
		BorderSizePixel = 1,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = zindexadd+4
	})

	local inputs = {}
	for i=1,3 do -- i am NOT doing 3 20 lines of code
		local mainFrame = create('Frame',{
			Name = tostring(i),
			Parent = colorpickerFrame,
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BackgroundTransparency = 0.500,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 6+(39*(i-1)), 0, 116),
			Size = UDim2.new(0, 35, 0, 14),
			ZIndex = zindexadd+2,
		})
		local a = create('TextLabel',{
			Name = tostring(i),
			Parent = mainFrame,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 1, 0, 0),
			Size = UDim2.new(1, 0, 1, -1),
			ZIndex = zindexadd+3,
			Font = Enum.Font.Gotham,
			Text = "255",
			TextColor3 = Color3.fromRGB(180, 180, 180),
			TextSize = 11.000,
			TextWrapped = true,
		})
		SetupFrame(mainFrame,{corner = {radius = UDim.new(0,4)},pad = {top = UDim.new(0,1),bottom = UDim.new(0,1),left = UDim.new(0,8),right = UDim.new(0,8)},stroke = {}})
		table.insert(inputs,a)
	end
	local window = self._window
	local callback = options.callback or function() end
	local flag = options.flag; if not flag then window._undefinedFlags += 1; flag = 'undefined_'..window._undefinedFlags end
	local callback = options.callback or function() end


	local default = {Color = Color3.fromRGB(255, 255, 255),Alpha = 0}
	if options.default then
		if typeof(options.default) == 'Color3' then
			default.Color = options.default
		elseif typeof(options.default) == 'table' then
			default = options.default
		end
	end
	window.flags[flag] = {Color = default.Color,Alpha = default.Alpha or 0}
	local h,s,v = default.Color:ToHSV()
	
	local a = default.Alpha or 0
	
	local function set(color,setpos)
		local newhue,newsat,newval = color:ToHSV()

		if setpos then
			h = newhue
			s = newsat
			v = newval

			alphapicker.Position = UDim2.new(0,1,a,0)
			huepicker.Position = UDim2.new(h,0,0,1)
			colorpointer.Position = UDim2.new(1-s,-3,1-v,-3)
		end
		image.ImageColor3 = Color3.fromHSV(h,1,1)

		alpha.BackgroundColor3 = Color3.fromHSV(h,1,1)

		inputs[1].Text = math.floor(color.R*255) 
		inputs[2].Text = math.floor(color.G*255)
		inputs[3].Text = math.floor(color.B*255) 

		window.flags[flag].Color = color
		window.flags[flag].Alpha = a
		callback(window.flags[flag])
	end
	local function SetA(newa)
		a = newa
		alphapicker.Position = UDim2.new(0,1,a,0)
		set(Color3.fromHSV(h,1-s,1-v))
	end
	local function SetH(value)
		h = value
		huepicker.Position = UDim2.new(h,0,0,1)
		set(Color3.fromHSV(h,1-s,1-v))
	end
	local function SetS(value)
		s = value
		colorpointer.Position = UDim2.new(s,-3,v,-3)
		set(Color3.fromHSV(h,1-s,1-v))
	end
	local function SetV(value)
		v = value
		colorpointer.Position = UDim2.new(s,-3,v,-3)
		set(Color3.fromHSV(h,1-s,1-v))
	end

	CreateSlider(alphaslideFrame,{side = 'Y',min=0,max=1,float=0.01,default=0,set=SetA})
	CreateSlider(hueslideFrame,{side = 'X',min=0,max=1,float=0.01,default=0,set=SetH})

	CreateSlider(colorpickerSlide,{side = 'X',min=0,max=1,float=0.01,default=0,set=SetS})
	CreateSlider(colorpickerSlide,{side = 'Y',min=0,max=1,float=0.01,default=0,set=SetV})

	set(default.Color,true)

	local r,g,b


	local textbox;textbox = CreateInput(inputs[1],{focuses = true,callback = function(a,text,b,c)
		if not a then
			r = text
		else
			if tonumber(text) then
				set(Color3.fromRGB(text,inputs[2].Text,inputs[3].Text),true)
			else
				textbox.Text = r
			end
		end
	end})
	inputs[1] = textbox
	local textbox;textbox = CreateInput(inputs[2],{focuses = true,callback = function(a,text,b,c)
		if not a then
			g = text
		else
			if tonumber(text) then
				set(Color3.fromRGB(inputs[1].Text,text,inputs[3].Text),true)
			else
				textbox.Text = g
			end
		end
	end})
	inputs[2] = textbox
	local textbox;textbox = CreateInput(inputs[3],{focuses = true,callback = function(a,text,b,c)
		if not a then
			b = text
		else
			if tonumber(text) then
				set(Color3.fromRGB(inputs[1].Text,inputs[2].Text,text),true)
			else
				textbox.Text = b
			end
		end
	end})
	inputs[3] = textbox
	
	local function SetValue(color)
		a = typeof(color) == 'table' and color.Alpha or 0
		local color = typeof(color) == 'table' and color.Color or color
		set(color,true)
	end
	
	window._FlagsSet[flag] = SetValue
	
	local newmt = table.clone(self)
	newmt._holder = mainHolder
	newmt._segment = true
	setmetatable(newmt,Elements)
	return setmetatable({Set = SetValue},{__index = newmt})

end
function Elements:Settings(options)
	local options = formatTable(options)
	
	local mainHolder = self._holder
	if not self._segment then
		mainHolder = CreateElement(self)
	end
	if not mainHolder.Parent:FindFirstChild('Title') then
		create('TextLabel',{
			Name = 'Title',
			Parent = mainHolder.Parent,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 12),
			ZIndex = mainHolder.ZIndex+1,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 12.000,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = options.name or ''
		})
	end
	local scroll = self._tabSector

	local edgeX = scroll.AbsolutePosition.X+scroll.AbsoluteSize.X
	
	local zindexadd = 200+#self._sector:GetChildren()*200
	local settingIcon = create('ImageLabel',{
		Parent = mainHolder,
		Name = (10-#mainHolder:GetChildren()),
		BackgroundTransparency = 1.000,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 46, 0, 0),
		Size = UDim2.new(0, 15, 0, 15),
		ZIndex = mainHolder.ZIndex+1,
		Image = "http://www.roblox.com/asset/?id=14259672152",
		ImageColor3 = Color3.fromRGB(200, 200, 200),
		SliceScale = 4.000,
	})
	local sizex = 150
	local offset = 10
	
	local posX = ((settingIcon.AbsolutePosition.X+offset >= edgeX or settingIcon.AbsolutePosition.X+offset+sizex >= edgeX) and -(sizex+offset) or offset+(settingIcon.AbsoluteSize.X/2))
	local posY = math.clamp(settingIcon.AbsolutePosition.Y,scroll.AbsolutePosition.Y,scroll.AbsolutePosition.Y+scroll.AbsoluteSize.Y)
	
	local button = create('TextButton',{
		Parent = settingIcon,
		Name = 'Button',
		Size = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1,
		TextTransparency = 1,
		ZIndex = mainHolder.ZIndex+2,
	})
	local settingFrame = create('Frame',{
		Name = 'Setting',
		Parent = settingIcon,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0,
		Position = UDim2.new(0, posX, 0, posY-settingIcon.AbsolutePosition.Y+2),
		Size = UDim2.new(0, sizex, 0, 10),
		ZIndex = zindexadd,
		Visible = false,
	})
	SetupFrame(settingFrame,{Corner = {radius = UDim.new(0, 4)},stroke = {}})
	button.MouseButton1Down:Connect(function()
		settingFrame.Visible = not settingFrame.Visible
	end)
	local settingsHolder = create('Frame',{
		Parent = settingFrame,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = zindexadd+1,
	})
	SetupFrame(settingsHolder,
		{
			list = {pad = UDim.new(0,5),directing = 'Vertical',horizontalalignment = 'Left',verticalalignment = 'Top'},
			pad = {bottom = UDim.new(0,5),top = UDim.new(0,5),left = UDim.new(0,6), right = UDim.new(0,6)}
		}
	)

	local list = settingsHolder.UIListLayout
	local function UpdatePos()
		local contentSize = list.AbsoluteContentSize.Y + 25

		local posY = math.clamp(settingIcon.AbsolutePosition.Y+(-contentSize/2+7),scroll.AbsolutePosition.Y,scroll.AbsolutePosition.Y+scroll.AbsoluteSize.Y)

		settingFrame.Size = UDim2.new(0,sizex,0,contentSize)
		settingFrame.Position = UDim2.new(0, posX, 0, posY-settingIcon.AbsolutePosition.Y+2)	
	end
	list:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(UpdatePos)
	scroll:GetPropertyChangedSignal('CanvasSize'):Connect(UpdatePos)
	return setmetatable(
		{
			_holder = settingsHolder,
			_window = self._window,
			_tabSector = self._tabSector,
			_sector = self._sector,
			_settingMenu = true,
			_holderSize = UDim2.new(1,-60,1,0),
			_holderPosition = UDim2.new(1,-80,0,0)
		},
		{__index = Elements}
	)
end
function Elements:Title(options)
	local options = formatTable(options)
	local oldMainholder = CreateElement(self)
	local mainHolder = oldMainholder.Parent
	oldMainholder:Destroy() 

	local title = options.title or ''
	local description = options.description

	if description then
		mainHolder.Size = UDim2.new(1, 0, 0, 28)
	end 

	SetupFrame(mainHolder,{
		list = {Pad = UDim.new(0,4),direction = 'Vertical',horizontalalignment = 'Left',verticalalignment = 'Center'}
	})
	create('TextLabel',{
		Parent = mainHolder,
		Name = 'Title',
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, description and 12 or 15),
		ZIndex = mainHolder.ZIndex+1,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title
	})

	if description then
		create('TextLabel',{
			Parent = mainHolder,
			Name = 'Description',
			LayoutOrder = 2,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 12),
			ZIndex = mainHolder.ZIndex+1,
			Font = Enum.Font.Gotham,
			Text = description,
			TextColor3 = Color3.fromRGB(108, 108, 108),
			TextSize = 12.000,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end
end
function Elements:Toggle(options)
	local options = formatTable(options)
	local mainHolder = self._holder

	if not self._segment then
		mainHolder = CreateElement(self)
	end
	if not mainHolder.Parent:FindFirstChild('Title') then
		create('TextLabel',{
			Name = 'Title',
			Parent = mainHolder.Parent,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 12),
			ZIndex = mainHolder.ZIndex+1,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 12.000,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = options.name or ''
		})
	end
	local toggle = create('Frame',{
		Name = 'Toggle',
		LayoutOrder = (10-#mainHolder:GetChildren()),
		Parent = mainHolder,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.5,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(0, 33, 1, 0),
		ZIndex = mainHolder.ZIndex+2,
	})
	SetupFrame(toggle,{
		corner = {radius = UDim.new(1,0)},
		pad = {bottom = UDim.new(0,1),top = UDim.new(0,1),right = UDim.new(0,1),left = UDim.new(0,1)},
		stroke = {}
	})
	local circle = create('Frame',{
		Name = 'Circle',
		Parent = toggle,
		BackgroundColor3 = Color3.fromRGB(125, 125, 125),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 1, 0, 0),
		Size = UDim2.new(0, 12, 1, 0),
		ZIndex = mainHolder.ZIndex+3,
	})
	local btn = create('TextButton',{
		Name = 'Callback Handler',
		Parent = toggle,
		BackgroundTransparency = 1,
		Text = '',
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = mainHolder.ZIndex+4,
	})
	SetupFrame(circle,{corner = {radius = UDim.new(1,0)}})

	local window = self._window
	local flag = options.flag; if not flag then window._undefinedFlags += 1; flag = 'undefined_'..window._undefinedFlags end
	local callback = options.callback or function() end
	window.flags[flag] = (options.default ~= nil)

	local function OnCallback()
		if window.flags[flag] then
			Tween(circle,0.25,'Quad','Out',{BackgroundColor3 = Color3.new(1, 1, 1),Position = UDim2.new(1, -13, 0,0)})
		else
			Tween(circle,0.25,'Quad','Out',{BackgroundColor3 = Color3.fromRGB(125, 125, 125),Position = UDim2.new(0, 1,0,0)})
		end
		--Tween(circle,0.25,'Quad','Out',{BackgroundColor3 = (window.flags[flag] and Color3.new(1, 1, 1) or Color3.fromRGB(125, 125, 125)),Position = UDim2.new(window.flags[flag] and 1 or 0, window.flags[flag] and -13 or 1,0,0)})
		callback(window.flags[flag])
	end
	local function Set(val)
		window.flags[flag] = val
		OnCallback()
	end
	Set(window.flags[flag])
	local _ = toggle.AbsolutePosition -- abs position doesnt get updated until indexes lmao
	btn.MouseButton1Down:Connect(function() Set(not window.flags[flag]) end)
	
	window._FlagsSet[flag] = Set
	
	local newmt = table.clone(self)
	newmt._holder = mainHolder
	newmt._segment = true
	setmetatable(newmt,Elements)
	return setmetatable({Set = Set},{__index = newmt})
end
function Elements:Input(options)
	local options = formatTable(options)
	local mainHolder = self._holder

	if not self._segment then
		mainHolder = CreateElement(self)
	end
	if not mainHolder.Parent:FindFirstChild('Title') then
		create('TextLabel',{
			Name = 'Title',
			Parent = mainHolder.Parent,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 12),
			ZIndex = mainHolder.ZIndex+1,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 12.000,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = options.name or ''
		})
	end
	local window = self._window
	local callback = options.callback or function() end
	local flag = options.flag; if not flag then window._undefinedFlags += 1; flag = 'undefined_'..window._undefinedFlags end
	local input = create('Frame',{
		Name = 'Input',
		LayoutOrder = (10-#mainHolder:GetChildren()),
		Parent = mainHolder,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(0, 100, 1, 0),
		ZIndex = mainHolder.ZIndex+2,
	})
	SetupFrame(input,{pad = {Bottom = UDim.new(0,1),top = UDim.new(0,1),right = UDim.new(0,8),left = UDim.new(0,8)},corner = {radius = UDim.new(1,0)},stroke = {}})
	local inputTextlabel = create('TextLabel',{
		Parent = input,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = mainHolder.ZIndex+3,
		Font = Enum.Font.Gotham,
		Text = "0",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextSize = 14,
		TextWrapped = true,
	})
	local function set(text)
		inputTextlabel.Text = text
		window.flags[flag] = text
		callback(text)
	end
	inputTextlabel = CreateInput(inputTextlabel,{focuses = options.focuses,callback = function(...)
		window.flags[flag] = inputTextlabel.Text
		callback(...)
	end,})
	
	window._FlagsSet[flag] = set
	
	local newmt = table.clone(self)
	newmt._holder = mainHolder
	newmt._segment = true
	setmetatable(newmt,Elements)
	
	return setmetatable({Set = set},{__index = newmt})
end
function Elements:Slider(options)
	local options = formatTable(options)
	local mainHolder = self._holder

	local window = self._window
	local flag = options.flag; if not flag then window._undefinedFlags += 1; flag = 'undefined_'..window._undefinedFlags end
	local callback = options.callback or function() end
	local min = options.min or 0
	local max = options.max or 100
	local default = options.default or min
	local float = options.float or 1
	local showvalue = true
	if options.showvalue == false then showvalue = false end


	if not self._segment then
		mainHolder = CreateElement(self)
	end
	if not mainHolder.Parent:FindFirstChild('Title') then
		create('TextLabel',{
			Name = 'Title',
			Parent = mainHolder.Parent,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 12),
			ZIndex = mainHolder.ZIndex+1,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 12.000,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = options.name or ''
		})
	end

	local SlideHolder = create('Frame',{
		Name = 'Slider',
		LayoutOrder = (10-#mainHolder:GetChildren()),
		Parent = mainHolder,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 1.000,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 70+(showvalue and txtservice:GetTextSize(tostring(max),12,Enum.Font['GothamMedium'],Vector2.new(math.huge,math.huge)).X+5 or 0), 1, 0),
		ZIndex = mainHolder.ZIndex+2,
	})
	SetupFrame(SlideHolder,{pad = {bottom = UDim.new(0,1),top = UDim.new(0,1),left = UDim.new(0,1),right = UDim.new(0,1)},corner = {radius = UDim.new(1,0)}})
	local slider = create('Frame',{
		Name = 'Slide',
		Parent = SlideHolder,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -65, 0.5, -1),
		Size = UDim2.new(0, 60, 0, 2),
		ZIndex = mainHolder.ZIndex+3
	})
	local circle = create('Frame',{
		Parent = slider,
		Name = 'Circle',
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.new(0, -5, 0, 6),
		Size = UDim2.new(0, 12, 0, 12),
		ZIndex = mainHolder.ZIndex+3
	})
	SetupFrame(circle,{corner = {radius = UDim.new(1,0)}})
	SetupFrame(slider,{corner = {radius = UDim.new(1,0)}})

	local textLabel;
	if showvalue then
		textLabel = create('TextLabel',{
			Parent = SlideHolder,
			Name = 'Counter',
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(0, txtservice:GetTextSize(tostring(max),12,Enum.Font['GothamMedium'],Vector2.new(math.huge,math.huge)).X, 1, 0),
			ZIndex = SlideHolder.ZIndex+1,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 12.000,
			TextXAlignment = 'Right'
		})
	end
	local function set(newval)
		newval = math.clamp(newval,min,max)

		circle.Position = UDim2.new((newval-min)/(max-min),-3,0,-6)

		if textLabel then
			textLabel.Text = tostring(newval)
		end
		window.flags[flag] = newval
		callback(newval)
	end

	local a = CreateSlider(slider,{min = min,max = max,default = default,float = float,side = 'X',set = set})
	a.Position = UDim2.new(0,0,0,-6)
	a.Size = UDim2.new(0,60,0,12)

	set(default)
	
	window._FlagsSet[flag] = set
	
	local newmt = table.clone(self)
	newmt._holder = mainHolder
	newmt._segment = true
	setmetatable(newmt,Elements)
	return setmetatable({
		Set = set,
		
	},{__index = newmt})
end
function Elements:Dropdown(options)
	local options = formatTable(options)
	local mainHolder = self._holder

	if not self._segment then
		mainHolder = CreateElement(self)
	end
	if not mainHolder.Parent:FindFirstChild('Title') then
		create('TextLabel',{
			Name = 'Title',
			Parent = mainHolder.Parent,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 12),
			ZIndex = mainHolder.ZIndex+1,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 12.000,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = options.name or ''
		})
	end
	local choices = options.options or {}
	local current = options.default or {}

	local min = options.min or 0
	local max = options.max or #choices

	if min>max then error('kill yourself (min is bigger than max)',2) end
	
	local currentChild = #self._sector:GetChildren()
	local zindexadd = 100
	
	local dropdownHolder = create('Frame',{
		Parent = mainHolder,
		Name = 'Dropdown',
		LayoutOrder = (10-#mainHolder:GetChildren()),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(0, 90, 1, 0),
		ZIndex = zindexadd,
	})
	SetupFrame(dropdownHolder,{Corner = {radius = UDim.new(0,2)},stroke = {}})

	local btn = create('TextButton',{
		Parent = dropdownHolder,
		Name = 'Handler',
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = zindexadd+1,
		Text = '',
		TextTransparency = 1,
	})

	local choiceText = create('TextLabel',{
		Parent = dropdownHolder,
		Name = 'Choice',
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 5, 0, 2),
		Size = UDim2.new(1, -20, 0, 9),
		ZIndex = zindexadd+1,
		Font = Enum.Font.Gotham,
		Text = '',
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	local arrow = create('ImageLabel',{
		Parent = dropdownHolder,
		Name = 'Arrow',
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -12, 0, 5),
		Size = UDim2.new(0, 7, 0, 4),
		ZIndex = dropdownHolder.ZIndex+1,
		Image = "http://www.roblox.com/asset/?id=14259608577",
		ImageColor3 = Color3.fromRGB(200, 200, 200),
	})
	dropdownHolder:GetPropertyChangedSignal('ZIndex'):Connect(function()
		arrow.ZIndex = dropdownHolder.ZIndex+1
	end)
	local optionsHolder = create('ScrollingFrame',{
		Parent = dropdownHolder,
		Name = 'OptionsHolder',
		Active = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 17),
		Size = UDim2.new(1, 0, 0, 73),
		Visible = false,
		ZIndex = zindexadd+1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = 'Y',
		ScrollBarImageTransparency = 1,
	})
	SetupFrame(optionsHolder,{list = {pad = UDim.new(0,5),direction = 'Vertical',horizontalalignment = 'Left',verticalalignment = 'Top'},pad = {Top = UDim.new(0,1),Bottom = UDim.new(0,1),right = UDim.new(0,4),left = UDim.new(0,4)}})

	local window = self._window
	local flag = options.flag; if not flag then window._undefinedFlags += 1; flag = 'undefined_'..window._undefinedFlags end
	local callback = options.callback or function() end
	
	local function Update()
		local str = ''
		if #current == 0 then str = 'None' choiceText.TextColor3 = Color3.fromRGB(125,125,125) else
			choiceText.TextColor3 = Color3.fromRGB(255,255,255)
			for i,v in pairs(current) do
				local len = txtservice:GetTextSize(v,choiceText.TextSize,Enum.Font.Gotham,choiceText.AbsoluteSize).X
				if txtservice:GetTextSize(str,choiceText.TextSize,Enum.Font.Gotham,choiceText.AbsoluteSize).X + len >= choiceText.AbsoluteSize.X-7 then
					str = str..'...'
					break
				end
				str = str..tostring(v)..(#current ~= 1 and (i==#current and '' or ', ') or '')
			end
		end
		choiceText.Text = str

		window.flags[flag] = (max == 1 and current[1] or current)
		callback(window.flags[flag])
	end
	Update()
	
	local ChosenFrames = {}
	local FramesChosen = {}
	local function OnClick(frame) -- last time it took like a day or something
		if not FramesChosen[frame] then
			if #ChosenFrames == max then -- causes double update + stack overflow otherwise
				local frame = ChosenFrames[1]
				Tween(frame,0.25,'Quad','In',{TextColor3 = Color3.fromRGB(125, 125, 125)})
				TabRemove(current,frame.Text)
				TabRemove(ChosenFrames,frame)
				FramesChosen[frame] = false
			end
			Tween(frame,0.25,'Quad','In',{TextColor3 = Color3.fromRGB(255, 255, 255)})
			TabInsert(current,frame.Text)
			TabInsert(ChosenFrames,frame)
			FramesChosen[frame] = true
		else -- trying to remove
			if #current <= min then return end
			Tween(frame,0.25,'Quad','In',{TextColor3 = Color3.fromRGB(125, 125, 125)})
			TabRemove(current,frame.Text)
			TabRemove(ChosenFrames,frame)
			FramesChosen[frame] = false
		end
		Update()
	end
	local indx = 1
	local choicesholders = {}
	for i,v in pairs(choices) do
		local frame = create('TextLabel',{
			Parent = optionsHolder,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -5, 0, 12),
			ZIndex = zindexadd+11,
			Font = Enum.Font.Gotham,
			Text = tostring(v),
			TextColor3 = Color3.fromRGB(125, 125, 125),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		choicesholders[tostring(v)] = frame
		local button = create('TextButton',{
			Parent = frame,
			BackgroundTransparency = 1,
			TextTransparency = 1,
			Size = UDim2.new(1,0,1,0),
			ZIndex = frame.ZIndex+1,
		})
		frame.MouseEnter:Connect(function()
			if FramesChosen[frame] then return end
			Tween(frame,0.25,'Quad','In',{TextColor3 = Color3.fromRGB(200, 200, 200)})
		end)
		frame.MouseLeave:Connect(function()
			if FramesChosen[frame] then return end
			Tween(frame,0.25,'Quad','In',{TextColor3 = Color3.fromRGB(125, 125, 125)})
		end)
		button.MouseButton1Down:Connect(function()
			OnClick(frame)
		end)
		optionsHolder:GetPropertyChangedSignal('ZIndex'):Connect(function()
			frame.ZIndex = optionsHolder.ZIndex + 1
			button.ZIndex = frame.ZIndex + 1
		end)
		if min >= indx then
			OnClick(frame)
		end
		indx += 1
	end
	optionsHolder.Size = UDim2.new(1,-5,0,0)
	
	
	self._sector.ChildAdded:Connect(function()

		zindexadd = 100+(#self._sector:GetChildren()-currentChild)*100
		dropdownHolder.ZIndex = zindexadd
		optionsHolder.ZIndex = zindexadd+1
		choiceText.ZIndex = zindexadd+1
		btn.ZIndex = zindexadd+1
	end)
	btn.MouseButton1Down:Connect(function()
		optionsHolder.Visible = not optionsHolder.Visible
		local time = optionsHolder.Visible and 0.4 or 0.3
		local size = optionsHolder.Visible and UDim2.new(0,90,1,math.clamp(optionsHolder.AbsoluteCanvasSize.Y,20,100)+5) or UDim2.new(0, 90, 1, 0)
		local size2 =optionsHolder.Visible and UDim2.new(1,0,0,math.clamp(optionsHolder.AbsoluteCanvasSize.Y,20,100)+5) or UDim2.new(1,0,0,0)
		Tween(dropdownHolder,time,'Quad','InOut',{Size = size})
		Tween(optionsHolder,time,'Quad','InOut',{Size = size2})
	end)
	local function SetValue(newoptions)
		if typeof(newoptions) == 'table' then
			for i,v in pairs(newoptions) do
				if not choices[i] then newoptions[i] = nil end
			end
		else
			newoptions = {newoptions}
		end
		current = newoptions
		for i,v in pairs(choicesholders) do
			local a = table.find(current,i)
			v.TextColor3 = a and Color3.fromRGB(255,255,255) or Color3.fromRGB(125, 125, 125)
			FramesChosen[v] = a ~= nil
			local b = table.find(ChosenFrames,v)
			if b then table.remove(ChosenFrames,b) end
		end
		Update()
	end
	window._FlagsSet[flag] = SetValue
	
	local newmt = table.clone(self)
	newmt._holder = mainHolder
	newmt._segment = true
	setmetatable(newmt,Elements)
	return setmetatable({Set = SetValue},{__index = newmt})
end
function Elements:Label(options)
	local options = formatTable(options)
	local mainHolder = CreateElement(self)
	create('TextLabel',{
		Name = 'Title',
		Parent = mainHolder.Parent,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1.000,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 12),
		ZIndex = mainHolder.ZIndex+1,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 12.000,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = options.name or ''
	})
	mainHolder:Destroy()
end
function Elements:Button(options)
	local options = formatTable(options)
	local mainHolder = self._holder

	if not self._segment then
		mainHolder = CreateElement(self)
	end
	local callback = options.callback or function() end
	mainHolder.Position = UDim2.new(0,1,0,-1)
	mainHolder.Size = UDim2.new(0,180,1,2)

	local button = create('Frame',{
		Name = 'Button',
		LayoutOrder = 0,
		Parent = mainHolder,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = mainHolder.ZIndex+2,
	})
	SetupFrame(button,{corner = {radius = UDim.new(0,2)},stroke = {}})
	create('TextLabel',{
		Parent = button,
		Name = 'Label',
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 3, 0, 1),
		Size = UDim2.new(1, 0, 1, -3),
		ZIndex = mainHolder.ZIndex+3,
		Font = Enum.Font.Gotham,
		Text = options.name or '',
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 12.000,
	})

	local btn = create('TextButton', {
		Parent = button,
		Name = 'Handler',
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = mainHolder.ZIndex + 4,
		Text = '',
	})

	btn.MouseButton1Down:Connect(callback)
end


local keys = { -- took mostly from vozoid, not doing allat
	[Enum.KeyCode.LeftShift] = 'L-SHIFT',
	[Enum.KeyCode.RightShift] = 'R-SHIFT',
	[Enum.KeyCode.One] = '1',
	[Enum.KeyCode.Two] = '2',
	[Enum.KeyCode.Three] = '3',
	[Enum.KeyCode.Four] = '4',
	[Enum.KeyCode.Five] = '5',
	[Enum.KeyCode.Six] = '6',
	[Enum.KeyCode.Seven] = '7',
	[Enum.KeyCode.Eight] = '8',
	[Enum.KeyCode.Nine] = '9',
	[Enum.KeyCode.Zero] = '0',
	[Enum.KeyCode.LeftControl] = 'L-CTRL',
	[Enum.KeyCode.RightControl] = 'R-CTRL',
	[Enum.KeyCode.RightAlt] = 'R-ALT',
	[Enum.KeyCode.LeftAlt] = 'L-ALT',
	[Enum.KeyCode.CapsLock] = 'CAPSLOCK',
	[Enum.KeyCode.KeypadOne] = 'NUM-1',
	[Enum.KeyCode.KeypadTwo] = 'NUM-2',
	[Enum.KeyCode.KeypadThree] = 'NUM-3',
	[Enum.KeyCode.KeypadFour] = 'NUM-4',
	[Enum.KeyCode.KeypadFive] = 'NUM-5',
	[Enum.KeyCode.KeypadSix] = 'NUM-6',
	[Enum.KeyCode.KeypadSeven] = 'NUM-7',
	[Enum.KeyCode.KeypadEight] = 'NUM-8',
	[Enum.KeyCode.KeypadNine] = 'NUM-9',
	[Enum.KeyCode.KeypadZero] = 'NUM-0',
	[Enum.KeyCode.Minus] = "-",
	[Enum.KeyCode.Equals] = "=",
	[Enum.KeyCode.Tilde] = "~",
	[Enum.KeyCode.LeftBracket] = "[",
	[Enum.KeyCode.RightBracket] = "]",
	[Enum.KeyCode.RightParenthesis] = ")",
	[Enum.KeyCode.LeftParenthesis] = "(",
	[Enum.KeyCode.Semicolon] = ",",
	[Enum.KeyCode.Quote] = "'",
	[Enum.KeyCode.BackSlash] = "\\",
	[Enum.KeyCode.Comma] = ",",
	[Enum.KeyCode.Period] = ".",
	[Enum.KeyCode.Slash] = "/",
	[Enum.KeyCode.Asterisk] = "*",
	[Enum.KeyCode.Plus] = "+",
	[Enum.KeyCode.Period] = ".",
	[Enum.KeyCode.Backquote] = "`",
	[Enum.UserInputType.MouseButton1] = "MOUSE-1",
	[Enum.UserInputType.MouseButton2] = "MOUSE-2",
	[Enum.UserInputType.MouseButton3] = "MOUSE-3"
}
local function GetEnum(EnumList, EnumChild)
	local s,result = pcall(function() return EnumList[EnumChild] end)
	if not s then return end
	return result
end
local function GetKeyCode(name)
	for i,v in pairs(keys) do
		if v == name then return i end
	end
	return GetEnum(Enum.KeyCode,name) or GetEnum(Enum.UserInputType,name) or name
end
function Elements:Keybind(options)
	local options = formatTable(options)
	local mainHolder = CreateElement(self)

	local window = self._window
	local callback = options.callback or function() end

	mainHolder.Size += UDim2.new(0,0,0,1)
	create('TextLabel',{
		Name = 'Title',
		Parent = mainHolder.Parent,
		BackgroundTransparency = 1.000,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 12),
		ZIndex = mainHolder.ZIndex+1,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 12.000,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = options.name or ''
	})
	local keybindHolder = create("Frame",{
		Name = 'KeybindHolder',
		Parent = mainHolder,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 75, 1, 0),
		ZIndex = mainHolder.ZIndex+2,
	})

	local btn = create('TextButton',{
		Name = 'Handler',
		Parent = keybindHolder,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 10, 1, 0),
		Position = UDim2.new(0,-5,0,0),
		ZIndex = mainHolder.ZIndex+5,
		Text = ''
	})
	SetupFrame(keybindHolder,
		{
			corner = {radius = UDim.new(0,2)},
			pad = {bottom = UDim.new(0,1),top = UDim.new(0,1),Left = UDim.new(0,8),right = UDim.new(0,8)},
			stroke = {}
		}
	)
	local keyText = create('TextLabel',{
		Parent = keybindHolder,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1.000,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = mainHolder.ZIndex+3,
		Font = Enum.Font.Gotham,
		Text = "NONE",
		TextColor3 = Color3.fromRGB(125, 125, 125),
		TextSize = 12,
		TextWrapped = false,
	})
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	local Update
	local flag = options.flag; if not flag then window._undefinedFlags += 1; flag = 'undefined_'..window._undefinedFlags end
	window.flags[flag] = {
		Active = options.active,
		Type = options.Type or 1,
		Binding = false,
	} -- 1 toggle 2 hold

	local typechoser = create('Frame',{
		Parent = keybindHolder,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5,0,0.5,0),
		Size = UDim2.new(),
		ZIndex = mainHolder.ZIndex+5,
		Visible = false,
	})
	SetupFrame(typechoser,{stroke = {},corner = {radius = UDim.new(0,2)}})
	local button1 = create('TextButton',{
		Parent = typechoser,
		BackgroundColor3 = Color3.fromRGB(125, 125, 125),
		BackgroundTransparency = 1.000,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0.5, 0),
		ZIndex = mainHolder.ZIndex+6,
		Font = Enum.Font.SourceSans,
		Text = "TOGGLE",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
	})
	local button2 = create('TextButton',{
		Parent = typechoser,
		BackgroundColor3 = Color3.fromRGB(125, 125, 125),
		BackgroundTransparency = 1.000,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0.5, 0),
		ZIndex = mainHolder.ZIndex+6,
		Font = Enum.Font.SourceSans,
		Text = "HOLD",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
	})
	
	local scroll = self._tabSector
	local scrollY = scroll.AbsoluteCanvasSize.Y

	local edgeX = scroll.AbsolutePosition.X+scroll.AbsoluteSize.X
	local sizex = 50
	local offset = 15

	local reverse = (keybindHolder.AbsolutePosition.X+keybindHolder.AbsoluteSize.X+offset >= edgeX or keybindHolder.AbsolutePosition.X+keybindHolder.AbsoluteSize.X+offset+sizex >= edgeX)

	local function UpdateVisibility(set)
		if set == false or typechoser.Visible then
			Tween(button1,0.5,'Quad','Out',{TextTransparency = 1})
			Tween(button2,0.5,'Quad','Out',{TextTransparency = 1})
			Tween(typechoser,0.5,'Quad','Out',{Position = UDim2.new(0.5,0,0.5,0),Size = UDim2.new()}).Completed:Wait()
			typechoser.Visible = false
		else
			local posY = math.clamp(keybindHolder.AbsolutePosition.Y-8,scroll.AbsolutePosition.Y,scroll.AbsolutePosition.Y+scrollY)
			typechoser.Visible = true
			Tween(button1,0.5,'Quad','Out',{TextTransparency = 0})
			Tween(button2,0.5,'Quad','Out',{TextTransparency = 0})
			Tween(typechoser,0.5,'Quad','Out',{Position = (reverse and UDim2.new(0,-65, 0, -8) or UDim2.new(1,15,0,-8)),Size = UDim2.new(0, 50, 0, 30)}).Completed:Wait()
		end
	end
	btn.MouseButton2Down:Connect(function() UpdateVisibility() end)
	button1.MouseButton1Down:Connect(function()
		window.flags[flag].Type = 1
		Update()
		UpdateVisibility(false)
	end)
	button2.MouseButton1Down:Connect(function()
		window.flags[flag].Type = 2
		Update()
		UpdateVisibility(false)
	end)
	button1.MouseEnter:Connect(function()
		if window.flags[flag].Type ~= 1 then
			Tween(button1,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(200,200,200)})
		end
	end)
	button2.MouseEnter:Connect(function()
		if window.flags[flag].Type ~= 2 then
			Tween(button2,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(200,200,200)})
		end
	end)
	button1.MouseLeave:Connect(function()
		if window.flags[flag].Type ~= 1 then
			Tween(button1,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(125,125,125)})
		end
	end)
	button2.MouseLeave:Connect(function()
		if window.flags[flag].Type ~= 2 then
			Tween(button2,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(125,125,125)})
		end
	end)
	
	local key
	local function setkey(newkey)
		local keyName = keys[newkey] or tostring(newkey):match("Enum%.%a+%.(%a+)") or newkey

		local color = (keyName == 'NONE' or keyName == '...') and Color3.fromRGB(125, 125, 125) or Color3.fromRGB(255, 255, 255)
		Tween(keyText,0.1,'Quad','In',{TextColor3 = color})
		keyText.Text = keyName
		keybindHolder.Size = UDim2.new(0,keyText.TextBounds.X+10,1,0)
		key = GetKeyCode(keyName)
		
		window.flags[flag]['Key'] = keyName
	end
	setkey('NONE')
	local defaultKey = options.key
	if defaultKey then
		if typeof(defaultKey) == 'EnumItem' then
			setkey(defaultKey)
		else
			setkey(Enum.KeyCode[defaultKey] or Enum.UserInputType.MouseButton1)
		end
	end
	Update = function()
		local val = window.flags[flag]
		
		if val.Type == 1 then
			Tween(button1,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(255,255,255)})
			Tween(button2,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(125,125,125)})
		else
			Tween(button1,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(125,125,125)})
			Tween(button2,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(255,255,255)})
		end
		callback(val)
	end
	Update()
	
	

	local bindingSignal

	btn.MouseButton1Click:Connect(function()
		window.flags[flag].Binding = true
		setkey('...')
		bindingSignal = uis.InputBegan:Connect(function(input,a)
			--if a then return end
			if input.KeyCode == Enum.KeyCode.Backspace then
				setkey('NONE')
			elseif input.KeyCode == Enum.KeyCode.Unknown then
				setkey(input.UserInputType)
			else
				setkey(input.KeyCode)
			end
			window.flags[flag].Binding = false
			bindingSignal:Disconnect()
			Update()
		end)
	end)
	Connections[math.random()] = uis.InputBegan:Connect(function(input,a)
		--if a then return end
		if key == input.KeyCode or key == input.UserInputType then
			if window.flags[flag].Type == 1 then
				window.flags[flag].Active = not window.flags[flag].Active
			else
				window.flags[flag].Active = true
			end
			Update()
		end
	end)
	Connections[math.random()] = uis.InputEnded:Connect(function(input,a)
		--if a then return end
		if key == input.KeyCode or key == input.UserInputType then
			if window.flags[flag].Type == 2 then
				window.flags[flag].Active = false
				Update()
			end
		end
	end)
	
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------

	
	local function SetValue(value)
		assert(typeof(value) == 'table')
		local value = formatTable(value)
		window.flags[flag].Binding = false
		window.flags[flag].Active = value.active
		window.flags[flag].Type = value.type or window.flags[flag].Type
		setkey(GetKeyCode(value.key or 'NONE'))
	end
	window._FlagsSet[flag] = SetValue
	
	local newmt = table.clone(self)
	newmt._holder = mainHolder
	newmt._segment = true
	setmetatable(newmt,Elements)
	return setmetatable({Set = SetValue},{__index = newmt})
end
function SetupSector(window,tab)
	SetupFrame(tab,{
		list = {pad = UDim.new(0,14),direction = 'Horizontal',horizontalalignment = 'Left',verticalalignment = 'Top'},
		pad = {top = UDim.new(0,1), left = UDim.new(0, 1),right = UDim.new(0,3)}
	})
	local rightRow = create('Frame',{
		Name = 'Row 1',
		Parent = tab,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0.5, -7, 1, 0),
	})
	local leftRow = create('Frame',{
		Name = 'Row 2',
		Parent = tab,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0.5,-7,1,0)
	})
	local _, _, rightList = SetupFrame(rightRow,{
		list = {pad = UDim.new(0,14),verticalalignment = 'Top',direction = 'Vertical'}
	})
	local _, _, leftList = SetupFrame(leftRow,{
		list = {pad = UDim.new(0,14),verticalalignment = 'Top',direction = 'Vertical'}
	})

	local function handleCanvas()
		task.wait()

		tab.CanvasSize = UDim2.new(0, 0, 0, math.max(leftList.AbsoluteContentSize.Y, rightList.AbsoluteContentSize.Y) + tab.Parent.UIPadding.PaddingTop.Offset + tab.Parent.UIPadding.PaddingBottom.Offset)
	end

	rightList:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(handleCanvas)
	leftList:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(handleCanvas)

	local SectionsHandler = {}
	function SectionsHandler:Sector(options)
		local options = formatTable(options)
		local row = options.side == 1 and rightRow or leftRow
		local section = create('Frame',{
			Parent = row,
			ZIndex = 2,
			BackgroundColor3 = Color3.fromRGB(30,30,30),
			BackgroundTransparency = 0.5,
			Size = UDim2.new(),
			Name = 'Sector'
		})
		SetupFrame(section,{
			list = {pad = UDim.new(0,12),direction = 'Vertical',horizontalalignment = 'Left',verticalalignment = 'Top'},
			corner = {radius = UDim.new(0,4)},
			pad = {Bottom = UDim.new(0,16),top = UDim.new(0,16),right = UDim.new(0,16),left = UDim.new(0,16)},
			stroke = {}
		})
		local list = section.UIListLayout
		list:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function(newval)
			local contentSize = list.AbsoluteContentSize.Y + 32

			section.Size = UDim2.new(1,0,0,contentSize)
			handleCanvas()
		end)
		return setmetatable(
			{
				_holder = section,
				_window = window,
				_side = options.side,
				_tabSector = tab,
				_sector = section,
				_holderSize = UDim2.new(0,100,1,0),
				_holderPosition = UDim2.new(0,80,0,0)
			},
			{__index = function(a,b) return Segment[b] or Elements[b] end}
		)
	end

	return SectionsHandler
end
local Tabs = {}
Tabs.__index = Tabs
function Tabs.normal(tabholder,window)
	local tab = create('ScrollingFrame',{
		Parent = tabholder,
		Name = 'Sector',
		LayoutOrder = #window._tabs+1,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		BottomImage = "",
		CanvasSize = UDim2.new(0, 0, 1, 0),
		ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50),
		ScrollBarThickness = 1,
		TopImage = "",
		Active = true,
		ZIndex = 3,
		Visible = false
	})


	return tab,SetupSector(window,tab)
end

local skins = {}
skins.__index = skins
function skins.new(options,window,tab)
	local options = formatTable(options)
	
	local self = setmetatable(
		{
			_window = window,
			_CurrentChoices = {},
		},
		skins
	)
	local flag = options.flag; if not flag then window._undefinedFlags += 1; flag = 'undefined_'..window._undefinedFlags end
	window.flags[flag] = {choices = {},options = {}}	
	self._flag = flag
	
	tab.Visible = false
	local background = create('Frame',{
		Parent = tab,
		Name = 'Background',
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BackgroundTransparency = 0.500,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 2,
	})
	SetupFrame(background,{
		corner = {radius = UDim.new(0,4)},stroke = {}
	})
	local addframe = create('Frame',{
		Parent = tab,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1.000,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 2,
		Visible = false,
	})
	local content = create('ScrollingFrame',{
		Name = 'Content',
		Parent = tab,
		Active = true,
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BackgroundTransparency = 1.000,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = true,
		ZIndex = 2,
		BottomImage = "",
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 1,
		TopImage = "",
	})
	self._ChoicesHolder = content
	do
		create('UIGridLayout',{
			Parent = content,
			CellPadding = UDim2.new(0,4,0,4),
			CellSize = UDim2.new(0,80,0,85),
			FillDirection = 'Horizontal',
			SortOrder = 'LayoutOrder'
		})
		SetupFrame(content,{pad = {top = UDim.new(0,14),bottom = UDim.new(0,14),left = UDim.new(0,12),right = UDim.new(0,11)}})

		local addbutton = create('Frame',{
			Parent = content,
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.new(0, 100, 0, 100),
			ZIndex = 3,
		})
		SetupFrame(addbutton,{corner = {radius = UDim.new(0,4)},pad = {top = UDim.new(0,3),bottom = UDim.new(0,3),left = UDim.new(0,3),right = UDim.new(0,3)},stroke = {}})

		for i=0,1 do -- best for loop
			create('Frame',{
				Parent = addbutton,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, -5, 0.5, -20),
				Rotation = i*90,
				Size = UDim2.new(0, 10, 0, 40),
				ZIndex = 4,
			})
		end
		create('TextButton',{
			Parent = addbutton,
			BackgroundTransparency = 1,
			TextTransparency = 1,
			ZIndex = addbutton.ZIndex + 1,
			Size = UDim2.new(1,0,1,0),
		}).MouseButton1Down:Connect(function()
			content.Visible = not content.Visible
			addframe.Visible = not addframe.Visible
		end)

	end
	do
		local options = create('ScrollingFrame',{
			Name = 'Options',
			Parent = addframe,
			Active = true,
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 30),
			Size = UDim2.new(1, -5, 1, -30),
			ZIndex = 3,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 1,
		})
		SetupFrame(options,{list = {pad = UDim.new(0,5),horizontalalignment = 'Left',direction = 'Vertical',SortOrder = 'Name',Verticalalignment = 'Top'},pad = {bottom = UDim.new(0,10),top = UDim.new(0,10),right = UDim.new(0,15),left = UDim.new(0,15)}})
		self._OptionsHolder = options
		local menu = create('Frame',{
			Parent = addframe,
			Name = 'Menu',
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 30),
			ZIndex = 3,
		})
		SetupFrame(menu,{
			corner = {radius = UDim.new(0,4)},
			list = {pad = UDim.new(0,6),direction = 'Horizontal',order = 'LayoutOrder',HorizontalAlignment = 'Left',verticalalignment = 'Top'},
			pad = {top = UDim.new(0,5),bottom = UDim.new(0,5),left = UDim.new(0,5),right = UDim.new(0,5)},
			stroke = {}
		})
		
		local add = create('Frame',{
			Parent = menu,
			Name = 'Add',
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			LayoutOrder = 2,
			Size = UDim2.new(0, 140, 1, 0),
			ZIndex = 4,
		})
		
		local back = create('Frame',{
			Parent = menu,
			Name = 'Back',
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.new(0, 60, 1, 0),
			ZIndex = 4,
		})
		
		local search = create('Frame',{
			Parent = menu,
			Name = 'Search',
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			LayoutOrder = 3,
			Size = UDim2.new(0, 200, 1, 0),
			ZIndex = 4,
		})
		SetupFrame(add,{corner = {radius = UDim.new(0,2)},stroke = {}})
		SetupFrame(back,{corner = {radius = UDim.new(0,2)},stroke = {}})
		SetupFrame(search,{corner = {radius = UDim.new(0,2)},stroke = {}})
		
		create('TextButton',{
			Parent = back,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 1),
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 4,
			Font = Enum.Font.GothamMedium,
			Text = "Back",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14.000,
		}).MouseButton1Down:Connect(function()
			content.Visible = true
			addframe.Visible = false
		end)
		create('TextButton',{
			Parent = add,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 3),
			TextScaled = true,
			TextWrapped = true,
			Size = UDim2.new(1, 0, 1, -5),
			ZIndex = 4,
			Font = Enum.Font.GothamMedium,
			Text = "Add Selected (0)",
			TextColor3 = Color3.fromRGB(125, 125, 125),
			TextSize = 14.000,
		}).MouseButton1Down:Connect(function()
			return self:_HandleChoices()
		end)
		local searchbox = create('TextBox',{
			Parent = search,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 5, 0, 3),
			Size = UDim2.new(1, -5, 1, -5),
			TextScaled = true,
			ZIndex = 5,
			Font = Enum.Font.GothamMedium,
			Text = "Search",
			TextColor3 = Color3.fromRGB(125, 125, 125),
			TextSize = 14.000,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local isEmpty = true
		local ignore = false
		searchbox.Focused:Connect(function()
			searchbox.TextColor3 = Color3.fromRGB(255, 255, 255)
			if isEmpty then
				searchbox.Text = ''
			end
		end)
		searchbox.FocusLost:Connect(function()
			searchbox.ClearTextOnFocus = searchbox.Text == ''
			isEmpty = searchbox.Text == ''
			if searchbox.Text == '' then
				searchbox.TextColor3 = Color3.fromRGB(125,125,125)
				ignore = true
				searchbox.Text = 'Search'
			end
		end)
		searchbox:GetPropertyChangedSignal('Text'):Connect(function()
			if ignore then
				ignore = false
				isEmpty = true
			else
				isEmpty = searchbox.Text == ''
			end
			for i,v in pairs(options:GetChildren()) do
				if not v:IsA('Frame') then continue end
	
				if v.Name:match(searchbox.Text) or isEmpty then
					v.Visible = true
				else
					v.Visible = false
				end
			end
		end)
	end
	
	self:AddOptions(options.options or {})
	self:AddChoices(options.choices or {})
end
function skins:AddOption(suffix,option)
	local holder = self._OptionsHolder
	local option = formatTable(option)
	local name = option.name or ''
	local window = self._window
	local flag = self._flag
	
	local suffix = suffix or ''
	
	local holder = create('Frame',{
		Parent = holder,
		Name = (suffix or '')..' | '..(name or ''),
		LayoutOrder = #holder:GetChildren()-1,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 40),
		ZIndex = 4,
	})
	SetupFrame(holder,{pad = {bottom = UDim.new(0,5),top = UDim.new(0,5),left = UDim.new(),right = UDim.new(0,5)}})
	create('ImageLabel',{
		Parent = holder,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 30, 1, 0),
		ZIndex = 4,
		Image = option.image or '',
	})
	create('TextLabel',{
		Parent = holder,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1.000,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 35, 0, 0),
		Size = UDim2.new(0, 200, 1, 0),
		ZIndex = 4,
		Font = Enum.Font.GothamMedium,
		Text = (suffix or '')..' | '..(name or ''),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14.000,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local button = create('Frame',{
		Name = 'Button',
		Parent = holder,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -75, 0, 0),
		Size = UDim2.new(0, 75, 1, 0),
		ZIndex = 4,
	})
	SetupFrame(button,{corner = {radius = UDim.new(0,2)},stroke = {}})
	
	window.flags[self._flag].options[suffix] = window.flags[self._flag].options[suffix] or {}
	local data = {image = option.image or '',name = option.name or ''}
	table.insert(window.flags[self._flag].options[suffix],data)
	local id = #window.flags[self._flag].options[suffix]
	local btn = create('TextButton',{
		Name = 'Button',
		Parent = button,
		BackgroundColor3 = Color3.fromRGB(200, 200, 200),
		BackgroundTransparency = 1.000,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 4,
		Font = Enum.Font.GothamMedium,
		Text = "ADD",
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 14.000,
	})
	btn.MouseButton1Down:Connect(function()
		if window.flags[flag].choices[suffix] and window.flags[flag].choices[suffix].name == data.name then return end
		if self._CurrentChoices[suffix] then
			self._CurrentChoices[suffix] = nil
			self:_SetSelection(self:_GetSelection()-1)
			Tween(btn,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(200,200,200)})
		else
			self._CurrentChoices[suffix] = data

			self:_SetSelection(self:_GetSelection()+1)
			Tween(btn,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(125,125,125)})
		end
		self:FilterOptions()
	end)
	btn.MouseEnter:Connect(function()
		if self._CurrentChoices[suffix] ~= data and (not window.flags[flag].choices[suffix] or window.flags[flag].choices[suffix].name ~= data.name) then
			Tween(btn,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(255,255,255)})
		end
	end)
	btn.MouseLeave:Connect(function()
		if self._CurrentChoices[suffix] ~= data and (not window.flags[flag].choices[suffix] or window.flags[flag].choices[suffix].name ~= data.name) then
			Tween(btn,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(200,200,200)})
		end
	end)
end
function skins:AddChoice(suffix,data)
	if self._window.flags[self._flag].choices[suffix] then return end
	local holder = self._ChoicesHolder
	local option = formatTable(data)
	local frame = create('Frame',{
		Parent = holder,
		LayoutOrder = #holder:GetChildren()-1,
		Name = 'Choice',
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 100, 0, 100),
		ZIndex = 3,
	})
	SetupFrame(frame,{corner = {radius = UDim.new(0,4)},pad = {Bottom = UDim.new(0,3),top = UDim.new(0,3),right = UDim.new(0,3),left = UDim.new(0,3)},stroke = {}})
	local button = create('ImageButton',{
		Parent = frame,
		BackgroundColor3 = Color3.fromRGB(200, 200, 200),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 4,
		Image = option.image or ''
	})
	button.MouseButton1Down:Connect(function()
		self._window.flags[self._flag].choices[suffix] = nil
		frame:Destroy()
		self:FilterOptions()
	end)
	self._window.flags[self._flag].choices[suffix] = option

end
function skins:AddChoices(options)
	for i,v in pairs(options) do
		for _,v2 in pairs(v) do
			self:AddChoice(i,v2)
		end
	end
end
function skins:AddOptions(options)
	for i,v in pairs(options) do
		for _,v2 in pairs(v) do
			self:AddOption(i,v2)
		end
	end
end
function skins:_HandleChoices()
	for i,v in pairs(self._CurrentChoices) do
		self:AddChoice(i,v)
	end
	
	table.clear(self._CurrentChoices)
	self:FilterOptions()
	self:_SetSelection(0)
end
function skins:_SetSelection(n)
	local text = "Add Selection ("..n..')'
	self._OptionsHolder.Parent.Menu.Add.TextButton.Text = text
	Tween(self._OptionsHolder.Parent.Menu.Add.TextButton,0.2,'Quad','Out',{TextColor3 = tonumber(n) == 0 and Color3.fromRGB(125,125,125) or Color3.fromRGB(255,255,255)})
end
function skins:_GetSelection()
	return self._OptionsHolder.Parent.Menu.Add.TextButton.Text:match("%d+")
end


function skins:FilterOptions()
	for i,v in pairs(self._OptionsHolder:GetChildren()) do
		if not v:IsA('Frame') then continue end
		local data = v.Name:split(' | ')
		local value = self._CurrentChoices[data[1]]
		local value2 = self._window.flags[self._flag].choices[data[1]]
		if (value and value.name ~= data[2]) or (value2 and value2.name ~= data[2]) then
			v.Visible = false
			Tween(v.Button.Button,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(200,200,200)})
		else
			if not (value or value2) then
				Tween(v.Button.Button,0.2,'Quad','Out',{TextColor3 = Color3.fromRGB(200,200,200)})
			end
			v.Visible = true
		end
	end
end

function Tabs.skins(tabholder,window,options) -- whatever name it yourself
	local options = formatTable(options)
	
	return tabholder,skins.new(options,window,tabholder)
end

local Notify = {}
Notify.__index = Notify
function Notify.new(options,notifsholder)
	local options = typeof(options) == 'table' and formatTable(options) or {text=tostring(options)}
	local holder = create('Frame',{
		Parent = notifsholder,
		Name = 'Holder',
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(50, 0, 0, 20),
		ZIndex = 3,
		ClipsDescendants = true,
	})
	SetupFrame(holder,{corner = {radius = UDim.new(0,4)},stroke = {}})
	
	options.color = options.color or Color3.fromRGB(255,255,255)
	options.time = options.time or 1.3
	
	if options.grad ~= false then
		create('Frame',{
			Name = 'Color',
			Parent = holder,
			BackgroundColor3 = options.color,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 1),
			Size = UDim2.new(0, 1, 1, -2),
			ZIndex = 4,
		})
		create('Frame',{
			Name = 'Color2',
			Parent = holder,
			BackgroundColor3 = options.color,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0,1,0,0),
			Size = UDim2.new(0, 1, 1, 0),
			ZIndex = 4,
		})
	end
	local text = create('TextLabel',{
		Parent = holder,
		Name = 'Text',
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1.000,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 7, 0, 0),
		Size = UDim2.new(1, -10, 1, 0),
		ZIndex = 4,
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14.000,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = options.text or ''
	})
	
	holder.Size = UDim2.new(0,text.TextBounds.X+15,0,25)
	
	local mt = setmetatable({_holder = holder,_options = options},Notify)
	task.spawn(Notify[options.style and options.style:lower() or 'normal'],mt)
	return mt
end
function Notify:_Animate()
	local signals = {
		OnFinish = Signal.new(),
		OnAnimation = Signal.new(),
	}
	coroutine.wrap(function()
		local size = self._holder.AbsoluteSize
		self._holder.Size = UDim2.new(0,0,0,size.Y)

		Tween(self._holder,0.6,'Quad','Out',{Size = UDim2.new(0,size.X,0,size.Y)})

		wait(self._options.time)
		
		signals.OnAnimation:Fire()
		Tween(self._holder,0.2,'Quad','Out',{BackgroundTransparency = 1,Position = UDim2.new(-1,0,0,0)})
		Tween(self._holder.Color,0.2,'Quad','Out',{BackgroundTransparency = 1})
		Tween(self._holder.Stroke,0.2,'Quad','Out',{Transparency = 1})
		Tween(self._holder.Color2,0.2,'Quad','Out',{BackgroundTransparency = 1})
		local t = Tween(self._holder.Text,0.2,'Quad','Out',{TextTransparency = 1})
		t.Completed:Wait()
		
		signals.OnFinish:Fire()
		self._holder:Destroy()
	end)()
	return signals
end
function Notify:normal()
	return self:_Animate()
end
function Notify:warning()
	local shouldbreak = false
	local grad,grad2 = self._holder.Color,self._holder.Color2
	coroutine.wrap(function()
		local a = 0
		while not shouldbreak do
			Tween(grad,0.25,'Linear','In',{BackgroundColor3 = Color3.new() or self._options.color})
			local t = Tween(grad2,0.25,'Linear','In',{BackgroundColor3 = Color3.new() or self._options.color})
			t.Completed:Wait()
			a+=1
		end
	end)()

	local signals = self:_Animate()
	signals.OnFinish:Connect(function()
		shouldbreak = true
	end)
	return signals
end
function Notify:time()
	local shouldbreak = false
	local time = self._options.time
	local timer = create('Frame',{
		Parent = self._holder,
		Position = UDim2.new(0,2,1,-1),
		Size = UDim2.new(0,0,0,1),
		BackgroundColor3 = self._options.color,
		ZIndex = 4,
		BorderSizePixel = 0,
	})
	local ct = 0
	local loop = rs.RenderStepped:Connect(function(dt)
		ct += dt
		timer.Size = UDim2.new(math.min(ct/time,1),-6,0,1)
	end)

	local signals = self:_Animate()
	signals.OnAnimation:Connect(function()
		loop:Disconnect()
		Tween(timer,0.2,'Quad','Out',{BackgroundTransparency = 1})
	end)
	return signals
end
function Notify:loading()
	local shouldbreak = false
	local grad,grad2 = self._holder.Color,self._holder.Color2
	local bar = create('Frame',{
		Parent = self._holder,
		Position = UDim2.new(0,1,1,-1),
		Size = UDim2.new(0,0,0,1),
		BackgroundColor3 = self._options.color,
		ZIndex = 4,
		BorderSizePixel = 0,
	})
	coroutine.wrap(function()
		local a = 0
		while not shouldbreak do
			local sizex = self._holder.AbsoluteSize.X/3
			local x = (sizex/2)
			
			local t = Tween(bar,0.6,'Linear','Out',{Position = UDim2.new(0.5,a%2 == 0 and x or -x,1,-1),Size = UDim2.new(0,a%2 == 0 and -sizex or sizex,0,1)})
			t.Completed:Wait()
			local t = Tween(bar,0.6,'Quad','Out',{Position = a%2==0 and UDim2.new(1,-2,1,-1) or UDim2.new(0,2,1,-1),Size = UDim2.new(0,1,0,1)})
			t.Completed:Wait()
			a+=1
			task.wait(.15)
		end
	end)()

	local signals = self:_Animate()
	signals.OnAnimation:Connect(function()
		shouldbreak = true
		Tween(bar,0.2,'Quad','Out',{BackgroundTransparency = 1})
	end)
	return signals
end
function Notify:SetText(text)
	self._holder.Text.Text = text
	self._holder.Size = UDim2.new(0,self._holder.Text.TextBounds.X+10,0,25)
end
local Watermark = {}
Watermark.__index = Watermark
function Watermark.new(watermark,options)
	local mt = setmetatable({_watermark = watermark},Watermark)

	mt:Edit(options or {})
	return mt
end
function Watermark:Edit(options) -- background, textcolor, richtext
	local options = formatTable(options)
	if options.text then
		self._watermark.Text.Text = tostring(options.text)
	end
end
function ui:Init(options)
	local options = formatTable(options)

	local parent = options.parent or script.Parent or game:GetService('CoreGui')

	local UIsHolder = create('ScreenGui',{
		Name = 'UIHolder',
		Parent = parent,
		ZIndexBehavior = 'Global',
		ResetOnSpawn = false
	})

	function ui:Unload()
		for _, connection in next, Connections do
			connection:Disconnect()
		end
		
		UIsHolder:Destroy()
	end

	function ui:SetToggled(bool)
		UIsHolder.Enabled = bool
	end

	function ui:Toggle()
		self:SetToggled(not UIsHolder.Enabled)
	end

	function ui:Watermark(options)
		local options = formatTable(options)

		local text = options.text or 'Lynx'

		local watermark = create('Frame',{
			Name = "Watermark",
			Parent = UIsHolder,
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 32, 0, 32),
			Size = UDim2.new(0, 32, 0, 32),
		})
		Dragify(watermark)
		SetupFrame(watermark, {
			corner = {radius = UDim.new(0, 8)},
			pad = {bottom = UDim.new(0, 8), top = UDim.new(0, 8), left = UDim.new(0, 16), right = UDim.new(0, 16)},
			stroke = {}
		})

		local text = create('TextLabel', {
			Name = "Text",
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			RichText = true,
			Text = text,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextScaled = false,
			TextWrapped = false,
			TextXAlignment = "Left",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Parent = watermark
		})

		text:GetPropertyChangedSignal('TextBounds'):Connect(function()
			task.wait()

			local bounds = text.TextBounds
			watermark.Size = UDim2.new(0, bounds.X + 32, 0, bounds.Y + 16)
		end)
		
		return Watermark.new(watermark,options)
	end
	do
	--super duper cool uilistlayout
		local notifs = create("ScreenGui",{
			Parent = UIsHolder.Parent,
			Name = 'Notifications'
		})
		local notifsholder = create('Frame',{
			Name = 'NotificationsHolder',
			Parent = notifs,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1.000,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 50, 0, 50),
			Size = UDim2.new(0, 34, 50, 0),
			ZIndex = 2,
		})
		local childs = {}
		local offsets = {}
		notifsholder.ChildAdded:Connect(function(child)
			if child.Name == 'Holder' then
				local y = #childs*30 -- was meant to have getpropchangedsignal but lazy to change allat
				child.Position = UDim2.new(0,child.AbsolutePosition.X,0,y)
				table.insert(childs,child)
				offsets[child] = y
			end
		end)
		notifsholder.ChildRemoved:Connect(function(child)
			if child.Name == 'Holder' then
				local t = table.find(childs,child)
				local curY = offsets[child]

				for i=t+1,#childs do
					local child = childs[i]

					local oldy = curY
					curY = offsets[child]
					offsets[child] = oldy
					Tween(child,0.2,'Quad','Out',{Position = UDim2.new(0,child.AbsolutePosition.X-notifsholder.AbsolutePosition.X,0,oldy)})
				end
				offsets[child] = nil
				table.remove(childs,t)
			end
		end)
		function ui:Notify(options)
			return Notify.new(options,notifsholder)
		end
	end
	
	function ui:SetupLoader(options)
		local options = formatTable(options)

		local span = options.time or 2

		local loaderFrame = create('Frame',{
			Parent = UIsHolder,
			Name = 'Loading',
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, -50, 0.5, -50),
			Size = UDim2.fromOffset(100, 100),
		})

		SetupFrame(loaderFrame, {
			corner = {radius = UDim.new(1, 0)},
			pad = {bottom = UDim.new(0, 16),top = UDim.new(0, 16),left = UDim.new(0, 16),right = UDim.new(0, 16)}
		})

		local circle = create('ImageLabel', {
			Name = "Circle",
			Image = "rbxassetid://6331335348",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Parent = loaderFrame		
		})

		local startTick = tick()

		task.spawn(function()
			while task.wait() do
				if tick() - startTick >= (span - 2) then 
					task.spawn(function()
						Tween(circle, 0.1, 'Quad', 'In', {ImageTransparency = 1})
						task.wait(.1)
						circle.Rotation = 0
						circle.Image = 'rbxassetid://1202200114'
						Tween(circle, 0.1, 'Quad', 'In', {ImageTransparency = 0})
						task.wait(1)
						Tween(loaderFrame, 0.2, 'Quad', 'In', {BackgroundTransparency = 1})
						Tween(circle, 0.2, 'Quad', 'In', {ImageTransparency = 1})
						task.wait(.9)
						loaderFrame:Destroy()
					end)
					break 
				end

				circle.Rotation = (circle.Rotation + 5) % 360
			end
		end)
	end

	function ui:NewWindow(options)
		local options = formatTable(options)

		local windowOptions = formatTable(options.window)
		local windowName = windowOptions.name or 'Lynx'
		local windowDescription = windowOptions.description or 'Universal'

		local userOptions= formatTable(options.user)
		local username = userOptions.name or 'Finobe'
		local role = userOptions.role or 'Developer'
		local icon = userOptions.icon



		local windowFrame = create('Frame',{
			Parent = UIsHolder,
			Name = 'Window',
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BackgroundTransparency = 0.030,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 640, 0, 500),
		})
		windowFrame.Position = UDim2.new(0.5, -windowFrame.AbsoluteSize.X/2, 0.5, -windowFrame.AbsoluteSize.Y/2)

		SetupFrame(windowFrame,{
			corner = {radius = UDim.new(0,8)},
			stroke = {Color = Color3.fromRGB(40,40,40)}
		})
		local sideBar = create('Frame',{
			Parent = windowFrame,
			Name = 'Sidebar',
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1.000,
			Size = UDim2.new(0.270000011, 0, 1, 0),
			BorderSizePixel = 0,
		})
		Dragify(windowFrame,sideBar)
		local window = {
			_tabs = {},
			_undefinedFlags = 0,
			_FlagsSet = {},
			_DefaultFlags = {},
			flags = {},
		}
		window['Flags'] = window.flags
		function window:SaveConfig(name)
			local cfg = {}
			for i,v in pairs(window.flags) do
				local val = v
				if typeof(v) == 'table' and v.Color and typeof(v.Color) == 'Color3' then
					val = {Color = {R = v.Color.R,G=v.Color.G,B=v.Color.B},Alpha = v.Alpha}
				end
				cfg[i] = val
			end
			return hs:JSONEncode(cfg)
		end
		function window:LoadConfig(input)
			local load = hs:JSONDecode(input)
			for flag,val in pairs(load) do
				if typeof(val) == 'table' and typeof(val.Color) == 'table' then
					val.Color = Color3.new(val.Color.R,val.Color.G,val.Color.B)
				end
				if window._FlagsSet[flag] then
					window._FlagsSet[flag](val)
				end
			end
		end
		do -- content setup
			local content = create('Frame',{
				Name = 'Content',
				Parent = sideBar,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1.000,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),            
			})
			create('UIPadding',{
				Parent = content,
				PaddingBottom = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 16),
			})	
			---------------------------------------------------------
			local windowsInfo = create('Frame',{
				Parent = content,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1.000,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0.150000006, -16),
			})
			create('UIListLayout',{
				Parent = windowsInfo,
				Padding = UDim.new(0,4),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			})
			create('TextLabel',{
				Name = 'a_name',
				Parent = windowsInfo,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 18),
				Font = Enum.Font.GothamBlack,
				Text = windowName,
				RichText = true,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14.000,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
			})
			create('TextLabel',{
				Name = 'b_Description',
				Parent = windowsInfo,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 18),
				Font = Enum.Font.Gotham,
				Text = windowDescription,
				RichText = true,
				TextColor3 = Color3.fromRGB(108, 108, 108),
				TextSize = 14.000,
				TextStrokeColor3 = Color3.fromRGB(92, 92, 92),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			})
			------------------------------------------------------------
			local userInfo = create('Frame',{
				Name = 'UserInfo',
				Parent = content,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0.9, 0),
				Size = UDim2.new(1, 0, 0.1, 0),	
			})
			SetupFrame(userInfo,{list = {pad = UDim.new(0,16),sort = 'LayoutOrder',direction = 'Horizontal',horizontalalignment = 'Left'}})

			if icon then
				SetupFrame(create('ImageLabel',{
					Name = 'Img',
					Parent = userInfo,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0.5, -12),
					Size = UDim2.new(0, 24, 0, 24),
					Image = icon,
				}),{corner = {radius = UDim.new(1,0),stroke = {}}})
			end

			local info = create('Frame',{
				Name = 'Info',
				Parent = userInfo,
				BackgroundTransparency = 1.000,
				BorderSizePixel = 0,
				Position = UDim2.new(0, icon and 56 or 0, 0, 0),
				Size = UDim2.new(1, icon and -40 or 0, 1, 0),
			})
			SetupFrame(info,{list = {pad = UDim.new(0,4)}})
			create('TextLabel',{
				Parent = info,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 56, 0.5, -18),
				Size = UDim2.new(1, 0, 0, 14),
				Font = Enum.Font.GothamBold,
				Text = username,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14.000,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,		
			})
			create('TextLabel',{
				Parent = info,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 56, 0.5, -18),
				Size = UDim2.new(1, 0, 0, 14),
				Font = Enum.Font.Gotham,
				Text = role,
				TextColor3 = Color3.fromRGB(108, 108, 108),
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			})


			--------------------------------------------------------------
			local tabs = create('ScrollingFrame',{
				Name = 'Tabs',
				Parent = content,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1.000,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0.150000006, 0),
				Selectable = false,
				Size = UDim2.new(1, 0, 0.75, -24),
				BottomImage = "",
				CanvasSize = UDim2.new(0, 0, 0, 145),
				ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50),
				ScrollBarThickness = 1,
				TopImage = "",
			})
			local _, _, list, pad = SetupFrame(tabs,{
				list = {pad = UDim.new(0,8),VerticalAlignment = 'Top'},
				Pad = {left = UDim.new(0,1),top = UDim.new(0,1), right = UDim.new(0, 8)}
			})

			list:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
				task.wait()
				local abs = list.AbsoluteContentSize
				tabs.CanvasSize = UDim2.new(0, abs.X, 0, abs.Y)
			end)

			
			local function _tween(fp, is)
				Tween(fp, 0.25, 'Quad', 'In', {BackgroundTransparency = is and 0 or 1})
				Tween(fp:FindFirstChildOfClass('UIStroke'), 0.25, 'Quad', 'In', {Transparency = is and 0 or 1})
			end
			function window:Tab(options)
				local options = formatTable(options)
				
				local type = options.type and options.type:lower() or 'normal'
				local icon = options.icon

				----------------------------------------------------------------------------------
				local section = create('Frame',{
					Name = ('1'):rep(#tabs:GetChildren()-1),
					Parent = tabs,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1.000,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = UDim2.new(1, -1, 0, 32),
					ZIndex = 2,
				})

				local _clickHandler = create('TextButton', {
					Name = 'Handler',
					Parent = section,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 5,
					Size = UDim2.new(1, 0, 1, 0),
					Text = '',
				})

				local tab_a = create('Frame',{
					Name = 'Tab',
					Parent = section,
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
					ZIndex = 3,
				})
				local _,stroke,_,_ = SetupFrame(tab_a,{
					corner = {radius = UDim.new(0,4)},
					list = {pad = UDim.new(0,8),horizontalalignment = 'Left',verticalalignment = 'Center',direction = 'Horizontal'},
					pad = {bottom = UDim.new(0,10),top = UDim.new(0,10),left = UDim.new(0,10),right = UDim.new(0,10)},
					stroke = {}
				})
				stroke.Transparency = 1

				if icon then
					create('ImageLabel',{
						Name = 'a_icon',
						Parent = tab_a,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1.000,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Size = UDim2.new(0, 16, 1, 0),
						ZIndex = 4,
						Image = icon,
						ScaleType = Enum.ScaleType.Fit,
					})
				end
				create('TextLabel',{
					Name = 'b_text',
					Parent = tab_a,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1.000,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = UDim2.new(1, icon and -28 or 0, 1, 0),
					ZIndex = 4,
					Font = Enum.Font.GothamMedium,
					Text = options.name or '[NO NAME]',
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 14,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				----------------------------------------------------------------------------------
				local tabHolder = create('Frame',{
					Parent = windowFrame,
					Name = 'SectorHolder_'..(#window._tabs+1),
					Size = UDim2.new(0.73, 0,1, 0),
					Position = UDim2.new(0.27,0,0,0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
				})

				SetupFrame(tabHolder, {
					pad = {bottom = UDim.new(0,14),top = UDim.new(0,14),right = UDim.new(0,14),left = UDim.new(0,14)}
				})
				local tab,funcs = Tabs[type](tabHolder,window,options)
				_clickHandler.MouseButton1Down:Connect(function()
					if window._CurrentTab[1] ~= section then

						task.spawn(function()
							_tween(window._CurrentTab[1].Tab, false)
							window._CurrentTab[2].Visible = false
							window._CurrentTab[2].ZIndex -= 1	

							window._CurrentTab = {section,tab}
							tab.ZIndex += 1
							_tween(section.Tab, true)
						end)
						tab.Visible = true
					end
				end)
				if not window._CurrentTab then
					window._CurrentTab = {section,tab}

					_tween(window._CurrentTab[1].Tab, true)
					tab.Visible = true
					tab.ZIndex += 1
				end


				table.insert(window._tabs,tab)
				return funcs
			end
			function window:Separator()
				create('Frame',{
					Name = 'Separator',
					Parent = create('Frame',{
						Name = ('1'):rep(#tabs:GetChildren()-1),
						Parent = tabs,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -1, 0, 32),
						ZIndex = 2,
					}),
					BackgroundColor3 = Color3.fromRGB(40, 40, 40),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(1, 0, 0, 1),
				})
			end
		end
		create('Frame',{
			Name = "Separator",
			Parent = sideBar,
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0, 1, 1, 0),
		})


		return window
	end
end

ui:Init()

return ui