-----------------------------------------
--													--
-- Module: TB_Stack							--
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


entity TB_Stack is
end entity;


architecture testbench of TB_Stack is	-- default
	-- DUT INTERFACE --
	component LIFO_Stack is	-- Push-down LIFO Stack with from-the-top offset
		generic (
			WORD: positive := 16;
			ADDR: positive := 8		-- address vector size
		);
		port (
			-- CLOCK --
			clock: in std_logic;

			-- CONTROL --
			op: in std_logic_vector(1 downto 0);
			offset: in std_logic_vector(ADDR-1 downto 0);

			-- DATA --
			stack_in: in std_logic_vector(WORD-1 downto 0);
			stack_out: out std_logic_vector(WORD-1 downto 0);

			-- STACK ERRORS --
			overflow, underflow: out std_logic
		);
	end component;


	-- CONSTANTS --
	constant T: time := 20 ns;
	constant LAG: time := 12 ns;

	constant N: natural := 16;
	constant ADDR: positive := 8;

	-- opcodes
	constant STACK_RESET: std_logic_vector(1 downto 0) :=	"00";
	constant STACK_POP: std_logic_vector(1 downto 0) :=	"01";
	constant STACK_PUSH: std_logic_vector(1 downto 0) :=	"10";
	constant STACK_NOP: std_logic_vector(1 downto 0) :=	"11";


	-- SIGNALS --
	signal clock, overflow, underflow: std_logic;
	signal op: std_logic_vector(1 downto 0);
	signal offset: std_logic_vector(ADDR-1 downto 0);
	signal stack_in, stack_out: std_logic_vector(N-1 downto 0);


	-- TESTING --
	begin
		UUT: LIFO_Stack
			generic map (
				WORD => N,
				ADDR => ADDR
			)
			port map (
				clock => clock,
				op => op,
				offset => offset,
				stack_in => stack_in,
				stack_out => stack_out,
				overflow => overflow,
				underflow => underflow
			);

		CLK: process is	-- 50% duty
			begin
				clock <= '0';
				wait for (T/2);
				clock <= '1';
				wait for (T/2);
		end process;

		STIMULUS: process is
			begin
				wait until rising_edge(clock);

				op <= STACK_RESET;
				offset<= x"00";
				wait for LAG;
				assert ((overflow='0') and (underflow='0'))
						 report "Reported false Stack error"
						 severity ERROR;
				wait until rising_edge(clock);

				op <= STACK_POP;
				wait for LAG;
				assert ((overflow='0') and (underflow='1'))
						 report "Didn't report Stack underflow"
						 severity ERROR;
				wait until rising_edge(clock);

				op <= STACK_RESET;
				wait until rising_edge(clock);

				op <= STACK_PUSH;
				stack_in <= x"FAAA";
				wait for LAG;
				assert ((overflow='0') and (underflow='0'))
						 report "Reported false Stack error"
						 severity ERROR;
				wait until rising_edge(clock);

				op <= STACK_PUSH;
				stack_in <= x"5111";
				wait for LAG;
				assert (stack_out=x"FAAA")
						 report "Wrong TOS after last PUSH"
						 severity ERROR;
				wait until rising_edge(clock);

				op <= STACK_NOP;
				offset <= std_logic_vector(to_unsigned(1, ADDR));
				wait for LAG;
				assert (stack_out=x"5111")
						 report "Wrong TOS after last PUSH"
						 severity ERROR;
				wait until rising_edge(clock);

				op <= STACK_NOP;
				offset <= x"00";
				wait for LAG;
				assert (stack_out=x"FAAA")
						 report "Wrong value read on Stack after PICK(1)"
						 severity ERROR;
				wait until rising_edge(clock);

				op <= STACK_POP;
				wait for LAG;
				assert (stack_out=x"5111")
						 report "Wrong TOS value"
						 severity ERROR;
				wait until rising_edge(clock);

				op <= STACK_POP;
				wait for LAG;
				assert (stack_out=x"FAAA")
						 report "Wrong TOS value read after last POP"
						 severity ERROR;
				wait until rising_edge(clock);

				-- push until overfloing
				for i in (2**ADDR)-1 downto 1 loop
					op <= STACK_PUSH;
					stack_in <= std_logic_vector(to_unsigned(i, N));
					wait until rising_edge(clock);
				end loop;

				op <= STACK_PUSH;
				stack_in <= x"D000";
				wait for LAG;
				assert ((overflow='1') and (underflow='0'))
						 report "Didn't report Stack overflow"
						 severity ERROR;

				-- TOTAL TIME : (255+10)*T + LAG
		end process;

end architecture;
