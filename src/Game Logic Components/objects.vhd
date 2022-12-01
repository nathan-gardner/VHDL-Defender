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
ENTITY objects IS
	PORT (
		-- inputs:
		clk : IN STD_LOGIC;
		pause : IN STD_LOGIC := '0';
		EndGame : IN STD_LOGIC := '0';
		hcount : IN INTEGER;
		vcount : IN INTEGER;
		killObject : IN STD_LOGIC_VECTOR(0 TO 4);
		M1Pt, M2Pt, M3Pt, M4Pt, M5Pt : OUT INTEGER;
		M1Pos, M2Pos, M3Pos, M4Pos, M5Pos : OUT point_2D;
		M1Vel, M2Vel, M3Vel, M4Vel, M5Vel : OUT point_2D;
		M1On, M2On, M3On, M4On, M5On : OUT BOOLEAN;
		M1Width, M2Width, M3Width, M4Width, M5Width : OUT INTEGER;
		M1Height, M2Height, M3Height, M4Height, M5Height : OUT INTEGER;
		ledfix : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
	);
END ENTITY;
ARCHITECTURE obj OF objects IS
	-------------------------------------------------------------------------------
	--Enemy Objects:
	SIGNAL MarrayOut, MArray : type_gameObjArray(0 TO 4) := init_obj1 & init_obj2 & init_obj3 & init_obj4 & init_obj5;
	SIGNAL EndGameSig : STD_LOGIC := '0';
	TYPE intArray IS ARRAY(NATURAL RANGE <>) OF INTEGER;
	SIGNAL objMod : intArray(0 TO 4);
	-----------------------------------------------------------------------------
	SIGNAL clk_Count : INTEGER := 0;
	SIGNAL clkprescaler : INTEGER := 5000000; --50 MHz / clk_prescaler = desired speed
	SIGNAL deadReg : STD_LOGIC_VECTOR(0 TO 4);
	--**************************************************************************
	SIGNAL currWait : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '1');
	SIGNAL NextState : STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL feedback : STD_LOGIC;

	SIGNAL startState : STD_LOGIC_VECTOR(11 DOWNTO 0) := "111111111111"; -- intial state

	SIGNAL setReg : STD_LOGIC_VECTOR(0 TO 4) := "00000";
	SIGNAL stickyReg : STD_LOGIC_VECTOR(0 TO 4) := "00000";
	SIGNAL RandClk : STD_LOGIC := '0';
	SIGNAL resetSig : STD_LOGIC := '0';

	COMPONENT clock_divider IS PORT (clk_in : IN STD_LOGIC;
		clk_out : OUT STD_LOGIC);
	END COMPONENT;

