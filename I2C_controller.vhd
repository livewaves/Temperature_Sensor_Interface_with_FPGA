library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity I2C_Controller is
    Port ( 
				Clock 							: in 		STD_LOGIC;
				Data_In 						: in 		unsigned (15 downto 0);
				Address_Pointer						: in 		unsigned (7 downto 0);
				Send 							: in 		STD_LOGIC;
				R_W							: in		std_logic;
				Data_Type 						: in 		std_logic;
				Data_Out 						: out		unsigned (15 downto 0);
				Data_Out_Valid 						: out 		STD_LOGIC;
				Busy 							: out 		STD_LOGIC;
				SCL 							: out		STD_LOGIC;
				SDA 							: inout		STD_LOGIC
           );
end I2C_Controller;

architecture Behavioral of I2C_Controller is

	signal	Data_In_Int						:	unsigned (15 downto 0)			:=	(others=>'0');
	signal	Data_High_Byte_Buff					:	unsigned (7 downto 0)			:=	(others=>'0');
	signal	Data_Low_Byte_Buff					:	unsigned (7 downto 0)			:=	(others=>'0');
	signal	Address_Pointer_Int					:	unsigned (7 downto 0)			:=	(others=>'0');
	signal	Address_Pointer_Buff					:	unsigned (7 downto 0)			:=	(others=>'0');
	signal	Send_Int						:	std_logic				:=	'0';
	signal	Send_Prev						:	std_logic				:=	'0';
	signal	Data_Type_Int						:	std_logic				:=	'0';
	signal	Data_Type_Buff						:	std_logic				:=	'0';
	signal	Data_Out_Int						:	unsigned (15 downto 0)			:=	(others=>'0');
	signal	Data_Out_Valid_Int					:	std_logic				:=	'0';
	signal	Busy_Int						:	std_logic				:=	'0';
	signal	SCL_Int							:	std_logic				:=	'1';
	signal	R_W_Int							:	std_logic				:=	'0';
	signal	R_W_Buff						:	std_logic				:=	'0';
	
	
	signal	I2C_Data_Write						:	std_logic				:=	'1';
	signal	I2C_Data_Write_Int					:	std_logic				:=	'0';
	signal	I2C_Data_Read						:	std_logic				:=	'0';
	signal	I2C_Data_Read_Int					:	std_logic				:=	'0';
	
	signal	R_W_Mode						:	std_logic				:=	'0';		
	signal	I2C_Write_Read						:	std_logic				:=	'0';		
	signal	I2C_Clock_Generation_Mode				:	std_logic				:=	'0';		
	signal	I2C_Clock_Divider					:	unsigned (8 downto 0)			:=	(others=>'0');	
	signal	I2C_Start_Stop_Counter					:	unsigned (7 downto 0)			:=	(others=>'0');	
	signal	I2C_Clock_Counter					:	unsigned (5 downto 0)			:=	(others=>'0');	
	signal	Serial_Bit_Counter					:	unsigned (2 downto 0)			:=	(others=>'0');	
	signal	I2C_Packet_Generation_State				:	unsigned (3 downto 0)			:=	(others=>'0');
	
	constant Serial_Bus_Address					:	unsigned (7 downto 0)			:=	"01001011";
			
						
