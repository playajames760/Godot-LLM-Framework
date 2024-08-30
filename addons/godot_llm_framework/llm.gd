extends Node

## LLM: A class for handling interactions with Large Language Model (LLMs).
##
## This class provides a unified interface for working with different LLM providers,
## managing configuration, handling responses, and integrating with tools.

class_name LLM

## The current configuration for the LLM, including provider settings and API keys.
@export var config: LLMConfig

## A dictionary to store registered tools.
@export var tools: Dictionary = {}

## An array to store recent chat messages.
@export var message_history: Array = []

## The current LLM provider API instance.
var api: LLMProviderAPI

func _ready() -> void:
	assert(config, "LLM must have a valid config")
	_initialize_api()

## Creates a new LLM instance with the given configuration.
##
## [param p_config] The LLMConfig instance to use for this LLM.
## [return] A new LLM instance with the specified configuration.
static func create(p_config: LLMConfig):
	var llm = LLM.new()
	llm.config = p_config
	return llm

## Initializes the appropriate API based on the current configuration.
func _initialize_api():
	match config.provider:
		LLMProviderAPI.Provider.ANTHROPIC:
			api = AnthropicAPI.new()
		LLMProviderAPI.Provider.OPENAI:
			push_error("OpenAI support has not been implemented yet.")
	
	if api:
		api.set_api_key(config.api_key)
		add_child(api)  # Add the LLMProviderAPI instance as a child of LLM

## Generates a response from the LLM using the given prompt and parameters.
##
## This method handles the main interaction flow with the LLM, including tool use if supported.
##
## [param prompt] The input prompt for the LLM.
## [param params] Additional parameters for the request (optional).
## [return] A dictionary containing the generated response and any additional information.
func generate_response(prompt: String, params: Dictionary = {}) -> Dictionary:
	if not api:
		push_error("API not initialized")
		return {}

	var request_params = config.to_dict().duplicate()
	request_params.merge(params, true)

	# Add user message to log
	append_message_history({"role": "user", "content": prompt})
	
	# Add message_history to the request_params
	request_params["messages"] = message_history
	
	var response

	# Send basic request if no tools are registered or not supported
	if not api.supports_tool_use() || not tools:
		response = await api.generate_response(request_params)
		append_message_history({"role": "assistant", "content": api.extract_response_messages(response)}) # TODO Validate content exists
		return response

	request_params["tools"] = api.prepare_tools_for_request(tools.values()) # TODO This may break providers that dont use the 'tools' identifier to provider tools in a request
	
	response = await api.generate_response(request_params)
	#TODO implement handle error response
	append_message_history({"role": "assistant", "content": api.extract_response_messages(response)})
	
	while response.stop_reason == "tool_use":
		var tool_calls = api.extract_tool_calls(response)

		if not tool_calls.is_empty():
			var tool_results = _execute_tool_calls(tool_calls)
			append_message_history({"role": "user", "content": api.format_tool_results(tool_results)})
			request_params["messages"] = message_history

			response = await api.generate_response(request_params)
			append_message_history({"role": "assistant", "content": api.extract_response_messages(response)})
	
	return response

## Adds a message with content to the messages log, removing old messages if the limit is reached.
##
## [param content] The content to add to the message history array.
func append_message_history(content: Dictionary) -> void:
	message_history.append(content)
	while message_history.size() > config.max_message_history:
		message_history.pop_front()

## Retrieves the list of available models from the current API.
##
## [return] An array of available model names.
func get_available_models() -> Array:
	if not api:
		push_error("API not initialized")
		return []

	return api.get_available_models()

## Sets a new provider and API key, reinitializing the API.
##
## [param provider] The new LLM provider to use.
## [param api_key] The new API key for the provider.
func set_provider(provider: LLMProviderAPI.Provider, api_key: String) -> void:
	# Remove the old API instance if it exists
	if api:
		remove_child(api)
		api.queue_free()
	
	config.provider = provider
	config.api_key = api_key
	_initialize_api()

## Sets the default model for the LLM.
##
## [param model] The new default model to use.
func set_model(model: String) -> void:
	config.model = model

## Updates the current configuration with new values.
##
## [param new_config] A dictionary containing the new configuration values.
func update_config(new_config: Dictionary) -> void:
	var config_dict = config.to_dict()
	config_dict.merge(new_config, true)
	config = LLMConfig.from_dict(config_dict)

## Sets the maximum number of messages to keep in the history.
##
## [param limit] The new maximum number of messages to keep.
func set_max_message_history(limit: int) -> void:
	config.max_messages_log = limit
	while message_history.size() > limit:
		message_history.pop_front()

## Clears all messages from the message history.
func clear_message_history() -> void:
	message_history = []

## Adds a tool to the list of available tools.
##
## [param tool] The BaseTool instance to add.
## @todo Add error if tools aren't supported by the current API.
func add_tool(tool: BaseTool):
	tools[tool.tool_name] = tool

## Removes a tool from the list of available tools.
##
## [param tool_name] The name of the tool to remove.
## @todo Add error if tools aren't supported by the current API.
func remove_tool(tool_name: String):
	tools.erase(tool_name)

## Executes a list of tool calls and returns their results.
##
## This function iterates through the provided tool calls, executes each tool
## if it's available, and collects the results. If a tool is not found, a warning
## is logged.
##
## [param tool_calls] An array of tool call dictionaries, each containing 'name', 'id', and 'input' keys.
## [return] An array of dictionaries containing tool execution results, each with 'id' and 'output' keys.
func _execute_tool_calls(tool_calls: Array) -> Array:
	var results = []
	for p_call in tool_calls:
		if tools.has(p_call.name):
			var tool = tools[p_call.name]
			var output = tool.execute(p_call.input)
			results.append({
				"id": p_call.id,
				"output": output
			})
		else:
			push_warning("Tool not found: " + p_call.name)
	return results

## Logs API interactions for debugging purposes.
##
## [param request] The request dictionary.
## [param response] The response dictionary.
func log_interaction(request: Dictionary, response: Dictionary) -> void:
	print("DEBUG: log_interaction called")
	print("API Interaction - " + LLMProviderAPI.Provider.keys()[config.provider])
	print("Request: ", request)
	print("Response: ", response)
