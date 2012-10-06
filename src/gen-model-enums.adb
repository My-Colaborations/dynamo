-----------------------------------------------------------------------
--  gen-model-enums -- Enum definitions
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

package body Gen.Model.Enums is

   --  ------------------------------
   --  Enum value definition
   --  ------------------------------

   --  Get the value identified by the name.
   --  If the name cannot be found, the method should return the Null object.
   overriding
   function Get_Value (From : Value_Definition;
                       Name : String) return Util.Beans.Objects.Object is
   begin
      return Definition (From).Get_Value (Name);
   end Get_Value;

   --  ------------------------------
   --  Table Definition

   --  Get the value identified by the name.
   --  If the name cannot be found, the method should return the Null object.
   overriding
   function Get_Value (From : Enum_Definition;
                       Name : String) return Util.Beans.Objects.Object is
   begin
      if Name = "values" then
         return From.Values_Bean;
      elsif Name = "name" then
         return Util.Beans.Objects.To_Object (From.Type_Name);
      elsif Name = "isEnum" then
         return Util.Beans.Objects.To_Object (True);
      else
         return Mappings.Mapping_Definition (From).Get_Value (Name);
      end if;
   end Get_Value;

   --  Prepare the generation of the model.
   overriding
   procedure Prepare (O : in out Enum_Definition) is
   begin
      O.Target := O.Type_Name;
      null;
   end Prepare;

   --  ------------------------------
   --  Initialize the table definition instance.
   --  ------------------------------
   overriding
   procedure Initialize (O : in out Enum_Definition) is
   begin
      O.Values_Bean := Util.Beans.Objects.To_Object (O.Values'Unchecked_Access,
                                                     Util.Beans.Objects.STATIC);
   end Initialize;

   --  ------------------------------
   --  Create an enum with the given name.
   --  ------------------------------
   function Create_Enum (Name : in Unbounded_String) return Enum_Definition_Access is
      Enum : constant Enum_Definition_Access := new Enum_Definition;
   begin
      Enum.Name := Name;
      declare
         Pos : constant Natural := Index (Enum.Name, ".", Ada.Strings.Backward);
      begin
         if Pos > 0 then
            Enum.Pkg_Name := Unbounded_Slice (Enum.Name, 1, Pos - 1);
            Enum.Type_Name := Unbounded_Slice (Enum.Name, Pos + 1, Length (Enum.Name));
         else
            Enum.Pkg_Name := To_Unbounded_String ("ADO");
            Enum.Type_Name := Enum.Name;
         end if;
      end;
      return Enum;
   end Create_Enum;

end Gen.Model.Enums;
