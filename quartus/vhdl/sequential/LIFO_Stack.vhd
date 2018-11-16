-----------------------------------------
--													--
-- Module: LIFO_Stack						--
--													--
-- Package: Memory							--
--													--
-- Author:	Gabriel B. Sant'Anna			--
--			baiocchi.gabriel@gmail.com		--
--													--
-----------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;		-- type conversion
use ieee.math_real.all;			-- log2 & ceil


entity LIFO_Stack is	-- Push-down LIFO Stack with from-the-top offset
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
end entity;


architecture altera_onchip of LIFO_Stack is	-- default
	-- COMPONENTS --
	component onchip_ram IS	-- Altera Quartus wizard generated single-port RAM
		PORT
		(
			address	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			wren		: IN STD_LOGIC ;
			q			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	END component;

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
	constant UNDEFINED: std_logic_vector(ADDR-1 downto 0) := (others => '-');

	-- opcodes
	constant STACK_RESET: std_logic_vector(1 downto 0) :=	"00";
	constant STACK_POP: std_logic_vector(1 downto 0) :=	"01";
	constant STACK_PUSH: std_logic_vector(1 downto 0) :=	"10";
	constant STACK_NOP: std_logic_vector(1 downto 0) :=	"11";


	-- SIGNALS --
	signal address_sig, final_address_sig,
			 tosp_D_sig, tosp_Q_sig,
			 pushed, popped: std_logic_vector(ADDR-1 downto 0);

	signal wren_sig, reset_sig, update_tosp: std_logic;

	signal sel_tosp_D: std_logic_vector(0 downto 0);
	signal tosp_mux_in: std_logic_vector((ADDR*2)-1 downto 0);
	signal sel_address: std_logic_vector(1 downto 0);
	signal address_mux_in: std_logic_vector((ADDR*4)-1 downto 0);


	-- COMPOSITE BEHAVIOUR --
	begin
		-- @note fixed data'length and address'length on wizard generated RAM
		assert ((WORD >= 16) and (ADDR >= 8))
				 report "On-chip RAM is incompatible with LIFO parameters."
				 severity FAILURE;

		MEMORY: onchip_ram
			port map (
				address => final_address_sig(7 downto 0),
				clock => clock,
				data => stack_in(15 downto 0),
				wren => wren_sig,
				q => stack_out(15 downto 0)
			);

		TOS_POINTER_REG: Reg
			generic map (WIDTH => ADDR)
			port map (
				clock => clock,
				reset => reset_sig,
				enable => update_tosp,
				D => tosp_D_sig,
				Q => tosp_Q_sig
			);

		MUX_TOSP: Multiplexer
			generic map (
				WIDTH => ADDR,
				FAN_IN => 2
			)
			port map (
				sel => sel_tosp_D,
				mux_in => tosp_mux_in,
				mux_out => tosp_D_sig
			);

		MUX_ADDR: Multiplexer
			generic map (
				WIDTH => ADDR,
				FAN_IN => 4
			)
			port map (
				sel => sel_address,
				mux_in => address_mux_in,
				mux_out => address_sig
			);

		wren_sig <= op(1) and (not op(0));	-- write <-> PUSH ("10")
		reset_sig <= op(1) nor op(0);			-- RESET <-> op="00"
		update_tosp <= op(1) xor op(0);		-- update TOSP <-> op="01" | op="10"

		-- @todo could be better optimized with a complete adder/subtractor unit.
		pushed <= std_logic_vector(unsigned(tosp_Q_sig) - 1);
		popped <= std_logic_vector(unsigned(tosp_Q_sig) + 1);

		sel_tosp_D(0) <= op(1);
		tosp_mux_in <= (
			pushed &	-- 1 -> PUSH
			popped	-- 0 -> POP
		);

		sel_address <= op;
		address_mux_in <= (
			tosp_Q_sig &	-- 11 -> read at current tosp
			pushed &			-- 10 -> write at next of stack
			popped &			-- 01 -> read at next of stack
			UNDEFINED		-- 00
		);

		final_address_sig <= std_logic_vector(unsigned(address_sig) + unsigned(offset));

		overflow <= '1' when (op = STACK_PUSH) and (unsigned(tosp_Q_sig) = 1)	-- overflow <-> TOSP=BOTTOM and PUSH
						else '0';

		underflow <= '1' when (unsigned(tosp_Q_sig) = 0) and (op = STACK_POP)	-- underflow <-> TOSP=TOP and POP
						  else '0';

end architecture;
