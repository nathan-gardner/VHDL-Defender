------------------------------------------------------------------------------------------------------------------------------------------
-- Project: Defender (DSD Final Project Fall 2021)
-- Author: Blake Martin
-- Date: 11/30/21
------------------------------------------------------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
LIBRARY work;
USE work.graphicsPackage.ALL;

ENTITY ship IS
	PORT (
		-- inputs:
		pause : IN STD_LOGIC;
		clk : IN STD_LOGIC;
		killShip : IN STD_LOGIC := '0';
		playerControls : IN controls;
		hcount : IN INTEGER;
		vcount : IN INTEGER;
		points : IN INTEGER;
		--Outputs:
		EndGame : OUT STD_LOGIC := '0';
		position, velocity : OUT point_2D;
		objHeight, objWidth : OUT INTEGER;
		elementOn : OUT BOOLEAN := true;
		lives : OUT INTEGER;
		ledFix : OUT STD_LOGIC
	);
END ENTITY;
ARCHITECTURE myship OF ship IS
	SIGNAL ShipObj : type_gameObj := init_ship;
	SIGNAL killShipSig : STD_LOGIC := '0';
	SIGNAL clk_Count : INTEGER := 0;
	CONSTANT clkPrescaler1 : INTEGER := 5000000;
	CONSTANT clkPrescaler2 : INTEGER := 5000000;

