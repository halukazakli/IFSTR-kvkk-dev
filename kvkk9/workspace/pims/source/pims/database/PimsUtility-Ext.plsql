-----------------------------------------------------------------------------
--
--  Logical unit: PimsUtility
--  Component:    PIMS
--
--  IFS Developer Studio Template Version 3.0
--
--  Date    Sign    History
--  ------  ------  ---------------------------------------------------------
--  191231  Haluk   Created.
-----------------------------------------------------------------------------

layer Ext;

-------------------- PUBLIC DECLARATIONS ------------------------------------

fnd_role_  CONSTANT VARCHAR2(15):= 'PIMS_RUNTIME';

-------------------- PRIVATE DECLARATIONS -----------------------------------


-------------------- LU SPECIFIC IMPLEMENTATION METHODS ---------------------


-------------------- LU SPECIFIC PRIVATE METHODS ----------------------------

PROCEDURE Check_Required_Columns___(
   columns_ IN VARCHAR2,
   sql_ IN VARCHAR2)
IS
   g_count_    NUMBER;
   g_desc_tab_ DBMS_SQL.DESC_TAB;
   
   PROCEDURE describe_columns IS
      l_cur_ INTEGER;
   BEGIN
      l_cur_ := dbms_sql.open_cursor;
      @ApproveDynamicStatement(2019-12-31,Haluk)
      dbms_sql.parse            (l_cur_, sql_, dbms_sql.native);
      dbms_sql.describe_columns (l_cur_, g_count_, g_desc_tab_);
      dbms_sql.close_cursor     (l_cur_);
   EXCEPTION
      WHEN OTHERS THEN
         IF dbms_sql.is_open (l_cur_) THEN 
            dbms_sql.close_cursor (l_cur_);
         END IF;
         RAISE;
   END describe_columns;
BEGIN
   IF sql_ IS NULL THEN
      Error_SYS.Record_General(lu_name_,'PIMSSQLMISSING: Sql statement is required!');
   END IF;
   
   IF columns_ IS NULL THEN
      Error_SYS.Record_General(lu_name_,'PIMSCOLUMNSMISSING: Required columns are required!');
   END IF;
      
   describe_columns;
   FOR i IN  1 .. g_count_ LOOP
      IF INSTR(columns_, g_desc_tab_(i).col_name) = 0 THEN
         Error_SYS.Record_General(lu_name_,'PIMSREQUIREDCOLUMN: Columns list does not match the required columns!');
      END IF;
   END LOOP;
   
   DECLARE
      l_input_ VARCHAR2(4000) := replace(columns_,' ','');
      l_count_ BINARY_INTEGER;
      l_array_ dbms_utility.lname_array;
      found_  NUMBER:=0;
   BEGIN
      dbms_utility.comma_to_table(regexp_replace(l_input_, '(^|,)', '\1x'), l_count_, l_array_);
      FOR I IN 1 .. l_count_ LOOP
         found_ := 0;
         FOR j IN  1 .. g_count_ LOOP
            IF trim(g_desc_tab_(j).col_name) = trim(substr(l_array_(i), 2)) THEN
               found_ :=1;
            END IF;
         END LOOP;
         
         IF found_ = 0 THEN
            Error_SYS.Record_General(lu_name_,'PIMSMISSINGCOLUMN: Required columns is missing! ' || substr(l_array_(i), 2));
         END IF;
      END LOOP;
   END;
END Check_Required_Columns___;

PROCEDURE Check_Role_Exists___
IS
   count_ NUMBER;
BEGIN
   SELECT COUNT(*) 
   INTO   count_
   FROM   FND_ROLE 
   WHERE  ROLE = fnd_role_;
   
   IF count_ = 0 THEN
      Error_SYS.Record_General(lu_name_,'PIMSROLENOTFOUND: Required user role was not found!');
   END IF;
END Check_Role_Exists___;

PROCEDURE Create_View___(
   view_name_    IN VARCHAR2,
   view_sql_     IN VARCHAR2,
   description_  IN VARCHAR2,
   created_by_   IN VARCHAR2)
IS
   view_info_  VARCHAR2(500)  := chr(13) || chr(10) || '-------------------------------------------------' ||
                                 chr(13) || chr(10) || '-- Description: ' || description_ || 
                                 chr(13) || chr(10) || '-- Create Date: ' || to_char(sysdate,'yyyy-mm-dd hh24:mi') ||
                                 chr(13) || chr(10) || '-- Created By: ' || created_by_ || 
                                 chr(13) || chr(10) || '-- Fnd User: ' || Fnd_Session_Api.Get_Fnd_User || 
                                 chr(13) || chr(10) || '-------------------------------------------------';
BEGIN
   Check_Role_Exists___;
   
   @ApproveDynamicStatement(2019-12-31,Haluk)
   EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW ' || view_name_ || ' AS ' || view_sql_ || view_info_;
   
   @ApproveDynamicStatement(2019-12-31,Haluk)
   EXECUTE IMMEDIATE 'COMMENT ON TABLE ' || view_name_ || ' IS ''LU=' || lu_name_ || '^PROMPT=' || view_name_ || '^MODULE=' || module_ || '^''';
   
   @ApproveDynamicStatement(2019-12-31,Haluk)
   EXECUTE IMMEDIATE 'GRANT ALL ON ' || view_name_ || ' TO ' || fnd_role_;
   
   dbms_output.put_line('View created: ' || view_name_);
END Create_View___;

-------------------- LU SPECIFIC PROTECTED METHODS --------------------------


-------------------- LU SPECIFIC PUBLIC METHODS -----------------------------

