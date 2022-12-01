------------------------------------------------------------------------------------------------------------------------------------------
-- Project: Defender (DSD Final Project Fall 2021)
-- Author: Blake Martin
-- Date: 11/05/21
------------------------------------------------------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
LIBRARY work;
USE work.graphicsPackage.ALL;
ENTITY enemies IS
	PORT (
		-- Inputs:
		clk : IN STD_LOGIC;
		pause : IN STD_LOGIC := '0';
		EndGame : IN STD_LOGIC := '0';
		killEnemy : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
		hcount : IN INTEGER;
		vcount : IN INTEGER;
		-- Outputs:
		Wavereset : OUT STD_LOGIC;
		small1Pt, small2Pt, small3Pt, Med1Pt, Med2Pt, Med3Pt, big1Pt, big2Pt, big3Pt : OUT INTEGER;
		small1Pos, small2Pos, small3Pos, med1Pos, med2Pos, med3Pos, big1Pos, big2Pos, big3Pos : OUT point_2D;
		small1Vel, small2Vel, small3Vel, Med1Vel, Med2Vel, Med3Vel, Big1Vel, Big2Vel, Big3Vel : OUT point_2D;
		small1On, small2On, Small3On, Med1On, Med2On, Med3On, Big1On, Big2On, Big3On : OUT BOOLEAN;
		small1Width, small2Width, small3Width, Med1Width, Med2Width, Med3Width, big1Width, big2Width, big3Width : OUT INTEGER;
		small1Height, small2Height, small3Height, Med1Height, Med2Height, Med3Height, big1Height, big2Height, big3Height : OUT INTEGER;
		ledfix : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
		waveCountOut : OUT INTEGER := 0

	);
END ENTITY;
ARCHITECTURE enemiesArch OF enemies IS
	------------------------------------------------------------------------------------
	--Enemy Objects:
	SIGNAL smallArray, smallArrayOut : type_gameObjArray(2 DOWNTO 0) := (OTHERS => init_small);
	SIGNAL MedArray, MedArrayOut : type_gameObjArray(2 DOWNTO 0) := (OTHERS => init_med);
	SIGNAL bigArray, BigArrayOut : type_gameObjArray(2 DOWNTO 0) := (OTHERS => init_big);
	SIGNAL deadReg : STD_LOGIC_VECTOR(8 DOWNTO 0) := "000000000";
	SIGNAL WaveResetSig : STD_LOGIC := '0';
	------------------------------------------------------------------------------------
	-- Clks
	SIGNAL clk_Count : INTEGER := 0;
	SIGNAL clkprescaler : INTEGER := 5000000; --50 MHz / clk_prescaler = desired speed
	SIGNAL RandClk : STD_LOGIC := '0';
	------------------------------------------------------------------------------------
	TYPE intArray IS ARRAY(NATURAL RANGE <>) OF INTEGER;
	SIGNAL enemyMod : intArray(8 DOWNTO 0);

	SIGNAL currWait : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '1');
	SIGNAL NextState : STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL feedback : STD_LOGIC;
	SIGNAL startState : STD_LOGIC_VECTOR(11 DOWNTO 0) := "111111111111"; -- intial state
	SIGNAL setReg : STD_LOGIC_VECTOR(8 DOWNTO 0) := "000000000";
	SIGNAL stickyReg : STD_LOGIC_VECTOR(8 DOWNTO 0) := "000000000";
	SIGNAL waveCount : INTEGER := 0;
	SIGNAL holdKill : STD_LOGIC_VECTOR(8 DOWNTO 0) := (OTHERS => '0');

	COMPONENT clock_divider IS PORT (clk_in : IN STD_LOGIC;
		clk_out : OUT STD_LOGIC);
	END COMPONENT;

