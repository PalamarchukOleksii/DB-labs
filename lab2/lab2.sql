begin
   execute immediate 'DROP TABLE TempSales';
   execute immediate 'DROP TABLE TempBasketHeader';
   execute immediate 'DROP TABLE TempBasketFilter';
exception
   when others then
      null;
end;
/

create table tempsales (
   checkid   varchar2(50) null,
   productid varchar2(50) not null,
   amount    number(10,3) not null,
   id        number
      generated always as identity
);

insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41001',
           'Beer',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41001',
           'Wine',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41001',
           'Olives',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41001',
           'Omelette',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41001',
           'Beer',
           5 );

insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41002',
           'Wine',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41002',
           'Omelette',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41002',
           'TOMATO JUICE',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41002',
           'Cheesesteak Salad',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41002',
           'Olives',
           10 );

insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41003',
           'Beer',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41003',
           'Olives',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41003',
           'Bacon Omelette',
           10 );

insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41004',
           'Bacon Omelette',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41004',
           'TOMATO JUICE',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41004',
           'Cheesesteak Salad',
           10 );
insert into tempsales (
   checkid,
   productid,
   amount
) values ( '41004',
           'Greek Salad',
           10 );

create table tempbasketheader (
   basketid   raw(16) not null,
   basketname varchar2(100) not null
);

alter table tempbasketheader add constraint pk_tempbasketheader primary key ( basketname );

create table tempbasketfilter (
   basketid       raw(16) not null,
   basketfilterid raw(16) default sys_guid() not null,
   productid      varchar2(50) not null,
   excludeflag    varchar2(1) default 'N' not null
);

alter table tempbasketfilter add constraint pk_tempbasketfilter primary key ( basketfilterid );

declare
   v_basketid raw(16);
begin
   v_basketid := sys_guid();
   insert into tempbasketheader (
      basketid,
      basketname
   ) values ( v_basketid,
              'Include Beer' );
   insert into tempbasketfilter (
      basketid,
      productid,
      excludeflag
   ) values ( v_basketid,
              'Beer',
              'N' );

   v_basketid := sys_guid();
   insert into tempbasketheader (
      basketid,
      basketname
   ) values ( v_basketid,
              'Exclude Beer' );
   insert into tempbasketfilter (
      basketid,
      productid,
      excludeflag
   ) values ( v_basketid,
              'Beer',
              'Y' );

   v_basketid := sys_guid();
   insert into tempbasketheader (
      basketid,
      basketname
   ) values ( v_basketid,
              'Include Beer and Exclude Wine' );
   insert into tempbasketfilter (
      basketid,
      productid,
      excludeflag
   ) values ( v_basketid,
              'Beer',
              'N' );
   insert into tempbasketfilter (
      basketid,
      productid,
      excludeflag
   ) values ( v_basketid,
              'Wine',
              'Y' );

   v_basketid := sys_guid();
   insert into tempbasketheader (
      basketid,
      basketname
   ) values ( v_basketid,
              'Empty Basket' );

   v_basketid := sys_guid();
   insert into tempbasketheader (
      basketid,
      basketname
   ) values ( v_basketid,
              'Exclude Beer and Wine' );
   insert into tempbasketfilter (
      basketid,
      productid,
      excludeflag
   ) values ( v_basketid,
              'Beer',
              'Y' );
   insert into tempbasketfilter (
      basketid,
      productid,
      excludeflag
   ) values ( v_basketid,
              'Wine',
              'Y' );

   v_basketid := sys_guid();
   insert into tempbasketheader (
      basketid,
      basketname
   ) values ( v_basketid,
              'Include both Beer and Wine' );
   insert into tempbasketfilter (
      basketid,
      productid,
      excludeflag
   ) values ( v_basketid,
              'Beer',
              'N' );
   insert into tempbasketfilter (
      basketid,
      productid,
      excludeflag
   ) values ( v_basketid,
              'Wine',
              'N' );

end;
/

select *
  from tempsales;
select *
  from tempbasketheader;
