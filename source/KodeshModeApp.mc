import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class KodeshModeApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        KodeshSettings.migrateLegacyStorageToProperties();
        KodeshSettings.initializeMissingStorageFromProperties();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Called after App Settings are changed from Garmin Connect / Connect IQ.
    function onSettingsChanged() as Void {
        KodeshSettings.syncPropertiesToStorage();
        AppFonts.clearCustomFontCache();
        WatchUi.requestUpdate();
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new KodeshModeView(), new KodeshModeDelegate() ];
    }

}

function getApp() as KodeshModeApp {
    return Application.getApp() as KodeshModeApp;
}