------------------------------------------------------------------------------------------------------------------------------------------
-- Project: Defender (DSD Final Project Fall 2021)
-- Author: Blake Martin
-- Date: 11/30/21
------------------------------------------------------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.math_real.ALL;
LIBRARY work;
USE work.graphicsPackage.ALL;

ENTITY shootingEnemies IS
	PORT (
		-- inputs:
		clk : IN STD_LOGIC;
		pause : IN STD_LOGIC := '0';
		EndGame : IN STD_LOGIC := '0';
		waveCount : IN INTEGER := 0;
		ship : IN type_gameObj;
		killShootingEnemy, killEnemyLaser : IN STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
		hcount : IN INTEGER;
		vcount : IN INTEGER;
		waveResetIn : IN STD_LOGIC;
		shootingEnemyOut1 : OUT type_gameObj;
		shootingEnemyOut2 : OUT type_gameObj;
		shootingEnemyOut3 : OUT type_gameObj;
		EnemyLaserOut1 : OUT type_gameObj;
		EnemyLaserOut2 : OUT type_gameObj;
		EnemyLaserOut3 : OUT type_gameObj;
		ledfix : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)

	);
END ENTITY;

ARCHITECTURE enemiesArch OF shootingEnemies IS
	-------------------------------------------------------------------------------
	SIGNAL deadReg, laserDeadReg, holdKill : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
	SIGNAL WaveresetSig : STD_LOGIC := '0';
	SIGNAL EnemyLasersSig : type_gameObjArray(2 DOWNTO 0);
	-----------------------------------------------------------------------------
	SIGNAL clk_Count : INTEGER := 0;
	SIGNAL clkprescaler : INTEGER := 5000000; --50 MHz / clk_prescaler = desired speed

	--**************************************************************************
	TYPE intArray IS ARRAY(NATURAL RANGE <>) OF INTEGER;
	SIGNAL enemyMod, laserMod : intArray(2 DOWNTO 0);
	SIGNAL shipObj1 : type_gameObj := init_ship;

	SIGNAL currWait : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '1');
	SIGNAL NextState : STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL feedback : STD_LOGIC;

	SIGNAL LiveEnemies : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000"; 		 -- 12 shootingEnemies
	SIGNAL startState : STD_LOGIC_VECTOR(11 DOWNTO 0) := "111111111111"; -- intial state
	SIGNAL setReg : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
	SIGNAL stickyReg : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
	SIGNAL RandClk : STD_LOGIC := '0';
	SIGNAL EnemyLaserArrayOut, ShootingEnemyArrayOut, shootingEnemyArray : type_gameObjArray(2 DOWNTO 0) := (init_ShootingSmall & init_ShootingMed & init_ShootingBig);
	COMPONENT clock_divider IS PORT (clk_in : IN STD_LOGIC;
		clk_out : OUT STD_LOGIC);
	END COMPONENT;

