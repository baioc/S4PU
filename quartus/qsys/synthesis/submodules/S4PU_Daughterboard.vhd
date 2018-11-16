-----------------------------------------
--													--
-- Module: S4PU_Daughterboard				--
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


entity S4PU_Daughterboard is
	generic (ARCH: positive := 16);	-- Internal bus size, must be at least 16-bit.
	port (
		-- SYNC --
		clock: in std_logic;
		reset_n: in std_logic;

		-- Avalon MM Slave as Bridge --
		ext_write: in std_logic;
		ext_address: in std_logic_vector(ARCH-1 downto 0);
		ext_writedata: in std_logic_vector(ARCH-1 downto 0);
		ext_readdata: out std_logic_vector(ARCH-1 downto 0);
		
		-- S4PU Conduit --
		mode: in std_logic
	);
end entity;


architecture embedded_v0 of S4PU_Daughterboard is	-- default
	-- COMPONENTS --
	component S4PU is	-- Simple Forth Processing Unit
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
	end component;
	
	component prog_rom IS	-- Quartus wizard-generated single-port ROM initialized from ./memory/prog.mif
		PORT
		(
			address	: IN STD_LOGIC_VECTOR (11 DOWNTO 0);	-- 4096 words
			clock		: IN STD_LOGIC  := '1';
			q			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	END component;
	
	component dual_ram IS	-- Quartus wizard-generated dual-port RAM
		PORT
		(
			address_a	: IN STD_LOGIC_VECTOR (13 DOWNTO 0);	-- 12288 words
			address_b	: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
			clock			: IN STD_LOGIC  := '1';
			data_a		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			data_b		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			wren_a		: IN STD_LOGIC  := '0';
			wren_b		: IN STD_LOGIC  := '0';
			q_a			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
			q_b			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	END component;


	-- CONSTANTS --
	constant MAIN_MEM_START: natural := 0;
	constant MAIN_MEM_END: natural :=	32767;
	
	constant PROG_MEM_START: natural :=	32768;
	constant PROG_MEM_END: natural :=	40959;


	-- SIGNALS --
	signal cpu_reset_n, main_mem_wren,
			 rs_overflow, rs_underflow,
			 ds_overflow, ds_underflow,
			 cpu_read, cpu_write: std_logic;

	signal cpu_address, address_range,
			 cpu_readdata, cpu_writedata,
			 prog_mem_q, main_mem_q: std_logic_vector(ARCH-1 downto 0);


	-- INTERNAL STATE --
	subtype InternalState is std_logic_vector(ARCH-1 downto 0);
	signal last_address: InternalState;


	-- DESCRIPTION --
	begin
		-- @note fixed data'length and address'length on wizard-generated memory
		assert (ARCH >= 16)
				 report "Architecture incompatible with instantiated memories: must be at least 16-bit."
				 severity FAILURE;


		-- COMP. INSTANTIATION --
		CPU: S4PU
			generic map (ARCH => ARCH)
			port map (
				clock => clock,
				reset_n => cpu_reset_n,
				mode => mode,
				rs_overflow => rs_overflow,
				rs_underflow => rs_underflow,
				ds_overflow => ds_overflow,
				ds_underflow => ds_underflow,

				read => cpu_read,
				write => cpu_write,
				address => cpu_address,
				readdata => cpu_readdata,
				writedata => cpu_writedata
			);

		PROGRAM_MEMORY: prog_rom
			port map (
				address => cpu_address(11 downto 0),
				clock => clock,
				q => prog_mem_q(15 downto 0)
			);

		MAIN_MEMORY: dual_ram
			port map (
				clock => clock,

				address_a => cpu_address(13 downto 0),
				data_a => cpu_writedata(15 downto 0),
				wren_a => main_mem_wren,
				q_a => main_mem_q(15 downto 0),

				address_b => ext_address(13 downto 0),
				data_b => ext_writedata(15 downto 0),
				wren_b => ext_write,
				q_b => ext_readdata(15 downto 0)
			);


		-- BEHAVIOUR --
		cpu_reset_n <= reset_n and	-- @note any under/overflow triggers reset
							not(rs_overflow or rs_underflow or ds_overflow or ds_underflow);

		main_mem_wren <= '1' when
									cpu_write='1'
									and (unsigned(cpu_address) >= MAIN_MEM_START)
									and (unsigned(cpu_address) <= MAIN_MEM_END)
								else '0';

		-- address register
		ME: process (clock, reset_n) is
			begin
				if (reset_n = '0') then
					last_address <= (others => '0');
				elsif (rising_edge(clock)) then
					last_address <= cpu_address;
				end if;
		end process;

		-- "output logic"
		address_range <= last_address when
									cpu_write='1'
										or ( cpu_read='1'
											  and (unsigned(cpu_address) - unsigned(last_address) /= 1) )
							  else cpu_address;	-- bypass register when not reading consecutively

		cpu_readdata <= prog_mem_q when
								(unsigned(address_range) >= PROG_MEM_START)
								and (unsigned(address_range) <= PROG_MEM_END)
							else main_mem_q;

end architecture;
