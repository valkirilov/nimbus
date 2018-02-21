public class SimpleWeatherInfo : GLib.Object {

    public string city { get; set; }
    public string country { get; set; }
    public double temperature { get; set; }
    public string description { get; set; }
    public string icon { get; set; }

    public SimpleWeatherInfo() {
        this.city = "-";
        this.country = "-";
        this.temperature = 0;
        this.description = "-";
    }

    public signal void updated ();

    public void update () {
        updated ();
    }

    public string get_symbolic_icon_name () {
        string icon_name = "";
        switch (this.icon) {
            case "01d":
                icon_name = "weather-clear-sky-night-symbolic";
                break;
            case "01n":
                icon_name = "weather-clear-sky-symbolic";
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


}
