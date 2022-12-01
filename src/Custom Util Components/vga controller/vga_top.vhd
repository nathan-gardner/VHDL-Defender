------------------------------------------------------------------------------------------------------------------------------------------
-- Project: Defender (DSD Final Project Fall 2021)
-- Authors: Blake Martin & Nathan Gardner
-- Date: 11/30/21
------------------------------------------------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY vga_top IS

	PORT (
		--From accelerometer:
		red_out, green_out, blue_out : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

		-- Inputs for image generation

		pixel_clk_m : IN STD_LOGIC; -- pixel clock for VGA mode being used
		reset_n_m : IN STD_LOGIC; --active low asycnchronous reset

		row : OUT INTEGER;
		col : OUT INTEGER;

		-- Outputs for image generation

		h_sync_m : OUT STD_LOGIC; --horiztonal sync pulse
		v_sync_m : OUT STD_LOGIC; --vertical sync pulse

		red_m : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0'); --red magnitude output to DAC
		green_m : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0'); --green magnitude output to DAC
		blue_m : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0') --blue magnitude output to DAC
	);

END vga_top;

ARCHITECTURE vga_structural OF vga_top IS
	COMPONENT vga_controller IS

		PORT (

			pixel_clk : IN STD_LOGIC; --pixel clock at frequency of VGA mode being used
			reset_n : IN STD_LOGIC; --active low asycnchronous reset
			h_sync : OUT STD_LOGIC; --horiztonal sync pulse
			v_sync : OUT STD_LOGIC; --vertical sync pulse
			disp_ena : OUT STD_LOGIC; --display enable ('1' = display time, '0' = blanking time)
			column : OUT INTEGER; --horizontal pixel coordinate
			row : OUT INTEGER; --vertical pixel coordinate
			n_blank : OUT STD_LOGIC; --direct blacking output to DAC
			n_sync : OUT STD_LOGIC --sync-on-green output to DAC

		);

	END COMPONENT;

	COMPONENT hw_image_generator IS

		PORT (

			disp_ena : IN STD_LOGIC; --display enable ('1' = display time, '0' = blanking time)
			row : IN INTEGER; --row pixel coordinate
			column : IN INTEGER; --column pixel coordinate
			red_out, green_out, blue_out : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			red : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0'); --red magnitude output to DAC
			green : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0'); --green magnitude output to DAC
			blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0') --blue magnitude output to DAC

		);

	END COMPONENT;
	SIGNAL pll_OUT_to_vga_controller_IN, dispEn : STD_LOGIC;
	SIGNAL rowSignal, colSignal : INTEGER;
BEGIN

	row <= rowSignal;
	col <= colSignal;

	pll_OUT_to_vga_controller_IN <= pixel_clk_m;
	-- Just need 3 components for VGA system
	U2 : vga_controller PORT MAP(pll_OUT_to_vga_controller_IN, reset_n_m, h_sync_m, v_sync_m, dispEn, colSignal, rowSignal, OPEN, OPEN);
	U3 : hw_image_generator PORT MAP(dispEn, rowSignal, colSignal, red_out, blue_out, green_out, red_m, green_m, blue_m);

END vga_structural;