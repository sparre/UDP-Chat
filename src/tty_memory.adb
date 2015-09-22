with
  POSIX.IO,
  POSIX.Terminal_Functions;

use
  POSIX.IO,
  POSIX.Terminal_Functions;

package body TTY_Memory is
   Memory : Terminal_Characteristics;

   procedure Restore is
   begin
      Set_Terminal_Characteristics (File            => Standard_Input,
                                    Characteristics => Memory);
   end Restore;

   procedure Save is
   begin
      Memory := Get_Terminal_Characteristics (File => Standard_Input);
   end Save;
end TTY_Memory;
