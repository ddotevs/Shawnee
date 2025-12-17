' ****************************************************************
' * MainScene.brs - Main Scene Logic
' * Handles content loading, category navigation, and item display
' ****************************************************************

' ============================================================
' CONFIGURATION - Set your GitHub raw URL here
' ============================================================
' Replace with your actual GitHub raw URL after pushing to repo:
' Format: https://raw.githubusercontent.com/USERNAME/REPO/BRANCH/content/content.json
function getContentUrl() as String
    return "https://raw.githubusercontent.com/ddotevs/Shawnee/main/content/content.json"
end function
' ============================================================

sub init()
    m.top.backgroundColor = "#1a1a2e"
    m.top.backgroundURI = ""

    ' Get references to UI components
    m.categoryList = m.top.findNode("categoryList")
    m.itemsGrid = m.top.findNode("itemsGrid")
    m.detailPanel = m.top.findNode("detailPanel")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.loadingText = m.top.findNode("loadingText")
    m.channelTitle = m.top.findNode("channelTitle")

    ' Weather and Lake Level UI components
    m.weatherTemp = m.top.findNode("weatherTemp")
    m.weatherDesc = m.top.findNode("weatherDesc")
    m.lakeLevel = m.top.findNode("lakeLevel")
    m.lakeBelowPool = m.top.findNode("lakeBelowPool")

    ' State management
    m.currentFocus = "categories" ' "categories", "items", or "detail"
    m.content = invalid
    m.categories = []
    m.currentCategoryIndex = 0

    ' Set up observers
    m.categoryList.observeField("itemFocused", "onCategoryFocused")
    m.categoryList.observeField("itemSelected", "onCategorySelected")
    m.itemsGrid.observeField("itemFocused", "onItemFocused")
    m.itemsGrid.observeField("itemSelected", "onItemSelected")

    ' Load content
    loadContent()

    ' Load weather and lake level data
    loadWeather()
    loadLakeLevel()
end sub

' ****************************************************************
' * Content Loading
' ****************************************************************

sub loadContent()
    m.loadingGroup.visible = true
    m.loadingText.text = "Loading content..."
    m.categoryList.visible = false
    m.itemsGrid.visible = false

    ' Create and start content task
    m.contentTask = CreateObject("roSGNode", "ContentTask")

    ' Set remote URL for GitHub-hosted content
    m.contentTask.contentUrl = getContentUrl()

    ' Observe completion
    m.contentTask.observeField("content", "onContentLoaded")
    m.contentTask.observeField("error", "onContentError")
    m.contentTask.control = "run"
end sub

sub onContentLoaded()
    content = m.contentTask.content
    source = m.contentTask.source

    if content = invalid
        showError("No content available")
        return
    end if

    m.content = content

    ' Log content source
    if source = "remote"
        print "MainScene: Content loaded from GitHub"
    else
        print "MainScene: Content loaded from local file (fallback)"
    end if

    ' Update channel branding
    if content.channel <> invalid
        if content.channel.name <> invalid
            m.channelTitle.text = content.channel.name
        end if
    end if

    ' Store categories
    if content.categories <> invalid
        m.categories = content.categories
    end if

    ' Build category list
    buildCategoryList()

    ' Hide loading, show content
    m.loadingGroup.visible = false
    m.categoryList.visible = true
    m.itemsGrid.visible = true

    ' Set initial focus
    m.categoryList.setFocus(true)
    m.currentFocus = "categories"

    ' Load first category items
    if m.categories.count() > 0
        loadCategoryItems(0)
    end if
end sub

sub onContentError()
    errorMsg = m.contentTask.error
    showError(errorMsg)
end sub

sub showError(message as String)
    m.loadingGroup.visible = true
    m.loadingText.text = "Error: " + message
    print "Content Error: "; message
end sub

' ****************************************************************
' * Category Management
' ****************************************************************

sub buildCategoryList()
    contentNode = CreateObject("roSGNode", "ContentNode")

    for each category in m.categories
        itemNode = CreateObject("roSGNode", "ContentNode")
        itemNode.title = category.title
        itemNode.addFields({ categoryId: category.id })
        contentNode.appendChild(itemNode)
    end for

    m.categoryList.content = contentNode
end sub

sub onCategoryFocused()
    index = m.categoryList.itemFocused
    if index >= 0 and index < m.categories.count()
        loadCategoryItems(index)
        m.currentCategoryIndex = index
    end if
end sub

sub onCategorySelected()
    ' Move focus to items grid when category is selected
    m.itemsGrid.setFocus(true)
    m.currentFocus = "items"
end sub

