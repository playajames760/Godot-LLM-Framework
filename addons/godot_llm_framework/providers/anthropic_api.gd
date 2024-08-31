extends LLMProviderAPI
## AnthropicAPI: A class for interacting with the Anthropic API to generate responses using their language models.
##
## This class implements the LLMProviderAPI interface for the Anthropic API,
## allowing generation of responses and handling of tool calls using Anthropic's models.
## It provides methods for generating responses, getting available models, and preparing tool data for requests.
##
## @tutorial: https://docs.anthropic.com/claude/reference/getting-started-with-the-api

class_name AnthropicAPI

## The base URL for the Anthropic API.
const API_URL = "https://api.anthropic.com/v1/messages"

## Generates a response using the Anthropic API.
##
## This method sends a request to the Anthropic API with the provided parameters
## and returns the generated response.
##
## [param params] A dictionary of parameters for the API call, including:
## - "model": The model to use (default: "claude-3-haiku-20240307")
## - "max_tokens": Maximum number of tokens to generate (default: 1024)
## - "messages": The conversation history
## - "temperature": Controls randomness (default: 1.0)
## - "top_p": Controls diversity via nucleus sampling (default: 1.0)
## - "top_k": Controls diversity via top-k sampling (default: -1)
## - "system": Optional system message to set context
## - "tools": Optional list of tools available to the model
##
## [return] A dictionary containing the generated response or an error message.
func generate_response(params: Dictionary) -> Dictionary:
	var headers = {
		"x-api-key": api_key,
		"anthropic-version": "2023-06-01",
		"Content-Type": "application/json"
	}

	var body = {
		"model": params.get("model", "claude-3-haiku-20240307"),
		"max_tokens": params.get("max_tokens", 1024),
		"messages": params.get("messages"),
		"temperature": params.get("temperature", 1.0),
		"top_p": params.get("top_p", 1.0),
		"top_k": params.get("top_k", -1),
		"stream": false
	}

	# Adds system prompt if it has been provided
	if params.has("system"):
		body["system"] = params.get("system")
	
	# Adds tools to the body if they are provided
	if params.has("tools"):
		body["tools"] = params.get("tools")

	var response = await _make_request(API_URL, headers, body)
	
	var error_message

	if response.has("error"):
		error_message = "Anthropic API error: " + response.error.message
		push_error(error_message)
		return {"Error": error_message}
	
	if response.has("content"):
		return response
	
	# If we reach this point, there was an unexpected response format
	error_message = "Unexpected response format from Anthropic API"
	push_error(error_message)
	return {"Error": error_message}

## Returns a list of available models for the Anthropic API.
##
## This method provides a static list of known models as there's currently
## no API endpoint to fetch available models dynamically.
##
## [return] An array of strings representing the available model names.
func get_available_models() -> Array:
	return [
		"claude-3-5-sonnet-20240620",
		"claude-3-opus-20240229",
		"claude-3-sonnet-20240229",
		"claude-3-haiku-20240307",
		"claude-2.1",
		"claude-2.0",
		"claude-instant-1.2"
	]

## Extracts response messages from the API response.
##
## [return] An array of extracted response messages.
func extract_response_messages(response: Dictionary) -> Array:
	return [response.Error] if response.has("Error") else response.content

## Checks if this API supports tool use.
##
## [return] [code]true[/code] as Anthropic API supports tool use.
func supports_tool_use() -> bool:
	return true

## Prepares the tools data for the API request.
##
## This method converts the tool objects into a format suitable for
## inclusion in the API request.
##
## [param tools] An array of tool objects to be prepared.
## [return] An array of prepared tool dictionaries.
func prepare_tools_for_request(tools: Array) -> Array:
	var prepared_tools = []
	for tool in tools:
		prepared_tools.append(tool.to_dict())
	return prepared_tools

## Extracts tool calls from the API response.
##
## This method parses the API response to identify and extract any tool calls
## made by the model.
##
## [param response] The response dictionary from the API.
## [return] An array of dictionaries representing the extracted tool calls.
func extract_tool_calls(response: Dictionary) -> Array:
	var tool_calls = []
	for content in response.get("content", []):
		if content.get("type") == "tool_use":
			tool_calls.append({
				"id": content.get("id"),
				"name": content.get("name"),
				"input": content.get("input")
			})
	return tool_calls

## Formats the results of tool executions for inclusion in the next API request.
##
## This method prepares the results of tool executions in a format suitable
## for sending back to the API in subsequent requests.
##
## [param tool_results] An array of dictionaries containing the results of tool executions.
## [return] An array of formatted tool result dictionaries.
func format_tool_results(tool_results: Array) -> Array:
	var array = []
	for result in tool_results:
		array.append({
			"type": "tool_result",
			"tool_use_id": result.get("id"),
			"content": result.get("output")
		})
	return array
