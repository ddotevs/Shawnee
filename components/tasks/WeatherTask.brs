' ****************************************************************
' * WeatherTask.brs - Fetches current weather from Open-Meteo API
' * Location: Westminster, SC area (zip 29693)
' ****************************************************************

sub init()
    m.top.functionName = "fetchWeather"
end sub

sub fetchWeather()
    lat = m.top.latitude
    lon = m.top.longitude
    
    ' Open-Meteo API - free, no API key required
    url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,weather_code&temperature_unit=fahrenheit&timezone=America%2FNew_York"
    
    print "WeatherTask: Fetching weather from "; url
    
    ' Create HTTP request
    http = CreateObject("roUrlTransfer")
    http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    http.InitClientCertificates()
    http.SetUrl(url)
    http.EnableEncodings(true)
    
    response = http.GetToString()
    
    if response = "" or response = invalid
        m.top.error = "Failed to fetch weather data"
        m.top.success = false
        print "WeatherTask: Failed to fetch weather"
        return
    end if
    
    ' Parse JSON response
    json = ParseJson(response)
    
    if json = invalid
        m.top.error = "Failed to parse weather data"
        m.top.success = false
        print "WeatherTask: Failed to parse JSON"
        return
    end if
    
    ' Extract current weather
    if json.current <> invalid
        temp = json.current.temperature_2m
        code = json.current.weather_code
        
        ' Format temperature string
        tempInt = Int(temp)
        tempStr = Str(tempInt)
        tempStr = trimString(tempStr)
        m.top.temperature = tempStr + Chr(176) + "F"
        
        m.top.weatherCode = code
        m.top.weatherDescription = getWeatherDescription(code)
        m.top.weatherIcon = getWeatherIcon(code)
        m.top.success = true
        
        print "WeatherTask: Success - "; m.top.temperature; " - "; m.top.weatherDescription
    else
        m.top.error = "No current weather data"
        m.top.success = false
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

' Map WMO weather codes to descriptions
function getWeatherDescription(code as Integer) as String
    if code = 0
        return "Clear Sky"
    else if code = 1
        return "Mainly Clear"
    else if code = 2
        return "Partly Cloudy"
    else if code = 3
        return "Overcast"
    else if code >= 45 and code <= 48
        return "Foggy"
    else if code >= 51 and code <= 55
        return "Drizzle"
    else if code >= 56 and code <= 57
        return "Freezing Drizzle"
    else if code >= 61 and code <= 65
        return "Rain"
    else if code >= 66 and code <= 67
        return "Freezing Rain"
    else if code >= 71 and code <= 77
        return "Snow"
    else if code >= 80 and code <= 82
        return "Rain Showers"
    else if code >= 85 and code <= 86
        return "Snow Showers"
    else if code = 95
        return "Thunderstorm"
    else if code >= 96 and code <= 99
        return "Thunderstorm w/ Hail"
    else
        return "Unknown"
    end if
end function

' Map WMO weather codes to text icons
function getWeatherIcon(code as Integer) as String
    if code = 0
        return "*"
    else if code >= 1 and code <= 2
        return "~*"
    else if code = 3
        return "~~"
    else if code >= 45 and code <= 48
        return "..."
    else if code >= 51 and code <= 67
        return "','"
    else if code >= 71 and code <= 77
        return "***"
    else if code >= 80 and code <= 86
        return "','"
    else if code >= 95 and code <= 99
        return "!!!"
    else
        return "?"
    end if
end function
