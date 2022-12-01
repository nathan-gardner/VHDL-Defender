LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
ENTITY accelerometer_top IS

	PORT (

		max10_clk : IN STD_LOGIC;

		GSENSOR_CS_N : OUT STD_LOGIC;
		GSENSOR_SCLK : OUT STD_LOGIC;
		GSENSOR_SDI : INOUT STD_LOGIC;
		GSENSOR_SDO : INOUT STD_LOGIC;
		dFix : OUT STD_LOGIC_VECTOR(5 DOWNTO 0) := "111111";
		ledFix : OUT STD_LOGIC_VECTOR(9 DOWNTO 0) := "0000000000";
		clk_Out : OUT STD_LOGIC;

		data_x : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_y : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_z : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0);
		shiftMagx, shiftMagy, shiftMagz : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		x_shiftDir, y_shiftDir, z_shiftDir : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)

	);

END accelerometer_top;

ARCHITECTURE accelerometer_top_behav OF accelerometer_top IS

	COMPONENT ADXL345_controller IS PORT (

		reset_n : IN STD_LOGIC;
		clk : IN STD_LOGIC;
		data_valid : OUT STD_LOGIC;
		data_x : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_y : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_z : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		SPI_SDI : OUT STD_LOGIC;
		SPI_SDO : IN STD_LOGIC;
		SPI_CSN : OUT STD_LOGIC;
		SPI_CLK : OUT STD_LOGIC

		);
	END COMPONENT;

	COMPONENT pll IS
		PORT (
			inclk0 : IN STD_LOGIC := '0';
			c0 : OUT STD_LOGIC
		);
	END COMPONENT;
	SIGNAL co_to_iSPI_CLK, c1_to_iSPI_CLK_OUT, oRST_to_RESET : STD_LOGIC;
	SIGNAL x_shiftDir_sig, y_shiftDir_sig, z_shiftDir_sig : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL oneMHz_clk : STD_LOGIC;

	--signal signedAngle, unsignedAngle : integer;
	SIGNAL signedMagx, signedMagy, signedMagz : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL countMagX, countMagy, countMagz : INTEGER; -- absolute magnitude of counting speed

