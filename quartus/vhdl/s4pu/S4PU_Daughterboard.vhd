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

		-- MEMORY EXTENSION (External Bus to Avalon Bridge) --
		read, write: out std_logic;
		address: out std_logic_vector(ARCH-1 downto 0);
		readdata: in std_logic_vector(ARCH-1 downto 0);
		writedata: out std_logic_vector(ARCH-1 downto 0);
		acknowledge: in std_logic
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


	-- CONSTANT MEMORY RANGE MAPPING --
	constant MAIN_MEM_START: natural := 0;
	constant PROG_MEM_START: natural := 32768;
	constant EXT_MEM_START: natural := 41984;

	-- @XXX DE2 COULDN'T FIT THE DESIGN SO BOARD MEMORY WAS CUT
	constant MAIN_MEM_END: natural := MAIN_MEM_START + 16383;	-- 16Ki
	constant PROG_MEM_END: natural := PROG_MEM_START + 4095;		-- 4Ki
	constant EXT_MEM_END: natural := EXT_MEM_START + 23551;		-- xA400 - xFFFF


	-- CONSTANTS --
	constant UNDEFINED: std_logic_vector(ARCH-1 downto 0) := (others => '-');


	-- SIGNALS --
	signal main_mem_wren, cpu_reset_n,
			 cpu_read, cpu_write, external,
			 rs_overflow, rs_underflow,
			 ds_overflow, ds_underflow: std_logic;

	signal avalon_read, avalon_write,
			 avalon_ren, avalon_wren: std_logic_vector(0 downto 0);

	signal cpu_address, cpu_readdata, cpu_writedata,
			 main_mem_address, main_mem_q,
			 prog_mem_address, prog_mem_q,
			 last_address, address_range, ext_mem_q,
			 avalon_in, avalon_out, avalon_addr: std_logic_vector(ARCH-1 downto 0);


	-- BEHAVIOUR --
	begin
		-- @note fixed data'length and address'length on wizard-generated memory
		assert (ARCH >= 16)
				 report "Architecture incompatible with instantiated memory: should be at least 16-bit."
				 severity FAILURE;


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

		cpu_reset_n <= reset_n and		-- @note treating und/overflow as critical errors
							not(rs_overflow or rs_underflow or ds_overflow or ds_underflow);

		-- memory mapping
		cpu_readdata <= main_mem_q when
								(unsigned(address_range) >= MAIN_MEM_START and unsigned(address_range) <= MAIN_MEM_END)
							 else prog_mem_q when
								(unsigned(address_range) >= PROG_MEM_START and unsigned(address_range) <= PROG_MEM_END)
							 else ext_mem_q when
								(unsigned(address_range) >= EXT_MEM_START and unsigned(address_range) <= EXT_MEM_END)
							 else UNDEFINED;


		MAIN_MEMORY: main_ram
			port map (
				address => main_mem_address(13 downto 0),
				clock => clock,
				data => cpu_writedata(15 downto 0),
				wren => main_mem_wren,
				q => main_mem_q(15 downto 0)
			);

		main_mem_address <= std_logic_vector(unsigned(cpu_address) - MAIN_MEM_START);

		main_mem_wren <= '1' when cpu_write='1' and
										  (unsigned(cpu_address) >= MAIN_MEM_START and unsigned(cpu_address) <= MAIN_MEM_END)
							  else '0';


		PROGRAM_MEMORY: prog_rom
			port map (
				address => prog_mem_address(11 downto 0),
				clock => clock,
				q => prog_mem_q(15 downto 0)
			);

		prog_mem_address <= std_logic_vector(unsigned(cpu_address) - PROG_MEM_START);


		ADDR_REG: Reg
			generic map (WIDTH => ARCH)
			port map (
				clock => clock,
				reset => '0',
				enable => '1',
				D => cpu_address,
				Q => last_address
			);

		address_range <= last_address when (abs(signed(cpu_address)-signed(last_address)) /= 1)
							  else cpu_address;	-- bypass register when reading consecutively


		AVALON_ADDR_REG: Reg
			generic map (WIDTH => ARCH)
			port map (
				clock => clock,
				reset => '0',
				enable => external,
				D => cpu_address,
				Q => avalon_addr
			);

		AVALON_IN_REG: Reg
			generic map (WIDTH => ARCH)
			port map (
				clock => clock,
				reset => '0',
				enable => acknowledge,
				D => readdata,
				Q => avalon_in
			);

		AVALON_OUT_REG: Reg
			generic map (WIDTH => ARCH)
			port map (
				clock => clock,
				reset => '0',
				enable => external,
				D => cpu_writedata,
				Q => avalon_out
			);

		AVALON_READ_REG: Reg
			generic map (WIDTH => 1)
			port map (
				clock => clock,
				reset => acknowledge,
				enable => external,
				D => avalon_ren,
				Q => avalon_read
			);

		AVALON_WRITE_REG: Reg
			generic map (WIDTH => 1)
			port map (
				clock => clock,
				reset => acknowledge,
				enable => external,
				D => avalon_wren,
				Q => avalon_write
			);

		avalon_ren(0) <= cpu_read;
		avalon_wren(0) <= cpu_write;
		external <= '1' when (unsigned(cpu_address) >= EXT_MEM_START and unsigned(cpu_address) <= EXT_MEM_END) else '0';
		address <= cpu_address when external='1' else avalon_addr;	-- @note interface addresses are not converted to the external address space
		ext_mem_q <= readdata when acknowledge='1' else avalon_in;
		writedata <= cpu_writedata when external='1' else avalon_out;
		read <= cpu_read when external='1' else avalon_read(0);
		write <= cpu_write when external='1' else avalon_write(0);

end architecture;
