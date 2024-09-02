extends Node

## LLMProviderAPI: An abstract base class for LLM (Language Model) provider APIs.
##
## This class defines the interface for interacting with different LLM providers
## and provides some common functionality for making HTTP requests. It serves as
## a template for implementing specific LLM provider APIs.

class_name LLMProviderAPI

## Enum representing supported LLM providers.
##
## This enum is used to identify different LLM providers that can be used with this API.
enum Provider {
	OPENAI,
	ANTHROPIC
}

## The API key for authenticating with the LLM provider.
var api_key: String

## Sets the API key for the LLM provider.
##
## [param key] The API key to set.
func set_api_key(key: String) -> void:
	api_key = key

## Generates a response from the LLM using the given parameters.
##
## This method should be overridden in derived classes to implement
## provider-specific logic.
##
## [param _params] A dictionary of parameters for the request, including the prompt.
## [return] A dictionary containing the generated response or error information.
func generate_response(_params: Dictionary) -> Dictionary:
	push_error("Method 'generate_response' must be overridden in derived class")
	return {}

## Streams a response from the LLM using the given parameters.
##
## This method should be overridden in derived classes to implement
## provider-specific logic for streaming responses.
##
## [param _params] A dictionary of parameters for the request, including the prompt.
func stream_response(_params: Dictionary) -> void:
	push_error("Method 'stream_response' must be overridden in derived class")

## Retrieves the list of available models from the LLM provider.
##
## This method should be overridden in derived classes to implement
## provider-specific logic for fetching available models.
##
## [return] An array of available model names.
func get_available_models() -> Array:
	push_error("Method 'get_available_models' must be overridden in derived class")
	return []

## Helper method for making HTTP requests.
##
## [param url] The URL to send the request to.
## [param headers] A dictionary of HTTP headers to include in the request.
## [param body] A dictionary representing the request body (will be converted to JSON).
## [return] A dictionary containing the parsed JSON response.
func _make_request(url: String, headers: Dictionary, body: Dictionary) -> Dictionary:
	return await _coroutine_request(url, headers, body)