BEGIN
	clk_out <= OneMHz_clk;
	x_shiftDir <= x_shiftDir_sig;
	y_shiftDir <= y_shiftDir_sig;
	z_shiftDir <= z_shiftDir_sig;

	signedMagx <= data_x(15 DOWNTO 8);
	SignedMagy <= data_y(15 DOWNTO 8);
	SignedMagz <= data_z(15 DOWNTO 8);

	U0 : ADXL345_controller PORT MAP('1', onemHz_Clk, OPEN, data_x, data_y, data_z, GSENSOR_SDI, GSENSOR_SDO, GSENSOR_CS_N, GSENSOR_SCLK);
	U1 : pll PORT MAP(inclk0 => max10_clk, c0 => OneMHz_clk);
	--- determine directon to count based on the accelerometer data ---
	PROCESS (oneMHz_clk)
	BEGIN
		IF signedMagx = "00000000" THEN --- shift left
			IF (to_integer(unsigned(data_x(7 DOWNTO 0))) > 3) THEN
				x_shiftDir_sig <= "10";
			ELSE
				x_shiftDir_sig <= "00";
			END IF;
		ELSIF signedMagx = "11111111" THEN --- shift right
			IF (to_integer(unsigned(NOT data_x(7 DOWNTO 0))) > 3) THEN
				x_shiftDir_sig <= "11";
			ELSE
				x_shiftdir_sig <= "00";
			END IF;
		ELSE
			x_shiftDir_sig <= "00"; -- undefined behavior
		END IF;
	END PROCESS;

	PROCESS (oneMHz_clk)
	BEGIN
		IF signedMagy = "00000000" THEN
			IF (to_integer(unsigned(data_y(7 DOWNTO 0))) > 3) THEN
				y_shiftDir_sig <= "11";
			ELSE
				y_shiftDir_sig <= "00";
			END IF;
		ELSIF signedMagy = "11111111" THEN
			IF (to_integer(unsigned(NOT data_y(7 DOWNTO 0))) > 3) THEN
				y_shiftDir_sig <= "10";
			ELSE
				y_shiftDir_sig <= "00";
			END IF;
		ELSE
			y_shiftDir_sig <= "00";
		END IF;
	END PROCESS;

	PROCESS (oneMhz_clk)
	BEGIN
		IF signedMagz = "00000000" THEN
			IF (to_integer(unsigned(data_z(7 DOWNTO 0))) > 3) THEN
				z_shiftDir_sig <= "11";
			ELSE
				z_shiftDir_sig <= "00";
			END IF;
		ELSIF signedMagz = "11111111" THEN
			IF (to_integer(unsigned(NOT data_z(7 DOWNTO 0))) > 3) THEN
				z_shiftDir_sig <= "10";
			ELSE
				z_shiftDir_sig <= "00";
			END IF;
		ELSE
			z_shiftDir_sig <= "00";
		END IF;
	END PROCESS;
	-----------------------------------------------------------------------------------------------------
	PROCESS (x_shiftDir_sig)
	BEGIN
		CASE x_shiftDir_sig IS
			WHEN "10" => countMagx <= to_integer(unsigned(data_x(7 DOWNTO 0))); -- determines speed at which we count down
			WHEN "11" => countMagx <= to_integer(unsigned(NOT data_x(7 DOWNTO 0))); -- determines speed at which we count up
			WHEN OTHERS => countMagx <= 0;
		END CASE;
	END PROCESS;
	PROCESS (y_shiftDir_sig)
	BEGIN
		CASE y_shiftDir_sig IS
			WHEN "10" => countMagy <= to_integer(unsigned(data_y(7 DOWNTO 0))); -- determines speed at which we count down
			WHEN "11" => countMagy <= to_integer(unsigned(NOT data_y(7 DOWNTO 0))); -- determines speed at which we count up
			WHEN OTHERS => countMagy <= 0;
		END CASE;
	END PROCESS;

	PROCESS (z_shiftDir_sig)
	BEGIN
		CASE z_shiftDir_sig IS
			WHEN "10" => countMagz <= to_integer(unsigned(data_z(7 DOWNTO 0))); -- determines speed at which we count down
			WHEN "11" => countMagz <= to_integer(unsigned(NOT data_z(7 DOWNTO 0))); -- determines speed at which we count up
			WHEN OTHERS => countMagz <= 0;
		END CASE;
	END PROCESS;

	------------------------------------------------------------------------------------------------------------
	--- determine unsigned angle magnitude
	--x_shiftDir_sig, y_shiftDir_sig, z_shiftDir_sig, ,data_x,data_y,data_z
	PROCESS (countMagX)
	BEGIN
		--- determine shift magnitude
		CASE countMagX IS
			WHEN 0 TO 20 => shiftMagx <= "000";
			WHEN 21 TO 63 => shiftMagx <= "001";
			WHEN 64 TO 127 => shiftMagx <= "010";
			WHEN 128 TO 191 => shiftMagX <= "011";
			WHEN 192 TO 255 => shiftMagx <= "100";
			WHEN OTHERS => shiftMagx <= "000";
		END CASE;
	END PROCESS;

	PROCESS (countMagy)
	BEGIN
		CASE countMagy IS
			WHEN 0 TO 20 => shiftMagy <= "000";
			WHEN 21 TO 63 => shiftMagy <= "001";
			WHEN 64 TO 127 => shiftMagy <= "010";
			WHEN 128 TO 191 => shiftMagy <= "011";
			WHEN 192 TO 255 => shiftMagy <= "100";
			WHEN OTHERS => shiftMagy <= "000";
		END CASE;
	END PROCESS;

	PROCESS (countMagz)
	BEGIN
		CASE countMagz IS
			WHEN 0 TO 20 => shiftMagz <= "000";
			WHEN 21 TO 63 => shiftMagz <= "001";
			WHEN 64 TO 127 => shiftMagz <= "010";
			WHEN 128 TO 191 => shiftMagz <= "011";
			WHEN 192 TO 255 => shiftMagz <= "100";
			WHEN OTHERS => shiftMagz <= "000";
		END CASE;
	END PROCESS;
	----------------------------------------------------------------------------------------------
END ARCHITECTURE;