sub loadCategoryItems(categoryIndex as Integer)
    if categoryIndex < 0 or categoryIndex >= m.categories.count()
        return
    end if

    category = m.categories[categoryIndex]
    items = category.items

    if items = invalid or items.count() = 0
        m.itemsGrid.content = invalid
        return
    end if

    contentNode = CreateObject("roSGNode", "ContentNode")

    for each item in items
        itemNode = CreateObject("roSGNode", "ContentNode")
        itemNode.title = item.title

        ' Set poster/image
        if item.image <> invalid
            itemNode.hdPosterUrl = item.image
            itemNode.sdPosterUrl = item.image
        else if item.icon <> invalid
            itemNode.hdPosterUrl = item.icon
            itemNode.sdPosterUrl = item.icon
        end if

        ' Store full item data
        itemNode.addFields({
            itemId: item.id,
            shortDescription: item.shortDescription,
            fullDescription: item.description,
            itemData: item
        })

        contentNode.appendChild(itemNode)
    end for

    m.itemsGrid.content = contentNode
    m.itemsGrid.jumpToItem = 0
end sub

' ****************************************************************
' * Item Events
' ****************************************************************

sub onItemFocused()
    ' Could show preview info here
    index = m.itemsGrid.itemFocused
    ' print "Item focused: "; index
end sub

sub onItemSelected()
    index = m.itemsGrid.itemSelected
    if m.itemsGrid.content = invalid then return

    itemNode = m.itemsGrid.content.getChild(index)
    if itemNode = invalid then return

    ' Get the full item data
    itemData = itemNode.getField("itemData")
    if itemData = invalid then return

    ' Show detail panel
    showDetailPanel(itemData)
end sub

sub showDetailPanel(itemData as Object)
    m.detailPanel.visible = true
    m.detailPanel.itemData = itemData
    m.detailPanel.setFocus(true)
    m.currentFocus = "detail"
end sub

sub hideDetailPanel()
    m.detailPanel.visible = false
    m.itemsGrid.setFocus(true)
    m.currentFocus = "items"
end sub

' ****************************************************************
' * Key Press Handling
' ****************************************************************

function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false

    if not press then return false

    if m.currentFocus = "detail"
        if key = "back"
            hideDetailPanel()
            handled = true
        end if
    else if m.currentFocus = "items"
        if key = "back" or key = "left"
            m.categoryList.setFocus(true)
            m.currentFocus = "categories"
            handled = true
        end if
    else if m.currentFocus = "categories"
        if key = "right"
            if m.itemsGrid.content <> invalid and m.itemsGrid.content.getChildCount() > 0
                m.itemsGrid.setFocus(true)
                m.currentFocus = "items"
                handled = true
            end if
        else if key = "back"
            ' Let system handle exit
            handled = false
        end if
    end if

    return handled
end function

' ****************************************************************
' * Weather Loading
' ****************************************************************

sub loadWeather()
    print "MainScene: Loading weather data..."
    
    m.weatherTask = CreateObject("roSGNode", "WeatherTask")
    ' Coordinates for zip 29693 (Westminster, SC area)
    m.weatherTask.latitude = "34.6645"
    m.weatherTask.longitude = "-83.0968"
    
    m.weatherTask.observeField("success", "onWeatherLoaded")
    m.weatherTask.control = "run"
end sub

sub onWeatherLoaded()
    if m.weatherTask.success
        m.weatherTemp.text = m.weatherTask.temperature
        m.weatherDesc.text = m.weatherTask.weatherDescription
        print "MainScene: Weather updated - "; m.weatherTask.temperature
    else
        m.weatherTemp.text = "N/A"
        m.weatherDesc.text = "Unable to load"
        print "MainScene: Weather error - "; m.weatherTask.error
    end if
end sub

' ****************************************************************
' * Lake Level Loading
' ****************************************************************

sub loadLakeLevel()
    print "MainScene: Loading lake level data..."
    
    m.lakeLevelTask = CreateObject("roSGNode", "LakeLevelTask")
    m.lakeLevelTask.url = "http://www.mylakehartwell.com/level"
    
    m.lakeLevelTask.observeField("success", "onLakeLevelLoaded")
    m.lakeLevelTask.control = "run"
end sub

sub onLakeLevelLoaded()
    if m.lakeLevelTask.success
        m.lakeLevel.text = m.lakeLevelTask.waterLevel
        
        ' Format the below pool message
        if m.lakeLevelTask.belowFullPool <> invalid and m.lakeLevelTask.belowFullPool <> ""
            m.lakeBelowPool.text = m.lakeLevelTask.belowFullPool + " below full pool"
        else
            m.lakeBelowPool.text = "Full pool: 660.00 ft"
        end if
        
        print "MainScene: Lake level updated - "; m.lakeLevelTask.waterLevel
    else
        m.lakeLevel.text = "N/A"
        m.lakeBelowPool.text = "Unable to load"
        print "MainScene: Lake level error - "; m.lakeLevelTask.error
    end if
end sub
