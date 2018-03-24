

public class PreferencesDialog : Gtk.Dialog {

    MainWindow main_window;
    SimpleWeatherInfo simple_wheater_info;
    AppIndicator.Indicator tray_indicator;

    private Gtk.ComboBox units_box;
    private Gtk.ComboBox modes_box;
    private Gtk.Entry manual_location_entry;
    private Gtk.Switch manual_location_switch;

    private Settings settings;

    public PreferencesDialog (MainWindow main_window, AppIndicator.Indicator tray_indicator, SimpleWeatherInfo simple_wheater_info) {
        //set_transient_for (window);
        settings = new Settings ("com.github.danrabbit.nimbus");

        this.main_window = main_window;
        this.simple_wheater_info = simple_wheater_info;
        this.tray_indicator = tray_indicator;

        build_ui ();
        connect_signals ();
    }

    string[] available_units = {"Celsius", "Fahrenheit"};
    string[] available_modes = {"Default", "Only widget", "Only indicator"};

    private void build_ui () {
        this.set_border_width (12);
        this.window_position = Gtk.WindowPosition.CENTER;
        this.get_style_context ().add_class ("preferences");

        set_size_request (590, 530);
        resizable = false;
        deletable = false;
        modal = true;

        var grid = new Gtk.Grid ();
        grid.set_column_homogeneous (false);
        grid.set_row_homogeneous (false);
        grid.row_spacing = 8;
        grid.column_spacing = 8;

        var general_section_label = new Gtk.Label ("<b>General</b>");
        general_section_label.set_use_markup (true);
        general_section_label.set_halign (Gtk.Align.START);

        var units_label = new Gtk.Label ("Units");
        units_label.set_halign (Gtk.Align.START);
        build_units_box();

        var modes_label = new Gtk.Label ("Mode");
        modes_label.set_halign (Gtk.Align.START);
        build_modes_box();

        var location_section_label = new Gtk.Label ("<b>Location</b>");
        location_section_label.set_use_markup (true);
        location_section_label.set_halign (Gtk.Align.START);

        var automatic_location_label = new Gtk.Label ("Automatic");
        automatic_location_label.set_halign (Gtk.Align.START);

        var automatic_location_value_label = new Gtk.Label (
            this.simple_wheater_info.geo_city + ", " + this.simple_wheater_info.geo_country
        );
        automatic_location_value_label.set_halign (Gtk.Align.START);

        var manual_location_label = new Gtk.Label ("Manual");
        manual_location_label.set_halign (Gtk.Align.START);
        manual_location_entry = new Gtk.Entry ();
        manual_location_entry.set_placeholder_text ("London, UK");
        manual_location_entry.set_text (settings.get_string ("settings-location-manual-value"));

        manual_location_switch = new Gtk.Switch ();
        if (settings.get_boolean ("settings-location-manual") == false) {
            manual_location_entry.set_sensitive (false);
            manual_location_switch.set_active (false);
        }
        else if (settings.get_boolean ("settings-location-manual") == true) {
            manual_location_entry.set_sensitive (true);
            manual_location_switch.set_active (true);
        }

        grid.attach (general_section_label, 1, 1, 1, 1);
        grid.attach (units_label, 1, 3, 3, 1);
        grid.attach (units_box, 4, 3, 3, 1);
        grid.attach (modes_label, 1, 4, 3, 1);
        grid.attach (modes_box, 4, 4, 3, 1);

        grid.attach (location_section_label, 1, 5, 1, 1);
        grid.attach (automatic_location_label, 1, 6, 3, 1);
        grid.attach (automatic_location_value_label, 4, 6, 3, 1);
        grid.attach (manual_location_label, 1, 7, 3, 1);
        grid.attach (manual_location_entry, 4, 7, 3, 1);
        grid.attach (manual_location_switch, 8, 7, 3, 1);

        this.get_content_area().add (grid);

        add_button (_("_Close"), Gtk.ResponseType.CLOSE);

        this.show_all ();
    }

    private void build_units_box () {
        Gtk.ListStore liststore_units = new Gtk.ListStore (1, typeof (string));

        for (int i = 0; i < available_units.length; i++){
            Gtk.TreeIter iter;
            liststore_units.append (out iter);
            liststore_units.set (iter, 0, available_units[i]);
        }

        units_box = new Gtk.ComboBox.with_model (liststore_units);
        Gtk.CellRendererText cell_units = new Gtk.CellRendererText ();
        units_box.pack_start (cell_units, false);
        units_box.set_attributes (cell_units, "text", 0);

        units_box.set_active (settings.get_int ("settings-units"));
    }

    private void build_modes_box () {
        Gtk.ListStore liststore_modes = new Gtk.ListStore (1, typeof (string));

        for (int i = 0; i < available_modes.length; i++){
            Gtk.TreeIter iter;
            liststore_modes.append (out iter);
            liststore_modes.set (iter, 0, available_modes[i]);
        }

        modes_box = new Gtk.ComboBox.with_model (liststore_modes);
        Gtk.CellRendererText cell_modes = new Gtk.CellRendererText ();
        modes_box.pack_start (cell_modes, false);
        modes_box.set_attributes (cell_modes, "text", 0);

        modes_box.set_active (settings.get_int ("settings-modes"));
    }

    private void connect_signals () {

        units_box.changed.connect (() => {
            //string unit = available_units[units_box.get_active ()];
            settings.set_int ("settings-units", units_box.get_active ());
            this.simple_wheater_info.update_weather_info ();
        });

        modes_box.changed.connect (() => {
            //string mode = available_modes[modes_box.get_active ()];
            settings.set_int ("settings-modes", modes_box.get_active ());

            if (modes_box.get_active () == Nimbus.MODES_DEFAULT) {
                this.main_window.show ();
                this.tray_indicator.set_status (AppIndicator.IndicatorStatus.ATTENTION);
            }
            else if (modes_box.get_active () == Nimbus.MODES_WIDGET_ONLY) {
                this.main_window.show ();
                this.tray_indicator.set_status(AppIndicator.IndicatorStatus.PASSIVE);
            }
            else if (modes_box.get_active () == Nimbus.MODES_INDICATOR_ONLY) {
                this.main_window.hide ();
                this.tray_indicator.set_status(AppIndicator.IndicatorStatus.ATTENTION);
            }
        });

        manual_location_switch.state_set.connect ((state) => {
            manual_location_entry.set_sensitive (state);
            settings.set_boolean ("settings-location-manual", state);

            if (state) {
                string manual_location = manual_location_entry.get_text ();
                this.simple_wheater_info.set_manual_location (manual_location);
            }
            else {
                this.simple_wheater_info.set_automatic_location (true);
            }

            return false;
        });

        manual_location_entry.changed.connect (() => {
            string manual_location = manual_location_entry.get_text ();
            settings.set_string ("settings-location-manual-value", manual_location);
            this.simple_wheater_info.set_manual_location (manual_location);
            this.simple_wheater_info.update_weather_info ();
        });

        this.response.connect (on_response);
    }

    private void on_response (Gtk.Dialog source, int response_id) {
        switch (response_id) {
            case Gtk.ResponseType.CLOSE:
                destroy ();
            break;
        }
    }

}
