extends Resource

## A resource class for storing and managing LLM (Large Language Model) configuration.
##
## This class provides a convenient way to store, serialize, and deserialize
## LLM configuration settings, including provider, API key, model, and other parameters.

class_name LLMConfig

## The LLM provider (e.g., "anthropic", "openai").
@export var provider: LLMProviderAPI.Provider = LLMProviderAPI.Provider.ANTHROPIC

## The API key for authenticating with the LLM provider.
@export var api_key: String = ""

## The default model to use for LLM requests.
@export var model: String = "claude-3-haiku-20240307"

## The temperature setting for controlling randomness in LLM outputs.
@export var temperature: float = 0.7

## The max number of messages to store in the message history.
@export var max_message_history: int = 20

## A dictionary for any additional paramaters
@export var additional_parameters: Dictionary = {}

## Converts the LLMConfig instance to a dictionary.
##
## This method is useful for serializing the configuration to JSON or other formats.
##
## [return] A dictionary representation of the LLMConfig instance.
func to_dict() -> Dictionary:
    return {
        "provider": LLMProviderAPI.Provider.keys()[provider],
        "api_key": api_key,
        "model": model,
        "temperature": temperature,
        "max_message_history": max_message_history
    }

## Creates an LLMConfig instance from a dictionary.
##
## This static method is useful for deserializing configuration data from JSON or other formats.
##
## [param dict] A dictionary containing LLM configuration data.
## [return] A new LLMConfig instance populated with the data from the input dictionary.
static func from_dict(dict: Dictionary) -> LLMConfig:
    var config = LLMConfig.new()
    config.provider = dict.get("provider", LLMProviderAPI.Provider.ANTHROPIC)
    config.api_key = dict.get("api_key", "")
    config.model = dict.get("model", "claude-3-haiku-20240307")
    config.temperature = dict.get("temperature", 0.7)
    config.max_messages_log = dict.get("max_message_history", 20)
    return config