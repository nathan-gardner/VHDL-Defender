-- --------------------------------------
--
--  BASIC VHDL LOGIC GATES PACKAGE
--
--  (C) 2018, 2019 JW BRUCE
--  TENNESSEE TECH UNIVERSITY
--
-- ----------------------------------------
--      DO NOT MODIFY THIS FILE!!!!!!!!!
-- ----------------------------------------
-- REVISION HISTORY
-- ----------------------------------------
-- Rev 0.1 -- Created        (JWB Nov.2018)
-- Rev 0.2 -- Refactored into package
--                           (JWB Nov.2018)
-- Rev 0.3 -- Added more combinational
--            gates and the first sequential
--            logic primitives (SR latch & FF)
--                           (JWB Dec.2018)
-- Rev 0.4 -- Clean up some and prepared
--            for use in the Spring 2019
--            semester
--                           (JWB Feb.2019)
-- Rev 0.5 -- Created better design example
--            for use in the Spring 2019
--            semester
--                           (JWB Feb.2019)
-- Rev 0.6 -- Added some behavioral combi
--            logic building blocks
--                           (JWB Sept.2019)

--
-- ================================================
-- Package currently contains the following gates:
-- ================================================
--  COMBINATIONAL               SEQUENTIAL
--    inv                         SR
--    orX
--    norX
--    andX
--    nandX
--    xorX
--    xnorX
--    ripple_counter
--
--  where X is 2, 3, 4 and
--    denotes the number of inputs
-- ==================================

-- --------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
--- -------------------------------------

-- EXAMPLE 1 : package and package body definition

PACKAGE TTU IS
  CONSTANT Size : NATURAL; -- Deferred constant
  SUBTYPE Byte IS STD_LOGIC_VECTOR(7 DOWNTO 0);
  -- Subprogram declaration...
  FUNCTION PARITY (V : Byte) RETURN STD_LOGIC;
  FUNCTION MAJ4 (x1 : STD_LOGIC; x2 : STD_LOGIC; x3 : STD_LOGIC;x4 : STD_LOGIC) RETURN STD_LOGIC;
END PACKAGE TTU;

PACKAGE BODY TTU IS
  CONSTANT Size : NATURAL := 16;
  -- Subprogram body...
  FUNCTION PARITY (V : Byte) RETURN STD_LOGIC IS
    VARIABLE B : STD_LOGIC := '0';
  BEGIN
    FOR I IN V'RANGE LOOP
      B := B XOR V(I);
    END LOOP;
    RETURN B;
  END FUNCTION PARITY;

  FUNCTION MAJ4 (x1 : STD_LOGIC;x2 : STD_LOGIC;x3 : STD_LOGIC;x4 : STD_LOGIC) RETURN STD_LOGIC IS
    VARIABLE tmp : STD_LOGIC_VECTOR(3 DOWNTO 0);
    VARIABLE retval : STD_LOGIC;
  BEGIN
    tmp := x1 & x2 & x3 & x4;

    IF (tmp = "1110") THEN
      retval := '1';
    ELSIF (tmp = "1101") THEN
      retval := '1';
    ELSIF (tmp = "1011") THEN
      retval := '1';
    ELSIF (tmp = "0111") THEN
      retval := '1';
    ELSIF (tmp = "1111") THEN
      retval := '1';
    ELSE
      retval := '0';
    END IF;
    RETURN retval;
  END FUNCTION MAJ4;

END PACKAGE BODY TTU;

----------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY EX_PACKAGE IS PORT (
  A : IN Byte;
  Y : OUT STD_LOGIC);
END ENTITY EX_PACKAGE;

ARCHITECTURE A1 OF EX_PACKAGE IS
BEGIN
  Y <= PARITY(A);
END ARCHITECTURE A1;

