module DatesBenchmarks
# Based on https://github.com/quinnj/Dates.jl/blob/master/perf/perf.jl


using BenchmarkTools

const SUITE = BenchmarkGroup()

g = addgroup!(SUITE, "construction")

g["Date"] = @benchmarkable Dates.Date(2014,1,1)
g["DateTime"] = @benchmarkable Dates.DateTime(2014,1,1,0,0,0,0)


g = addgroup!(SUITE, "accessor")

_date = Date(2014,7,19)
_datetime = DateTime(2014,7,19,15,13,12,512)

g["year"] = @benchmarkable Dates.year($_date)
g["month"] = @benchmarkable Dates.month($_date)
g["day"] = @benchmarkable Dates.day($_date)
g["hour"] = @benchmarkable Dates.hour($_datetime)
g["minute"] = @benchmarkable Dates.minute($_datetime)
g["second"] = @benchmarkable Dates.second($_datetime)
g["millisecond"] = @benchmarkable Dates.millisecond($_datetime)


g = addgroup!(SUITE, "conversion")

g["DateTime -> Date"] = @benchmarkable Dates.Date($_datetime)
g["Date -> DateTime"] = @benchmarkable Dates.DateTime($_date)


g = addgroup!(SUITE, "string")

g["Date"] = @benchmarkable string($_date)
g["DateTime"] = @benchmarkable string($_datetime)


g = addgroup!(SUITE, "query")

g["isleapyear","Date"]            = @benchmarkable Dates.isleapyear($_date)
g["isleapyear","DateTime"]        = @benchmarkable Dates.isleapyear($_datetime)
g["firstdayofmonth","Date"]       = @benchmarkable Dates.firstdayofmonth($_date)
g["firstdayofmonth","DateTime"]   = @benchmarkable Dates.firstdayofmonth($_datetime)
g["lastdayofmonth","Date"]        = @benchmarkable Dates.lastdayofmonth($_date)
g["lastdayofmonth","DateTime"]    = @benchmarkable Dates.lastdayofmonth($_datetime)
g["dayofweek","Date"]             = @benchmarkable Dates.dayofweek($_date)
g["dayofweek","DateTime"]         = @benchmarkable Dates.dayofweek($_datetime)
g["dayofweekofmonth","Date"]      = @benchmarkable Dates.dayofweekofmonth($_date)
g["dayofweekofmonth","DateTime"]  = @benchmarkable Dates.dayofweekofmonth($_datetime)
g["daysofweekinmonth","Date"]     = @benchmarkable Dates.daysofweekinmonth($_date)
g["daysofweekinmonth","DateTime"] = @benchmarkable Dates.daysofweekinmonth($_datetime)
g["firstdayofweek","Date"]        = @benchmarkable Dates.firstdayofweek($_date)
g["firstdayofweek","DateTime"]    = @benchmarkable Dates.firstdayofweek($_datetime)
g["lastdayofweek","Date"]         = @benchmarkable Dates.lastdayofweek($_date)
g["lastdayofweek","DateTime"]     = @benchmarkable Dates.lastdayofweek($_datetime)
g["dayofyear","Date"]             = @benchmarkable Dates.dayofyear($_date)
g["dayofyear","DateTime"]         = @benchmarkable Dates.dayofyear($_datetime)

for b in values(g)
    b.params.time_tolerance = 0.25
end

g = addgroup!(SUITE, "arithmetic")

_years = Dates.Year(3)
_months = Dates.Month(7)
_days = Dates.Day(78)
_hours = Dates.Hour(13)
_minutes = Dates.Minute(22)
_seconds = Dates.Second(22)
_milliseconds = Dates.Millisecond(333)

g["Date","Year"] = @benchmarkable $_date + $_years
g["DateTime","Year"] = @benchmarkable $_datetime + $_years
g["Date","Month"] = @benchmarkable $_date + $_months
g["DateTime","Month"] = @benchmarkable $_datetime + $_months
g["Date","Day"] = @benchmarkable $_date + $_days
g["DateTime","Day"] = @benchmarkable $_datetime + $_days
g["DateTime","Hour"] = @benchmarkable $_datetime + $_hours
g["DateTime","Minute"] = @benchmarkable $_datetime + $_minutes
g["DateTime","Second"] = @benchmarkable $_datetime + $_seconds
g["DateTime","Millisecond"] = @benchmarkable $_datetime + $_milliseconds


g = addgroup!(SUITE, "parse")

_datetime_str = "2016-02-19T12:34:56.78"
_date_str = "2016-02-19"

g["DateTime"] = @benchmarkable DateTime($_datetime_str)
g["Date"] = @benchmarkable Date($_date_str)

_custom_date_str = "20160219"
_custom_date_fmt = "yyyymmdd"
_custom_datetime_str = "20160219 123456.78"
_custom_datetime_fmt = "yyyymmdd HHMMSS.sss"

# Note: Also benchmarks the time it takes to create the custom format
g["Date","DateFormat"] = @benchmarkable Date($_custom_date_str, $_custom_date_fmt)
g["DateTime","DateFormat"] = @benchmarkable DateTime($_custom_datetime_str, $_custom_datetime_fmt)

g["DateTime","ISODateTimeFormat"] = @benchmarkable DateTime($_datetime_str, $(Dates.ISODateTimeFormat))
g["Date","ISODateFormat"] = @benchmarkable Date($_date_str, $(Dates.ISODateFormat))
g["DateTime","RFC1123Format","Titlecase"] = @benchmarkable DateTime("Sat, 12 Nov 2016 07:45:36", $(Dates.RFC1123Format))
g["DateTime","RFC1123Format","Lowercase"] = @benchmarkable DateTime("sat, 12 Nov 2016 07:45:36", $(Dates.RFC1123Format))
g["DateTime","RFC1123Format","Mixedcase"] = @benchmarkable DateTime("sAt, 12 Nov 2016 07:45:36", $(Dates.RFC1123Format))

end
