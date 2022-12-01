------------------------------------------------------------------------------------------------------------------------------------------
-- Project: Defender (DSD Final Project Fall 2021)
-- Authors: Blake Martin & Nathan Gardner
-- Date: 11/30/21
------------------------------------------------------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_arith.conv_std_logic_vector;

-- Custom PKG
LIBRARY work;
USE work.graphicsPackage.ALL;

ENTITY defender IS
	PORT (
		clk : IN STD_LOGIC;  											-- 50 Mhz Clk
		hcount : IN INTEGER; 											-- col
		vcount : IN INTEGER; 											-- row
		key0 : IN STD_LOGIC; 											-- start/ pause
		Key1 : IN STD_LOGIC; 											-- shoot
		shiftMagx, shiftMagy : IN STD_LOGIC_VECTOR(2 DOWNTO 0); 		-- 2-D Accelerometer Angular Magnitude
		x_shiftDir, y_shiftDir : IN STD_LOGIC_VECTOR(1 DOWNTO 0); 		-- 2-D Accelerometer Angle Orientation
		red_out, green_out, blue_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);-- Digital Color Signal to VGA-out
		ledfix : OUT STD_LOGIC_VECTOR(9 DOWNTO 0); 						-- Used for signal probing during project development
		ARDUINO_IO : OUT STD_LOGIC_VECTOR(12 DOWNTO 0)
	);
END ENTITY;
--********************************************************************************************************************
ARCHITECTURE controller OF defender IS

	SIGNAL clkCount : INTEGER RANGE 0 TO 2 := 0;

	SIGNAL soundLaser : STD_LOGIC := '0';

	--Programming Signals:
	SIGNAL pause : STD_LOGIC := '1'; -- this needs to be converted to a finite state machine   ******NOTE**********

	--Clock Signals for processes:
	SIGNAL clk_Count : INTEGER := 0; --initalizes clkCounts in various processes
	SIGNAL clkprescaler : INTEGER := 5000000; --50 MHz / clk_prescaler = desired speed

	--GAME OBJECT SIGNALS:
	SIGNAL waveCount : INTEGER := 0;

	SIGNAL ship_Sig : type_gameObj := init_ship;
	SIGNAL ship_rom : rom_type := ship_rom_const; -- for ROM Mapping to Pixels
	SIGNAL enemyArray : type_gameObjArray(8 DOWNTO 0); -- signal to receive enemy signals and map onto game-object matrix

	-- Objects to map onto Graphics Signals:
	SIGNAL gameObjMatrix : type_gameObjMatrix; -- matrix of gameObjectArrays

	SIGNAL player_controls : controls;
	SIGNAL killEnemy, killEnemySig : STD_LOGIC_VECTOR(8 DOWNTO 0) := (OTHERS => '0');
	SIGNAL killShip, killShipSig : STD_LOGIC := '0';
	SIGNAL killLaser, killLaserSig : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
	SIGNAL killObject : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
	SIGNAL killShootingEnemy, killEnemyLaser : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
	SIGNAL EndGame, Wavereset : STD_LOGIC := '0'; --

	--GRAPHIC SIGNALS:
	SIGNAL scoreboard_Sig : scoreboard_data := init_scoreboard;
	CONSTANT numDrawElements : INTEGER RANGE 0 TO 5 := 5;
	SIGNAL drawElementArrayMatrix : drawElementMatrix; -- top-most data structure for pixel-mapping

	SIGNAL terrain_Sig : terrain_data := init_terrain;

	-------------- EXPLOSION SIGNALS --------------------------------
	SIGNAL inExplosion : BOOLEAN := false;

	SIGNAL explosion_rom_addr, explosion_rom_col : INTEGER;
	SIGNAL explosion_rom_data : STD_LOGIC_VECTOR (0 TO 24);
	SIGNAL explosion_rom_bit : STD_LOGIC;

	SIGNAL explosion_rom_data_15 : STD_LOGIC_VECTOR (0 TO 14);
	SIGNAL explosion_rom_data_25 : STD_LOGIC_VECTOR (0 TO 24);
	SIGNAL explosion_rom_data_30 : STD_LOGIC_VECTOR (0 TO 29);

	SIGNAL explosionOnCount : INTEGER := 0;
	SIGNAL explosionData : type_explosion := init_explosion;
	-----------------------------------------------------------------
	TYPE intArray IS ARRAY(NATURAL RANGE <>) OF INTEGER;
	---------------- Object data ------------------------------------
	SIGNAL inObj : BOOLEAN := false;

	SIGNAL obj_rom_addr, obj_rom_col : INTEGER;
	SIGNAL obj_rom_bit : STD_LOGIC;
	-----------------------------------------------------------------
	SIGNAL sky_Sig : sky_data := init_sky;
