import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Storage;

class ZmanimEngine {
    class Coordinates {
        var lat as Float;
        var lon as Float;

        function initialize(aLat as Float, aLon as Float) {
            lat = aLat;
            lon = aLon;
        }
    }

    class GregorianDateParts {
        var year as Number;
        var month as Number;
        var day as Number;

        function initialize(aYear as Number, aMonth as Number, aDay as Number) {
            year = aYear;
            month = aMonth;
            day = aDay;
        }
    }

    class ShabbatTimes {
        var entry as Float;
        var exit as Float;
        var entryMoment as Time.Moment;
        var exitMoment as Time.Moment;
        var entryJd as Number;
        var exitJd as Number;

        function initialize(aEntry as Float, aExit as Float, aEntryMoment as Time.Moment, aExitMoment as Time.Moment, aEntryJd as Number, aExitJd as Number) {
            entry = aEntry;
            exit = aExit;
            entryMoment = aEntryMoment;
            exitMoment = aExitMoment;
            entryJd = aEntryJd;
            exitJd = aExitJd;
        }
    }

    private var _cachedShabbatTimes = null;
    private var _cachedShabbatKey as String = "";

    function getLocationId() as String {
        var loc = KodeshSettings.getValue("location");

        if (loc == null) {
            return "loc_jerusalem";
        }

        return loc as String;
    }

    function getCoordinates() as Coordinates {
        var locStr = getLocationId();

        if (locStr.equals("loc_jerusalem")) { return new Coordinates(31.7683f, 35.2137f); }
        if (locStr.equals("loc_telaviv")) { return new Coordinates(32.0853f, 34.7818f); }
        if (locStr.equals("loc_haifa")) { return new Coordinates(32.7940f, 34.9896f); }
        if (locStr.equals("loc_eilat")) { return new Coordinates(29.5577f, 34.9519f); }

        if (locStr.equals("loc_gps")) {
            if (ShabbatMode.isEnabled()) {
                var frozen = ShabbatMode.getFrozenGpsCoordinates();
                if (frozen != null) { return new Coordinates(frozen.lat, frozen.lon); }
            }

            var last = ShabbatMode.getLastGpsCoordinates();
            if (last != null) { return new Coordinates(last.lat, last.lon); }

            ShabbatMode.requestGpsUpdate();
        }

        return new Coordinates(31.7683f, 35.2137f);
    }

    function constrain(val as Float, limit as Float) as Float {
        while (val < 0.0f) { val += limit; }
        while (val >= limit) { val -= limit; }
        return val;
    }

    function isGregorianLeapYear(year as Number) as Boolean {
        if ((year % 400) == 0) { return true; }
        if ((year % 100) == 0) { return false; }
        return (year % 4) == 0;
    }

