# Godot LLM Framework

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Basic Setup](#basic-setup)
  - [Generating Responses](#generating-responses)
  - [Using Tools](#using-tools)
  - [Creating Custom Tools](#creating-custom-tools)
- [API Reference](#api-reference)
- [Configuration](#configuration)
- [Examples](#examples)
- [Contributing](#contributing)
- [License](#license)

## Introduction

The Godot LLM Framework is a powerful addon for the Godot game engine that enables seamless integration of Large Language Models (LLMs) into your game development workflow. This framework provides a unified interface for working with different LLM providers, making it easy to incorporate advanced natural language processing, dialogue generation, and dynamic content creation directly within your Godot projects.

## Features

- Support for multiple LLM providers (currently Anthropic's Claude, with OpenAI support in progress)
- Easy-to-use API for generating responses from LLMs
- Tool system for extending LLM capabilities with custom functions
- Configurable settings for fine-tuning LLM behavior
- Message history management for contextual conversations
- Asynchronous operations for smooth integration with Godot's event loop

## Installation

Find the addon using the [Godot Asset Library](https://godotengine.org/asset-library) or follow the instructions below for manual installs

1. Download the `godot_llm_framework` folder from this repository.
2. Place the folder in your Godot project's `addons/` directory.
3. Enable the addon in your project settings:
   - Go to "Project" > "Project Settings" > "Plugins"
   - Find "Godot LLM Framework" and check the "Enable" box

## Usage

### Basic Setup

1. Add an LLM node to your scene.
2. Configure the LLM node in the Inspector:
   - Set the `Provider` (e.g., ANTHROPIC)
   - Enter your API key
   - Adjust other settings as needed (model, temperature, etc.)

### Generating Responses

```gdscript
@onready var llm = $LLM

func _ready():
    var response = await llm.generate_response("Tell me a joke about game development.")
    print(response)
```

### Using Tools

1. Register tools with your LLM instance:

```gdscript
llm.add_tool(WeatherTool.new())
llm.add_tool(UserNameTool.new())
```

2. Generate responses that may use tools:

```gdscript
var response = await llm.generate_response("What's the weather like in California, and can you call me by my name?")
print(response)
```

### Creating Custom Tools

1. Create a new script that extends `BaseTool`:

```gdscript
extends BaseTool

class_name MyCustomTool

func _init():
    super._init(
        "my_custom_tool",
        "Description of what my tool does",
        {
            "type": "object",
            "properties": {
                "input_param": {
                    "type": "string",
                    "description": "Description of the input parameter"
                }
            },
            "required": ["input_param"]
        }
    )

func execute(input: Dictionary) -> String:
    # Implement your tool's functionality here
    return "Result of my custom tool"
```

2. Register your custom tool with the LLM:

```gdscript
llm.add_tool(MyCustomTool.new())
```

## API Reference

For detailed API documentation, please refer to the inline comments in the source code, particularly in the following files:

- `llm.gd`
- `llm_provider_api.gd`
- `llm_config.gd`
- `base_tool.gd`

## Configuration

The LLM's behavior can be configured through the `LLMConfig` resource. Key settings include:

- `provider`: The LLM provider to use (e.g., ANTHROPIC)
- `api_key`: Your API key for the chosen provider
- `model`: The specific model to use (e.g., "claude-3-haiku-20240307")
- `temperature`: Controls the randomness of the output (0.0 to 1.0)
- `max_message_history`: The maximum number of messages to keep in the conversation history

## Examples

Check out the `example.gd` and `example.tscn` files in the addon folder for a working example of how to use the Godot LLM Framework.

## Contributing

Contributions to the Godot LLM Framework are welcome! Please follow these steps:

1. Fork the repository
2. Create a new branch for your feature or bug fix
3. Commit your changes with clear, descriptive commit messages
4. Push your branch and submit a pull request

Please ensure your code follows the existing style and includes appropriate documentation.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