BEGIN
	Wavereset <= WaveResetSig;
	waveCountOut <= waveCount;
	small1Pt <= smallArrayOut(0).points;
	small2Pt <= smallArrayOut(1).points;
	small3Pt <= smallArrayOut(2).points;
	Med1Pt <= MedArrayOut(0).points;
	Med2Pt <= MedArrayOut(1).points;
	Med3Pt <= MedArrayOut(2).points;
	Big1Pt <= BigArrayOut(0).points;
	Big2Pt <= BigArrayOut(1).points;
	Big3Pt <= BigArrayOut(2).points;
	small1Pos <= smallArrayOut(0).position;
	small2Pos <= smallArrayOut(1).position;
	small3Pos <= smallArrayOut(2).position;
	med1Pos <= MedArrayOut(0).position;
	med2Pos <= MedArrayOut(1).position;
	med3Pos <= MedArrayOut(2).position;
	big1Pos <= BigArrayOut(0).position;
	big2Pos <= BigArrayOut(1).position;
	big3Pos <= BigArrayOut(2).position;
	small1Vel <= SmallArrayOut(0).velocity;
	small2Vel <= SmallArrayOut(1).velocity;
	small3Vel <= SmallArrayOut(2).velocity;
	Med1Vel <= MedArrayOut(0).velocity;
	Med2Vel <= MedArrayOut(1).velocity;
	Med3Vel <= MedArrayOut(2).velocity;
	Big1Vel <= BigArrayOut(0).velocity;
	Big2Vel <= BigArrayOut(1).velocity;
	Big3Vel <= BigArrayOut(2).velocity;
	small1On <= smallArrayOut(0).element_on;
	small2On <= smallArrayOut(1).element_on;
	Small3On <= smallArrayOut(2).element_on;
	Med1On <= MedArrayOut(0).element_on;
	Med2On <= MedArrayOut(1).element_on;
	Med3On <= MedArrayOut(2).element_on;
	Big1On <= BigArrayOut(0).element_on;
	Big2On <= BigArrayOut(1).element_on;
	Big3On <= BigArrayOut(2).element_on;
	small1Width <= smallArrayOut(0).objWidth;
	small2Width <= smallArrayOut(1).objWidth;
	small3Width <= smallArrayOut(2).objWidth;
	Med1Width <= MedArrayOut(0).objWidth;
	Med2Width <= MedArrayOut(1).objWidth;
	Med3Width <= MedArrayOut(2).objWidth;
	big1Width <= BigArrayOut(0).objWidth;
	big2Width <= BigArrayOut(0).objWidth;
	big3Width <= BigArrayOut(0).objWidth;
	small1Height <= smallArrayOut(0).objHeight;
	small2Height <= smallArrayOut(1).objHeight;
	small3Height <= smallArrayOut(2).objHeight;
	Med1Height <= MedArrayOut(0).objHeight;
	Med2Height <= MedArrayOut(1).objHeight;
	Med3Height <= MedArrayOut(2).objHeight;
	big1Height <= BigArrayOut(0).objHeight;
	big2Height <= BigArrayOut(1).objHeight;
	big3Height <= BigArrayOut(2).objHeight;
	--*********BEGIN************************
	----------------------------------------------------

	--**************************** BEGIN POSITIONAL LOGIC********************************************
	nextWave : PROCESS (clk, EndGame)
		VARIABLE resetWaves, setNextWave : BOOLEAN := false;
		VARIABLE setClk, resetClk : INTEGER := 0;
		VARIABLE waveCountV : INTEGER := 0;
	BEGIN
		IF (EndGame = '1') THEN
			setNextWave := false;
			resetWaves := true;
			waveCount <= 0;
			waveCountV := 0;
			setClk := 0;
			resetClk := 0;
		ELSE
			IF (rising_edge(clk)) THEN
				waveCount <= waveCountV;
				IF (WaveResetSig = '1') THEN
					setNextWave := true;
					setClk := 0;
				END IF;
				IF (setNextWave) THEN
					setClk := setClk + 1;
					IF (setClk = 10000000) THEN
						setClk := 0;
						waveCountV := waveCountV + 1;
						setNextWave := false;
					END IF;
				ELSE
					setClk := 0;
				END IF;

				IF (resetWaves) THEN
					resetClk := resetClk + 1;
					IF (resetClk = 10000000) THEN
						resetClk := 0;
						waveCountV := 0;
						resetWaves := false;
						setNextWave := false;
					END IF;
				ELSE
					resetClk := 0;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	animEnemies : PROCESS (clk, EndGame)
		VARIABLE EnemyBounds : type_bounds;
		VARIABLE clkCount1 : INTEGER := clk_count;
		VARIABLE currState : INTEGER := to_integer(unsigned(currWait));
		VARIABLE modVal : intArray(8 DOWNTO 0) := (OTHERS => 0);
		VARIABLE clkCount4 : INTEGER := clk_count;
	BEGIN
		smallArrayOut <= smallArray;
		medArrayOut <= medArray;
		bigArrayOut <= bigArray;
		FOR i IN 0 TO 2 LOOP
			IF (EndGame = '1') THEN
				smallArray(i).position <= smallPos;
				smallArray(i).element_on <= false;
				MedArray(i).position <= medPos;
				MedArray(i).element_on <= false;
				BigArray(i).position <= bigPos;
				bigArray(i).element_on <= false;
				clkCount1 := 0;
			ELSIF (pause = '1') THEN
				IF (smallArray(i).element_on) THEN
					smallArray(i).position.x <= smallArray(i).position.x;
					smallArray(i).position.y <= smallArray(i).position.y;
					smallArray(i).objWidth <= smallWidth;
					smallArray(i).objHeight <= smallHeight;
				END IF;

				IF (MedArray(i).element_on) THEN

					MedArray(i).position.y <= MedArray(i).position.y;
					MedArray(i).objWidth <= MedWidth;
					MedArray(i).objHeight <= MedHeight;
				END IF;

				IF (BigArray(i).element_on) THEN
					BigArray(i).position.x <= BigArray(i).position.x;
					BigArray(i).position.y <= BigArray(i).position.y;
					BigArray(i).objWidth <= BigWidth;
					BigArray(i).objHeight <= BigHeight;
				END IF;

				clkCount1 := 0;

			ELSE
				-- maybe move the deadReg check to each ARRAY
				IF (rising_edge(clk)) THEN
					currState := to_integer(unsigned(currWait));
					modVal(i) := currstate MOD enemyMod(i);
					IF (stickyReg(i) = '0' AND modVal(i + 3) = 0 AND DeadReg(i) = '0' AND waveCount > 1) THEN
						smallArray(i).element_on <= true;
						setReg(i) <= '1';
					ELSIF (deadReg(i) = '1') THEN
						smallArray(i).element_on <= false;
						setReg(i) <= '0';
					END IF;

					modVal(i + 3) := currState MOD enemyMod(i + 3);
					IF (stickyReg(i + 3) = '0' AND modVal(i + 3) = 0 AND deadReg(i + 3) = '0' AND waveCount > 0) THEN
						MedArray(i).element_on <= true;
						setReg(i + 3) <= '1';
					ELSIF (deadReg(i + 3) = '1') THEN
						medArray(i).element_on <= false;
						setReg(i + 3) <= '0';
					END IF;

					modVal(i + 6) := currstate MOD enemyMod(i + 6);
					IF (stickyReg(i + 6) = '0' AND modVal(i + 6) = 0 AND DeadReg(i + 6) = '0') THEN
						setReg(i + 6) <= '1';
						BigArray(i).element_on <= true;
					ELSIF (deadReg(i + 6) = '1') THEN
						bigArray(i).element_on <= false;
						setReg(i + 6) <= '0';
					END IF;

					clkCount1 := clkCount1 + 1;
					IF (clkCount1 >= clkPrescaler) THEN
						clkCount1 := 0;
						IF (smallArray(i).element_on) THEN
							IF (smallArray(i).position.x > 0 AND deadReg(i) = '0') THEN
								smallArray(i).position.x <= smallArray(i).position.x + smallArray(i).velocity.x;
								smallArray(i).velocity.y <= (to_integer(unsigned(currWait)) MOD 4) - 2;
								IF (smallArray(i).velocity.y + smallArray(i).position.y > mapEdgeTop AND smallArray(i).velocity.y + smallArray(i).position.y < mapEdgeBottom) THEN
									smallArray(i).position.y <= smallArray(i).position.y + smallArray(i).velocity.y;
								ELSIF (smallArray(i).velocity.y + smallArray(i).position.y <= mapEdgeTop) THEN
									smallArray(i).velocity.y <= 3;
									smallArray(i).position.y <= smallArray(i).position.y + smallArray(i).velocity.y;
								ELSE
									smallArray(i).velocity.y <= - 3;
									smallArray(i).position.y <= smallArray(i).position.y + smallArray(i).velocity.y;
								END IF;
							ELSIF (deadReg(i) = '0' AND smallArray(i).position.x <= 0) THEN
								smallArray(i).position <= smallPos;
							ELSE
								smallArray(i).position <= smallPos;
								smallArray(i).element_on <= false;
							END IF;
						ELSE
							smallArray(i).position <= smallPos;
						END IF;
						----------------------------------------------
						IF (MedArray(i).element_on) THEN
							IF (MedArray(i).position.x > 0 AND deadReg(i + 3) = '0') THEN
								MedArray(i).position.x <= MedArray(i).position.x + MedArray(i).velocity.x;
								MedArray(i).velocity.y <= ((to_integer(unsigned(currWait)) + 4) MOD 4) - 2;
								IF (MedArray(i).velocity.y + MedArray(i).position.y > mapEdgeTop AND medArray(i).velocity.y + medArray(i).position.y < mapEdgeBottom) THEN
									MedArray(i).position.y <= MedArray(i).position.y + MedArray(i).velocity.y;
								ELSIF (MedArray(i).velocity.y + MedArray(i).position.y <= mapEdgeTop) THEN
									MedArray(i).velocity.y <= 3;
									MedArray(i).position.y <= medArray(i).position.y + medArray(i).velocity.y;
								ELSE
									MedArray(i).velocity.y <= - 3;
									MedArray(i).position.y <= MedArray(i).position.y + MedArray(i).velocity.y;
								END IF;
							ELSIF (deadReg(i + 3) = '0' AND MedArray(i).position.x <= 0) THEN
								MedArray(i).position <= medPos;
							ELSE
								medArray(i).position <= medPos;
								medArray(i).element_on <= false;
							END IF;
						ELSE
							medArray(i).position <= medPos;
						END IF;
						-----------------------------------------------
						IF (BigArray(i).element_on) THEN
							IF (BigArray(i).position.x > 0 AND deadReg(i + 6) = '0') THEN
								bigArray(i).position.x <= bigArray(i).position.x + bigArray(i).velocity.x;
								bigArray(i).velocity.y <= ((to_integer(unsigned(currWait)) + 1037) MOD 4) - 2;
								IF (bigArray(i).velocity.y + bigArray(i).position.y > mapEdgeTop AND bigArray(i).velocity.y + bigArray(i).position.y < mapEdgeBottom) THEN
									bigArray(i).position.y <= bigArray(i).position.y + bigArray(i).velocity.y;
								ELSIF (MedArray(i).velocity.y + bigArray(i).position.y <= mapEdgeTop) THEN
									bigArray(i).velocity.y <= 3;
									bigArray(i).position.y <= bigArray(i).position.y + bigArray(i).velocity.y;
								ELSE
									bigArray(i).velocity.y <= - 3;
									bigArray(i).position.y <= bigArray(i).position.y + bigArray(i).velocity.y;
								END IF;
							ELSIF (deadReg(i + 6) = '0' AND bigArray(i).position.x < 0) THEN
								bigArray(i).position <= bigPos;
							ELSE
								bigArray(i).position <= bigPos;
								bigArray(i).element_on <= false;

							END IF;
						ELSE
							bigArray(i).position <= bigPos;

						END IF;
					END IF;
				END IF;
			END IF;
		END LOOP;
	END PROCESS;

	--------------------------------------------------------------------------------------------------------------
	enemyMod(0) <= 2300; --2700 small enemy
	enemyMod(1) <= 2200; -- 2200 small enemy
	enemyMod(2) <= 2100; -- 1500 small enemy
	enemyMod(3) <= 1500;
	enemyMod(4) <= 1350;
	enemyMod(5) <= 1200;
	enemyMod(6) <= 1300;
	enemyMod(7) <= 1250;
	enemyMod(8) <= 1000;

	ClkGen : clock_divider PORT MAP(clk_in => clk, clk_out => RandClk);
	------------------------------------------------------------------------------------------------------------------

	-- State Register
	StateReg : PROCESS (RandClk, Endgame, WaveResetSig)
	BEGIN
		IF (EndGame = '1' OR WaveResetSig = '1') THEN
			currWait <= startState;
		ELSE
			IF (rising_edge(RandClk)) THEN
				currWait <= NextState;
			END IF;
		END IF;
	END PROCESS;
	-----------------------------------------------------------------------------------------------------------
	holdKillProcess : PROCESS (killEnemy(0), killEnemy(1), killEnemy(2), killEnemy(3), killEnemy(4), killEnemy(5), killEnemy(6), killEnemy(7), killEnemy(8), EndGame, clk)
		VARIABLE holdClk : intArray(8 DOWNTO 0) := (OTHERS => 0);
	BEGIN
		IF (EndGame = '1') THEN
			holdKill <= (OTHERS => '1');
		ELSIF (killEnemy(0) = '1') THEN
			holdKill(0) <= '1';
		ELSIF (killEnemy(1) = '1') THEN
			holdKill(1) <= '1';
		ELSIF (killEnemy(2) = '1') THEN
			holdKill(2) <= '1';
		ELSIF (killEnemy(3) = '1') THEN
			holdKill(3) <= '1';
		ELSIF (killEnemy(4) = '1') THEN
			holdKill(4) <= '1';
		ELSIF (killEnemy(5) = '1') THEN
			holdKill(5) <= '1';
		ELSIF (killEnemy(6) = '1') THEN
			holdKill(6) <= '1';
		ELSIF (killEnemy(7) = '1') THEN
			holdKill(7) <= '1';
		ELSIF (killEnemy(8) = '1') THEN
			holdKill(8) <= '1';
		ELSE
			IF (rising_edge(clk)) THEN
				IF (holdKill(0) = '1') THEN
					holdClk(0) := holdClk(0) + 1;
					IF (holdClk(0) = 10000) THEN
						holdClk(0) := 0;
						holdKill(0) <= '0';
					END IF;
				ELSIF (holdKill(1) = '1') THEN
					holdClk(1) := holdClk(1) + 1;
					IF (holdClk(1) = 10000) THEN
						holdClk(1) := 0;
						holdKill(1) <= '0';
					END IF;
				ELSIF (holdKill(2) = '1') THEN
					holdClk(2) := holdClk(2) + 1;
					IF (holdClk(2) = 10000) THEN
						holdClk(2) := 0;
						holdKill(2) <= '0';
					END IF;
				ELSIF (holdKill(3) = '1') THEN
					holdClk(3) := holdClk(3) + 1;
					IF (holdClk(3) = 10000) THEN
						holdClk(3) := 0;
						holdKill(3) <= '0';
					END IF;
				ELSIF (holdKill(4) = '1') THEN
					holdClk(4) := holdClk(4) + 1;
					IF (holdClk(4) = 10000) THEN
						holdClk(4) := 0;
						holdKill(4) <= '0';
					END IF;
				ELSIF (holdKill(5) = '1') THEN
					holdClk(5) := holdClk(5) + 1;
					IF (holdClk(5) = 10000) THEN
						holdClk(5) := 0;
						holdKill(5) <= '0';
					END IF;
				ELSIF (holdKill(6) = '1') THEN
					holdClk(6) := holdClk(6) + 1;
					IF (holdClk(6) = 10000) THEN
						holdClk(6) := 0;
						holdKill(6) <= '0';
					END IF;
				ELSIF (holdKill(7) = '1') THEN
					holdClk(7) := holdClk(7) + 1;
					IF (holdClk(7) = 10000) THEN
						holdClk(7) := 0;
						holdKill(7) <= '0';
					END IF;
				ELSIF (holdKill(8) = '1') THEN
					holdClk(8) := holdClk(8) + 1;
					IF (holdClk(8) = 10000) THEN
						holdClk(8) := 0;
						holdKill(8) <= '0';
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	----------------------------------------------------------------------------------------------------------------------

	PROCESS (clk, EndGame)
		VARIABLE resetV : STD_LOGIC := '0';
		VARIABLE clkCountF : INTEGER := clk_count;
	BEGIN
		IF (EndGame = '1') THEN
			smallArray(0).velocity.x <= - 5;
			smallArray(1).velocity.x <= - 5;
			smallArray(2).velocity.x <= - 5;
			MedArray(0).velocity.x <= - 4;
			MedArray(1).velocity.x <= - 4;
			MedArray(2).velocity.x <= - 4;
			BigArray(0).velocity.x <= - 3;
			BigArray(1).velocity.x <= - 3;
			BigArray(2).velocity.x <= - 3;
			WaveResetSig <= '1';

			clkCountF := 0;
		ELSE
			IF (rising_edge(clk)) THEN
				IF (holdKill(0) = '1') THEN
					deadReg(0) <= '1';
				ELSIF (holdKill(1) = '1') THEN
					deadReg(1) <= '1';
				ELSIF (holdKill(2) = '1') THEN
					deadReg(2) <= '1';
				ELSIF (holdKill(3) = '1') THEN
					deadReg(3) <= '1';
				ELSIF (holdKill(4) = '1') THEN
					deadReg(4) <= '1';
				ELSIF (holdKill(5) = '1') THEN
					deadReg(5) <= '1';
				ELSIF (holdKill(6) = '1') THEN
					deadReg(6) <= '1';
				ELSIF (holdKill(7) = '1') THEN
					deadReg(7) <= '1';
				ELSIF (holdKill(8) = '1') THEN
					deadReg(8) <= '1';
				END IF;

				IF (waveCount = 0) THEN
					IF (deadReg(8 DOWNTO 6) = "111") THEN
						clkCountF := clkCountF + 1;
						WaveResetSig <= '1';
						IF (clkCountF >= 100000) THEN
							clkCountF := 0;
							WaveResetSig <= '0';
							deadReg <= (OTHERS => '0');
							FOR g IN 0 TO 2 LOOP
								bigArray(g).velocity.x <= bigArray(g).velocity.x - 2;
							END LOOP;
						END IF;
					END IF;
				ELSIF (waveCount = 1) THEN
					IF (deadReg(8 DOWNTO 3) = "111111") THEN
						clkCountF := clkCountF + 1;
						WaveResetSig <= '1';
						IF (clkCountF >= 100000) THEN
							clkCountF := 0;
							deadReg <= (OTHERS => '0');
							WaveResetSig <= '0';
							FOR g IN 0 TO 2 LOOP
								MedArray(g).velocity.x <= MedArray(g).velocity.x - 2;
								bigArray(g).velocity.x <= bigArray(g).velocity.x - 2;
							END LOOP;
						END IF;
					END IF;
				ELSIF (waveCount > 1) THEN
					IF (deadReg = "111111111") THEN
						clkCountF := clkCountF + 1;
						WaveResetSig <= '1';
						IF (clkCountF >= 100000) THEN
							clkCountF := 0;
							deadReg <= (OTHERS => '0');
							WaveResetSig <= '0';
							FOR g IN 0 TO 2 LOOP
								smallArray(g).velocity.x <= smallArray(g).velocity.x - 2;
								IF (smallArray(g).velocity.x >= - 4) THEN
									smallArray(g).velocity.x <= - 4;
								END IF;
								MedArray(g).velocity.x <= MedArray(g).velocity.x - 2;
								IF (MedArray(g).velocity.x >= - 4) THEN
									MedArray(g).velocity.x <= - 4;
								END IF;
								bigArray(g).velocity.x <= bigArray(g).velocity.x - 2;
								IF (bigArray(g).velocity.x >= - 4) THEN
									bigArray(g).velocity.x <= - 4;
								END IF;
							END LOOP;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	ledFix(0) <= deadReg(0);
	ledFix(1) <= deadReg(1);
	ledFix(2) <= deadReg(2);
	ledFix(3) <= deadReg(3);
	ledFix(4) <= deadReg(4);
	ledFix(5) <= deadReg(5);
	ledFix(6) <= deadReg(6);
	ledFix(7) <= deadReg(7);
	ledFix(8) <= deadReg(8);

	--------------------------------------------------------------------------------------
	wave : PROCESS (clk)
		VARIABLE clkCount3 : INTEGER := clk_count;
	BEGIN
		IF (rising_edge(Clk)) THEN
			FOR N IN 8 DOWNTO 0 LOOP
				IF (WaveResetSig = '1' OR EndGame = '1') THEN
					stickyReg <= "000000000";
				ELSIF (holdKill(N) = '1') THEN
					stickyReg(N) <= '0';
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
	feedback <= (((currWait(0) XOR currWait(3)) XOR currWait(5)) XOR currWait(11));
	NextState <= feedback & currWait(11 DOWNTO 1);
	--**********************************************************************************************
END ARCHITECTURE;