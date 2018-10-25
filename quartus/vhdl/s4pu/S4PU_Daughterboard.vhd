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
use ieee.numeric_std.all;	-- type conversion


entity S4PU_Daughterboard is
	generic (ARCH: positive := 16);	-- Architecture word size, should be at least 16-bit
	port (
		-- CLOCK --
		clock: in std_logic;

		-- CPU CONTROL --
		reset_n: in std_logic;	-- active low, synchronous
		mode: in std_logic;

		-- MEMORY EXTENSION (Avalon spec.) --
		read, write: out std_logic;
		address: out std_logic_vector(ARCH-1 downto 0);
		readdata: in std_logic_vector(ARCH-1 downto 0);
		writedata: out std_logic_vector(ARCH-1 downto 0)
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

	component main_ram IS	-- Altera Quartus wizard-generated single-port RAM
		PORT
		(
			address	: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			wren		: IN STD_LOGIC ;
			q			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	END component;

	component prog_rom IS	-- Altera Quartus wizard-generated single-port ROM from ./memory/prog.mif
		PORT
		(
			address	: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			q			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	end component;


	-- CONSTANT MEMORY RANGE MAPPING --
	constant MAIN_MEM_START: natural := 0;
	constant PROG_MEM_START: natural := 32768;
	constant EXT_MEM_START: natural := 41984;

	-- @XXX DE2 COULDN'T FIT THE DESIGN SO BOARD MEMORY WAS CUT
	constant MAIN_MEM_END: natural := MAIN_MEM_START + 16383;	-- 16Ki
	constant PROG_MEM_END: natural := PROG_MEM_START + 4095;		-- 4Ki
	constant EXT_MEM_END: natural := EXT_MEM_START + 23551;		-- xA400 - xFFFF


	-- SIGNALS --
	signal main_mem_wren, cpu_reset_n,
			 cpu_read, cpu_write,
			 rs_overflow, rs_underflow,
			 ds_overflow, ds_underflow: std_logic;

	signal cpu_address, address_range,
			 cpu_readdata, cpu_writedata,
			 main_mem_address, main_mem_q,
			 prog_mem_address, prog_mem_q: std_logic_vector(ARCH-1 downto 0);


	-- INTERNAL STATE --
	subtype InternalState is std_logic_vector(ARCH-1 downto 0);
	signal last_address: InternalState;


	-- DESCRIPTION --
	begin
		-- @note fixed data'length and address'length on wizard-generated memory
		assert (ARCH >= 16)
				 report "Architecture incompatible with instantiated memory: should be at least 16-bit."
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

		MAIN_MEMORY: main_ram
			port map (
				address => main_mem_address(13 downto 0),
				clock => clock,
				data => cpu_writedata(15 downto 0),
				wren => main_mem_wren,
				q => main_mem_q(15 downto 0)
			);

		PROGRAM_MEMORY: prog_rom
			port map (
				address => prog_mem_address(11 downto 0),
				clock => clock,
				q => prog_mem_q(15 downto 0)
			);


		-- BEHAVIOUR --
		writedata <= cpu_writedata;
		address <= cpu_address;

		-- @note stack errors are treated as critical errors that reset the cpu
		cpu_reset_n <= reset_n and not(rs_overflow or rs_underflow or ds_overflow or ds_underflow);

		-- address range conversion
		main_mem_address <= std_logic_vector(unsigned(cpu_address) - MAIN_MEM_START);
		prog_mem_address <= std_logic_vector(unsigned(cpu_address) - PROG_MEM_START);

		-- memory mapping
		main_mem_wren <= '1' when cpu_write='1' and (unsigned(cpu_address) >= MAIN_MEM_START) and (unsigned(cpu_address) <= MAIN_MEM_END)
								else '0';

		read <= '1' when cpu_read='1' and (unsigned(cpu_address) >= EXT_MEM_START) and (unsigned(cpu_address) <= EXT_MEM_END)
					else '0';
		write <= '1' when cpu_write='1' and (unsigned(cpu_address) >= EXT_MEM_START) and (unsigned(cpu_address) <= EXT_MEM_END)
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

		-- output logic
		address_range <= last_address when cpu_write='1' or (cpu_read='1' and (unsigned(cpu_address)-unsigned(last_address) /= 1))
							  else cpu_address;	-- bypass register when not reading consecutively

		cpu_readdata <= main_mem_q when (unsigned(address_range) >= MAIN_MEM_START)
											and (unsigned(address_range) <= MAIN_MEM_END) else
							 prog_mem_q when (unsigned(address_range) >= PROG_MEM_START)
											and (unsigned(address_range) <= PROG_MEM_END) else
							 readdata when (unsigned(address_range) >= EXT_MEM_START)
											and (unsigned(address_range) <= EXT_MEM_END)
							 else (others => '1'); -- undefined

end architecture;
