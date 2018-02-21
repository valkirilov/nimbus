/*
* Copyright (c) 2017 Daniel Foré (http://danielfore.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

public class MainWindow : Gtk.Dialog {
    private const string COLOR_PRIMARY = """
        @define-color colorPrimary %s;
        .background,
        .titlebar {
            transition: all 600ms ease-in-out;
        }
    """;

    private Gtk.Stack stack;
    private AppIndicator.Indicator tray_indicator;

    private GWeather.Location location;
    private GWeather.Info weather_info;
    private SimpleWeatherInfo simple_weather_info;

    public MainWindow (Gtk.Application application) {
        Object (application: application,
                icon_name: "com.github.danrabbit.nimbus",
                resizable: false,
                title: _("Nimbus"),
                height_request: 272,
                width_request: 500);
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        set_keep_below (true);
        stick ();

        simple_weather_info = new SimpleWeatherInfo();

        get_location.begin ();

        weather_info = new GWeather.Info (location, GWeather.ForecastType.LIST);

        var weather_icon = new Gtk.Image.from_icon_name (weather_info.get_symbolic_icon_name (), Gtk.IconSize.DIALOG);

        var weather_label = new Gtk.Label (weather_info.get_sky ());
        weather_label.halign = Gtk.Align.END;
        weather_label.hexpand = true;
        weather_label.margin_top = 6;
        weather_label.get_style_context ().add_class ("weather");

        var temp_label = new Gtk.Label (weather_info.get_temp ());
        temp_label.halign = Gtk.Align.START;
        temp_label.margin_bottom = 3;
        temp_label.get_style_context ().add_class ("temperature");

        var location_label = new Gtk.Label ("");
        location_label.halign = Gtk.Align.END;
        location_label.margin_bottom = 12;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.margin_bottom = 6;
        grid.margin_end = 18;
        grid.margin_start = 18;
        grid.attach (weather_icon, 0, 0, 1, 2);
        grid.attach (temp_label, 1, 0, 1, 2);
        grid.attach (weather_label, 2, 0, 1, 1);
        grid.attach (location_label, 2, 1, 1, 1);

        var spinner = new Gtk.Spinner ();
        spinner.active = true;
        spinner.halign = Gtk.Align.CENTER;
        spinner.vexpand = true;

        var alert_label = new Gtk.Label (_("Unable to Get Location"));

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        stack.vhomogeneous = true;
        stack.add (spinner);
        stack.add_named (grid, "weather");
        stack.add_named (alert_label, "alert");

        var content_box = get_content_area () as Gtk.Box;
        content_box.border_width = 0;
        content_box.add (stack);
        content_box.show_all ();

        var action_box = get_action_area () as Gtk.Box;
        action_box.visible = false;

        tray_indicator = new AppIndicator.Indicator("Koki", "indicator-messages",
            AppIndicator.IndicatorCategory.APPLICATION_STATUS);

        tray_indicator.set_status(AppIndicator.IndicatorStatus.ATTENTION);
        tray_indicator.set_attention_icon("content-loading-symbolic");

        var tray_indicator_menu = new Gtk.Menu();

        var tray_indicator_menu_item = new Gtk.MenuItem.with_label("Nimbus");
        tray_indicator_menu_item.show();
        tray_indicator_menu.append(tray_indicator_menu_item);

        tray_indicator.set_menu(tray_indicator_menu);

        button_press_event.connect ((e) => {
            if (e.button == Gdk.BUTTON_PRIMARY) {
                begin_move_drag ((int) e.button, (int) e.x_root, (int) e.y_root, e.time);
                return true;
            }
            return false;
        });

        focus_in_event.connect (() => {
            weather_info.update ();
        });

        simple_weather_info.updated.connect (() => {
            stdout.printf ("Update weather inormation...\n");

            location_label.label = simple_weather_info.city + ", " + simple_weather_info.country;

            weather_icon.icon_name = simple_weather_info.get_symbolic_icon_name ();
            weather_label.label = simple_weather_info.description;

            temp_label.label = _("%i°").printf ((int) simple_weather_info.temperature);

            string color_primary = simple_weather_info.get_weather_color ();
            var provider = new Gtk.CssProvider ();
            try {
                var colored_css = COLOR_PRIMARY.printf (color_primary);
                provider.load_from_data (colored_css, colored_css.length);
                 Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (GLib.Error e) {
                critical (e.message);
            }

            tray_indicator.set_attention_icon(weather_icon.icon_name);
            tray_indicator.set_label("  " + temp_label.label, temp_label.label);
            tray_indicator_menu_item.set_label (weather_label.label + " - " + location_label.label);
        });

    }

    public async void get_location () {
        try {
            var simple = yield new GClue.Simple ("com.github.danrabbit.nimbus", GClue.AccuracyLevel.CITY, null);

            simple.notify["location"].connect (() => {
                on_location_updated (simple.location.latitude, simple.location.longitude);
            });

            on_location_updated (simple.location.latitude, simple.location.longitude);
        } catch (Error e) {
            warning ("Failed to connect to GeoClue2 service: %s", e.message);
            stack.visible_child_name = "alert";
            return;
        }
    }

    public void on_location_updated (double latitude, double longitude) {
        location = GWeather.Location.get_world ();
        location = location.find_nearest_city (latitude, longitude);
        if (location != null) {
            stack.visible_child_name = "weather";
            get_weather_info(location.get_city_name (), location.get_country ());
        }
    }

    public void get_weather_info (string city, string country) {
        string APP_ID = "c15c9ccbeb1c536e7cdcad2ef4c82c42";
        string API_URL = "http://api.openweathermap.org/data/2.5/weather";

        var uri = "%s?q=%s,%s&appid=%s&units=metric".printf (API_URL, city, country.down (), APP_ID);
        stdout.printf ("API URI: %s\n", uri);

        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", uri);
        session.send_message (message);

        try {
            var parser = new Json.Parser ();
            parser.load_from_data ((string) message.response_body.flatten ().data, -1);

            var response_root_object = parser.get_root ().get_object ();
            var weather = response_root_object.get_array_member ("weather");
            var sys = response_root_object.get_object_member ("sys");
            var main = response_root_object.get_object_member ("main");

            string weather_descriptnon = "";
            string weather_icon = "";
            foreach (var weather_details_item in weather.get_elements ()) {
                var weather_details = weather_details_item.get_object ();
                weather_descriptnon = weather_details.get_string_member ("main");
                weather_icon = weather_details.get_string_member ("icon");
            }

            simple_weather_info.city = response_root_object.get_string_member ("name");
            simple_weather_info.country = sys.get_string_member ("country");
            simple_weather_info.temperature = main.get_double_member ("temp");
            simple_weather_info.description = weather_descriptnon;
            simple_weather_info.icon = weather_icon;

            stdout.printf ("City: %s\n", simple_weather_info.city);
            stdout.printf ("Country: %s\n", simple_weather_info.country);
            stdout.printf ("Description: %s\n", simple_weather_info.description);
            stdout.printf ("Temperature: %f\n", simple_weather_info.temperature);

            simple_weather_info.update ();
        } catch (Error e) {
            stderr.printf ("I guess something is not working...\n");
        }
    }
}
