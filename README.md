Pi Kiosk - A collection of files to use a RasPi as a Kiosk device for a webpage

Contains udev Rules and hwdb files for calibration and adjustment of 3M EXII Touch controller that we happen to have access to use as a control dashboard.

In it's current form it uses Weston and Chromium as the interface.

To install on a RasPi, write raspbian lite to an sd card, copy all the files to a directory, plug the RasPi in and let it do it's setup process. After it has rebooted, you can log in and run the install script (requires a network connection).
