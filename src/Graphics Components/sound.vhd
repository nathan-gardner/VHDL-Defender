------------------------------------------------------------------------------------------------------------------------------------------
-- Project: Defender (DSD Final Project Fall 2021)
-- Author: Nathan Gardner
-- Date: 11/30/21
------------------------------------------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
library work;
use work.graphicsPackage.all;
use work.TTU.all;

entity sound is
	port(
		ARDUINO_IO : out std_logic_vector(12 downto 12);
		MAX10_CLK1_50 : in std_logic;
		pause : in std_logic;
		shootSound : in std_logic
	);
end entity;

architecture sound_arch of sound is

constant laserTone : std_logic_vector(23 downto 0) := "000000110111010110011100";
constant Asharp4 : std_logic_vector(23 downto 0) := "000000001000110010100010";
constant Dsharp4 : std_logic_vector(23 downto 0) := "000000001101001010111001";
constant Fsharp4 : std_logic_vector(23 downto 0) := "000000001011000100011111";
constant Dsharp5 : std_logic_vector(23 downto 0) := "000000000110100101011100";
constant Csharp4 : std_logic_vector(23 downto 0) := "000000001110101110111101";
constant Gsharp4 : std_logic_vector(23 downto 0) := "000000001001110111101011";
constant Csharp5 : std_logic_vector(23 downto 0) := "000000000111011001001011";

constant n : natural := 24;
signal clk, clear, IO12 : std_logic;
signal dout, limit : std_logic_vector(n-1 downto 0);
signal toggle : std_logic;

------------------------------------------------------------------

signal clkCount : natural range 0 to 67108000 := 0;

signal shoot : std_logic := '1';

------------------------------------------------------------------

--- ripple counter component ---
component ripple_counter is
 generic (n : natural := 4);
 port ( clk : in std_logic;
        clear : in std_logic;
        dout : out std_logic_vector(n-1 downto 0)
 );
end component;

component pll is
	port(
		inclk0 : in std_logic;
		c4 : out std_logic
	);
end component;

component clock_divider16 is port(clk_in : in std_logic; clk_out: out std_logic); end component;

begin

	ClkGen : clock_divider16 port map(clk_in => MAX10_CLK1_50, clk_out => clk);

	twentyfourbitcounter: ripple_counter generic map(n => n) port map(clk => clk, clear => clear, dout => dout);
	--pll_inst : pll PORT MAP (inclk0 => MAX10_CLK1_50, c4 => clk); -- clk is 16.777 MHz clock

	--limit <= SW & "00000000000000";
	--LEDR(0) <= toggle;
	ARDUINO_IO(12) <= toggle;

	--- check dout equal to limit ---
	process(clk)
	begin
	if (rising_edge(clk)) then
		if((pause = '1') OR (shootSound = '1')) then
			if dout = limit then
				clear <= '1';
				toggle <= not toggle;
			else
				clear <= '0';
			end if;
		end if;
	end if;
	end process;

	sound : process(clk)
	variable clkCountVar : natural := 0;
	begin
	if(rising_edge(clk)) then
		if(shootSound = '1') then
			clkcountVar := clkCountVar + 1;
			if((clkCountVar >= 0) AND (clkCountVar <= 8388500)) then
				limit <= laserTone;
			else
				clkCountVar := 0;
			end if;
		elsif(pause = '1') then
		clkCountVar := clkCountVar + 1;

			if((clkCountVar >= 0) AND (clkCountVar <= 8388500)) then
				limit <= Asharp4;
			elsif((clkCountVar > 8388500) AND (clkCountVar <= 16777000)) then
				limit <= Dsharp4;
			elsif((clkCountVar > 16777000) AND (clkCountVar <= 25165500)) then
				limit <= Fsharp4;
			elsif((clkCountVar > 25165500) AND (clkCountVar <= 33554000)) then
				limit <= Dsharp5;
			elsif((clkCountVar > 33554000) AND (clkCountVar <= 41942500)) then
				limit <= Csharp4;
			elsif((clkCountVar > 41942500) AND (clkCountVar <= 50331000)) then
				limit <= Gsharp4;
			elsif((clkCountVar > 50331000) AND (clkCountVar <= 58719500)) then
				limit <= Csharp4;
			elsif((clkCountVar > 58719500) AND (clkCountVar <= 67108000)) then
				limit <= Csharp5;
			else
				clkCountVar := 0;
			end if;
		else
			clkCountVar := 0;
		end if;
	end if;

	end process;


end architecture;