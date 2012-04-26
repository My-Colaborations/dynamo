-----------------------------------------------------------------------
--  gen-commands-propset -- Set a property on dynamo project
--  Copyright (C) 2011, 2012 Stephane Carrez
--  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
-----------------------------------------------------------------------
with Ada.Text_IO;
with GNAT.Command_Line;

package body Gen.Commands.Propset is

   --  ------------------------------
   --  Execute the command with the arguments.
   --  ------------------------------
   procedure Execute (Cmd       : in Command;
                      Generator : in out Gen.Generator.Handler) is
      pragma Unreferenced (Cmd);
      use GNAT.Command_Line;
      use Ada.Strings.Unbounded;

      Name     : constant String := Get_Argument;
      Value    : constant String := Get_Argument;
   begin
      if Name'Length = 0 then
         Gen.Commands.Usage;
         return;
      end if;

      Generator.Read_Project ("dynamo.xml", True);
      Generator.Set_Project_Property (Name, Value);
      Generator.Save_Project;
   end Execute;

   --  ------------------------------
   --  Write the help associated with the command.
   --  ------------------------------
   procedure Help (Cmd : in Command;
                   Generator : in out Gen.Generator.Handler) is
      pragma Unreferenced (Cmd, Generator);
      use Ada.Text_IO;
   begin
      Put_Line ("propset: Set the value of a property in the dynamo project file");
      Put_Line ("Usage: propset NAME VALUEE");
      New_Line;
   end Help;

end Gen.Commands.Propset;
