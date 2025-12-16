' ****************************************************************
' * Shawnee Channel - Main Entry Point
' * A simple read-only Roku channel using BrightScript
' ****************************************************************

sub Main(args as Dynamic)
    ' Initialize the screen and message port
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    ' Create and show the main scene
    scene = screen.CreateScene("MainScene")
    screen.show()

    ' Handle deep linking if channel was launched with content ID
    if args.contentId <> invalid and args.mediaType <> invalid
        scene.contentId = args.contentId
        scene.mediaType = args.mediaType
    end if

    ' Main event loop
    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)

        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed()
                return
            end if
        end if
    end while
end sub

' ****************************************************************
' * Utility Functions
' ****************************************************************

function GetAppInfo() as Object
    appInfo = CreateObject("roAppInfo")
    return {
        id: appInfo.GetID(),
        title: appInfo.GetTitle(),
        version: appInfo.GetVersion(),
        devId: appInfo.GetDevID()
    }
end function

