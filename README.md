# Stripped-Defender-Project
This repo contains the final project for the Digitial Systems Design project with all Intel Quartus & pin files removed to reduce clutter.

## Hardware
This game was written for, and deployed on, a Terasic DE-10 Lite Board.

![terasic-de10-lite-board-layout](https://user-images.githubusercontent.com/72426318/191805279-a3f6c483-69da-4f85-89b1-a38e71548bc4.jpg)]

## Features of Game
- The game passes wave by wave, with enemies increasing in speed and in later waves, begin to shoot back. 
- The ship is controlled with the on-board accelerometer of the DE-10 Lite board. 
- Enemies of different sizes, speeds, and lasers/not are randomly generated with a Linear-Shift Feedback Register.
- Non-enemy objects that must be dodged spawn for waves >3 in addition to alien enemies.

## Design Issues
This class was an introduction to hardware description languages, so some of the important aspects of FPGA programming (specifically timing) were lacking. 
* Timing issues such as lasers passing through enemies without being detected were present in the final version of the project. 
* The background music is extremely simple and not fun to listen to at all, it essentially an alternating frequency that was used in conjunction with a piezo-buzzer.

## Credits **
## Top Level Entity (Defender.vhd)
Written by Blake Martin & Nathan Gardner

## Game Logic (Lives, Enemies, Ship, Lasers, Collision Handling, etc.) 
Written by Blake Martin

## Graphics / Sound Logic (Moving Terrain, Background Stars, Explosion Animation, Laser sound, background music, ROM maps, displays at top of screen)
Written by Nathan Gardner
