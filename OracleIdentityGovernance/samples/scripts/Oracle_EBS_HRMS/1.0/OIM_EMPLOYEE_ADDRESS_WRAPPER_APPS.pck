-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for CREATING synonym of procedures/packages and Tables required for HRMS
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

create or replace PACKAGE OIM_EMPLOYEE_ADDRESS_WRAPPER AUTHID CURRENT_USER AS

    PROCEDURE create_person_address_api (person_id IN number ,primary_flag IN varchar2 ,style IN varchar2 ,date_from IN date ,date_to IN date ,address_type IN varchar2 ,address_line1 IN varchar2 ,address_line2 IN varchar2 ,address_line3 IN varchar2 ,town_or_city IN varchar2 ,region_1 IN varchar2 ,region_2 IN varchar2 ,region_3 IN varchar2 ,postal_code IN varchar2 ,country IN varchar2 ,telephone_number_1 IN varchar2 ,telephone_number_2 IN varchar2 ,telephone_number_3 IN varchar2 ,address_id OUT number ,object_version_number OUT number );

    PROCEDURE update_person_address_api ( address_id IN number,person_id IN number ,primary_flag IN varchar2 ,style IN varchar2 ,date_from IN date ,date_to IN date ,address_type IN varchar2 ,address_line1 IN varchar2 ,address_line2 IN varchar2 ,address_line3 IN varchar2 ,town_or_city IN varchar2 ,region_1 IN varchar2 ,region_2 IN varchar2 ,region_3 IN varchar2 ,postal_code IN varchar2 ,country IN varchar2 ,telephone_number_1 IN varchar2 ,telephone_number_2 IN varchar2 ,telephone_number_3 IN varchar2);

    PROCEDURE delete_person_address_api ( address_id IN number,date_from IN date);

END OIM_EMPLOYEE_ADDRESS_WRAPPER;

 /
 
 create or replace PACKAGE BODY OIM_EMPLOYEE_ADDRESS_WRAPPER AS
 
 -------Procedure for create address for an employee --------
procedure create_person_address_api
(
      person_id                     IN     number,
      primary_flag                  IN     varchar2,
      style                         IN     varchar2,
      date_from                     IN     date,
      date_to                       IN     date,
      address_type                  IN     varchar2,
      address_line1                 IN     varchar2,
      address_line2                 IN     varchar2,
      address_line3                 IN     varchar2,
      town_or_city                  IN     varchar2,
      region_1                      IN     varchar2,
      region_2                      IN     varchar2,
      region_3                      IN     varchar2,
      postal_code                   IN     varchar2,
      country                       IN     varchar2,
      telephone_number_1            IN     varchar2,
      telephone_number_2            IN     varchar2,
      telephone_number_3            IN     varchar2,
      address_id                    OUT  number,
      object_version_number         OUT  number
)
is
BEGIN
    -- Start of API
    HR_PERSON_ADDRESS_API.CREATE_PERSON_ADDRESS(
            p_effective_date            => date_from,
            P_person_id                 => person_id,
            P_primary_flag              => primary_flag,
            P_style                     => style,
            P_date_from                 => date_from,
            P_date_to                   => date_to,
            P_ADDRESS_TYPE              => address_type,
            P_address_line1             => address_line1,
            P_address_line2             => address_line2,
            P_address_line3             => address_line3,
            P_town_or_city              => town_or_city,
            P_region_1                  => region_1,
            P_region_2                  => region_2,
            P_region_3                  => region_3,
            P_postal_code               => postal_code,
            P_country                   => country,
            P_telephone_number_1        => telephone_number_1,
            P_telephone_number_2        => telephone_number_2,
            P_telephone_number_3        => telephone_number_3,
            P_address_id                => address_id,
            P_object_version_number     => object_version_number
  );

  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line(SUBSTR(SQLERRM,1,200));
      raise;
END create_person_address_api ;

PROCEDURE update_person_address_api
(
  address_id                   IN     number,
  person_id                    IN number,
  primary_flag                 IN varchar2,
  style                        IN varchar2 ,
  date_from                    IN date ,
  date_to                      IN date ,
  address_type                 IN varchar2 ,
  address_line1                IN varchar2 ,
  address_line2                IN varchar2 ,
  address_line3                IN varchar2 ,
  town_or_city                 IN varchar2 ,
  region_1                     IN varchar2 ,
  region_2                     IN varchar2 ,
  region_3                     IN varchar2 ,
  postal_code                  IN varchar2 ,
  country                      IN varchar2 ,
  telephone_number_1           IN varchar2 ,
  telephone_number_2           IN varchar2 ,
  telephone_number_3           IN varchar2
)
IS
      l_object_version_number           per_addresses.object_version_number%type;

BEGIN
    SELECT MAX(object_version_number) into l_object_version_number  FROM PER_ADDRESSES WHERE address_id = update_person_address_api.address_id;

    -- Start of API
    HR_PERSON_ADDRESS_API.update_person_address(
        p_effective_date            => date_from,
        p_address_id                => address_id,
        p_object_version_number     => l_object_version_number,
        p_date_from                 => date_from,
        p_date_to                   =>  date_to,
        p_primary_flag              => primary_flag,
        p_address_type              => address_type,
        P_address_line1             => address_line1,
        p_address_line2             => address_line2,
        p_address_line3             => address_line3,
        p_town_or_city              => town_or_city,
        p_region_1                  => region_1,
        p_region_2                  => region_2,
        p_region_3                  => region_3,
        p_postal_code               => postal_code,
        p_country                   => country,
        p_telephone_number_1        => telephone_number_1,
        p_telephone_number_2        => telephone_number_2,
        p_telephone_number_3        => telephone_number_3
);

EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line(SUBSTR(SQLERRM,1,200));
      raise;
END update_person_address_api ;

PROCEDURE delete_person_address_api(address_id   IN     number,
                                    date_from IN date
)
IS
      l_date_to                         date;
      l_date_from                       date;
      l_object_version_number           per_addresses.object_version_number%type;

BEGIN
    SELECT MAX(PER_ADDRESSES.date_to) into l_date_to  FROM PER_ADDRESSES WHERE address_id = delete_person_address_api.address_id;
    --End Date is already set, ignore
    if l_date_to is null then
    
    l_date_to :=  SYSDATE;

    SELECT MAX(object_version_number) into l_object_version_number  FROM PER_ADDRESSES WHERE address_id = delete_person_address_api.address_id;
    IF date_from IS NOT NULL THEN
        l_date_from := date_from;
    ELSE
        SELECT MAX(PER_ADDRESSES.date_from) into l_date_from  FROM PER_ADDRESSES WHERE address_id = delete_person_address_api.address_id;
    end if;
    -- date_from should be always less than or equal to date_to
    if l_date_from > l_date_to then
        l_date_to := l_date_from;
    end if;
    -- Start of API
    HR_PERSON_ADDRESS_API.update_person_address(p_effective_date             => l_date_from,
                                                p_address_id                => address_id,
                                                p_date_from                 => l_date_from,
                                                p_date_to                    =>  l_date_to,
                                                p_object_version_number     => l_object_version_number);
    end if;
EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line(SUBSTR(SQLERRM,1,200));
      raise;
END delete_person_address_api ;

 
END OIM_EMPLOYEE_ADDRESS_WRAPPER;

/

