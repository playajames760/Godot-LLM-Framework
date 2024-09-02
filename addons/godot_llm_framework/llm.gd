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

## A bool to enable printing debug messages to the console.
@export var debug: bool = false

## The current LLM provider API instance.
var api: LLMProviderAPI

func _ready() -> void:
	assert(config, "LLM must have a valid config")
	if debug: print("LLM: _ready() called")
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
	if debug: print("LLM: Initializing API")
	match config.provider:
		LLMProviderAPI.Provider.ANTHROPIC:
			api = AnthropicAPI.new()
			if debug: print("LLM: Anthropic API initialized")
		LLMProviderAPI.Provider.OPENAI:
			push_error("OpenAI support has not been implemented yet.")
			if debug: print("LLM: Error - OpenAI support not implemented")
	
	if api:
		api.set_api_key(config.api_key)
		add_child(api)  # Add the LLMProviderAPI instance as a child of LLM
		if debug: print("LLM: API key set and API added as child")
	else:
		if debug: print("LLM: Failed to initialize API")

## Generates a response from the LLM using the given prompt and parameters.
##
## This method handles the main interaction flow with the LLM, including tool use if supported.
##
## [param prompt] The input prompt for the LLM.
## [param params] Additional parameters for the request (optional).
## [param use_tools] Specify if you want the request to use tools or not. Default's to true (optional).
## [return] A dictionary containing the generated response and any additional information.
func generate_response(prompt: String, params: Dictionary = {}, use_tools: bool = true) -> Dictionary:
	if debug: print("LLM: generate_response() called with prompt: ", prompt)
	if not api:
		push_error("API not initialized")
		if debug: print("LLM: Error - API not initialized")
		return {}

	var request_params = _get_clean_config(config.to_dict())
	request_params.merge(params, true)

	# Add user message to log
	append_message_history({"role": "user", "content": prompt})
	
	# Add message_history to the request_params
	request_params["messages"] = message_history
	
	var response

	# Send basic request if no tools are registered or not supported
	if not api.supports_tool_use() || not tools || not use_tools:
		if debug: print("LLM: Sending basic request (no tools)")
		if debug: print("LLM: Request parameters: ", JSON.stringify(request_params, "\t"))
		response = await api.generate_response(request_params)
		if debug: print("LLM: Response received: ", JSON.stringify(response, "\t"))
		append_message_history({"role": "assistant", "content": api.extract_response_messages(response)}) # TODO Validate content exists
		return response

	if debug: print("LLM: Preparing tools for request")
	request_params["tools"] = api.prepare_tools_for_request(tools.values())
	
	if debug: print("LLM: Sending request with tools")
	if debug: print("LLM: Request parameters: ", JSON.stringify(request_params, "\t"))
	response = await api.generate_response(request_params)
	if debug: print("LLM: Response received: ", JSON.stringify(response, "\t"))
	#TODO implement handle error response
	append_message_history({"role": "assistant", "content": api.extract_response_messages(response)})
	
	var max_loop_limit = 5
	while api.has_tool_calls(response) && max_loop_limit > 0:
		if debug: print("LLM: Processing tool calls, remaining loops: ", max_loop_limit)
		var tool_calls = api.extract_tool_calls(response)

		if not tool_calls.is_empty():
			if debug: print("LLM: Executing tool calls")
			var tool_results = _execute_tool_calls(tool_calls)
			append_message_history({"role": "user", "content": api.format_tool_results(tool_results)})
			request_params["messages"] = message_history

			if debug: print("LLM: Sending follow-up request after tool execution")
			if debug: print("LLM: Request parameters: ", JSON.stringify(request_params, "\t"))
			response = await api.generate_response(request_params)
			if debug: print("LLM: Response received: ", JSON.stringify(response, "\t"))
			append_message_history({"role": "assistant", "content": api.extract_response_messages(response)})
		
		max_loop_limit -= 1
	
	if max_loop_limit <= 0:
		push_warning("Reached max tool loop limit")
		if debug: print("LLM: Warning - Reached max tool loop limit")

	if debug: print("LLM: generate_response() completed")
	return response

## Adds a message with content to the messages log, removing old messages if the limit is reached.
##
## [param content] The content to add to the message history array.
func append_message_history(content: Dictionary) -> void:
	message_history.append(content)
	while message_history.size() > config.max_message_history:
		message_history.pop_front()
	if debug: print("LLM: Message appended to history, current size: ", message_history.size())

## Retrieves the list of available models from the current API.
##
## [return] An array of available model names.
func get_available_models() -> Array:
	if debug: print("LLM: get_available_models() called")
	if not api:
		push_error("API not initialized")
		if debug: print("LLM: Error - API not initialized")
		return []

	var models = api.get_available_models()
	if debug: print("LLM: Available models: ", models)
	return models

## Sets a new provider and API key, reinitializing the API.
##
## [param provider] The new LLM provider to use.
## [param api_key] The new API key for the provider.
func set_provider(provider: LLMProviderAPI.Provider, api_key: String) -> void:
	if debug: print("LLM: set_provider() called with provider: ", LLMProviderAPI.Provider.keys()[provider])
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
	if debug: print("LLM: set_model() called with model: ", model)
	config.model = model

## Updates the current configuration with new values.
##
## [param new_config] A dictionary containing the new configuration values.
func update_config(new_config: Dictionary) -> void:
	if debug: print("LLM: update_config() called with new config: ", new_config)
	var config_dict = config.to_dict()
	config_dict.merge(new_config, true)
	config = LLMConfig.from_dict(config_dict)

func _get_clean_config(config: Dictionary) -> Dictionary:
	var clean_config = config.duplicate()
	clean_config.erase("max_message_history")
	clean_config.erase("provider")
	return clean_config

## Sets the maximum number of messages to keep in the history.
##
## [param limit] The new maximum number of messages to keep.
func set_max_message_history(limit: int) -> void:
	if debug: print("LLM: set_max_message_history() called with limit: ", limit)
	config.max_messages_log = limit
	while message_history.size() > limit:
		message_history.pop_front()

## Clears all messages from the message history.
func clear_message_history() -> void:
	if debug: print("LLM: clear_message_history() called")
	message_history = []

## Adds a tool to the list of available tools.
##
## [param tool] The BaseTool instance to add.
## @todo Add error if tools aren't supported by the current API.
func add_tool(tool: BaseTool):
	if debug: print("LLM: add_tool() called with tool: ", tool.tool_name)
	tools[tool.tool_name] = tool

## Removes a tool from the list of available tools.
##
## [param tool_name] The name of the tool to remove.
## @todo Add error if tools aren't supported by the current API.
func remove_tool(tool_name: String):
	if debug: print("LLM: remove_tool() called with tool_name: ", tool_name)
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
	if debug: print("LLM: _execute_tool_calls() called with ", tool_calls.size(), " tool calls")
	var results = []
	for p_call in tool_calls:
		if tools.has(p_call.name):
			if debug: print("LLM: Executing tool: ", p_call.name)
			if debug: print("LLM: Tool input: ", p_call.input)
			var tool = tools[p_call.name]
			var output = tool.execute(p_call.input)
			if debug: print("LLM: Tool output: ", output)
			results.append({
				"id": p_call.id,
				"output": output
			})
		else:
			push_warning("Tool not found: " + p_call.name)
			if debug: print("LLM: Warning - Tool not found: ", p_call.name)
	if debug: print("LLM: _execute_tool_calls() completed with ", results.size(), " results")
	return results