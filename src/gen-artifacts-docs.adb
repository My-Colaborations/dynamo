-----------------------------------------------------------------------
--  gen-artifacts-docs -- Artifact for documentation
--  Copyright (C) 2012, 2013, 2014, 2015, 2018, 2019, 2020 Stephane Carrez
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
with Util.Files;
with Util.Log.Loggers;
with Util.Strings;
with Util.Streams.Pipes;
with Util.Streams.Texts;
with Util.Processes;

with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Characters.Handling;
with Ada.Strings.Maps;
with Ada.Exceptions;

with Gen.Utils;

with Gen.Artifacts.Docs.Googlecode;
with Gen.Artifacts.Docs.Markdown;
package body Gen.Artifacts.Docs is

   use Util.Log;
   use type Ada.Strings.Maps.Character_Set;

   Log : constant Loggers.Logger := Loggers.Create ("Gen.Artifacts.Docs");

   Spaces : constant Ada.Strings.Maps.Character_Set
     := Ada.Strings.Maps.To_Set (' ')
     or Ada.Strings.Maps.To_Set (ASCII.HT)
     or Ada.Strings.Maps.To_Set (ASCII.VT)
     or Ada.Strings.Maps.To_Set (ASCII.CR)
     or Ada.Strings.Maps.To_Set (ASCII.LF);

   Google_Formatter   : aliased Gen.Artifacts.Docs.Googlecode.Document_Formatter;
   Markdown_Formatter : aliased Gen.Artifacts.Docs.Markdown.Document_Formatter;

   --  Get the header level of the line if the line is a header.
   --  Returns 0 if the line is not a header.
   function Get_Header_Level (Line : in String) return Natural;

   --  Get the header from the line, removing any markup.
   function Get_Header (Line : in String) return String;

   --  ------------------------------
   --  Prepare the model after all the configuration files have been read and before
   --  actually invoking the generation.
   --  ------------------------------
   overriding
   procedure Prepare (Handler : in out Artifact;
                      Model   : in out Gen.Model.Packages.Model_Definition'Class;
                      Context : in out Generator'Class) is
      pragma Unreferenced (Model);

      Docs   : Doc_Maps.Map;
      Name    : constant String := (if Handler.Format = DOC_WIKI_GOOGLE
                                    then "generator.doc.xslt.command"
                                    else "generator.markdown.xslt.command");
      Command : constant String := Context.Get_Parameter (Name);
   begin
      Log.Info ("Using command: {0}", Command);

      Handler.Xslt_Command := Ada.Strings.Unbounded.To_Unbounded_String (Command);
      Handler.Scan_Files ("src", Docs);
      Handler.Scan_Files ("config", Docs);
      Handler.Scan_Files ("db", Docs);
      Handler.Scan_Files ("plugins", Docs);
      Generate (Docs, Context.Get_Result_Directory);
   end Prepare;

   --  ------------------------------
   --  Set the output document format to generate.
   --  ------------------------------
   procedure Set_Format (Handler : in out Artifact;
                         Format  : in Doc_Format;
                         Footer  : in Boolean) is
   begin
      Handler.Format := Format;
      Handler.Print_Footer := Footer;
      case Format is
         when DOC_WIKI_GOOGLE =>
            Handler.Formatter := Google_Formatter'Access;

         when DOC_MARKDOWN =>
            Handler.Formatter := Markdown_Formatter'Access;

      end case;
   end Set_Format;

   --  ------------------------------
   --  Load from the file a list of link definitions which can be injected in the generated doc.
   --  This allows to avoid polluting the Ada code with external links.
   --  ------------------------------
   procedure Read_Links (Handler : in out Artifact;
                         Path    : in String) is
      use Ada.Strings.Fixed;
      procedure Read (Line : in String);
      procedure Read (Line : in String) is
         Pos : constant Natural := Util.Strings.Rindex (Line, ' ');
      begin
         if Pos > 0 and then Line (Line'First) /= '#' then
            Handler.Formatter.Links.Include
              (Key      => Trim (Line (Line'First .. Pos), Ada.Strings.Both),
               New_Item => Trim (Line (Pos .. Line'Last), Ada.Strings.Both));
         end if;
      end Read;
   begin
      if Ada.Directories.Exists (Path) then
         Log.Info ("Reading documentation links file {0}", Path);
         Util.Files.Read_File (Path, Read'Access);
      end if;
   end Read_Links;

   --  ------------------------------
   --  Include the document extract represented by <b>Name</b> into the document <b>Into</b>.
   --  The included document is marked so that it will not be generated.
   --  ------------------------------
   procedure Include (Docs     : in out Doc_Maps.Map;
                      Into     : in out File_Document;
                      Name     : in String;
                      Mode     : in Line_Include_Kind;
                      Position : in Natural) is
      --  Include the lines from the document into another.
      procedure Do_Include (Source : in String;
                            Doc    : in out File_Document);

      --  ------------------------------
      --  Include the lines from the document into another.
      --  ------------------------------
      procedure Do_Include (Source : in String;
                            Doc    : in out File_Document) is
         Iter : Line_Vectors.Cursor := Doc.Lines (Mode).Last;
      begin
         Log.Debug ("Merge {0} in {1}", Source, Ada.Strings.Unbounded.To_String (Into.Name));
         Into.Lines (L_INCLUDE).Insert (Before => Position,
                                        New_Item => (Len => 0, Kind => L_TEXT, Content => ""));
         while Line_Vectors.Has_Element (Iter) loop
            Into.Lines (L_INCLUDE).Insert (Before   => Position,
                                           New_Item => Line_Vectors.Element (Iter));
            Line_Vectors.Previous (Iter);
         end loop;
         Doc.Was_Included := True;
      end Do_Include;

      Pos : constant Doc_Maps.Cursor := Docs.Find (Name);
   begin
      if not Doc_Maps.Has_Element (Pos) then
         Log.Error ("Cannot include document '{0}'", Name);
         return;
      end if;
      Docs.Update_Element (Pos, Do_Include'Access);
   end Include;

   --  ------------------------------
   --  Include the document extract represented by <b>Name</b> into the document <b>Into</b>.
   --  The included document is marked so that it will not be generated.
   --  ------------------------------
   procedure Include (Docs     : in out Doc_Maps.Map;
                      Into     : in out File_Document;
                      Name     : in String;
                      Position : in Natural) is
      pragma Unreferenced (Docs);
      procedure Do_Include (Line : in String);

      Pos : Natural := Position;

      procedure Do_Include (Line : in String) is
      begin
         Into.Lines (L_INCLUDE).Insert (Before => Pos,
                                        New_Item => (Len => Line'Length,
                                                     Kind => L_TEXT,
                                                     Content => Line));
         Pos := Pos + 1;
      end Do_Include;

   begin
      if not Ada.Directories.Exists (Name) then
         Log.Error ("{0}: Cannot include document: {1}",
                    Ada.Strings.Unbounded.To_String (Into.Name), Name);
         return;
      end if;
      Util.Files.Read_File (Path     => Name,
                            Process  => Do_Include'Access);
   end Include;

   --  ------------------------------
   --  Generate the project documentation that was collected in <b>Docs</b>.
   --  The documentation is merged so that the @include tags are replaced by the matching
   --  document extracts.
   --  ------------------------------
   procedure Generate (Docs : in out Doc_Maps.Map;
                       Dir  : in String) is
      --  Merge the documentation.
      procedure Merge (Source : in String;
                       Doc    : in out File_Document);

      --  Generate the documentation.
      procedure Generate (Source : in String;
                          Doc    : in File_Document);

      --  ------------------------------
      --  Merge the documentation.
      --  ------------------------------
      procedure Merge (Source : in String;
                       Doc    : in out File_Document) is
         pragma Unreferenced (Source);

         Pos : Natural := 1;
      begin
         while Pos <= Natural (Doc.Lines (L_INCLUDE).Length) loop
            declare
               L : constant Line_Type := Line_Vectors.Element (Doc.Lines (L_INCLUDE), Pos);
            begin
               if L.Kind in L_INCLUDE | L_INCLUDE_QUERY |
               L_INCLUDE_PERMISSION | L_INCLUDE_CONFIG |
               L_INCLUDE_BEAN
               then
                  Line_Vectors.Delete (Doc.Lines (L_INCLUDE), Pos);
                  Include (Docs, Doc, L.Content, L.Kind, Pos);
               elsif L.Kind = L_INCLUDE_DOC then
                  Line_Vectors.Delete (Doc.Lines (L_INCLUDE), Pos);
                  Include (Docs, Doc, L.Content, Pos);
               else
                  Pos := Pos + 1;
               end if;
            end;
         end loop;
      end Merge;

      --  ------------------------------
      --  Generate the documentation.
      --  ------------------------------
      procedure Generate (Source : in String;
                          Doc    : in File_Document) is

         procedure Write (Line : in Line_Type);

         Name : constant String := Doc.Formatter.Get_Document_Name (Doc);
         Path : constant String := Util.Files.Compose (Dir, Name);
         File : Ada.Text_IO.File_Type;
         Iter : Line_Vectors.Cursor := Doc.Lines (L_INCLUDE).First;

         procedure Write (Line : in Line_Type) is
         begin
            Doc.Formatter.Write_Line (File => File,
                                      Line => Line);
         end Write;

      begin
         if Doc.Lines (L_INCLUDE).Is_Empty or Doc.Was_Included then
            return;
         end if;

         Log.Info ("Generating doc {0}", Path);
         Ada.Directories.Create_Path (Dir);

         Ada.Text_IO.Create (File => File,
                             Mode => Ada.Text_IO.Out_File,
                             Name => Path);
         Doc.Formatter.Start_Document (Document => Doc,
                                       File     => File);

         while Line_Vectors.Has_Element (Iter) loop
            Line_Vectors.Query_Element (Iter, Write'Access);
            Line_Vectors.Next (Iter);
         end loop;
         Doc.Formatter.Finish_Document (Document => Doc,
                                        File     => File,
                                        Source   => Source);
         Ada.Text_IO.Close (File);
      end Generate;

      Iter : Doc_Maps.Cursor := Docs.First;
   begin
      --  First pass: merge the documentation.
      while Doc_Maps.Has_Element (Iter) loop
         Docs.Update_Element (Position => Iter, Process => Merge'Access);
         Doc_Maps.Next (Iter);
      end loop;

      --  Second pass: build the documentation.
      Iter := Docs.First;
      while Doc_Maps.Has_Element (Iter) loop
         Doc_Maps.Query_Element (Iter, Generate'Access);
         Doc_Maps.Next (Iter);
      end loop;
   end Generate;

   --  ------------------------------
   --  Scan the files in the directory refered to by <b>Path</b> and collect the documentation
   --  in the <b>Docs</b> hashed map.
   --  ------------------------------
   procedure Scan_Files (Handler : in out Artifact;
                         Path    : in String;
                         Docs    : in out Doc_Maps.Map) is
      use Ada.Directories;

      File_Filter  : constant Filter_Type := (Ordinary_File => True,
                                              Directory     => False,
                                              others        => False);
      Dir_Filter  : constant Filter_Type := (Ordinary_File => False,
                                             Directory     => True,
                                             others        => False);
      Ent     : Ada.Directories.Directory_Entry_Type;
      Search  : Search_Type;

   begin
      if not Ada.Directories.Exists (Path) then
         return;
      end if;
      Start_Search (Search, Directory => Path,
                    Pattern => "*", Filter => File_Filter);
      while More_Entries (Search) loop
         Get_Next_Entry (Search, Ent);
         declare
            Name      : constant String := Simple_Name (Ent);
            Full_Path : constant String := Ada.Directories.Full_Name (Ent);
            Doc       : File_Document;
            Pos       : constant Natural := Util.Strings.Rindex (Name, '.');
         begin
            if Gen.Utils.Is_File_Ignored (Name) or Pos = 0 then
               Log.Debug ("File {0} ignored", Name);

            else
               Log.Debug ("Collect {0}", Full_Path);

               Doc.Print_Footer := Handler.Print_Footer;
               Doc.Formatter := Handler.Formatter;
               if Name (Pos .. Name'Last) = ".ads" or Name (Pos .. Name'Last) = ".adb" then
                  Handler.Read_Ada_File (Full_Path, Doc);

               elsif Name (Pos .. Name'Last) = ".xml" then
                  Handler.Read_Xml_File (Full_Path, Doc);

               end if;
               Log.Info ("Adding document '{0}'", Name);
               Docs.Include (Name, Doc);
            end if;
         end;
      end loop;

      Start_Search (Search, Directory => Path,
                    Pattern => "*", Filter => Dir_Filter);
      while More_Entries (Search) loop
         Get_Next_Entry (Search, Ent);
         declare
            Name      : constant String := Simple_Name (Ent);
         begin
            if not Gen.Utils.Is_File_Ignored (Name)
              and Name /= "regtests"
            then
               Handler.Scan_Files (Ada.Directories.Full_Name (Ent), Docs);
            end if;
         end;
      end loop;
   end Scan_Files;

   --  ------------------------------
   --  Returns True if the line indicates a bullet or numbered list.
   --  ------------------------------
   function Is_List (Line : in String) return Boolean is
   begin
      if Line'Length <= 3 then
         return False;
      elsif Line (Line'First) = '*' and Line (Line'First + 1) = ' ' then
         return True;
      else
         return Line (Line'First .. Line'First + 3) = "  * ";
      end if;
   end Is_List;

   --  ------------------------------
   --  Returns True if the line indicates a code sample.
   --  ------------------------------
   function Is_Code (Line : in String) return Boolean is
   begin
      if Line'Length <= 3 then
         return False;
      else
         return Line (Line'First) =  ' ' and Line (Line'First + 1) = ' ';
      end if;
   end Is_Code;

   --  ------------------------------
   --  Get the header level of the line if the line is a header.
   --  Returns 0 if the line is not a header.
   --  ------------------------------
   function Get_Header_Level (Line : in String) return Natural is
      Result : Natural := 0;
   begin
      for I in Line'Range loop
         exit when Line (I) /= '=';
         Result := Result + 1;
         exit when Result >= 4;
      end loop;
      return Result;
   end Get_Header_Level;

   --  ------------------------------
   --  Get the header from the line, removing any markup.
   --  ------------------------------
   function Get_Header (Line : in String) return String is
      Start  : Natural := Line'First;
      Finish : Natural := Line'Last;
   begin
      while Start < Finish and (Line (Start) = '=' or Line (Start) = ' ') loop
         Start := Start + 1;
      end loop;
      while Start < Finish and (Line (Finish) = '=' or Line (Finish) = ' ') loop
         Finish := Finish - 1;
      end loop;
      return Line (Start .. Finish);
   end Get_Header;

   --  ------------------------------
   --  Append a raw text line to the document.
   --  ------------------------------
   procedure Append_Line (Doc  : in out File_Document;
                          Line : in String) is
      Level : Natural;
   begin
      if Doc.State = IN_LIST then
         Doc.Lines (L_INCLUDE).Append (Line_Type '(Len  => Line'Length,
                                                   Kind => L_LIST_ITEM,
                                                   Content => Line));
      else
         Level := Get_Header_Level (Line);
         if Level = 0 then
            Doc.Lines (L_INCLUDE).Append (Line_Type '(Len  => Line'Length,
                                                      Kind => L_TEXT,
                                                      Content => Line));
         else
            declare
               Header : constant String := Get_Header (Line);
            begin
               case Level is
                  when 1 =>
                     Doc.Lines (L_INCLUDE).Append (Line_Type '(Len => Header'Length,
                                                               Kind => L_HEADER_1,
                                                               Content => Header));

                  when 2 =>
                     Doc.Lines (L_INCLUDE).Append (Line_Type '(Len => Header'Length,
                                                               Kind => L_HEADER_2,
                                                               Content => Header));
                  when 3 =>
                     Doc.Lines (L_INCLUDE).Append (Line_Type '(Len => Header'Length,
                                                               Kind => L_HEADER_3,
                                                               Content => Header));
                  when others =>
                     Doc.Lines (L_INCLUDE).Append (Line_Type '(Len => Header'Length,
                                                               Kind => L_HEADER_4,
                                                               Content => Header));
               end case;
            end;
         end if;
      end if;
   end Append_Line;

   --  ------------------------------
   --  Look and analyze the tag defined on the line.
   --  ------------------------------
   procedure Append_Tag (Doc : in out File_Document;
                         Tag : in String) is
      use Ada.Strings.Unbounded;
      use Ada.Strings;

      Pos : constant Natural := Util.Strings.Index (Tag, ' ');
   begin
      if Pos = 0 then
         return;
      end if;
      declare
         Value : constant String := Ada.Strings.Fixed.Trim (Tag (Pos .. Tag'Last), Spaces, Spaces);
      begin
         if Tag (Tag'First .. Pos - 1) = TAG_TITLE then
            Doc.Title := To_Unbounded_String (Value);

         elsif Tag (Tag'First .. Pos - 1) = TAG_SEE then
            Doc.Lines (L_INCLUDE).Append (Line_Type '(Len     => Value'Length,
                                          Kind    => L_SEE,
                                          Content => Value));

         elsif Tag (Tag'First .. Pos - 1) = TAG_INCLUDE then
            Doc.Lines (L_INCLUDE).Append (Line_Type '(Len     => Value'Length,
                                          Kind    => L_INCLUDE,
                                          Content => Value));

         elsif Tag (Tag'First .. Pos - 1) = TAG_INCLUDE_PERM then
            Doc.Lines (L_INCLUDE).Append (Line_Type '(Len     => Value'Length,
                                          Kind    => L_INCLUDE_PERMISSION,
                                          Content => Value));

         elsif Tag (Tag'First .. Pos - 1) = TAG_INCLUDE_CONFIG then
            Doc.Lines (L_INCLUDE).Append (Line_Type '(Len     => Value'Length,
                                          Kind    => L_INCLUDE_CONFIG,
                                          Content => Value));

         elsif Tag (Tag'First .. Pos - 1) = TAG_INCLUDE_BEAN then
            Doc.Lines (L_INCLUDE).Append (Line_Type '(Len     => Value'Length,
                                          Kind    => L_INCLUDE_BEAN,
                                          Content => Value));

         elsif Tag (Tag'First .. Pos - 1) = TAG_INCLUDE_QUERY then
            Doc.Lines (L_INCLUDE).Append (Line_Type '(Len     => Value'Length,
                                          Kind    => L_INCLUDE_QUERY,
                                          Content => Value));

         elsif Tag (Tag'First .. Pos - 1) = TAG_INCLUDE_DOC then
            Doc.Lines (L_INCLUDE).Append (Line_Type '(Len     => Value'Length,
                                          Kind    => L_INCLUDE_DOC,
                                          Content => Value));

         else
            raise Unknown_Tag with Tag (Tag'First .. Pos - 1);
         end if;
      end;
   end Append_Tag;

   --  ------------------------------
   --  Analyse the documentation line and collect the documentation text.
   --  ------------------------------
   procedure Append (Doc   : in out File_Document;
                     Line  : in String) is
   begin
      if Line'Length >= 1 and then Line (Line'First) = TAG_CHAR then
         --  Force a close of the code extract if we see some @xxx command.
         if Doc.State = IN_CODE or Doc.State = IN_CODE_SEPARATOR then
            Doc.Lines (L_INCLUDE).Append (Line_Type '(Len => 0,
                                                      Kind => L_END_CODE,
                                                      Content => ""));
            Append_Line (Doc, "");
         end if;
         Doc.State := IN_PARA;
         Append_Tag (Doc, Line (Line'First + 1 .. Line'Last));
         return;
      end if;

      case Doc.State is
         when IN_PARA =>
            if Line'Length = 0 then
               Doc.State := IN_SEPARATOR;

            elsif Is_List (Line) then
               Doc.State := IN_LIST;
            end if;
            Append_Line (Doc, Line);

         when IN_SEPARATOR =>
            if Is_List (Line) then
               Doc.State := IN_LIST;

            elsif Is_Code (Line) then
               Doc.State := IN_CODE;
               Doc.Lines (L_INCLUDE).Append (Line_Type '(Len => 0,
                                                         Kind => L_START_CODE,
                                                         Content => ""));
            end if;
            Append_Line (Doc, Line);

         when IN_CODE =>
            if Line'Length = 0 then
               Doc.State := IN_CODE_SEPARATOR;
               return;
            end if;
            Append_Line (Doc, Line);

         when IN_CODE_SEPARATOR =>
            if Line'Length > 0 and
            then (Ada.Characters.Handling.Is_Letter (Line (Line'First))
                  or Line (Line'First) = '=')
            then
               Doc.Lines (L_INCLUDE).Append (Line_Type '(Len => 0,
                                                         Kind => L_END_CODE,
                                                         Content => ""));
               Append_Line (Doc, "");
               Doc.State := IN_PARA;
            end if;
            Append_Line (Doc, Line);

         when IN_LIST =>
            if Is_List (Line) then
               Doc.Lines (L_INCLUDE).Append (Line_Type '(Len => Line'Length,
                                                         Kind => L_LIST, Content => Line));

            elsif Line'Length = 0 then
               Doc.State := IN_SEPARATOR;
               Append_Line (Doc, Line);

            else
               Append_Line (Doc, " " & Ada.Strings.Fixed.Trim (Line, Ada.Strings.Left));
            end if;

      end case;
   end Append;

   --  ------------------------------
   --  After having collected the documentation, terminate the document by making sure
   --  the opened elements are closed.
   --  ------------------------------
   procedure Finish (Doc : in out File_Document) is
   begin
      if Doc.State = IN_CODE or Doc.State = IN_CODE_SEPARATOR then
         Doc.Lines (L_INCLUDE).Append (Line_Type '(Len => 0, Kind => L_END_CODE, Content => ""));
         Doc.State := IN_PARA;
      end if;
   end Finish;

   --  ------------------------------
   --  Set the name associated with the document extract.
   --  ------------------------------
   procedure Set_Name (Doc  : in out File_Document;
                       Name : in String) is
      S1 : String := Ada.Strings.Fixed.Trim (Name, Ada.Strings.Both);
   begin
      for I in S1'Range loop
         if S1 (I) = '.' or S1 (I) = '/' or S1 (I) = '\' then
            S1 (I) := '_';
         end if;
      end loop;
      Doc.Name := Ada.Strings.Unbounded.To_Unbounded_String (S1);
   end Set_Name;

   --  ------------------------------
   --  Set the title associated with the document extract.
   --  ------------------------------
   procedure Set_Title (Doc   : in out File_Document;
                        Title : in String) is
      use Ada.Strings;

      Pos : Natural := Ada.Strings.Fixed.Index (Title, " -- ");
   begin
      if Pos = 0 then
         Pos := Title'First;
      else
         Pos := Pos + 4;
      end if;
      Doc.Title := Unbounded.To_Unbounded_String (Fixed.Trim (Title (Pos .. Title'Last), Both));
   end Set_Title;

   --  ------------------------------
   --  Read the Ada specification/body file and collect the useful documentation.
   --  To keep the implementation simple, we don't use the ASIS packages to scan and extract
   --  the documentation.  We don't need to look at the Ada specification itself.  Instead,
   --  we assume that the Ada source follows some Ada style guidelines.
   --  ------------------------------
   procedure Read_Ada_File (Handler : in out Artifact;
                            File    : in String;
                            Result  : in out File_Document) is
      pragma Unreferenced (Handler);

      procedure Process (Line : in String);

      Done              : Boolean := False;
      Doc_Block         : Boolean := False;

      procedure Process (Line : in String) is
      begin
         Result.Line_Number := Result.Line_Number + 1;
         if Done then
            return;

         elsif Line'Length <= 1 then
            Doc_Block := False;

         elsif Line (Line'Last) = ASCII.CR then
            Result.Line_Number := Result.Line_Number - 1;
            Process (Line (Line'First .. Line'Last - 1));

         elsif Line (Line'First) = '-' and Line (Line'First + 1) = '-' then
            if Doc_Block then
               if Line'Length < 4 then
                  Append (Result, "");

               elsif Line (Line'First + 2) = ' ' and Line (Line'First + 3) = ' ' then
                  Append (Result, Line (Line'First + 4 .. Line'Last));
               end if;
            elsif Line'Length >= 5 and then Line (Line'First .. Line'First + 4) = "--  =" then
               Doc_Block := True;
               Append (Result, Line (Line'First + 4 .. Line'Last));

            elsif Result.Line_Number = 2 then
               Set_Title (Result, Line (Line'First + 2 .. Line'Last));

            end if;

         else
            declare
               Pos  : Natural := Ada.Strings.Fixed.Index (Line, "package");
               Last : Natural;
            begin
               if Pos > 0 then
                  Done := True;
                  Pos := Ada.Strings.Fixed.Index (Line, " ", Pos);
                  if Pos > 0 then
                     Last := Ada.Strings.Fixed.Index (Line, " ", Pos + 1);
                     if Ada.Strings.Fixed.Index (Line (Pos .. Last), "body") = 0 then
                        Set_Name (Result,  Line (Pos .. Last));
                     else
                        Pos := Last;
                        Last := Ada.Strings.Fixed.Index (Line, " ", Pos + 1);
                        Set_Name (Result,  Line (Pos .. Last));
                     end if;
                  end if;
               end if;
            end;

         end if;

      exception
         when E : Unknown_Tag =>
            Log.Error ("{0}:{1}: Unkown comment tag '@{2}'",
                       Ada.Directories.Base_Name (File),
                       Util.Strings.Image (Result.Line_Number),
                       Ada.Exceptions.Exception_Message (E));
      end Process;
   begin
      Util.Files.Read_File (File, Process'Access);
      Finish (Result);
   end Read_Ada_File;

   --  ------------------------------
   --  Read the XML file and extract the documentation.  For this extraction we use
   --  an XSLT stylesheet and run the external tool <b>xstlproc</b>.
   --  ------------------------------
   procedure Read_Xml_File (Handler : in out Artifact;
                            File    : in String;
                            Result  : in out File_Document) is
      function Find_Mode (Line : in String) return Line_Include_Kind;
      procedure Append (Line : in Ada.Strings.Unbounded.Unbounded_String);

      Is_Empty       : Boolean := True;
      Current_Mode   : Line_Include_Kind := L_INCLUDE;

      function Find_Mode (Line : in String) return Line_Include_Kind is
      begin
         if Line = "### Permissions" then
            return L_INCLUDE_PERMISSION;
         elsif Line = "### Queries" then
            return L_INCLUDE_QUERY;
         elsif Line = "### Beans" or Line = "### Mapping" then
            return L_INCLUDE_BEAN;
         elsif Line = "### Configuration" then
            return L_INCLUDE_CONFIG;
         else
            return L_INCLUDE;
         end if;
      end Find_Mode;

      procedure Append (Line : in Ada.Strings.Unbounded.Unbounded_String) is
         Content : constant String := Ada.Strings.Unbounded.To_String (Line);
         Trimmed : constant String := Ada.Strings.Fixed.Trim (Content, Spaces, Spaces);
         Mode    : constant Line_Include_Kind := Find_Mode (Content);
      begin
         if Trimmed'Length > 0 then
            Is_Empty := False;
         end if;
         Result.Lines (L_INCLUDE).Append (Line_Type '(Len  => Trimmed'Length,
                                                      Kind => L_TEXT,
                                                      Content => Trimmed));
         if Mode /= L_INCLUDE then
            Current_Mode := Mode;
            return;
         end if;
         if Current_Mode /= L_INCLUDE then
            Result.Lines (Current_Mode).Append (Line_Type '(Len  => Trimmed'Length,
                                                            Kind => L_TEXT,
                                                            Content => Trimmed));
         end if;
      end Append;

      Pipe    : aliased Util.Streams.Pipes.Pipe_Stream;
      Reader  : Util.Streams.Texts.Reader_Stream;
      Name    : constant String := Ada.Directories.Base_Name (File);
      Command : constant String := Ada.Strings.Unbounded.To_String (Handler.Xslt_Command);
   begin
      Log.Info ("Running {0} {1}", Command, File);
      Pipe.Open (Command & " " & File, Util.Processes.READ);
      Reader.Initialize (Pipe'Unchecked_Access);

      while not Reader.Is_Eof loop
         declare
            Line : Ada.Strings.Unbounded.Unbounded_String;
         begin
            Reader.Read_Line (Line, True);
            Log.Debug ("Doc: {0}", Line);

            Append (Line);
         end;
      end loop;
      Pipe.Close;
      Set_Title (Result, Name);
      Set_Name (Result, Name);
      if Pipe.Get_Exit_Status /= 0 then
         Log.Error ("Command {0} exited with status {1}", Command,
                    Integer'Image (Pipe.Get_Exit_Status));
      end if;
      if Is_Empty then
         Line_Vectors.Clear (Result.Lines (L_INCLUDE));
      end if;

   exception
      when E : Util.Processes.Process_Error =>
         Log.Error ("Command {0} failed: {1}", Command, Ada.Exceptions.Exception_Message (E));
   end Read_Xml_File;

end Gen.Artifacts.Docs;
