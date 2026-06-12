import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;

module ShabbatProgress {
    class State {
        var progress as Float;
        var isActive as Boolean;
        var isBefore as Boolean;
        var shouldShow as Boolean;

        function initialize(
            aProgress as Float,
            aIsActive as Boolean,
            aIsBefore as Boolean,
            aShouldShow as Boolean
        ) {
            progress = aProgress;
            isActive = aIsActive;
            isBefore = aIsBefore;
            shouldShow = aShouldShow;
        }
    }

    function emptyState() as State {
        return new State(0.0f, false, false, false);
    }

    function beforeState() as State {
        return new State(0.0f, false, true, true);
    }

    function doneState() as State {
        return new State(1.0f, false, false, false);
    }

    function momentToMinuteIndex(m) as Number {
        var info = Gregorian.info(m, Time.FORMAT_SHORT);

        // IMPORTANT:
        // Do not call Moment.value(), Moment.compare(), or toNumber() here.
        // On the Instinct 3 AMOLED simulator these can crash at runtime.
        var year = info.year;
        var month = info.month;
        var day = info.day;
        var hour = info.hour;
        var minute = info.min;

        return (((year * 12 + month) * 31 + day) * 24 + hour) * 60 + minute;
    }

    function calculate(now, entryTime, exitTime) as State {
        try {
            if (now == null || entryTime == null || exitTime == null) {
                return emptyState();
            }

            var nowMin = momentToMinuteIndex(now);
            var entryMin = momentToMinuteIndex(entryTime);
            var exitMin = momentToMinuteIndex(exitTime);

            if (exitMin <= entryMin) {
                return emptyState();
            }

            if (nowMin < entryMin) {
                return beforeState();
            }

            if (nowMin >= exitMin) {
                return doneState();
            }

            var totalMin = exitMin - entryMin;
            var elapsedMin = nowMin - entryMin;

            if (totalMin <= 0) {
                return emptyState();
            }

            if (elapsedMin < 0) {
                elapsedMin = 0;
            }

            if (elapsedMin > totalMin) {
                elapsedMin = totalMin;
            }

            var progress = (elapsedMin * 1.0f) / (totalMin * 1.0f);

            if (progress < 0.0f) {
                progress = 0.0f;
            }

            if (progress > 1.0f) {
                progress = 1.0f;
            }

            return new State(progress, true, false, true);
        } catch (ex) {
            return emptyState();
        }
    }
}
