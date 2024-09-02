extends Node
## Base class for implementing tools in the LLM system.
##
## This class provides a foundation for creating tools that can be used
## by the LLM system. It includes basic properties and methods that all
## tools should have, such as a name, description, and input schema.

class_name BaseTool

## The name of the tool.
var tool_name: String

## A brief description of what the tool does.
var description: String

## A dictionary describing the expected input format for the tool.
var input_schema: Dictionary

## Constructor for the BaseTool class.
##
## @param _name The name of the tool.
## @param _description A brief description of what the tool does.
## @param _input_schema A dictionary describing the expected input format.
func _init(_name: String, _description: String, _input_schema: Dictionary):
    tool_name = _name
    description = _description
    input_schema = _input_schema

## Execute the tool's functionality.
##
## This method should be overridden by specific tool implementations.
## It performs the main operation of the tool and returns the result.
##
## [param _input] A dictionary containing the input data for the tool.
## Return's a dictionary containing the result of the tool's execution and error status.
## The returned dictionary should have the following structure:
## [codeblock]
## {
##      "output": Variant, # The actual output of the tool
##      "is_error": bool   # True if an error occurred, false otherwise
## }
## [/codeblock]
## This structure allows for easy integration with the error handling system.
##
## @example
## [codeblock]
## func execute(input: Dictionary) -> Dictionary:
##     var result = {}
##     if some_condition:
##         result = {
##             "output": "Tool execution successful",
##             "is_error": false
##         }
##     else:
##         result = {
##             "output": "An error occurred during tool execution",
##             "is_error": true
##         }
##     return result
## [/codeblock]
func execute(_input: Dictionary) -> Dictionary:
    # This method should be overridden by specific tool implementations
    push_error("BaseTool.execute() must be overridden")
    return {
        "output": null,
        "is_error": true
    }

## Convert the tool's properties to a dictionary.
##
## @return A dictionary containing the tool's name, description, and input schema.
func to_dict() -> Dictionary:
    return {
        "name": tool_name,
        "description": description,
        "input_schema": input_schema
    }