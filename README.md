# GodotRollbackNetcode-Part-1

Repositories:
https://github.com/JonChauG/GodotRollbackNetcode-Part-1
https://github.com/JonChauG/GodotRollbackNetcode-Part-2
https://github.com/JonChauG/GodotRollbackNetcode-Part-3-FINAL

Tutorial Videos:
Part 1: Base Game and Saving Game States - https://www.youtube.com/watch?v=AOct7C422z8
Part 2: Delay-Based Netcode - https://www.youtube.com/watch?v=X55-gfqhQ_E
Part 3 (Final): Rollback Netcode - https://www.youtube.com/watch?v=sg1Q_71cjd8

Part 1 Video Transcript:
INTRO
  For this video, I'll be going over a simple base game and also a way of saving the game state that we’ll be using for rollback netcode later. Here is the final product of this video: we’ll be moving around the player object, the green square, with WASD, and when we press enter, we will rollback, or reset, the current game state to one from the past. So here, the green square will move back to where it was 7 frames ago.

TREE
  Conventionally in a basic game, you may have your key input checks in your player character code because it is more simple, direct, and appropriate. However, to later more easily manage the inputs of the local player and networked players, I am using a basic Node I’ve named InputControl that manages the inputs for all Player objects, which are its children in the tree.

SCENES
  The Player object is a basic KinematicBody and the Wall objects are basic StaticBodies. The only things I've changed from the default are the collision layer and mask bits so that Player objects will pass through other Player objects, but they will stop at Wall objects when moving using Godot’s move_and_collide() function. I've also included a Label here for the Player so that we can view a test value when we implement netcode later.

INPUTCONTROL.GD
  So let us now go over the InputControl script, which is run by the InputControl node and is the core code that runs our game.

  The input delay variable sets how long it takes for a key press input to have an effect shown on screen for the player, and this delay is measured in terms of frames. So when we press WASD to move the player, there’s a delay given by this variable before our player object actually moves. We use input delay here to account for network latency, which is the time it takes for packets to be sent over the network. But because there is no networking right now in our basic game, input delay here doesn’t currently serve any practical function. I’ll go more into detail about the use of input delay when I introduce networking later.

  The rollback variable sets the amount of states we save at a time in our state queue. When we implement rollback netcode later, this also means that this is the furthest back in terms of frames we can rollback to in order to begin resimulation of the game state. For now though in our basic game, we'll just be using our saved game states to revert to the oldest state in the queue when we press Enter, so in this case, the state that was saved seven frames ago relative to the current frame.

  The variable frame_num counts and tracks the current frame number in a 256-frame cycle. The frame number begins at 0 and increments on each frame as the game progresses. At the end of the 255th frame, the frame_num variable will reset to 0. So when we handle inputs, frame_num allows us to easily index and access elements in our input_array here relative to our current frame.

  This canReset boolean is just to make sure a state reset happens only once per press of the Enter key so that the game doesn’t repeatedly reset the state if we hold down Enter.

  I have created two main classes: Inputs and Frame_State. The Inputs class holds the input data for a given frame, and the Frame_State class holds the saved game state for a given frame. We’ll add more to these classes once we introduce networking.

  A game state is saved as a dictionary of dictionaries. The upper-layer game_state dictionary will have InputControl child names as keys. So here, the string LocalPlayer would be a key. And the value for each key is a dictionary that holds the variables needed to save the state of the given child. So the value of the LocalPlayer key is another dictionary that holds variables such as x position, y-position and other relevant values. 

  So in our ready function, we initialize our input array and state queue by filling them up with Inputs and Frame_State instances respectively.

  The physics_process() function is called once per frame by Godot. It only calls the handle_input() function now, but we'll add more to this later when we introduce networking.

  The handle_input() function handles the controlling of player objects based on the registered inputs. So right now, it’s only controlling our single LocalPlayer object, but when we have networking, it will also control the Player objects of networked players.

  I’m gonna go to the bottom here. Throughout the execution of the handle_input() function, the InputControl node will interact with its children using these functions here that just call a respective function in each individual child. So frame_start_all will call frame_start in all children and so on and so forth.

  To better understand what’s happening in these function calls, I’m gonna go over the LocalPlayer script now and then come back to the handle_input() function afterwards.-

LOCALPLAYER.GD
  So, remember that we have set the collision layer and mask bits such that Player characters do not collide and stop at each other when we use Godot’s move_and_collide() function. In order to detect intersections with other Player objects later, I will be using a Rect2 as a collision mask for intersection checks. The counter variable is just the test value that the Player object will show with its Label.
  
  When we call reset_state, we directly set all of the Player object variables according to the given state dictionary. Now, when I wrote this function, I had it in mind that if a child of InputControl does not exist in the state that we are resetting to, we will delete it. This is meant for objects that Players may spawn in during the middle of the game, such as projectiles. So if something like a projectile exists in the current game state, but does not exist in the game state that we are resetting to, we must delete it to correctly produce the game state we want. It’s important to note that if you want to implement something such as projectiles that can have their state reset, they should be direct children of InputControl in the tree according to the way I’ve implemented it.

  In the input_update() function, the Player object calculates its own new state based on the Inputs class instance given by InputControl. So here we apply the key presses recorded by InputControl to the Player object, move and test for collisions with walls, and update our Rect2 collision mask to match the new Player position.

  With the frame_start() function, we execute code that only needs to be run once at the beginning of the state calculation for the Player, and similarly with the frame_end() function, we execute code that only needs to be run once^ the final Player state for the frame is obtained. For now, frame_start(), input_update(), and frame_end() all run once per frame, so I’ll go back to this when we have rollback netcode and input_update can be called multiple times in a frame.

  And when we call get_state(), we just return a dictionary with the values needed to save a state.

INPUTCONTROL.GD
  So, returning back to the handle_input() function of InputControl...

  At the beginning of the frame, we’ll be saving the current game state before we record any inputs.

  Then we will call the frame_start() function for each child.

  We read our keyboard presses here and save them in our array of Inputs class instances to be used in the frame number given by the (current frame number + input delay). So remember that the input delay is set to 5 now. If the current frame number is 20, we won’t see the results of our key presses until frame 25. When we press on frame 21, we won’t see it until frame 26 and so on and so forth.

  Then we take the input we recorded previously 5 frames ago to use now for the current frame because its input delay time is up.

  Here, we will call reset_state() for the Player object if we press Enter to test if our saving of states works. We will reset to the oldest state (so this is the state 7 frames ago from the current frame), which is at the beginning of our state_queue.

  We apply the inputs for the current frame for each child, the only child being the Player object.

  And then we call frame_end for each child.

  Then, we create and add this frame's Frame_State class instance to the state_queue. We're using the pre_game_state we obtained at the beginning of the handle_input() function call because of rollback netcode reasons we'll see later. Basically, if inputs from networked players arrive to correct game states in the past and as a result correct the current game_state, we want to use this pre_game_state as a base to begin resimulation with the arriving inputs. We cannot use a game state recorded at the end of the frame because the inputs have already been applied in the state and cannot be corrected. 

  Then, we remove the oldest Frame_State from front of the queue to keep the queue size equal to the value of our rollback variable at the top of the script.

  And then finally we increment the frame_num.

DEMO
  So, let’s run the game. I’m pressing WASD, and movement’s good. Now let’s press enter, so we revert to the state 7 frames ago. Now sometimes there’s a little movement after pressing Enter even though we’re not pressing WASD. This is from the inputs that were held back by input delay and are now applied on the current frame, causing the player to move immediately after the state rollback. In the next video, we’ll introduce delay-based netcode.
