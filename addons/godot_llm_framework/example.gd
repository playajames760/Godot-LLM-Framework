extends Node

@onready var llm = %LLM
@onready var rich_text_label = %RichTextLabel

func _ready() -> void:
	if llm.api:
		rich_text_label.append_text("LLM initialized successfully\n")
	else:
		rich_text_label.append_text("LLM was not initialized successfully, check your config")
		return
	await get_tree().create_timer(0.5).timeout
	llm.add_tool(WeatherTool.new())
	rich_text_label.append_text("WeatherTool registered\n")
	await get_tree().create_timer(0.5).timeout
	llm.add_tool(UserNameTool.new())
	rich_text_label.append_text("UserName tool registered\n")
	await get_tree().create_timer(0.5).timeout
	rich_text_label.append_text("Generating response...\n")
	var response = await llm.generate_response("What is the weather like in california, and can you call me by my name.")
	rich_text_label.append_text("Response: " + JSON.stringify(response, "\t"))
