-- Create package specification
create or replace package pktest as
  -- Define record type for the result set
   type basket_record is record (
         basketname   varchar2(100),
         basketamount number,
         checksnumber number
   );
  
  -- Define table type based on the record
   type basket_table is
      table of basket_record;
  
  -- Pipelined function declaration
   function gettableinfo return basket_table
      pipelined;
  
  -- Procedure declaration
   procedure getgeneraltable (
      odata out sys_refcursor
   );
end pktest;
/

-- Create package body
create or replace package body pktest as
  -- Pipelined function implementation
   function gettableinfo return basket_table
      pipelined
   is
      rec basket_record;
    
    -- Cursor to get all basket results with their metrics
      cursor basket_results is
      with check_basket_match as (
         select distinct bh.basketname,
                         s.checkid,
                         case
            -- For empty basket (no filters), include all checks
                            when not exists (
                               select 1
                                 from tempbasketfilter bf
                                where bf.basketid = bh.basketid
                            ) then
                               1
            -- For baskets with filters, check if the check matches all filter conditions
                            when not exists (
                               select 1
                                 from tempbasketfilter bf
                                where bf.basketid = bh.basketid
                                  and (
                -- Check fails include condition (product should be present but isn't)
                                   ( bf.excludeflag = 'N'
                                  and not exists (
                                  select 1
                                    from tempsales s2
                                   where s2.checkid = s.checkid
                                     and s2.productid = bf.productid
                               ) )
                                   or
                -- Check fails exclude condition (product should be absent but is present)
                                    ( bf.excludeflag = 'Y'
                                  and exists (
                                  select 1
                                    from tempsales s2
                                   where s2.checkid = s.checkid
                                     and s2.productid = bf.productid
                               ) ) )
                            ) then
                               1
                            else
                               0
                         end as matches_basket
           from tempbasketheader bh
          cross join (
            select distinct checkid
              from tempsales
         ) s
      )
      select cbm.basketname,
             nvl(
                sum(s.amount),
                0
             ) as basketamount,
             count(distinct s.checkid) as checksnumber
        from check_basket_match cbm
        join tempsales s
      on cbm.checkid = s.checkid
       where cbm.matches_basket = 1
       group by cbm.basketname
       order by cbm.basketname;
   begin
    -- Loop through the cursor results and pipe each row
      for r in basket_results loop
         rec.basketname := r.basketname;
         rec.basketamount := r.basketamount;
         rec.checksnumber := r.checksnumber;
         pipe row ( rec );
      end loop;

      return;
   end gettableinfo;

  -- Procedure implementation
   procedure getgeneraltable (
      odata out sys_refcursor
   ) is
   begin
    -- Open the cursor with the same query result as the pipelined function
      open odata for select *
                       from table ( pktest.gettableinfo );
   end getgeneraltable;
end pktest;
/

-- Example usage:
-- 1. Using the pipelined function directly:
select *
  from table ( pktest.gettableinfo );

-- 2. Using the procedure:
declare
   v_cursor        sys_refcursor;
   v_basket_name   varchar2(100);
   v_basket_amount number;
   v_checks_number number;
begin
   pktest.getgeneraltable(v_cursor);
  
  -- Fetch and display results
   loop
      fetch v_cursor into
         v_basket_name,
         v_basket_amount,
         v_checks_number;
      exit when v_cursor%notfound;
      dbms_output.put_line('BasketName: '
                           || v_basket_name
                           || ', BasketAmount: '
                           || v_basket_amount
                           || ', ChecksNumber: '
                           || v_checks_number);
   end loop;

   close v_cursor;
end;
/


select *
  from tempsales;
select *
  from tempbasketheader;
select *
  from tempbasketfilter;