-----------------------------------------
--													--
-- Module: S4PU								--
--													--
-- Package: S4PU								--
--													--
-- Author:	Gabriel B. Sant'Anna			--
--			baiocchi.gabriel@gmail.com		--
--													--
-----------------------------------------


library ieee;
use ieee.std_logic_1164.all;


entity S4PU is	-- Simple Forth Processing Unit
	generic (ARCH: positive := 16);
	port (
		-- CLOCK --
		clock: in std_logic;

		-- SYSTEM CONTROL --
		reset_n: in std_logic;	-- active low, synchronous
		mode: in std_logic;

		-- STACK ERRORS --
		rs_overflow, rs_underflow: out std_logic;
		ds_overflow, ds_underflow: out std_logic;

		-- PUPPET/SLAVE MEMORY (Avalon spec.) --
		read, write: out std_logic;
		address: out std_logic_vector(ARCH-1 downto 0);
		readdata: in std_logic_vector(ARCH-1 downto 0);
		writedata: out std_logic_vector(ARCH-1 downto 0)
	);
end entity;


architecture composite of S4PU is	-- default
	-- SIGNALS --
	signal instruction_sig: std_logic_vector(ARCH-1 downto 0);
	signal alu_zero_sig: std_logic;
	signal rs_overflow_sig, rs_underflow_sig: std_logic;
	signal ds_overflow_sig, ds_underflow_sig: std_logic;
	signal ds_op_sig: std_logic_vector(1 downto 0);
	signal sel_ds_in_sig: std_logic;
	signal ds_pick_sig: std_logic;
	signal rs_op_sig: std_logic_vector(1 downto 0);
	signal sel_rs_in_sig: std_logic;
	signal alu_op_sig: std_logic_vector(3 downto 0);
	signal sel_alu_A_sig: std_logic_vector(2 downto 0);
	signal tos_load_sig: std_logic;
	signal pc_load_sig: std_logic;
	signal sel_pc_D_sig: std_logic_vector(2 downto 0);
	signal sel_addr_sig: std_logic_vector(2 downto 0);
	signal cir_load_sig: std_logic;
	signal sel_inst_sig: std_logic;


	-- COMPONENTS --
	component S4PU_Control is	-- S4PU Control Unit
		generic (ARCH: positive := 16);	-- considered 16-bit
		port (
			-- CLOCK --
			clock: in std_logic;

			-- EXTERNAL INPUTS --
			reset_n: in std_logic;	-- active low, synchronous
			mode: in std_logic;

			-- STATUS --
			instruction: in std_logic_vector(ARCH-1 downto 0);
			alu_zero: in std_logic;
			i_rs_overflow, i_rs_underflow: in std_logic;
			i_ds_overflow, i_ds_underflow: in std_logic;

			-- COMMANDS --
			ds_op: out std_logic_vector(1 downto 0);
			sel_ds_in: out std_logic;
			ds_pick: out std_logic;
			rs_op: out std_logic_vector(1 downto 0);
			sel_rs_in: out std_logic;
			alu_op: out std_logic_vector(3 downto 0);
			sel_alu_A: out std_logic_vector(2 downto 0);
			tos_load: out std_logic;
			pc_load: out std_logic;
			sel_pc_D: out std_logic_vector(2 downto 0);
			sel_addr: out std_logic_vector(2 downto 0);
			cir_load: out std_logic;
			sel_inst: out std_logic;

			-- EXTERNAL OUTPUTS --
			o_rs_overflow, o_rs_underflow: out std_logic;
			o_ds_overflow, o_ds_underflow: out std_logic;
			read, write: out std_logic
		);
	end component;

	component S4PU_Datapath is	-- S4PU Operative Unit
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
	end component;


	-- COMPOSITE BEHAVIOUR --
	begin
		CONTROL_BLOCK: S4PU_Control
			generic map (ARCH => ARCH)
			port map (
				clock => clock,

				reset_n => reset_n,
				mode => mode,

				instruction => instruction_sig,
				alu_zero => alu_zero_sig,
				i_rs_overflow => rs_overflow_sig,
				i_rs_underflow => rs_underflow_sig,
				i_ds_overflow => ds_overflow_sig,
				i_ds_underflow => ds_underflow_sig,
				ds_op => ds_op_sig,
				sel_ds_in => sel_ds_in_sig,
				ds_pick => ds_pick_sig,
				rs_op => rs_op_sig,
				sel_rs_in => sel_rs_in_sig,
				alu_op => alu_op_sig,
				sel_alu_A => sel_alu_A_sig,
				tos_load => tos_load_sig,
				pc_load => pc_load_sig,
				sel_pc_D => sel_pc_D_sig,
				sel_addr => sel_addr_sig,
				cir_load => cir_load_sig,
				sel_inst => sel_inst_sig,

				o_rs_overflow => rs_overflow,
				o_rs_underflow => rs_underflow,
				o_ds_overflow => ds_overflow,
				o_ds_underflow => ds_underflow,
				read => read, write => write
			);

		OPERATIVE_BLOCK: S4PU_Datapath
			generic map (ARCH => ARCH)
			port map (
				clock => clock,

				readdata => readdata,

				instruction => instruction_sig,
				alu_zero => alu_zero_sig,
				rs_overflow => rs_overflow_sig,
				rs_underflow => rs_underflow_sig,
				ds_overflow => ds_overflow_sig,
				ds_underflow => ds_underflow_sig,
				ds_op => ds_op_sig,
				sel_ds_in => sel_ds_in_sig,
				ds_pick => ds_pick_sig,
				rs_op => rs_op_sig,
				sel_rs_in => sel_rs_in_sig,
				alu_op => alu_op_sig,
				sel_alu_A => sel_alu_A_sig,
				tos_load => tos_load_sig,
				pc_load => pc_load_sig,
				sel_pc_D => sel_pc_D_sig,
				sel_addr => sel_addr_sig,
				cir_load => cir_load_sig,
				sel_inst => sel_inst_sig,

				address => address,
				writedata => writedata
			);
end architecture;
