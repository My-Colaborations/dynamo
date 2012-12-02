-----------------------------------------------------------------------
--  gen-model-mappings -- Type mappings for Code Generator
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

with Util.Log.Loggers;

--  The <b>Gen.Model.Mappings</b> package controls the mappings to convert an XML
--  type into the Ada type.
package body Gen.Model.Mappings is

   use Ada.Strings.Unbounded;
   use Util.Log;

   Log : constant Loggers.Logger := Loggers.Create ("Gen.Model.Mappings");

   Types : Mapping_Maps.Map;

   Mapping_Name : Unbounded_String;

   --  ------------------------------
   --  Mapping Definition

   --  ------------------------------
   --  Get the value identified by the name.
   --  If the name cannot be found, the method should return the Null object.
   --  ------------------------------
   overriding
   function Get_Value (From : in Mapping_Definition;
                       Name : in String) return Util.Beans.Objects.Object is
   begin
      if Name = "name" then
         return Util.Beans.Objects.To_Object (From.Target);
      elsif Name = "isBoolean" then
         return Util.Beans.Objects.To_Object (From.Kind = T_BOOLEAN);
      elsif Name = "isInteger" then
         return Util.Beans.Objects.To_Object (From.Kind = T_INTEGER);
      elsif Name = "isString" then
         return Util.Beans.Objects.To_Object (From.Kind = T_STRING);
      elsif Name = "isIdentifier" then
         return Util.Beans.Objects.To_Object (From.Kind = T_IDENTIFIER);
      elsif Name = "isDate" then
         return Util.Beans.Objects.To_Object (From.Kind = T_DATE);
      elsif Name = "isBlob" then
         return Util.Beans.Objects.To_Object (From.Kind = T_BLOB);
      elsif Name = "isEnum" then
         return Util.Beans.Objects.To_Object (From.Kind = T_ENUM);
      elsif Name = "isPrimitiveType" then
         return Util.Beans.Objects.To_Object (From.Kind /= T_TABLE and From.Kind /= T_BLOB);
      else
         return Definition (From).Get_Value (Name);
      end if;
   end Get_Value;

   --  ------------------------------
   --  Find the mapping for the given type name.
   --  ------------------------------
   function Find_Type (Name : in Ada.Strings.Unbounded.Unbounded_String)
                       return Mapping_Definition_Access is
      Pos : constant Mapping_Maps.Cursor := Types.Find (Mapping_Name & Name);
   begin
      if Mapping_Maps.Has_Element (Pos) then
         return Mapping_Maps.Element (Pos);
      else
         Log.Info ("Type '{0}' not found in mapping table '{1}'",
                   To_String (Name), To_String (Mapping_Name));
         return null;
      end if;
   end Find_Type;

   procedure Register_Type (Name    : in String;
                            Mapping : in Mapping_Definition_Access;
                            Kind    : in Basic_Type) is
      N    : constant Unbounded_String := Mapping_Name & To_Unbounded_String (Name);
      Pos  : constant Mapping_Maps.Cursor := Types.Find (N);
   begin
      Log.Debug ("Register type '{0}'", Name);

      if not Mapping_Maps.Has_Element (Pos) then
         Mapping.Kind := Kind;
         Types.Insert (N, Mapping);
      end if;
   end Register_Type;

   --  ------------------------------
   --  Register a type mapping <b>From</b> that is mapped to <b>Target</b>.
   --  ------------------------------
   procedure Register_Type (Target : in String;
                            From   : in String;
                            Kind   : in Basic_Type) is
      Name    : constant Unbounded_String := Mapping_Name & To_Unbounded_String (From);
      Pos     : constant Mapping_Maps.Cursor := Types.Find (Name);
      Mapping : Mapping_Definition_Access;
   begin
      Log.Debug ("Register type '{0}' mapped to '{1}' type {2}",
                 From, Target, Basic_Type'Image (Kind));

      if Mapping_Maps.Has_Element (Pos) then
         Mapping := Mapping_Maps.Element (Pos);
      else
         Mapping := new Mapping_Definition;
         Types.Insert (Name, Mapping);
      end if;
      Mapping.Target := To_Unbounded_String (Target);
      Mapping.Kind   := Kind;
   end Register_Type;

   --  ------------------------------
   --  Setup the type mapping for the language identified by the given name.
   --  ------------------------------
   procedure Set_Mapping_Name (Name : in String) is
   begin
      Log.Info ("Using type mapping {0}", Name);

      Mapping_Name := To_Unbounded_String (Name & ".");
   end Set_Mapping_Name;

end Gen.Model.Mappings;
