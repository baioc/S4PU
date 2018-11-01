library ieee;
use ieee.std_logic_1164.all;


entity DE2 is	-- FPGA EP2C35F672C6
	port (
		CLOCK_50: in std_logic;							-- system clock
		KEY: in std_logic_vector(0 downto 0);		-- reset button
		SW: in std_logic_vector(15 downto 0);		-- stdin & mode
		LEDR: out std_logic_vector(15 downto 0)	-- stdout
	);
end entity;


architecture nios2_computer of DE2 is	-- test
	-- COMPONENTS --
	component integration is
		port (
			clk_clk       : in  std_logic                     := 'X'; -- clk
			reset_reset_n : in  std_logic                     := 'X'; -- reset_n
			led_export    : out std_logic_vector(15 downto 0)         -- export
		);
	end component integration;
	
	-- BEHAVIOUR --
	begin
		u0 : component integration
				port map (
					clk_clk       => CLOCK_50,				--   clk.clk
					reset_reset_n => KEY(0),				-- reset.reset_n
					led_export    => LEDR(15 downto 0)	--   led.export
				);
		
end architecture;


architecture stack_computer of DE2 is	-- last, thus default
	-- COMPONENTS --
	component S4PU_Daughterboard is
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
	
	
	-- SIGNALS --
	signal read, write: std_logic;
	signal address, readdata, writedata, stdout: std_logic_vector(15 downto 0);
	
	
	-- BEHAVIOUR --
	begin
		U0: component S4PU_Daughterboard
			generic map (ARCH => 16)
			port map (
				clock => CLOCK_50,

				reset_n => KEY(0),
				mode => '1',

				read => read,
				write => write,
				address => address,
				readdata => readdata,
				writedata => writedata
			);
		
		STDOUT_REG: Reg
			generic map (WIDTH => 16)
			port map (
				clock => CLOCK_50,
				reset => '0',
				enable => write,
				D => writedata,
				Q => stdout
			);
		
		readdata <= SW(15 downto 0);
		LEDR(15 downto 0) <= stdout;
	
end architecture;