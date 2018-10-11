-----------------------------------------
--													--
-- Module: ALU_16								--
--													--
-- Package: S4PU								--
--													--
-- Author:	Gabriel B. Sant'Anna			--
--			baiocchi.gabriel@gmail.com		--
--													--
-----------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;	-- type conversion


entity ALU_16 is	-- 16-operation ALU
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
	begin
		assert (WORD > 8)
				 report "Invalid word size: Should be greater than 8."
				 severity FAILURE;
end entity;


architecture parallel of ALU_16 is	-- default
	-- SIGNALS --
	signal result,
			 nop, add, sub,
			 op_xor, op_or, op_and,
			 op_sla, op_sra, op_sll, op_srl: std_logic_vector(WORD downto 0);

	signal comp_equal, comp_less, comp_greater,
			 A_zero, A_negative, A_positive: std_logic;


	-- CONSTANT OPCODES --
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
		-- A
		nop <= '0' & A;

		-- A + B
		add <= std_logic_vector(signed(A(A'left) & A) + signed(B(B'left) & B));

		-- A - B
		sub <= std_logic_vector(signed(A(A'left) & A) - signed(B(B'left) & B));

		-- A = B
		comp_equal <= '1' when signed(sub) = 0 else '0';	-- A = B <-> A-B = 0

		-- A < B
		comp_less <= sub(sub'left);	-- A < B <-> A-B < 0

		-- A > B
		comp_greater <= comp_equal nor comp_less;	-- A > B <-> ¬(A=B) & ¬(A<B)

		-- A = 0
		A_zero <= '1' when signed(A) = 0 else '0';

		-- A < 0
		A_negative <= A(A'left);

		-- A > 0
		A_positive <= A_zero nor A_negative;

		-- A xor B
		op_xor <= '0' & (A xor B);

		-- A or B
		op_or <= '0' & (A or B);

		-- A and B
		op_and <= '0' & (A and B);

		-- arithmetic shift A 1 bit left
		op_sla <= A & '0';

		-- arithmetic shift A 1 bit right
		op_sra <= A(A'left) & A(A'left) & A(A'left downto A'right+1);

		-- logical shift A 8 bits left
		op_sll(7 downto 0) <= (others => '0');
		op_sll(WORD downto 8) <= A(A'left-7 downto A'right);

		-- logical shift A 8 bits right
		op_srl(WORD downto WORD-8) <= (others => '0');
		op_srl(WORD-9 downto 0) <= A(A'left downto A'right+8);


		-- temporary result
		with op select result <=
			add								when ALU_OP_ADD,
			sub								when ALU_OP_SUB,
			(others => comp_equal)		when ALU_OP_CET,
			(others => comp_less)		when ALU_OP_CLT,
			(others => comp_greater)	when ALU_OP_CGT,
			(others => A_zero)			when ALU_OP_ZER,
			(others => A_negative)		when ALU_OP_NEG,
			(others => A_positive)		when ALU_OP_POS,
			op_xor							when ALU_OP_XOR,
			op_or								when ALU_OP_OR,
			op_and							when ALU_OP_AND,
			op_sla							when ALU_OP_SAL,
			op_sra							when ALU_OP_SAR,
			op_sll							when ALU_OP_SBL,
			op_srl							when ALU_OP_SBR,
			nop								when others; -- ALU_OP_NOP

		-- overflow detect
		with op select overflow <=
			result(result'left) xor result(result'left-1)	when ALU_OP_ADD|ALU_OP_SUB|ALU_OP_SAL, -- possible arithmetic overflow
			'0'															when others;

		-- zero detect
		zero <= '1' when signed(result(WORD-1 downto 0)) = 0 else '0';

		-- ALU out
		Y <= result(WORD-1 downto 0);

end architecture;
