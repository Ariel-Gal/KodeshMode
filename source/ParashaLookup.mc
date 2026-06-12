import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Storage;
import Toybox.Math;
import Toybox.WatchUi;

class ParashaLookup {
    class HebrewDateSmart {
        var year as Number;
        var month as Number;
        var day as Number;
        var jd as Number;

        function initialize(aYear as Number, aMonth as Number, aDay as Number, aJd as Number) {
            year = aYear;
            month = aMonth;
            day = aDay;
            jd = aJd;
        }
    }

    class ParashaResult {
        var hasParasha as Boolean;
        var first as Number;
        var second as Number;
        var isDouble as Boolean;

        function initialize(aHasParasha as Boolean, aFirst as Number, aSecond as Number, aIsDouble as Boolean) {
            hasParasha = aHasParasha;
            first = aFirst;
            second = aSecond;
            isDouble = aIsDouble;
        }
    }

    function getCurrentParashaName(now) as String {
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var jd = gregorianToJd(date.year, date.month, date.day);
        var shabbosJd = getShabbosJd(jd);
        var hebrewShabbos = hebrewFromJd(shabbosJd);
        var israel = isIsraelSchedule();
        var result = getParashaForShabbos(hebrewShabbos.year, shabbosJd, israel);
        var hebrew = isHebrewLanguage();

        if (!result.hasParasha) {
            return hebrew ? loadStringResource(Rez.Strings.TextYomTov) : "Yom Tov";
        }

        var name = getParashaName(result.first, hebrew);

        if (result.isDouble) {
            name += hebrew ? loadStringResource(Rez.Strings.TextHebrewMaqaf) : "-";
            name += getParashaName(result.second, hebrew);
        }

        return name;
    }

    function isHebrewLanguage() as Boolean {
        var lang = KodeshSettings.getValue("language");
        return lang != null && lang.equals("lang_he");
    }

    function isIsraelSchedule() as Boolean {
        var schedule = KodeshSettings.getValue("parashaSchedule");
        if (schedule != null && schedule.equals("diaspora")) {
            return false;
        }
        return true;
    }

    function gregorianToJd(year as Number, month as Number, day as Number) as Number {
        var a = Math.floor((14.0f - month.toFloat()) / 12.0f).toNumber();
        var y = year + 4800 - a;
        var m = month + (12 * a) - 3;

        return day
            + Math.floor(((153 * m) + 2) / 5.0f).toNumber()
            + (365 * y)
            + Math.floor(y / 4.0f).toNumber()
            - Math.floor(y / 100.0f).toNumber()
            + Math.floor(y / 400.0f).toNumber()
            - 32045;
    }

    function weekdayFromJd(jd as Number) as Number {
        return ((jd + 1) % 7) + 1;
    }

    function jdToGregorian(jd as Number) as Array<Number> {
        var J = jd + 32044;
        var g = J / 146097;
        var dg = J % 146097;
        var c = (((dg / 36524) + 1) * 3) / 4;
        var dc = dg - (c * 36524);
        var b = dc / 1461;
        var db = dc % 1461;
        var a = (((db / 365) + 1) * 3) / 4;
        var da = db - (a * 365);
        var y = (g * 400) + (c * 100) + (b * 4) + a;
        var m = ((da * 5) + 308) / 153 - 2;
        var d = da - (((m + 4) * 153) / 5) + 122;
        var Y = y - 4800 + ((m + 2) / 12);
        var M = ((m + 2) % 12) + 1;
        var D = d + 1;
        return [Y, M, D] as Array<Number>;
    }

    function isKodeshDaytime(jd as Number, isIsrael as Boolean) as Boolean {
        if (weekdayFromJd(jd) == 7) {
            return true;
        }

        var hd = hebrewFromJd(jd);

        if (hd.month == 7) { // Tishrei
            if (hd.day == 1 || hd.day == 2) { return true; } // Rosh Hashana
            if (hd.day == 10) { return true; } // Yom Kippur
            if (hd.day == 15) { return true; } // Sukkot Day 1
            if (!isIsrael && hd.day == 16) { return true; } // Sukkot Day 2
            if (hd.day == 22) { return true; } // Shmini Atzeret
            if (!isIsrael && hd.day == 23) { return true; } // Simchat Torah
        } else if (hd.month == 1) { // Nissan
            if (hd.day == 15) { return true; } // Pesach 1
            if (!isIsrael && hd.day == 16) { return true; } // Pesach 2
            if (hd.day == 21) { return true; } // Pesach 7
            if (!isIsrael && hd.day == 22) { return true; } // Pesach 8
        } else if (hd.month == 3) { // Sivan
            if (hd.day == 6) { return true; } // Shavuot 1
            if (!isIsrael && hd.day == 7) { return true; } // Shavuot 2
        }

        return false;
    }

