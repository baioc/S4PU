library ieee;
use ieee.std_logic_1164.all;


entity DE2 is -- Cyclone II EP2C35F672C6 FPGA
	port (
		CLOCK_50: in std_logic;							-- system clock
		KEY: in std_logic_vector(0 downto 0);		-- reset button
		SW: in std_logic_vector(17 downto 17);		-- mode switch
		LEDR: out std_logic_vector(15 downto 0)	-- leds
	);
end entity;


architecture stack_computer of DE2 is	-- default
	-- COMPONENTS --
	component integration is
		port (
			clk_clk       : in  std_logic                     := 'X'; -- clk
			reset_reset_n : in  std_logic                     := 'X'; -- reset_n
			led_export    : out std_logic_vector(15 downto 0);        -- export
			s4pu_export   : in  std_logic                     := 'X'  -- mode
		);
	end component integration;

	-- BEHAVIOUR --
	begin
		u0 : component integration
			port map (
				clk_clk       => CLOCK_50,				--   clk.clk
				reset_reset_n => KEY(0),				-- reset.reset_n
				led_export    => LEDR(15 downto 0),	--   led.export
				s4pu_export   => SW(17)					--  s4pu.export.mode
			);
end architecture;
