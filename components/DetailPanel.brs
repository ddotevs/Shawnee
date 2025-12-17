' ****************************************************************
' * DetailPanel.brs - Detail View Logic
' * Parses and displays comprehensive item information
' ****************************************************************

sub init()
    ' Get references to UI elements
    m.detailPoster = m.top.findNode("detailPoster")
    m.detailTitle = m.top.findNode("detailTitle")
    m.shortDescription = m.top.findNode("shortDescription")
    m.fullDescription = m.top.findNode("fullDescription")

    ' Quick info cards
    m.addressCard = m.top.findNode("addressCard")
    m.addressLabel = m.top.findNode("addressLabel")
    m.phoneCard = m.top.findNode("phoneCard")
    m.phoneLabel = m.top.findNode("phoneLabel")
    m.hoursCard = m.top.findNode("hoursCard")
    m.hoursLabel = m.top.findNode("hoursLabel")
    m.distanceCard = m.top.findNode("distanceCard")
    m.distanceLabel = m.top.findNode("distanceLabel")

    ' Meta row
    m.priceLabel = m.top.findNode("priceLabel")
    m.ratingLabel = m.top.findNode("ratingLabel")
    m.reservationLabel = m.top.findNode("reservationLabel")

    ' Tips
    m.tipsCard = m.top.findNode("tipsCard")
    m.tipsLabel = m.top.findNode("tipsLabel")

    ' Tags
    m.tagsLabel = m.top.findNode("tagsLabel")

    ' Extended details and bottom section
    m.bottomSection = m.top.findNode("bottomSection")
    m.extendedDetails = m.top.findNode("extendedDetails")
end sub

sub onItemDataChanged()
    item = m.top.itemData

    if item = invalid
        clearAllFields()
        return
    end if

    ' Set image
    if item.image <> invalid
        m.detailPoster.uri = item.image
    else if item.icon <> invalid
        m.detailPoster.uri = item.icon
    else
        m.detailPoster.uri = ""
    end if

    ' Set title
    m.detailTitle.text = safeString(item.title)

    ' Set short description
    m.shortDescription.text = safeString(item.shortDescription)

    ' Set full description
    m.fullDescription.text = safeString(item.description)

    ' Address
    if item.address <> invalid and item.address <> ""
        m.addressCard.visible = true
        m.addressLabel.text = item.address
    else
        m.addressCard.visible = false
    end if

    ' Phone
    if item.phone <> invalid and item.phone <> ""
        m.phoneCard.visible = true
        m.phoneLabel.text = item.phone
    else
        m.phoneCard.visible = false
    end if

    ' Hours
    if item.hours <> invalid and item.hours <> ""
        m.hoursCard.visible = true
        m.hoursLabel.text = item.hours
    else
        m.hoursCard.visible = false
    end if

    ' Distance
    if item.distance <> invalid and item.distance <> ""
        m.distanceCard.visible = true
        m.distanceLabel.text = item.distance + " away"
    else
        m.distanceCard.visible = false
    end if

    ' Price
    if item.priceRange <> invalid and item.priceRange <> ""
        m.priceLabel.visible = true
        m.priceLabel.text = "Price: " + item.priceRange
    else
        m.priceLabel.visible = false
    end if

    ' Rating
    if item.rating <> invalid
        m.ratingLabel.visible = true
        m.ratingLabel.text = "Rating: " + item.rating.toStr()
    else
        m.ratingLabel.visible = false
    end if

    ' Reservation
    if item.reservationRequired = true
        m.reservationLabel.visible = true
        m.reservationLabel.text = "Reservation Required"
    else
        m.reservationLabel.visible = false
    end if

    ' Tips
    if item.tips <> invalid and item.tips <> ""
        m.tipsCard.visible = true
        m.tipsLabel.text = item.tips
    else
        m.tipsCard.visible = false
    end if

    ' Tags
    if item.tags <> invalid and item.tags.count() > 0
        m.tagsLabel.visible = true
        tagStr = ""
        for each tag in item.tags
            if tagStr <> "" then tagStr = tagStr + "  |  "
            tagStr = tagStr + tag
        end for
        m.tagsLabel.text = tagStr
    else
        m.tagsLabel.visible = false
    end if

    ' Build extended details for special item types
    buildExtendedDetails(item)
