------------------------------------------------------------------------------------------------------------------------------------------
-- Project: Defender (DSD Final Project Fall 2021)
-- Author: Nathan Gardner
-- Date: 11/30/21
------------------------------------------------------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

USE work.graphicsPackage.ALL;

ENTITY terrain IS
	PORT (
		clk : IN STD_LOGIC;
		hcount : IN INTEGER;
		vcount : IN INTEGER;
		pause : IN STD_LOGIC;
		terrainDataOut : OUT terrain_data := init_terrain
	);
END ENTITY;

ARCHITECTURE myterrain OF terrain IS
	SIGNAL red_out, green_out, blue_out : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL count : INTEGER := 0;
	SIGNAL shift : INTEGER RANGE 0 TO 10000 := 0;
BEGIN

	mapTerrain : PROCESS (hcount, vcount)
	BEGIN
		IF (vcount >= 1 AND vcount <= 640) THEN
			IF (vcount = (450 - terrain_rom_const(hcount + shift))) THEN
				terrainDataOut.pixelOn <= true;
				terrainDataOut.rgb <= "011000110011";
			ELSIF (vcount > (450 - terrain_rom_const(hcount + shift))) THEN --- ADDED THIS****
				terrainDataOut.pixelOn <= true;
				terrainDataOut.rgb <= "000000000000";
			ELSE
				terrainDataOut.pixelOn <= false;
			END IF;
		END IF;
	END PROCESS;

	moveTerrain : PROCESS (clk)
	BEGIN
		IF (pause = '0') THEN
			IF (rising_edge(clk)) THEN
				count <= count + 1;
				IF ((count >= 1000000)) THEN
					count <= 0;
					shift <= shift + 1;
					IF (shift = 8000) THEN
						shift <= 0;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;

END ARCHITECTURE;