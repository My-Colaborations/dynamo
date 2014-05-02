-----------------------------------------------------------------------
--  gen-commands-layout -- Layout creation command for dynamo
--  Copyright (C) 2011, 2012, 2013, 2014 Stephane Carrez
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
with Gen.Artifacts;
with GNAT.Command_Line;

with Util.Strings;
with Util.Files;
package body Gen.Commands.Layout is

   --  ------------------------------
   --  Execute the command with the arguments.
   --  ------------------------------
   procedure Execute (Cmd       : in Command;
                      Generator : in out Gen.Generator.Handler) is
      pragma Unreferenced (Cmd);
      use GNAT.Command_Line;
      use Ada.Strings.Unbounded;

      function Get_Name return String;

      Dir        : constant String := Generator.Get_Result_Directory;
      Layout_Dir : constant String := Util.Files.Compose (Dir, "web/WEB-INF/layouts");

      function Get_Name return String is
         Name : constant String := Get_Argument;
         Pos  : constant Natural := Util.Strings.Rindex (Name, '.');
      begin
         if Pos = 0 then
            return Name;
         elsif Name (Pos .. Name'Last) = ".xhtml" then
            return Name (Name'First .. Pos - 1);
         elsif Name (Pos .. Name'Last) = ".html" then
            return Name (Name'First .. Pos - 1);
         else
            return Name;
         end if;
      end Get_Name;

      Name   : constant String := Get_Name;
   begin
      if Name'Length = 0 then
         Gen.Commands.Usage;
         return;
      end if;

      Generator.Set_Force_Save (False);
      Generator.Set_Result_Directory (Layout_Dir);
      Generator.Set_Global ("pageName", Name);
      Gen.Generator.Generate_All (Generator, Gen.Artifacts.ITERATION_TABLE, "layout");
   end Execute;

   --  ------------------------------
   --  Write the help associated with the command.
   --  ------------------------------
   procedure Help (Cmd : in Command;
                   Generator : in out Gen.Generator.Handler) is
      pragma Unreferenced (Cmd, Generator);
      use Ada.Text_IO;

   begin
      Put_Line ("add-layout: Add a new layout page to the application");
      Put_Line ("Usage: add-layout NAME");
      New_Line;
      Put_Line ("  The layout page allows to give a common look to a set of pages.");
      Put_Line ("  You can create several layouts for your application.");
      Put_Line ("  Each layout can reference one or several building blocks that are defined");
      Put_Line ("  in the original page.");
      New_Line;
      Put_Line ("  The following files are generated:");
      Put_Line ("    web/WEB-INF/layouts/<name>.xhtml");
   end Help;

end Gen.Commands.Layout;
