# Kart Racer

*Note: A large part of the repository was unfortunately lost, so this is a (very) old backup.*

A simple (to be multiplayer) kart racing game created in Godot containing highly advanced RL bots to race against.

Tracks are generated randomly with many options, such as how often corners should appear and whether the height of the track is allowed to change.  
The bots are trained using PPO using the [godot-rl-agents](https://github.com/edbeeching/godot_rl_agents) library, with some custom tweaks to allow for self-play.  
Gameplay footage of the first iteration of the RL bots can be seen below:

https://github.com/user-attachments/assets/46cd0577-eada-4157-8266-8a9e30b2b696

## Attributions

- Physics Engine: [Godot Jolt](https://github.com/godot-jolt/godot-jolt)  
- Go Kart by Zsky [CC-BY](https://creativecommons.org/licenses/by/3.0/) via [Poly Pizza](https://poly.pizza/m/MkByxZCSMA)
