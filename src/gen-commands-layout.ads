-----------------------------------------------------------------------
--  gen-commands-layout -- Layout creation command for dynamo
--  Copyright (C) 2011, 2017 Stephane Carrez
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

package Gen.Commands.Layout is

   --  ------------------------------
   --  Layout Creation Command
   --  ------------------------------
   --  This command adds a XHTML layout to the web application.
   type Command is new Gen.Commands.Command with null record;

   --  Execute the command with the arguments.
   overriding
   procedure Execute (Cmd       : in Command;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Generator : in out Gen.Generator.Handler);

   --  Write the help associated with the command.
   overriding
   procedure Help (Cmd       : in Command;
                   Generator : in out Gen.Generator.Handler);

end Gen.Commands.Layout;
