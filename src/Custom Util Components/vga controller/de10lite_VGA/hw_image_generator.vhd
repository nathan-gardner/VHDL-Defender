
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.conv_std_logic_vector;
use ieee.numeric_std.all;
library work;
use work.graphicsPackage.all;

ENTITY hw_image_generator IS
  GENERIC(
   
	
	
	col_a : INTEGER := 40; -- bottom line of score
	col_b : INTEGER := 160;
	col_c : INTEGER := 240;
	col_d : INTEGER := 320;
	col_e : INTEGER := 400;
	col_f : INTEGER := 480;
	col_g : INTEGER := 560;
	col_h : INTEGER := 640;
	
	row_a : INTEGER := 68;
	row_b : INTEGER := 136;
	row_c : INTEGER := 204;
	row_d : INTEGER := 272;
	row_e : INTEGER := 340;
	row_f : INTEGER := 408;
	row_g : INTEGER := 480

	);  
  PORT(
    disp_ena :  IN   STD_LOGIC;  --display enable ('1' = display time, '0' = blanking time)
    row      :  IN   INTEGER;    --row pixel coordinate
    column   :  IN   INTEGER;    --column pixel coordinate
	 red_out, green_out, blue_out : in std_logic_vector(3 downto 0);
    red      :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
    green    :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
    blue     :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0')   --blue magnitude output to DAC
	 ); 
END entity;

ARCHITECTURE behavior OF hw_image_generator IS
BEGIN
  -------------------------------------------------------------------------------
  PROCESS(disp_ena, row, column)
  BEGIN
 -- left/right is red-shift...  forward/back is green shift.... yaw left/right is blue-shift
    IF(disp_ena = '1') THEN        --display time
	   case(row) is
			when 0 to mapEdgeTop-4								=> red <= red_out; green <= green_out; blue <= blue_out;
			when mapEdgeTop-3 to mapEdgeTop-1				=> red <= (others => '1'); green <= (others => '1'); blue <= (others => '1');
			when mapEdgeTop to mapEdgeBottom		=> red <= red_out; green <= green_out; blue <= blue_out;
			when mapEdgeBottom+1 to row_g        => red <= "0000"; green <= "0000"; blue <= "0000";  
			when others  => red <= "0000"; green <= "0000"; blue <= "0000"; 
		end case;
	else red <= "0000"; green <= "0000"; blue <= "0000";
	end if;	
end process;
--
-------------------------------------------------------------------------------
 
END behavior;














