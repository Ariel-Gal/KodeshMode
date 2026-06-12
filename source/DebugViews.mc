import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Storage;

class SimpleBackDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

class ResetDoneView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var centerY = h / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, centerY - 15, Graphics.FONT_SMALL, "Settings reset", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w / 2, centerY + 15, Graphics.FONT_XTINY, "Back to return", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class ZmanimDebugView extends WatchUi.View {
    private var _engine;
    private var _parasha;
    private var _hebrewFont;

    function initialize() {
        View.initialize();
        _engine = new ZmanimEngine();
        _parasha = new ParashaLookup();
        _hebrewFont = AppFonts.getHebrewTextFont();
    }

    function formatMoment(m as Time.Moment) as String {
        var info = Gregorian.info(m, Time.FORMAT_SHORT);
        return Lang.format("$1$:$2$", [info.hour.format("%02d"), info.min.format("%02d")]);
    }

    function locationLabel() as String {
        var loc = KodeshSettings.getValue("location");

        if (loc == null) {
            return "Jerusalem";
        }

        var value = loc as String;

        if (value.equals("loc_jerusalem")) {
            return "Jerusalem";
        }

        if (value.equals("loc_telaviv")) {
            return "Tel Aviv";
        }

        if (value.equals("loc_haifa")) {
            return "Haifa";
        }

        if (value.equals("loc_eilat")) {
            return "Eilat";
        }

        if (value.equals("loc_gps")) {
            if (ShabbatMode.isEnabled()) {
                return "GPS Frozen";
            }

            return "Last GPS";
        }

        return value;
    }

    function boolLabel(value as Boolean) as String {
        return value ? "ON" : "OFF";
    }

    function shortCoord(value as Float) as String {
        var scaled = (value * 1000.0f).toNumber();
        return ((scaled.toFloat()) / 1000.0f).toString();
    }

    function drawDivider(dc as Graphics.Dc, y as Number, width as Number) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(28, y, width - 28, y);
    }

    function drawCenteredLine(dc as Graphics.Dc, text as String, y as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            y,
            Graphics.FONT_XTINY,
            text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function drawCenteredHebrewLine(dc as Graphics.Dc, text as String, y as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            y,
            _hebrewFont,
            text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function drawTimeBlock(dc as Graphics.Dc, centerX as Number, topY as Number, label as String, value as String, color as Number) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            topY,
            Graphics.FONT_XTINY,
            label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            topY + 23,
            Graphics.FONT_SMALL,
            value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function getSafeParashaName(now) as String {
        var name = _parasha.getCurrentParashaName(now);

        if (name == null) {
            return "";
        }

        return name;
    }

    function getSafeSpecialName(now) as String {
        var name = _parasha.getCurrentSpecialShabbatName(now);

        if (name == null) {
            return "";
        }

        return name;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var now = Time.now();
        var coords = _engine.getCoordinates();
        var times = _engine.getShabbatTimes(now);

        var parashaName = getSafeParashaName(now);
        var specialName = getSafeSpecialName(now);

        var y = (height.toFloat() * 0.12f).toNumber();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            y,
            Graphics.FONT_TINY,
            "Zmanim Debug",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        y += 20;
        drawDivider(dc, y, width);
        y += 22;

        if (times != null) {
            drawTimeBlock(
                dc,
                (width.toFloat() * 0.32f).toNumber(),
                y,
                "Entry",
                formatMoment(times.entryMoment),
                Graphics.COLOR_GREEN
            );

            drawTimeBlock(
                dc,
                (width.toFloat() * 0.68f).toNumber(),
                y,
                "Exit",
                formatMoment(times.exitMoment),
                Graphics.COLOR_RED
            );

            y += 52;

            var entryInfo = Gregorian.info(times.entryMoment, Time.FORMAT_SHORT);
            var exitInfo = Gregorian.info(times.exitMoment, Time.FORMAT_SHORT);
            var entryOffset = _engine.getIsraelUtcOffsetHours(entryInfo.year, entryInfo.month, entryInfo.day, entryInfo.hour.toFloat()).toNumber();
            var exitOffset = _engine.getIsraelUtcOffsetHours(exitInfo.year, exitInfo.month, exitInfo.day, exitInfo.hour.toFloat()).toNumber();

            drawCenteredLine(
                dc,
                Lang.format("Candle $1$m   Havdalah $2$m", [
                    _engine.getCandleOffsetMinutes(coords).toNumber(),
                    _engine.getHavdalahOffsetMinutes().toNumber()
                ]),
                y,
                Graphics.COLOR_LT_GRAY
            );

            y += 16;

            drawCenteredLine(
                dc,
                Lang.format("UTC +$1$ / +$2$", [entryOffset, exitOffset]),
                y,
                Graphics.COLOR_LT_GRAY
            );

            y += 18;
        } else {
            drawCenteredLine(dc, "No upcoming block", y, Graphics.COLOR_RED);
            y += 28;
        }

        drawDivider(dc, y, width);
        y += 18;

        drawCenteredLine(dc, Lang.format("Location: $1$", [locationLabel()]), y, Graphics.COLOR_WHITE);
        y += 16;

        drawCenteredLine(
            dc,
            Lang.format("Coords: $1$, $2$", [shortCoord(coords.lat), shortCoord(coords.lon)]),
            y,
            Graphics.COLOR_LT_GRAY
        );

        y += 18;

        if (!parashaName.equals("")) {
            drawCenteredHebrewLine(dc, parashaName, y, Graphics.COLOR_WHITE);
            y += 18;
        }

        if (!specialName.equals("")) {
            drawCenteredHebrewLine(dc, specialName, y, Graphics.COLOR_YELLOW);
            y += 18;
        }

        drawCenteredLine(
            dc,
            Lang.format("Mode $1$   Special $2$", [
                boolLabel(ShabbatMode.isEnabled()),
                boolLabel(ShabbatMode.isSpecialModeEnabled())
            ]),
            y,
            Graphics.COLOR_YELLOW
        );
    }
}