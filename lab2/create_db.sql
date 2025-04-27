-- Begin Oracle PL/SQL conversion
-- Create a sequence for identity columns
begin
   execute immediate 'DROP SEQUENCE temp_sales_seq';
exception
   when others then
      if sqlcode != -2289 then
         raise;
      end if;
end;
/

create sequence temp_sales_seq start with 1 increment by 1;

-- Drop tables if they exist
begin
   execute immediate 'DROP TABLE TempSales PURGE';
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
end;
/

begin
   execute immediate 'DROP TABLE TempBasketFilter PURGE';
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
end;
/

begin
   execute immediate 'DROP TABLE TempBasketHeader PURGE';
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
end;
/

-- Create tables
create global temporary table tempsales (
   checkid   varchar2(50),
   productid varchar2(50) not null,
   amount    number(10,3) not null,
   id        number default temp_sales_seq.nextval
) on commit preserve rows;

create global temporary table tempbasketheader (
   basketid   raw(16) not null,
   basketname varchar2(100) not null,
   constraint pk_tempbasketheader primary key ( basketname )
) on commit preserve rows;

create global temporary table tempbasketfilter (
   basketid       raw(16) not null,
   basketfilterid raw(16) default sys_guid() not null,
   productid      varchar2(50) not null,
   excludeflag    varchar2(1) default 'N' not null,
   constraint pk_tempbasketfilter primary key ( basketfilterid )
) on commit preserve rows;

-- Insert data into TempSales
begin
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
end;
/

-- Insert data into basket tables
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

-- Select data from tables
select *
  from tempsales;
select *
  from tempbasketheader;
select *
  from tempbasketfilter;