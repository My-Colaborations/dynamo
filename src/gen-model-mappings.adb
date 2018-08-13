-----------------------------------------------------------------------
--  gen-model-mappings -- Type mappings for Code Generator
--  Copyright (C) 2011, 2012, 2015, 2018 Stephane Carrez
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

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Gen.Model.Mappings");

   Types : Mapping_Maps.Map;

   Mapping_Name : Unbounded_String;

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
         return Util.Beans.Objects.To_Object (From.Kind = T_INTEGER or From.Kind = T_ENTITY_TYPE);
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
      elsif Name = "isNullable" then
         return Util.Beans.Objects.To_Object (From.Nullable);
      else
         return Definition (From).Get_Value (Name);
      end if;
   end Get_Value;

   --  ------------------------------
   --  Get the type name.
   --  ------------------------------
   function Get_Type_Name (From : Mapping_Definition) return String is
   begin
      case From.Kind is
         when T_BOOLEAN =>
            return "boolean";

         when T_INTEGER =>
            return "integer";

         when T_DATE =>
            return "date";

         when T_IDENTIFIER =>
            return "identifier";

         when T_STRING =>
            return "string";

         when T_ENTITY_TYPE =>
            return "entity_type";

         when T_BLOB =>
            return "blob";

         when T_ENUM =>
            return From.Get_Name;

         when others =>
            return From.Get_Name;

      end case;
   end Get_Type_Name;

   --  ------------------------------
   --  Find the mapping for the given type name.
   --  ------------------------------
   function Find_Type (Name       : in Ada.Strings.Unbounded.Unbounded_String;
                       Allow_Null : in Boolean)
                       return Mapping_Definition_Access is
      Pos : constant Mapping_Maps.Cursor := Types.Find (Mapping_Name & Name);
   begin
      if not Mapping_Maps.Has_Element (Pos) then
         Log.Info ("Type '{0}' not found in mapping table '{1}'",
                   To_String (Name), To_String (Mapping_Name));
         return null;
      elsif Allow_Null then
         if Mapping_Maps.Element (Pos).Allow_Null = null then
            Log.Info ("Type '{0}' does not allow a null value in mapping table '{1}'",
                       To_String (Name), To_String (Mapping_Name));
            return Mapping_Maps.Element (Pos);
         end if;
         return Mapping_Maps.Element (Pos).Allow_Null;
      else
         return Mapping_Maps.Element (Pos);
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
   procedure Register_Type (Target     : in String;
                            From       : in String;
                            Kind       : in Basic_Type;
                            Allow_Null : in Boolean) is
      Name    : constant Unbounded_String := Mapping_Name & To_Unbounded_String (From);
      Pos     : constant Mapping_Maps.Cursor := Types.Find (Name);
      Mapping : Mapping_Definition_Access;
      Found   : Boolean;
   begin
      Log.Debug ("Register type '{0}' mapped to '{1}' type {2}",
                 From, Target, Basic_Type'Image (Kind));

      Found := Mapping_Maps.Has_Element (Pos);
      if Found then
         Mapping := Mapping_Maps.Element (Pos);
      else
         Mapping := new Mapping_Definition;
         Mapping.Set_Name (From);
         Types.Insert (Name, Mapping);
      end if;
      if Allow_Null then
         Mapping.Allow_Null := new Mapping_Definition;
         Mapping.Allow_Null.Target := To_Unbounded_String (Target);
         Mapping.Allow_Null.Kind := Kind;
         Mapping.Allow_Null.Nullable := True;
         if not Found then
            Mapping.Target := To_Unbounded_String (Target);
            Mapping.Kind   := Kind;
         end if;
      else
         Mapping.Target := To_Unbounded_String (Target);
         Mapping.Kind   := Kind;
      end if;
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
