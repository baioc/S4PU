-----------------------------------------
--													--
-- Module: S4PU_Control						--
--													--
-- Package: S4PU								--
--													--
-- Author:	Gabriel B. Sant'Anna			--
--			baiocchi.gabriel@gmail.com		--
--													--
-----------------------------------------


library ieee;
use ieee.std_logic_1164.all;


entity S4PU_Control is	-- S4PU Control Unit
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
	begin
		assert (ARCH >= 16)
				 report "Architecture should be at least 16-bits."
				 severity FAILURE;
end entity;


architecture fsm_v0 of S4PU_Control is	-- default
	-- INTERNAL STATE --
	type InternalState is (
		RESET,			FETCH,		DECODE,		CALL,
		LOAD_0,			LOAD_1,		STORE_0,		STORE_1,
		IF_FALSE,		IF_TRUE,		BRANCH,		RET,
		DROP,				LIT,			PICK_0,		PICK_1,
		TO_R,				R_FROM,		ALU_NOT,		ALU_OR,
		ALU_AND,			ALU_XOR,		ALU_ADD,		ALU_SUB,
		ALU_INC,			ALU_DEC,		ALU_EQUAL,	ALU_LESS,
		ALU_GREATER,	ALU_ZER,		ALU_NEG,		ALU_POS,
		ALU_SAL,			ALU_SAR,		DUP,			SWAP_0,
		SWAP_1,			ALU_SBL,		ALU_SBR
	);
	-- @todo attribute enum_encoding ... : string ... of InternalState: type is ...
	signal curr_state, next_state: InternalState;


	-- INSTRUCTION DECODING FUNCTION
	function NEXT_STATE_DECODE (
			inst: std_logic_vector(15 downto 0);
			zero: std_logic
	) return InternalState is
		variable goto_state: InternalState;
			begin
				if (inst(inst'right) = '0') then
					goto_state := CALL;

				elsif (inst = x"8001") then
					goto_state := DECODE;

				elsif (inst = x"8003") then
					goto_state := LOAD_0;

				elsif (inst = x"8005") then
					goto_state := STORE_0;

				elsif (inst = x"8007") then
					if (zero = '1') then
						goto_state := IF_FALSE;
					else
						goto_state := IF_TRUE;
					end if;

				elsif (inst = x"8009") then
					goto_state := BRANCH;

				elsif (inst = x"800D") then
					goto_state := RET;

				elsif (inst = x"800F") then
					goto_state := DROP;

				elsif (inst = x"8011") then
					goto_state := LIT;

				elsif (inst = x"8013") then
					goto_state := PICK_0;

				elsif (inst = x"8015") then
					goto_state := TO_R;

				elsif (inst = x"8017") then
					goto_state := R_FROM;

				elsif (inst = x"8019") then
					goto_state := ALU_NOT;

				elsif (inst = x"801B") then
					goto_state := ALU_OR;

				elsif (inst = x"801D") then
					goto_state := ALU_AND;

				elsif (inst = x"801F") then
					goto_state := ALU_XOR;

				elsif (inst = x"8021") then
					goto_state := ALU_ADD;

				elsif (inst = x"8023") then
					goto_state := ALU_SUB;

				elsif (inst = x"8025") then
					goto_state := ALU_INC;

				elsif (inst = x"8027") then
					goto_state := ALU_DEC;

				elsif (inst = x"8029") then
					goto_state := ALU_EQUAL;

				elsif (inst = x"802B") then
					goto_state := ALU_LESS;

				elsif (inst = x"802D") then
					goto_state := ALU_GREATER;

				elsif (inst = x"8035") then
					goto_state := ALU_ZER;

				elsif (inst = x"8037") then
					goto_state := ALU_NEG;

				elsif (inst = x"8039") then
					goto_state := ALU_POS;

				elsif (inst = x"8041") then
					goto_state := ALU_SAL;

				elsif (inst = x"8043") then
					goto_state := ALU_SAR;

				elsif (inst = x"804D") then
					goto_state := DUP;

				elsif (inst = x"804F") then
					goto_state := SWAP_0;

				elsif (inst = x"8051") then
					goto_state := ALU_SBL;

				elsif (inst = x"8053") then
					goto_state := ALU_SBR;

				-- undefined instruction code
				else
					goto_state := RESET;
				end if;

				return goto_state;
	end NEXT_STATE_DECODE;


	-- CONSTANT OPCODES --
	-- stacks
	constant STACK_RESET: std_logic_vector(1 downto 0) :=	"00";
	constant STACK_POP: std_logic_vector(1 downto 0) :=	"01";
	constant STACK_PUSH: std_logic_vector(1 downto 0) :=	"10";
	constant STACK_NOP: std_logic_vector(1 downto 0) :=	"11";

	-- alu
	constant ALU_OP_NOP: std_logic_vector(3 downto 0) :=	"0000";
	constant ALU_OP_ADD: std_logic_vector(3 downto 0) :=	"0001";
	constant ALU_OP_SUB: std_logic_vector(3 downto 0) :=	"0010";
	constant ALU_OP_CET: std_logic_vector(3 downto 0) :=	"0011";
	constant ALU_OP_CLT: std_logic_vector(3 downto 0) :=	"0100";
	constant ALU_OP_CGT: std_logic_vector(3 downto 0) :=	"0101";
	constant ALU_OP_ZER: std_logic_vector(3 downto 0) :=	"0110";
	constant ALU_OP_NEG: std_logic_vector(3 downto 0) :=	"0111";
	constant ALU_OP_POS: std_logic_vector(3 downto 0) :=	"1000";
	constant ALU_OP_XOR: std_logic_vector(3 downto 0) :=	"1001";
	constant ALU_OP_OR: std_logic_vector(3 downto 0) :=	"1010";
	constant ALU_OP_AND: std_logic_vector(3 downto 0) :=	"1011";
	constant ALU_OP_SAL: std_logic_vector(3 downto 0) :=	"1100";
	constant ALU_OP_SAR: std_logic_vector(3 downto 0) :=	"1101";
	constant ALU_OP_SBL: std_logic_vector(3 downto 0) :=	"1110";
	constant ALU_OP_SBR: std_logic_vector(3 downto 0) :=	"1111";


	-- BEHAVIOUR --
	begin
		-- FSM next state logic
		NSL: process (curr_state, reset_n, instruction, alu_zero) is
			begin
				if (reset_n = '0') then	-- synchronous reset
					next_state <= RESET;
				else
					case curr_state is
						when FETCH|CALL|IF_FALSE|IF_TRUE|BRANCH|RET|LIT =>
							next_state <= DECODE;

						when RESET =>
							next_state <= FETCH;

						when LOAD_0 =>
							next_state <= LOAD_1;

						when STORE_0 =>
							next_state <= STORE_1;

						when PICK_0 =>
							next_state <= PICK_1;

						when SWAP_0 =>
							next_state <= SWAP_1;

						when others =>	-- f(instruction, alu_zero)
							next_state <= NEXT_STATE_DECODE(instruction(15 downto 0), alu_zero);
					end case;
				end if;
		end process;


		-- memory element
		ME: process (clock) is
			begin
				if (rising_edge(clock)) then
					curr_state <= next_state;
				end if;
		end process;


		-- output logic
		with curr_state select ds_op <=
			STACK_RESET when RESET,
			STACK_POP when STORE_0|STORE_1|IF_FALSE|IF_TRUE|DROP|
								TO_R|ALU_OR|ALU_AND|ALU_XOR|ALU_ADD|
								ALU_SUB|ALU_EQUAL|ALU_LESS|ALU_GREATER|SWAP_0,
			STACK_PUSH when LIT|R_FROM|DUP|SWAP_1,
			STACK_NOP when others;

		with curr_state select sel_ds_in <=
			'1' when SWAP_1,	-- RS
			'0' when others;	-- TOS

		with curr_state select ds_pick <=
			'1' when PICK_0,	-- TOS(7 downto 0)
			'0' when others;	-- "0"

		with curr_state select rs_op <=
			STACK_RESET when RESET,
			STACK_POP when RET|R_FROM|SWAP_1,
			STACK_PUSH when CALL|TO_R|SWAP_0,
			STACK_NOP when others;

		with curr_state select sel_rs_in <=
			'0' when CALL,		-- PC
			'1' when others;	-- TOS

		with curr_state select alu_op <=
			ALU_OP_ADD when ALU_ADD|ALU_INC|ALU_DEC,
			ALU_OP_SUB when ALU_NOT|ALU_SUB,
			ALU_OP_CET when ALU_EQUAL,
			ALU_OP_CLT when ALU_LESS,
			ALU_OP_CGT when ALU_GREATER,
			ALU_OP_ZER when ALU_ZER,
			ALU_OP_NEG when ALU_NEG,
			ALU_OP_POS when ALU_POS,
			ALU_OP_XOR when ALU_XOR,
			ALU_OP_OR when ALU_OR,
			ALU_OP_AND when ALU_AND,
			ALU_OP_SAL when ALU_SAL,
			ALU_OP_SAR when ALU_SAR,
			ALU_OP_SBL when ALU_SBL,
			ALU_OP_SBR when ALU_SBR,
			ALU_OP_NOP when others;

		with curr_state select sel_alu_A <=
			"000" when RESET,															-- "0"
			"001" when ALU_INC,														-- "+1"
			"010" when ALU_NOT|ALU_DEC,											-- "-1"
			"100" when STORE_1|IF_FALSE|IF_TRUE|DROP|PICK_1|				------|
						  TO_R|ALU_OR|ALU_AND|ALU_XOR|ALU_ADD|					-- DS |
						  ALU_SUB|ALU_EQUAL|ALU_LESS|ALU_GREATER|SWAP_0,	------|
			"101" when R_FROM,														-- RS
			"110" when LOAD_1|LIT,													-- MEM
			"011" when others;														-- TOS

		tos_load <= '1';

		with curr_state select pc_load <=
			'0' when LOAD_0|STORE_0|PICK_0|SWAP_0,
			'1' when RESET|FETCH|CALL|IF_FALSE|IF_TRUE|BRANCH|RET|LIT,
			instruction(instruction'right) when others; -- g(instruction)

		with curr_state select sel_pc_D <=
			("00" & mode) when RESET,		-- h(mode)
			"011" when CALL,					-- CIR + 1
			"100" when IF_FALSE|BRANCH,	-- MEM + 1
			"101" when RET,					-- RS + 1
			"010" when others;				-- PC + 1

		with curr_state select sel_addr <=
			"001" when LOAD_0|STORE_0,		-- TOS
			"010" when IF_FALSE|BRANCH,	-- MEM
			"011" when CALL,					-- CIR
			"100" when RET,					-- RS
			"000" when others;				-- PC

		with curr_state select read <=
			'0' when STORE_0|RESET|PICK_0|SWAP_0,
			'1' when others;

		with curr_state select write <=
			'1' when STORE_0,
			'0' when others;

		with curr_state select cir_load <=
			'0' when LOAD_1|STORE_1|PICK_1|SWAP_1,
			'1' when others;

		with curr_state select sel_inst <=
			'1' when LOAD_1|STORE_1|PICK_1|SWAP_1,	-- CIR
			'0' when others;								-- MEM

		-- route stack error status to external output
		o_rs_overflow <= i_rs_overflow;
		o_rs_underflow <= i_rs_underflow;
		o_ds_overflow <= i_ds_overflow;
		o_ds_underflow <= i_ds_underflow;

end architecture;
