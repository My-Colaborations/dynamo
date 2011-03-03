-----------------------------------------------------------------------
--  gen-artifacts -- Artifacts for Code Generator
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
with Ada.Finalization;

with DOM.Core;
with Gen.Model;
with Gen.Model.Packages;

--  The <b>Gen.Artifacts</b> package represents the methods and process to prepare,
--  control and realize the code generation.
package Gen.Artifacts is

   --  ------------------------------
   --  Model Definition
   --  ------------------------------
   type Artifact is abstract new Ada.Finalization.Limited_Controlled with private;

   --  After the configuration file is read, processes the node whose root
   --  is passed in <b>Node</b> and initializes the <b>Model</b> with the information.
   procedure Initialize (Handler : in Artifact;
                         Path    : in String;
                         Node    : in DOM.Core.Node;
                         Model   : in out Gen.Model.Packages.Model_Definition'Class) is abstract;

   --  Prepare the model after all the configuration files have been read and before
   --  actually invoking the generation.
   procedure Prepare (Handler : in Artifact;
                      Model   : in out Gen.Model.Packages.Model_Definition'Class) is null;

private

   type Artifact is abstract new Ada.Finalization.Limited_Controlled with record
      Node : DOM.Core.Node;
   end record;

end Gen.Artifacts;
