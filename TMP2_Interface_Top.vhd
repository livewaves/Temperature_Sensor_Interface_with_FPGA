library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TMP2_Interface_Top is
    Port ( 
    			Clock 					:	in		STD_LOGIC;
    			Read_Temp				:	in		std_logic;
    			Temperature				:	out		unsigned (15 downto 0);
    			Temperature_Valid			:	out		std_logic;
    			Busy					:	out		std_logic;
    			
    			SCL					:	out		std_logic;
    			SDA					:	inout	std_logic
    	);
end TMP2_Interface_Top;

architecture Behavioral of TMP2_Interface_Top is

	signal	Read_Temp_Int					:	std_logic									:=	'0';
	signal	Read_Temp_Prev					:	std_logic									:=	'0';
	signal	Busy_Int					:	std_logic									:=	'0';
	
	signal	I2C_Data_In					:	unsigned (15 downto 0)								:= (others=>'0');
	signal	I2C_Address_Pointer				:	unsigned (7 downto 0)								:= (others=>'0');
	signal	I2C_Data_Type					:	std_logic									:=	'0';
	signal	I2C_R_W						:	std_logic									:=	'0';
	signal	I2C_Send					:	std_logic									:=	'0';
	signal	I2C_Data_Out					:	unsigned (15 downto 0)								:= (others=>'0');
	signal	I2C_Data_Out_Valid				:	std_logic									:=	'0';
	signal	I2C_Busy					:	std_logic									:=	'1';
	signal	I2C_Busy_Prev					:	std_logic									:=	'1';
	
	signal	Initialization_State				:	std_logic									:=	'0';
	signal	Temp_Read_State					:	std_logic									:=	'0';
		
begin

	I2C_Controller_inst: entity work.I2C_Controller
		port map (
			Clock                        	=> Clock,                     
			Data_In        			=> I2C_Data_In,      
			Address_Pointer 		=> I2C_Address_Pointer,
			Data_Type                   	=> I2C_Data_Type,                 
			R_W                         	=> I2C_R_W,                       
			Send                        	=> I2C_Send,                      
			Data_Out			=> I2C_Data_Out,     
			Data_Out_Valid              	=> I2C_Data_Out_Valid,            
			Busy                         	=> I2C_Busy,                      
			SCL                         	=> SCL,                       
			SDA                         	=> SDA                       
		);

	Temperature									<=	I2C_Data_Out;
	Temperature_Valid								<=	I2C_Data_Out_Valid;
	Busy										<=	Busy_Int;
		
	process(Clock)
	begin
	
		if rising_edge(Clock) then

			Read_Temp_Int							<=	Read_Temp;
			Read_Temp_Prev							<=	Read_Temp_Int;
			I2C_Busy_Prev							<=	I2C_Busy;
			I2C_Send							<=	'0';
			I2C_R_W								<=	'0';
			I2C_Data_Type							<=	'0';
		
			if (I2C_Busy = '0' and I2C_Busy_Prev = '1') then
				Busy_Int						<=	'0';			
			end if;
			
			if (Initialization_State = '0') then
			
				Initialization_State					<=	'1';
				I2C_Data_In						<=	x"0080";
				I2C_Address_Pointer					<=	x"03";
				I2C_Send						<=	'1';
				Busy_Int						<=	'1';
				
			end if;

			if (Temp_Read_State = '1') then
			
				Temp_Read_State						<=	'0';
				I2C_Address_Pointer					<=	x"00";
				I2C_Data_Type						<=	'1';
				I2C_Send						<=	'1';
				I2C_R_W							<=	'1';
				
			end if;
			
			if (Read_Temp_Int = '1' and Read_Temp_Prev = '0' and Busy_Int = '0') then
				
				Temp_Read_State						<=	'1';
				Busy_Int						<=	'1';
				
			end if;
						
		end if;
	
	end process;
	
end Behavioral;
