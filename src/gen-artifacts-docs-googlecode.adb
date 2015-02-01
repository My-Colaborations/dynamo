-----------------------------------------------------------------------
--  gen-artifacts-docs-googlecode -- Artifact for Googlecode documentation format
--  Copyright (C) 2015 Stephane Carrez
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

package body Gen.Artifacts.Docs.Googlecode is

   --  ------------------------------
   --  Get the document name from the file document (ex: <name>.wiki or <name>.md).
   --  ------------------------------
   overriding
   function Get_Document_Name (Formatter : in Document_Formatter;
                               Document  : in File_Document) return String is
   begin
      return Ada.Strings.Unbounded.To_String (Document.Name) & ".wiki";
   end Get_Document_Name;

   --  ------------------------------
   --  Start a new document.
   --  ------------------------------
   overriding
   procedure Start_Document (Formatter : in out Document_Formatter;
                             Document  : in File_Document;
                             File      : in Ada.Text_IO.File_Type) is
   begin
      Ada.Text_IO.Put_Line (File, "#summary " & Ada.Strings.Unbounded.To_String (Document.Title));
      Ada.Text_IO.New_Line (File);
   end Start_Document;

   --  ------------------------------
   --  Write a line in the target document formatting the line if necessary.
   --  ------------------------------
   overriding
   procedure Write_Line (Formatter : in out Document_Formatter;
                         File      : in Ada.Text_IO.File_Type;
                         Line      : in Line_Type) is
   begin
      if Line.Kind = L_LIST then
         Ada.Text_IO.New_Line (File);
         Ada.Text_IO.Put (File, Line.Content);
         Formatter.Need_Newline := True;

      elsif Line.Kind = L_LIST_ITEM then
         Ada.Text_IO.Put (File, Line.Content);
         Formatter.Need_Newline := True;

      else
         if Formatter.Need_Newline then
            Ada.Text_IO.New_Line (File);
            Formatter.Need_Newline := False;
         end if;
         Ada.Text_IO.Put_Line (File, Line.Content);
      end if;
   end Write_Line;

end Gen.Artifacts.Docs.Googlecode;
