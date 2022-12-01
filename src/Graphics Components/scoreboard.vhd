LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.std_logic_1164.ALL;
USE IEEE.Std_logic_Arith.ALL;
USE work.graphicsPackage.ALL;

ENTITY scoreboard IS
	PORT (
		score : IN INTEGER RANGE 0 TO 999;
		lives : IN INTEGER RANGE 0 TO 3;
		clk : IN STD_LOGIC;
		hcount : IN INTEGER;
		vcount : IN INTEGER;
		scoreboard_out : OUT scoreboard_data := init_scoreboard;
		pause : IN STD_LOGIC;
		waveCount : IN INTEGER
	);

END ENTITY;

ARCHITECTURE myscoreboard OF scoreboard IS

	COMPONENT fontROM IS
		GENERIC (
			addrWidth : INTEGER := 11;
			dataWidth : INTEGER := 8
		);
		PORT (
			clkA : IN STD_LOGIC;
			writeEnableA : IN STD_LOGIC;
			addrA : IN STD_LOGIC_VECTOR(addrWidth - 1 DOWNTO 0);
			dataOutA : OUT STD_LOGIC_VECTOR(dataWidth - 1 DOWNTO 0);
			dataInA : IN STD_LOGIC_VECTOR(dataWidth - 1 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT binary_to_bcd IS
		GENERIC (
			bits : INTEGER := 10; --size of the binary input numbers in bits
			digits : INTEGER := 3); --number of BCD digits to convert to
		PORT (
			clk : IN STD_LOGIC; --system clock
			reset_n : IN STD_LOGIC; --active low asynchronus reset
			ena : IN STD_LOGIC; --latches in new binary number and starts conversion
			binary : IN STD_LOGIC_VECTOR(bits - 1 DOWNTO 0); --binary number to convert
			busy : OUT STD_LOGIC; --indicates conversion in progress
			bcd : OUT STD_LOGIC_VECTOR(digits * 4 - 1 DOWNTO 0)); --resulting BCD number
	END COMPONENT;

	---- FONT INFORMATION ----
	SIGNAL fontAddrIn4, fontAddrIn3, fontAddrIn2, fontAddrIn1, fontAddrIn0 : STD_LOGIC_VECTOR(10 DOWNTO 0);
	SIGNAL fontDataOut4, fontDataOut3, fontDataOut2, fontDataOut1, fontDataOut0 : STD_LOGIC_VECTOR(0 TO 7);

	SIGNAL pixelOn : BOOLEAN;
	--------------------------

	SIGNAL numDigitElements : INTEGER := 20;
	SIGNAL scoreChar : type_scoreArray(0 TO 36) := (OTHERS => ("0101010", 4, 20, 0, 0, '0', '0'));

	--signal testInt, testIntBuffer : integer := 1234;
	--signal romOpCode0, romOpCode1, romOpCode2 : std_logic_vector(6 downto 0);

	--signal zeroDigit, onesDigit, twosDigit, threesDigit : integer;
	---- Binary to BCD ----
	SIGNAL clkCount : INTEGER := 0;
	SIGNAL numBits : INTEGER := 10;
	SIGNAL numDigits : INTEGER := 3;
	SIGNAL bin_bcd_Ena : STD_LOGIC := '0';
	SIGNAL binaryIn : STD_LOGIC_VECTOR(numBits - 1 DOWNTO 0);
	SIGNAL busySig : STD_LOGIC;
	SIGNAL bcdOut : STD_LOGIC_VECTOR(numDigits * 4 - 1 DOWNTO 0);
	SIGNAL clkpll : STD_LOGIC := '0';
	-----------------------

BEGIN

	--- define left and right bounds for digits ---
	scoreChar(30).score_left <= 514; -- #
	scoreChar(30).score_right <= 522;
	scoreChar(31).score_left <= 504; -- SPACE
	scoreChar(31).score_right <= 512;
	scoreChar(32).score_left <= 494; -- :
	scoreChar(32).score_right <= 502;
	scoreChar(33).score_left <= 484; -- e
	scoreChar(33).score_right <= 492;
	scoreChar(34).score_left <= 474; -- v
	scoreChar(34).score_right <= 482;
	scoreChar(35).score_left <= 464; -- a
	scoreChar(35).score_right <= 472;
	scoreChar(36).score_left <= 454; -- W
	scoreChar(36).score_right <= 462;

	scoreChar(29).score_left <= 10;
	scoreChar(29).score_right <= 18;
	scoreChar(28).score_left <= 20;
	scoreChar(28).score_right <= 28;
	scoreChar(27).score_left <= 30;
	scoreChar(27).score_right <= 38;
	scoreChar(26).score_left <= 40;
	scoreChar(26).score_right <= 48;
	scoreChar(25).score_left <= 50;
	scoreChar(25).score_right <= 58;
	scoreChar(24).score_left <= 60;
	scoreChar(24).score_right <= 68;
	scoreChar(23).score_left <= 70;
	scoreChar(23).score_right <= 78;
	scoreChar(22).score_left <= 80;
	scoreChar(22).score_right <= 88;
	scoreChar(21).score_left <= 90;
	scoreChar(21).score_right <= 98;
	scoreChar(20).score_left <= 100;
	scoreChar(20).score_right <= 108;
	scoreChar(19).score_left <= 271;
	scoreChar(19).score_right <= 279;
	scoreChar(18).score_left <= 281;
	scoreChar(18).score_right <= 289;
	scoreChar(17).score_left <= 291;
	scoreChar(17).score_right <= 299;
	scoreChar(16).score_left <= 301;
	scoreChar(16).score_right <= 309;
	scoreChar(15).score_left <= 311;
	scoreChar(15).score_right <= 319;
	scoreChar(14).score_left <= 321;
	scoreChar(14).score_right <= 329;
	scoreChar(13).score_left <= 331;
	scoreChar(13).score_right <= 339;
	scoreChar(12).score_left <= 341;
	scoreChar(12).score_right <= 349;
	scoreChar(11).score_left <= 351;
	scoreChar(11).score_right <= 359;
	scoreChar(10).score_left <= 361;
	scoreChar(10).score_right <= 369;
	scoreChar(9).score_left <= 532;
	scoreChar(9).score_right <= 540;
	scoreChar(8).score_left <= 542;
	scoreChar(8).score_right <= 550;
	scoreChar(7).score_left <= 552;
	scoreChar(7).score_right <= 560;
	scoreChar(6).score_left <= 562;
	scoreChar(6).score_right <= 570;
	scoreChar(5).score_left <= 572;
	scoreChar(5).score_right <= 580;
	scoreChar(4).score_left <= 582;
	scoreChar(4).score_right <= 590;
	scoreChar(3).score_left <= 592;
	scoreChar(3).score_right <= 600;
	scoreChar(2).score_left <= 602;
	scoreChar(2).score_right <= 610;
	scoreChar(1).score_left <= 612;
	scoreChar(1).score_right <= 620;
	scoreChar(0).score_left <= 622;
	scoreChar(0).score_right <= 630;
	-----------------------------------------------
	scoreChar(3).score_rom_opcode <= "0000000"; -- SPACE
	scoreChar(4).score_rom_opcode <= "0111010"; -- :
	scoreChar(5).score_rom_opcode <= "1100101"; -- e
	scoreChar(6).score_rom_opcode <= "1110010"; -- r
	scoreChar(7).score_rom_opcode <= "1101111"; -- o
	scoreChar(8).score_rom_opcode <= "1100011"; -- c
	scoreChar(9).score_rom_opcode <= "1010011"; -- S
	--scoreChar(10).score_rom_opcode <= "0001111"; -- *   -- SPACE
	--scoreChar(11).score_rom_opcode <= "1010010"; -- R   -- SPACE
	--scoreChar(12).score_rom_opcode <= "1000101"; -- E   -- E
	--scoreChar(13).score_rom_opcode <= "1000100"; -- D   -- S
	--scoreChar(14).score_rom_opcode <= "1001110"; -- N   -- U
	--scoreChar(15).score_rom_opcode <= "1000101"; -- E   -- A
	--scoreChar(16).score_rom_opcode <= "1000110"; -- F   -- P
	--scoreChar(17).score_rom_opcode <= "1000101"; -- E   -- SPACE
	--scoreChar(18).score_rom_opcode <= "1000100"; -- D   -- SPACE
	--scoreChar(19).score_rom_opcode <= "0001111"; -- *   -- SPACE

	--scoreChar(30).score_rom_opcode <= "1001100"; -- #
	scoreChar(31).score_rom_opcode <= "0000000"; -- SPACE
	scoreChar(32).score_rom_opcode <= "0111010"; -- :
	scoreChar(33).score_rom_opcode <= "1100101"; -- e
	scoreChar(34).score_rom_opcode <= "1110110"; -- v
	scoreChar(35).score_rom_opcode <= "1100001"; -- a
	scoreChar(36).score_rom_opcode <= "1010111"; -- W

	scoreChar(20).score_rom_opcode <= "0000011"; -- heart
	scoreChar(21).score_rom_opcode <= "0000011"; -- heart
	scoreChar(22).score_rom_opcode <= "0000011"; -- heart
	scoreChar(23).score_rom_opcode <= "0000000"; -- SPACE
	scoreChar(24).score_rom_opcode <= "0111010"; -- :
	scoreChar(25).score_rom_opcode <= "1110011"; -- s
	scoreChar(26).score_rom_opcode <= "1100101"; -- e
	scoreChar(27).score_rom_opcode <= "1110110"; -- v
	scoreChar(28).score_rom_opcode <= "1101001"; -- i
	scoreChar(29).score_rom_opcode <= "1001100"; -- L
	charSet0 : ENTITY work.fontROM
		GENERIC MAP(
			addrWidth => 11,
			dataWidth => 8
		)
		PORT MAP(
			clkA => clk,
			writeEnableA => '0', -- never write
			addrA => fontAddrIn0,
			dataOutA => fontDataOut0,
			dataInA => (OTHERS => '0')
		);

	charSet1 : ENTITY work.fontROM
		GENERIC MAP(
			addrWidth => 11,
			dataWidth => 8
		)
		PORT MAP(
			clkA => clk,
			writeEnableA => '0', -- never write
			addrA => fontAddrIn1,
			dataOutA => fontDataOut1,
			dataInA => (OTHERS => '0')
		);

	charSet2 : ENTITY work.fontROM
		GENERIC MAP(
			addrWidth => 11,
			dataWidth => 8
		)
		PORT MAP(
			clkA => clk,
			writeEnableA => '0', -- never write
			addrA => fontAddrIn2,
			dataOutA => fontDataOut2,
			dataInA => (OTHERS => '0')
		);

	charSet3 : ENTITY work.fontROM
		GENERIC MAP(
			addrWidth => 11,
			dataWidth => 8
		)
		PORT MAP(
			clkA => clk,
			writeEnableA => '0', -- never write
			addrA => fontAddrIn3,
			dataOutA => fontDataOut3,
			dataInA => (OTHERS => '0')
		);

	charSet4 : ENTITY work.fontROM
		GENERIC MAP(
			addrWidth => 11,
			dataWidth => 8
		)
		PORT MAP(
			clkA => clk,
			writeEnableA => '0', -- never write
			addrA => fontAddrIn4,
			dataOutA => fontDataOut4,
			dataInA => (OTHERS => '0')
		);

	bin_to_bcd : ENTITY work.binary_to_bcd

		GENERIC MAP(
			bits => 10, --size of the binary input numbers in bits
			digits => 3) --number of BCD digits to convert to
		PORT MAP(
			clk => clk, --system clock
			reset_n => '1', --active low asynchronus reset
			ena => '1', --latches in new binary number and starts conversion
			binary => binaryIn, --binary number to convert
			busy => busySig, --indicates conversion in progress
			bcd => bcdOut); --resulting BCD number

	binaryIn <= conv_std_logic_vector(score, binaryIn'length); -- convert score integer to std_logic_vector

	scoreOutput : PROCESS (clk)
	BEGIN
		IF (rising_edge(clk)) THEN
			CASE(bcdOut(3 DOWNTO 0)) IS
				WHEN "0000" => scoreChar(0).score_rom_opcode <= "0110000";
				WHEN "0001" => scoreChar(0).score_rom_opcode <= "0110001";
				WHEN "0010" => scoreChar(0).score_rom_opcode <= "0110010";
				WHEN "0011" => scoreChar(0).score_rom_opcode <= "0110011";
				WHEN "0100" => scoreChar(0).score_rom_opcode <= "0110100";
				WHEN "0101" => scoreChar(0).score_rom_opcode <= "0110101";
				WHEN "0110" => scoreChar(0).score_rom_opcode <= "0110110";
				WHEN "0111" => scoreChar(0).score_rom_opcode <= "0110111";
				WHEN "1000" => scoreChar(0).score_rom_opcode <= "0111000";
				WHEN "1001" => scoreChar(0).score_rom_opcode <= "0111001";
				WHEN OTHERS => scoreChar(0).score_rom_opcode <= "0101010";
			END CASE;

			CASE(bcdOut(7 DOWNTO 4)) IS
				WHEN "0000" => scoreChar(1).score_rom_opcode <= "0110000";
				WHEN "0001" => scoreChar(1).score_rom_opcode <= "0110001";
				WHEN "0010" => scoreChar(1).score_rom_opcode <= "0110010";
				WHEN "0011" => scoreChar(1).score_rom_opcode <= "0110011";
				WHEN "0100" => scoreChar(1).score_rom_opcode <= "0110100";
				WHEN "0101" => scoreChar(1).score_rom_opcode <= "0110101";
				WHEN "0110" => scoreChar(1).score_rom_opcode <= "0110110";
				WHEN "0111" => scoreChar(1).score_rom_opcode <= "0110111";
				WHEN "1000" => scoreChar(1).score_rom_opcode <= "0111000";
				WHEN "1001" => scoreChar(1).score_rom_opcode <= "0111001";
				WHEN OTHERS => scoreChar(1).score_rom_opcode <= "0101010";
			END CASE;

			CASE(bcdOut(11 DOWNTO 8)) IS
				WHEN "0000" => scoreChar(2).score_rom_opcode <= "0110000";
				WHEN "0001" => scoreChar(2).score_rom_opcode <= "0110001";
				WHEN "0010" => scoreChar(2).score_rom_opcode <= "0110010";
				WHEN "0011" => scoreChar(2).score_rom_opcode <= "0110011";
				WHEN "0100" => scoreChar(2).score_rom_opcode <= "0110100";
				WHEN "0101" => scoreChar(2).score_rom_opcode <= "0110101";
				WHEN "0110" => scoreChar(2).score_rom_opcode <= "0110110";
				WHEN "0111" => scoreChar(2).score_rom_opcode <= "0110111";
				WHEN "1000" => scoreChar(2).score_rom_opcode <= "0111000";
				WHEN "1001" => scoreChar(2).score_rom_opcode <= "0111001";
				WHEN OTHERS => scoreChar(2).score_rom_opcode <= "0101010";
			END CASE;

			CASE(pause) IS
				WHEN '0' =>
				scoreChar(10).score_rom_opcode <= "0001111"; -- *
				scoreChar(11).score_rom_opcode <= "1010010"; -- R
				scoreChar(12).score_rom_opcode <= "1000101"; -- E
				scoreChar(13).score_rom_opcode <= "1000100"; -- D
				scoreChar(14).score_rom_opcode <= "1001110"; -- N
				scoreChar(15).score_rom_opcode <= "1000101"; -- E
				scoreChar(16).score_rom_opcode <= "1000110"; -- F
				scoreChar(17).score_rom_opcode <= "1000101"; -- E
				scoreChar(18).score_rom_opcode <= "1000100"; -- D
				scoreChar(19).score_rom_opcode <= "0001111"; -- *
				WHEN '1' =>
				scoreChar(10).score_rom_opcode <= "0000000"; -- SPACE
				scoreChar(11).score_rom_opcode <= "0000000"; -- SPACE
				scoreChar(12).score_rom_opcode <= "1000101"; -- E
				scoreChar(13).score_rom_opcode <= "1010011"; -- S
				scoreChar(14).score_rom_opcode <= "1010101"; -- U
				scoreChar(15).score_rom_opcode <= "1000001"; -- A
				scoreChar(16).score_rom_opcode <= "1010000"; -- P
				scoreChar(17).score_rom_opcode <= "0000000"; -- SPACE
				scoreChar(18).score_rom_opcode <= "0000000"; -- SPACE
				scoreChar(19).score_rom_opcode <= "0000000"; -- SPACE
			END CASE;

		END IF;
	END PROCESS;

	waveCountDisp : PROCESS (waveCount)
	BEGIN
		CASE(waveCount + 1) IS
			WHEN 0 => scoreChar(30).score_rom_opcode <= "0110000";
			WHEN 1 => scoreChar(30).score_rom_opcode <= "0110001";
			WHEN 2 => scoreChar(30).score_rom_opcode <= "0110010";
			WHEN 3 => scoreChar(30).score_rom_opcode <= "0110011";
			WHEN 4 => scoreChar(30).score_rom_opcode <= "0110100";
			WHEN 5 => scoreChar(30).score_rom_opcode <= "0110101";
			WHEN 6 => scoreChar(30).score_rom_opcode <= "0110110";
			WHEN 7 => scoreChar(30).score_rom_opcode <= "0110111";
			WHEN 8 => scoreChar(30).score_rom_opcode <= "0111000";
			WHEN 9 => scoreChar(30).score_rom_opcode <= "0111001";
			WHEN OTHERS => scoreChar(30).score_rom_opcode <= "0101010";
		END CASE;
	END PROCESS;

	--- Draw that scoreboard
	PROCESS (hcount, vcount)
	BEGIN

		IF (hcount >= scoreChar(0).score_left AND hcount < scoreChar(0).score_right AND vcount >= scoreChar(0).score_top AND vcount < scoreChar(0).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn0 <= (scoreChar(0).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(0).score_top, 4));
			scoreChar(0).fontBitEn <= fontDataOut0(hcount - scoreChar(0).score_left);

			IF ((scoreChar(0).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(1).score_left AND hcount < scoreChar(1).score_right AND vcount >= scoreChar(1).score_top AND vcount < scoreChar(1).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn1 <= (scoreChar(1).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(1).score_top, 4));
			scoreChar(1).fontBitEn <= fontDataOut1(hcount - scoreChar(1).score_left);

			IF ((scoreChar(1).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(2).score_left AND hcount < scoreChar(2).score_right AND vcount >= scoreChar(2).score_top AND vcount < scoreChar(2).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn2 <= (scoreChar(2).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(2).score_top, 4));
			scoreChar(2).fontBitEn <= fontDataOut2(hcount - scoreChar(2).score_left);

			IF ((scoreChar(2).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(3).score_left AND hcount < scoreChar(3).score_right AND vcount >= scoreChar(3).score_top AND vcount < scoreChar(3).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn3 <= (scoreChar(3).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(3).score_top, 4));
			scoreChar(3).fontBitEn <= fontDataOut3(hcount - scoreChar(3).score_left);

			IF ((scoreChar(3).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(4).score_left AND hcount < scoreChar(4).score_right AND vcount >= scoreChar(4).score_top AND vcount < scoreChar(4).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn4 <= (scoreChar(4).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(4).score_top, 4));
			scoreChar(4).fontBitEn <= fontDataOut4(hcount - scoreChar(4).score_left);

			IF ((scoreChar(4).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(5).score_left AND hcount < scoreChar(5).score_right AND vcount >= scoreChar(5).score_top AND vcount < scoreChar(5).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn0 <= (scoreChar(5).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(5).score_top, 4));
			scoreChar(5).fontBitEn <= fontDataOut0(hcount - scoreChar(5).score_left);

			IF ((scoreChar(5).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(6).score_left AND hcount < scoreChar(6).score_right AND vcount >= scoreChar(6).score_top AND vcount < scoreChar(6).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn1 <= (scoreChar(6).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(6).score_top, 4));
			scoreChar(6).fontBitEn <= fontDataOut1(hcount - scoreChar(6).score_left);

			IF ((scoreChar(6).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(7).score_left AND hcount < scoreChar(7).score_right AND vcount >= scoreChar(7).score_top AND vcount < scoreChar(7).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn2 <= (scoreChar(7).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(7).score_top, 4));
			scoreChar(7).fontBitEn <= fontDataOut2(hcount - scoreChar(7).score_left);

			IF ((scoreChar(7).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(8).score_left AND hcount < scoreChar(8).score_right AND vcount >= scoreChar(8).score_top AND vcount < scoreChar(8).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn3 <= (scoreChar(8).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(8).score_top, 4));
			scoreChar(8).fontBitEn <= fontDataOut3(hcount - scoreChar(8).score_left);

			IF ((scoreChar(8).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(9).score_left AND hcount < scoreChar(9).score_right AND vcount >= scoreChar(9).score_top AND vcount < scoreChar(9).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn4 <= (scoreChar(9).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(9).score_top, 4));
			scoreChar(9).fontBitEn <= fontDataOut4(hcount - scoreChar(9).score_left);

			IF ((scoreChar(9).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(10).score_left AND hcount < scoreChar(10).score_right AND vcount >= scoreChar(10).score_top AND vcount < scoreChar(10).score_bottom) THEN
			scoreboard_out.rgb <= "111100001111";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn0 <= (scoreChar(10).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(10).score_top, 4));
			scoreChar(10).fontBitEn <= fontDataOut0(hcount - scoreChar(10).score_left);

			IF ((scoreChar(10).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(11).score_left AND hcount < scoreChar(11).score_right AND vcount >= scoreChar(11).score_top AND vcount < scoreChar(11).score_bottom) THEN
			scoreboard_out.rgb <= "111100001111";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn1 <= (scoreChar(11).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(11).score_top, 4));
			scoreChar(11).fontBitEn <= fontDataOut1(hcount - scoreChar(11).score_left);

			IF ((scoreChar(11).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(12).score_left AND hcount < scoreChar(12).score_right AND vcount >= scoreChar(12).score_top AND vcount < scoreChar(12).score_bottom) THEN
			scoreboard_out.rgb <= "111100001111";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn2 <= (scoreChar(12).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(12).score_top, 4));
			scoreChar(12).fontBitEn <= fontDataOut2(hcount - scoreChar(12).score_left);

			IF ((scoreChar(12).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(13).score_left AND hcount < scoreChar(13).score_right AND vcount >= scoreChar(13).score_top AND vcount < scoreChar(13).score_bottom) THEN
			scoreboard_out.rgb <= "111100001111";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn3 <= (scoreChar(13).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(13).score_top, 4));
			scoreChar(13).fontBitEn <= fontDataOut3(hcount - scoreChar(13).score_left);

			IF ((scoreChar(13).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(14).score_left AND hcount < scoreChar(14).score_right AND vcount >= scoreChar(14).score_top AND vcount < scoreChar(14).score_bottom) THEN
			scoreboard_out.rgb <= "111100001111";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn4 <= (scoreChar(14).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(14).score_top, 4));
			scoreChar(14).fontBitEn <= fontDataOut4(hcount - scoreChar(14).score_left);

			IF ((scoreChar(14).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(15).score_left AND hcount < scoreChar(15).score_right AND vcount >= scoreChar(15).score_top AND vcount < scoreChar(15).score_bottom) THEN
			scoreboard_out.rgb <= "111100001111";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn0 <= (scoreChar(15).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(15).score_top, 4));
			scoreChar(15).fontBitEn <= fontDataOut0(hcount - scoreChar(15).score_left);

			IF ((scoreChar(15).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(16).score_left AND hcount < scoreChar(16).score_right AND vcount >= scoreChar(16).score_top AND vcount < scoreChar(16).score_bottom) THEN
			scoreboard_out.rgb <= "111100001111";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn1 <= (scoreChar(16).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(16).score_top, 4));
			scoreChar(16).fontBitEn <= fontDataOut1(hcount - scoreChar(16).score_left);

			IF ((scoreChar(16).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(17).score_left AND hcount < scoreChar(17).score_right AND vcount >= scoreChar(17).score_top AND vcount < scoreChar(17).score_bottom) THEN
			scoreboard_out.rgb <= "111100001111";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn2 <= (scoreChar(17).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(17).score_top, 4));
			scoreChar(17).fontBitEn <= fontDataOut2(hcount - scoreChar(17).score_left);

			IF ((scoreChar(17).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(18).score_left AND hcount < scoreChar(18).score_right AND vcount >= scoreChar(18).score_top AND vcount < scoreChar(18).score_bottom) THEN
			scoreboard_out.rgb <= "111100001111";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn3 <= (scoreChar(18).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(18).score_top, 4));
			scoreChar(18).fontBitEn <= fontDataOut3(hcount - scoreChar(18).score_left);

			IF ((scoreChar(18).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(19).score_left AND hcount < scoreChar(19).score_right AND vcount >= scoreChar(19).score_top AND vcount < scoreChar(19).score_bottom) THEN
			scoreboard_out.rgb <= "111100001111";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn4 <= (scoreChar(19).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(19).score_top, 4));
			scoreChar(19).fontBitEn <= fontDataOut4(hcount - scoreChar(19).score_left);

			IF ((scoreChar(19).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(20).score_left AND hcount < scoreChar(20).score_right AND vcount >= scoreChar(20).score_top AND vcount < scoreChar(20).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn0 <= (scoreChar(20).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(20).score_top, 4));
			scoreChar(20).fontBitEn <= fontDataOut0(hcount - scoreChar(20).score_left);

			IF ((scoreChar(20).fontBitEn = '1') AND (lives >= 3)) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(21).score_left AND hcount < scoreChar(21).score_right AND vcount >= scoreChar(21).score_top AND vcount < scoreChar(21).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn1 <= (scoreChar(21).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(21).score_top, 4));
			scoreChar(21).fontBitEn <= fontDataOut1(hcount - scoreChar(21).score_left);

			IF ((scoreChar(21).fontBitEn = '1') AND (lives >= 2)) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(22).score_left AND hcount < scoreChar(22).score_right AND vcount >= scoreChar(22).score_top AND vcount < scoreChar(22).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn2 <= (scoreChar(22).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(22).score_top, 4));
			scoreChar(22).fontBitEn <= fontDataOut2(hcount - scoreChar(22).score_left);

			IF ((scoreChar(22).fontBitEn = '1') AND (lives >= 1)) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(23).score_left AND hcount < scoreChar(23).score_right AND vcount >= scoreChar(23).score_top AND vcount < scoreChar(23).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn3 <= (scoreChar(23).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(23).score_top, 4));
			scoreChar(23).fontBitEn <= fontDataOut3(hcount - scoreChar(23).score_left);

			IF ((scoreChar(23).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(24).score_left AND hcount < scoreChar(24).score_right AND vcount >= scoreChar(24).score_top AND vcount < scoreChar(24).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn4 <= (scoreChar(24).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(24).score_top, 4));
			scoreChar(24).fontBitEn <= fontDataOut4(hcount - scoreChar(24).score_left);

			IF ((scoreChar(24).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(25).score_left AND hcount < scoreChar(25).score_right AND vcount >= scoreChar(25).score_top AND vcount < scoreChar(25).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn0 <= (scoreChar(25).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(25).score_top, 4));
			scoreChar(25).fontBitEn <= fontDataOut0(hcount - scoreChar(25).score_left);

			IF ((scoreChar(25).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(26).score_left AND hcount < scoreChar(26).score_right AND vcount >= scoreChar(26).score_top AND vcount < scoreChar(26).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------

			fontAddrIn1 <= (scoreChar(26).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(26).score_top, 4));
			scoreChar(26).fontBitEn <= fontDataOut1(hcount - scoreChar(26).score_left);

			IF ((scoreChar(26).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(27).score_left AND hcount < scoreChar(27).score_right AND vcount >= scoreChar(27).score_top AND vcount < scoreChar(27).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------
			fontAddrIn2 <= (scoreChar(27).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(27).score_top, 4));
			scoreChar(27).fontBitEn <= fontDataOut2(hcount - scoreChar(27).score_left);

			IF ((scoreChar(27).fontBitEn = '1')) THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(28).score_left AND hcount < scoreChar(28).score_right AND vcount >= scoreChar(28).score_top AND vcount < scoreChar(28).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------
			fontAddrIn3 <= (scoreChar(28).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(28).score_top, 4));
			scoreChar(28).fontBitEn <= fontDataOut3(hcount - scoreChar(28).score_left);

			IF (scoreChar(28).fontBitEn = '1') THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(29).score_left AND hcount < scoreChar(29).score_right AND vcount >= scoreChar(29).score_top AND vcount < scoreChar(29).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------
			fontAddrIn4 <= (scoreChar(29).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(29).score_top, 4));
			scoreChar(29).fontBitEn <= fontDataOut4(hcount - scoreChar(29).score_left);

			IF (scoreChar(29).fontBitEn = '1') THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(30).score_left AND hcount < scoreChar(30).score_right AND vcount >= scoreChar(30).score_top AND vcount < scoreChar(30).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------
			fontAddrIn4 <= (scoreChar(30).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(30).score_top, 4));
			scoreChar(30).fontBitEn <= fontDataOut4(hcount - scoreChar(30).score_left);

			IF (scoreChar(30).fontBitEn = '1') THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(31).score_left AND hcount < scoreChar(31).score_right AND vcount >= scoreChar(31).score_top AND vcount < scoreChar(31).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------
			fontAddrIn4 <= (scoreChar(31).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(31).score_top, 4));
			scoreChar(31).fontBitEn <= fontDataOut4(hcount - scoreChar(31).score_left);

			IF (scoreChar(31).fontBitEn = '1') THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(32).score_left AND hcount < scoreChar(32).score_right AND vcount >= scoreChar(32).score_top AND vcount < scoreChar(32).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------
			fontAddrIn4 <= (scoreChar(32).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(32).score_top, 4));
			scoreChar(32).fontBitEn <= fontDataOut4(hcount - scoreChar(32).score_left);

			IF (scoreChar(32).fontBitEn = '1') THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(33).score_left AND hcount < scoreChar(33).score_right AND vcount >= scoreChar(33).score_top AND vcount < scoreChar(33).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------
			fontAddrIn4 <= (scoreChar(33).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(33).score_top, 4));
			scoreChar(33).fontBitEn <= fontDataOut4(hcount - scoreChar(33).score_left);

			IF (scoreChar(33).fontBitEn = '1') THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(34).score_left AND hcount < scoreChar(34).score_right AND vcount >= scoreChar(34).score_top AND vcount < scoreChar(34).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------
			fontAddrIn4 <= (scoreChar(34).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(34).score_top, 4));
			scoreChar(34).fontBitEn <= fontDataOut4(hcount - scoreChar(34).score_left);

			IF (scoreChar(34).fontBitEn = '1') THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(35).score_left AND hcount < scoreChar(35).score_right AND vcount >= scoreChar(35).score_top AND vcount < scoreChar(35).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------
			fontAddrIn4 <= (scoreChar(35).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(35).score_top, 4));
			scoreChar(35).fontBitEn <= fontDataOut4(hcount - scoreChar(35).score_left);

			IF (scoreChar(35).fontBitEn = '1') THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSIF (hcount >= scoreChar(36).score_left AND hcount < scoreChar(36).score_right AND vcount >= scoreChar(36).score_top AND vcount < scoreChar(36).score_bottom) THEN
			scoreboard_out.rgb <= "111100000000";
			-----SCOREBOARD LOGIC-----------
			fontAddrIn4 <= (scoreChar(36).score_rom_opcode & conv_std_logic_vector(vcount - scoreChar(36).score_top, 4));
			scoreChar(36).fontBitEn <= fontDataOut4(hcount - scoreChar(36).score_left);

			IF (scoreChar(36).fontBitEn = '1') THEN
				scoreboard_out.pixelOn <= true;
			ELSE
				scoreboard_out.pixelOn <= false;
			END IF;

		ELSE
			scoreboard_out.pixelOn <= false;
		END IF;

	END PROCESS;
END ARCHITECTURE;