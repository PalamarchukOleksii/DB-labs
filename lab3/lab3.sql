-- Package Specification Creation
create or replace package pkg_dynamic_objects is
    -- Constants
   newline constant varchar2(2) := chr(10);

    -- Procedure to create DB objects based on table name
   procedure create_database_objects (
      p_table_name varchar2
   );

    -- Helper procedures for creating each object type
   procedure create_main_table (
      p_table_name varchar2
   );
   procedure create_log_table (
      p_table_name varchar2
   );
   procedure create_sequence (
      p_table_name varchar2
   );
   procedure create_trigger (
      p_table_name varchar2
   );
   procedure create_view (
      p_table_name varchar2
   );

    -- Procedure to drop objects (if needed)
   procedure drop_objects_if_exist (
      p_table_name varchar2
   );

end pkg_dynamic_objects;
/

-- Package Body Creation
create or replace package body pkg_dynamic_objects is

    -- Main procedure to create all objects
   procedure create_database_objects (
      p_table_name varchar2
   ) is
   begin
      dbms_output.put_line('Starting object creation for table: ' || p_table_name);

        -- First, drop existing objects (if any)
      drop_objects_if_exist(p_table_name);

        -- Create objects in the correct order
      create_main_table(p_table_name);
      create_log_table(p_table_name);
      create_sequence(p_table_name);
      create_trigger(p_table_name);
      create_view(p_table_name);
      commit;
      dbms_output.put_line('All objects successfully created for table: ' || p_table_name);
   exception
      when others then
         rollback;
         dbms_output.put_line('Error creating objects: ' || sqlerrm);
         dbms_output.put_line('Error backtrace: ' || dbms_utility.format_error_backtrace);
         raise;
   end create_database_objects;

    -- Procedure to drop existing objects
   procedure drop_objects_if_exist (
      p_table_name varchar2
   ) is
      v_sql   varchar2(1000);
      v_count number;
   begin
        -- Drop view
      begin
         select count(*)
           into v_count
           from user_views
          where view_name = upper('V_' || p_table_name);

         if v_count > 0 then
            v_sql := 'DROP VIEW V_' || upper(p_table_name);
            execute immediate v_sql;
            dbms_output.put_line('Dropped view: V_' || upper(p_table_name));
         end if;
      exception
         when others then
            null; -- Ignore if view does not exist
      end;

        -- Drop trigger
      begin
         select count(*)
           into v_count
           from user_triggers
          where trigger_name = upper('TRG_'
                                     || p_table_name
                                     || '_AUDIT');

         if v_count > 0 then
            v_sql := 'DROP TRIGGER TRG_'
                     || upper(p_table_name)
                     || '_AUDIT';
            execute immediate v_sql;
            dbms_output.put_line('Dropped trigger: TRG_'
                                 || upper(p_table_name)
                                 || '_AUDIT');
         end if;
      exception
         when others then
            null; -- Ignore if trigger does not exist
      end;

        -- Drop tables
      for table_rec in (
         select table_name
           from user_tables
          where table_name in ( upper(p_table_name),
                                upper(p_table_name || '_LOG') )
      ) loop
         begin
            v_sql := 'DROP TABLE '
                     || table_rec.table_name
                     || ' CASCADE CONSTRAINTS';
            execute immediate v_sql;
            dbms_output.put_line('Dropped table: ' || table_rec.table_name);
         exception
            when others then
               null; -- Ignore if table does not exist
         end;
      end loop;

        -- Drop sequences
      for seq_rec in (
         select sequence_name
           from user_sequences
          where sequence_name like upper('SEQ_'
                                         || p_table_name
                                         || '%')
      ) loop
         begin
            v_sql := 'DROP SEQUENCE ' || seq_rec.sequence_name;
            execute immediate v_sql;
            dbms_output.put_line('Dropped sequence: ' || seq_rec.sequence_name);
         exception
            when others then
               null; -- Ignore if sequence does not exist
         end;
      end loop;

   end drop_objects_if_exist;

    -- Create Main Table
   procedure create_main_table (
      p_table_name varchar2
   ) is
      v_sql varchar2(4000);
   begin
        -- Construct SQL for table creation
      v_sql := 'CREATE TABLE '
               || upper(p_table_name)
               || ' ('
               || newline
               || '    id NUMBER PRIMARY KEY,'
               || newline
               || '    name VARCHAR2(100) NOT NULL,'
               || newline
               || '    description VARCHAR2(500),'
               || newline
               || '    created_date DATE DEFAULT SYSDATE,'
               || newline
               || '    updated_date DATE DEFAULT SYSDATE,'
               || newline
               || '    status NUMBER(1) DEFAULT 1 CHECK (status IN (0,1)),'
               || newline
               || '    created_by VARCHAR2(50) DEFAULT USER,'
               || newline
               || '    updated_by VARCHAR2(50) DEFAULT USER'
               || newline
               || ')';

      execute immediate v_sql;

        -- Add comments to columns
      v_sql := 'COMMENT ON TABLE '
               || upper(p_table_name)
               || ' IS ''Main table for '
               || p_table_name
               || '''';
      execute immediate v_sql;
      v_sql := 'COMMENT ON COLUMN '
               || upper(p_table_name)
               || '.id IS ''Unique identifier''';
      execute immediate v_sql;
      v_sql := 'COMMENT ON COLUMN '
               || upper(p_table_name)
               || '.name IS ''Name of the record''';
      execute immediate v_sql;
      v_sql := 'COMMENT ON COLUMN '
               || upper(p_table_name)
               || '.description IS ''Description of the record''';
      execute immediate v_sql;
      v_sql := 'COMMENT ON COLUMN '
               || upper(p_table_name)
               || '.status IS ''Record status (0-inactive, 1-active)''';
      execute immediate v_sql;
      dbms_output.put_line('Created main table: ' || upper(p_table_name));
   end create_main_table;

    -- Create Log Table
   procedure create_log_table (
      p_table_name varchar2
   ) is
      v_sql            varchar2(4000);
      v_log_table_name varchar2(30) := upper(p_table_name || '_LOG');
   begin
        -- Construct SQL for log table creation
      v_sql := 'CREATE TABLE '
               || v_log_table_name
               || ' ('
               || newline
               || '    log_id NUMBER PRIMARY KEY,'
               || newline
               || '    table_name VARCHAR2(30) DEFAULT '''
               || upper(p_table_name)
               || ''','
               || newline
               || '    record_id NUMBER,'
               || newline
               || '    operation VARCHAR2(10) CHECK (operation IN (''INSERT'', ''UPDATE'', ''DELETE'')),'
               || newline
               || '    old_values CLOB,'
               || newline
               || '    new_values CLOB,'
               || newline
               || '    operation_date DATE DEFAULT SYSDATE,'
               || newline
               || '    operation_user VARCHAR2(50) DEFAULT USER'
               || newline
               || ')';

      execute immediate v_sql;

        -- Create sequence for log table
      v_sql := 'CREATE SEQUENCE SEQ_'
               || v_log_table_name
               || '_ID START WITH 1 INCREMENT BY 1 NOCACHE';
      execute immediate v_sql;

        -- Add comment
      v_sql := 'COMMENT ON TABLE '
               || v_log_table_name
               || ' IS ''Change log for table '
               || upper(p_table_name)
               || '''';
      execute immediate v_sql;
      dbms_output.put_line('Created log table: ' || v_log_table_name);
   end create_log_table;

    -- Create Sequence
   procedure create_sequence (
      p_table_name varchar2
   ) is
      v_sql      varchar2(1000);
      v_seq_name varchar2(30) := 'SEQ_' || upper(p_table_name);
   begin
      v_sql := 'CREATE SEQUENCE '
               || v_seq_name
               || ' START WITH 1 INCREMENT BY 1 NOCACHE NOMAXVALUE';
      execute immediate v_sql;
      dbms_output.put_line('Created sequence: ' || v_seq_name);
   end create_sequence;

    -- Create Audit Trigger
   procedure create_trigger (
      p_table_name varchar2
   ) is
      v_sql            varchar2(4000);
      v_trigger_name   varchar2(30) := 'TRG_'
                                     || upper(p_table_name)
                                     || '_AUDIT';
      v_log_table_name varchar2(30) := upper(p_table_name)
                                       || '_LOG';
   begin
        -- Create trigger for auditing changes
      v_sql := 'CREATE OR REPLACE TRIGGER '
               || v_trigger_name
               || newline
               || 'AFTER INSERT OR UPDATE OR DELETE ON '
               || upper(p_table_name)
               || newline
               || 'FOR EACH ROW'
               || newline
               || 'DECLARE'
               || newline
               || '    v_operation VARCHAR2(10);'
               || newline
               || '    v_old_values CLOB;'
               || newline
               || '    v_new_values CLOB;'
               || newline
               || '    v_record_id NUMBER;'
               || newline
               || 'BEGIN'
               || newline
               || '    -- Determine operation type'
               || newline
               || '    IF INSERTING THEN'
               || newline
               || '        v_operation := ''INSERT'';'
               || newline
               || '        v_record_id := :NEW.id;'
               || newline
               || '        v_new_values := ''name='' || :NEW.name || ''; description='' || :NEW.description || ''; status='' || :NEW.status;'
               || newline
               || '    ELSIF UPDATING THEN'
               || newline
               || '        v_operation := ''UPDATE'';'
               || newline
               || '        v_record_id := :NEW.id;'
               || newline
               || '        v_old_values := ''name='' || :OLD.name || ''; description='' || :OLD.description || ''; status='' || :OLD.status;'
               || newline
               || '        v_new_values := ''name='' || :NEW.name || ''; description='' || :NEW.description || ''; status='' || :NEW.status;'
               || newline
               || '    ELSIF DELETING THEN'
               || newline
               || '        v_operation := ''DELETE'';'
               || newline
               || '        v_record_id := :OLD.id;'
               || newline
               || '        v_old_values := ''name='' || :OLD.name || ''; description='' || :OLD.description || ''; status='' || :OLD.status;'
               || newline
               || '    END IF;'
               || newline
               || newline
               || '    -- Log the change'
               || newline
               || '    INSERT INTO '
               || v_log_table_name
               || ' (log_id, record_id, operation, old_values, new_values)'
               || newline
               || '    VALUES (SEQ_'
               || v_log_table_name
               || '_ID.NEXTVAL, v_record_id, v_operation, v_old_values, v_new_values);'
               || newline
               || 'END;';

      execute immediate v_sql;
      dbms_output.put_line('Created trigger: ' || v_trigger_name);
   end create_trigger;

    -- Create View
   procedure create_view (
      p_table_name varchar2
   ) is
      v_sql       varchar2(4000);
      v_view_name varchar2(30) := 'V_' || upper(p_table_name);
   begin
        -- Create view with active records
      v_sql := 'CREATE OR REPLACE VIEW '
               || v_view_name
               || ' AS'
               || newline
               || 'SELECT '
               || newline
               || '    id,'
               || newline
               || '    name,'
               || newline
               || '    description,'
               || newline
               || '    created_date,'
               || newline
               || '    updated_date,'
               || newline
               || '    created_by,'
               || newline
               || '    updated_by,'
               || newline
               || '    CASE status '
               || newline
               || '        WHEN 1 THEN ''Active'''
               || newline
               || '        WHEN 0 THEN ''Inactive'''
               || newline
               || '        ELSE ''Unknown'''
               || newline
               || '    END AS status_name'
               || newline
               || 'FROM '
               || upper(p_table_name)
               || newline
               || 'WHERE status = 1';

      execute immediate v_sql;

        -- Add comment to view
      v_sql := 'COMMENT ON TABLE '
               || v_view_name
               || ' IS ''View of active records for table '
               || upper(p_table_name)
               || '''';
      execute immediate v_sql;
      dbms_output.put_line('Created view: ' || v_view_name);
   end create_view;

end pkg_dynamic_objects;
/

-- Examples of package usage
begin
   dbms_output.enable(1000000);

    -- Create objects for the PRODUCTS table
   pkg_dynamic_objects.create_database_objects('PRODUCTS');
end;
/

-- Testing the created objects
-- Insert test data into the PRODUCTS table
insert into products (
   id,
   name,
   description
) values ( seq_products.nextval,
           'Test Product 1',
           'Description of Test Product 1' );

insert into products (
   id,
   name,
   description
) values ( seq_products.nextval,
           'Test Product 2',
           'Description of Test Product 2' );

-- Update a record (trigger will fire)
update products
   set
   description = 'Updated description for Product 1'
 where name = 'Test Product 1';

-- View data through the view
select *
  from v_products;

-- View the change log
select *
  from products_log
 order by operation_date;

commit;

-- Verify created objects
select 'TABLES' as object_type,
       table_name as object_name
  from user_tables
 where table_name like '%PRODUCTS%'
    or table_name like '%CUSTOMERS%'
union all
select 'SEQUENCES' as object_type,
       sequence_name as object_name
  from user_sequences
 where sequence_name like '%PRODUCTS%'
    or sequence_name like '%CUSTOMERS%'
union all
select 'TRIGGERS' as object_type,
       trigger_name as object_name
  from user_triggers
 where trigger_name like '%PRODUCTS%'
    or trigger_name like '%CUSTOMERS%'
union all
select 'VIEWS' as object_type,
       view_name as object_name
  from user_views
 where view_name like '%PRODUCTS%'
    or view_name like '%CUSTOMERS%'
 order by object_type,
          object_name;