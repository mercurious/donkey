// Donkey's Firefox settings. launch.sh writes them into the profile on
// every start, so edit profile/user.js in Donkey's home, not the copy.

// Size: the Retroid Pocket Flip 2 packs 1920x1080 into 5.5 inches (~400 ppi).
// Twice the desktop pixel ratio, plus touch density for the toolbar, makes
// the browser chrome legible at arm's length. userChrome.css adds the rest.
user_pref("layout.css.devPixelsPerPx", "2.0");
user_pref("browser.uidensity", 2);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Dark everywhere: the screen is OLED, and the keyboard is dark too.
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
user_pref("layout.css.prefers-color-scheme.content-override", 0);

// Touch and controller input.
user_pref("dom.w3c_touch_events.enabled", 1);
user_pref("apz.allow_zooming", true);
user_pref("general.smoothScroll", true);
// B sends Alt+Left for Back; a bare Alt must not open the menu bar.
user_pref("ui.key.menuAccessKeyFocuses", false);

// A handheld browser: pick up where you left off, no first-run detours.
user_pref("browser.startup.page", 3);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.toolbars.bookmarks.visibility", "never");