PROCEDURE Create_Data_Subject(
   name_        IN VARCHAR2,
   sql_         IN VARCHAR2,
   description_ IN VARCHAR2,
   created_by_  IN VARCHAR2)
IS
   columns_    VARCHAR2(100) := 'ID, NAME';
   view_name_  VARCHAR2(30)  := module_ || '_DS_$' || name_;
BEGIN
   Check_Required_Columns___(columns_, sql_);
   Create_View___(view_name_, sql_, description_, created_by_);
END Create_Data_Subject;

PROCEDURE Create_Personal_Data(
   name_        IN VARCHAR2,
   id_          IN NUMBER,
   sql_         IN VARCHAR2,
   description_ IN VARCHAR2,
   created_by_  IN VARCHAR2)
IS
   columns_    VARCHAR2(100) := 'ID, PERSONAL_DATA, KEY_REFERENCE';
   view_name_  VARCHAR2(30)  := module_ || '_PD_$' || name_ || '$'|| id_;
BEGIN
   Check_Required_Columns___(columns_, sql_);
   Create_View___(view_name_, sql_, description_, created_by_);
END Create_Personal_Data;

PROCEDURE Create_Purpose(
   purpose_id_  IN VARCHAR2,
   sql_         IN VARCHAR2,
   description_ IN VARCHAR2,
   created_by_  IN VARCHAR2)
IS
   columns_    VARCHAR2(100) := 'ID';
   view_name_  VARCHAR2(30)  := module_ || '_P_$' || purpose_id_;
BEGIN
   Check_Required_Columns___(columns_, sql_);
   Create_View___(view_name_, sql_, description_, created_by_);
END Create_Purpose;

PROCEDURE Drop_Data_Subject(
   name_ IN VARCHAR2)
IS
   view_name_  VARCHAR2(30)  := module_ || '_DS_$' || name_;
BEGIN
   @ApproveDynamicStatement(2019-12-31,Haluk)
   EXECUTE IMMEDIATE 'DROP VIEW ' || view_name_;
END Drop_Data_Subject;

PROCEDURE Drop_Personal_Data(
   name_ IN VARCHAR2,
   id_   IN NUMBER)
IS
   view_name_  VARCHAR2(30)  := module_ || '_PD_$' || name_ || '$'|| id_;
BEGIN
   @ApproveDynamicStatement(2019-12-31,Haluk)
   EXECUTE IMMEDIATE 'DROP VIEW ' || view_name_;
END Drop_Personal_Data;

PROCEDURE Drop_Purpose(
   purpose_id_ IN VARCHAR2)
IS
   view_name_  VARCHAR2(30)  := module_ || '_P_$' || purpose_id_;
BEGIN
   @ApproveDynamicStatement(2019-12-31,Haluk)
   EXECUTE IMMEDIATE 'DROP VIEW ' || view_name_;
END Drop_Purpose;

PROCEDURE Anonymize_Data(
   data_subject_name_  IN VARCHAR2,
   personal_data_name_ IN VARCHAR2,
   data_source_id_     IN NUMBER,
   id_                 IN VARCHAR2,
   table_name_         IN VARCHAR2,
   key_field_          IN VARCHAR2,
   personal_data_type_ IN VARCHAR2, -- DataColumn, DataRow, Picture, document
   cleanup_method_     IN VARCHAR2, -- Remove, Anonymize
   data_type_          IN VARCHAR2, -- String, Number, Date, Blob, Clob
   update_field_       IN VARCHAR2,
   update_data_        IN VARCHAR2)
IS
   query_sql_ VARCHAR2(2000);
   execute_sql_ VARCHAR2(2000);
   key_data_  VARCHAR2(30);
BEGIN
   query_sql_ := 'SELECT MIN(PD.KEY_REFERENCE)
  FROM PIMS_DS_$' || data_subject_name_ || ' DS, PIMS_PD_$' || personal_data_name_ || '$' || data_source_id_ || ' PD
 WHERE DS.ID = PD.ID
   AND PD.ID = ''' || id_ || '''';
   dbms_output.Put_Line('Query: ' || query_sql_);
   
   @ApproveDynamicStatement(2019-12-31,Haluk)
   EXECUTE IMMEDIATE query_sql_ INTO key_data_;
   dbms_output.Put_Line('Key Data: ' || key_data_);
   
   
   IF personal_data_type_ = 'DataRow' THEN
      execute_sql_ := 'DELETE FROM ' || table_name_ || ' WHERE ' || key_field_ || ' = ''' || key_data_ || '''';
   ELSIF personal_data_type_ = 'DataColumn' THEN
      execute_sql_ := 'UPDATE ' || table_name_ || ' SET ' || update_field_ || ' = ';
      IF cleanup_method_ = 'Remove' THEN
         execute_sql_ := execute_sql_ || 'null';
      ELSE
         IF data_type_ = 'Number' THEN
            execute_sql_ := execute_sql_ || 'to_number(nvl(''' || update_data_ || ''',0))';
         ELSIF data_type_ = 'Date' THEN
            execute_sql_ := execute_sql_ || 'to_date(nvl(''' || update_data_ || ''',''1001-01-01''),''yyyy-MM-dd'')';
         ELSE 
            execute_sql_ := execute_sql_ || '''' || update_data_ || '''';
         END IF;
      END IF;
      execute_sql_ := execute_sql_ || ' WHERE ' || key_field_ || ' = ''' || key_data_ || '''';
   ELSE
      NULL;
   END IF;
   dbms_output.Put_Line('Execute Sql_: ' || execute_sql_);
   
--   @ApproveDynamicStatement(2019-12-31,Haluk)
--   EXECUTE IMMEDIATE execute_sql_;
--   dbms_output.Put_Line('Executed.');
END Anonymize_Data;