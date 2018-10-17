shell.run("clear")
local versionString = "v0.0.1 ALPHA"
local nTime = os.time()
local nDay = os.day()
local monitor = peripheral.wrap("top")

local currentItem = 1 -- Caret location
local selectedTask = 0 -- Current selected task
local menuStack = {} -- because Lua is a bitch
local activeTasks = {}
local completedTasks = {} -- Lua is still a bitch
local activeTaskActions = {} -- Why is Lua such a cunt
local completedTaskActions = {}

local menuItemColors = {
    Default = colors.white,
    Delete = colors.red,
	Complete = colors.green,
	Reactivate = colors.yellow,
	Back = colors.lightGray,
}

-- Display tasks on the big screen for everyone to see
function displayTasksOnMonitor()
    monitor.clear()
    for i=1,39 do
        monitor.setCursorPos(i,2)
        monitor.write("-")
    end
    for i=1,12 do
        monitor.setCursorPos(25,i)
        monitor.write("|")
    end
    monitor.setCursorPos(7,1)
    monitor.write("Active tasks")
    for k,v in pairs(activeTasks) do
        if v.title ~= "Back" then
            monitor.setCursorPos(12-math.floor(string.len(v.title)/2),2+k)
            monitor.write(v.title)
        end
    end
    monitor.setCursorPos(28, 1)
    monitor.write("Other info")
    monitor.setCursorPos(27,3)
    monitor.write("Active:")
    monitor.setCursorPos(40-string.len(table.getn(activeTasks)-1),3)
    monitor.write(table.getn(activeTasks)-1)
    monitor.setCursorPos(27,4)
    monitor.write("Completed:")
    monitor.setCursorPos(40-string.len(table.getn(completedTasks)-1),4)
    monitor.write(table.getn(completedTasks)-1)
    
end

-- Save everything
function save()
    local data = {{},{}}
    for k,t in pairs({activeTasks, completedTasks}) do
        for key,task in pairs(t) do
            if task.title ~= "Back" then
                table.insert(data[k], task.title)
            end
        end
    end
    local file = fs.open("tasks.data","w")
    file.write(textutils.serialize(data))
    file.close()
    displayTasksOnMonitor()
end

-- Go to selected menu item
function switchMenuItem()
    selectedTask = currentItem
    table.insert(menuStack, menuStack[table.getn(menuStack)].children[currentItem])
    currentItem = 1
end

-- Go back to last menu item
function goBack()
    table.remove(menuStack)
    currentItem = 1
end

-- Complete a task and go back
function completeTask()
    local t = table.remove(activeTasks, selectedTask)
    t.children = completedTaskActions
    table.insert(completedTasks, table.getn(completedTasks), t)
    goBack()
    save()
end

-- Reactivate a task and go back
function reactivateTask()
    local t = table.remove(completedTasks, selectedTask)
    t.children = activeTaskActions
    table.insert(activeTasks, table.getn(activeTasks), t)
    goBack()
    save()
end

-- Delete a task and go back
function deleteTask(t)
    table.remove(t, selectedTask)
    goBack()
    save()
end

-- because fuck Lua that's why
function deleteTaskFromActive()
    deleteTask(activeTasks)
end

function deleteTaskFromCompleted()
    deleteTask(completedTasks)
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
    
    -- fuck off if it's empty
    if not name or name == "" or name == " " then
        goBack()
    else
        -- otherwise add task and then fuck off
        table.insert(activeTasks, table.getn(activeTasks), stringToTaskItem(name, nil, activeTaskActions))
        goBack() -- this is where we fuck off and pray it works
        save()
    end
end


-- Take a normal string and convert to a task item
function stringToTaskItem(s, a, c)
    a=a or switchMenuItem
    return {title=s, action=a, children=c}
end

local goBackMenuItem = stringToTaskItem("Back", goBack)
activeTaskActions = {
    {title="Complete", action=completeTask, children=nil},
    {title="Delete", action=deleteTaskFromActive, children=nil},
    goBackMenuItem
}
completedTaskActions = {
    {title="Reactivate", action=reactivateTask, children=nil},
    {title="Delete", action=deleteTaskFromCompleted, children=nil},
    goBackMenuItem
}

-- Load data from file
if fs.exists("tasks.data") then
    local file = fs.open("tasks.data","r")
    local rawData = file.readAll()
    file.close()
    data = textutils.unserialize(rawData)
    
    for key,name in pairs(data[1]) do
        activeTasks[key] = stringToTaskItem(name, nil, activeTaskActions)
    end
    for key,name in pairs(data[2]) do
        completedTasks[key] = stringToTaskItem(name, nil, completedTaskActions)
    end
end

-- Add back buttons in task lists
table.insert(activeTasks, goBackMenuItem)
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
		term.setTextColor(colors.magenta)
        print(">")
		term.setTextColor(menuItemColors.Default)
    end
    
    -- Draw items
    for k,item in pairs(menuItems or {}) do
        term.setCursorPos(4, curY)
        term.setTextColor(menuItemColors[item.title] or menuItemColors.Default)
        print(item.title)
        term.setTextColor(menuItemColors.Default)
        curY = curY+1
    end
end


-- Handle inputs
function readKey()
    local sEvent, button = os.pullEvent("key")
    if button == keys.down and currentItem ~= table.getn(menuStack[table.getn(menuStack)].children) then -- go down a menu item
        currentItem = currentItem+1
    elseif button == keys.up and currentItem ~= 1 then -- go up a menu item
        currentItem = currentItem-1
    elseif button == keys.enter then -- select menu item
        if menuStack[table.getn(menuStack)].children[currentItem].action then
            menuStack[table.getn(menuStack)].children[currentItem].action()
        end
    elseif button == keys.left or button == keys.backspace then
        if table.getn(menuStack) > 1 then -- Can we go back?
            goBack()
        end
    end
end

-- Run the program
displayTasksOnMonitor()
while true do
    shell.run("clear")
    drawMenu()
    readKey()
end

--shell.run("clear")
