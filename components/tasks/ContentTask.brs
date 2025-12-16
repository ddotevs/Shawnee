' ****************************************************************
' * ContentTask.brs - JSON Content Loader
' * Fetches content from remote URL (GitHub) with local fallback
' ****************************************************************

sub init()
    m.top.functionName = "loadContent"
end sub

sub loadContent()
    content = invalid
    contentUrl = m.top.contentUrl
    contentPath = m.top.contentPath

    ' Try remote URL first (GitHub raw content)
    if contentUrl <> invalid and contentUrl <> ""
        print "ContentTask: Fetching remote content from: "; contentUrl
        content = fetchRemoteContent(contentUrl)

        if content <> invalid
            m.top.source = "remote"
            print "ContentTask: Successfully loaded remote content"
        else
            print "ContentTask: Remote fetch failed, falling back to local"
        end if
    end if

    ' Fall back to local file if remote failed or not configured
    if content = invalid
        print "ContentTask: Loading local content from: "; contentPath
        content = loadLocalContent(contentPath)

        if content <> invalid
            m.top.source = "local"
            print "ContentTask: Successfully loaded local content"
        end if
    end if

    ' Final check
    if content = invalid
        m.top.error = "Failed to load content from both remote and local sources"
        return
    end if

    ' Sort categories and items by sortOrder
    if content.categories <> invalid
        sortByOrder(content.categories)
        for each category in content.categories
            if category.items <> invalid
                sortByOrder(category.items)
            end if
        end for
    end if

    m.top.content = content
end sub

' ****************************************************************
' * Remote Content Fetching (GitHub Raw URL)
' ****************************************************************

function fetchRemoteContent(url as String) as Object
    request = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")

    request.setMessagePort(port)
    request.setUrl(url)
    request.setCertificatesFile("common:/certs/ca-bundle.crt")
    request.initClientCertificates()
    request.enableHostVerification(false)
    request.enablePeerVerification(false)
    request.setRequest("GET")

    ' Add headers for GitHub raw content
    request.addHeader("Accept", "application/json")
    request.addHeader("Cache-Control", "no-cache")

    ' Set timeout (10 seconds)
    timeout = 10000

    if request.asyncGetToString()
        msg = wait(timeout, port)

        if type(msg) = "roUrlEvent"
            responseCode = msg.getResponseCode()
            print "ContentTask: HTTP Response Code: "; responseCode

            if responseCode = 200
                jsonString = msg.getString()
                if jsonString <> invalid and jsonString <> ""
                    content = ParseJson(jsonString)
                    if content <> invalid
                        return content
                    else
                        print "ContentTask: Failed to parse remote JSON"
                    end if
                else
                    print "ContentTask: Empty response from remote"
                end if
            else
                print "ContentTask: HTTP error: "; responseCode
                failureReason = msg.getFailureReason()
                if failureReason <> invalid
                    print "ContentTask: Failure reason: "; failureReason
                end if
            end if
        else
            print "ContentTask: Request timeout or no response"
        end if
    else
        print "ContentTask: Failed to initiate async request"
    end if

    return invalid
end function

' ****************************************************************
' * Local Content Loading (Fallback)
' ****************************************************************

function loadLocalContent(path as String) as Object
    jsonString = ReadAsciiFile(path)

    if jsonString = "" or jsonString = invalid
        print "ContentTask: Failed to read local file: "; path
        return invalid
    end if

    content = ParseJson(jsonString)

    if content = invalid
        print "ContentTask: Failed to parse local JSON"
        return invalid
    end if

    return content
end function

' ****************************************************************
' * Utility Functions
' ****************************************************************

sub sortByOrder(items as Object)
    ' Simple bubble sort by sortOrder
    n = items.count()
    for i = 0 to n - 2
        for j = 0 to n - 2 - i
            order1 = 999
            order2 = 999
            if items[j].sortOrder <> invalid then order1 = items[j].sortOrder
            if items[j + 1].sortOrder <> invalid then order2 = items[j + 1].sortOrder

            if order1 > order2
                temp = items[j]
                items[j] = items[j + 1]
                items[j + 1] = temp
            end if
        end for
    end for
end sub
