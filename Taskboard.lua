shell.run("clear")
local versionString = "v0.0.1 ALPHA"
local nTime = os.time()
local nDay = os.day()
local monitor = peripheral.wrap("top")


function printTest()
    term.setCursorPos(10,10)
    print("Testing stuff")
end

local currentItem = 1 -- Caret location
local menuStack = {} -- because Lua is a bitch
local activeTasks = {}
local completedTasks = {} -- Lua is still a bitch

-- Go to selected menu item
function switchMenuItem()
    table.insert(menuStack, menuStack[table.getn(menuStack)].children[currentItem])
    currentItem = 1
end

function goBack()
    table.remove(menuStack)
    currentItem = 1
end

function createTask()
    -- clear screen first
    switchMenuItem()
    shell.run("clear")
    drawMenu()
    
    -- draw some sexy text and wait for input
    term.setCursorPos(2, 6)
    print("Task name: ")
    term.setCursorPos(13, 6)
    local name = read() -- this is the input
    
    -- add task and fuck off
    table.insert(activeTasks, table.getn(activeTasks), stringToTaskItem(name))
    goBack() -- this is where we fuck off and pray it works
end


-- Take a normal string and convert to a task item
function stringToTaskItem(s, a, c)
    a=a or printTest
    return {title=s, action=a, children=c}
end

local goBackMenuItem = stringToTaskItem("Back", goBack)

-- fill with dummy data
for k,v in pairs({"task1", "task2"}) do
    activeTasks[k] = stringToTaskItem(v)
end
table.insert(activeTasks, goBackMenuItem)

for k,v in pairs({"task3", "task4"}) do
    completedTasks[k] = stringToTaskItem(v)
end
table.insert(completedTasks, goBackMenuItem)

-- Menus
local menu = { title="Main Menu", action=nil, children={
    {title="Active tasks", action=switchMenuItem, children=activeTasks},
    {title="New task", action=createTask, children=nil},
    {title="Completed tasks", action=switchMenuItem, children = completedTasks}
}}
menuStack = {menu} -- Basically just a history tho

-- Draw the current menu from the menu stack
function drawMenu()
    term.setCursorPos(1, 1)
    print("Taskboard "..versionString)
    
    if menuStack[table.getn(menuStack)].title then
        term.setCursorPos(1, 4)
        print("Current menu: "..menuStack[table.getn(menuStack)].title)
    end
    
    local curY = 6
    local menuItems = menuStack[table.getn(menuStack)].children
    
    -- Set arrow (>)
    if menuItems and table.getn(menuItems) then
        term.setCursorPos(2, curY + currentItem-1)
        print(">")
    end
    
    -- Draw items
    for k,item in pairs(menuItems or {}) do
        term.setCursorPos(4, curY)
        print(item.title)
        curY = curY+1
    end
end


-- Handle inputs
function readKey()
    local sEvent, button = os.pullEvent("key")
    if button == keys.down and currentItem ~= table.getn(menuStack[table.getn(menuStack)].children) then
        currentItem = currentItem+1
    elseif button == keys.up and currentItem ~= 1 then
        currentItem = currentItem-1
    elseif button == keys.enter then
        if menuStack[table.getn(menuStack)].children[currentItem].action then
            menuStack[table.getn(menuStack)].children[currentItem].action()
        end
    end
end

-- Run the program
while true do
    shell.run("clear")
    drawMenu()
    readKey()
end

--shell.run("clear")
