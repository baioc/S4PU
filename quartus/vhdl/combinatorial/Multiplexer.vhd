-----------------------------------------
--													--
-- Module: Multiplexer						--
--													--
-- Package: Generics							--
--													--
-- Author:	Gabriel B. Sant'Anna			--
--			baiocchi.gabriel@gmail.com		--
--													--
-----------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;	-- type conversion
use ieee.math_real.all;	-- log2 & ceil


entity Multiplexer is	-- Mux
	generic (
		WIDTH: positive := 1;
		FAN_IN: positive := 2	-- no. of WIDTH size inputs, should be a power of two
	);
	port (
		-- @note separate signals on mappings needed to fix "globally static" error on ModelSim
		sel: in std_logic_vector(natural(ceil(log2(real(FAN_IN))))-1 downto 0);
		mux_in: in std_logic_vector((WIDTH*FAN_IN)-1 downto 0);
		mux_out: out std_logic_vector(WIDTH-1 downto 0)
	);
	begin
		assert (2**sel'length = FAN_IN)
				 report "Invalid mux fan in: should be a power of two."
				 severity ERROR;
end entity;


architecture vectorial of Multiplexer is	-- default
	-- BEHAVIOUR --
	begin
		out_gen: for i in mux_out'range generate
			mux_out(i) <= mux_in(to_integer(unsigned(sel))*WIDTH + i);
		end generate;
end architecture;
