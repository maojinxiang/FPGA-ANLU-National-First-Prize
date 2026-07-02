-----------------------------------------------------
-- Company: anlgoic
-- Author: 	xg 
-----------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;


entity hdmi_tx is
	 Generic (FAMILY : STRING := "EG4");
	Port (
		PXLCLK_I : in STD_LOGIC;
		PXLCLK_5X_I : in STD_LOGIC;
		RST_N : in STD_LOGIC;
		
		--VGA
		VGA_HS : in std_logic;
		VGA_VS : in std_logic;
		VGA_DE : in std_logic;
		VGA_RGB : in std_logic_vector(23 downto 0);

		--HDMI
		HDMI_CLK_P : out  STD_LOGIC;
		HDMI_D2_P : out  STD_LOGIC;
		HDMI_D1_P : out  STD_LOGIC;
		HDMI_D0_P : out  STD_LOGIC		
	);
			  
end hdmi_tx;

architecture Behavioral of hdmi_tx is

component DVITransmitter is
	 Generic (FAMILY : STRING := "PH1");
    Port ( RED_I : in  STD_LOGIC_VECTOR (7 downto 0);
           GREEN_I : in  STD_LOGIC_VECTOR (7 downto 0);
           BLUE_I : in  STD_LOGIC_VECTOR (7 downto 0);
           HS_I : in  STD_LOGIC;
           VS_I : in  STD_LOGIC;
           VDE_I : in  STD_LOGIC;
		   RST_I : in STD_LOGIC;
           PCLK_I : in  STD_LOGIC;
           PCLK_X5_I : in  STD_LOGIC;
           TMDS_TX_CLK_P : out  STD_LOGIC;
           TMDS_TX_2_P : out  STD_LOGIC;
           TMDS_TX_1_P : out  STD_LOGIC;
           TMDS_TX_0_P : out  STD_LOGIC
		   );
end component;

signal SysRst : std_logic;

begin

		
	Inst_DVITransmitter: DVITransmitter 
	GENERIC MAP (FAMILY => "EG4")
	PORT MAP(
		RED_I => VGA_RGB(23 downto 16),
		GREEN_I => VGA_RGB(15 downto 8),
		BLUE_I => VGA_RGB(7 downto 0),
		HS_I => VGA_HS,
		VS_I => VGA_VS,
		VDE_I => VGA_DE,
		RST_I => RST_N,
		PCLK_I => PXLCLK_I,
		PCLK_X5_I => PXLCLK_5X_I,
		TMDS_TX_CLK_P => HDMI_CLK_P,
		TMDS_TX_2_P => HDMI_D2_P,
		TMDS_TX_1_P => HDMI_D1_P,
		TMDS_TX_0_P => HDMI_D0_P
		
	);
	
end Behavioral;

