------------------------------------------------------------------------------------------------------------------------------------------
-- Project: Defender (DSD Final Project Fall 2021)
-- Author: Blake Martin
-- Date: 11/30/21
------------------------------------------------------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.graphicsPackage.ALL;

-- need numGameObjects for array

ENTITY laser IS

	PORT (-- inputs"
		pause : IN STD_LOGIC; --Key0
		clk : IN STD_LOGIC;
		killLaser : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
		playerControls : controls;
		ship : IN type_gameObj;
		hcount : IN INTEGER;
		vcount : IN INTEGER;

		-- outputs:
		laser1Out, laser2out, laser3out, laser4out, laser5out : OUT type_gameObj;
		ledFix : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)

	);

END ENTITY;

ARCHITECTURE Lazer OF laser IS

	SIGNAL clk_count : INTEGER := 0;
	SIGNAL clkprescaler : INTEGER := 5000000; --50 MHz / clk_prescaler = desired speed

	SIGNAL laser1, laser2, laser3, laser4, laser5 : type_gameObj := init_laser;

	SIGNAL shipObj1, shipObj2, shipObj3, shipObj4, shipObj5 : type_gameObj := init_ship;
	SIGNAL synch : INTEGER;
	SIGNAL deadReg : STD_LOGIC_VECTOR(4 DOWNTO 0);