----------------------------------------
-- The INVERTER
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY INV IS
  PORT (
    x : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END INV;

ARCHITECTURE RTL OF INV IS
BEGIN
  PROCESS (x) IS
  BEGIN
    y <= NOT x;
  END PROCESS;
END RTL;

-- ------------------------------------
-- OR GATES

----------------------------------------
-- The TWO-INPUT OR GATE
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY OR2 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END OR2;

ARCHITECTURE RTL OF OR2 IS
BEGIN
  PROCESS (x0, x1) IS
  BEGIN
    y <= x0 OR x1;
  END PROCESS;
END RTL;

-- The THREE-input OR gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY OR3 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    x2 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END OR3;

ARCHITECTURE RTL OF or3 IS
BEGIN
  PROCESS (x0, x1, x2) IS
  BEGIN
    y <= x1 OR x2 OR x0;
  END PROCESS;
END RTL;

-- The FOUR-input OR gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY OR4 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    x2 : IN STD_LOGIC;
    x3 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END OR4;

ARCHITECTURE RTL OF OR4 IS
BEGIN
  PROCESS (x1, x2, x3, x0) IS
  BEGIN
    y <= x1 OR x2 OR x3 OR x0;
  END PROCESS;
END RTL;

-- ------------------------------------
-- AND GATES

-- The TWO-input AND gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY AND2 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END AND2;

ARCHITECTURE RTL OF AND2 IS
BEGIN
  PROCESS (x1, x0) IS
  BEGIN
    y <= x1 AND x0;
  END PROCESS;
END RTL;

-- The THREE-input AND gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY AND3 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    x2 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END AND3;

ARCHITECTURE RTL OF AND3 IS
BEGIN
  PROCESS (x1, x2, x0) IS
  BEGIN
    y <= x1 AND x2 AND x0;
  END PROCESS;
END RTL;

-- The FOUR-input AND gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY AND4 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    x2 : IN STD_LOGIC;
    x3 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END AND4;

ARCHITECTURE RTL OF AND4 IS
BEGIN
  PROCESS (x1, x2, x3, x0) IS
  BEGIN
    y <= x1 AND x2 AND x3 AND x0;
  END PROCESS;
END RTL;

-- ------------------------------------
-- XOR GATES

-- The TWO-input XOR gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY XOR2 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END XOR2;

ARCHITECTURE RTL OF XOR2 IS
BEGIN
  PROCESS (x1, x0) IS
  BEGIN
    y <= x1 XOR x0;
  END PROCESS;
END RTL;

-- The THREE-input XOR gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY XOR3 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    x2 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END XOR3;

ARCHITECTURE RTL OF XOR3 IS
BEGIN
  PROCESS (x1, x2, x0) IS
  BEGIN
    y <= x1 XOR x2 XOR x0;
  END PROCESS;
END RTL;

-- The FOUR-input XOR gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY XOR4 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    x2 : IN STD_LOGIC;
    x3 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END XOR4;

ARCHITECTURE RTL OF XOR4 IS
BEGIN
  PROCESS (x1, x2, x3, x0) IS
  BEGIN
    y <= x1 XOR x2 XOR x3 XOR x0;
  END PROCESS;
END RTL;

-- ------------------------------------
-- NOR GATES

-- The TWO-input NOR gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY NOR2 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END NOR2;

ARCHITECTURE RTL OF NOR2 IS
BEGIN
  PROCESS (x1, x0) IS
  BEGIN
    y <= x1 NOR x0;
  END PROCESS;
END RTL;

-- The THREE-input NOR gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY NOR3 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    x2 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END NOR3;

ARCHITECTURE RTL OF NOR3 IS
BEGIN
  PROCESS (x1, x2, x0) IS
  BEGIN
    y <= NOT(x1 OR x2 OR x0);
  END PROCESS;
END RTL;

-- The FOUR-input NOR gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY NOR4 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    x2 : IN STD_LOGIC;
    x3 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END NOR4;

ARCHITECTURE RTL OF NOR4 IS
BEGIN
  PROCESS (x1, x2, x3, x0) IS
  BEGIN
    y <= NOT(x1 OR x2 OR x3 OR x0);
  END PROCESS;
END RTL;

-- ------------------------------------
-- NAND GATES

-- The TWO-input NAND gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY NAND2 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END NAND2;

ARCHITECTURE RTL OF NAND2 IS
BEGIN
  PROCESS (x1, x0) IS
  BEGIN
    y <= x1 NAND x0;
  END PROCESS;
END RTL;

-- The THREE-input NAND gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY NAND3 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    x2 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END NAND3;

ARCHITECTURE RTL OF NAND3 IS
BEGIN
  PROCESS (x1, x2, x0) IS
  BEGIN
    y <= NOT(x1 AND x2 AND x0);
  END PROCESS;
END RTL;

-- The FOUR-input NAND gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY NAND4 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    x2 : IN STD_LOGIC;
    x3 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END NAND4;

ARCHITECTURE RTL OF NAND4 IS
BEGIN
  PROCESS (x1, x2, x3, x0) IS
  BEGIN
    y <= NOT(x1 AND x2 AND x3 AND x0);
  END PROCESS;
END RTL;

-- ------------------------------------
-- XNOR GATES

-- The TWO-input XNOR gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY XNOR2 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END XNOR2;

ARCHITECTURE RTL OF XNOR2 IS
BEGIN
  PROCESS (x1, x0) IS
  BEGIN
    y <= x1 XNOR x0;
  END PROCESS;
END RTL;

-- The THREE-input XNOR gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY XNOR3 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    x2 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END XNOR3;

ARCHITECTURE RTL OF XNOR3 IS
BEGIN
  PROCESS (x1, x2, x0) IS
  BEGIN
    y <= NOT(x1 XOR x2 XOR x0);
  END PROCESS;
END rtl;

-- The FOUR-input XOR gate
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY XNOR4 IS
  PORT (
    x0 : IN STD_LOGIC;
    x1 : IN STD_LOGIC;
    x2 : IN STD_LOGIC;
    x3 : IN STD_LOGIC;
    y : OUT STD_LOGIC);
END XNOR4;

ARCHITECTURE RTL OF XNOR4 IS BEGIN
  PROCESS (x1, x2, x3, x0) IS
  BEGIN
    y <= NOT(x0 XOR x1 XOR x2 XOR x3);
  END PROCESS;
END RTL;

-- =======================================================
-- === COMBINATIONAL LOGIC BUILDING BLOCKS
-- =======================================================

-- the 3-to-8 decoder
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY decoder_3to8 IS
  PORT (
    sel : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
    y : OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
END decoder_3to8;

ARCHITECTURE behavioral OF decoder_3to8 IS
BEGIN
  WITH sel SELECT
    y <= "00000001" WHEN "000",
    "00000010" WHEN "001",
    "00000100" WHEN "010",
    "00001000" WHEN "011",
    "00010000" WHEN "100",
    "00100000" WHEN "101",
    "01000000" WHEN "110",
    "10000000" WHEN "111",
    "00000000" WHEN OTHERS;
END behavioral;

-- the two-to-one MUX
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY mux_2to1 IS
  PORT (
    A, B : IN STD_LOGIC;
    S : IN STD_LOGIC;
    Z : OUT STD_LOGIC);
END mux_2to1;

ARCHITECTURE behavioral OF mux_2to1 IS
BEGIN

  PROCESS (A, B, S) IS
  BEGIN
    IF (S = '0') THEN
      Z <= A;
    ELSE
      Z <= B;
    END IF;
  END PROCESS;
END behavioral;

-- the four-to-one MUX
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY mux_4to1 IS
  PORT (
    A, B, C, D : IN STD_LOGIC;
    S0, S1 : IN STD_LOGIC;
    Z : OUT STD_LOGIC);
END mux_4to1;

ARCHITECTURE behavioral OF mux_4to1 IS
BEGIN
  PROCESS (A, B, C, D, S0, S1) IS
  BEGIN
    IF (S0 = '0' AND S1 = '0') THEN
      Z <= A;
    ELSIF (S0 = '1' AND S1 = '0') THEN
      Z <= B;
    ELSIF (S0 = '0' AND S1 = '1') THEN
      Z <= C;
    ELSE
      Z <= D;
    END IF;
  END PROCESS;
END behavioral;

-- =======================================================
-- === SEQUENTIAL GATES
-- =======================================================
-- The SR latch
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY SR_LATCH IS
  PORT (
    S : IN STD_LOGIC;
    R : IN STD_LOGIC;
    Q : INOUT STD_LOGIC;
    Qnot : INOUT STD_LOGIC);
END SR_LATCH;

ARCHITECTURE RTL OF SR_LATCH IS BEGIN
  Q <= R NOR Qnot;
  Qnot <= S NOR Q;
END RTL;

-- the SR flip-flop

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY SRFF IS PORT (
  S : IN STD_LOGIC;
  R : IN STD_LOGIC;
  CLK : IN STD_LOGIC;
  RESET : IN STD_LOGIC;
  Q : OUT STD_LOGIC;
  Qnot : OUT STD_LOGIC);
END SRFF;

ARCHITECTURE RTL OF SRFF IS BEGIN
  PROCESS (S, R, CLK, RESET)
  BEGIN
    IF (RESET = '1') THEN -- async reset
      Q <= '0';
      Qnot <= '0';
    ELSIF (rising_edge(clk)) THEN -- synchronous behavoir
      IF (S /= R) THEN
        Q <= S;
        Qnot <= R;
      ELSIF (S = '1' AND R = '1') THEN
        Q <= 'Z';
        Qnot <= 'Z';
      END IF;
    END IF;
  END PROCESS;
END RTL;

-- the D flip-flop

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY DFF IS PORT (
  D : IN STD_LOGIC;
  CLK : IN STD_LOGIC;
  RESET : IN STD_LOGIC;
  Q : OUT STD_LOGIC;
  Qnot : OUT STD_LOGIC);
END DFF;

ARCHITECTURE RTL OF DFF IS BEGIN
  PROCESS (D, CLK, RESET)
  BEGIN
    IF (RESET = '1') THEN -- async reset
      Q <= '0';
      Qnot <= '0';
    ELSIF (rising_edge(clk)) THEN -- synchronous behavoir
      Q <= D;
      Qnot <= NOT D;
    END IF;
  END PROCESS;
END RTL;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.TTU.ALL;

ENTITY ripple_counter IS
  GENERIC (n : NATURAL := 4);
  PORT (
    clk : IN STD_LOGIC;
    clear : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(n - 1 DOWNTO 0)
  );
END ripple_counter;

ARCHITECTURE arch_rtl OF ripple_counter IS
  SIGNAL clk_i : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
  SIGNAL q_i : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);

BEGIN
  clk_i(0) <= clk;
  clk_i(n - 1 DOWNTO 1) <= q_i(n - 2 DOWNTO 0);

  gen_cnt : FOR i IN 0 TO n - 1 GENERATE
    dff : PROCESS (clear, clk_i)
    BEGIN
      IF (clear = '1') THEN
        q_i(i) <= '0';
      ELSIF (clk_i(i)'event AND clk_i(i) = '1') THEN
        q_i(i) <= NOT q_i(i);
      END IF;
    END PROCESS dff;
  END GENERATE;
  dout <= NOT q_i;
END arch_rtl;