BEGIN

	EnemyLaserOut1 <= EnemyLaserArrayOut(0);
	EnemyLaserOut2 <= EnemyLaserArrayOut(1);
	EnemyLaserOut3 <= EnemyLaserArrayOut(2);

	--**************************** BEGIN POSITIONAL LOGIC********************************************
	animShootingEnemies : PROCESS (clk, pause)
		VARIABLE EnemyBounds : type_bounds;
		VARIABLE clkCount1 : INTEGER := clk_count;
		VARIABLE currState : INTEGER := to_integer(unsigned(currWait));
		VARIABLE modVal : INTEGER := 0;
		VARIABLE lastVelX, LastVelY : intArray(2 DOWNTO 0) := (OTHERS => 0);
		VARIABLE stopX : intArray(2 DOWNTO 0) := 475 & 425 & 525;
		VARIABLE stopYTop : intArray(2 DOWNTO 0);
		VARIABLE stopYBottom : intArray(2 DOWNTO 0);
	BEGIN
		shootingEnemyOut1.element_on <= shootingEnemyArray(0).element_on;
		shootingEnemyOut1.position <= shootingEnemyArray(0).position;
		shootingEnemyOut1.velocity <= shootingEnemyArray(0).velocity;
		shootingEnemyOut1.objWidth <= shootingEnemyArray(0).objWidth;
		shootingEnemyOut1.objHeight <= shootingEnemyArray(0).objHeight;

		shootingEnemyOut2.element_on <= shootingEnemyArray(1).element_on;
		shootingEnemyOut2.position <= shootingEnemyArray(1).position;
		shootingEnemyOut2.velocity <= shootingEnemyArray(1).velocity;
		shootingEnemyOut2.objWidth <= shootingEnemyArray(1).objWidth;
		shootingEnemyOut2.objHeight <= shootingEnemyArray(1).objHeight;

		shootingEnemyOut3.element_on <= shootingEnemyArray(2).element_on;
		shootingEnemyOut3.position <= shootingEnemyArray(2).position;
		shootingEnemyOut3.velocity <= shootingEnemyArray(2).velocity;
		shootingEnemyOut3.objWidth <= shootingEnemyArray(2).objWidth;
		shootingEnemyOut3.objHeight <= shootingEnemyArray(2).objHeight;
		stopYTop(0) := mapEdgeTop + 20;
		stopYTop(1) := mapEdgeTop + 50;
		stopYTop(2) := mapEdgeTop + 100;
		stopYBottom(0) := mapEdgeBottom - 20;
		stopYBottom(1) := mapEdgeBottom - 50;
		stopYBottom(2) := mapEdgeBottom - 100;
		FOR i IN 0 TO 2 LOOP
			IF (pause = '1') THEN
				IF (shootingEnemyArray(i).element_on) THEN
					shootingEnemyArray(i).position <= shootingEnemyArray(i).position;
					shootingEnemyArray(i).velocity <= shootingEnemyArray(i).velocity;
					shootingEnemyArray(i).objWidth <= shootingEnemyArray(i).ObjWidth;
					shootingEnemyArray(i).objHeight <= shootingEnemyArray(i).objHeight;
				END IF;
				clkCount1 := 0;
			ELSE
				-- maybe move the deadReg check to each ARRAY
				IF (rising_edge(clk)) THEN
					currState := to_integer(unsigned(currWait));
					modVal := currstate MOD enemyMod(i);
					IF (stickyReg(i) = '0' AND modVal = 0 AND DeadReg(i) = '0' AND waveCount > 2) THEN
						shootingEnemyArray(i).element_on <= true;
					ELSIF (deadReg(i) = '1') THEN
						shootingEnemyArray(i).element_on <= false;
					ELSE
						clkCount1 := clkCount1 + 1;
						IF (clkCount1 >= clkPrescaler + 2000000) THEN
							clkCount1 := 0;
							IF (shootingEnemyArray(i).element_on) THEN
								IF (shootingEnemyArray(i).position.x > stopX(i) AND deadReg(i) = '0') THEN
									shootingEnemyArray(i).position.x <= shootingEnemyArray(i).position.x + shootingEnemyArray(i).velocity.x;
								ELSIF (shootingEnemyArray(i).position.x <= stopX(i) AND deadReg(i) = '0') THEN
									IF (shootingEnemyArray(i).velocity.x < 0) THEN
										shootingEnemyArray(i).velocity.x <= shootingEnemyArray(i).velocity.x + 1;
										shootingEnemyArray(i).position.x <= shootingEnemyArray(i).position.x + shootingEnemyArray(i).velocity.x;
									ELSIF (shootingEnemyArray(i).velocity.x = 0) THEN
										IF (shootingEnemyArray(i).velocity.y = 0 AND lastVelY(i) <= 3) THEN
											shootingEnemyArray(i).velocity.y <= 1;
											shootingEnemyArray(i).position.y <= shootingEnemyArray(i).position.y + 1;
										ELSIF (shootingEnemyArray(i).velocity.y = 0 AND lastVelY(i) > 3) THEN
											shootingEnemyArray(i).velocity.y <= - 1;
											shootingEnemyArray(i).position.y <= shootingEnemyArray(i).position.y - 1;
										ELSIF (shootingEnemyArray(i).velocity.y > 0 AND shootingEnemyArray(i).position.y + shootingEnemyArray(i).velocity.y + shootingEnemyArray(i).objHeight < stopYBottom(i)) THEN
											shootingEnemyArray(i).velocity.y <= shootingEnemyArray(i).velocity.y + 1;
											shootingEnemyArray(i).position.y <= shootingEnemyArray(i).position.y + shootingEnemyArray(i).velocity.y;
										ELSIF (shootingEnemyArray(i).velocity.y > 1 AND shootingEnemyArray(i).position.y + shootingEnemyArray(i).velocity.y + shootingEnemyArray(i).objHeight >= stopYBottom(i)) THEN
											shootingEnemyArray(i).velocity.y <= - 1;
											shootingEnemyArray(i).position.y <= shootingEnemyArray(i).position.y + shootingEnemyArray(i).velocity.y;
										ELSIF (shootingEnemyArray(i).velocity.y < 0 AND shootingEnemyArray(i).velocity.y + shootingEnemyArray(i).position.y > stopYTop(i)) THEN
											shootingEnemyArray(i).velocity.y <= shootingEnemyArray(i).velocity.y - 1;
											shootingEnemyArray(i).position.y <= shootingEnemyArray(i).position.y + shootingEnemyArray(i).velocity.y;
										ELSIF (shootingEnemyArray(i).velocity.y <- 1 AND shootingEnemyArray(i).velocity.y + shootingEnemyArray(i).position.y <= stopYTop(i)) THEN
											shootingEnemyArray(i).velocity.y <= 1;
											shootingEnemyArray(i).position.y <= shootingEnemyArray(i).position.y + shootingEnemyArray(i).velocity.y;
										END IF;
									END IF;
								END IF;
							ELSE
								CASE(i) IS
									WHEN 0 => shootingEnemyArray(i).position <= smallPos;
									shootingEnemyArray(i).velocity <= small_Velo;
									WHEN 1 => shootingEnemyArray(i).position <= MedPos;
									shootingEnemyArray(i).velocity <= med_velo;
									WHEN 2 => shootingEnemyArray(i).position <= BigPos;
									shootingEnemyArray(i).velocity <= big_velo;
								END CASE;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END LOOP;
	END PROCESS;

	holdKillProcess : PROCESS (killShootingEnemy(0), killShootingEnemy(1), killShootingEnemy(2), EndGame, clk)
		VARIABLE holdClk : intArray(2 DOWNTO 0) := (OTHERS => 0);
	BEGIN
		IF (EndGame = '1') THEN
			holdKill <= (OTHERS => '1');
		ELSIF (killShootingEnemy(0) = '1') THEN
			holdKill(0) <= '1';
		ELSIF (killShootingEnemy(1) = '1') THEN
			holdKill(1) <= '1';
		ELSIF (killShootingEnemy(2) = '1') THEN
			holdKill(2) <= '1';
		ELSE
			IF (rising_edge(clk)) THEN
				IF (holdKill(0) = '1') THEN
					holdClk(0) := holdClk(0) + 1;
					IF (holdClk(0) = clkprescaler) THEN
						holdClk(0) := 0;
						holdKill(0) <= '0';
					END IF;
				ELSIF (holdKill(1) = '1') THEN
					holdClk(1) := holdClk(1) + 1;
					IF (holdClk(1) = clkprescaler) THEN
						holdClk(1) := 0;
						holdKill(1) <= '0';
					END IF;
				ELSIF (holdKill(2) = '1') THEN
					holdClk(2) := holdClk(2) + 1;
					IF (holdClk(2) = clkprescaler) THEN
						holdClk(2) := 0;
						holdKill(2) <= '0';
					END IF;
				ELSE
					holdClk(0) := 0;
					holdClk(1) := 0;
					holdClk(2) := 0;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	--------------------------------------------------------------------------------------------------------------
	enemyMod(0) <= 2745;
	enemyMod(1) <= 1517;
	enemyMod(2) <= 3000;

	laserMod(0) <= 3500;
	laserMod(1) <= 3250;
	laserMod(2) <= 3750;

	ClkGen : clock_divider PORT MAP(clk_in => clk, clk_out => RandClk);
	------------------------------------------------------------------------------------------------------------------
	--****************************ENEMY GENERATOR CODE**************************************************************
	----------------------------------------------------------
	shootingEnemyDeadReg : PROCESS (clk, waveResetIn)
		VARIABLE WaveresetV : STD_LOGIC := '0';
		VARIABLE clkCountF1 : INTEGER := clk_count;
		VARIABLE deadRegV : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
		VARIABLE resetReady, nextWaveReady : BOOLEAN := false;
	BEGIN
		IF (waveResetIn = '1') THEN
			nextWaveReady := true;
		ELSE
			IF (rising_edge(clk)) THEN
				WaveresetSig <= WaveresetV;
				IF (holdKill(0) = '1') THEN
					deadReg(0) <= '1';

				ELSIF (holdKill(1) = '1') THEN
					deadReg(1) <= '1';

				ELSIF (holdKill(2) = '1') THEN
					deadReg(2) <= '1';
				END IF;

				IF ((deadReg = "111" AND nextWaveReady) OR resetReady) THEN
					clkCountF1 := clkCountF1 + 1;
					IF (clkCountF1 >= 500000000) THEN -- currently 1 second change to 10 seconds?
						clkCountF1 := 0;
						deadReg <= (OTHERS => '0');
						WaveresetV := '0';
						resetReady := false;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	--------------------------------------------------------------------------------------------------
	FireLasers : PROCESS (clk)
		VARIABLE modResult : intArray(2 DOWNTO 0) := 3 & 3 & 3;
		VARIABLE currState2 : INTEGER := to_integer(unsigned(currWait));
		VARIABLE directionVector : point_2D;
		VARIABLE magDirection : INTEGER := 0;
		VARIABLE x_sq, y_sq : INTEGER := 0;
		VARIABLE preSqrt : INTEGER := 0;
		VARIABLE set : intArray(2 DOWNTO 0) := (OTHERS => 0);
		VARIABLE hcountSig1, vcountSig1 : INTEGER;
		VARIABLE EnemyBounds, laserBounds1 : type_bounds;
		VARIABLE x_position1 : INTEGER := 20;
		VARIABLE clkCount21 : intArray(2 DOWNTO 0) := (OTHERS => clk_count);
		VARIABLE setLaser : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
	BEGIN
		IF (rising_edge(clk)) THEN
			EnemyLaserArrayOut <= EnemyLasersSig;
			currState2 := to_integer(unsigned(currWait));
			FOR e IN 0 TO 2 LOOP
				IF (laserDeadReg(e) = '1' OR EnemyLasersSig(e).position.x <= mapEdgeLeft OR EnemyLasersSig(e).position.y <= mapEdgeTop OR EnemyLasersSig(e).position.y >= mapEdgeBottom) THEN
					setLaser(e) := '0';
				END IF;
				modResult(e) := laserMod(e) MOD currState2;
				IF (shootingEnemyArray(e).element_on AND modResult(e) = 0 AND setLaser(e) = '0') THEN
					setLaser(e) := '1';
					enemyLasersSig(e).ObjWidth <= 5;
					enemyLasersSig(e).objHeight <= 3;
					enemyLasersSig(e).position.x <= shootingEnemyArray(e).position.x;
					enemyLasersSig(e).position.y <= shootingEnemyArray(e).position.y;

					enemyLasersSig(e).velocity.x <= (ship.position.x - enemyLasersSig(e).position.x) / 50; -- scaled x component of velocity vector
					enemyLasersSig(e).velocity.y <= (ship.position.y - enemyLasersSig(e).position.y) / 50; -- scaled y component of velocity vector
					enemyLasersSig(e).element_on <= true;
				END IF;
				IF (shootingEnemyArray(e).element_on AND setLaser(e) = '1') THEN
					IF (pause = '1') THEN
						EnemyLasersSig(e).position.x <= EnemyLasersSig(e).position.x;
						EnemyLasersSig(e).position.y <= EnemyLasersSig(e).position.y;
						clkCount21(e) := 0;
					ELSE

						IF (EnemyLasersSig(e).element_on) THEN
							clkCount21(e) := clkCount21(e) + 1;
							IF (clkCount21(e) >= clkPrescaler) THEN
								clkCount21(e) := 0;
								EnemyLasersSig(e).position.x <= EnemyLasersSig(e).position.x + EnemyLasersSig(e).velocity.x;
								EnemyLasersSig(e).position.y <= EnemyLasersSig(e).position.y + EnemyLasersSig(e).velocity.y;
							END IF;
						ELSE
							clkCount21(e) := 0;
							EnemyBounds := createBounds(shootingEnemyArray(e));
							EnemyLasersSig(e).position.x <= EnemyBounds.R;
							EnemyLasersSig(e).position.y <= EnemyBounds.bottom;

						END IF;
					END IF;
				ELSE
					clkCount21(e) := 0;
					EnemyBounds := createBounds(shootingEnemyArray(e));
					EnemyLasersSig(e).position.x <= EnemyBounds.R;
					EnemyLasersSig(e).position.y <= EnemyBounds.bottom;
					EnemyLasersSig(e).velocity.x <= 0;
					EnemyLasersSig(e).velocity.y <= 0;
					EnemyLasersSig(e).element_on <= false;
				END IF;
			END LOOP;
		END IF;
	END PROCESS;

	------------------------------------------------------------------------------------------------------
	ledFix(0) <= deadReg(0);
	ledFix(1) <= deadReg(1);
	ledFix(2) <= deadReg(2);
	ledfix(3) <= EndGame;

	------------------------------------------------------------------------------------------------
	enemyLaserDegReg : PROCESS (clk, EndGame)
		VARIABLE clkCountD11, clkCountD21, clkCountD31 : INTEGER := clk_count;
		VARIABLE deadRegV2 : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
	BEGIN
		IF (EndGame = '1') THEN
			deadRegV2 := (OTHERS => '0');
			clkCountD11 := 0;
			clkCountD21 := 0;
			clkCountD31 := 0;
		ELSE
			IF (rising_edge(clk)) THEN
				laserDeadReg <= deadRegV2;
				IF (killEnemyLaser(0) = '1' OR EnemyLaserArrayOut(0).position.x < 0 OR EnemyLaserArrayOut(0).position.y > mapEdgeBottom OR EnemyLaserArrayOut(0).position.y < mapEdgeTop) THEN
					deadRegV2(0) := '1';
					clkCountD11 := 0;
				ELSIF (killEnemyLaser(1) = '1' OR EnemyLaserArrayOut(1).position.x < 0 OR EnemyLaserArrayOut(1).position.y > mapEdgeBottom OR EnemyLaserArrayOut(1).position.y < mapEdgeTop) THEN
					deadRegV2(1) := '1';
					clkCountD21 := 0;
				ELSIF (killEnemyLaser(2) = '1' OR EnemyLaserArrayOut(2).position.x < 0 OR EnemyLaserArrayOut(2).position.y > mapEdgeBottom OR EnemyLaserArrayOut(2).position.y < mapEdgeTop) THEN
					deadRegV2(2) := '1';
					clkCountD31 := 0;
				END IF;

				IF (deadRegV2(0) = '1') THEN
					clkCountD11 := clkCountD11 + 1;
					IF (clkCountD11 >= 10000) THEN
						deadRegV2(0) := '0';
						clkCountD11 := 0;
					END IF;
				END IF;
				IF (deadRegV2(1) = '1') THEN
					clkCountD21 := clkCountD21 + 1;
					IF (clkCountD21 >= 10000) THEN
						deadRegV2(1) := '0';
						clkCountD21 := 0;
					END IF;
				END IF;

				IF (deadRegV2(2) = '1') THEN
					clkCountD31 := clkCountD31 + 1;
					IF (clkCountD31 >= 10000) THEN
						deadRegV2(2) := '0';
						clkCountD31 := 0;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	-------------------------------------------------------------------------------------------------------------------------
	-- State Register
	StateReg : PROCESS (RandClk)
	BEGIN
		IF (rising_edge(RandClk)) THEN
			IF (EndGame = '0') THEN
				currWait <= NextState;
			ELSE
				currWait <= startState;
			END IF;
		END IF;
	END PROCESS;
	--------------------------------------------------------------------------------------
	wave : PROCESS (clk)
	BEGIN
		IF (rising_edge(Clk)) THEN

			FOR N IN 2 DOWNTO 0 LOOP
				IF (WaveresetSig = '1' OR EndGame = '1') THEN
					stickyReg <= "000";
				ELSE
					IF (stickyReg(N) /= '1') THEN
						stickyReg(N) <= stickyReg(N) XOR setReg(N);
					END IF;
				END IF;
			END LOOP;

			--end if;
		END IF;
	END PROCESS;
	-------------------------------------------------------------------------------------------------
	-- Combination logic
	feedback <= (((currWait(0) XOR currWait(3)) XOR currWait(5)) XOR currWait(11));
	NextState <= feedback & currWait(11 DOWNTO 1);
	--**********************************************************************************************
END ARCHITECTURE;