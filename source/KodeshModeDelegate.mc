import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Timer;

class KodeshModeDelegate extends WatchUi.BehaviorDelegate {
    private const EVENT_DEBOUNCE_MS = 500;

    private var _lastKeyTime as Number = 0;
    private var _exitTapCount as Number = 0;
    private var _exitTimer as Timer.Timer?;
    private const EXIT_TIMEOUT_MS = 5000;

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        return showPhoneSettingsOnly();
    }

    function isEnterKey(keyEvent) as Boolean {
        return keyEvent != null && keyEvent.getKey() == WatchUi.KEY_ENTER;
    }

    function isBackKey(keyEvent) as Boolean {
        return keyEvent != null && keyEvent.getKey() == WatchUi.KEY_ESC;
    }

    function isMenuKey(keyEvent) as Boolean {
        if (keyEvent == null) {
            return false;
        }

        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_MENU) {
            return true;
        }

        return false;
    }

    function onExitTimeout() as Void {
        _exitTapCount = 0;
        if (_exitTimer != null) {
            _exitTimer.stop();
            _exitTimer = null;
        }
    }

    function handlePrimaryPressed() as Void {
        var now = System.getTimer();

        if ((now - _lastKeyTime) < EVENT_DEBOUNCE_MS) {
            return;
        }

        _lastKeyTime = now;

        if (ShabbatMode.isEnabled()) {
            if (_exitTimer != null) {
                _exitTimer.stop();
            } else {
                _exitTimer = new Timer.Timer();
            }
            _exitTimer.start(method(:onExitTimeout), EXIT_TIMEOUT_MS, false);

            _exitTapCount++;

            if (_exitTapCount >= 3) {
                if (_exitTimer != null) {
                    _exitTimer.stop();
                    _exitTimer = null;
                }
                var tapToPass = _exitTapCount;
                _exitTapCount = 0; // reset for next time or if exit is cancelled
                var exitView = new ShabbatExitView(tapToPass);
                WatchUi.pushView(exitView, new ShabbatExitDelegate(exitView, tapToPass), WatchUi.SLIDE_IMMEDIATE);
            }
        } else {
            var enabled = ShabbatMode.enable();
            if (!enabled) {
                var sys = System.getDeviceSettings();
                if (sys has :requiresBurnInProtection && sys.requiresBurnInProtection) {
                    openGuide();
                } else {
                    WatchUi.requestUpdate();
                }
                return;
            }
            WatchUi.pushView(new ShabbatTransitionView(), null, WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function openMainMenuDebounced() as Boolean {
        var now = System.getTimer();

        if ((now - _lastKeyTime) < EVENT_DEBOUNCE_MS) {
            return true;
        }

        _lastKeyTime = now;
        return showPhoneSettingsOnly();
    }

    function showPhoneSettingsOnly() as Boolean {
        if (ShabbatMode.isEnabled()) {
            return true;
        } else {
            ShabbatMode.setStatus(ShabbatMode.settingsOnPhoneText());
            WatchUi.requestUpdate();
        }

        return true;
    }

    function onBack() as Boolean {
        if (ShabbatMode.isEnabled()) {
            return true;
        }

        return false;
    }

    function openGuide() as Boolean {
        var guide = new GuideView();
        WatchUi.pushView(guide, new GuideDelegate(guide), WatchUi.SLIDE_LEFT);
        return true;
    }

    function onHold(clickEvent as WatchUi.ClickEvent) as Boolean {
        return openMainMenuDebounced();
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        if (isMenuKey(keyEvent)) {
            return openMainMenuDebounced();
        }

        if (ShabbatMode.isEnabled()) {
            return true;
        }

        return false;
    }

    function onKeyPressed(keyEvent as WatchUi.KeyEvent) as Boolean {
        if (isMenuKey(keyEvent)) {
            return openMainMenuDebounced();
        }

        if (isEnterKey(keyEvent)) {
            handlePrimaryPressed();
            return true;
        }

        if (ShabbatMode.isEnabled()) {
            return true;
        }

        return false;
    }

    function onKeyReleased(keyEvent as WatchUi.KeyEvent) as Boolean {
        if (isEnterKey(keyEvent)) {
            return true;
        }

        if (isBackKey(keyEvent) && ShabbatMode.isEnabled()) {
            return true;
        }

        return false;
    }

    function onSelect() as Boolean {
        handlePrimaryPressed();
        return true;
    }

    function openMainMenu() as Boolean {
        return showPhoneSettingsOnly();
    }
}

var gLastInteractionTime as Number = 0;
