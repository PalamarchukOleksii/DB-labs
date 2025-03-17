begin
   execute immediate 'DROP TABLE table1 CASCADE CONSTRAINTS';
   execute immediate 'DROP TABLE table2 CASCADE CONSTRAINTS';
   execute immediate 'DROP SEQUENCE seq_table1_id';
   execute immediate 'DROP SEQUENCE seq_table2_id';
exception
   when others then
      null;
end;
/

create table table1 (
   id   number primary key,
   col2 number,
   col3 number,
   col4 number,
   col5 number,
   col6 number
);

create table table2 (
   id   number primary key,
   col2 varchar2(1),
   col3 varchar2(1),
   col4 varchar2(1),
   col5 varchar2(1),
   col6 varchar2(1)
);

create sequence seq_table1_id start with 1 increment by 1;
create sequence seq_table2_id start with 1 increment by 1;

create or replace trigger trg_table1_before_insert before
   insert on table1
   for each row
begin
   :new.id := seq_table1_id.nextval;
end;
/

create or replace trigger trg_table2_before_insert before
   insert on table2
   for each row
begin
   :new.id := seq_table2_id.nextval;
end;
/

declare
   num_rows number := 5;
begin
   for i in 1..num_rows loop
      insert into table1 (
         col2,
         col3,
         col4,
         col5,
         col6
      ) values ( floor(dbms_random.value(
         1,
         100
      )),
                 floor(dbms_random.value(
                    1,
                    100
                 )),
                 floor(dbms_random.value(
                    1,
                    100
                 )),
                 floor(dbms_random.value(
                    1,
                    100
                 )),
                 floor(dbms_random.value(
                    1,
                    100
                 )) );
   end loop;

   for i in 1..num_rows loop
      insert into table2 (
         col2,
         col3,
         col4,
         col5,
         col6
      ) values ( chr(floor(dbms_random.value(
         65,
         90
      ))),
                 chr(floor(dbms_random.value(
                    65,
                    90
                 ))),
                 chr(floor(dbms_random.value(
                    65,
                    90
                 ))),
                 chr(floor(dbms_random.value(
                    65,
                    90
                 ))),
                 chr(floor(dbms_random.value(
                    65,
                    90
                 ))) );
   end loop;

   commit;
end;
/

declare
   type row_type is
      table of number;
   type matrix_type is
      table of row_type;
   matrix matrix_type := matrix_type();
   v_row  row_type;
   cursor cur is
   select id,
          col2,
          col3,
          col4,
          col5,
          col6
     from table1;
begin
   for r in cur loop
      v_row := row_type(
         r.id,
         r.col2,
         r.col3,
         r.col4,
         r.col5,
         r.col6
      );
      matrix.extend;
      matrix(matrix.last) := v_row;
   end loop;

   for i in 1..matrix.count loop
      for j in 1..matrix(i).count loop
         dbms_output.put(matrix(i)(j)
                         || ' ');
      end loop;
      dbms_output.put_line('');
   end loop;
end;
/

declare
   type t_row is
      table of number;
   type t_matrix is
      table of t_row;
   v_matrix    t_matrix := t_matrix();
   v_max_value number := -999999;
   v_rows      number;
   v_cols      number;
   cursor cur is
   select id,
          col2,
          col3,
          col4,
          col5,
          col6
     from table1;
begin
   for r in cur loop
      v_matrix.extend;
      v_matrix(v_matrix.count) := t_row(
         r.id,
         r.col2,
         r.col3,
         r.col4,
         r.col5,
         r.col6
      );
   end loop;

   v_rows := v_matrix.count;
   if v_rows > 0 then
      v_cols := v_matrix(1).count;
   else
      raise_application_error(
         -20001,
         'Table is empty'
      );
   end if;

   dbms_output.put_line('Processing matrix dimensions: '
                        || v_rows
                        || 'x'
                        || v_cols);
   dbms_output.put_line('Processing left half:');
   for j in 0..( v_cols / 2 ) loop
      for i in j..( v_rows - j - 1 ) loop
         dbms_output.put_line('Checking element ['
                              || i
                              || ','
                              || j
                              || ']: '
                              || v_matrix(i + 1)(j + 1));
         if v_matrix(i + 1)(j + 1) > v_max_value then
            v_max_value := v_matrix(i + 1)(j + 1);
         end if;
      end loop;
   end loop;

   dbms_output.put_line('Processing right half:');
   for j in ( v_cols / 2 )..( v_cols - 1 ) loop
      for i in ( v_cols - j - 1 )..( v_rows - v_cols + j ) loop
         dbms_output.put_line('Checking element ['
                              || i
                              || ','
                              || j
                              || ']: '
                              || v_matrix(i + 1)(j + 1));
         if v_matrix(i + 1)(j + 1) > v_max_value then
            v_max_value := v_matrix(i + 1)(j + 1);
         end if;
      end loop;
   end loop;

   dbms_output.put_line('Maximum value in the shaded area: ' || v_max_value);
exception
   when no_data_found then
      dbms_output.put_line('No data found in the cursor');
   when others then
      dbms_output.put_line('An error occurred: ' || sqlerrm);
end;
/

declare
   v_rec        table2%rowtype;
   v_row_string varchar2(100);
begin
   select *
     into v_rec
     from table2
    where id = 1;

   v_rec.col2 := 'H';
   v_rec.col3 := 'E';
   v_rec.col4 := 'L';
   v_rec.col5 := 'L';
   v_rec.col6 := 'O';
   update table2
      set col2 = v_rec.col2,
          col3 = v_rec.col3,
          col4 = v_rec.col4,
          col5 = v_rec.col5,
          col6 = v_rec.col6
    where id = 1;

   commit;
   v_row_string := v_rec.id
                   || ' | '
                   || v_rec.col2
                   || ' | '
                   || v_rec.col3
                   || ' | '
                   || v_rec.col4
                   || ' | '
                   || v_rec.col5
                   || ' | '
                   || v_rec.col6;

   dbms_output.put_line('Updated row 1: ' || v_row_string);
exception
   when no_data_found then
      dbms_output.put_line('Error: Row with ID = 1 not found.');
   when others then
      dbms_output.put_line('Error: ' || sqlerrm);
end;
/