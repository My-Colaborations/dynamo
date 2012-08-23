-----------------------------------------------------------------------
--  gen-commands-project -- Project creation command for dynamo
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
with Ada.Directories;
with Ada.Text_IO;
with Gen.Artifacts;
with GNAT.Command_Line;
with GNAT.OS_Lib;

with Util.Log.Loggers;
with Util.Strings.Transforms;
package body Gen.Commands.Project is

   use Util.Log;

   Log : constant Loggers.Logger := Loggers.Create ("Gen.Commands.Project");

   --  ------------------------------
   --  Generator Command
   --  ------------------------------
   function Get_Name_From_Email (Email : in String) return String;

   --  ------------------------------
   --  Get the user name from the email address.
   --  Returns the possible user name from his email address.
   --  ------------------------------
   function Get_Name_From_Email (Email : in String) return String is
      Pos : Natural := Util.Strings.Index (Email, '<');
   begin
      if Pos > 0 then
         return Email (Email'First .. Pos - 1);
      end if;
      Pos := Util.Strings.Index (Email, '@');
      if Pos > 0 then
         return Email (Email'First .. Pos - 1);
      else
         return Email;
      end if;
   end Get_Name_From_Email;

   --  Execute the command with the arguments.
   procedure Execute (Cmd       : in Command;
                      Generator : in out Gen.Generator.Handler) is
      pragma Unreferenced (Cmd);
      use GNAT.Command_Line;

   begin
      --  If a dynamo.xml file exists, read it.
      if Ada.Directories.Exists ("dynamo.xml") then
         Generator.Read_Project ("dynamo.xml");
      else
         Generator.Set_Project_Property ("license", "apache");
         Generator.Set_Project_Property ("author", "unknown");
         Generator.Set_Project_Property ("author_email", "unknown@company.com");
      end if;
      --  Parse the command line
      loop
         case Getopt ("l:") is
         when ASCII.NUL => exit;

         when 'l' =>
            declare
               L : constant String := Util.Strings.Transforms.To_Lower_Case (Parameter);
            begin
               Log.Info ("License {0}", L);

               if L = "apache" then
                  Generator.Set_Project_Property ("license", "apache");
               elsif L = "gpl" then
                  Generator.Set_Project_Property ("license", "gpl");
               elsif L = "proprietary" then
                  Generator.Set_Project_Property ("license", "proprietary");
               else
                  Generator.Error ("Invalid license: {0}", L);
                  Generator.Error ("Valid licenses: apache, gpl, proprietary");
                  return;
               end if;
            end;

         when others =>
            null;
         end case;
      end loop;
      declare
         Name  : constant String := Get_Argument;
         Arg2  : constant String := Get_Argument;
         Arg3  : constant String := Get_Argument;
      begin
         if Name'Length = 0 then
            Generator.Error ("Missing project name");
            Gen.Commands.Usage;
            return;
         end if;

         if Util.Strings.Index (Arg2, '@') > Arg2'First then
            Generator.Set_Project_Property ("author_email", Arg2);
            if Arg3'Length = 0 then
               Generator.Set_Project_Property ("author", Get_Name_From_Email (Arg2));
            else
               Generator.Set_Project_Property ("author", Arg3);
            end if;

         elsif Util.Strings.Index (Arg3, '@') > Arg3'First then
            Generator.Set_Project_Property ("author", Arg2);
            Generator.Set_Project_Property ("author_email", Arg3);

         elsif Arg3'Length > 0 then
            Generator.Error ("The last argument should be the author's email address.");
            Gen.Commands.Usage;
            return;
         end if;

         Generator.Set_Project_Name (Name);
         Generator.Set_Force_Save (False);
         Gen.Generator.Generate_All (Generator, Gen.Artifacts.ITERATION_TABLE, "project");

         Generator.Save_Project;
         declare
            use type GNAT.OS_Lib.String_Access;

            Path   : constant GNAT.OS_Lib.String_Access
              := GNAT.OS_Lib.Locate_Exec_On_Path ("autoconf");
            Args   : GNAT.OS_Lib.Argument_List (1 .. 0);
            Status : Boolean;
         begin
            if Path = null then
               Generator.Error ("The 'autoconf' tool was not found.  It is necessary to "
                                & "generate the configure script.");
               Generator.Error ("Install 'autoconf' or launch it manually.");
            else
               Ada.Directories.Set_Directory (Generator.Get_Result_Directory);
               Log.Info ("Executing {0}", Path.all);
               GNAT.OS_Lib.Spawn (Path.all, Args, Status);
               if not Status then
                  Generator.Error ("Execution of {0} failed", Path.all);
               end if;
            end if;
         end;
      end;
   end Execute;

   --  ------------------------------
   --  Write the help associated with the command.
   --  ------------------------------
   procedure Help (Cmd       : in Command;
                   Generator : in out Gen.Generator.Handler) is
      pragma Unreferenced (Cmd, Generator);
      use Ada.Text_IO;
   begin
      Put_Line ("create-project: Create a new Ada Web Application project");
      Put_Line ("Usage: create-project [-l apache|gpl|proprietary] NAME [AUTHOR] [EMAIL]");
      New_Line;
      Put_Line ("  Creates a new AWA application with the name passed in NAME.");
      Put_Line ("  The application license is controlled with the -l option. ");
      Put_Line ("  License headers can use either the Apache, the GNU license or");
      Put_Line ("  a proprietary license. The author's name and email addresses");
      Put_Line ("  are also reported in generated files.");
   end Help;

end Gen.Commands.Project;
