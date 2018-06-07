# BQuest.
BQuest is a World of Warcraft game add-on in development.
## Purpose.
The purpose of the add-on is to allow the player to create custom quests and share them with others.
Basically, it is an in-game to-do list, that updates automatically.
## Features.
Types of activities that currently can be tracked:
1. Spell casts.
2. Item aquisition.
3. Destruction of enemies.

Types of activities that are planned to be supported:
1. Item delivery.
2. Ability mastering.
## Usage.
1. Install like a normal add-on.
2. In game, type or create macro:
```
/run ShowUIPanel(BQuest)
```
3. A frame will appear. At the bottom if it, click 'Add' button to add a new quest. Another frame will appear.
4. For example, let us create a quest that tracks if the player has a Hearthstone. This gets tricky.
4.1. Link Hearthstone in the chat, or ask someone to link it.
4.2. Select "CollectItem" radio button to indicate that you want to track item aquisition.
4.3. Focus on edit box labeled "Item link" and insert a link from the chat frame into it, like you normally would.
4.4. In the edit box labeled "Item amount" insert desired amount of Hearthstones, for example 1.
4.5. Click "Accept" button.
5. A new entry in the main frame will appear.

Note: grey labels indicate that the parameter is optional. For example, players can optionally limit tracked spell casts
to specific enemies, NPC or other player alike.
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