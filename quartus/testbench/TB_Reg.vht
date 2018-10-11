-----------------------------------------
--													--
-- Module: TB_Reg								--
--													--
-- Package: Testbench						--
--													--
-- Author:	Gabriel B. Sant'Anna			--
--			baiocchi.gabriel@gmail.com		--
--													--
-----------------------------------------


library ieee;
use ieee.std_logic_1164.all;


entity TB_Reg is
end entity;


architecture testbench of TB_Reg is	-- default
	-- DUT INTERFACE --
	component Reg is	-- Register with asynchronous reset
		generic (WIDTH: positive := 8);
		port (
			-- CLOCK & CONTROL --
			clock: in std_logic;
			reset, enable: in std_logic;	-- asynchronous reset

			-- DATA --
			D: in std_logic_vector(WIDTH-1 downto 0);
			Q: out std_logic_vector(WIDTH-1 downto 0)
		);
	end component;


	-- CONSTANTS --
	constant T: time := 20 ns;
	constant LAG: time := 5 ns;
	constant N: natural := 8;


	-- SIGNALS --
	signal clock, reset, enable: std_logic;
	signal D, Q: std_logic_vector(N-1 downto 0);


	-- TESTING --
	begin
		UUT: Reg
			generic map (WIDTH => N)
			port map (
				clock => clock,
				reset => reset,
				enable => enable,
				D => D,
				Q => Q
			);

		CLK: process is -- 50% duty
			begin
				clock <= '0';
				wait for (T/2);
				clock <= '1';
				wait for (T/2);
		end process;

		STIMULUS: process is
			begin
				wait until rising_edge(clock);
				wait for LAG;

				reset <= '0';
				enable <= '1';
				D <= x"d0";
				wait until rising_edge(clock);
				wait for LAG;
				assert (Q=x"d0")
						 report "Register Load failed"
						 severity ERROR;

				reset <= '1';
				enable <= '0';
				wait for LAG;
				assert (Q=x"00")
						 report "Register Asynchronous Reset failed"
						 severity ERROR;

				reset <= '0';
				enable <= '0';
				D <= x"FA";
				wait until rising_edge(clock);
				wait for LAG;
				assert (Q=x"00")
						 report "Register Disable failed"
						 severity ERROR;

				enable <= '1';
				D <= x"FA";
				wait until rising_edge(clock);
				wait for LAG;
				assert (Q=x"FA")
						 report "Register Load failed"
						 severity ERROR;

				-- TOTAL TIME : 4 * T
		end process;

end architecture;
