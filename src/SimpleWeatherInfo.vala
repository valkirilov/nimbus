public class SimpleWeatherInfo : GLib.Object {

    public double latitude { get; set; }
    public double longitude { get; set; }
    public string city { get; set; }
    public string country { get; set; }
    public double temperature;
    public string description { get; set; }
    public string icon { get; set; }

    public string geo_city;
    public string geo_country;

    private GLib.HashTable<string, string> table_icon_names;
    private GLib.HashTable<string, string> table_weather_colors;
    private GLib.HashTable<string, string> table_icon_colors;

    private Settings settings;

    public SimpleWeatherInfo() {
        this.latitude = 0.0;
        this.longitude = 0.0;
        this.city = "-";
        this.country = "-";
        this.temperature = 0;
        this.description = "-";

        settings = new Settings ("com.github.danrabbit.nimbus");

        table_icon_names = new GLib.HashTable<string, string> (str_hash, str_equal);
        table_icon_names.insert("01d", "weather-clear-symbolic");
        table_icon_names.insert("01n", "weather-clear-night-symbolic");
        table_icon_names.insert("02d", "weather-few-clouds-symbolic");
        table_icon_names.insert("02n", "weather-few-clouds-night-symbolic");
        table_icon_names.insert("03d", "weather-overcast-symbolic");
        table_icon_names.insert("03n", "weather-overcast-symbolic");
        table_icon_names.insert("04d", "weather-overcast-symbolic");
        table_icon_names.insert("04n", "weather-overcast-symbolic");
        table_icon_names.insert("09d", "weather-showers-symbolic");
        table_icon_names.insert("09n", "weather-showers-symbolic");
        table_icon_names.insert("10d", "weather-showers-scattered-symbolic");
        table_icon_names.insert("10n", "weather-showers-scattered-symbolic");
        table_icon_names.insert("11d", "weather-storm-symbolic");
        table_icon_names.insert("11n", "weather-storm-symbolic");
        table_icon_names.insert("13d", "weather-snow-symbolic");
        table_icon_names.insert("13n", "weather-snow-symbolic");
        table_icon_names.insert("50d", "weather-fog-symbolic");
        table_icon_names.insert("50n", "weather-fog-symbolic");

        table_weather_colors = new GLib.HashTable<string, string> (str_hash, str_equal);
        table_weather_colors.insert("weather-overcast-symbolic", "#68758e");
        table_weather_colors.insert("weather-showers-symbolic", "#68758e");
        table_weather_colors.insert("weather-showers-scattered-symbolic", "#68758e");
        table_weather_colors.insert("weather-storm-symbolic", "#555c68");
        table_weather_colors.insert("weather-snow-symbolic", "#9ca7ba");
        table_weather_colors.insert("weather-fog-symbolic", "#a1a6af");

        table_icon_colors = new GLib.HashTable<string, string> (str_hash, str_equal);
        table_icon_colors.insert("weather-snow-symbolic", "weather-snow");
        table_icon_colors.insert("weather-snow-night-symbolic", "weather-snow");
        table_icon_colors.insert("weather-showers-symbolic", "weather-rain");
        table_icon_colors.insert("weather-showers-scattered-symbolic", "weather-rain");
        table_icon_colors.insert("weather-showers-scattered-night-symbolic", "weather-rain");
        table_icon_colors.insert("weather-few-clouds-symbolic", "weather-clouds");
        table_icon_colors.insert("weather-overcast-symbolic", "weather-clouds");
        table_icon_colors.insert("weather-fog-symbolic", "weather-fog");
    }

    public signal void weather_info_updated ();
    public signal void location_updated ();

    public void set_location (double latitude, double longitude) {
        this.latitude = latitude;
        this.longitude = longitude;

        location_updated ();
    }

    public void get_location_info (bool fetch_weather_info) {
      string APP_ID = "c15c9ccbeb1c536e7cdcad2ef4c82c42";
      string API_URL = "http://api.openweathermap.org/data/2.5/weather";
      string units = this.get_units ();

      string uri = "%s?lat=%f&lon=%f&appid=%s&units=%s".printf (API_URL, this.latitude, this.longitude, APP_ID, units);

      stdout.printf ("API URI: %s\n", uri);

      var session = new Soup.Session ();
      var message = new Soup.Message ("GET", uri);
      session.send_message (message);

      try {
          var parser = new Json.Parser ();
          parser.load_from_data ((string) message.response_body.flatten ().data, -1);

          var response_root_object = parser.get_root ().get_object ();
          var sys = response_root_object.get_object_member ("sys");

          this.geo_city = response_root_object.get_string_member ("name");
          this.geo_country = sys.get_string_member ("country");

          this.print_weather_info ();

          if (fetch_weather_info) {
              this.update_weather_info ();
          }
      } catch (Error e) {
          stderr.printf ("Failed to connect to OpenWeatherMap service.\n");
      }
    }

    public void update_weather_info () {
        string APP_ID = "c15c9ccbeb1c536e7cdcad2ef4c82c42";
        string API_URL = "http://api.openweathermap.org/data/2.5/weather";
        string units = this.get_units ();

        string uri;
        if (settings.get_boolean ("settings-location-manual") == false) {
            uri = "%s?lat=%f&lon=%f&appid=%s&units=%s".printf (API_URL, this.latitude, this.longitude, APP_ID, units);
        }
        else {
            uri = "%s?q=%s,%s&appid=%s&units=%s".printf (API_URL, this.city, this.country, APP_ID, units);
        }

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

            this.city = response_root_object.get_string_member ("name");
            this.country = sys.get_string_member ("country");
            this.temperature = main.get_double_member ("temp");
            this.description = weather_descriptnon;
            this.icon = weather_icon;

            this.print_weather_info ();
            this.weather_info_updated ();
        } catch (Error e) {
            stderr.printf ("Failed to connect to OpenWeatherMap service.\n");
        }
    }

    public string get_temperature () {
        var formatted_temperature = _("%i°").printf ((int) this.temperature);
        return formatted_temperature;
    }

    public string get_symbolic_icon_name () {
        string icon_name = this.table_icon_names.get (this.icon);

        stdout.printf ("Icon: %s : %s\n", this.icon, icon_name);
        return icon_name;
    }

    public string get_weather_color () {
        string color_primary = "#42baea";
        string icon_name = this.get_symbolic_icon_name ();

        if (this.table_weather_colors.contains (icon_name)) {
            color_primary = this.table_weather_colors.get (icon_name);
        }

        if (this.icon[2] == 'n') {
            color_primary = "#183048";
        }

        stdout.printf ("Weather color: %s\n", color_primary);

        return color_primary;
    }

    public string get_icon_color () {
        string icon_name = this.get_symbolic_icon_name ();
        string icon_color = "none";

        if (this.table_icon_colors.contains (icon_name)) {
            icon_color = this.table_icon_colors.get (icon_name);
        }

        stdout.printf ("Icon Color: %s\n", icon_color);
        return icon_color;
    }

    public void print_weather_info () {
        stdout.printf ("City: %s\n", this.city);
        stdout.printf ("Country: %s\n", this.country);
        stdout.printf ("Description: %s\n", this.description);
        stdout.printf ("Temperature: %f\n", this.temperature);

        stdout.printf ("GEO City: %s\n", this.geo_city);
        stdout.printf ("GEO Country: %s\n", this.geo_country);
    }

    public string get_units () {
        if (settings.get_int ("settings-units") == Nimbus.UNITS_CELSIUS) {
            return "metric";
        }
        else if (settings.get_int ("settings-units") == Nimbus.UNITS_FAHRENHEIT) {
            return "imperial";
        }
        return "metric";
    }

    public void set_automatic_location(bool fetch_weather_info) {
        get_location.begin (fetch_weather_info);
    }

    public async void get_location (bool fetch_weather_info) {
        try {
            var simple = yield new GClue.Simple ("com.github.danrabbit.nimbus", GClue.AccuracyLevel.CITY, null);
            on_location_updated (simple.location.latitude, simple.location.longitude, fetch_weather_info);
        } catch (Error e) {
            warning ("Failed to connect to GeoClue2 service: %s", e.message);
            //stack.visible_child_name = "alert";
            return;
        }
    }

    public void on_location_updated (double latitude, double longitude, bool fetch_weather_info) {
        this.set_location (latitude, longitude);
        this.get_location_info (fetch_weather_info);
    }

    public void set_manual_location(string location) {
        string[] location_details = location.split (", ");
        this.city = location_details[0];
        this.country = location_details[1];

        this.update_weather_info ();
    }

}
