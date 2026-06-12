import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Application.Storage;
import Toybox.Time;

module ShabbatProgressRenderer {
    const TEST_MODE = false; // Production: keep false. Enable only briefly in simulator testing.

    function isEnabled() as Boolean {
        var value = KodeshSettings.getValue("shabbatProgress");

        if (value == null) {
            return true;
        }

        return value == true;
    }

    function draw(dc as Graphics.Dc, now as Time.Moment, entryTime as Time.Moment?, exitTime as Time.Moment?, cx as Number, cy as Number, isAod as Boolean) as Void {
        try {
        if (!isEnabled()) {
            return;
        }

        var progress = 0.0f;
        var shouldShow = false;
        var isActive = false;

        if (TEST_MODE) {
            progress = 0.68f;
            shouldShow = true;
            isActive = true;
        } else if (entryTime != null && exitTime != null) {
            var state = ShabbatProgress.calculate(now, entryTime, exitTime);
            progress = state.progress;
            shouldShow = state.shouldShow;
            isActive = state.isActive;
        }

        if (!shouldShow) {
            return;
        }

        var w = dc.getWidth();
        var h = dc.getHeight();
        var minDim = w < h ? w : h;
        var clockTime = System.getClockTime();

        // AMOLED AOD: keep the ring away from the exact same pixels.
        // MIP devices pass isAod=false, so they keep the normal full ring.
        var margin = isAod ? 14 : 8;
        var radiusJitter = isAod ? ((clockTime.min % 3) - 1) : 0;
        var radius = (minDim / 2) - margin + radiusJitter;

        if (radius < 20) {
            return;
        }

        if (isAod) {
            drawAodTrack(dc, cx, cy, radius, clockTime.min);
        } else {
            dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(3);
            dc.drawCircle(cx, cy, radius);
        }

        if (isActive && progress > 0.0f) {
            var endDeg = -90.0f + (progress * 360.0f);

            if (isAod) {
                drawRingSegment(dc, cx, cy, radius, -90.0f, endDeg, 0x666666, 2, true, clockTime.min % 2);
            } else {
                drawRingSegment(dc, cx, cy, radius, -90.0f, endDeg, Graphics.COLOR_GREEN, 6, false, 0);
            }
        }
        } catch (ex) {
            return;
        }
    }

    function toRadiansSafe(deg as Float) as Float {
        return deg * 0.01745329252f;
    }

    function drawAodTrack(dc as Graphics.Dc, cx as Number, cy as Number, radius as Number, minute as Number) as Void {
        var phase = (minute % 12) * 30.0f;
        var rOuter = radius.toFloat();
        var rInner = rOuter - 3.0f;

        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        for (var i = 0; i < 12; i++) {
            var deg = -90.0f + phase + (i * 30.0f);
            var rad = toRadiansSafe(deg);

            var x1 = cx + (Math.cos(rad) * rInner).toNumber();
            var y1 = cy + (Math.sin(rad) * rInner).toNumber();
            var x2 = cx + (Math.cos(rad) * rOuter).toNumber();
            var y2 = cy + (Math.sin(rad) * rOuter).toNumber();

            dc.drawLine(x1, y1, x2, y2);
        }
    }

    function drawRingSegment(dc as Graphics.Dc, cx as Number, cy as Number, radius as Number, startDeg as Float, endDeg as Float, color as Number, penWidth as Number, dashed as Boolean, dashPhase as Number) as Void {
        if (endDeg <= startDeg) {
            return;
        }

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(penWidth);

        var step = dashed ? 5.0f : 2.5f;
        var current = startDeg;
        var dashIndex = dashPhase;
        var r = radius.toFloat();

        while (current < endDeg) {
            var next = current + step;

            if (next > endDeg) {
                next = endDeg;
            }

            if (!dashed || (dashIndex % 2 == 0)) {
                var rad1 = toRadiansSafe(current);
                var rad2 = toRadiansSafe(next);

                var x1 = cx + (Math.cos(rad1) * r).toNumber();
                var y1 = cy + (Math.sin(rad1) * r).toNumber();
                var x2 = cx + (Math.cos(rad2) * r).toNumber();
                var y2 = cy + (Math.sin(rad2) * r).toNumber();

                dc.drawLine(x1, y1, x2, y2);
            }

            dashIndex += 1;
            current = next;
        }
    }
}
