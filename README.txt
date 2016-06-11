 ___    ___    ___    _____  _   _  _____  _   _  _____ 
(  _`\ |  _`\ (  _`\ (  _  )( ) ( )(  _  )( ) ( )(_   _)
| (_) )| (_) )| (_(_)| (_) || |/'/'| ( ) || | | |  | |  
|  _ <'| ,  / |  _)_ |  _  || , <  | | | || | | |  | |  
| (_) )| |\ \ | (_( )| | | || |\`\ | (_) || (_) |  | |  
(____/'(_) (_)(____/'(_) (_)(_) (_)(_____)(_____)  (_)  
- Coded in VHDL

AUTHORS: Dallon Glick and Mark Crossen
COURSE: ECEN 320, Winter 2016, Dr. Mike Wirthlin, Brigham Young University

SUMMARY: 
We made a simple game of the classic game breakout; the game can be started with button 2, reset with button 3, and
the paddle is controlled with buttons 1 and 0. LEDs 1 and 0 show your score; LED 3 shows your lives. Reach 30 points to win!

INSTRUCTIONS:
1. In order for the start, win, and game over screens to display properly, the images must first be written to the SRAM.
   This is done through Adept. Open Adept, click the memory tab, select the breakout_images.txt file, and click write.
2. After this, select the breakout_game.bit file using the config tab and program it to the board.

FUTURE WORK: 
1. We possibly could make it so you do not need to load the SRAM using the adept tool; i.e., it would be nice if we wrote
   code that did this when the bit file was first loaded onto the board.
2. We could make more levels.
3. We could improve the physics of the game; i.e., we could make it so the angle of the ball changes based on what direction
   the paddle is moving, etc.
   
PROJECT BUILD OPTIONS:
No special options or build procedures were needed to synthesize the circuit.

PROJECT SIZE: Summarize your project FPGA utilization by including the following:
Total Lines of VHDL code:
Number of slices used: 345 slices out of 4656 7%
Minimum Clock Period: 12.39 ns
I/O: 2 inputs, 17 outputs, 1 inout
Line of Code: 1061 lines