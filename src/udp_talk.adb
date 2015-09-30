with
  Ada.Characters.Handling,
  Ada.Characters.Latin_1,
  Ada.Command_Line,
  Ada.Exceptions,
  Ada.Streams,
  Ada.Text_IO,
  GNAT.Sockets,
  POSIX.Direct_Character_IO,
  POSIX.IO,
  POSIX.Process_Primitives,
  POSIX.Terminal_Functions,
  TTY_Memory,
  Mercurial;

use
  Ada.Streams,
  Ada.Text_IO,
  GNAT.Sockets;

procedure UDP_Talk is
   Line_Length : constant := 80;

   Socket   : Socket_Type;
   To, From : Sock_Addr_Type;

   task Logger is
      entry New_Peer (Address : in Sock_Addr_Type);
   end Logger;

   task body Logger is
      File : File_Type;
      Peer : Sock_Addr_Type;
   begin
      begin
         Open (File => File,
               Name => "peers.log",
               Mode => Append_File);
      exception
         when
           others =>
            Create (File => File,
                    Name => "peers.log",
                    Mode => Append_File);
      end;

      accept New_Peer (Address : in Sock_Addr_Type) do
         Peer := Address;
      end New_Peer;

      Put_Line (File => File,
                Item => Image (Peer));
      Flush (File);

      loop
         declare
            Save : Boolean := False;
         begin
            accept New_Peer (Address : in Sock_Addr_Type) do
               if Address /= Peer then
                  Peer := Address;
                  Save := True;
               end if;
            end New_Peer;

            if Save then
               Put_Line (File => File,
                         Item => Image (Peer));
               Flush (File);
            end if;
         end;
      end loop;
   end Logger;

   procedure End_Of_Talk (Error : in Boolean := False);
   procedure Set_Character_By_Character_And_No_Echo_Mode;

   function Source_Address return Sock_Addr_Type;
   function Target_Address return Sock_Addr_Type;

   procedure Put (Message : in     Stream_Element_Array);
   procedure Send_And_Show (Message : in     Character);
   procedure Send (Datagram : in     String);

   procedure Put_Backspace;

   procedure End_Of_Talk (Error : in Boolean := False) is
      use POSIX.Process_Primitives;
   begin
      TTY_Memory.Restore;
      if Error then
         Exit_Process (Status => 1);
      else
         Exit_Process (Status => 0);
      end if;
   end End_Of_Talk;

   procedure Put (Message : in     Stream_Element_Array) is
      Inverse   : constant String := Ada.Characters.Latin_1.ESC & "[7m";
      Plain     : constant String := Ada.Characters.Latin_1.ESC & "[m";
   begin
      if Message'Length = 0 then
         null;
      elsif Message'Length = 1 and then
            Character'Val (Message (Message'First)) = 'D'
      then
         Put_Backspace;
      elsif Message'Length = 3 and then
            Character'Val (Message (Message'First)) = 'E'
      then
         Put (Ada.Characters.Latin_1.ESC);
         Put (Character'Val (Message (Message'First + 1)));
         Put (Character'Val (Message (Message'First + 2)));
      elsif Message'Length = 2 and then
            Character'Val (Message (Message'First)) = 'K'
      then
         Put (Inverse & Character'Val (Message (Message'Last)) & Plain);
      else
         Put (Inverse & "»");
         for Index in Message'Range loop
            Put (Character'Val (Message (Index)));
         end loop;
         Put ("«" & Plain);
      end if;
   end Put;

   procedure Put_Backspace is
      Move_Left : constant String := Ada.Characters.Latin_1.ESC & "[D";
   begin
      Put (Move_Left & " " & Move_Left);
   end Put_Backspace;

   procedure Send (Datagram : in     String) is
      Buffer : Stream_Element_Array
                 (Stream_Element_Offset (Datagram'First) ..
                  Stream_Element_Offset (Datagram'Last));
      Last   : Stream_Element_Offset;
   begin
      for I in Datagram'Range loop
         Buffer (Stream_Element_Offset (I)) :=
           Character'Pos (Datagram (I));
      end loop;

      Send_Socket (Socket => Socket,
                   Item   => Buffer,
                   Last   => Last,
                   To     => To);
      if Last /= Buffer'Last then
         Put_Line ("Failed to send all of the datagram '" & Datagram & "'.");
      end if;
   end Send;

   procedure Send_And_Show (Message : in     Character) is
      use Ada.Characters.Handling;
   begin
      if Is_Graphic (Message) or
         Message = Ada.Characters.Latin_1.LF
      then
         Send (Datagram => 'K' & Message);
         Put (Message);
      elsif Message = Ada.Characters.Latin_1.ESC then
         declare
            use POSIX.Direct_Character_IO;
            Datagram : String (1 .. 3) := "E..";
         begin
            Datagram (2) := To_Character (Get);
            Datagram (3) := To_Character (Get);

            Send (Datagram => Datagram);
            Put (Message & Datagram (2 .. 3));
         end;
      elsif Message = Ada.Characters.Latin_1.DEL then
         Send (Datagram => "D");
         Put (Message);
         Put_Backspace;
      else
         Put ("[don't know how to send character" &
              Natural'Image (Character'Pos (Message)) & "]");
      end if;
   end Send_And_Show;

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

   function Source_Address return Sock_Addr_Type is
      use Ada.Command_Line;
   begin
      return (Family => Family_Inet,
              Addr   => Any_Inet_Addr,
              Port   => Port_Type'Value (Argument (1)));
   exception
      when others =>
         Put_Line (File => Standard_Error,
                   Item => "The first command line argument should be " &
                     "the source port number.");
         End_Of_Talk (Error => True);
         return raise Program_Error with "Should never get here.";
   end Source_Address;

   function Target_Address return Sock_Addr_Type is
      use Ada.Command_Line;
   begin
      begin
         return (Family => Family_Inet,
                 Addr   => Addresses (Get_Host_By_Name (Argument (2))),
                 Port   => Port_Type'Value (Argument (3)));
      exception
         when others =>
            return (Family => Family_Inet,
                    Addr   => Inet_Addr (Argument (2)),
                    Port   => Port_Type'Value (Argument (3)));
      end;
   exception
      when others =>
         Put_Line (File => Standard_Error,
                   Item => "The second command line argument should be " &
                           "the target host name.");
         Put_Line (File => Standard_Error,
                   Item => "The third command line argument should be " &
                           "the target port number.");
         End_Of_Talk (Error => True);
         return raise Program_Error with "Should never get here.";
   end Target_Address;

   task Receiver is
      entry Start;
   end Receiver;

   task body Receiver is
      Buffer : Stream_Element_Array (1 .. Line_Length);
      Filled : Stream_Element_Offset;
   begin
      accept Start;
      loop
         Receive_Socket (Socket => Socket,
                         Item   => Buffer,
                         Last   => Filled,
                         From   => To);
         Put (Message => Buffer (Buffer'First .. Filled));

         Logger.New_Peer (Address => To);
      end loop;
      pragma Warnings (Off);
      POSIX.Process_Primitives.Exit_Process (Status => 1);
      pragma Warnings (On);
   exception
      when Oops : others =>
         Put_Line (File => Standard_Error,
                   Item => "Receiver (revision " & Mercurial.Revision &
                           "): An exception was raised: " &
                           Ada.Exceptions.Exception_Message (Oops));
         End_Of_Talk (Error => True);
   end Receiver;

begin
   From := Source_Address;
   To   := Target_Address;

   TTY_Memory.Save;
   Set_Character_By_Character_And_No_Echo_Mode;

   Create_Socket (Socket => Socket,
                  Mode   => Socket_Datagram);
   Bind_Socket (Socket  => Socket,
                Address => From);
   Receiver.Start;

   loop
      declare
         use POSIX.Direct_Character_IO;
         Input : Character_Or_EOF;
      begin
         Input := Get;
         if End_Of_File (Input) then
            End_Of_Talk;
         else
            Send_And_Show (Message => To_Character (Input));
         end if;
      end;
   end loop;
exception
   when Oops : others =>
      Put_Line (File => Standard_Error,
                Item => "Transmitter (revision " & Mercurial.Revision &
                        "): An exception was raised: " &
                        Ada.Exceptions.Exception_Message (Oops));
      End_Of_Talk (Error => True);
end UDP_Talk;
