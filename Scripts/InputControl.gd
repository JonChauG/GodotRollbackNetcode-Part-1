#By Jon Chau
extends Node

#amount of input delay in frames
var input_delay = 5 
#number of frame states to save in order to implement rollback (max amount of frames able to rollback)
var rollback = 7

var input_array = [] #array to hold 256 Inputs
var state_queue = [] #queue for Frame_States of past frames (for rollback)

var frame_num = 0 #ranges between 0-255 per circular input array cycle (cycle is every 256 frames)

var canReset = true #for testing state reset

#---classes---
class Inputs:
	#Indexing [0]: W, [1]: A, [2]: S, [3]: D, [4]: SPACE
	#inputs by local player for a single frame
	var local_input = [false, false, false, false, false] 


class Frame_State:
	var local_input #inputs by local player for a single frame
	var frame #state's frame number according to 256 frame cycle number
	var game_state #holds the values needed for tracking a game's state at a given frame.

	func _init(_local_input : Array, _frame : int, _game_state : Dictionary):
		self.local_input = _local_input #Array of booleans
		self.frame = _frame
		self.game_state = _game_state #Dictionary of dictionaries
		#game_state keys are child names, values are their individual state dictionaries
		#states: Keys are state vars of the children (e.g. x, y), values are the var values 

#---functions---
func _ready():
	#initialize input array
	for _x in range (0, 256):
		input_array.append(Inputs.new()) 
	
	#initialize state queue
	for _x in range (0, rollback):
		#empty local input, frame 0, inital game state
		state_queue.append(Frame_State.new([], 0, get_game_state()))


func _physics_process(_delta):
	handle_input() 


func handle_input(): #get input, run rollback if necessary, call input execution
	var pre_game_state = get_game_state()
	var current_input = null
	var local_input = [false, false, false, false, false]
	
	frame_start_all() #for all children, set their update vars to their current/actual values
	
	#record local inputs
	if Input.is_key_pressed(KEY_W):
		local_input[0] = true
	if Input.is_key_pressed(KEY_A):
		local_input[1] = true
	if Input.is_key_pressed(KEY_S):
		local_input[2] = true
	if Input.is_key_pressed(KEY_D):
		local_input[3] = true
	if Input.is_key_pressed(KEY_SPACE):
		local_input[4] = true

	#testing resetting of state
	if Input.is_key_pressed(KEY_ENTER):
		canReset && reset_state_all(state_queue[0].game_state)
		canReset = false
	else:
		canReset = true

	input_array[(frame_num + input_delay) % 256].local_input = local_input

	current_input = Inputs.new()
	current_input.local_input = input_array[frame_num].local_input.duplicate()
	
	input_update_all(current_input) #update children with current input
	execute_all() #implement all applied updates/inputs to all child objects
	
	#store current frame state into queue
	state_queue.append(Frame_State.new(current_input.local_input, frame_num, pre_game_state))
	
	#remove oldest state from queue
	state_queue.pop_front()

	frame_num = (frame_num + 1)%256 #increment frame_num cycle


func frame_start_all():
	for child in get_children():
		child.frame_start()


func reset_state_all(game_state : Dictionary):
	for child in get_children():
		child.reset_state(game_state)


func input_update_all(input : Inputs):
	for child in get_children():
		child.input_update(input)


func execute_all():
	for child in get_children():
		child.execute()


func get_game_state():
	var state = {}
	for child in get_children():
		state[child.name] = child.get_state()
	return state.duplicate(true) #deep duplicate to copy all nested dictionaries by value