## Coroutine for making HTTP requests.
##
## This method handles the actual HTTP request process, including adding and
## removing the HTTPRequest node, sending the request, and parsing the response.
##
## [param url] The URL to send the request to.
## [param headers] A dictionary of HTTP headers to include in the request.
## [param body] A dictionary representing the request body (will be converted to JSON).
## [return] A dictionary containing the parsed JSON response.
func _coroutine_request(url: String, headers: Dictionary, body: Dictionary) -> Dictionary:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Wait for the next frame to ensure the node is added to the scene tree
	await get_tree().process_frame
	
	var header_array = PackedStringArray()
	for key in headers:
		header_array.append(key + ": " + headers[key])
	
	var error = http_request.request(url, header_array, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		push_error("An error occurred in the HTTP request.")
		remove_child(http_request)
		http_request.queue_free()
		return {}

	var response = await http_request.request_completed
	remove_child(http_request)
	http_request.queue_free()

	if response[0] != HTTPRequest.RESULT_SUCCESS:
		push_error("Received HTTP response code: " + str(response[1]))
		return {}

	var json = JSON.parse_string(response[3].get_string_from_utf8())
	if json == null:
		push_error("Failed to parse JSON response")
		return {}

	return json

## Helper method for making streaming HTTP requests.
##
## This method sets up a streaming HTTP request and connects it to the
## _on_streaming_request_completed method for processing chunks.
##
## [param url] The URL to send the request to.
## [param headers] A dictionary of HTTP headers to include in the request.
## [param body] A dictionary representing the request body (will be converted to JSON).
# func _make_streaming_request(url: String, headers: Dictionary, body: Dictionary) -> void:
# 	var http_request = HTTPRequest.new()
# 	add_child(http_request)
	
# 	# Wait for the next frame to ensure the node is added to the scene tree
# 	await get_tree().process_frame
	
# 	http_request.connect("request_completed", Callable(self, "_on_streaming_request_completed"))
	
# 	var header_array = PackedStringArray()
# 	for key in headers:
# 		header_array.append(key + ": " + headers[key])
	
# 	body["stream"] = true
# 	var error = http_request.request(url, header_array, HTTPClient.METHOD_POST, JSON.stringify(body))
# 	if error != OK:
# 		push_error("An error occurred in the streaming HTTP request.")
# 		remove_child(http_request)
# 		http_request.queue_free()

## Callback method for processing streaming HTTP responses.
##
## This method parses the streaming response, extracts content chunks,
## and emits the streaming_chunk_received signal for each chunk.
##
## [param result] The result code of the HTTP request.
## [param response_code] The HTTP response code.
## [param _headers] The response headers (unused).
## [param body] The response body.
# func _on_streaming_request_completed(result, response_code, _headers, body):
# 	if result != HTTPRequest.RESULT_SUCCESS:
# 		push_error("Received HTTP response code: " + str(response_code))
# 		return

# 	var response_text = body.get_string_from_utf8()
# 	var lines = response_text.split("\n")
# 	for line in lines:
# 		if line.begins_with("data: "):
# 			var json_str = line.substr(6)  # Remove "data: " prefix
# 			var json = JSON.parse_string(json_str)
# 			if json and json.has("choices") and json.choices.size() > 0:
# 				var chunk = json.choices[0].delta.content
# 				if chunk:
# 					print("streaming_chunk_received", chunk) #TODO from old implementation need to be reimplemented 

# 	# Clean up the HTTPRequest node
# 	var http_request = get_node("HTTPRequest")
# 	if http_request:
# 		remove_child(http_request)
# 		http_request.queue_free()

## Extracts response messages from the API response.
##
## This method should be overridden in derived classes to implement
## provider-specific logic for extracting response messages.
##
## [return] An array of extracted response messages.
func extract_response_messages(_response: Dictionary) -> Array:
	push_error("Method 'extract_response_messages' must be overridden in derived class")
	return []

## Checks if this API supports tool use.
##
## [return] [code]true[/code] if the API supports tool use, [code]false[/code] otherwise.
func supports_tool_use() -> bool:
	return false

## Prepares the tools in the format expected by the specific provider for the API request.
##
## This method should be overridden in derived classes to implement
## provider-specific logic for preparing tools.
##
## [param _tools] An array of BaseTool objects to be prepared.
## [return] An array of prepared tool data in the format expected by the provider.
func prepare_tools_for_request(_tools: Array[BaseTool]) -> Array:
	push_error("Method 'prepare_tools_for_request' must be overridden in derived class")
	return []

## Checks if the response contains any tool calls.
##
## This method should be overridden in derived classes to implement
## provider-specific logic for detecting tool calls in the response.
##
## [param response] The response dictionary from the API.
## [return] [code]true[/code] if the response contains tool calls, [code]false[/code] otherwise.
func has_tool_calls(_response: Dictionary) -> bool:
	push_error("Method 'has_tool_calls' must be overridden in derived class")
	return false

## Extracts tool calls from the API response.
##
## This method should be overridden in derived classes to implement
## provider-specific logic for extracting tool calls from the response.
##
## [param _response] The response dictionary from the API.
## [return] An array of extracted tool call dictionaries, each containing 'name', 'id', and 'input' keys.
func extract_tool_calls(_response: Dictionary) -> Array:
	push_error("Method 'extract_tool_calls' must be overridden in derived class")
	return []

## Formats the results of tool executions in the provider's expected format for inclusion in the next API request.
##
## This method should be overridden in derived classes to implement
## provider-specific logic for formatting tool results.
##
## [param _tool_results]
## An array of dictionaries containing the results from tool executions. Each dictionary in the array has two keys:
## 1. 'id': Identifies the specific tool execution
## 2. 'output': Contains the output of the tool execution
## [return] An array of formatted tool result data in the provider's expected format.
## For error handling, check if result.output.is_error is True.
func format_tool_results(_tool_results: Array) -> Array:
	push_error("Method 'format_tool_results' must be overridden in derived class")
	return []
