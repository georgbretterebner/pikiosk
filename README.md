# Currently pfusch! <del>Don't use yet!</del> Might be ready to use.
## I warned you.

Pi Kiosk - A collection of files and scripts to use a RasPi as a Kiosk device for a webpage. Builds a custom image that is then flashed to an SD-Card. Just run the script and insert the SD-Card into your Pi. Done. Everything else is set up automatically.

Contains udev Rules and hwdb files for calibration and adjustment of 3M EXII Touch controller that we have lying around and use as a control dashboard.

In it's current form it uses Weston and Chromium in kiosk mode for the user interface.

To install on a RasPi, insert an SD-Card run install.sh and follow the install script.

You might want to check install.sh and update the links as described in the file first! (Especially if you want to run it on HW other than RasPi 3 series!!)