BEGIN

	M1Pt <= MarrayOut(0).points;
	M2Pt <= MarrayOut(1).points;
	M3Pt <= MarrayOut(2).points;
	M4Pt <= MarrayOut(3).points;
	M5Pt <= MarrayOut(4).points;

	M1Pos <= MarrayOut(0).position;
	M2Pos <= MarrayOut(1).position;
	M3Pos <= MarrayOut(2).position;
	M4Pos <= MarrayOut(3).position;
	M5Pos <= MarrayOut(4).position;

	M1Vel <= MarrayOut(0).velocity;
	M2Vel <= MarrayOut(1).velocity;
	M3Vel <= MarrayOut(2).velocity;
	M4Vel <= MarrayOut(3).velocity;
	M5Vel <= MarrayOut(4).velocity;

	M1On <= MarrayOut(0).element_on;
	M2On <= MarrayOut(1).element_on;
	M3On <= MarrayOut(2).element_on;
	M4On <= MarrayOut(3).element_on;
	M5On <= MarrayOut(4).element_on;
	M1Width <= MarrayOut(0).objWidth;
	M2Width <= MarrayOut(1).objWidth;
	M3Width <= MarrayOut(2).objWidth;
	M4Width <= MarrayOut(3).objWidth;
	M5Width <= MarrayOut(4).objWidth;

	M1Height <= MarrayOut(0).objHeight;
	M2Height <= MarrayOut(1).objHeight;
	M3Height <= MarrayOut(2).objHeight;
	M4Height <= MarrayOut(3).objHeight;
	M5Height <= MarrayOut(4).objHeight;

	--**************************** BEGIN POSITIONAL LOGIC********************************************
	animObjects : PROCESS (clk, EndGame, Pause)
		VARIABLE objBounds : type_bounds;
		VARIABLE clkCount1 : INTEGER := clk_count;
		VARIABLE currState : INTEGER := to_integer(unsigned(currWait));
		VARIABLE modVal : INTEGER;
		VARIABLE clkCount4 : INTEGER := clk_count;
	BEGIN
		MarrayOut <= MArray;
		FOR i IN 0 TO 4 LOOP
			IF (EndGame = '1') THEN
				MArray(i).element_on <= false;
				MArray(i).position.x <= 645;
				clkCount1 := 0;
			ELSIF (pause = '1') THEN
				IF (MArray(i).element_on) THEN
					MArray(i).position.x <= MArray(i).position.x;
					MArray(i).position.y <= MArray(i).position.y;
					MArray(i).velocity <= obj_velo;
					MArray(i).objWidth <= objectWidth;
					MArray(i).objHeight <= objectHeight;
				END IF;
				clkCount1 := 0;
			ELSE
				IF (rising_edge(clk)) THEN
					currState := to_integer(unsigned(currWait));
					modVal := currstate MOD objMod(i);
					IF (stickyReg(i) = '0' AND modVal = 0 AND DeadReg(i) = '0') THEN
						MArray(i).element_on <= true;
					ELSIF (deadReg(i) = '1') THEN
						MArray(i).element_on <= false;
					END IF;
					clkCount1 := clkCount1 + 1;
					IF (clkCount1 >= clkPrescaler) THEN
						clkCount1 := 0;
						IF (MArray(i).element_on) THEN
							IF (MArray(i).position.x > 0 AND deadReg(i) = '0') THEN
								MArray(i).position.x <= MArray(i).position.x + MArray(i).velocity.x;
							ELSE
								MArray(i).position.x <= 645;
								MArray(i).element_on <= false;
							END IF;
						ELSE
							MArray(i).position.x <= 645;
						END IF;
					END IF;
				END IF;
			END IF;
		END LOOP;
	END PROCESS;

	--------------------------------------------------------------------------------------------------------------
	objMod(0) <= 1900;
	objMod(1) <= 3000;
	objMod(2) <= 3500;
	objMod(3) <= 2100;
	objMod(4) <= 1400;

	ClkGen : clock_divider PORT MAP(clk_in => clk, clk_out => RandClk);

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
	PROCESS (clk, EndGame)
		VARIABLE deadRegV : STD_LOGIC_VECTOR(0 TO 4) := (OTHERS => '0');
		VARIABLE ResetV : STD_LOGIC := '0';
		VARIABLE clkCountF : INTEGER := clk_count;
	BEGIN
		IF (EndGame = '1') THEN
			deadRegV := (OTHERS => '1');
		ELSE
			IF (rising_edge(clk)) THEN
				clkCountF := clkCountF + 1;
				deadReg <= deadRegV;
				ResetSig <= ResetV;
				IF (killObject(0) = '1') THEN
					deadRegV(0) := '1';
					clkCountF := 0;
				ELSIF (killObject(1) = '1') THEN
					deadRegV(1) := '1';
					clkCountF := 0;
				ELSIF (killObject(2) = '1') THEN
					deadRegV(2) := '1';
					clkCountF := 0;
				ELSIF (killObject(3) = '1') THEN
					deadRegV(3) := '1';
					clkCountF := 0;
				ELSIF (killObject(4) = '1') THEN
					deadRegV(4) := '1';
					clkCountF := 0;
				END IF;

				IF (deadRegV = "11111") THEN
					resetV := '1';
					clkCountF := clkCountF + 1;
					IF (clkCountF >= 1000) THEN
						clkCountF := 0;
						deadRegV := (OTHERS => '0');
						ResetV := '0';
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

	--------------------------------------------------------------------------------------
	wave : PROCESS (clk)
		VARIABLE clkCount3 : INTEGER := clk_count;
	BEGIN
		IF (rising_edge(Clk)) THEN
			FOR N IN 0 TO 4 LOOP
				IF (ResetSig = '1' OR EndGame = '1') THEN
					stickyReg <= "00000";
				ELSE
					IF (stickyReg(N) /= '1') THEN
						stickyReg(N) <= stickyReg(N) XOR setReg(N);
					END IF;
				END IF;
			END LOOP;
		END IF;
	END PROCESS;
	-------------------------------------------------------------------------------------------------
	feedback <= (((currWait(0) XOR currWait(3)) XOR currWait(5)) XOR currWait(11));
	NextState <= feedback & currWait(11 DOWNTO 1);
	--**********************************************************************************************
END ARCHITECTURE;