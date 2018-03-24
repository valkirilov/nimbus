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
    private SimpleWeatherInfo simple_weather_info;
    private Settings settings;
    private bool is_initialized;

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

        is_initialized = false;

        simple_weather_info = new SimpleWeatherInfo();
        settings = new Settings ("com.github.danrabbit.nimbus");

        build_ui_dock_settings ();

        var weather_icon = new Gtk.Image.from_icon_name ("content-loading-symbolic", Gtk.IconSize.DIALOG);

        var weather_label = new Gtk.Label (simple_weather_info.city);
        weather_label.halign = Gtk.Align.END;
        weather_label.hexpand = true;
        weather_label.margin_top = 6;
        weather_label.get_style_context ().add_class ("weather");

        var temp_label = new Gtk.Label (simple_weather_info.get_temperature ());
        temp_label.halign = Gtk.Align.START;
        temp_label.margin_bottom = 3;
        temp_label.get_style_context ().add_class ("temperature");

        var location_label = new Gtk.Label (simple_weather_info.country);
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

        stack.visible_child_name = "weather";

        build_ui_tray_indicator ();

        button_press_event.connect ((e) => {
            if (e.button == Gdk.BUTTON_PRIMARY) {
                begin_move_drag ((int) e.button, (int) e.x_root, (int) e.y_root, e.time);
                return true;
            }

            return false;
        });

        focus_in_event.connect (() => {
            simple_weather_info.update_weather_info ();
        });

        simple_weather_info.weather_info_updated.connect (() => {

            stack.visible_child_name = "weather";

            location_label.label = simple_weather_info.city + ", " + simple_weather_info.country;

            weather_icon.icon_name = simple_weather_info.get_symbolic_icon_name ();
            weather_label.label = simple_weather_info.description;

            // TODO: Refactor it
            //print(weather_icon.get_style_context () .list_classes ());
            weather_icon.get_style_context ().remove_class ("weather-snow");
            weather_icon.get_style_context ().remove_class ("weather-rain");
            weather_icon.get_style_context ().remove_class ("weather-clouds");
            weather_icon.get_style_context ().remove_class ("weather-fog");
            weather_icon.get_style_context ().add_class (simple_weather_info.get_icon_color ());

            temp_label.label = simple_weather_info.get_temperature ();

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
            //tray_indicator_menu_item.set_label (weather_label.label + " - " + location_label.label);

            Timeout.add (1000 * 60 * 15, () => {
                simple_weather_info.update_weather_info ();
            });

        });

        simple_weather_info.set_automatic_location (false);

        // Get the weather info
        if (settings.get_boolean ("settings-location-manual") == false) {
            simple_weather_info.set_automatic_location (true);
        }
        else if (settings.get_boolean ("settings-location-manual") == true) {
            string manual_location = settings.get_string ("settings-location-manual-value");
            simple_weather_info.set_manual_location (manual_location);
        }

    }

    public void build_ui_tray_indicator () {
        tray_indicator = new AppIndicator.Indicator("Nimbus", "indicator-messages", AppIndicator.IndicatorCategory.APPLICATION_STATUS);
        tray_indicator.set_attention_icon("content-loading-symbolic");

        if (settings.get_int ("settings-modes") == Nimbus.MODES_DEFAULT
            || settings.get_int ("settings-modes") == Nimbus.MODES_INDICATOR_ONLY) {
            tray_indicator.set_status (AppIndicator.IndicatorStatus.ATTENTION);
        }
        else if (settings.get_int ("settings-modes") == Nimbus.MODES_WIDGET_ONLY) {
            tray_indicator.set_status(AppIndicator.IndicatorStatus.PASSIVE);
        }

        var tray_indicator_menu = new Gtk.Menu();

        var tray_indicator_menu_item = new Gtk.MenuItem.with_label("Nimbus");
        tray_indicator_menu_item.show();
        tray_indicator_menu.append(tray_indicator_menu_item);

        var tray_indicator_menu_separator = new Gtk.SeparatorMenuItem ();
        tray_indicator_menu_separator.show ();
        tray_indicator_menu.append (tray_indicator_menu_separator);

        var tray_indicator_menu_item_preferences = new Gtk.MenuItem.with_label ("Preferences");
        tray_indicator_menu_item_preferences.show ();
        tray_indicator_menu_item_preferences.activate.connect (() => {
            open_preferences_dialog ();
        });
        tray_indicator_menu.append (tray_indicator_menu_item_preferences);

        var tray_indicator_menu_item_quit = new Gtk.MenuItem.with_label ("Quit");
        tray_indicator_menu_item_quit.show ();
        tray_indicator_menu_item_quit.activate.connect (Gtk.main_quit);
        tray_indicator_menu.append (tray_indicator_menu_item_quit);

        tray_indicator.set_menu(tray_indicator_menu);
    }

    public void build_ui_dock_settings() {
        var quicklist = new Dbusmenu.Menuitem ();

        // Create root's children
        var item_preferences = new Dbusmenu.Menuitem ();
        item_preferences.property_set (Dbusmenu.MENUITEM_PROP_LABEL, "Preferences");
        item_preferences.item_activated.connect (() => {
            open_preferences_dialog ();
        });

        // Add children to the quicklist
        quicklist.child_append (item_preferences);

        // Finally, tell libunity to show the desired quicklist
        var entry = Unity.LauncherEntry.get_for_desktop_id ("com.github.danrabbit.nimbus.desktop");
        entry.quicklist = quicklist;
    }

    public void open_preferences_dialog () {
        var dialog = new PreferencesDialog (this, tray_indicator, simple_weather_info);
        dialog.run ();
    }

}
