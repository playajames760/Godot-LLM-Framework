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

var system_prompt: String

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

	# Adds tools to the body if they are provided
	if params.has("tools"):
		body["tools"] = params.get("tools")

	# Adds system prompt if it has been provided
	if params.has("system"):
		body["system"] = params.get("system")
	elif system_prompt:
		body["system"] = system_prompt

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

func extract_response_messages(response: Dictionary) -> Array:
	return [response.Error] if response.has("Error") else response.content

func supports_tool_use() -> bool:
	return true

func prepare_tools_for_request(tools: Array) -> Array:
	var prepared_tools = []
	for tool in tools:
		prepared_tools.append(tool.to_dict())
	return prepared_tools

func has_tool_calls(response: Dictionary) -> bool:
	return response.has("stop_reason") && response.stop_reason == "tool_use"

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

func format_tool_results(tool_results: Array) -> Array:
	var array = []
	for result in tool_results:
		var is_error = false
		if result.output.has("is_error"):
			is_error = result.output.is_error
			result.output.erase("is_error")
		array.append({
			"type": "tool_result",
			"tool_use_id": result.id,
			"content": JSON.stringify(result.output),
			"is_error": is_error
		})
	return array

func supports_system_prompt() -> bool:
	return true

func set_system_prompt(prompt: String) -> void:
	system_prompt = prompt

func get_system_prompt() -> String:
	return system_prompt