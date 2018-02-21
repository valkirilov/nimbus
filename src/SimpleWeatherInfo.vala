public class SimpleWeatherInfo : GLib.Object {

    public double latitude { get; set; }
    public double longitude { get; set; }
    public string city { get; set; }
    public string country { get; set; }
    public double temperature;
    public string description { get; set; }
    public string icon { get; set; }

    public SimpleWeatherInfo() {
        this.latitude = 0.0;
        this.longitude = 0.0;
        this.city = "-";
        this.country = "-";
        this.temperature = 0;
        this.description = "-";
    }

    public signal void weather_info_updated ();
    public signal void location_updated ();

    public void set_location (double latitude, double longitude) {
        this.latitude = latitude;
        this.longitude = longitude;

        location_updated ();
    }

    public void update_weather_info () {
        string APP_ID = "c15c9ccbeb1c536e7cdcad2ef4c82c42";
        string API_URL = "http://api.openweathermap.org/data/2.5/weather";

        var uri = "%s?lat=%f&lon=%f&appid=%s&units=metric".printf (API_URL, this.latitude, this.longitude, APP_ID);
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
        string icon_name = "";
        switch (this.icon) {
            case "01d":
                icon_name = "weather-clear-sky-symbolic";
                break;
            case "01n":
                icon_name = "weather-clear-sky-night-symbolic";
                break;
            case "02d":
            case "04d":
                icon_name = "weather-few-clouds-symbolic";
                break;
            case "02n":
            case "04n":
                icon_name = "weather-few-clouds-night-symbolic";
                break;
            case "03d":
                icon_name = "weather-scattered-clouds-symbolic";
                break;
            case "03n":
                icon_name = "weather-scattered-clouds-night-symbolic";
                break;
            case "09d":
                icon_name = "weather-shower-rain-symbolic";
                break;
            case "09n":
                icon_name = "weather-shower-rain-night-symbolic";
                break;
            case "10d":
                icon_name = "weather-rain-symbolic";
                break;
            case "10n":
                icon_name = "weather-rain-night-symbolic";
                break;
            case "11d":
                icon_name = "weather-thunderstorm-symbolic";
                break;
            case "11n":
                icon_name = "weather-thunderstorm-night-symbolic";
                break;
            case "13d":
                icon_name = "weather-snow-symbolic";
                break;
            case "13n":
                icon_name = "weather-snow-night-symbolic";
                break;
            case "50d":
                icon_name = "weather-mist-symbolic";
                break;
            case "50n":
                icon_name = "weather-mist-night-symbolic";
                break;
         }

         stdout.printf ("Icon: %s : %s\n", this.icon, icon_name);
         return icon_name;
    }

    public string get_weather_color () {
        string color_primary;

        switch (this.get_symbolic_icon_name ()) {
            case "weather-clear-night-symbolic":
            case "weather-few-clouds-night-symbolic":
                color_primary = "#183048";
                break;
            case "weather-few-clouds-symbolic":
            case "weather-overcast-symbolic":
            case "weather-showers-symbolic":
            case "weather-showers-scattered-symbolic":
                color_primary = "#68758e";
                break;
            case "weather-snow-symbolic":
                color_primary = "#6fc3ff";
                break;
            default:
                color_primary = "#42baea";
                break;
        }

        return color_primary;
    }

    public void print_weather_info () {
        stdout.printf ("City: %s\n", this.city);
        stdout.printf ("Country: %s\n", this.country);
        stdout.printf ("Description: %s\n", this.description);
        stdout.printf ("Temperature: %f\n", this.temperature);
    }


}