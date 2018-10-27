-----------------------------------------
--													--
-- Module: FPGA top-level					--
--													--
-- Author:	Gabriel B. Sant'Anna			--
--			baiocchi.gabriel@gmail.com		--
--													--
-----------------------------------------


library ieee;
use ieee.std_logic_1164.all;


entity FPGA is	-- Cyclone II EP2C35F672C6
	port (
		CLOCK_50: in std_logic;							-- system clock
		KEY: in std_logic_vector(0 downto 0);		-- reset button
		SW: in std_logic_vector(17 downto 0);		-- stdin & mode
		LEDR: out std_logic_vector(15 downto 0)	-- stdout
	);
end entity;


architecture stack_computer of FPGA is	-- default
	-- COMPONENTS --
	component S4PU_Daughterboard is
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
	end component;

	component integration is
		port (
			clk_clk          : in  std_logic                     := 'X';             -- clk
			reset_reset_n    : in  std_logic                     := 'X';             -- reset_n
			ebab_address     : in  std_logic_vector(15 downto 0) := (others => 'X'); -- address
			ebab_byte_enable : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- byte_enable
			ebab_read        : in  std_logic                     := 'X';             -- read
			ebab_write       : in  std_logic                     := 'X';             -- write
			ebab_write_data  : in  std_logic_vector(15 downto 0) := (others => 'X'); -- write_data
			ebab_acknowledge : out std_logic;                                        -- acknowledge
			ebab_read_data   : out std_logic_vector(15 downto 0);                    -- read_data
			led_export       : out std_logic_vector(15 downto 0);                    -- export
			sw_export        : in  std_logic_vector(15 downto 0) := (others => 'X')  -- export
		);
	end component integration;


	-- SIGNALS --
	signal mode, acknowledge,
			 read, write: std_logic;

	signal readdata, writedata,
			 address: std_logic_vector(15 downto 0);


	-- BEHAVIOUR --
	begin
		u0 : component integration
			port map (
				clk_clk          => CLOCK_50,					-- clk.clk
				reset_reset_n    => KEY(0),					-- reset.reset_n
				ebab_address     => address,					-- ebab.address
				ebab_byte_enable => "11",						-- .byte_enable
				ebab_read        => read,						-- .read
				ebab_write       => write,						-- .write
				ebab_write_data  => writedata,				-- .write_data
				ebab_acknowledge => acknowledge,				-- .acknowledge
				ebab_read_data   => readdata,					-- .read_data
				led_export       => LEDR(15 downto 0),		-- led.export
				sw_export        => SW(15 downto 0)			-- sw.export
			);

		U1: component S4PU_Daughterboard
			generic map (ARCH => 16)
			port map (
				clock => CLOCK_50,

				reset_n => KEY(0),
				mode => SW(17),

				read => read,
				write => write,
				address => address,
				readdata => readdata,
				writedata => writedata,
				acknowledge => acknowledge
			);

end architecture;
