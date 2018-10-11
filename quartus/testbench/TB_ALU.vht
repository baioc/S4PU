-----------------------------------------
--													--
-- Module: TB_ALU								--
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


entity TB_ALU is
end entity;


architecture testbench_16 of TB_ALU is	-- default
	-- DUT INTERFACE --
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


	-- CONSTANTS --
	constant LAG: time := 20 ns;

	constant N: natural := 16;

	-- opcodes
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
	signal op: std_logic_vector(3 downto 0);
	signal A, B, Y: std_logic_vector(N-1 downto 0);
	signal zero, overflow: std_logic;


	-- TESTING --
	begin
		UUT: ALU_16
			generic map (WORD => N)
			port map (
				op => op,
				A => A,
				B => B,
				Y => Y,
				zero => zero,
				overflow => overflow
			);

		STIMULUS: process is
			begin
				wait for LAG;

				-- Y = A
				op <= ALU_OP_NOP;
				A <= x"C0DE";
				wait for LAG;
				assert ((Y=x"C0DE") and (zero='0') and (overflow='0'))
						 report "ALU error on operation NOP"
						 severity ERROR;
				op <= ALU_OP_NOP;
				A <= x"0000";
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation NOP"
						 severity ERROR;

				-- Y = A + B
				op <= ALU_OP_ADD;
				A <= std_logic_vector(to_signed(0, N));
				B <= std_logic_vector(to_signed(0, N));
				wait for LAG;
				assert ((signed(Y)=0) and (zero='1') and (overflow='0'))
						 report "ALU error on operation ADD"
						 severity ERROR;
				op <= ALU_OP_ADD;
				A <= std_logic_vector(to_signed(32767, N));
				B <= std_logic_vector(to_signed(1, N));
				wait for LAG;
				assert ((signed(Y)=-32768) and (zero='0') and (overflow='1'))
						 report "ALU error on operation ADD"
						 severity ERROR;
				op <= ALU_OP_ADD;
				A <= std_logic_vector(to_signed(-32768, N));
				B <= std_logic_vector(to_signed(-1, N));
				wait for LAG;
				assert ((signed(Y)=32767) and (zero='0') and (overflow='1'))
						 report "ALU error on operation ADD"
						 severity ERROR;

				-- Y = A - B
				op <= ALU_OP_SUB;
				A <= std_logic_vector(to_signed(0, N));
				B <= std_logic_vector(to_signed(0, N));
				wait for LAG;
				assert ((signed(Y)=0) and (zero='1') and (overflow='0'))
						 report "ALU error on operation SUB"
						 severity ERROR;
				op <= ALU_OP_SUB;
				A <= std_logic_vector(to_signed(32767, N));
				B <= std_logic_vector(to_signed(-1, N));
				wait for LAG;
				assert ((signed(Y)=-32768) and (zero='0') and (overflow='1'))
						 report "ALU error on operation SUB"
						 severity ERROR;
				op <= ALU_OP_SUB;
				A <= std_logic_vector(to_signed(-32768, N));
				B <= std_logic_vector(to_signed(1, N));
				wait for LAG;
				assert ((signed(Y)=32767) and (zero='0') and (overflow='1'))
						 report "ALU error on operation SUB"
						 severity ERROR;

				-- Y = ?(A = B)
				op <= ALU_OP_CET;
				A <= x"C0DE";
				B <= x"1337";
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation EQ"
						 severity ERROR;
				op <= ALU_OP_CET;
				A <= x"FEED";
				B <= x"FEED";
				wait for LAG;
				assert ((Y=x"FFFF") and (zero='0') and (overflow='0'))
						 report "ALU error on operation EQ"
						 severity ERROR;

				-- Y = ?(A < B)
				op <= ALU_OP_CLT;
				A <= std_logic_vector(to_signed(42, N));
				B <= std_logic_vector(to_signed(-55, N));
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation LESS"
						 severity ERROR;
				op <= ALU_OP_CLT;
				A <= std_logic_vector(to_signed(-42, N));
				B <= std_logic_vector(to_signed(55, N));
				wait for LAG;
				assert ((Y=x"FFFF") and (zero='0') and (overflow='0'))
						 report "ALU error on operation LESS"
						 severity ERROR;
				op <= ALU_OP_CLT;
				A <= std_logic_vector(to_signed(7, N));
				B <= std_logic_vector(to_signed(7, N));
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation LESS"
						 severity ERROR;

				-- Y = ?(A > B)
				op <= ALU_OP_CGT;
				A <= std_logic_vector(to_signed(42, N));
				B <= std_logic_vector(to_signed(-55, N));
				wait for LAG;
				assert ((Y=x"FFFF") and (zero='0') and (overflow='0'))
						 report "ALU error on operation GREATER"
						 severity ERROR;
				op <= ALU_OP_CGT;
				A <= std_logic_vector(to_signed(-55, N));
				B <= std_logic_vector(to_signed(42, N));
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation GREATER"
						 severity ERROR;
				op <= ALU_OP_CGT;
				A <= std_logic_vector(to_signed(7, N));
				B <= std_logic_vector(to_signed(7, N));
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation GREATER"
						 severity ERROR;

				-- Y = ?(A = 0)
				op <= ALU_OP_ZER;
				A <= x"AAAA";
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation ZER"
						 severity ERROR;
				op <= ALU_OP_ZER;
				A <= x"0000";
				wait for LAG;
				assert ((Y=x"FFFF") and (zero='0') and (overflow='0'))
						 report "ALU error on operation ZER"
						 severity ERROR;

				-- Y = ?(A < 0)
				op <= ALU_OP_NEG;
				A <= std_logic_vector(to_signed(0, N));
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation NEG"
						 severity ERROR;
				op <= ALU_OP_NEG;
				A <= std_logic_vector(to_signed(5, N));
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation NEG"
						 severity ERROR;
				op <= ALU_OP_NEG;
				A <= std_logic_vector(to_signed(-5, N));
				wait for LAG;
				assert ((Y=x"FFFF") and (zero='0') and (overflow='0'))
						 report "ALU error on operation NEG"
						 severity ERROR;

				-- Y = ?(A > 0)
				op <= ALU_OP_POS;
				A <= std_logic_vector(to_signed(0, N));
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation POS"
						 severity ERROR;
				op <= ALU_OP_POS;
				A <= std_logic_vector(to_signed(5, N));
				wait for LAG;
				assert ((Y=x"FFFF") and (zero='0') and (overflow='0'))
						 report "ALU error on operation POS"
						 severity ERROR;
				op <= ALU_OP_POS;
				A <= std_logic_vector(to_signed(-5, N));
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation POS"
						 severity ERROR;

				-- Y = A xor B
				op <= ALU_OP_XOR;
				A <= x"AAAA";
				B <= x"5555";
				wait for LAG;
				assert ((Y=x"FFFF") and (zero='0') and (overflow='0'))
						 report "ALU error on operation XOR"
						 severity ERROR;
				op <= ALU_OP_XOR;
				A <= x"BBBB";
				B <= x"BBBB";
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation XOR"
						 severity ERROR;

				-- Y = A or B
				op <= ALU_OP_OR;
				A <= x"FAFA";
				B <= x"F5F5";
				wait for LAG;
				assert ((Y=x"FFFF") and (zero='0') and (overflow='0'))
						 report "ALU error on operation OR"
						 severity ERROR;
				op <= ALU_OP_OR;
				A <= x"0000";
				B <= x"CCCC";
				wait for LAG;
				assert ((Y=x"CCCC") and (zero='0') and (overflow='0'))
						 report "ALU error on operation OR"
						 severity ERROR;

				-- Y = A and B
				op <= ALU_OP_AND;
				A <= x"AAAA";
				B <= x"5555";
				wait for LAG;
				assert ((Y=x"0000") and (zero='1') and (overflow='0'))
						 report "ALU error on operation AND"
						 severity ERROR;
				op <= ALU_OP_AND;
				A <= x"8000";
				B <= x"FFFF";
				wait for LAG;
				assert ((Y=x"8000") and (zero='0') and (overflow='0'))
						 report "ALU error on operation AND"
						 severity ERROR;

				-- Y = A * 2
				op <= ALU_OP_SAL;
				A <= std_logic_vector(to_signed(-160, N));
				wait for LAG;
				assert ((signed(Y)=-320) and (zero='0') and (overflow='0'))
						 report "ALU error on operation SAL"
						 severity ERROR;
				op <= ALU_OP_SAL;
				A <= std_logic_vector(to_signed(16384, N));
				wait for LAG;
				assert ((signed(Y)=-32768) and (zero='0') and (overflow='1'))
						 report "ALU error on operation SAL"
						 severity ERROR;

				-- Y = A / 2
				op <= ALU_OP_SAR;
				A <= std_logic_vector(to_signed(320, N));
				wait for LAG;
				assert ((signed(Y)=160) and (zero='0') and (overflow='0'))
						 report "ALU error on operation SAR"
						 severity ERROR;
				op <= ALU_OP_SAR;
				A <= std_logic_vector(to_signed(-3, N));
				wait for LAG;
				assert ((signed(Y)=-2) and (zero='0') and (overflow='0'))
						 report "ALU error on operation SAR"
						 severity ERROR;

				-- Y = A << 8
				op <= ALU_OP_SBL;
				A <= x"ABCD";
				wait for LAG;
				assert ((Y=x"CD00") and (zero='0') and (overflow='0'))
						 report "ALU error on operation SBL"
						 severity ERROR;

				-- Y = A >> 8
				op <= ALU_OP_SBR;
				A <= x"ABCD";
				wait for LAG;
				assert ((Y=x"00AB") and (zero='0') and (overflow='0'))
						 report "ALU error on operation SBR"
						 severity ERROR;

				-- TOTAL TIME : 37 * LAG
		end process;

end architecture;