end sub

sub buildExtendedDetails(item as Object)
    detailText = ""

    ' WiFi details
    if item.details <> invalid
        details = item.details

        if details.networkName <> invalid
            detailText = detailText + "WiFi: " + details.networkName
            if details.password <> invalid
                detailText = detailText + "   |   Password: " + details.password
            end if
            detailText = detailText + "     "
        end if

        if details.checkInTime <> invalid
            detailText = detailText + "Check-in: " + details.checkInTime + "     "
        end if
        if details.checkOutTime <> invalid
            detailText = detailText + "Check-out: " + details.checkOutTime + "     "
        end if
        if details.keyLocation <> invalid
            detailText = detailText + "Key: " + details.keyLocation + "     "
        end if

        if details.instructions <> invalid
            detailText = detailText + details.instructions + "     "
        end if
    end if

    ' Emergency contacts
    if item.contacts <> invalid and item.contacts.count() > 0
        for each contact in item.contacts
            detailText = detailText + contact.name + ": " + contact.phone
            if contact.available <> invalid
                detailText = detailText + " (" + contact.available + ")"
            end if
            detailText = detailText + chr(10)
        end for
    end if

    ' House rules
    if item.rules <> invalid and item.rules.count() > 0
        detailText = detailText + "RULES: "
        for each rule in item.rules
            detailText = detailText + rule + "   |   "
        end for
    end if

    ' Appliances
    if item.appliances <> invalid and item.appliances.count() > 0
        detailText = detailText + "APPLIANCES: "
        for each appliance in item.appliances
            detailText = detailText + appliance.name
            if appliance.brand <> invalid
                detailText = detailText + " (" + appliance.brand + ")"
            end if
            if appliance.instructions <> invalid
                detailText = detailText + " - " + appliance.instructions
            end if
            detailText = detailText + "   |   "
        end for
    end if

    ' Dietary options
    if item.dietaryOptions <> invalid and item.dietaryOptions.count() > 0
        dietStr = ""
        for each diet in item.dietaryOptions
            if dietStr <> "" then dietStr = dietStr + ", "
            dietStr = dietStr + diet
        end for
        detailText = detailText + "Dietary: " + dietStr + "     "
    end if

    ' Amenities
    if item.amenities <> invalid and item.amenities.count() > 0
        amenStr = ""
        for each amenity in item.amenities
            if amenStr <> "" then amenStr = amenStr + ", "
            amenStr = amenStr + amenity
        end for
        detailText = detailText + "Amenities: " + amenStr + "     "
    end if

    ' Show bottom section if we have extended details
    if detailText <> ""
        m.bottomSection.visible = true
        m.extendedDetails.visible = true
        m.extendedDetails.text = detailText
    else
        m.bottomSection.visible = false
        m.extendedDetails.visible = false
    end if
end sub

sub clearAllFields()
    m.detailPoster.uri = ""
    m.detailTitle.text = ""
    m.shortDescription.text = ""
    m.fullDescription.text = ""
    m.addressCard.visible = false
    m.phoneCard.visible = false
    m.hoursCard.visible = false
    m.distanceCard.visible = false
    m.priceLabel.visible = false
    m.ratingLabel.visible = false
    m.reservationLabel.visible = false
    m.tipsCard.visible = false
    m.tagsLabel.visible = false
    m.bottomSection.visible = false
    m.extendedDetails.visible = false
end sub

function safeString(value as Dynamic) as String
    if value = invalid then return ""
    return value.toStr()
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
    ' Let MainScene handle all key events including back button
    return false
end function