select *
  from tempbasketfilter;

commit;

begin
   execute immediate 'DROP TYPE BASKET_RESULT_TAB';
   execute immediate 'DROP TYPE BASKET_RESULT_OBJ';
   execute immediate 'DROP PACKAGE pktest';
exception
   when others then
      null;
end;
/

create or replace type basket_result_obj as object (
      basket_name  varchar2(255),
      total_amount number,
      check_count  number
);
/

create or replace type basket_result_tab as
   table of basket_result_obj;
/

create or replace package pktest as
   function gettableinfo return basket_result_tab
      pipelined;

   procedure getgeneraltable (
      odata out sys_refcursor
   );

   e_no_data_found exception;
   pragma exception_init ( e_no_data_found,-20001 );
end pktest;
/

create or replace package body pktest as
   function gettableinfo return basket_result_tab
      pipelined
   is
      v_basket_name  tempbasketheader.basketname%type;
      v_basket_id    tempbasketheader.basketid%type;
      v_check_count  number;
      v_total_amount number;
      v_basket_count number := 0;
      cursor c_baskets is
      select basketid,
             basketname
        from tempbasketheader
       order by basketname;

   begin
      select count(*)
        into v_basket_count
        from tempbasketheader;

      if v_basket_count = 0 then
         raise_application_error(
            -20001,
            'No basket data found'
         );
      end if;
      for r_basket in c_baskets loop
         v_basket_id := r_basket.basketid;
         v_basket_name := r_basket.basketname;
         with eligible_checks as (
            select distinct s.checkid
              from tempsales s
             where not exists (
               select 1
                 from tempbasketfilter f
                where f.basketid = v_basket_id
                  and ( ( f.excludeflag = 'N'
                  and not exists (
                  select 1
                    from tempsales s2
                   where s2.checkid = s.checkid
                     and s2.productid = f.productid
               ) )
                   or ( f.excludeflag = 'Y'
                  and exists (
                  select 1
                    from tempsales s2
                   where s2.checkid = s.checkid
                     and s2.productid = f.productid
               ) ) )
            )
         )
         select count(distinct s.checkid),
                nvl(
                   sum(s.amount),
                   0
                )
           into
            v_check_count,
            v_total_amount
           from tempsales s
          where s.checkid in (
            select checkid
              from eligible_checks
         );

         pipe row ( basket_result_obj(
            v_basket_name,
            v_total_amount,
            v_check_count
         ) );
      end loop;

      return;
   exception
      when no_data_found then
         raise_application_error(
            -20001,
            'No basket data found'
         );
      when others then
         raise_application_error(
            -20002,
            'Error in GetTableInfo: ' || sqlerrm
         );
   end gettableinfo;

   procedure getgeneraltable (
      odata out sys_refcursor
   ) is
   begin
      open odata for select basket_name,
                            total_amount,
                            check_count
                                      from table ( pktest.gettableinfo )
                      order by basket_name;
   exception
      when others then
         if odata%isopen then
            close odata;
         end if;
         raise_application_error(
            -20003,
            'Error in GetGeneralTable: ' || sqlerrm
         );
   end getgeneraltable;

end pktest;
/

select *
  from table ( pktest.gettableinfo );

declare
   o_cursor       sys_refcursor;
   v_basket_name  varchar2(255);
   v_total_amount number;
   v_check_count  number;
begin
   pktest.getgeneraltable(o_cursor);
   dbms_output.put_line('--------------------------------------------------');
   dbms_output.put_line('                Basket Summary');
   dbms_output.put_line('--------------------------------------------------');
   loop
      fetch o_cursor into
         v_basket_name,
         v_total_amount,
         v_check_count;
      exit when o_cursor%notfound;
      dbms_output.put_line('Basket Name: ' || v_basket_name);
      dbms_output.put_line('Total Amount: ' || v_total_amount);
      dbms_output.put_line('Check Count: ' || v_check_count);
      dbms_output.put_line('--------------------------------------------------');
   end loop;
   close o_cursor;
end;
/