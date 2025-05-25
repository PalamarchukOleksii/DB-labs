-- Лабораторна робота №3: Використання динамічного SQL для створення об'єктів бази даних
-- Автор: Студент
-- Мета: Створити пакет з динамічним SQL для створення 5 об'єктів БД

-- Створення специфікації пакета
create or replace package pkg_dynamic_objects is
    -- Константи
   newline constant varchar2(2) := chr(10);
    
    -- Процедура для створення об'єктів БД за назвою таблиці
   procedure create_database_objects (
      p_table_name varchar2
   );
    
    -- Допоміжні процедури для створення кожного типу об'єкта
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
    
    -- Процедура для видалення об'єктів (якщо потрібно)
   procedure drop_objects_if_exist (
      p_table_name varchar2
   );

end pkg_dynamic_objects;
/

-- Створення тіла пакета
create or replace package body pkg_dynamic_objects is

    -- Основна процедура для створення всіх об'єктів
   procedure create_database_objects (
      p_table_name varchar2
   ) is
   begin
      dbms_output.put_line('Початок створення об''єктів для таблиці: ' || p_table_name);
        
        -- Спочатку видаляємо існуючі об'єкти (якщо є)
      drop_objects_if_exist(p_table_name);
        
        -- Створюємо об'єкти в правильному порядку
      create_main_table(p_table_name);
      create_log_table(p_table_name);
      create_sequence(p_table_name);
      create_trigger(p_table_name);
      create_view(p_table_name);
      commit;
      dbms_output.put_line('Всі об''єкти успішно створені для таблиці: ' || p_table_name);
   exception
      when others then
         rollback;
         dbms_output.put_line('Помилка при створенні об''єктів: ' || sqlerrm);
         dbms_output.put_line('Трасування помилки: ' || dbms_utility.format_error_backtrace);
         raise;
   end create_database_objects;

    -- Процедура для видалення існуючих об'єктів
   procedure drop_objects_if_exist (
      p_table_name varchar2
   ) is
      v_sql   varchar2(1000);
      v_count number;
   begin
        -- Видаляємо представлення
      begin
         select count(*)
           into v_count
           from user_views
          where view_name = upper('V_' || p_table_name);

         if v_count > 0 then
            v_sql := 'DROP VIEW V_' || upper(p_table_name);
            execute immediate v_sql;
            dbms_output.put_line('Видалено представлення: V_' || upper(p_table_name));
         end if;
      exception
         when others then
            null;
      end;
        
        -- Видаляємо тригер
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
            dbms_output.put_line('Видалено тригер: TRG_'
                                 || upper(p_table_name)
                                 || '_AUDIT');
         end if;
      exception
         when others then
            null;
      end;
        
        -- Видаляємо таблиці
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
            dbms_output.put_line('Видалено таблицю: ' || table_rec.table_name);
         exception
            when others then
               null;
         end;
      end loop;
        
        -- Видаляємо послідовності
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
            dbms_output.put_line('Видалено послідовність: ' || seq_rec.sequence_name);
         exception
            when others then
               null;
         end;
      end loop;

   end drop_objects_if_exist;

    -- Створення основної таблиці
   procedure create_main_table (
      p_table_name varchar2
   ) is
      v_sql varchar2(4000);
   begin
        -- Формуємо SQL для створення таблиці
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
        
        -- Додаємо коментарі до колонок
      v_sql := 'COMMENT ON TABLE '
               || upper(p_table_name)
               || ' IS ''Основна таблиця для '
               || p_table_name
               || '''';
      execute immediate v_sql;
      v_sql := 'COMMENT ON COLUMN '
               || upper(p_table_name)
               || '.id IS ''Унікальний ідентифікатор''';
      execute immediate v_sql;
      v_sql := 'COMMENT ON COLUMN '
               || upper(p_table_name)
               || '.name IS ''Назва запису''';
      execute immediate v_sql;
      v_sql := 'COMMENT ON COLUMN '
               || upper(p_table_name)
               || '.description IS ''Опис запису''';
      execute immediate v_sql;
      v_sql := 'COMMENT ON COLUMN '
               || upper(p_table_name)
               || '.status IS ''Статус запису (0-неактивний, 1-активний)''';
      execute immediate v_sql;
      dbms_output.put_line('Створено основну таблицю: ' || upper(p_table_name));
   end create_main_table;

    -- Створення журнальної таблиці
   procedure create_log_table (
      p_table_name varchar2
   ) is
      v_sql            varchar2(4000);
      v_log_table_name varchar2(30) := upper(p_table_name || '_LOG');
   begin
        -- Формуємо SQL для створення журнальної таблиці
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
        
        -- Створюємо послідовність для журнальної таблиці
      v_sql := 'CREATE SEQUENCE SEQ_'
               || v_log_table_name
               || '_ID START WITH 1 INCREMENT BY 1 NOCACHE';
      execute immediate v_sql;
        
        -- Додаємо коментар
      v_sql := 'COMMENT ON TABLE '
               || v_log_table_name
               || ' IS ''Журнал змін для таблиці '
               || upper(p_table_name)
               || '''';
      execute immediate v_sql;
      dbms_output.put_line('Створено журнальну таблицю: ' || v_log_table_name);
   end create_log_table;

    -- Створення послідовності
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
        
        -- Примітка: В Oracle не можна додавати коментарі до послідовностей через COMMENT ON
        -- Коментар можна додати тільки при створенні або через словник даних

      dbms_output.put_line('Створено послідовність: ' || v_seq_name);
   end create_sequence;

    -- Створення тригера для аудиту
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
        -- Створюємо тригер для аудиту змін
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
               || '    -- Визначаємо тип операції'
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
               || '    -- Записуємо в журнал'
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
      dbms_output.put_line('Створено тригер: ' || v_trigger_name);
   end create_trigger;

    -- Створення представлення
   procedure create_view (
      p_table_name varchar2
   ) is
      v_sql       varchar2(4000);
      v_view_name varchar2(30) := 'V_' || upper(p_table_name);
   begin
        -- Створюємо представлення з активними записами
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
               || '        WHEN 1 THEN ''Активний'''
               || newline
               || '        WHEN 0 THEN ''Неактивний'''
               || newline
               || '        ELSE ''Невідомо'''
               || newline
               || '    END AS status_name'
               || newline
               || 'FROM '
               || upper(p_table_name)
               || newline
               || 'WHERE status = 1';

      execute immediate v_sql;
        
        -- Додаємо коментар до представлення
      v_sql := 'COMMENT ON VIEW '
               || v_view_name
               || ' IS ''Представлення активних записів таблиці '
               || upper(p_table_name)
               || '''';
      execute immediate v_sql;
      dbms_output.put_line('Створено представлення: ' || v_view_name);
   end create_view;

end pkg_dynamic_objects;
/

-- Приклади використання пакета
begin
   dbms_output.enable(1000000);
    
    -- Створюємо об'єкти для таблиці PRODUCTS
   pkg_dynamic_objects.create_database_objects('PRODUCTS');
end;
/

-- Тестування створених об'єктів
-- Вставляємо тестові дані в таблицю PRODUCTS
insert into products (
   id,
   name,
   description
) values ( seq_products.nextval,
           'Тестовий продукт 1',
           'Опис тестового продукту 1' );

insert into products (
   id,
   name,
   description
) values ( seq_products.nextval,
           'Тестовий продукт 2',
           'Опис тестового продукту 2' );

-- Оновлюємо запис (спрацьовує тригер)
update products
   set
   description = 'Оновлений опис продукту 1'
 where name = 'Тестовий продукт 1';

-- Переглядаємо дані через представлення
select *
  from v_products;

-- Переглядаємо журнал змін
select *
  from products_log
 order by operation_date;

commit;

-- Перевірка створених об'єктів
select 'ТАБЛИЦІ' as object_type,
       table_name as object_name
  from user_tables
 where table_name like '%PRODUCTS%'
    or table_name like '%CUSTOMERS%'
union all
select 'ПОСЛІДОВОСТІ' as object_type,
       sequence_name as object_name
  from user_sequences
 where sequence_name like '%PRODUCTS%'
    or sequence_name like '%CUSTOMERS%'
union all
select 'ТРИГЕРИ' as object_type,
       trigger_name as object_name
  from user_triggers
 where trigger_name like '%PRODUCTS%'
    or trigger_name like '%CUSTOMERS%'
union all
select 'ПРЕДСТАВЛЕННЯ' as object_type,
       view_name as object_name
  from user_views
 where view_name like '%PRODUCTS%'
    or view_name like '%CUSTOMERS%'
 order by object_type,
          object_name;