BEGIN
	-----------------------------------------------------------------------------------------------------------------------------
	deadRegister : PROCESS (clk)
		VARIABLE clkCountD1, clkCountD2, clkCountD3, clkCountD4, clkCountD5 : INTEGER := clk_count;
		VARIABLE deadRegV : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
		VARIABLE killLaserV : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
	BEGIN
		IF (rising_edge(clk)) THEN
			killLaserV := killLaser;
			deadReg <= deadRegV;
			IF (killLaserV(0) = '1') THEN
				deadRegV(0) := '1';
				clkCountD1 := 0;
			ELSIF (killLaserV(1) = '1') THEN
				deadRegV(1) := '1';
				clkCountD2 := 0;
			ELSIF (killLaserV(2) = '1') THEN
				deadRegV(2) := '1';
				clkCountD3 := 0;
			ELSIF (killLaserV(3) = '1') THEN
				deadRegV(3) := '1';
				clkCountD4 := 0;
			ELSIF (killLaserV(4) = '1') THEN
				deadRegV(4) := '1';
				clkCountD5 := 0;
			END IF;

			IF (deadRegV(0) = '1') THEN
				clkCountD1 := clkCountD1 + 1;
				IF (clkCountD1 >= 10000) THEN
					deadRegV(0) := '0';
					clkCountD1 := 0;
				END IF;
			END IF;
			IF (deadRegV(1) = '1') THEN
				clkCountD2 := clkCountD2 + 1;
				IF (clkCountD2 >= 10000) THEN
					deadRegV(1) := '0';
					clkCountD2 := 0;
				END IF;
			END IF;

			IF (deadRegV(2) = '1') THEN
				clkCountD3 := clkCountD3 + 1;
				IF (clkCountD3 >= 10000) THEN
					deadRegV(2) := '0';
					clkCountD3 := 0;
				END IF;
			END IF;

			IF (deadRegV(3) = '1') THEN
				clkCountD4 := clkCOuntD4 + 1;
				IF (clkCountD4 >= 10000) THEN
					deadRegV(3) := '0';
					clkCountD4 := 0;
				END IF;
			END IF;

			IF (deadRegV(4) = '1') THEN
				clkCountD5 := clkCOuntD5 + 1;
				IF (clkCountD5 >= 10000) THEN
					deadRegV(4) := '0';
					clkCountD5 := 0;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	ledFix(4) <= deadReg(4);
	ledFix(3) <= deadReg(3);
	ledFix(2) <= deadReg(2);
	ledFix(1) <= deadReg(1);
	ledFix(0) <= deadReg(0);

	laser1OnOff : PROCESS (clk, deadReg(0))
		VARIABLE laserBounds1 : type_bounds;
	BEGIN
		IF (deadReg(0) = '1') THEN
			laser1.element_on <= false;
		ELSE
			IF (rising_edge(clk)) THEN
				IF (synch = clkPrescaler - 1) THEN
					laserBounds1 := createBounds(laser1);
					IF (laser1.element_on = false) THEN
						IF (playerControls.shoot = '1') THEN
							laser1.element_on <= true;
						ELSE
							laser1.element_on <= false;
						END IF;

					ELSIF (laser1.element_on = true) THEN
						IF (deadReg(0) = '0') THEN
							laser1.element_on <= true;
						ELSE
							laser1.element_on <= false;
						END IF;
					ELSE
						laser1.element_on <= false;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	------------------------------------------------
	animLaser1 : PROCESS (clk)
		VARIABLE hcountSig1, vcountSig1 : INTEGER;
		VARIABLE shipBounds1, laserBounds1 : type_bounds;
		VARIABLE x_position1 : INTEGER := 20;
		VARIABLE clkCount1 : INTEGER := clk_count;

	BEGIN
		shipObj1 <= ship;
		laser1out <= laser1;
		IF (rising_edge(clk)) THEN

			IF (pause = '1') THEN
				shipBounds1 := createBounds(shipObj1);
				laser1.position.x <= laser1.position.x;
				laser1.position.y <= laser1.position.y;
				laser1.objWidth <= laserWidth;
				laser1.objHeight <= laserHeight;
				laser1.velocity <= laser_velo;
				clkCount1 := 0;
				synch <= 0;

			ELSE
				clkCount1 := clkCount1 + 1;
				synch <= synch + 1;
				IF (clkCount1 >= clkPrescaler) THEN
					clkCount1 := 0;
					synch <= 0;
					IF (laser1.element_on) THEN
						laser1.velocity <= laser_velo;
						laser1.position.x <= laser1.position.x + laser1.velocity.x;
					ELSE
						shipBounds1 := createBounds(shipObj1);
						laser1.position.x <= shipBounds1.R;
						laser1.position.y <= shipBounds1.bottom;
					END IF;

				END IF;
			END IF;
		END IF;
	END PROCESS;
	------------------------------------------------------------------------------------------------------------------

	laser2OnOff : PROCESS (clk, deadReg(1))
		VARIABLE laserBounds2 : type_bounds;
	BEGIN
		IF (deadReg(1) = '1') THEN
			laser2.element_on <= false;
		ELSE
			IF (rising_edge(clk)) THEN
				IF (synch = clkPrescaler - 1) THEN
					laserBounds2 := createBounds(laser2);
					IF (laser2.element_on = false) THEN
						IF (playerControls.shoot = '1' AND laser1.element_on) THEN
							laser2.element_on <= true;
						ELSE
							laser2.element_on <= false;
						END IF;

					ELSIF (laser2.element_on = true) THEN
						IF (deadReg(1) = '0') THEN
							laser2.element_on <= true;
						ELSE
							laser2.element_on <= false;
						END IF;
					ELSE
						laser2.element_on <= false;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	--------------------------------------------------
	animLaser2 : PROCESS (clk)
		VARIABLE shipBounds2, laserBounds2 : type_bounds;
		VARIABLE clkCount2 : INTEGER := 0;

	BEGIN
		shipObj2 <= ship;
		laser2out <= laser2;
		IF (rising_edge(clk)) THEN

			IF (pause = '1') THEN
				shipBounds2 := createBounds(shipObj2);
				laser2.position.x <= laser2.position.x;
				laser2.position.y <= laser2.position.y;
				laser2.objWidth <= laserWidth;
				laser2.objHeight <= laserHeight;
				laser2.velocity <= laser_velo;
				clkCount2 := 0;

			ELSE
				clkCount2 := clkCount2 + 1;
				IF (clkCount2 >= clkPrescaler) THEN
					clkCount2 := 0;
					IF (laser2.element_on) THEN
						laser2.velocity <= laser_velo;
						laser2.position.x <= laser2.position.x + laser2.velocity.x;
					ELSE
						shipBounds2 := createBounds(shipObj2);
						laser2.position.x <= shipBounds2.R;
						laser2.position.y <= shipBounds2.bottom;
					END IF;

				END IF;
			END IF;
		END IF;
	END PROCESS;
	----------------------------------------------------------------------------------------------------------------------
	laser3OnOff : PROCESS (clk, deadReg(2))
		VARIABLE laserBounds3 : type_bounds;
	BEGIN
		IF (deadReg(2) = '1') THEN
			laser3.element_on <= false;
		ELSE
			IF (rising_edge(clk)) THEN
				IF (synch = clkPrescaler - 1) THEN
					laserBounds3 := createBounds(laser3);
					IF (laser3.element_on = false) THEN
						IF (playerControls.shoot = '1' AND laser2.element_on) THEN
							laser3.element_on <= true;
						ELSE
							laser3.element_on <= false;
						END IF;

					ELSIF (laser3.element_on = true) THEN
						IF (deadReg(2) = '0') THEN
							laser3.element_on <= true;
						ELSE
							laser3.element_on <= false;
						END IF;
					ELSE
						laser3.element_on <= false;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	------------------------------------------------------------
	animLaser3 : PROCESS (clk)
		VARIABLE shipBounds3, laserBounds : type_bounds;
		VARIABLE clkCount3 : INTEGER := 0;

	BEGIN
		shipObj3 <= ship;
		laser3out <= laser3;
		IF (rising_edge(clk)) THEN

			IF (pause = '1') THEN
				shipBounds3 := createBounds(shipObj3);
				laser3.position.x <= laser3.position.x;
				laser3.position.y <= laser3.position.y;
				laser3.objWidth <= laserWidth;
				laser3.objHeight <= laserHeight;
				laser3.velocity <= laser_velo;
				clkCount3 := 0;

			ELSE
				clkCount3 := clkCount3 + 1;
				IF (clkCount3 >= clkPrescaler) THEN
					clkCount3 := 0;
					IF (laser3.element_on) THEN
						laser3.velocity <= laser_velo;
						laser3.position.x <= laser3.position.x + laser3.velocity.x;
					ELSE
						shipBounds3 := createBounds(shipObj3);
						laser3.position.x <= shipBounds3.R;
						laser3.position.y <= shipBounds3.bottom;
					END IF;

				END IF;
			END IF;
		END IF;
	END PROCESS;
	-------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------
	laser4OnOff : PROCESS (clk, deadReg(3))
		VARIABLE laserBounds4 : type_bounds;
	BEGIN
		IF (deadReg(3) = '1') THEN
			laser4.element_on <= false;
		ELSE
			IF (rising_edge(clk)) THEN
				IF (synch = clkPrescaler - 1) THEN
					laserBounds4 := createBounds(laser4);
					IF (laser4.element_on = false) THEN
						IF (playerControls.shoot = '1' AND laser3.element_on) THEN
							laser4.element_on <= true;
						ELSE
							laser4.element_on <= false;
						END IF;

					ELSIF (laser4.element_on = true) THEN
						IF (deadReg(3) = '0') THEN
							laser4.element_on <= true;
						ELSE
							laser4.element_on <= false;
						END IF;
					ELSE
						laser4.element_on <= false;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	------------------------------------------------------------
	animLaser4 : PROCESS (clk)
		VARIABLE shipBounds4, laserBounds4 : type_bounds;
		VARIABLE clkCount4 : INTEGER := 0;

	BEGIN
		shipObj4 <= ship;
		laser4out <= laser4;
		IF (rising_edge(clk)) THEN

			IF (pause = '1') THEN
				shipBounds4 := createBounds(shipObj4);
				laser4.position.x <= laser4.position.x;
				laser4.position.y <= laser4.position.y;
				laser4.objWidth <= laserWidth;
				laser4.objHeight <= laserHeight;
				laser4.velocity <= laser_velo;
				clkCount4 := 0;

			ELSE
				clkCount4 := clkCount4 + 1;
				IF (clkCount4 >= clkPrescaler) THEN
					clkCount4 := 0;
					IF (laser4.element_on) THEN
						laser4.velocity <= laser_velo;
						laser4.position.x <= laser4.position.x + laser4.velocity.x;
					ELSE
						shipBounds4 := createBounds(shipObj4);
						laser4.position.x <= shipBounds4.R;
						laser4.position.y <= shipBounds4.bottom;
					END IF;

				END IF;
			END IF;
		END IF;
	END PROCESS;
	-------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------
	laser5OnOff : PROCESS (clk, deadReg(4))
		VARIABLE laserBounds5 : type_bounds;
	BEGIN
		IF (deadReg(4) = '1') THEN
			laser5.element_on <= false;
		ELSE
			IF (rising_edge(clk)) THEN
				IF (synch = clkPrescaler - 1) THEN
					laserBounds5 := createBounds(laser5);
					IF (laser5.element_on = false) THEN
						IF (playerControls.shoot = '1' AND laser4.element_on) THEN
							laser5.element_on <= true;
						ELSE
							laser5.element_on <= false;
						END IF;

					ELSIF (laser5.element_on = true) THEN
						IF (deadReg(4) = '0') THEN
							laser5.element_on <= true;
						ELSE
							laser5.element_on <= false;
						END IF;
					ELSE
						laser5.element_on <= false;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	------------------------------------------------------------
	animLaser5 : PROCESS (clk)
		VARIABLE shipBounds5, laserBounds5 : type_bounds;
		VARIABLE clkCount5 : INTEGER := 0;

	BEGIN
		shipObj5 <= ship;
		laser5out <= laser5;
		IF (rising_edge(clk)) THEN

			IF (pause = '1') THEN
				shipBounds5 := createBounds(shipObj5);
				laser5.position.x <= laser5.position.x;
				laser5.position.y <= laser5.position.y;
				laser5.objWidth <= laserWidth;
				laser5.objHeight <= laserHeight;
				laser5.velocity <= laser_velo;
				clkCount5 := 0;

			ELSE
				clkCount5 := clkCount5 + 1;
				IF (clkCount5 >= clkPrescaler) THEN
					clkCount5 := 0;
					IF (laser5.element_on) THEN
						laser5.velocity <= laser_velo;
						laser5.position.x <= laser5.position.x + laser5.velocity.x;
					ELSE
						shipBounds5 := createBounds(shipObj5);
						laser5.position.x <= shipBounds5.R;
						laser5.position.y <= shipBounds5.bottom;
					END IF;

				END IF;
			END IF;
		END IF;
	END PROCESS;
END ARCHITECTURE;
-------------------------------------------------------------------------------------------------------------------