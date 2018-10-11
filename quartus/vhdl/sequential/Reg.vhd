-----------------------------------------
--													--
-- Module: Reg									--
--													--
-- Package: Generics							--
--													--
-- Author:	Gabriel B. Sant'Anna			--
--			baiocchi.gabriel@gmail.com		--
--													--
-----------------------------------------


library ieee;
use ieee.std_logic_1164.all;


entity Reg is	-- Register with asynchronous reset
	generic (WIDTH: positive := 8);
	port (
		-- CLOCK & CONTROL --
		clock: in std_logic;
		reset, enable: in std_logic;	-- asynchronous reset

		-- DATA --
		D: in std_logic_vector(WIDTH-1 downto 0);
		Q: out std_logic_vector(WIDTH-1 downto 0)
	);
end entity;


architecture canonical of Reg is	-- default
	-- INTERNAL STATE --
	subtype InternalState is std_logic_vector(WIDTH-1 downto 0);
	signal curr_state, next_state: InternalState;


	-- BEHAVIOUR --
	begin
		-- next-state logic : Combinatorial
		next_state <= D when enable = '1' else curr_state;

		-- memory element : Sequential
		ME: process (clock, reset) is
			begin
				if (reset = '1') then
					curr_state <= (others => '0');
				elsif (rising_edge(clock)) then
					curr_state <= next_state;
				end if;
		end process;

		-- output logic
		Q <= curr_state;
end architecture;
