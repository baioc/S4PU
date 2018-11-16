-----------------------------------------
--													--
-- Module: S4PU_Datapath					--
--													--
-- Package: S4PU								--
--													--
-- Author:	Gabriel B. Sant'Anna			--
--			baiocchi.gabriel@gmail.com		--
--													--
-----------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;		-- type conversion
use ieee.math_real.all;			-- log2 & ceil


entity S4PU_Datapath is	-- S4PU Operative Unit
	generic (ARCH: positive := 16);
	port (
		-- CLOCK --
		clock: in std_logic;

		-- EXTERNAL INPUTS --
		readdata: in std_logic_vector(ARCH-1 downto 0);

		-- COMMANDS --
		ds_op: in std_logic_vector(1 downto 0);
		sel_ds_in: in std_logic;
		ds_pick: in std_logic;
		rs_op: in std_logic_vector(1 downto 0);
		sel_rs_in: in std_logic;
		alu_op: in std_logic_vector(3 downto 0);
		sel_alu_A: in std_logic_vector(2 downto 0);
		tos_load: in std_logic;
		pc_load: in std_logic;
		sel_pc_D: in std_logic_vector(2 downto 0);
		sel_addr: in std_logic_vector(2 downto 0);
		cir_load: in std_logic;
		sel_inst: in std_logic;

		-- STATUS --
		instruction: out std_logic_vector(ARCH-1 downto 0);
		alu_zero: out std_logic;
		rs_overflow, rs_underflow: out std_logic;
		ds_overflow, ds_underflow: out std_logic;

		-- EXTERNAL OUTPUTS --
		address: out std_logic_vector(ARCH-1 downto 0);
		writedata: out std_logic_vector(ARCH-1 downto 0)
	);
end entity;


