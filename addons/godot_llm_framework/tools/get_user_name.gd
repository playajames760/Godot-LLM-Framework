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

func execute(_input: Dictionary) -> String:
    # Implement actual weather fetching logic here
    if OS.has_environment("USERNAME"):
        return OS.get_environment("USERNAME")
    elif OS.has_environment("USER"):
        return OS.get_environment("USER")
    else:
        return "John Doe"