    function getShabbosJd(jd as Number) as Number {
        return jd + (7 - weekdayFromJd(jd));
    }

    function isHebrewLeapYear(year as Number) as Boolean {
        return (((7 * year) + 1) % 19) < 7;
    }

    function elapsedMonths(year as Number) as Number {
        return Math.floor(((235 * year) - 234) / 19.0f).toNumber();
    }

    function elapsedDays(year as Number) as Number {
        var monthsElapsed = elapsedMonths(year);
        var partsElapsed = 204 + (793 * (monthsElapsed % 1080));
        var hoursElapsed = 5
            + (12 * monthsElapsed)
            + (793 * Math.floor(monthsElapsed / 1080.0f).toNumber())
            + Math.floor(partsElapsed / 1080.0f).toNumber();

        var conjunctionDay = 1
            + (29 * monthsElapsed)
            + Math.floor(hoursElapsed / 24.0f).toNumber();

        var conjunctionParts = (1080 * (hoursElapsed % 24)) + (partsElapsed % 1080);
        var altDay = conjunctionDay;

        if (
            conjunctionParts >= 19440
            || ((conjunctionDay % 7) == 2 && conjunctionParts >= 9924 && !isHebrewLeapYear(year))
            || ((conjunctionDay % 7) == 1 && conjunctionParts >= 16789 && isHebrewLeapYear(year - 1))
        ) {
            altDay += 1;
        }

        if ((altDay % 7) == 0 || (altDay % 7) == 3 || (altDay % 7) == 5) {
            altDay += 1;
        }

        return altDay;
    }

    function daysInHebrewYear(year as Number) as Number {
        return elapsedDays(year + 1) - elapsedDays(year);
    }

    function hasLongCheshvan(year as Number) as Boolean {
        return (daysInHebrewYear(year) % 10) == 5;
    }

    function hasShortKislev(year as Number) as Boolean {
        return (daysInHebrewYear(year) % 10) == 3;
    }

    function hebrewMonthLength(year as Number, month as Number) as Number {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 11) {
            return 30;
        }

        if (month == 2 || month == 4 || month == 6 || month == 10 || month == 13) {
            return 29;
        }

        if (month == 12) {
            return isHebrewLeapYear(year) ? 30 : 29;
        }

        if (month == 8) {
            return hasLongCheshvan(year) ? 30 : 29;
        }

        if (month == 9) {
            return hasShortKislev(year) ? 29 : 30;
        }

