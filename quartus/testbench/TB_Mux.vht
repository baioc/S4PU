-----------------------------------------
--													--
-- Module: TB_Mux								--
--													--
-- Package: Testbench						--
--													--
-- Author:	Gabriel B. Sant'Anna			--
--			baiocchi.gabriel@gmail.com		--
--													--
-----------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;	-- type conversion
use ieee.math_real.all;	-- log2 & ceil


entity TB_Mux is
end entity;


architecture testbench_64x16 of TB_Mux is	-- default
	-- DUT INTERFACE --
	component Multiplexer is	-- Mux
		generic (
			WIDTH: positive := 1;
			FAN_IN: positive := 2	-- no. of WIDTH size inputs, should be a power of two
		);
		port (
			sel: in std_logic_vector(natural(ceil(log2(real(FAN_IN))))-1 downto 0);
			mux_in: in std_logic_vector((WIDTH*FAN_IN)-1 downto 0);
			mux_out: out std_logic_vector(WIDTH-1 downto 0)
		);
	end component;


	-- CONSTANTS --
	constant LAG: time := 8 ns;

	constant N: natural := 16;
	constant ADDR: positive := 2;
	constant FAN: positive := 2**ADDR;

	constant A: std_logic_vector(N-1 downto 0) := x"BABE";
	constant B: std_logic_vector(N-1 downto 0) := x"BEEF";
	constant C: std_logic_vector(N-1 downto 0) := x"CAFE";
	constant D: std_logic_vector(N-1 downto 0) := x"FEED";


	-- SIGNALS --
	signal sel: std_logic_vector(ADDR-1 downto 0);
	signal mux_in: std_logic_vector((N*FAN)-1 downto 0);
	signal mux_out: std_logic_vector(N-1 downto 0);


	-- TESTING --
	begin
		UUT: Multiplexer
			generic map (
				WIDTH => N,
				FAN_IN => FAN
			)
			port map (
				sel => sel,
				mux_in => mux_in,
				mux_out => mux_out
			);

		mux_in <= (
			D &	-- 11
			C &	-- 10
			B &	-- 01
			A		-- 00
		);

		STIMULUS: process is
			begin
				wait for LAG;

				sel <= "00";
				wait for LAG;
				assert (mux_out=A)
						 report "Multiplexing error when select '00'"
						 severity ERROR;

				sel <= "01";
				wait for LAG;
				assert (mux_out=B)
						 report "Multiplexing error when select '01'"
						 severity ERROR;

				sel <= "10";
				wait for LAG;
				assert (mux_out=C)
						 report "Multiplexing error when select '10'"
						 severity ERROR;

				sel <= "11";
				wait for LAG;
				assert (mux_out=D)
						 report "Multiplexing error when select '11'"
						 severity ERROR;

				-- TOTAL TIME : 5 * LAG
		end process;

end architecture;
