CREATE OR REPLACE EDITIONABLE PACKAGE "OLEKSA"."PKTEST" as
   function gettableinfo return basket_result_tab
      pipelined;

   procedure getgeneraltable (
      odata out sys_refcursor
   );

   e_no_data_found exception;
   pragma exception_init ( e_no_data_found,-20001 );
end pktest;
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "OLEKSA"."PKTEST" as
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