BEGIN

	-- This entity maps the score to ROM
	scoreboard : ENTITY work.scoreboard
		PORT MAP(
			score => gameObjMatrix(0, 0).points,
			lives => gameObjMatrix(0, 0).lives,
			clk => clk,
			hcount => Hcount,
			vcount => Vcount,
			scoreboard_out => scoreboard_Sig,
			pause => pause,
			waveCount => waveCount
		);
	-----------------------------------------*** Added by Blake--------------
	-- This entity receives user-input and maps it onto a data structure labeled as player_controls
	PlayerControls : ENTITY work.shipController PORT MAP(clk, ShiftMagx, shiftMagy, x_shiftDir, y_shiftDir, key1, player_controls);

	-----------------------------------------*** Added by Blake--------------
	--This entity receives the player controls and game dynamics signals and outputs the ship's dynamics data for pixel-mapping
	playerShip : ENTITY work.ship
		PORT MAP(
			-- inputs:
			pause => pause, 					-- output of pause FSM
			clk => clk, 						-- 50 MHz clk
			killShip => killShipSig, 			-- kill ship signal
			playercontrols => player_controls,  --up, down, left, right, shoot
			hcount => hcount,
			vcount => vcount,
			points => gameObjMatrix(0, 0).points,
			--Outputs:
			EndGame => endGame,
			position => gameObjMatrix(0, 0).position,
			velocity => gameObjMatrix(0, 0).velocity,
			objHeight => gameObjMatrix(0, 0).objHeight,
			ObjWidth => gameObjMatrix(0, 0).objWidth,
			elementOn => gameObjMatrix(0, 0).element_on,
			lives => gameObjMatrix(0, 0).lives,
			ledFix => ledFix(0)
		);

	-----------------------------------------*** Added by Blake--------------
	-- This entity receives game dynamics signals and outputs the enemys' dynamics data for pixel-mapping
	enemyAnim : ENTITY work.enemies
		PORT MAP(
			-- inputs:
			clk => clk,
			pause => pause,
			EndGame => EndGame,
			killEnemy => killEnemySig,
			hcount => hcount,
			vcount => vcount,
			Wavereset => Wavereset,
			--Outputs:
			ledfix => ledFix(9 DOWNTO 1),
			small1Pt => gameObjMatrix(0, 2).points, small2Pt => gameObjMatrix(1, 2).points, small3Pt => gameObjMatrix(2, 2).points, Med1Pt => gameObjMatrix(3, 2).points, Med2Pt => gameObjMatrix(4, 2).points, Med3Pt => gameObjMatrix(5, 2).points, Big1Pt => gameObjMatrix(6, 2).points, Big2Pt => gameObjMatrix(7, 2).points, Big3Pt => gameObjMatrix(8, 2).points,
			small1Pos => gameObjMatrix(0, 2).position, small2Pos => gameObjMatrix(1, 2).position, small3Pos => gameObjMatrix(2, 2).position, med1Pos => gameObjMatrix(3, 2).position, med2Pos => gameObjMatrix(4, 2).position, med3Pos => gameObjMatrix(5, 2).position, big1Pos => gameObjMatrix(6, 2).position, big2Pos => gameObjMatrix(7, 2).position, big3Pos => gameObjMatrix(8, 2).position,
			small1Vel => gameObjMatrix(0, 2).velocity, small2Vel => gameObjMatrix(1, 2).velocity, small3Vel => gameObjMatrix(2, 2).velocity, Med1Vel => gameObjMatrix(3, 2).velocity, Med2Vel => gameObjMatrix(4, 2).velocity, Med3Vel => gameObjMatrix(5, 2).velocity, Big1Vel => gameObjMatrix(6, 2).velocity, Big2Vel => gameObjMatrix(7, 2).velocity, Big3Vel => gameObjMatrix(8, 2).velocity,
			small1On => gameObjMatrix(0, 2).element_on, small2On => gameObjMatrix(1, 2).element_on, Small3On => gameObjMatrix(2, 2).element_on, Med1On => gameObjMatrix(3, 2).element_on, Med2On => gameObjMatrix(4, 2).element_on, Med3On => gameObjMatrix(5, 2).element_on, Big1On => gameObjMatrix(6, 2).element_on, Big2On => gameObjMatrix(7, 2).element_on, Big3On => gameObjMatrix(8, 2).element_on,
			small1Width => gameObjMatrix(0, 2).objWidth, small2Width => gameObjMatrix(1, 2).objWidth, small3Width => gameObjMatrix(2, 2).objWidth, Med1Width => gameObjMatrix(3, 2).objWidth, Med2Width => gameObjMatrix(4, 2).objWidth, Med3Width => gameObjMatrix(5, 2).objWidth, Big1Width => gameObjMatrix(6, 2).objWidth, big2Width => gameObjMatrix(7, 2).objWidth, big3Width => gameObjMatrix(8, 2).objWidth,
			small1Height => gameObjMatrix(0, 2).objHeight, small2Height => gameObjMatrix(1, 2).objHeight, small3Height => gameObjMatrix(2, 2).objHeight, Med1Height => gameObjMatrix(3, 2).objHeight, Med2Height => gameObjMatrix(4, 2).objHeight, Med3Height => gameObjMatrix(5, 2).objHeight, big1Height => gameObjMatrix(6, 2).objHeight, big2Height => gameObjMatrix(7, 2).objHeight, big3Height => gameObjMatrix(8, 2).objHeight,
			waveCountOut => waveCount
		);
	-----------------------------------------*** Added by Blake--------------
	shootingEnemiesEntity : ENTITY work.shootingEnemies
		PORT MAP(
			-- inputs:
			clk => clk,
			pause => pause,
			EndGame => EndGame,
			ship => gameObjMatrix(0, 0),
			waveCount => waveCount,
			killShootingEnemy => killShootingEnemy,
			killEnemyLaser => killEnemyLaser,
			waveResetIn => Wavereset,
			hcount => hcount,
			vcount => vcount,
			shootingEnemyOut1 => gameObjMatrix(0, 4),
			shootingEnemyOut2 => gameObjMatrix(1, 4),
			shootingEnemyOut3 => gameObjMatrix(2, 4),
			EnemyLaserOut1 => gameObjMatrix(0, 5),
			EnemyLaserOut2 => gameObjMatrix(1, 5),
			EnemyLaserOut3 => gameObjMatrix(2, 5),
			ledfix(0) => ledfix(0),
			ledfix(1) => ledfix(1),
			ledfix(2) => ledfix(2)
		);

	-----------------------------------------*** Added by Blake--------------
	-- This entity receives game dynamics signals and outputs the enemys' dynamics data for pixel-mapping
	objectAnim : ENTITY work.objects
		PORT MAP(
			clk => clk,
			pause => pause,
			EndGame => EndGame,
			hcount => hcount,
			vcount => vcount,
			killObject => killObject,
			M1Pt => gameObjMatrix(0, 3).points,
			M2Pt => gameObjMatrix(1, 3).points,
			M3Pt => gameObjMatrix(2, 3).points,
			M4Pt => gameObjMatrix(3, 3).points,
			M5Pt => gameObjMatrix(4, 3).points,
			M1Pos => gameObjMatrix(0, 3).position,
			M2Pos => gameObjMatrix(1, 3).position,
			M3Pos => gameObjMatrix(2, 3).position,
			M4Pos => gameObjMatrix(3, 3).position,
			M5Pos => gameObjMatrix(4, 3).position,
			M1Vel => gameObjMatrix(0, 3).velocity,
			M2Vel => gameObjMatrix(1, 3).velocity,
			M3Vel => gameObjMatrix(2, 3).velocity,
			M4Vel => gameObjMatrix(3, 3).velocity,
			M5Vel => gameObjMatrix(4, 3).velocity,
			M1On => gameObjMatrix(0, 3).element_on,
			M2On => gameObjMatrix(1, 3).element_on,
			M3On => gameObjMatrix(2, 3).element_on,
			M4On => gameObjMatrix(3, 3).element_on,
			M5On => gameObjMatrix(4, 3).element_on,
			M1Width => gameObjMatrix(0, 3).ObjWidth,
			M2Width => gameObjMatrix(1, 3).ObjWidth,
			M3Width => gameObjMatrix(2, 3).ObjWidth,
			M4Width => gameObjMatrix(3, 3).ObjWidth,
			M5Width => gameObjMatrix(4, 3).ObjWidth,
			M1Height => gameObjMatrix(0, 3).objHeight,
			M2Height => gameObjMatrix(1, 3).objHeight,
			M3Height => gameObjMatrix(2, 3).objHeight,
			M4Height => gameObjMatrix(3, 3).objHeight,
			M5Height => gameObjMatrix(4, 3).objHeight
		);
	----------------------------------------------------------------------------------------------------

	
	terrain : ENTITY work.terrain
		PORT MAP(
			clk => clk,
			hcount => HCount,
			vcount => VCount,
			pause => pause,
			terrainDataOut => terrain_Sig
		);
	
	sound : ENTITY work.sound
		PORT MAP(
			ARDUINO_IO => ARDUINO_IO,
			MAX10_CLK1_50 => clk,
			pause => pause,
			shootSound => soundLaser
		);
	
	checkShipCollisions : PROCESS (clk, endGame)
		VARIABLE setkillShip : STD_LOGIC := '0';
		VARIABLE setkillLaser, setKillObject : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
		VARIABLE setkillEnemy : STD_LOGIC_VECTOR(8 DOWNTO 0) := (OTHERS => '0');
		VARIABLE clkC : INTEGER := clk_count;
		VARIABLE slow : INTEGER := 0;
		VARIABLE ptsToGive : INTEGER := 0;
		VARIABLE setKillShootingEnemy, setKillEnemyLaser : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0'); -- NEW*****
		VARIABLE m : INTEGER := 0;
		VARIABLE holdMovingClk : intArray(8 DOWNTO 0) := (OTHERS => 0);
		VARIABLE holdShootingClk : intArray(2 DOWNTO 0) := (OTHERS => 0);
		VARIABLE givePointsClk : INTEGER := 0;
	BEGIN
		IF (EndGame = '1') THEN
			gameObjMatrix(0, 0).points <= 0;
			killLaserSig <= (OTHERS => '0');
			killEnemySig <= (OTHERS => '0');
			killShipSig <= '0';
			killEnemyLaser <= (OTHERS => '0');
			killShootingEnemy <= (OTHERS => '0');
			killObject <= (OTHERS => '0');
			holdMovingClk := (OTHERS => 0);
			holdShootingClk := (OTHERS => 0);
		ELSE
			IF (rising_edge(clk)) THEN
				killLaserSig <= setKillLaser;
				killEnemySig <= setKillEnemy;
				killShipSig <= setKillShip;
				killObject <= setKillObject;
				killShootingEnemy <= setKillShootingEnemy;
				killEnemyLaser <= setKillEnemyLaser;
				setkillLaser := (OTHERS => '0');
				setKillObject := (OTHERS => '0');
				setKillEnemyLaser := (OTHERS => '0');
				setkillShip := '0';
				FOR j IN 0 TO 8 LOOP
					IF (drawElementArrayMatrix(0, 0).pixelOn AND drawElementArrayMatrix(j, 2).pixelOn) THEN
						setkillShip := '1';
						setKillEnemy(j) := '1';
					END IF;
					IF (gameObjMatrix(j, 2).position.x + gameObjMatrix(j, 2).objWidth < 0) THEN
						setKillEnemy(j) := '1';
					END IF;
					FOR i IN 0 TO 4 LOOP
						IF (i < 2) THEN
							m := i;
						ELSE
							m := 2;
						END IF;
						IF (drawElementArrayMatrix(m, 5).pixelOn AND drawElementArrayMatrix(0, 0).pixelOn) THEN
							setkillEnemyLaser(m) := '1';
							setKillShip := '1';
						END IF;

						IF (drawElementArrayMatrix(0, 0).pixelOn AND drawElementArrayMatrix(i, 3).pixelOn) THEN
							setkillShip := '1';
							setKillObject(i) := '1';
						END IF;
						IF (gameObjMatrix(i, 1).position.x > 640) THEN
							setKillLaser(i) := '1';
						END IF;

						IF (drawElementArrayMatrix(i, 1).pixelOn AND drawElementArrayMatrix(j, 2).pixelOn) THEN
							setKillLaser(i) := '1';
							setKillEnemy(j) := '1';
							ptsToGive := gameObjMatrix(j, 2).points;
						END IF;

						IF (drawElementArrayMatrix(i, 1).pixelOn AND drawElementArrayMatrix(0, 4).pixelOn) THEN
							setkillLaser(i) := '1';
							setKillShootingEnemy(0) := '1';
							ptsToGive := gameObjMatrix(0, 4).points;
						ELSIF (drawElementArrayMatrix(i, 1).pixelOn AND drawElementArrayMatrix(1, 4).pixelOn) THEN
							setkillLaser(i) := '1';
							setKillShootingEnemy(1) := '1';
							ptsToGive := gameObjMatrix(1, 4).points;
						ELSIF (drawElementArrayMatrix(i, 1).pixelOn AND drawElementArrayMatrix(2, 4).pixelOn) THEN
							setkillLaser(i) := '1';
							setKillShootingEnemy(2) := '1';
							ptsToGive := gameObjMatrix(2, 4).points;
						END IF;
					END LOOP;
				END LOOP;
				IF (setkillEnemy(0) = '1') THEN
					holdMovingClk(0) := holdMovingClk(0) + 1;
					IF (holdMovingClk(0) >= clkprescaler) THEN
						holdMovingClk(0) := 0;
						setkillEnemy(0) := '0';
					END IF;
				END IF;
				IF (setkillEnemy(1) = '1') THEN
					holdMovingClk(1) := holdMovingClk(1) + 1;
					IF (holdMovingClk(1) >= clkprescaler) THEN
						holdMovingClk(1) := 0;
						setkillEnemy(1) := '0';
					END IF;
				END IF;
				IF (setkillEnemy(2) = '1') THEN
					holdMovingClk(2) := holdMovingClk(2) + 1;
					IF (holdMovingClk(2) >= clkprescaler) THEN
						holdMovingClk(2) := 0;
						setkillEnemy(2) := '0';
					END IF;
				END IF;
				IF (setkillEnemy(3) = '1') THEN
					holdMovingClk(3) := holdMovingClk(3) + 1;
					IF (holdMovingClk(3) >= clkprescaler) THEN
						holdMovingClk(3) := 0;
						setkillEnemy(3) := '0';
					END IF;
				END IF;
				IF (setkillEnemy(4) = '1') THEN
					holdMovingClk(4) := holdMovingClk(4) + 1;
					IF (holdMovingClk(4) >= clkprescaler) THEN
						holdMovingClk(4) := 0;
						setkillEnemy(4) := '0';
					END IF;
				END IF;
				IF (setkillEnemy(5) = '1') THEN
					holdMovingClk(5) := holdMovingClk(5) + 1;
					IF (holdMovingClk(5) >= clkprescaler) THEN
						holdMovingClk(5) := 0;
						setkillEnemy(5) := '0';
					END IF;
				END IF;
				IF (setkillEnemy(6) = '1') THEN
					holdMovingClk(6) := holdMovingClk(6) + 1;
					IF (holdMovingClk(6) >= clkprescaler) THEN
						holdMovingClk(6) := 0;
						setkillEnemy(6) := '0';
					END IF;
				END IF;
				IF (setkillEnemy(7) = '1') THEN
					holdMovingClk(7) := holdMovingClk(7) + 1;
					IF (holdMovingClk(7) >= clkprescaler) THEN
						holdMovingClk(7) := 0;
						setkillEnemy(7) := '0';
					END IF;
				END IF;
				IF (setkillEnemy(8) = '1') THEN
					holdMovingClk(8) := holdMovingClk(8) + 1;
					IF (holdMovingClk(8) >= clkprescaler) THEN
						holdMovingClk(8) := 0;
						setkillEnemy(8) := '0';
					END IF;
				END IF;
				IF (setKillShootingEnemy(0) = '1') THEN
					holdShootingClk(0) := holdShootingClk(0) + 1;
					IF (holdShootingClk(0) >= clkprescaler) THEN
						holdShootingClk(0) := 0;
						setKillShootingEnemy(0) := '0';
					END IF;
				END IF;
				IF (setKillShootingEnemy(1) = '1') THEN
					holdShootingClk(1) := holdShootingClk(1) + 1;
					IF (holdShootingClk(1) >= clkprescaler) THEN
						holdShootingClk(1) := 0;
						setKillShootingEnemy(1) := '0';
					END IF;
				END IF;
				IF (setKillShootingEnemy(2) = '1') THEN
					holdShootingClk(2) := holdShootingClk(1) + 1;
					IF (holdShootingClk(2) >= clkprescaler) THEN
						holdShootingClk(2) := 0;
						setKillShootingEnemy(2) := '0';
					END IF;
				END IF;

				IF (ptsToGive > 0) THEN
					givePointsClk := givePointsClk + 1;
					IF (givePointsClk >= clkprescaler) THEN
						givePointsClk := 0;
						gameObjMatrix(0, 0).points <= gameObjMatrix(0, 0).points + ptsToGive;
						ptsToGive := 0;
					END IF;
				END IF;

				IF (gameObjMatrix(0, 0).points >= 500 AND gameObjMatrix(0, 0).lives < 3) THEN
					gameObjMatrix(0, 0).points <= gameObjMatrix(0, 0).points - 500;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	-----------------------------------------*** Added by Blake--------------
	Lasers : ENTITY work.laser
		PORT MAP(
			pause => pause,
			clk => clk,
			killLaser => killLaserSig,
			playerControls => player_controls,
			hcount => hcount,
			vcount => vcount,
			ship => gameObjMatrix(0, 0), --in
			laser1out => gameObjMatrix(0, 1),
			laser2out => gameObjMatrix(1, 1),
			laser3out => gameObjMatrix(2, 1),
			laser4out => gameObjMatrix(3, 1),
			laser5out => gameObjMatrix(4, 1)
		);

	drawShip : PROCESS (hcount, vcount)
	BEGIN
		ship_rom_addr <= vCount - gameObjMatrix(0, 0).position.y;
		ship_rom_col <= hCount - gameObjMatrix(0, 0).position.x;
		-- getting the data and the bit from the rom
		ship_rom_data <= ship_rom(ship_rom_addr);
		ship_rom_bit <= ship_rom_data(ship_rom_col);
		IF (hCount >= gameObjMatrix(0, 0).position.x AND hCount <= gameObjMatrix(0, 0).position.x + gameObjMatrix(0, 0).objwidth - 1 AND vcount >= gameObjMatrix(0, 0).position.y AND vcount <= gameObjMatrix(0, 0).position.y + gameObjMatrix(0, 0).objheight - 1) THEN
			-- Calculating the addr and col of the ROM for the ship
			sq_ship_on <= '1';
		ELSE
			sq_ship_on <= '0';
		END IF;

		IF ((sq_ship_on = '1') AND (ship_rom_bit = '1')) THEN
			drawElementArrayMatrix(0, 0).pixelOn <= true;
		ELSE
			drawElementArrayMatrix(0, 0).pixelOn <= false;
		END IF;
	END PROCESS;


	drawlasers : PROCESS (hcount, vcount)
	BEGIN
		FOR z IN 0 TO 4 LOOP
			IF (hCount >= gameObjMatrix(z, 1).position.x AND hCount <= gameObjMatrix(z, 1).position.x + gameObjMatrix(z, 1).objwidth - 1 AND vcount >= gameObjMatrix(z, 1).position.y AND vcount <= gameObjMatrix(z, 1).position.y + gameObjMatrix(z, 1).objheight - 1) THEN
				IF (gameobjMatrix(z, 1).element_on) THEN
					DrawElementArrayMatrix(z, 1).pixelOn <= true;
				ELSE
					DrawElementArrayMatrix(z, 1).pixelOn <= false;
				END IF;
			ELSE
				DrawElementArrayMatrix(z, 1).pixelOn <= false;
			END IF;
		END LOOP;
	END PROCESS;


	drawShootingEnemies : PROCESS (hcount, vcount) -- ADD ROMS TO THIS PROCESS
		VARIABLE shootalien_rom_bit : INTEGER;
		VARIABLE shootalien_rom_addr, shootalien_rom_col : INTEGER;
	BEGIN
		FOR f2 IN 0 TO 8 LOOP
			IF (hCount >= gameObjMatrix(f2, 4).position.x AND hCount <= gameObjMatrix(f2, 4).position.x + gameObjMatrix(f2, 4).objwidth - 1 AND vcount >= gameObjMatrix(f2, 4).position.y AND vcount <= gameObjMatrix(f2, 4).position.y + gameObjMatrix(f2, 4).objheight - 1) THEN
				-- Calculating the addr and col of the ROM for the ship
				shootalien_rom_addr := vCount - gameObjMatrix(f2, 4).position.y;
				shootalien_rom_col := hCount - gameObjMatrix(f2, 4).position.x;

				IF (gameObjMatrix(f2, 4).objwidth = 15) THEN
					-- getting the data and the bit from the rom
					shootalien_rom_bit := specialEnemy15(shootalien_rom_addr, shootalien_rom_col);
				ELSIF (gameObjMatrix(f2, 4).objwidth = 25) THEN
					-- getting the data and the bit from the rom
					shootalien_rom_bit := specialEnemy25(shootalien_rom_addr, shootalien_rom_col);
				ELSIF (gameObjMatrix(f2, 4).objwidth = 30) THEN
					-- getting the data and the bit from the rom
					shootalien_rom_bit := specialEnemy30(shootalien_rom_addr, shootalien_rom_col);
				END IF;
				IF ((gameobjMatrix(f2, 4).element_on) AND (shootalien_rom_bit = 1)) THEN
					DrawElementArrayMatrix(f2, 4).pixelOn <= true;
					DrawElementArrayMatrix(f2, 4).rgb <= "111111111111";
				ELSIF ((gameobjMatrix(f2, 4).element_on) AND (shootalien_rom_bit = 2)) THEN
					DrawElementArrayMatrix(f2, 4).pixelOn <= true;
					DrawElementArrayMatrix(f2, 4).rgb <= "111100000000";
				ELSE
					DrawElementArrayMatrix(f2, 4).pixelOn <= false;
					DrawElementArrayMatrix(f2, 4).rgb <= "000000000000";
				END IF;
			ELSE
				DrawElementArrayMatrix(f2, 4).pixelOn <= false;
			END IF;
		END LOOP;
	END PROCESS;


	drawEnemylasers : PROCESS (hcount, vcount)
	BEGIN
		FOR z2 IN 0 TO 2 LOOP
			IF (hCount >= gameObjMatrix(z2, 5).position.x AND hCount <= gameObjMatrix(z2, 5).position.x + gameObjMatrix(z2, 5).objwidth - 1 AND vcount >= gameObjMatrix(z2, 5).position.y AND vcount <= gameObjMatrix(z2, 5).position.y + gameObjMatrix(z2, 5).objheight - 1) THEN
				IF (gameobjMatrix(z2, 5).element_on) THEN
					DrawElementArrayMatrix(z2, 5).pixelOn <= true;
				ELSE
					DrawElementArrayMatrix(z2, 5).pixelOn <= false;
				END IF;
			ELSE
				DrawElementArrayMatrix(z2, 5).pixelOn <= false;
			END IF;
		END LOOP;
	END PROCESS;

	drawObjects : PROCESS (hcount, vcount)
		VARIABLE obj_rom_data : STD_LOGIC_VECTOR (0 TO 24) := (OTHERS => '0');
	BEGIN
		FOR z IN 0 TO 4 LOOP
			IF (hCount >= gameObjMatrix(z, 3).position.x AND hCount <= gameObjMatrix(z, 3).position.x + gameObjMatrix(z, 3).objwidth - 1 AND vcount >= gameObjMatrix(z, 3).position.y AND vcount <= gameObjMatrix(z, 3).position.y + gameObjMatrix(z, 3).objheight - 1) THEN
				obj_rom_addr <= vCount - gameObjMatrix(z, 3).position.y;
				obj_rom_col <= hCount - gameObjMatrix(z, 3).position.x;
				-- getting the data and the bit from the rom
				IF ((z = 0) OR (z = 1)) THEN
					obj_rom_data := met_object_rom_const(obj_rom_addr);
				ELSIF (z = 2) THEN
					obj_rom_data := ufo_object_rom_const(obj_rom_addr);
				ELSIF ((z = 3) OR (z = 4)) THEN
					obj_rom_data := sat_object_rom_const(obj_rom_addr);
				END IF;
				obj_rom_bit <= obj_rom_data(obj_rom_col);

				-- READ ROM DATA
				IF (gameobjMatrix(z, 3).element_on AND (obj_rom_bit = '1')) THEN
					DrawElementArrayMatrix(z, 3).pixelOn <= true;
				ELSE
					DrawElementArrayMatrix(z, 3).pixelOn <= false;
				END IF;
			ELSE
				DrawElementArrayMatrix(z, 3).pixelOn <= false;
			END IF;
		END LOOP;
	END PROCESS;

	drawEnemies : PROCESS (hcount, vcount)
	BEGIN
		FOR f IN 0 TO 8 LOOP
			IF (hCount >= gameObjMatrix(f, 2).position.x AND hCount <= gameObjMatrix(f, 2).position.x + gameObjMatrix(f, 2).objwidth - 1 AND vcount >= gameObjMatrix(f, 2).position.y AND vcount <= gameObjMatrix(f, 2).position.y + gameObjMatrix(f, 2).objheight - 1) THEN
				-- Calculating the addr and col of the ROM for the ship
				alien_rom_addr <= vCount - gameObjMatrix(f, 2).position.y;
				alien_rom_col <= hCount - gameObjMatrix(f, 2).position.x;

				IF (gameObjMatrix(f, 2).objwidth = 15) THEN
					-- getting the data and the bit from the rom
					alien_rom_data_15 <= small_alien_rom_const(alien_rom_addr);
					alien_rom_bit <= alien_rom_data_15(alien_rom_col);
				ELSIF (gameObjMatrix(f, 2).objwidth = 25) THEN
					-- getting the data and the bit from the rom
					alien_rom_data_25 <= medium_alien_rom_const(alien_rom_addr);
					alien_rom_bit <= alien_rom_data_25(alien_rom_col);
				ELSIF (gameObjMatrix(f, 2).objwidth = 30) THEN
					-- getting the data and the bit from the rom
					alien_rom_data_30 <= large_alien_rom_const(alien_rom_addr);
					alien_rom_bit <= alien_rom_data_30(alien_rom_col);
				END IF;
				IF (gameobjMatrix(f, 2).element_on AND (alien_rom_bit = '1')) THEN
					DrawElementArrayMatrix(f, 2).pixelOn <= true;
				ELSE
					DrawElementArrayMatrix(f, 2).pixelOn <= false;
				END IF;
			ELSE
				DrawElementArrayMatrix(f, 2).pixelOn <= false;
			END IF;
		END LOOP;
	END PROCESS;

	--DRAW THE STARS
	drawSky : PROCESS (hcount, vcount)
	BEGIN

		IF ((hcount * vcount MOD 37 = 0) AND (hcount * vcount MOD 41 = 0) AND (hcount * vcount MOD 2 = 0) AND (vcount < mapEdgeBottom AND vcount > mapEdgeTop) AND (hcount > 2 AND hcount < 638)) THEN -- 409
			sky_Sig.pixelOn <= true;
		ELSE
			sky_Sig.pixelOn <= false;
		END IF;
	END PROCESS;



	drawFrame : PROCESS (hcount, vcount)
		VARIABLE tempGameMatrix : type_gameObjMatrix := gameObjMatrix;
		VARIABLE tempDrawMatrix : drawElementMatrix := drawElementArrayMatrix;
		VARIABLE set : BOOLEAN := false;
		VARIABLE red_outVar, green_outVar, blue_outVar : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
	BEGIN
		red_outVar := (OTHERS => '0');
		green_outVar := (OTHERS => '0');
		blue_outVar := (OTHERS => '0');
		FOR w IN 0 TO 3 LOOP
			IF (w < 3) THEN
				FOR x IN 0 TO 4 * W LOOP
					tempdrawMatrix(x, w) := drawElementArrayMatrix(x, w);
					IF (tempDrawMatrix(x, w).pixelOn) THEN
						IF (NOT Set) THEN
							red_out <= tempDrawMatrix(x, w).rgb(11 DOWNTO 8);
							green_out <= tempDrawMatrix(x, w).rgb(7 DOWNTO 4);
							blue_out <= tempDrawMatrix(x, w).rgb(3 DOWNTO 0);
							set := true;
						END IF;
					END IF;
				END LOOP;
			ELSE
				FOR y IN 0 TO 4 LOOP
					tempdrawMatrix(y, w) := drawElementArrayMatrix(y, w);
					IF (tempDrawMatrix(y, w).pixelOn) THEN
						IF (NOT Set) THEN
							red_out <= tempDrawMatrix(y, w).rgb(11 DOWNTO 8);
							green_out <= tempDrawMatrix(y, w).rgb(7 DOWNTO 4);
							blue_out <= tempDrawMatrix(y, w).rgb(3 DOWNTO 0);
							set := true;
						END IF;
					END IF;
				END LOOP;
			END IF;
		END LOOP;

		FOR R IN 4 TO 5 LOOP
			FOR S IN 0 TO 2 LOOP
				tempdrawMatrix(S, R) := drawElementArrayMatrix(S, R);
				IF (tempDrawMatrix(S, R).pixelOn) THEN
					IF (NOT Set) THEN
						red_out <= tempDrawMatrix(S, R).rgb(11 DOWNTO 8);
						green_out <= tempDrawMatrix(S, R).rgb(7 DOWNTO 4);
						blue_out <= tempDrawMatrix(S, R).rgb(3 DOWNTO 0);
						set := true;
					END IF;
				END IF;
			END LOOP;
		END LOOP;

		IF (set) THEN
			set := false;
		ELSIF (scoreboard_Sig.pixelOn) THEN
			red_out <= scoreboard_Sig.rgb(11 DOWNTO 8);
			green_out <= scoreboard_Sig.rgb(7 DOWNTO 4);
			blue_out <= scoreboard_Sig.rgb(3 DOWNTO 0);

		ELSIF (explosionData.pixelOn) THEN --  AND explosionData.explosionHold
			red_out <= explosionData.rgb(11 DOWNTO 8);
			green_out <= explosionData.rgb(7 DOWNTO 4);
			blue_out <= explosionData.rgb(3 DOWNTO 0);

		ELSIF (terrain_Sig.pixelOn) THEN 
			red_out <= terrain_Sig.rgb(11 DOWNTO 8);
			green_out <= terrain_Sig.rgb(7 DOWNTO 4);
			blue_out <= terrain_Sig.rgb(3 DOWNTO 0);

		ELSIF (sky_Sig.pixelOn) THEN ----------- DRAW THE STARS ---------
			red_out <= sky_Sig.rgb(11 DOWNTO 8);
			green_out <= sky_Sig.rgb(7 DOWNTO 4);
			blue_out <= sky_Sig.rgb(3 DOWNTO 0);

		ELSE
			red_out <= (OTHERS => '0');
			green_out <= (OTHERS => '0');
			blue_out <= (OTHERS => '0');
		END IF;
	END PROCESS;

	-- Process for drawing explosions
	drawExplosions : PROCESS (vcount, hcount)
	BEGIN

		IF (hCount >= explosionData.position.x AND hCount <= explosionData.position.x + explosionData.size - 1 AND vCount >= explosionData.position.y AND vCount <= explosionData.position.y + explosionData.size - 1) THEN
			inExplosion <= true; -- explosionData.pixelOn <= true;
		ELSE
			inExplosion <= false; -- explosionData.pixelOn <= false;
		END IF;

		--- Calculate the column and row of the explosion
		explosion_rom_addr <= vCount - explosionData.position.y;
		explosion_rom_col <= hCount - explosionData.position.x;

		IF (explosionData.size = 15) THEN
			-- getting the data and the bit from the rom
			explosion_rom_data_15 <= small_exp_rom_const(explosion_rom_addr);
			explosion_rom_bit <= explosion_rom_data_15(explosion_rom_col);
		ELSIF (explosionData.size = 25) THEN
			explosion_rom_data_25 <= medium_exp_rom_const(explosion_rom_addr);
			explosion_rom_bit <= explosion_rom_data_25(explosion_rom_col);
		ELSIF (explosionData.size = 30) THEN
			explosion_rom_data_30 <= large_exp_rom_const(explosion_rom_addr);
			explosion_rom_bit <= explosion_rom_data_30(explosion_rom_col);
		END IF;

		IF ((inExplosion) AND (explosion_rom_bit = '1') AND (explosionData.explosionHold)) THEN
			explosionData.pixelOn <= true;
		ELSE
			explosionData.pixelOn <= false;
		END IF;

	END PROCESS;

	checkExplosions : PROCESS (clk)
		VARIABLE size, posx, posy, sizeInc : INTEGER := 0;
	BEGIN
		explosionData.size <= size;
		explosionData.position.x <= posx;
		explosionData.position.y <= posy;

		IF (rising_edge(clk)) THEN
			FOR f IN 0 TO 8 LOOP -- does this need to be in a loop to check with we are in an enemy?
				IF (killEnemy(f) = '1' OR killEnemySig(f) = '1') THEN -- latch in values for the postion of the enemy - (killEnemy of killEnemySig)
					IF (gameObjMatrix(f, 2).objwidth = 15) THEN
						-- Explosion location:
						posx := gameObjMatrix(f, 2).position.x;
						posy := gameObjMatrix(f, 2).position.y;
						size := 15;
						explosionData.explosionHold <= true;
					ELSIF (gameObjMatrix(f, 2).objwidth = 25) THEN
						posx := gameObjMatrix(f, 2).position.x;
						posy := gameObjMatrix(f, 2).position.y;
						size := 25;
						explosionData.explosionHold <= true;
					ELSIF (gameObjMatrix(f, 2).objwidth = 30) THEN
						posx := gameObjMatrix(f, 2).position.x;
						posy := gameObjMatrix(f, 2).position.y;
						size := 30;
						explosionData.explosionHold <= true;
					END IF;
				END IF;

				IF (explosionData.explosionHold) THEN -- added this here
					explosionOnCount <= explosionOnCount + 1;
				END IF;
				IF (explosionOnCount >= 25000000) THEN
					explosionData.explosionHold <= false;
					explosionOnCount <= 0;
				END IF;

			END LOOP;

			FOR f3 IN 0 TO 2 LOOP
				IF (killShootingEnemy(f3) = '1') THEN
					IF (gameObjMatrix(f3, 4).objwidth = 15) THEN
						-- Explosion location:
						posx := gameObjMatrix(f3, 4).position.x;
						posy := gameObjMatrix(f3, 4).position.y;
						size := 15;
						explosionData.explosionHold <= true;
					ELSIF (gameObjMatrix(f3, 4).objwidth = 25) THEN
						posx := gameObjMatrix(f3, 4).position.x;
						posy := gameObjMatrix(f3, 4).position.y;
						size := 25;
						explosionData.explosionHold <= true;
					ELSIF (gameObjMatrix(f3, 4).objwidth = 30) THEN
						posx := gameObjMatrix(f3, 4).position.x;
						posy := gameObjMatrix(f3, 4).position.y;
						size := 30;
						explosionData.explosionHold <= true;
					END IF;
				END IF;

				IF (explosionData.explosionHold) THEN -- added this here
					explosionOnCount <= explosionOnCount + 1;
				END IF;
				IF (explosionOnCount >= 25000000) THEN
					explosionData.explosionHold <= false;
					explosionOnCount <= 0;
				END IF;
			END LOOP;
		END IF;
	END PROCESS;

	-----------------------------------------*** Added by Blake--------------
	--LATCH IN THE PAUSE STATE
	pauseGame : PROCESS (clk, EndGame)
		VARIABLE setpause : BOOLEAN := false;
	BEGIN
		IF (EndGame = '1') THEN
			pause <= '1';
			setpause := false;
		ELSE
			IF (rising_edge(clk)) THEN
				IF (pause = '1' AND key0 = '0' AND (NOT setpause)) THEN
					pause <= '0';
					setpause := true;
				ELSIF (pause = '0' AND key0 = '0' AND (NOT setpause)) THEN
					pause <= '1';
					setpause := true;
				END IF;

				IF (key0 = '1') THEN
					setpause := false;
				END IF;
			END IF;
		END IF;
	END PROCESS;


	laserSound : PROCESS (clk)
		VARIABLE setSound : BOOLEAN := false;
		VARIABLE soundLaserV : STD_LOGIC := '0';
		VARIABLE clockcountF : NATURAL := 0;
	BEGIN
		IF rising_edge(clk) THEN
			soundLaser <= soundLaserV;
			FOR q IN 0 TO 4 LOOP
				IF ((gameObjMatrix(q, 1).position.x >= gameObjMatrix(0, 0).position.x + gameObjMatrix(0, 0).ObjWidth) AND (gameObjMatrix(q, 1).position.x <= gameObjMatrix(0, 0).position.x + gameObjMatrix(0, 0).objWidth + 40) AND (key1 = '0')) THEN
					setSound := true;
				END IF;
			END LOOP;

			IF (setSound = true) THEN
				soundLaserV := '1';
				setSound := false;
			ELSIF (setSound = false) THEN
				clockcountF := clockcountF + 1;
				IF (clockcountF >= 100000000) THEN
					clockcountF := 0;
					soundLaserV := '0';
				END IF;
			END IF;
		END IF;
	END PROCESS;

	--ship color
	DrawElementArrayMatrix(0, 0).rgb <= "111100000000";

	-- Laser Colors
	DrawElementArrayMatrix(0, 1).rgb <= "111100111011";
	DrawElementArrayMatrix(1, 1).rgb <= "110101001111";
	DrawElementArrayMatrix(2, 1).rgb <= "111100001111";
	DrawElementArrayMatrix(3, 1).rgb <= "110101100111";
	DrawElementArrayMatrix(4, 1).rgb <= "101111001110";

	--Moving Enemy Colors
	DrawElementArrayMatrix(0, 2).rgb <= "101111111010";
	DrawElementArrayMatrix(1, 2).rgb <= "110000001100";
	DrawElementArrayMatrix(2, 2).rgb <= "111111110000";
	DrawElementArrayMatrix(3, 2).rgb <= "111111111111";
	DrawElementArrayMatrix(4, 2).rgb <= "111100001111";
	DrawElementArrayMatrix(5, 2).rgb <= "000011111111";
	DrawElementArrayMatrix(6, 2).rgb <= "111111000011";
	DrawElementArrayMatrix(7, 2).rgb <= "100011110011";
	DrawElementArrayMatrix(8, 2).rgb <= "101110110100";

	--Object Colors
	DrawElementArrayMatrix(0, 3).rgb <= "011101111001";
	DrawElementArrayMatrix(1, 3).rgb <= "011101111001";
	DrawElementArrayMatrix(2, 3).rgb <= "011101111001";
	DrawElementArrayMatrix(3, 3).rgb <= "011101111001";
	DrawElementArrayMatrix(4, 3).rgb <= "011101111001";

	-- Enemy Laser Colors
	drawElementArrayMatrix(0, 5).rgb <= "111100000000";
	drawElementArrayMatrix(1, 5).rgb <= "111100000000";
	drawElementArrayMatrix(2, 5).rgb <= "111100000000";
END ARCHITECTURE;