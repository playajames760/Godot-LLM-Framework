extends BaseTool

class_name UserNameTool

func _init():
    super._init(
        "get_user_name",
        "Gets the current user's name",
        {
            "type": "object"
        }
    )

func execute(_input: Dictionary) -> Dictionary:
    var result = {
        "output" = "",
        "is_error" = false
    }
    if OS.has_environment("USERNAME"):
        result.output = OS.get_environment("USERNAME")
    elif OS.has_environment("USER"):
        result.output = OS.get_environment("USER")
    else:
        result.output = "John Doe"
    return result