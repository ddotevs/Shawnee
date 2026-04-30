' ****************************************************************
' * SlideshowTask.brs - Fetches photo URLs from Cloudflare Worker
' * Returns an array of image URLs for the slideshow background
' ****************************************************************

sub init()
    m.top.functionName = "fetchPhotos"
end sub

sub fetchPhotos()
    url = m.top.workerUrl

    if url = "" or url = invalid
        m.top.error = "No worker URL configured"
        m.top.success = false
        return
    end if

    print "SlideshowTask: Fetching photos from "; url

    ' Create HTTP request
    http = CreateObject("roUrlTransfer")
    http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    http.InitClientCertificates()
    http.SetUrl(url)
    http.EnableEncodings(true)

    response = http.GetToString()

    if response = "" or response = invalid
        m.top.error = "Failed to fetch photos from worker"
        m.top.success = false
        print "SlideshowTask: Failed to fetch photos"
        return
    end if

    ' Parse JSON response
    json = ParseJson(response)

    if json = invalid
        m.top.error = "Failed to parse photo data"
        m.top.success = false
        print "SlideshowTask: Failed to parse JSON"
        return
    end if

    ' Check for error in response
    if json.error <> invalid and json.error <> ""
        m.top.error = json.error
        m.top.success = false
        print "SlideshowTask: Worker error - "; json.error
        return
    end if

    ' Extract photo URLs
    if json.photos <> invalid and json.photos.count() > 0
        m.top.photoUrls = json.photos
        m.top.success = true
        print "SlideshowTask: Success - "; json.photos.count().toStr(); " photos loaded"
    else
        m.top.error = "No photos found in album"
        m.top.success = false
        print "SlideshowTask: No photos in response"
    end if
end sub
