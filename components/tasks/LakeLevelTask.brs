' ****************************************************************
' * LakeLevelTask.brs - Scrapes Lake Hartwell water level
' * Source: mylakehartwell.com/level
' ****************************************************************

sub init()
    m.top.functionName = "fetchLakeLevel"
end sub

sub fetchLakeLevel()
    url = m.top.url
    
    print "LakeLevelTask: Fetching lake level from "; url
    
    ' Create HTTP request
    http = CreateObject("roUrlTransfer")
    http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    http.InitClientCertificates()
    http.SetUrl(url)
    http.EnableEncodings(true)
    
    response = http.GetToString()
    
    if response = "" or response = invalid
        m.top.error = "Failed to fetch lake level data"
        m.top.success = false
        print "LakeLevelTask: Failed to fetch page"
        return
    end if
    
    print "LakeLevelTask: Got response, parsing HTML..."
    
    ' Parse the HTML to extract water level
    parseLakeData(response)
end sub

sub parseLakeData(html as String)
    ' Find the water level value (the big number in 46px font)
    ' Pattern: font-size:46px; font-weight:bold; color:#09C;">653.29</div>
    
    levelMarker = "font-size:46px"
    levelPos = html.Instr(levelMarker)
    
    if levelPos >= 0
        ' Find the > after the style
        searchStart = levelPos + Len(levelMarker)
        tempHtml = Mid(html, searchStart + 1)
        gtPos = tempHtml.Instr(">")
        
        if gtPos >= 0
            ' Find the closing </div>
            afterGt = Mid(tempHtml, gtPos + 2)
            endPos = afterGt.Instr("</div>")
            
            if endPos >= 0
                ' Extract the level value
                levelValue = Left(afterGt, endPos)
                levelValue = trimString(levelValue)
                m.top.waterLevel = levelValue
                print "LakeLevelTask: Found water level: "; levelValue
            end if
        end if
    end if
    
    ' Find "below full pool" info
    ' Pattern: Level is X.XX feet
    belowMarker = "Level is "
    belowPos = html.Instr(belowMarker)
    
    if belowPos >= 0
        searchStart = belowPos + Len(belowMarker)
        tempHtml = Mid(html, searchStart + 1)
        endPos = tempHtml.Instr("</font>")
        
        if endPos >= 0
            belowValue = Left(tempHtml, endPos)
            belowValue = trimString(belowValue)
            m.top.belowFullPool = belowValue
            print "LakeLevelTask: Found below pool: "; belowValue
        end if
    end if
    
    ' Check if we got the main data
    if m.top.waterLevel <> invalid and m.top.waterLevel <> ""
        m.top.success = true
        print "LakeLevelTask: Success!"
    else
        m.top.error = "Could not parse water level from page"
        m.top.success = false
        print "LakeLevelTask: Failed to parse water level"
    end if
end sub

' Helper function to trim whitespace from string
function trimString(str as String) as String
    result = str
    ' Remove leading whitespace
    while Len(result) > 0 and (Left(result, 1) = " " or Left(result, 1) = Chr(9) or Left(result, 1) = Chr(10) or Left(result, 1) = Chr(13))
        result = Mid(result, 2)
    end while
    ' Remove trailing whitespace
    while Len(result) > 0 and (Right(result, 1) = " " or Right(result, 1) = Chr(9) or Right(result, 1) = Chr(10) or Right(result, 1) = Chr(13))
        result = Left(result, Len(result) - 1)
    end while
    return result
end function
