extends LLMProviderAPI

# NOTE: CONSIDER THIS A WIP, IT IS NOT WORKING YET!

## OpenAIAPI: A class for interacting with the OpenAI API to generate responses using their language models.
##
## This class implements the LLMProviderAPI interface for the OpenAI API,
## allowing generation of responses using OpenAI's models. It provides methods for
## generating responses and fetching available models.
##
## @experimental
## @tutorial: https://platform.openai.com/docs/api-reference

class_name OpenAIAPI

## The base URL for the OpenAI API chat completions endpoint.
const API_URL = "https://api.openai.com/v1/chat/completions"

## Generates a response using the OpenAI API.
##
## This method sends a request to the OpenAI API with the provided parameters
## and returns the generated response.
##
## [param params] A dictionary of parameters for the API call, including:
## - "model": The model to use (default: "gpt-3.5-turbo")
## - "messages": The conversation history
## - "temperature": Controls randomness (default: 0.7)
## - "max_tokens": Maximum number of tokens to generate (default: 150)
## - "top_p": Controls diversity via nucleus sampling (default: 1.0)
## - "frequency_penalty": Decreases the model's likelihood to repeat the same line verbatim (default: 0.0)
## - "presence_penalty": Increases the model's likelihood to talk about new topics (default: 0.0)
## - "tools": Optional list of tools available to the model
## - "tool_choice": Optional, how the model should choose to use tools (default: "auto")
##
## [return] The generated response as a string or an error dictionary.
func generate_response(params: Dictionary) -> Dictionary:
    var headers = [
        "Authorization: Bearer " + api_key,
        "Content-Type: application/json"
    ]

    var body = {
        "model": params.get("model", "gpt-3.5-turbo"),
        "messages": params.get("messages"),
        "temperature": params.get("temperature", 0.7),
        "max_tokens": params.get("max_tokens", 150),
        "top_p": params.get("top_p", 1.0),
        "frequency_penalty": params.get("frequency_penalty", 0.0),
        "presence_penalty": params.get("presence_penalty", 0.0)
    }

    if params.has("tools"):
        body["tools"] = params.get("tools")
        body["tool_choice"] = params.get("tool_choice", "auto")

    var response = await _make_request(API_URL, headers, body)

    var error_message

    if response.has("error"):
        error_message = "OpenAI API error: " + response.error.message
        push_error(error_message)
        return { "error": error_message }
    
    if response.has("choices") and response.choices.size() > 0:
        var message = response.choices[0].message
        if message.has("content"):
            return message.content
        elif message.has("tool_calls"):
            return { "error": "OpenAI tool call initiated but not implemented." }
    
    error_message = "Unexpected response format from OpenAI API"
    push_error(error_message)
    return { "error": error_message }

## Fetches the list of available models from the OpenAI API.
##
## Note: This method currently returns a static list of commonly used models.
## It should be implemented to fetch available models from the OpenAI API dynamically.
##
## @todo Implement API call to fetch available models dynamically.
##
## [return] An array of strings representing the available model names.
func get_available_models() -> Array:
    # This should be implemented to fetch available models from OpenAI API
    # For now, we'll return a static list of commonly used models
    return ["gpt-3.5-turbo", "gpt-4"]