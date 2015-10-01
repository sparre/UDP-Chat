with
  Ada.Text_IO;
with
  POSIX.IO,
  POSIX.Terminal_Functions;

with
  POSIX.Direct_Character_IO,
  TTY_Memory;

procedure Key_Code_Logger is
   procedure Set_Character_By_Character_And_No_Echo_Mode;

   procedure Set_Character_By_Character_And_No_Echo_Mode is
      use POSIX.Terminal_Functions;
      Info  : Terminal_Characteristics;
      Modes : Terminal_Modes_Set;
   begin
      Info := Get_Terminal_Characteristics (File => POSIX.IO.Standard_Input);
      Modes := Terminal_Modes_Of (Info);
      Modes (Canonical_Input) := False;
      Modes (Echo) := False;
      Define_Terminal_Modes (Characteristics => Info,
                             Modes           => Modes);
      Define_Minimum_Input_Count (Characteristics     => Info,
                                  Minimum_Input_Count => 1);
      Set_Terminal_Characteristics (File            => POSIX.IO.Standard_Input,
                                    Characteristics => Info);
   end Set_Character_By_Character_And_No_Echo_Mode;
begin
   TTY_Memory.Save;
   Set_Character_By_Character_And_No_Echo_Mode;

   loop
      declare
         use Ada.Text_IO;
         use POSIX.Direct_Character_IO;
         Input : Character_Or_EOF;
      begin
         Input := Get;
         if End_Of_File (Input) then
            Put_Line ("<EOF>");
            exit;
         else
            Put_Line (Natural'Image (Character'Pos (To_Character (Input))));
         end if;
      end;
   end loop;

   TTY_Memory.Restore;
exception
   when others =>
      TTY_Memory.Restore;
end Key_Code_Logger;
