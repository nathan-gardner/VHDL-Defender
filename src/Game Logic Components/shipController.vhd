------------------------------------------------------------------------------------------------------------------------------------------
-- Project: Defender (DSD Final Project Fall 2021)
-- Author: Blake Martin
-- Date: 11/30/21
------------------------------------------------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

LIBRARY work;
USE work.graphicsPackage.ALL;

ENTITY shipController IS
	PORT (
		clk : IN STD_LOGIC;
		shiftMagx, shiftMagy : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		x_shiftDir, y_shiftDir : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		key1 : IN STD_LOGIC;

		controlCommand : OUT controls
	);
END ENTITY;

ARCHITECTURE controller OF shipController IS
BEGIN
	-- LEFT / RIGHT CALCULATION:
	calc_LeftRight : PROCESS (clk)
		VARIABLE playerControls : controls;
	BEGIN
		IF (x_shiftDir = "10") THEN
			PlayerControls.L := '1';
			PlayerControls.R := '0';
			PlayerControls.moveMagx := shiftMagx;
		ELSIF (x_shiftDir = "11") THEN
			PlayerControls.L := '0';
			PlayerControls.R := '1';
			PlayerControls.moveMagx := shiftMagx;
		ELSE
			PlayerControls.L := '0';
			PlayerControls.R := '0';
			PlayerControls.moveMagx := (OTHERS => '0');
		END IF;

		-- UP / DOWN CALCULATION:
		IF (y_shiftDir = "11") THEN
			PlayerControls.up := '1';
			PlayerControls.down := '0';
			PlayerControls.moveMagy := shiftMagy;
		ELSIF (y_shiftDir = "10") THEN
			PlayerControls.up := '0';
			PlayerControls.down := '1';
			PlayerControls.moveMagy := shiftMagy;
		ELSE
			PlayerControls.up := '0';
			PlayerControls.down := '0';
			PlayerControls.moveMagy := (OTHERS => '0');
		END IF;

		IF (key1 = '0') THEN
			playerControls.shoot := '1';
		ELSE
			playerControls.shoot := '0';
		END IF;
		controlCommand <= PlayerControls;
	END PROCESS;

END ARCHITECTURE;