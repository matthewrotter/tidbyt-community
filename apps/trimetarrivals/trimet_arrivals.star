load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

# tidbyt-rtpi-rotter
KEY = "AV6+xWcEh5NwKoBQWuqhebPskYm6mM1A8qkaTsfhZu0DC7eYQG4PgEfsiHq2H9a0Yl2U+6RQXjsLpXIRBLhQnFWiFf+j3/NtMbffxZMhyYRCSSlJb5l0+eVi5BtxZDesmkQLFYIRKUxZMbAacUTkt3TT4OSVnW4OErY7bXAOAA=="

DEFAULT_LOCATION = """
{"lat":45.6,"lng":"-122.64","locality":"Portland, OR","timezone":"America/Los_Angeles"}
"""
DEFAULT_STOP = "13043"
URL = "https://developer.trimet.org/ws/V2/arrivals?locIDs={}&appID={}&json=true"
# URL = "https://developer.trimet.org/ws/V2/arrivals?locIDs={}&appID=3EE99DA9677E312D637CED197&json=true"

def main(config):
    api_key = secret.decrypt(KEY) or "3EE99DA9677E312D637CED197"
    # print("api_key: %s" % api_key)

    # config
    # font_sm = config.get("font-sm", "tom-thumb")
    font_sm = config.get("font-sm", "CG-pixel-3x5-mono")
    font_lg = config.get("font-lg", "6x13")
    color_primary = config.str("color-primary", "#0F387A")
    color_secondary = config.str("color-secondary", "#C4321E")
    stop = config.str("stop", DEFAULT_STOP)
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone).format("1/2 3:04 PM")

    print("stop: {0}; pcol: {1}; scol: {2}".format(stop, color_primary, color_secondary))

    stop_cached = cache.get("stop")
    if stop_cached != None:
        print("Hit! Displaying cached data.")
        rep = json.decode(stop_cached)
    else:
        print("Miss! Calling TriMet API with")
        response = http.get(URL.format(stop, api_key))
        if response.status_code != 200:
            fail("request failed with status %d", response.status_code)
        rep = response.json()
        # print(rep)
        cache.set("stop", json.encode(rep), ttl_seconds = 5)

    # print(rep["resultSet"])
    stop = rep["resultSet"]["location"][0]["desc"]
    valid_arrivals = [x for x in rep["resultSet"]["arrival"] if x["status"] == "estimated"]

    est = int(valid_arrivals[0]["estimated"])
    conv = time.from_timestamp(est // 1000).in_location(timezone).format("3:04 PM")
    route = str(int(valid_arrivals[0]["route"]))

    alt_est = int(valid_arrivals[1]["estimated"])
    alt_conv = time.from_timestamp(alt_est // 1000).in_location(timezone).format("3:04 PM")
    alt_route = str(int(valid_arrivals[1]["route"]))

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Marquee(
                    width = 64,
                    align = "start",
                    offset_start = 5,
                    offset_end = 8,
                    child = render.Text(
                        content = "%s" % stop,
                        font = font_sm,
                        color = color_primary,
                    ),
                ),
                render.Row(
                    main_align = "space_around",
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Box(
                            height = 14,
                            width = 16,
                            color = color_secondary,
                            child = render.Text(
                                content = route,
                                font = font_lg,
                            ),
                        ),
                        render.Text(
                            content = "%s" % conv,
                            font = font_lg,
                            color = color_secondary,
                        ),
                    ],
                ),
                render.Row(
                    main_align = "space_around",
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Box(
                            height = 9,
                            width = 12,
                            color = color_primary,
                            child = render.Text(
                                content = alt_route,
                                font = font_sm,
                            ),
                        ),
                        render.Text(
                            content = "%s" % alt_conv,
                            font = font_sm,
                            color = color_primary,
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop",
                name = "Stop ID",
                desc = "Enter a TriMet Stop ID",
                icon = "bus",
                default = DEFAULT_STOP,
            ),
            schema.Color(
                id = "color_primary",
                name = "Primary Color",
                desc = "Color of the top and bottom lines.",
                icon = "brush",
                default = "#0F387A",
            ),
            schema.Color(
                id = "color_secondary",
                name = "Secondary Color",
                desc = "Color of the middle line.",
                icon = "brush",
                default = "#C4321E",
            ),
        ],
    )
