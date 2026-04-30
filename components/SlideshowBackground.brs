' ****************************************************************
' * SlideshowBackground.brs - Photo slideshow with crossfade
' * Cycles through album photos with smooth opacity transitions
' ****************************************************************

sub init()
    m.posterA = m.top.findNode("posterA")
    m.posterB = m.top.findNode("posterB")

    ' Track which poster is currently active (visible)
    m.activePoster = "A"
    m.currentIndex = 0
    m.photos = []

    ' Create the slideshow timer
    m.timer = CreateObject("roSGNode", "Timer")
    m.timer.repeat = true
    m.timer.duration = m.top.interval
    m.timer.observeField("fire", "onTimerFire")

    ' Create fade-in animation for poster B
    m.fadeInB = CreateObject("roSGNode", "Animation")
    m.fadeInB.duration = 1.5
    m.fadeInB.easeFunction = "linear"
    fieldInterp = m.fadeInB.createChild("FloatFieldInterpolator")
    fieldInterp.fieldToInterp = "posterB.opacity"
    fieldInterp.key = [0.0, 1.0]
    fieldInterp.keyValue = [0.0, 1.0]
    m.top.appendChild(m.fadeInB)

    ' Create fade-in animation for poster A
    m.fadeInA = CreateObject("roSGNode", "Animation")
    m.fadeInA.duration = 1.5
    m.fadeInA.easeFunction = "linear"
    fieldInterpA = m.fadeInA.createChild("FloatFieldInterpolator")
    fieldInterpA.fieldToInterp = "posterA.opacity"
    fieldInterpA.key = [0.0, 1.0]
    fieldInterpA.keyValue = [0.0, 1.0]
    m.top.appendChild(m.fadeInA)

    ' Create fade-out animation for poster A
    m.fadeOutA = CreateObject("roSGNode", "Animation")
    m.fadeOutA.duration = 1.5
    m.fadeOutA.easeFunction = "linear"
    fieldInterpOutA = m.fadeOutA.createChild("FloatFieldInterpolator")
    fieldInterpOutA.fieldToInterp = "posterA.opacity"
    fieldInterpOutA.key = [0.0, 1.0]
    fieldInterpOutA.keyValue = [1.0, 0.0]
    m.top.appendChild(m.fadeOutA)

    ' Create fade-out animation for poster B
    m.fadeOutB = CreateObject("roSGNode", "Animation")
    m.fadeOutB.duration = 1.5
    m.fadeOutB.easeFunction = "linear"
    fieldInterpOutB = m.fadeOutB.createChild("FloatFieldInterpolator")
    fieldInterpOutB.fieldToInterp = "posterB.opacity"
    fieldInterpOutB.key = [0.0, 1.0]
    fieldInterpOutB.keyValue = [1.0, 0.0]
    m.top.appendChild(m.fadeOutB)
end sub

sub onPhotoUrlsChanged()
    m.photos = m.top.photoUrls

    if m.photos = invalid or m.photos.count() = 0
        m.timer.control = "stop"
        return
    end if

    ' Load the first image immediately
    m.currentIndex = 0
    m.posterA.uri = m.photos[0]
    m.posterA.opacity = 1.0
    m.posterB.opacity = 0.0
    m.activePoster = "A"

    ' Start the timer if we have more than one photo
    if m.photos.count() > 1
        m.timer.duration = m.top.interval
        m.timer.control = "start"
    end if

    print "SlideshowBackground: Loaded "; m.photos.count().toStr(); " photos"
end sub

sub onTimerFire()
    if m.photos = invalid or m.photos.count() < 2
        return
    end if

    ' Advance to the next photo
    m.currentIndex = m.currentIndex + 1
    if m.currentIndex >= m.photos.count()
        m.currentIndex = 0
    end if

    nextUrl = m.photos[m.currentIndex]

    ' Crossfade: load next image on inactive poster, then fade
    if m.activePoster = "A"
        ' Load next on B, fade B in and A out
        m.posterB.uri = nextUrl
        m.fadeInB.control = "start"
        m.fadeOutA.control = "start"
        m.activePoster = "B"
    else
        ' Load next on A, fade A in and B out
        m.posterA.uri = nextUrl
        m.fadeInA.control = "start"
        m.fadeOutB.control = "start"
        m.activePoster = "A"
    end if
end sub
