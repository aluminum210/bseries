# BQuest.
BQuest is a World of Warcraft game add-on in development.
## Purpose.
The purpose of the add-on is to allow the player to create custom quests and share them with others.
Basically, it is an in-game to-do list, that updates automatically.
## Features.
Types of quests implemented:
1. Collect items.
Types of quests planned:
1. Deliver items to a player.
2. Kill a unit or units.
3. Learn an ability.
4. Use an ability certain amount of times. Optinally on a specific unit. 
## Notes.
### Functionality.
Custom quests have state and are mutable!
A quest will only update progress based on events that happened __after__ the quest's creation. 
This is partly limitaion, that was decided to be left uncombated.
### Code style.
Anonymous functions and the following syntax in general 
```
--[[ Avoid the following in this project: ]]--
local myFunc = function() 
  print('This is my function that was defined problematically.')
end

--[[ Also avoid: ]]--
myFrame:SetScript('OnEvent', function(self, event, ...)
  print('This is my anonymous callback!')
end)
```
are __avoided__ intentionally.
This is due to the fact the source code formatter of choice,
that is https://dptole.github.io/lua-beautifier/,
fails to recognize the syntax.
Do instead:
```
local function myGoodFunc()
  print('This is a good function!.')
end

local function myFrameCallback()
  print('This is a good callback!.')
end
myFrame:SetScript('OnEvent', myFrameCallback)
```

Linting is part of the build cycle.
Therefore proper source code formatting is necessary.