        return 29;
    }

    function hebrewToJd(year as Number, month as Number, day as Number) as Number {
        var days = elapsedDays(year) + day - 1;
        var m = 7;

        while (m <= 13) {
            if (!(m == 13 && !isHebrewLeapYear(year))) {
                if (m == month) {
                    return 347997 + days;
                }
                days += hebrewMonthLength(year, m);
            }
            m += 1;
        }

        m = 1;

        while (m <= 6) {
            if (m == month) {
                return 347997 + days;
            }
            days += hebrewMonthLength(year, m);
            m += 1;
        }

        return 347997 + days;
    }

    function hebrewFromJd(jd as Number) as HebrewDateSmart {
        var rel = jd - 347997;
        var year = Math.floor(rel / 365.0f).toNumber() + 2;
        var firstDay = elapsedDays(year);

        while (firstDay > rel) {
            year -= 1;
            firstDay = elapsedDays(year);
        }

        var daysRemaining = rel - firstDay;
        var month = 7;

        while (month <= 13) {
            if (!(month == 13 && !isHebrewLeapYear(year))) {
                var len = hebrewMonthLength(year, month);
                if (daysRemaining >= len) {
                    daysRemaining -= len;
                } else {
                    return new HebrewDateSmart(year, month, daysRemaining + 1, jd);
                }
            }
            month += 1;
        }

        month = 1;

        while (month <= 6) {
            var len2 = hebrewMonthLength(year, month);
            if (daysRemaining >= len2) {
                daysRemaining -= len2;
            } else {
                return new HebrewDateSmart(year, month, daysRemaining + 1, jd);
            }
            month += 1;
        }

        return new HebrewDateSmart(year, 6, 29, jd);
    }

    function isParshaless(date as HebrewDateSmart, israel as Boolean) as Boolean {
        if (israel) {
            if (date.month == 7 && date.day == 23) {
                return false;
            }

            if (date.month == 1 && date.day == 22) {
                return false;
            }

            if (date.month == 3 && date.day == 7) {
                return false;
            }
        }

        if (date.month == 7) {
            if (date.day == 1 || date.day == 2 || date.day == 10) {
                return true;
            }

            if (date.day >= 15 && date.day <= 23) {
                return true;
            }
        }

        if (date.month == 1 && date.day >= 15 && date.day <= 22) {
            return true;
        }

        if (date.month == 3 && (date.day == 6 || date.day == 7)) {
            return true;
        }

        return false;
    }

    function parshaFromQueue(index as Number) as Number {
        if (index == 0) {
            return 51;
        }

        if (index == 1) {
            return 52;
        }

        var p = index - 2;

        if (p >= 0 && p <= 51) {
            return p;
        }

        return -1;
    }

    function shouldDoubleParasha(parsha as Number, year as Number, shabbosJd as Number, israel as Boolean, pesachDay as Number) as Boolean {
        var leap = isHebrewLeapYear(year);

        if (parsha == 21 && ((hebrewToJd(year, 1, 14) - shabbosJd) / 7.0f) < 3.0f) {
            return true;
        }

        if ((parsha == 26 || parsha == 28) && !leap) {
            return true;
        }

        if (parsha == 31 && !leap && (!israel || pesachDay != 7)) {
            return true;
        }

        if (parsha == 38 && !israel && pesachDay == 5) {
            return true;
        }

        if (parsha == 41 && ((hebrewToJd(year, 5, 9) - shabbosJd) / 7.0f) < 2.0f) {
            return true;
        }

        if (parsha == 50 && weekdayFromJd(hebrewToJd(year + 1, 7, 1)) > 4) {
            return true;
        }

        return false;
    }

    function getParashaForShabbos(year as Number, targetShabbosJd as Number, israel as Boolean) as ParashaResult {
        var pesachDay = weekdayFromJd(hebrewToJd(year, 1, 15));
        var roshHashanaJd = hebrewToJd(year, 7, 1);
        var roshHashanaWeekday = weekdayFromJd(roshHashanaJd);
        var shabbosJd = roshHashanaJd + (7 - roshHashanaWeekday);
        var queueIndex = 0;

        if (roshHashanaWeekday > 4) {
            queueIndex = 1;
        }

        while (true) {
            var shabbosHebrew = hebrewFromJd(shabbosJd);

            if (shabbosHebrew.year != year) {
                break;
            }

            if (isParshaless(shabbosHebrew, israel)) {
                if (shabbosJd == targetShabbosJd) {
                    return new ParashaResult(false, -1, -1, false);
                }
            } else {
                var first = parshaFromQueue(queueIndex);
                var second = -1;
                var isDouble = false;

                queueIndex += 1;

                if (first >= 0 && shouldDoubleParasha(first, year, shabbosJd, israel, pesachDay)) {
                    second = parshaFromQueue(queueIndex);
                    if (second >= 0) {
                        isDouble = true;
                        queueIndex += 1;
                    }
                }

                if (shabbosJd == targetShabbosJd) {
                    return new ParashaResult(true, first, second, isDouble);
                }
            }

            shabbosJd += 7;
        }

        return new ParashaResult(false, -1, -1, false);
    }

    function loadStringResource(id) as String {
        return WatchUi.loadResource(id) as String;
    }

    function getParashaName(index as Number, hebrew as Boolean) as String {
        if (hebrew) {
            if (index == 0) { return loadStringResource(Rez.Strings.ParashaHe0); }
            if (index == 1) { return loadStringResource(Rez.Strings.ParashaHe1); }
            if (index == 2) { return loadStringResource(Rez.Strings.ParashaHe2); }
            if (index == 3) { return loadStringResource(Rez.Strings.ParashaHe3); }
            if (index == 4) { return loadStringResource(Rez.Strings.ParashaHe4); }
            if (index == 5) { return loadStringResource(Rez.Strings.ParashaHe5); }
            if (index == 6) { return loadStringResource(Rez.Strings.ParashaHe6); }
            if (index == 7) { return loadStringResource(Rez.Strings.ParashaHe7); }
            if (index == 8) { return loadStringResource(Rez.Strings.ParashaHe8); }
            if (index == 9) { return loadStringResource(Rez.Strings.ParashaHe9); }
            if (index == 10) { return loadStringResource(Rez.Strings.ParashaHe10); }
            if (index == 11) { return loadStringResource(Rez.Strings.ParashaHe11); }
            if (index == 12) { return loadStringResource(Rez.Strings.ParashaHe12); }
            if (index == 13) { return loadStringResource(Rez.Strings.ParashaHe13); }
            if (index == 14) { return loadStringResource(Rez.Strings.ParashaHe14); }
            if (index == 15) { return loadStringResource(Rez.Strings.ParashaHe15); }
            if (index == 16) { return loadStringResource(Rez.Strings.ParashaHe16); }
            if (index == 17) { return loadStringResource(Rez.Strings.ParashaHe17); }
            if (index == 18) { return loadStringResource(Rez.Strings.ParashaHe18); }
            if (index == 19) { return loadStringResource(Rez.Strings.ParashaHe19); }
            if (index == 20) { return loadStringResource(Rez.Strings.ParashaHe20); }
            if (index == 21) { return loadStringResource(Rez.Strings.ParashaHe21); }
            if (index == 22) { return loadStringResource(Rez.Strings.ParashaHe22); }
            if (index == 23) { return loadStringResource(Rez.Strings.ParashaHe23); }
            if (index == 24) { return loadStringResource(Rez.Strings.ParashaHe24); }
            if (index == 25) { return loadStringResource(Rez.Strings.ParashaHe25); }
            if (index == 26) { return loadStringResource(Rez.Strings.ParashaHe26); }
            if (index == 27) { return loadStringResource(Rez.Strings.ParashaHe27); }
            if (index == 28) { return loadStringResource(Rez.Strings.ParashaHe28); }
            if (index == 29) { return loadStringResource(Rez.Strings.ParashaHe29); }
            if (index == 30) { return loadStringResource(Rez.Strings.ParashaHe30); }
            if (index == 31) { return loadStringResource(Rez.Strings.ParashaHe31); }
            if (index == 32) { return loadStringResource(Rez.Strings.ParashaHe32); }
            if (index == 33) { return loadStringResource(Rez.Strings.ParashaHe33); }
            if (index == 34) { return loadStringResource(Rez.Strings.ParashaHe34); }
            if (index == 35) { return loadStringResource(Rez.Strings.ParashaHe35); }
            if (index == 36) { return loadStringResource(Rez.Strings.ParashaHe36); }
            if (index == 37) { return loadStringResource(Rez.Strings.ParashaHe37); }
            if (index == 38) { return loadStringResource(Rez.Strings.ParashaHe38); }
            if (index == 39) { return loadStringResource(Rez.Strings.ParashaHe39); }
            if (index == 40) { return loadStringResource(Rez.Strings.ParashaHe40); }
            if (index == 41) { return loadStringResource(Rez.Strings.ParashaHe41); }
            if (index == 42) { return loadStringResource(Rez.Strings.ParashaHe42); }
            if (index == 43) { return loadStringResource(Rez.Strings.ParashaHe43); }
            if (index == 44) { return loadStringResource(Rez.Strings.ParashaHe44); }
            if (index == 45) { return loadStringResource(Rez.Strings.ParashaHe45); }
            if (index == 46) { return loadStringResource(Rez.Strings.ParashaHe46); }
            if (index == 47) { return loadStringResource(Rez.Strings.ParashaHe47); }
            if (index == 48) { return loadStringResource(Rez.Strings.ParashaHe48); }
            if (index == 49) { return loadStringResource(Rez.Strings.ParashaHe49); }
            if (index == 50) { return loadStringResource(Rez.Strings.ParashaHe50); }
            if (index == 51) { return loadStringResource(Rez.Strings.ParashaHe51); }
            if (index == 52) { return loadStringResource(Rez.Strings.ParashaHe52); }
            if (index == 53) { return loadStringResource(Rez.Strings.ParashaHe53); }
            return "";
        }

        if (index == 0) { return loadStringResource(Rez.Strings.ParashaEn0); }
        if (index == 1) { return loadStringResource(Rez.Strings.ParashaEn1); }
        if (index == 2) { return loadStringResource(Rez.Strings.ParashaEn2); }
        if (index == 3) { return loadStringResource(Rez.Strings.ParashaEn3); }
        if (index == 4) { return loadStringResource(Rez.Strings.ParashaEn4); }
        if (index == 5) { return loadStringResource(Rez.Strings.ParashaEn5); }
        if (index == 6) { return loadStringResource(Rez.Strings.ParashaEn6); }
        if (index == 7) { return loadStringResource(Rez.Strings.ParashaEn7); }
        if (index == 8) { return loadStringResource(Rez.Strings.ParashaEn8); }
        if (index == 9) { return loadStringResource(Rez.Strings.ParashaEn9); }
        if (index == 10) { return loadStringResource(Rez.Strings.ParashaEn10); }
        if (index == 11) { return loadStringResource(Rez.Strings.ParashaEn11); }
        if (index == 12) { return loadStringResource(Rez.Strings.ParashaEn12); }
        if (index == 13) { return loadStringResource(Rez.Strings.ParashaEn13); }
        if (index == 14) { return loadStringResource(Rez.Strings.ParashaEn14); }
        if (index == 15) { return loadStringResource(Rez.Strings.ParashaEn15); }
        if (index == 16) { return loadStringResource(Rez.Strings.ParashaEn16); }
        if (index == 17) { return loadStringResource(Rez.Strings.ParashaEn17); }
        if (index == 18) { return loadStringResource(Rez.Strings.ParashaEn18); }
        if (index == 19) { return loadStringResource(Rez.Strings.ParashaEn19); }
        if (index == 20) { return loadStringResource(Rez.Strings.ParashaEn20); }
        if (index == 21) { return loadStringResource(Rez.Strings.ParashaEn21); }
        if (index == 22) { return loadStringResource(Rez.Strings.ParashaEn22); }
        if (index == 23) { return loadStringResource(Rez.Strings.ParashaEn23); }
        if (index == 24) { return loadStringResource(Rez.Strings.ParashaEn24); }
        if (index == 25) { return loadStringResource(Rez.Strings.ParashaEn25); }
        if (index == 26) { return loadStringResource(Rez.Strings.ParashaEn26); }
        if (index == 27) { return loadStringResource(Rez.Strings.ParashaEn27); }
        if (index == 28) { return loadStringResource(Rez.Strings.ParashaEn28); }
        if (index == 29) { return loadStringResource(Rez.Strings.ParashaEn29); }
        if (index == 30) { return loadStringResource(Rez.Strings.ParashaEn30); }
        if (index == 31) { return loadStringResource(Rez.Strings.ParashaEn31); }
        if (index == 32) { return loadStringResource(Rez.Strings.ParashaEn32); }
        if (index == 33) { return loadStringResource(Rez.Strings.ParashaEn33); }
        if (index == 34) { return loadStringResource(Rez.Strings.ParashaEn34); }
        if (index == 35) { return loadStringResource(Rez.Strings.ParashaEn35); }
        if (index == 36) { return loadStringResource(Rez.Strings.ParashaEn36); }
        if (index == 37) { return loadStringResource(Rez.Strings.ParashaEn37); }
        if (index == 38) { return loadStringResource(Rez.Strings.ParashaEn38); }
        if (index == 39) { return loadStringResource(Rez.Strings.ParashaEn39); }
        if (index == 40) { return loadStringResource(Rez.Strings.ParashaEn40); }
        if (index == 41) { return loadStringResource(Rez.Strings.ParashaEn41); }
        if (index == 42) { return loadStringResource(Rez.Strings.ParashaEn42); }
        if (index == 43) { return loadStringResource(Rez.Strings.ParashaEn43); }
        if (index == 44) { return loadStringResource(Rez.Strings.ParashaEn44); }
        if (index == 45) { return loadStringResource(Rez.Strings.ParashaEn45); }
        if (index == 46) { return loadStringResource(Rez.Strings.ParashaEn46); }
        if (index == 47) { return loadStringResource(Rez.Strings.ParashaEn47); }
        if (index == 48) { return loadStringResource(Rez.Strings.ParashaEn48); }
        if (index == 49) { return loadStringResource(Rez.Strings.ParashaEn49); }
        if (index == 50) { return loadStringResource(Rez.Strings.ParashaEn50); }
        if (index == 51) { return loadStringResource(Rez.Strings.ParashaEn51); }
        if (index == 52) { return loadStringResource(Rez.Strings.ParashaEn52); }
        if (index == 53) { return loadStringResource(Rez.Strings.ParashaEn53); }
        return "";
    }

    function getHebrewMonthName(month as Number, hebrew as Boolean) as String {
        if (hebrew) {
            if (month == 1) { return loadStringResource(Rez.Strings.HebMonthHe1); }
            if (month == 2) { return loadStringResource(Rez.Strings.HebMonthHe2); }
            if (month == 3) { return loadStringResource(Rez.Strings.HebMonthHe3); }
            if (month == 4) { return loadStringResource(Rez.Strings.HebMonthHe4); }
            if (month == 5) { return loadStringResource(Rez.Strings.HebMonthHe5); }
            if (month == 6) { return loadStringResource(Rez.Strings.HebMonthHe6); }
            if (month == 7) { return loadStringResource(Rez.Strings.HebMonthHe7); }
            if (month == 8) { return loadStringResource(Rez.Strings.HebMonthHe8); }
            if (month == 9) { return loadStringResource(Rez.Strings.HebMonthHe9); }
            if (month == 10) { return loadStringResource(Rez.Strings.HebMonthHe10); }
            if (month == 11) { return loadStringResource(Rez.Strings.HebMonthHe11); }
            if (month == 12) { return loadStringResource(Rez.Strings.HebMonthHe12); }
            if (month == 13) { return loadStringResource(Rez.Strings.HebMonthHe13); }
            return "";
        }

        if (month == 1) { return loadStringResource(Rez.Strings.HebMonthEn1); }
        if (month == 2) { return loadStringResource(Rez.Strings.HebMonthEn2); }
        if (month == 3) { return loadStringResource(Rez.Strings.HebMonthEn3); }
        if (month == 4) { return loadStringResource(Rez.Strings.HebMonthEn4); }
        if (month == 5) { return loadStringResource(Rez.Strings.HebMonthEn5); }
        if (month == 6) { return loadStringResource(Rez.Strings.HebMonthEn6); }
        if (month == 7) { return loadStringResource(Rez.Strings.HebMonthEn7); }
        if (month == 8) { return loadStringResource(Rez.Strings.HebMonthEn8); }
        if (month == 9) { return loadStringResource(Rez.Strings.HebMonthEn9); }
        if (month == 10) { return loadStringResource(Rez.Strings.HebMonthEn10); }
        if (month == 11) { return loadStringResource(Rez.Strings.HebMonthEn11); }
        if (month == 12) { return loadStringResource(Rez.Strings.HebMonthEn12); }
        if (month == 13) { return loadStringResource(Rez.Strings.HebMonthEn13); }
        return "";
    }

    function getHebrewLetter(value as Number) as String {
        if (value == 1) { return loadStringResource(Rez.Strings.HebLetter1); }
        if (value == 2) { return loadStringResource(Rez.Strings.HebLetter2); }
        if (value == 3) { return loadStringResource(Rez.Strings.HebLetter3); }
        if (value == 4) { return loadStringResource(Rez.Strings.HebLetter4); }
        if (value == 5) { return loadStringResource(Rez.Strings.HebLetter5); }
        if (value == 6) { return loadStringResource(Rez.Strings.HebLetter6); }
        if (value == 7) { return loadStringResource(Rez.Strings.HebLetter7); }
        if (value == 8) { return loadStringResource(Rez.Strings.HebLetter8); }
        if (value == 9) { return loadStringResource(Rez.Strings.HebLetter9); }
        if (value == 10) { return loadStringResource(Rez.Strings.HebLetter10); }
        if (value == 20) { return loadStringResource(Rez.Strings.HebLetter20); }
        if (value == 30) { return loadStringResource(Rez.Strings.HebLetter30); }
        if (value == 40) { return loadStringResource(Rez.Strings.HebLetter40); }
        return "";
    }

    function getHebrewNumberSmall(num as Number) as String {
        if (num <= 0) {
            return "";
        }

        if (!isHebrewLanguage()) {
            return num.toString();
        }
        if (num == 1) { return loadStringResource(Rez.Strings.HebNum1); }
        if (num == 2) { return loadStringResource(Rez.Strings.HebNum2); }
        if (num == 3) { return loadStringResource(Rez.Strings.HebNum3); }
        if (num == 4) { return loadStringResource(Rez.Strings.HebNum4); }
        if (num == 5) { return loadStringResource(Rez.Strings.HebNum5); }
        if (num == 6) { return loadStringResource(Rez.Strings.HebNum6); }
        if (num == 7) { return loadStringResource(Rez.Strings.HebNum7); }
        if (num == 8) { return loadStringResource(Rez.Strings.HebNum8); }
        if (num == 9) { return loadStringResource(Rez.Strings.HebNum9); }
        if (num == 10) { return loadStringResource(Rez.Strings.HebNum10); }
        if (num == 11) { return loadStringResource(Rez.Strings.HebNum11); }
        if (num == 12) { return loadStringResource(Rez.Strings.HebNum12); }
        if (num == 13) { return loadStringResource(Rez.Strings.HebNum13); }
        if (num == 14) { return loadStringResource(Rez.Strings.HebNum14); }
        if (num == 15) { return loadStringResource(Rez.Strings.HebNum15); }
        if (num == 16) { return loadStringResource(Rez.Strings.HebNum16); }
        if (num == 17) { return loadStringResource(Rez.Strings.HebNum17); }
        if (num == 18) { return loadStringResource(Rez.Strings.HebNum18); }
        if (num == 19) { return loadStringResource(Rez.Strings.HebNum19); }
        if (num == 20) { return loadStringResource(Rez.Strings.HebNum20); }
        if (num == 21) { return loadStringResource(Rez.Strings.HebNum21); }
        if (num == 22) { return loadStringResource(Rez.Strings.HebNum22); }
        if (num == 23) { return loadStringResource(Rez.Strings.HebNum23); }
        if (num == 24) { return loadStringResource(Rez.Strings.HebNum24); }
        if (num == 25) { return loadStringResource(Rez.Strings.HebNum25); }
        if (num == 26) { return loadStringResource(Rez.Strings.HebNum26); }
        if (num == 27) { return loadStringResource(Rez.Strings.HebNum27); }
        if (num == 28) { return loadStringResource(Rez.Strings.HebNum28); }
        if (num == 29) { return loadStringResource(Rez.Strings.HebNum29); }
        if (num == 30) { return loadStringResource(Rez.Strings.HebNum30); }
        if (num == 31) { return loadStringResource(Rez.Strings.HebNum31); }
        if (num == 32) { return loadStringResource(Rez.Strings.HebNum32); }
        if (num == 33) { return loadStringResource(Rez.Strings.HebNum33); }
        if (num == 34) { return loadStringResource(Rez.Strings.HebNum34); }
        if (num == 35) { return loadStringResource(Rez.Strings.HebNum35); }
        if (num == 36) { return loadStringResource(Rez.Strings.HebNum36); }
        if (num == 37) { return loadStringResource(Rez.Strings.HebNum37); }
        if (num == 38) { return loadStringResource(Rez.Strings.HebNum38); }
        if (num == 39) { return loadStringResource(Rez.Strings.HebNum39); }
        if (num == 40) { return loadStringResource(Rez.Strings.HebNum40); }
        if (num == 41) { return loadStringResource(Rez.Strings.HebNum41); }
        if (num == 42) { return loadStringResource(Rez.Strings.HebNum42); }
        if (num == 43) { return loadStringResource(Rez.Strings.HebNum43); }
        if (num == 44) { return loadStringResource(Rez.Strings.HebNum44); }
        if (num == 45) { return loadStringResource(Rez.Strings.HebNum45); }
        if (num == 46) { return loadStringResource(Rez.Strings.HebNum46); }
        if (num == 47) { return loadStringResource(Rez.Strings.HebNum47); }
        if (num == 48) { return loadStringResource(Rez.Strings.HebNum48); }
        if (num == 49) { return loadStringResource(Rez.Strings.HebNum49); }

        return num.toString();
    }

    function getHebrewDateDisplayString(now, afterTzeit as Boolean) as String {
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var jd = gregorianToJd(date.year, date.month, date.day);

        if (afterTzeit) {
            jd += 1;
        }

        var hd = hebrewFromJd(jd);
        var hebrew = isHebrewLanguage();

        if (hebrew) {
            var format = loadStringResource(Rez.Strings.TextHebrewDateFormat);
            return Lang.format(format, [getHebrewNumberSmall(hd.day), getHebrewMonthName(hd.month, true)]);
        }

        return Lang.format("$1$ $2$", [hd.day, getHebrewMonthName(hd.month, false)]);
    }

    function getOmerCountForHebrewDate(hd as HebrewDateSmart) as Number {
        if (hd.month == 1 && hd.day >= 16) {
            return hd.day - 15;
        }

        if (hd.month == 2) {
            return 15 + hd.day;
        }

        if (hd.month == 3 && hd.day <= 5) {
            return 44 + hd.day;
        }

        return 0;
    }

    function getOmerString(now, afterTzeit as Boolean) as String {
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var jd = gregorianToJd(date.year, date.month, date.day);

        if (afterTzeit) {
            jd += 1;
        }

        var hd = hebrewFromJd(jd);
        var count = getOmerCountForHebrewDate(hd);

        if (count <= 0 || count > 49) {
            return "";
        }

        if (isHebrewLanguage()) {
            var format = loadStringResource(Rez.Strings.TextOmerTodayFormat);
            return Lang.format(format, [getHebrewNumberSmall(count)]);
        }

        return Lang.format("Omer $1$", [count]);
    }

    function getCurrentHebrewDateString(now) as String {
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var jd = gregorianToJd(date.year, date.month, date.day);
        var hd = hebrewFromJd(jd);
        var hebrew = isHebrewLanguage();
        return Lang.format("$1$ $2$ $3$", [hd.day, getHebrewMonthName(hd.month, hebrew), hd.year]);
    }

    function lastShabbatOnOrBefore(jd as Number) as Number {
        var weekday = weekdayFromJd(jd);

        if (weekday == 7) {
            return jd;
        }

        return jd - weekday;
    }

    function getSpecialShabbatNameForJd(shabbosJd as Number, hebrew as Boolean) as String {
        var hd = hebrewFromJd(shabbosJd);
        var year = hd.year;
        var adar = isHebrewLeapYear(year) ? 13 : 12;

        var roshAdar = hebrewToJd(year, adar, 1);
        var shkalimJd = lastShabbatOnOrBefore(roshAdar);
        if (shabbosJd == shkalimJd) {
            return hebrew ? loadStringResource(Rez.Strings.SpecialHeShekalim) : loadStringResource(Rez.Strings.SpecialEnShekalim);
        }

        var purimJd = hebrewToJd(year, adar, 14);
        if (shabbosJd < purimJd && shabbosJd >= purimJd - 7) {
            return hebrew ? loadStringResource(Rez.Strings.SpecialHeZachor) : loadStringResource(Rez.Strings.SpecialEnZachor);
        }

        var roshNissan = hebrewToJd(year, 1, 1);
        var hachodeshJd = lastShabbatOnOrBefore(roshNissan);
        if (shabbosJd == hachodeshJd) {
            return hebrew ? loadStringResource(Rez.Strings.SpecialHeHaChodesh) : loadStringResource(Rez.Strings.SpecialEnHaChodesh);
        }

        if (shabbosJd == hachodeshJd - 7) {
            return hebrew ? loadStringResource(Rez.Strings.SpecialHeParah) : loadStringResource(Rez.Strings.SpecialEnParah);
        }

        var pesachJd = hebrewToJd(year, 1, 15);
        if (shabbosJd < pesachJd && shabbosJd >= pesachJd - 7) {
            return hebrew ? loadStringResource(Rez.Strings.SpecialHeHaGadol) : loadStringResource(Rez.Strings.SpecialEnHaGadol);
        }

        var roshHashana = hebrewToJd(year, 7, 1);
        var yomKippur = hebrewToJd(year, 7, 10);
        if (shabbosJd > roshHashana && shabbosJd < yomKippur) {
            return hebrew ? loadStringResource(Rez.Strings.SpecialHeShuva) : loadStringResource(Rez.Strings.SpecialEnShuva);
        }

        var tishaBav = hebrewToJd(year, 5, 9);
        if (shabbosJd <= tishaBav && shabbosJd >= tishaBav - 7) {
            return hebrew ? loadStringResource(Rez.Strings.SpecialHeChazon) : loadStringResource(Rez.Strings.SpecialEnChazon);
        }

        if (shabbosJd > tishaBav && shabbosJd <= tishaBav + 7) {
            return hebrew ? loadStringResource(Rez.Strings.SpecialHeNachamu) : loadStringResource(Rez.Strings.SpecialEnNachamu);
        }

        return "";
    }

    function getCurrentSpecialShabbatName(now) as String {
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var jd = gregorianToJd(date.year, date.month, date.day);
        var shabbosJd = getShabbosJd(jd);
        return getSpecialShabbatNameForJd(shabbosJd, isHebrewLanguage());
    }

    function getCurrentParashaDebugString(now) as String {
        var parasha = getCurrentParashaName(now);
        var special = getCurrentSpecialShabbatName(now);

        if (!special.equals("")) {
            return Lang.format("$1$ / $2$", [parasha, special]);
        }

        return parasha;
    }

}