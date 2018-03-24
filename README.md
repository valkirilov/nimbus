# Nimbus
See the current temperature and weather conditions for your location with this minimal color-changing applet.

![Nimbus Screenshot](https://raw.github.com/valkirilov/nimbus/master/data/screenshot.gif)

Changes in this version:
* Wingpanel indicator with basic info for the current weather conditions
* Preferences window
* 3 view modes (Only widget, only indicator or both)
* Units type (Celsius, Fahrenheit)
* Manual location
* Using [Open Weather Map](http://openweathermap.org/) instead of GWeather

### Forked by Daniel Foré
[Official repo](https://github.com/danrabbit/nimbus)

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.danrabbit.nimbus)

## Building, Testing, and Installation

You'll need the following dependencies to build:
* libgeoclue-2-dev
* libgtk-3-dev
* libgweather-3-dev
* meson
* valac
* libappindicator3-dev
* libunity-dev

You'll need the following dependencies to run:
* geoclue-2.0

Run `meson build` to configure the build environment and run `ninja test` to build and run automated tests

    meson build --prefix=/usr
    cd build
    ninja test

To install, use `ninja install`, then execute with `com.github.danrabbit.nimbus`

    sudo ninja install
    com.github.danrabbit.nimbus