begin
 
	IOBUF_inst : IOBUF
		generic map (
				DRIVE 		=> 12,
				IOSTANDARD 	=> "DEFAULT",
				SLEW 		=> "SLOW")
	
		port map (
				O 		=> I2C_Data_Read, 		-- Buffer output
				IO	 	=> SDA, 			-- Buffer inout port (connect directly to top-level port)
				I 		=> I2C_Data_Write,	 	-- Buffer input
				T 		=> R_W_Mode		 	-- 3-state enable input, high=input, low=output
			);

	Data_Out						<=	Data_Out_Int;
	Data_Out_Valid						<=	Data_Out_Valid_Int;
	Busy							<=	Busy_Int;
	SCL							<=	SCL_Int;
	I2C_Data_Write						<=	I2C_Data_Write_Int;
	
		
	process(Clock)
	begin
	
		if rising_edge(Clock) then
		
			Data_In_Int										<=	Data_In;
			Address_Pointer_Int									<=	Address_Pointer;
			Send_Int										<=	Send;
			Send_Prev										<=	Send_Int;
			Data_Type_Int										<=	Data_Type;
			I2C_Data_Read_Int									<=	I2C_Data_Read;
			R_W_Int											<=	R_W;
			SCL_Int											<=	'1';
			I2C_Data_Write_Int									<=	'1';
			R_W_Mode										<=	'0';	
			I2C_Clock_Divider									<=	I2C_Clock_Divider + 1;
			I2C_Start_Stop_Counter									<=	I2C_Start_Stop_Counter + 1;
			Data_Out_Valid_Int									<=	'0';

			if (I2C_Clock_Divider < to_unsigned(75,9) or I2C_Clock_Divider > to_unsigned(196,9)) then
				SCL_Int										<=	not I2C_Clock_Generation_Mode;
			end if;

			if (I2C_Clock_Divider = to_unsigned(271,9)) then
			
				I2C_Clock_Divider								<=	(others=>'0');
				I2C_Clock_Counter								<=	I2C_Clock_Counter + 1;
				Serial_Bit_Counter								<=	Serial_Bit_Counter - 1;
				
			end if;

			-- This state machine generates a full I2C packet.
			case I2C_Packet_Generation_State is

				when "0000" =>

				-- Wait for 1.31 us needed between stop and start condition.
				when "0001" =>
					
					if (I2C_Start_Stop_Counter = to_unsigned(130,8)) then
					
						I2C_Packet_Generation_State			<=	to_unsigned(2,4);	
						I2C_Start_Stop_Counter				<=	(others=>'0');
														
					end if;

				-- Start condition by reseting SDA for 0.61 us. Then wait for another 0.75 us to reach the begining of data.
				when "0010" =>	

					I2C_Data_Write_Int					<=	'0';

					if (I2C_Start_Stop_Counter > to_unsigned(61,8)) then
						SCL_Int						<=	'0';					
					end if;
					
					if (I2C_Start_Stop_Counter = to_unsigned(135,8)) then
					
						I2C_Packet_Generation_State			<=	to_unsigned(3,4);	
						I2C_Clock_Divider				<=	(others=>'0');
						I2C_Clock_Generation_Mode			<=	'1';
						Serial_Bit_Counter				<=	to_unsigned(6,3);
						I2C_Clock_Counter				<=	(others=>'0');
						
					end if;

				-- Sending serial bus address.
				when "0011" =>	

					I2C_Data_Write_Int					<=	Serial_Bus_Address(to_integer(Serial_Bit_Counter));
					
					if (I2C_Clock_Counter = to_unsigned(7,6)) then
						I2C_Packet_Generation_State			<=	to_unsigned(4,4);			
					end if;

				-- Sending write(read) bit.
				when "0100" =>	

					I2C_Data_Write_Int					<=	I2C_Write_Read;
					if (I2C_Clock_Counter = to_unsigned(8,6)) then
					
						I2C_Packet_Generation_State			<=	to_unsigned(5,4);	
						if (I2C_Write_Read = '1') then
						
							I2C_Packet_Generation_State		<=	to_unsigned(7,4);	
							I2C_Clock_Counter 				<= to_unsigned(17,6);
													
						end if;						
							
					end if;

				-- Changing bus to read mode to receive acknowledge from sensor.
				when "0101" =>	

					R_W_Mode						<=	'1';
					if (I2C_Clock_Counter = to_unsigned(9,6)) then
					
						I2C_Packet_Generation_State			<=	to_unsigned(6,4);	
						Serial_Bit_Counter				<=	to_unsigned(7,3);
						
					end if;

				-- Sending address pointer.
				when "0110" =>	

					I2C_Data_Write_Int					<=	Address_Pointer_Buff(to_integer(Serial_Bit_Counter));
					
					if (I2C_Clock_Counter = to_unsigned(17,6)) then
						I2C_Packet_Generation_State			<=	to_unsigned(7,4);		
					end if;

				-- Changing bus to read mode to receive acknowledge from sensor.
				when "0111" =>	

					R_W_Mode						<=	'1';
					if (I2C_Clock_Counter = to_unsigned(18,6)) then
					
						I2C_Packet_Generation_State			<=	to_unsigned(9,4);	
						Serial_Bit_Counter				<=	to_unsigned(7,3);
						
						if (Data_Type_Buff = '0') then
						
							I2C_Packet_Generation_State		<=	to_unsigned(11,4);		
							I2C_Clock_Counter 				<= to_unsigned(27,6);
												
						end if;
						
						if (R_W_Buff = '1' and I2C_Write_Read = '0') then
							I2C_Packet_Generation_State		<=	to_unsigned(8,4);		
						end if;					
	
					end if;

				-- When read mode is selected, go back to start condition.
				when "1000" =>	
	
					if (I2C_Clock_Divider = to_unsigned(136,9)) then

						I2C_Packet_Generation_State			<=	to_unsigned(1,4);
						I2C_Start_Stop_Counter				<=	(others=>'0');
						I2C_Write_Read						<=	'1';
						I2C_Clock_Generation_Mode			<=	'0';
						
					end if;
					
				-- Sending(receiving) data high byte.
				when "1001" =>	

					I2C_Data_Write_Int						<=	Data_High_Byte_Buff(to_integer(Serial_Bit_Counter));
					R_W_Mode							<=	R_W_Buff;
					
					if (I2C_Clock_Divider = to_unsigned(136,9)) then
						Data_Out_Int(8+to_integer(Serial_Bit_Counter))	<=	I2C_Data_Read_Int;
					end if;
					
					if (I2C_Clock_Counter = to_unsigned(26,6)) then
						I2C_Packet_Generation_State			<=	to_unsigned(10,4);		
					end if;

				-- Changing bus to read mode to receive acknowledge from sensor when write command is in progress.
				-- resetting bus send acknowledge from FPGA when read command is in progress.
				when "1010" =>	

					R_W_Mode						<=	not R_W_Buff;
					I2C_Data_Write_Int					<=	'0';
					if (I2C_Clock_Counter = to_unsigned(27,6)) then
					
						I2C_Packet_Generation_State			<=	to_unsigned(11,4);	
						Serial_Bit_Counter				<=	to_unsigned(7,3);
						
					end if;

				-- Sending data low byte.
				when "1011" =>	

					I2C_Data_Write_Int					<=	Data_Low_Byte_Buff(to_integer(Serial_Bit_Counter));
					R_W_Mode						<=	R_W_Buff;
					
					if (I2C_Clock_Divider = to_unsigned(136,9)) then
						Data_Out_Int(to_integer(Serial_Bit_Counter))	<=	I2C_Data_Read_Int;
					end if;
										
					if (I2C_Clock_Counter = to_unsigned(35,6)) then
						I2C_Packet_Generation_State			<=	to_unsigned(12,4);		
					end if;

				-- Changing bus to read mode to receive acknowledge from sensor.
				when "1100" =>	

					R_W_Mode						<=	not R_W_Buff;
										
					if (I2C_Clock_Counter = to_unsigned(36,6)) then
					
						I2C_Packet_Generation_State			<=	to_unsigned(13,4);	
						I2C_Start_Stop_Counter				<=	(others=>'0');
						Data_Out_Valid_Int				<=	R_W_Buff;
						
					end if;
					
				-- Stop condition by setting SDA 0.61 us after SCL rising edge.
				when "1101" =>	

					I2C_Data_Write_Int					<=	'0';

					if (I2C_Start_Stop_Counter = to_unsigned(135,8)) then
					
						I2C_Packet_Generation_State			<=	to_unsigned(14,4);	
						I2C_Clock_Generation_Mode			<=	'0';
						I2C_Write_Read					<=	'0';						
						Busy_Int					<=	'0';
														
					end if;

				when "1110" =>	

				when others =>
			end case;			

			if (Send_Int = '1' and Send_Prev = '0' and Busy_Int = '0') then
			
				Data_High_Byte_Buff						<=	Data_In_Int(15 downto 8);
				Data_Low_Byte_Buff						<=	Data_In_Int(7 downto 0);
				Address_Pointer_Buff						<=	Address_Pointer_Int;
				R_W_Buff							<=	R_W_Int;
				Data_Type_Buff							<=	Data_Type_Int;
				I2C_Packet_Generation_State					<=	to_unsigned(1,4);
				I2C_Start_Stop_Counter						<=	(others=>'0');
				Busy_Int							<=	'1';
										
			end if;			
		
		end if;
	end process;
	
end Behavioral;
