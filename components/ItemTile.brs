' ****************************************************************
' * ItemTile.brs - Grid Item Tile Logic
' * Handles content display and focus animation
' ****************************************************************

sub init()
    m.tileBackground = m.top.findNode("tileBackground")
    m.focusBorder = m.top.findNode("focusBorder")
    m.itemPoster = m.top.findNode("itemPoster")
    m.titleLabel = m.top.findNode("titleLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.emergencyBadge = m.top.findNode("emergencyBadge")
end sub

sub onContentChanged()
    itemContent = m.top.itemContent

    if itemContent = invalid
        m.titleLabel.text = ""
        m.descriptionLabel.text = ""
        m.itemPoster.uri = ""
        m.emergencyBadge.visible = false
        return
    end if

    ' Set title
    if itemContent.title <> invalid
        m.titleLabel.text = itemContent.title
    else
        m.titleLabel.text = ""
    end if

    ' Set description
    shortDesc = itemContent.getField("shortDescription")
    if shortDesc <> invalid and shortDesc <> ""
        m.descriptionLabel.text = shortDesc
    else if itemContent.description <> invalid
        m.descriptionLabel.text = itemContent.description
    else
        m.descriptionLabel.text = ""
    end if

    ' Set image
    if itemContent.hdPosterUrl <> invalid and itemContent.hdPosterUrl <> ""
        m.itemPoster.uri = itemContent.hdPosterUrl
    else
        m.itemPoster.uri = "pkg:/images/placeholder.png"
    end if

    ' Check for emergency flag
    itemData = itemContent.getField("itemData")
    if itemData <> invalid and itemData.isEmergency = true
        m.emergencyBadge.visible = true
    else
        m.emergencyBadge.visible = false
    end if
end sub

sub onFocusChanged()
    focusPercent = m.top.focusPercent

    ' Animate focus border opacity
    m.focusBorder.opacity = focusPercent

    ' Scale effect on focus
    if focusPercent > 0.5
        m.tileBackground.color = "#1e2a4a"
    else
        m.tileBackground.color = "#16213e"
    end if
end sub

