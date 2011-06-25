-----------------------------------------------------------------------
--  gen-commands-templates -- Template based command
--  Copyright (C) 2011 Stephane Carrez
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

package Gen.Commands.Templates is

   --  ------------------------------
   --  Template Generic Command
   --  ------------------------------
   --  This command adds a XHTML page to the web application.
   type Command is new Gen.Commands.Command with private;
   type Command_Access is access all Command'Class;

   --  Execute the command with the arguments.
   procedure Execute (Cmd       : in Command;
                      Generator : in out Gen.Generator.Handler);

   --  Write the help associated with the command.
   procedure Help (Cmd       : in Command;
                   Generator : in out Gen.Generator.Handler);

   --  Read the template commands defined in dynamo configuration directory.
   procedure Read_Commands (Generator : in out Gen.Generator.Handler);

private

   type Command is new Gen.Commands.Command with record
      Name      : Ada.Strings.Unbounded.Unbounded_String;
      Title     : Ada.Strings.Unbounded.Unbounded_String;
      Usage     : Ada.Strings.Unbounded.Unbounded_String;
      Help_Msg  : Ada.Strings.Unbounded.Unbounded_String;
      Base_Dir  : Ada.Strings.Unbounded.Unbounded_String;
      Templates : Util.Strings.Sets.Set;
   end record;

end Gen.Commands.Templates;