    function daysInGregorianMonth(year as Number, month as Number) as Number {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) { return 31; }
        if (month == 4 || month == 6 || month == 9 || month == 11) { return 30; }
        return isGregorianLeapYear(year) ? 29 : 28;
    }

    function getDayOfYear(year as Number, month as Number, day as Number) as Number {
        var n1 = Math.floor(275.0f * month.toFloat() / 9.0f).toNumber();
        var n2 = Math.floor((month.toFloat() + 9.0f) / 12.0f).toNumber();
        var n3 = 1 + Math.floor((year.toFloat() - (4.0f * Math.floor(year.toFloat() / 4.0f)) + 2.0f) / 3.0f).toNumber();
        return n1 - (n2 * n3) + day - 30;
    }

    function calcSunsetUTC(lat as Float, lon as Float, year as Number, month as Number, day as Number, zenith as Float) as Float {
        var n = getDayOfYear(year, month, day);
        var lngHour = lon / 15.0f;
        var t = n.toFloat() + ((18.0f - lngHour) / 24.0f);
        var m = (0.9856f * t) - 3.289f;
        var l = m + (1.916f * Math.sin(Math.toRadians(m))) + (0.020f * Math.sin(Math.toRadians(2.0f * m))) + 282.634f;
        l = constrain(l, 360.0f);
        var ra = Math.toDegrees(Math.atan(0.91764f * Math.tan(Math.toRadians(l)))).toFloat();
        ra = constrain(ra, 360.0f);
        var lQuadrant = Math.floor(l / 90.0f).toFloat() * 90.0f;
        var raQuadrant = Math.floor(ra / 90.0f).toFloat() * 90.0f;
        ra = (ra + (lQuadrant - raQuadrant)) / 15.0f;
        var sinDec = 0.39782f * Math.sin(Math.toRadians(l));
        var cosDec = Math.cos(Math.asin(sinDec));
        var cosH = (Math.cos(Math.toRadians(zenith)) - (sinDec * Math.sin(Math.toRadians(lat)))) / (cosDec * Math.cos(Math.toRadians(lat)));
        if (cosH < -1.0f || cosH > 1.0f) { return -1.0f; }
        var h = Math.toDegrees(Math.acos(cosH)) / 15.0f;
        var localMeanTime = h + ra - (0.06571f * t) - 6.622f;
        return constrain(localMeanTime - lngHour, 24.0f);
    }

    function lastSundayInMonth(year as Number, month as Number) as Number {
        var pLookup = new ParashaLookup();
        var lastDay = daysInGregorianMonth(year, month);
        var jd = pLookup.gregorianToJd(year, month, lastDay);
        var weekday = pLookup.weekdayFromJd(jd);
        return lastDay - (weekday - 1);
    }

    function israelDstStartDay(year as Number) as Number { return lastSundayInMonth(year, 3) - 2; }
    function israelDstEndDay(year as Number) as Number { return lastSundayInMonth(year, 10); }

    function getIsraelUtcOffsetHours(year as Number, month as Number, day as Number, localHour as Float) as Float {
        if (month < 3 || month > 10) { return 2.0f; }
        if (month > 3 && month < 10) { return 3.0f; }
        if (month == 3) {
            var startDay = israelDstStartDay(year);
            if (day < startDay) { return 2.0f; }
            if (day > startDay) { return 3.0f; }
            return localHour >= 2.0f ? 3.0f : 2.0f;
        }
        var endDay = israelDstEndDay(year);
        if (day < endDay) { return 3.0f; }
        if (day > endDay) { return 2.0f; }
        return localHour < 2.0f ? 3.0f : 2.0f;
    }

    function isJerusalemArea(coords as Coordinates) as Boolean { return coords.lat >= 31.60f && coords.lat <= 31.90f && coords.lon >= 35.05f && coords.lon <= 35.35f; }
    function isHaifaOrZichronArea(coords as Coordinates) as Boolean { return coords.lat >= 32.50f && coords.lat <= 32.90f && coords.lon >= 34.80f && coords.lon <= 35.15f; }
    function isTelAvivArea(coords as Coordinates) as Boolean { return coords.lat >= 31.95f && coords.lat <= 32.25f && coords.lon >= 34.65f && coords.lon <= 34.95f; }

    function getManualCandleOffsetMinutes() as Float {
        var offsetStr = KodeshSettings.getValue("candleOffset");
        if (offsetStr != null) {
            var value = offsetStr as String;
            if (value.equals("offset_30")) { return 30.0f; }
            if (value.equals("offset_40")) { return 40.0f; }
            if (value.equals("offset_20")) { return 20.0f; }
        }
        return -1.0f;
    }

    function getCandleOffsetMinutes(coords as Coordinates) as Float {
        var locStr = getLocationId();
        if (locStr.equals("loc_jerusalem")) { return 40.0f; }
        if (locStr.equals("loc_haifa")) { return 30.0f; }
        if (locStr.equals("loc_telaviv")) { return 22.0f; }
        if (locStr.equals("loc_gps")) {
            if (isJerusalemArea(coords)) { return 40.0f; }
            if (isHaifaOrZichronArea(coords)) { return 30.0f; }
            if (isTelAvivArea(coords)) { return 22.0f; }
        }
        var manualOffset = getManualCandleOffsetMinutes();
        return manualOffset > 0.0f ? manualOffset : 20.0f;
    }

    function getHavdalahOffsetMinutes() as Float {
        var endMethod = KodeshSettings.getValue("endMethod");
        if (endMethod != null && (endMethod as String).equals("end_rt")) { return 72.0f; }
        return 45.0f;
    }

    function jdToGregorianParts(jd as Number) as GregorianDateParts {
        var pLookup = new ParashaLookup();
        var dateArr = pLookup.jdToGregorian(jd);
        return new GregorianDateParts(dateArr[0] as Number, dateArr[1] as Number, dateArr[2] as Number);
    }

    function calcEntryHour(entryJd as Number, coords as Coordinates) as Float {
        var parts = jdToGregorianParts(entryJd);
        var offsetHours = getIsraelUtcOffsetHours(parts.year, parts.month, parts.day, 18.0f);
        var sunsetUTC = calcSunsetUTC(coords.lat, coords.lon, parts.year, parts.month, parts.day, 90.833f);
        if (sunsetUTC == -1.0f) { return 18.0f; }
        var entryHour = constrain(sunsetUTC + offsetHours, 24.0f) - (getCandleOffsetMinutes(coords) / 60.0f);
        return entryHour < 0.0f ? entryHour + 24.0f : entryHour;
    }

    function calcExitHour(exitJd as Number, coords as Coordinates) as Float {
        var parts = jdToGregorianParts(exitJd);
        var offsetHours = getIsraelUtcOffsetHours(parts.year, parts.month, parts.day, 18.0f);
        var sunsetUTC = calcSunsetUTC(coords.lat, coords.lon, parts.year, parts.month, parts.day, 90.833f);
        if (sunsetUTC == -1.0f) { return 19.0f; }
        return constrain(constrain(sunsetUTC + offsetHours, 24.0f) + (getHavdalahOffsetMinutes() / 60.0f), 24.0f);
    }

    function getMomentForLocalHour(jd as Number, localHour as Float) as Time.Moment {
        var localParts = jdToGregorianParts(jd);
        var offsetHours = getIsraelUtcOffsetHours(localParts.year, localParts.month, localParts.day, localHour);
        var utcHour = localHour - offsetHours;
        var utcJd = jd;
        while (utcHour < 0.0f) { utcHour += 24.0f; utcJd -= 1; }
        while (utcHour >= 24.0f) { utcHour -= 24.0f; utcJd += 1; }
        var utcParts = jdToGregorianParts(utcJd);
        var hourInt = Math.floor(utcHour).toNumber();
        var minFloat = (utcHour - hourInt) * 60.0f;
        var minInt = Math.floor(minFloat).toNumber();
        var secInt = Math.floor((minFloat - minInt) * 60.0f).toNumber();
        if (hourInt >= 24) { hourInt = 23; minInt = 59; secInt = 59; }
        if (hourInt < 0) { hourInt = 0; minInt = 0; secInt = 0; }
        if (minInt >= 60) { minInt = 59; }
        if (secInt >= 60) { secInt = 59; }
        return Gregorian.moment({ :year => utcParts.year, :month => utcParts.month, :day => utcParts.day, :hour => hourInt, :minute => minInt, :second => secInt });
    }

    function calculateShabbatTimesForJds(entryJd as Number, exitJd as Number, coords as Coordinates) as ShabbatTimes? {
        var entryHour = calcEntryHour(entryJd, coords);
        var exitHour = calcExitHour(exitJd, coords);
        return new ShabbatTimes(entryHour, exitHour, getMomentForLocalHour(entryJd, entryHour), getMomentForLocalHour(exitJd, exitHour), entryJd, exitJd);
    }

    function momentToMinuteIndex(m) as Number {
        var info = Gregorian.info(m, Time.FORMAT_SHORT);
        return (((info.year * 12 + info.month) * 31 + info.day) * 24 + info.hour) * 60 + info.min;
    }

    function getCacheKey(now as Time.Moment, coords as Coordinates) as String {
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var latKey = (coords.lat * 1000.0f).toNumber();
        var lonKey = (coords.lon * 1000.0f).toNumber();
        var endMethod = KodeshSettings.getValue("endMethod");
        var candleOffset = KodeshSettings.getValue("candleOffset");
        var schedule = KodeshSettings.getValue("parashaSchedule");
        return Lang.format("$1$-$2$-$3$|$4$|$5$|$6$|$7$|$8$|$9$", [info.year, info.month, info.day, getLocationId(), latKey, lonKey, endMethod == null ? "" : endMethod as String, candleOffset == null ? "" : candleOffset as String, schedule == null ? "" : schedule as String]);
    }

    function isCacheUsable(now as Time.Moment, key as String) as Boolean {
        if (_cachedShabbatTimes == null || !_cachedShabbatKey.equals(key)) { return false; }
        var times = _cachedShabbatTimes as ShabbatTimes;
        return momentToMinuteIndex(times.exitMoment) > momentToMinuteIndex(now);
    }

    function getKodeshBlockUncached(now as Time.Moment, coords as Coordinates) as ShabbatTimes? {
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var pLookup = new ParashaLookup();
        var jdToday = pLookup.gregorianToJd(date.year, date.month, date.day);
        var isIsrael = pLookup.isIsraelSchedule();
        var nowIndex = momentToMinuteIndex(now);
        var entryJd = -1;
        for (var i = -3; i <= 14; i++) {
            var jd = jdToday + i;
            var isKodeshDay = pLookup.isKodeshDaytime(jd, isIsrael);
            var isKodeshNext = pLookup.isKodeshDaytime(jd + 1, isIsrael);
            if (!isKodeshDay && isKodeshNext) { entryJd = jd; }
            if (isKodeshDay && !isKodeshNext && entryJd != -1) {
                var times = calculateShabbatTimesForJds(entryJd, jd, coords);
                if (times != null && momentToMinuteIndex(times.exitMoment) > nowIndex) { return times; }
            }
        }
        return null;
    }

    function getKodeshBlock(now as Time.Moment) as ShabbatTimes? {
        var coords = getCoordinates();
        var key = getCacheKey(now, coords);
        if (isCacheUsable(now, key)) { return _cachedShabbatTimes as ShabbatTimes; }
        _cachedShabbatTimes = getKodeshBlockUncached(now, coords);
        _cachedShabbatKey = key;
        return _cachedShabbatTimes;
    }

    function isShabbat(now as Time.Moment) as Boolean {
        var times = getKodeshBlock(now);
        if (times == null) { return false; }
        var nowIndex = momentToMinuteIndex(now);
        return nowIndex >= momentToMinuteIndex(times.entryMoment) && nowIndex < momentToMinuteIndex(times.exitMoment);
    }

    function getShabbatTimes(now as Time.Moment) as ShabbatTimes? { return getKodeshBlock(now); }
    function getNextShabbatTimes(now as Time.Moment) as ShabbatTimes? { return getKodeshBlock(now); }
    function getCurrentOrNextKodeshBlock(now as Time.Moment) as ShabbatTimes? { return getKodeshBlock(now); }
    function invalidateCache() as Void { _cachedShabbatTimes = null; _cachedShabbatKey = ""; }

    function getTzeitMoment(now as Time.Moment) as Time.Moment? {
        var pLookup = new ParashaLookup();
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var jd = pLookup.gregorianToJd(date.year, date.month, date.day);
        var coords = getCoordinates();
        var offsetHours = getIsraelUtcOffsetHours(date.year, date.month, date.day, 18.0f);
        var sunsetUTC = calcSunsetUTC(coords.lat, coords.lon, date.year, date.month, date.day, 90.833f);
        if (sunsetUTC == -1.0f) { return null; }
        var tzeitLocal = constrain(constrain(sunsetUTC + offsetHours, 24.0f) + (45.0f / 60.0f), 24.0f);
        return getMomentForLocalHour(jd, tzeitLocal);
    }
}