BEGIN
	-----------------------------------------------------------------------------------------------------------

	deadRegister : PROCESS (clk, killShip)
		VARIABLE clkCountE : INTEGER := clk_count;
		VARIABLE killShipV : STD_LOGIC := '0';
		VARIABLE clkCountEnd : INTEGER := 0;
		VARIABLE EndgameVar : STD_LOGIC := '0';
	BEGIN
		IF (rising_edge(clk)) THEN
			EndGame <= EndGameVar;
			killShipSig <= killShipV;
			IF (killShip = '1') THEN
				killShipV := '1';
			ELSIF (killShip = '0' AND killShipV = '1') THEN
				clkCountE := clkCountE + 1;
				IF (clkCountE >= 50000000) THEN
					clkCountE := 0;
					killShipV := '0';
					shipObj.lives <= shipObj.lives - 1;
				END IF;
			END IF;

			IF (ShipObj.lives = 0 AND EndgameVar = '0') THEN
				EndGameVar := '1';
			ELSIF (EndGameVar = '1') THEN
				clkCountEnd := clkCountEnd + 1;
				IF (clkCountEnd = 50000000) THEN
					EndGameVar := '0';
					killShipV := '0';
					ShipObj.lives <= 3;
				END IF;
			END IF;

			IF (points >= 500) THEN
				IF (shipObj.lives < 3) THEN
					shipObj.lives <= shipObj.lives + 1;
				END IF;
			END IF;

		END IF;
	END PROCESS;

	ledFix <= killShipSig;
	-------------------------------------------
	anim : PROCESS (clk, killShipSig)
		VARIABLE shipBounds : type_bounds;
		VARIABLE x_position : INTEGER := 20;
		VARIABLE clkCount : INTEGER := clk_count;
	BEGIN
		position <= shipObj.position;
		velocity <= shipObj.velocity;
		objHeight <= shipObj.objHeight;
		objWidth <= shipObj.objWidth;
		elementOn <= shipObj.element_on;
		lives <= shipObj.lives;
		IF (pause = '1') THEN
			shipObj.element_on <= true;
			shipObj.position.x <= shipObj.position.x;
			shipObj.position.y <= shipObj.position.y;
			shipObj.objWidth <= shipWidthConst;
			shipObj.objHeight <= shipHeightConst;
			shipObj.velocity.x <= 0;
			shipObj.velocity.y <= 0;
			clkCount := 0;
		ELSIF (killShipSig = '1') THEN
			shipObj.position.x <= shipsInitialx;
			shipObj.position.y <= shipsInitialy;
			shipObj.velocity.x <= 0;
			shipObj.velocity.y <= 0;
			shipObj.objWidth <= shipWidthConst;
			shipObj.objHeight <= shipHeightConst;
			clkCount := 0;
		ELSE

			IF (rising_edge(clk)) THEN
				clkCount := clkCount + 1;
				IF (clkCount >= clkPrescaler1) THEN
					clkCount := 0;
					shipObj.position.x <= shipObj.position.x;
					shipObj.position.y <= shipObj.position.y;
					IF (playercontrols.up = '1') THEN
						IF (shipObj.velocity.y > 3) THEN
							shipObj.velocity.y <= shipObj.velocity.y - 3;
						ELSE
							shipObj.velocity.y <= shipObj.velocity.y - 1;
						END IF;
					END IF;

					IF (playercontrols.down = '1') THEN
						IF (shipObj.velocity.y <- 3) THEN
							shipObj.velocity.y <= shipObj.velocity.y + 3;
						ELSE
							shipObj.velocity.y <= shipObj.velocity.y + 1;
						END IF;
					END IF;

					IF (playercontrols.L = '1') THEN
						IF (shipObj.velocity.x > 3) THEN
							shipObj.velocity.x <= shipObj.velocity.x - 3;
						ELSE
							shipObj.velocity.x <= shipObj.velocity.x - 1;
						END IF;
					END IF;

					IF (playercontrols.R = '1') THEN
						IF (shipObj.velocity.x <- 3) THEN
							shipObj.velocity.x <= shipObj.velocity.x + 3;
						ELSE
							shipObj.velocity.x <= shipObj.velocity.x + 1;
						END IF;
					END IF;

					IF (playercontrols.up = '0' AND playercontrols.down = '0') THEN
						shipObj.velocity.y <= 0;
					END IF;

					IF (playercontrols.L = '0' AND playercontrols.R = '0') THEN
						shipObj.velocity.x <= 0;
					END IF;
					IF (shipObj.velocity.x > 8) THEN
						shipObj.velocity.x <= 8;
					ELSIF (shipObj.velocity.x <- 8) THEN
						shipObj.velocity.x <= - 8;
					END IF;

					IF (shipObj.velocity.y > 8) THEN
						shipObj.velocity.y <= 8;
					ELSIF (shipObj.velocity.y <- 8) THEN
						shipObj.velocity.y <= - 8;
					END IF;
					-- Create bounds for ship Object
					shipBounds := createBounds(shipObj);

					--If the top edge of ship is not at the upper bound then we can move up
					--If the bottom edge of ship is not at the lower bound then we can move down
					IF (shipBounds.top + shipObj.velocity.y > 0 AND shipBounds.bottom + shipObj.velocity.y < mapEdgeBottom) THEN
						shipObj.position.y <= shipObj.position.y + shipObj.velocity.y;
					ELSE
						IF (playerControls.up = '1') THEN
							IF (shipBounds.top + shipObj.velocity.y <= mapEdgeTop) THEN
								shipObj.position.y <= mapEdgeTop;
								shipObj.velocity.y <= 0;
							END IF;
						ELSIF (playercontrols.down = '1') THEN
							IF (shipBounds.bottom + shipObj.velocity.y >= mapEdgeBottom) THEN
								shipObj.position.y <= mapEdgeBottom - shipObj.objHeight - 1;
								shipObj.velocity.y <= 0;
							END IF;
						END IF;
					END IF;
					--if the leftmost edge of the ship is not at the left bound then we can move left
					IF (shipBounds.L + shipObj.velocity.x > 0 AND shipBounds.R + shipObj.velocity.x < 320) THEN
						shipObj.position.x <= shipObj.position.x + shipObj.velocity.x;

					ELSE
						IF (playercontrols.L = '1') THEN
							IF (shipBounds.L + shipObj.velocity.x <= 0) THEN
								shipObj.position.x <= mapEdgeLeft;
								shipObj.velocity.x <= 0;
							ELSE
								shipObj.position.x <= shipObj.position.x + shipObj.velocity.x;
							END IF;
						ELSIF (playercontrols.R = '1') THEN
							IF (shipBounds.R + shipObj.velocity.x >= 320) THEN
								shipObj.position.x <= 320 - shipObj.objWidth;
								shipObj.velocity.x <= 0;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	----------------------------------------------------------------------------------------------------------------------------------------------------

END ARCHITECTURE;