architecture operative_v0 of S4PU_Datapath is	-- default
	-- COMPONENTS --
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

	component ALU_16 is	-- 16-operation ALU
		generic (WORD: positive := 16);	-- should be greater than 8
		port (
			-- CONTROL --
			op: in std_logic_vector(3 downto 0);

			-- DATA --
			A, B: in std_logic_vector(WORD-1 downto 0);
			Y: out std_logic_vector(WORD-1 downto 0);

			-- SIGNALS --
			zero, overflow: out std_logic
		);
	end component;

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
	constant ADDR: positive := 8;
	constant UNDEFINED: std_logic_vector(ARCH-1 downto 0) := (others => '-');
	constant COMP_ADDR: std_logic_vector(ARCH-1 downto 0) := (others => '1');
	constant PROG_ADDR: std_logic_vector(ARCH-1 downto 0) := std_logic_vector(to_unsigned(32767, ARCH));


	-- SIGNALS --
	signal alu_A_sig, alu_Y_sig, tos_sig,
		    ds_in_sig, ds_out_sig,
		    rs_in_sig, rs_out_sig,
		    pc_D_sig, pc_Q_sig, final_pc_D_sig,
		    cir_sig: std_logic_vector(ARCH-1 downto 0);

	signal ds_offset_sig: std_logic_vector(ADDR-1 downto 0);

	signal alu_overflow_sig: std_logic;	-- @note unused (could be stored on a status register)

	signal sel_ds_offset_sig, sel_ds_in_sig,
			 sel_rs_in_sig, sel_inst_sig: std_logic_vector(0 downto 0);

	signal mux_in_alu_A: std_logic_vector((ARCH*8)-1 downto 0);
	signal mux_in_ds_offset: std_logic_vector((ADDR*2)-1 downto 0);
	signal mux_in_ds_in, mux_in_rs_in, mux_in_inst: std_logic_vector((ARCH*2)-1 downto 0);
	signal mux_in_pc_D, mux_in_addr: std_logic_vector((ARCH*8)-1 downto 0);


	-- BEHAVIOUR --
	begin
		ALU: ALU_16
			generic map (WORD => ARCH)
			port map (
				op => alu_op,

				A => alu_A_sig,
				B => tos_sig,
				Y => alu_Y_sig,

				zero => alu_zero,
				overflow => alu_overflow_sig
			);

		MUX_ALU_A: Multiplexer
			generic map (
				WIDTH => ARCH,
				FAN_IN => 8
			)
			port map (
				sel => sel_alu_A,
				mux_in => mux_in_alu_A,
				mux_out => alu_A_sig
			);
		mux_in_alu_A <= (
			UNDEFINED &											-- 111
			readdata &											-- 110
			rs_out_sig &										-- 101
			ds_out_sig &										-- 100
			tos_sig &											-- 011
			std_logic_vector(to_signed(-1, ARCH)) &	-- 010
			std_logic_vector(to_signed(1, ARCH)) &		-- 001
			std_logic_vector(to_signed(0, ARCH))		-- 000
		);

		TOS_REG: Reg
			generic map (WIDTH => ARCH)
			port map (
				clock => clock,
				reset => '0',
				enable => tos_load,

				D => alu_Y_sig,
				Q => tos_sig
			);

		DATA_STACK: LIFO_Stack
			generic map (
				WORD => ARCH,
				ADDR => ADDR
			)
			port map (
				clock => clock,

				op => ds_op,
				offset => ds_offset_sig,

				stack_in => ds_in_sig,
				stack_out => ds_out_sig,

				overflow => ds_overflow,
				underflow => ds_underflow
			);

		writedata <= ds_out_sig;

		MUX_DS_OFFSET: Multiplexer
			generic map (
				WIDTH => ADDR,
				FAN_IN => 2
			)
			port map (
				sel => sel_ds_offset_sig,
				mux_in => mux_in_ds_offset,
				mux_out => ds_offset_sig
			);
		sel_ds_offset_sig(0) <= ds_pick;
		mux_in_ds_offset <= (
			tos_sig(ADDR-1 downto 0) &					-- 1
			std_logic_vector(to_signed(0, ADDR))	-- 0
		);

		MUX_DS_IN: Multiplexer
			generic map (
				WIDTH => ARCH,
				FAN_IN => 2
			)
			port map (
				sel => sel_ds_in_sig,
				mux_in => mux_in_ds_in,
				mux_out => ds_in_sig
			);
		sel_ds_in_sig(0) <= sel_ds_in;
		mux_in_ds_in <= (
			rs_out_sig &	-- 1
			tos_sig			-- 0
		);

		RETURN_STACK: LIFO_Stack
			generic map (
				WORD => ARCH,
				ADDR => ADDR
			)
			port map (
				clock => clock,

				op => rs_op,
				offset => std_logic_vector(to_unsigned(0, ADDR)),

				stack_in => rs_in_sig,
				stack_out => rs_out_sig,

				overflow => rs_overflow,
				underflow => rs_underflow
			);

		MUX_RS_IN: Multiplexer
			generic map (
				WIDTH => ARCH,
				FAN_IN => 2
			)
			port map (
				sel => sel_rs_in_sig,
				mux_in => mux_in_rs_in,
				mux_out => rs_in_sig
			);
		sel_rs_in_sig(0) <= sel_rs_in;
		mux_in_rs_in <= (
			tos_sig &	-- 1
			pc_Q_sig		-- 0
		);

		PC_REG: Reg
			generic map (WIDTH => ARCH)
			port map (
				clock => clock,
				reset => '0',
				enable => pc_load,

				D => final_pc_D_sig,
				Q => pc_Q_sig
			);
		final_pc_D_sig <= std_logic_vector(unsigned(pc_D_sig) + 1);

		MUX_PC_D: Multiplexer
			generic map (
				WIDTH => ARCH,
				FAN_IN => 8
			)
			port map (
				sel => sel_pc_D,
				mux_in => mux_in_pc_D,
				mux_out => pc_D_sig
			);
		mux_in_pc_D <= (
			UNDEFINED &		-- 111
			UNDEFINED &		-- 110
			rs_out_sig &	-- 101
			readdata &		-- 100
			cir_sig &		-- 011
			pc_Q_sig &		-- 010
			PROG_ADDR &		-- 001
			COMP_ADDR		-- 000
		);

		CIR_REG: Reg
			generic map (WIDTH => ARCH)
			port map (
				clock => clock,
				reset => '0',
				enable => cir_load,

				D => readdata,
				Q => cir_sig
			);

		MUX_INST: Multiplexer
			generic map (
				WIDTH => ARCH,
				FAN_IN => 2
			)
			port map (
				sel => sel_inst_sig,
				mux_in => mux_in_inst,
				mux_out => instruction
			);
		sel_inst_sig(0) <= sel_inst;
		mux_in_inst <= (
			cir_sig &	-- 1
			readdata		-- 0
		);

		MUX_ADDR: Multiplexer
			generic map (
				WIDTH => ARCH,
				FAN_IN => 8
			)
			port map (
				sel => sel_addr,
				mux_in => mux_in_addr,
				mux_out => address
			);
		mux_in_addr <= (
			UNDEFINED &		-- 111
			UNDEFINED &		-- 110
			UNDEFINED &		-- 101
			rs_out_sig &	-- 100
			cir_sig &		-- 011
			readdata &		-- 010
			tos_sig &		-- 001
			pc_Q_sig			-- 000
		);

end architecture;
