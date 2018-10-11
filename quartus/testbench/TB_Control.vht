-----------------------------------------
--													--
-- Module: TB_Control						--
--													--
-- Package: Testbench						--
--													--
-- Author:	Gabriel B. Sant'Anna			--
--			baiocchi.gabriel@gmail.com		--
--													--
-----------------------------------------


library ieee;
use ieee.std_logic_1164.all;


entity TB_Control is
end entity;


architecture testbench_truthtable of TB_Control is	-- default
	-- DUT INTERFACE --
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


	-- CONSTANTS --
	constant T: time := 20 ns;
	constant LAG: time := 10 ns;

	-- instruction opcodes
	constant c_CALL: std_logic_vector(15 downto 0) :=		x"0000";
	constant c_NOP: std_logic_vector(15 downto 0) :=		x"8001";
	constant c_LOAD: std_logic_vector(15 downto 0) :=		x"8003";
	constant c_STORE: std_logic_vector(15 downto 0) :=		x"8005";
	constant c_IF: std_logic_vector(15 downto 0) :=			x"8007";
	constant c_BRANCH: std_logic_vector(15 downto 0) :=	x"8009";
	constant c_RET: std_logic_vector(15 downto 0) :=		x"800D";
	constant c_DROP: std_logic_vector(15 downto 0) :=		x"800F";
	constant c_LIT: std_logic_vector(15 downto 0) :=		x"8011";
	constant c_PICK: std_logic_vector(15 downto 0) :=		x"8013";
	constant c_TO_R: std_logic_vector(15 downto 0) :=		x"8015";
	constant c_R_FROM: std_logic_vector(15 downto 0) :=	x"8017";
	constant c_ALU_NOT: std_logic_vector(15 downto 0) :=	x"8019";
	constant c_ALU_OR: std_logic_vector(15 downto 0) :=	x"801B";
	constant c_ALU_AND: std_logic_vector(15 downto 0) :=	x"801D";
	constant c_ALU_XOR: std_logic_vector(15 downto 0) :=	x"801F";
	constant c_ALU_ADD: std_logic_vector(15 downto 0) :=	x"8021";
	constant c_ALU_SUB: std_logic_vector(15 downto 0) :=	x"8023";
	constant c_ALU_INC: std_logic_vector(15 downto 0) :=	x"8025";
	constant c_ALU_DEC: std_logic_vector(15 downto 0) :=	x"8027";
	constant c_ALU_CET: std_logic_vector(15 downto 0) :=	x"8029";
	constant c_ALU_CLT: std_logic_vector(15 downto 0) :=	x"802B";
	constant c_ALU_CGT: std_logic_vector(15 downto 0) :=	x"802D";
	constant c_ALU_ZER: std_logic_vector(15 downto 0) :=	x"8035";
	constant c_ALU_NEG: std_logic_vector(15 downto 0) :=	x"8037";
	constant c_ALU_POS: std_logic_vector(15 downto 0) :=	x"8039";
	constant c_ALU_SAL: std_logic_vector(15 downto 0) :=	x"8041";
	constant c_ALU_SAR: std_logic_vector(15 downto 0) :=	x"8043";
	constant c_DUP: std_logic_vector(15 downto 0) :=		x"804D";
	constant c_SWAP: std_logic_vector(15 downto 0) :=		x"804F";
	constant c_ALU_SBL: std_logic_vector(15 downto 0) :=	x"8051";
	constant c_ALU_SBR: std_logic_vector(15 downto 0) :=	x"8053";

	-- stack opcodes
	constant STACK_RESET: std_logic_vector(1 downto 0) :=	"00";
	constant STACK_POP: std_logic_vector(1 downto 0) :=	"01";
	constant STACK_PUSH: std_logic_vector(1 downto 0) :=	"10";
	constant STACK_NOP: std_logic_vector(1 downto 0) :=	"11";

	-- alu opcodes
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


	-- SIGNALS --
	signal clock, reset_n, mode, alu_zero,
		    sel_ds_in, ds_pick, sel_rs_in,
		    tos_load, pc_load, cir_load, sel_inst,
		    o_rs_overflow, o_rs_underflow,
		    o_ds_overflow, o_ds_underflow,
		    read, write: std_logic;

	signal instruction: std_logic_vector(15 downto 0);

	signal ds_op, rs_op: std_logic_vector(1 downto 0);

	signal alu_op: std_logic_vector(3 downto 0);

	signal sel_alu_A, sel_pc_D, sel_addr: std_logic_vector(2 downto 0);


	-- TESTING --
	begin
		UUT: S4PU_Control
			generic map (ARCH => 16)
			port map (
				clock => clock,

				reset_n => reset_n,
				mode => mode,

				instruction => instruction,
				alu_zero => alu_zero,
				i_rs_overflow => '-',
				i_rs_underflow => '-',
				i_ds_overflow => '-',
				i_ds_underflow => '-',

				ds_op => ds_op,
				sel_ds_in => sel_ds_in,
				ds_pick => ds_pick,
				rs_op => rs_op,
				sel_rs_in => sel_rs_in,
				alu_op => alu_op,
				sel_alu_A => sel_alu_A,
				tos_load => tos_load,
				pc_load => pc_load,
				sel_pc_D => sel_pc_D,
				sel_addr => sel_addr,
				cir_load => cir_load,
				sel_inst => sel_inst,

				o_rs_overflow => o_rs_overflow,
				o_rs_underflow => o_rs_underflow,
				o_ds_overflow => o_ds_overflow,
				o_ds_underflow => o_ds_underflow,
				read => read,
				write => write
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

				reset_n <= '0';
				mode <= '1';
				wait until rising_edge(clock);
				wait for LAG;
				assert ((ds_op=STACK_RESET) and (ds_pick='0') and (rs_op=STACK_RESET) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="000") and
						 (pc_load='1') and (sel_pc_D="001") and (write='0'))
						report "Dirty state: RESET .1"
						severity ERROR;

				reset_n <= '0';
				mode <= '0';
				wait until rising_edge(clock);
				wait for LAG;
				assert ((ds_op=STACK_RESET) and (ds_pick='0') and (rs_op=STACK_RESET) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="000") and
						 (pc_load='1') and (sel_pc_D="000") and (write='0'))
						report "Dirty state: RESET .0"
						severity ERROR;

				reset_n <= '1';
				wait until rising_edge(clock);
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1'))
						report "Dirty state: FETCH"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_NOP;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: DECODE after FETCH"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_CALL;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='0') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: NOP(DECODE) after DECODE"
						severity ERROR;
				wait until rising_edge(clock);

				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and
						 (rs_op=STACK_PUSH) and (sel_rs_in='0') and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="011") and
						 (sel_addr="011") and (write='0') and (read='1'))
						report "Dirty state: CALL after DECODE"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_LOAD;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: DECODE after CALL"
						severity ERROR;
				wait until rising_edge(clock);

				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='0') and
						 (sel_addr="001") and (write='0') and (read='1') and
						 (cir_load='1'))
						report "Dirty state: LOAD_0 after DECODE"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_STORE;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="110") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='0') and (sel_inst='1'))
						report "Dirty state: LOAD_1"
						severity ERROR;
				wait until rising_edge(clock);

				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='0') and
						 (sel_addr="001") and (write='1') and (read='0') and
						 (cir_load='1'))
						report "Dirty state: STORE_0 after LOAD"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_IF;
				alu_zero <= '1';
				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='0') and (sel_inst='1'))
						report "Dirty state: STORE_1"
						severity ERROR;
				wait until rising_edge(clock);

				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="100") and
						 (sel_addr="010") and (write='0') and (read='1'))
						report "Dirty state: IF_FALSE after STORE"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_IF;
				alu_zero <= '0';
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: DECODE after IF(false)"
						severity ERROR;
				wait until rising_edge(clock);

				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1'))
						report "Dirty state: IF_TRUE after DECODE"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_BRANCH;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: DECODE after IF(true)"
						severity ERROR;
				wait until rising_edge(clock);

				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="100") and
						 (sel_addr="010") and (write='0') and (read='1'))
						report "Dirty state: BRANCH after DECODE"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_RET;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: DECODE after BRANCH"
						severity ERROR;
				wait until rising_edge(clock);

				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_POP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="101") and
						 (sel_addr="100") and (write='0') and (read='1'))
						report "Dirty state: RET after DECODE"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_DROP;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: DECODE after RET"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_LIT;
				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: DROP after DECODE"
						severity ERROR;
				wait until rising_edge(clock);

				wait for LAG;
				assert ((ds_op=STACK_PUSH) and (sel_ds_in='0') and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="110") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1'))
						report "Dirty state: LIT after DROP"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_PICK;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: DECODE after LIT"
						severity ERROR;
				wait until rising_edge(clock);

				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='1') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='0') and (write='0') and (cir_load='1'))
						report "Dirty state: PICK_0 after DECODE"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_TO_R;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='0') and (sel_inst='1'))
						report "Dirty state: PICK_1"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_R_FROM;
				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and
						 (rs_op=STACK_PUSH) and (sel_rs_in='1') and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: TO_R after PICK"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_NOT;
				wait for LAG;
				assert ((ds_op=STACK_PUSH) and (sel_ds_in='0') and
						 (ds_pick='0') and (rs_op=STACK_POP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="101") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: R_FROM after TO_R"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_OR;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_SUB) and (sel_alu_A="010") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_NOT after R_FROM"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_AND;
				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_OR) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_OR after ALU_NOT"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_XOR;
				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_AND) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_AND after ALU_OR"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_ADD;
				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_XOR) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_XOR after ALU_AND"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_SUB;
				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_ADD) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_ADD after ALU_XOR"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_INC;
				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_SUB) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_SUB after ALU_ADD"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_DEC;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_ADD) and (sel_alu_A="001") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_INC after ALU_SUB"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_CET;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_ADD) and (sel_alu_A="010") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_DEC after ALU_INC"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_CLT;
				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_CET) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_CET after ALU_DEC"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_CGT;
				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_CLT) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_CLT after ALU_CET"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_ZER;
				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_CGT) and (sel_alu_A="100") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_CGT after ALU_CLT"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_NEG;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_ZER) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_ZER after ALU_CGT"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_POS;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NEG) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_NEG after ALU_ZER"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_SAL;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_POS) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_POS after ALU_NEG"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_SAR;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_SAL) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_SAL after ALU_POS"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_SBL;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_SAR) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_SAR after ALU_SAL"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_ALU_SBR;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_SBL) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_SBL after ALU_SAR"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_DUP;
				wait for LAG;
				assert ((ds_op=STACK_NOP) and (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_SBR) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: ALU_SBR after ALU_SBL"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_SWAP;
				wait for LAG;
				assert ((ds_op=STACK_PUSH) and (sel_ds_in='0') and
						 (ds_pick='0') and (rs_op=STACK_NOP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='1') and (sel_inst='0'))
						report "Dirty state: DUP after ALU_SBR"
						severity ERROR;
				wait until rising_edge(clock);

				wait for LAG;
				assert ((ds_op=STACK_POP) and (ds_pick='0') and
						 (rs_op=STACK_PUSH) and (sel_rs_in='1') and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="100") and
						 (pc_load='0') and (write='0') and (cir_load='1'))
						report "Dirty state: SWAP_0 after DUP"
						severity ERROR;
				wait until rising_edge(clock);

				instruction <= c_NOP;
				wait for LAG;
				assert ((ds_op=STACK_PUSH) and (sel_ds_in='1') and
						 (ds_pick='0') and (rs_op=STACK_POP) and
						 (alu_op=ALU_OP_NOP) and (sel_alu_A="011") and
						 (pc_load='1') and (sel_pc_D="010") and
						 (sel_addr="000") and (write='0') and (read='1') and
						 (cir_load='0') and (sel_inst='1'))
						report "Dirty state: SWAP_1"
						severity ERROR;

				-- TOTAL TIME : 48*T + LAG
		end process;

end architecture;
