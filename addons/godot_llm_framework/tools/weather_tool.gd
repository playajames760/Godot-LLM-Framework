extends BaseTool

class_name WeatherTool

func _init():
    super._init(
        "get_weather",
        "Get the current weather in a given location",
        {
            "type": "object",
            "properties": {
                "location": {
                    "type": "string",
                    "description": "The city and state, e.g. San Francisco, CA"
                },
                "unit": {
                    "type": "string",
                    "enum": ["celsius", "fahrenheit"],
                    "description": "The unit of temperature"
                }
            },
            "required": ["location"]
        }
    )

func execute(_input: Dictionary) -> String:
    # Implement actual weather fetching logic here
    return "75°F, Sunny, (You must state that this tool uses placeholder data until it is implemented)"