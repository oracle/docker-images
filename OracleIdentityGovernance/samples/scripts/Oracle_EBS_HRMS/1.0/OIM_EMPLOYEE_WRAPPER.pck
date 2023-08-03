-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for CREATING synonym of procedures/packages and Tables required for HRMS
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

create or replace PACKAGE OIM_EMPLOYEE_WRAPPER AS

 PROCEDURE create_person_api (hire_date IN date ,business_group_id IN number ,last_name IN varchar2 ,first_name IN varchar2 ,sex IN varchar2 ,person_type_id IN number ,
                           employee_number IN OUT nocopy varchar2 ,person_id OUT nocopy number ,title IN varchar2 ,email_address IN varchar2 ,marital_status IN varchar2 ,
                           nationality IN varchar2, national_identifier IN varchar2 ,date_of_birth IN date ,town_of_birth IN varchar2 ,region_of_birth IN varchar2 ,country_of_birth IN varchar2 );

 PROCEDURE update_person_api (person_id IN number ,last_name IN varchar2 DEFAULT NULL ,first_name IN varchar2 DEFAULT NULL ,sex IN varchar2 ,person_type_id IN number DEFAULT NULL,
                              hire_date IN date DEFAULT NULL ,business_group_id IN number ,employee_number IN OUT nocopy varchar2 ,object_version_number IN OUT nocopy number ,
                              title IN varchar2 ,email_address IN varchar2 ,marital_status IN varchar2 ,nationality IN varchar2 ,national_identifier IN varchar2 ,date_of_birth IN date ,
                              town_of_birth IN varchar2 ,region_of_birth IN varchar2 ,country_of_birth IN varchar2 );

 PROCEDURE delete_person_api ( person_id IN number );

 PROCEDURE terminate_person_api (person_id IN number );

 PROCEDURE rehire_ex_emp_api (person_id IN number ,hire_date IN date );

 PROCEDURE create_person_assignment_api ( person_id IN number, asg_effective_start_date IN date,  organization_id IN number, supervisor_id IN number, --assignment_number   IN OUT  varchar2,
                                       change_reason IN varchar2, job_id IN number, grade_id IN number, assignment_id OUT number);

 PROCEDURE delete_person_assignment_api(assignment_id IN number,asg_effective_start_date IN date);

 PROCEDURE update_person_assignment_api( person_id IN number, assignment_id  IN number,organization_id  IN number,job_id IN number,grade_id IN number,supervisor_id IN  number,change_reason  IN varchar2,asg_effective_start_date  IN date);

 END OIM_EMPLOYEE_WRAPPER;

 /

create or replace PACKAGE BODY OIM_EMPLOYEE_WRAPPER AS

procedure create_person_api(hire_date               IN  date,
                            business_group_id       IN  number,
                            last_name               IN  varchar2,
                            first_name              IN  varchar2,
                            sex                     IN  varchar2,
                            person_type_id          IN  number,
                            employee_number         IN  OUT nocopy varchar2,
                            person_id               OUT nocopy number,
                            title                   IN  varchar2,
                            email_address           IN  varchar2,
                            marital_status          IN  varchar2,
                            nationality             IN  varchar2,
                            national_identifier     IN  varchar2,
                            date_of_birth           IN  date,
                            town_of_birth           IN  varchar2,
                            region_of_birth         IN  varchar2,
                            country_of_birth        IN  varchar2 )
is
    -- Declare cursors and local variables
    l_full_name                    per_all_people_f.full_name%type;
    l_assignment_id                per_all_assignments_f.person_id%type;
    l_effective_start_date         per_all_people_f.effective_start_date%type;
    l_effective_end_date           per_all_people_f.effective_end_date%type;
    l_per_object_version_number    per_all_people_f.object_version_number%TYPE;
    l_asg_object_version_number    per_all_assignments_f.object_version_number%TYPE;
    l_comment_id                   per_all_people_f.comment_id%type;
    l_assignment_sequence          per_all_assignments_f.assignment_sequence%type;
    l_assignment_number            per_all_assignments_f.assignment_number%type;
    l_name_combination_warning     boolean;
    l_assign_payroll_warning       boolean;
    l_orig_hire_warning            boolean;
    sys_person_type                per_person_types.system_person_type%type;
    l_pdp_object_version_number    NUMBER;

BEGIN
    -- Start of API
    select system_person_type into sys_person_type from per_person_types where person_type_id=create_person_api.person_type_id;
    if sys_person_type = 'EMP' then
 
         HR_EMPLOYEE_API.create_employee(p_hire_date                    => hire_date,
                                         p_business_group_id            => business_group_id,
                                         p_last_name                    => last_name,
                                         p_first_name                   => first_name,
                                         p_sex                          => sex,
                                         p_person_type_id               => person_type_id,
                                         p_employee_number              => employee_number,
                                         p_person_id                    => person_id,
                                         p_full_name                    => l_full_name,
                                         p_assignment_id                => l_assignment_id,
                                         p_assignment_sequence          => l_assignment_sequence,
                                         p_assignment_number            => l_assignment_number,
                                         p_per_object_version_number    => l_per_object_version_number,
                                         p_asg_object_version_number    => l_asg_object_version_number,
                                         p_per_effective_start_date     => l_effective_start_date,
                                         p_per_effective_end_date       => l_effective_end_date,
                                         p_per_comment_id               => l_comment_id,
                                         p_name_combination_warning     => l_name_combination_warning,
                                         p_assign_payroll_warning       => l_assign_payroll_warning,
                                         p_orig_hire_warning            => l_orig_hire_warning,
                                         p_title                        => title,
                                         p_email_address                => email_address,
                                         p_marital_status               => marital_status,
                                         p_nationality                  => nationality,
                                         p_national_identifier          => national_identifier,
                                         p_date_of_birth                => date_of_birth,
                                         p_town_of_birth                => town_of_birth,
                                         p_region_of_birth              => region_of_birth,
                                         p_country_of_birth             => country_of_birth
        
                );
    elsif sys_person_type = 'CWK' then

            HR_CONTINGENT_WORKER_API.create_cwk(p_validate                      => FALSE,
                                                p_start_date                   => hire_date,
                                                p_business_group_id            => business_group_id,
                                                p_last_name                    => last_name,
                                                p_first_name                   => first_name,
                                                p_sex                          => sex,
                                                p_person_type_id               => person_type_id,
                                                p_npw_number                   => employee_number,
                                                p_person_id                    => person_id,
                                                p_per_object_version_number    => l_per_object_version_number,
                                                p_per_effective_start_date     => l_effective_start_date,
                                                p_per_effective_end_date       => l_effective_end_date,
                                                p_pdp_object_version_number    => l_pdp_object_version_number,
                                                p_full_name                    => l_full_name,
                                                p_comment_id                   => l_comment_id,
                                                p_assignment_id                => l_assignment_id,
                                                p_asg_object_version_number    => l_asg_object_version_number,
                                                p_assignment_sequence          => l_assignment_sequence,
                                                p_assignment_number            => l_assignment_number,
                                                p_name_combination_warning     => l_name_combination_warning,
                                                p_title                        => title,
                                                p_email_address                => email_address,
                                                p_marital_status               => marital_status,
                                                p_nationality                  => nationality,
                                                p_national_identifier          => national_identifier,
                                                p_date_of_birth                => date_of_birth,
                                                p_town_of_birth                => town_of_birth,
                                                p_region_of_birth              => region_of_birth,
                                                p_country_of_birth             => country_of_birth
                                                );
    else
      raise_application_error (-20001, 'Invalid person type');
    end if;

EXCEPTION
 WHEN OTHERS THEN
      dbms_output.put_line(SUBSTR(SQLERRM,1,100));
      raise;
END create_person_api;

-------Procedure for updating an employee record--------
procedure update_person_api( person_id              IN number, 
                             last_name              IN varchar2 default null, 
                             first_name             IN varchar2 default null, 
                             sex                    IN varchar2, 
                             person_type_id         IN number   default null, 
                             hire_date              IN date     default null, 
                             business_group_id      IN number, 
                             employee_number        IN OUT nocopy varchar2, 
                             object_version_number  IN OUT nocopy  number, 
                             title                  IN varchar2, 
                             email_address          IN varchar2, 
                             marital_status         IN varchar2, 
                             nationality            IN varchar2, 
                             national_identifier    IN varchar2, 
                             date_of_birth          IN date, 
                             town_of_birth          IN varchar2, 
                             region_of_birth        IN varchar2, 
                             country_of_birth       IN varchar2)
is
    -- Declare cursors and local variables
    l_effective_date               date := TRUNC(sysdate);
    l_object_version_number        per_all_people_f.object_version_number%type;
    l_employee_number              per_all_people_f.employee_number%type;
    l_npw_number                   per_all_people_f.npw_number%type;
    l_emp_start_date               per_all_people_f.effective_start_date%type;
    l_cwk_start_date               per_all_people_f.start_date%type;
    l_datetrack_update_mode        varchar2(10);
    l_effective_start_date         date;
    l_effective_end_date           date;
    l_full_name                    per_all_people_f.full_name%type;
    l_comment_id                   per_all_people_f.comment_id%type;
    l_name_combination_warning     boolean;
    l_assign_payroll_warning       boolean;
    l_orig_hire_warning            boolean;
    l_hire_date                    date;
    p_update_type                  varchar(10);
    p_old_start_date               date;
    l_Err_Msg                      varchar(1000);
    sys_person_type                per_person_types.system_person_type%type;
    
    ----
    cursor cur_emp_ovn is
        select employee_number, npw_number,object_version_number, effective_start_date
        from   per_all_people_f
        where  person_id = update_person_api.person_id
        and    business_group_id = update_person_api.business_group_id
        and   ((effective_start_date > trunc(sysdate)) OR trunc(sysdate) between effective_start_date and effective_end_date);
BEGIN

      ---Initialise local variables before call to hr_person_api.update_person
      for rec IN cur_emp_ovn
      loop
          l_employee_number       := rec.employee_number;
          l_emp_start_date        := rec.effective_start_Date;
          l_npw_number            := rec.npw_number;
    
    
      end loop;
      l_datetrack_update_mode := 'CORRECTION';
      select system_person_type into sys_person_type from per_person_types where person_type_id=update_person_api.person_type_id;
      if sys_person_type = 'EMP' then
          l_hire_date         :=hire_date;
          p_update_type       := 'E';
      elsif sys_person_type = 'CWK' then
          l_npw_number           := employee_number;
          employee_number        := null;
          l_hire_date            := null;     
          p_update_type          := 'C';
      end if;
      if l_emp_start_date <> hire_date then
        HR_CHANGE_START_DATE_API.Update_Start_Date(p_validate         => FALSE,
                                                   p_person_id        => person_id,
                                                   p_old_start_date   => l_emp_start_date,
                                                   p_new_start_date   => hire_date,
                                                   p_update_type      => p_update_type,
                                                   p_applicant_number => NULL,
                                                   p_warn_ee          => l_Err_Msg );
      end if;
    
      for rec IN cur_emp_ovn
      loop
          l_object_version_number := rec.object_version_number;
          l_effective_date        := rec.effective_start_Date;
      end loop;
    
      -- Start of API
      HR_PERSON_API.update_person(p_effective_date              => l_effective_date, 
                                p_datetrack_update_mode         => l_datetrack_update_mode, 
                                p_person_id                     => person_id, 
                                p_last_name                     => last_name, 
                                p_first_name                    => first_name, 
                                p_sex                           => sex, 
                                p_person_type_id                => person_type_id, 
                                p_original_date_of_hire         => l_hire_date, 
                                p_employee_number               => employee_number, 
                                p_npw_number                    => l_npw_number, 
                                p_object_version_number         => l_object_version_number, 
                                p_effective_start_date          => l_effective_start_date, 
                                p_effective_end_date            => l_effective_end_date, 
                                p_full_name                     => l_full_name, 
                                p_comment_id                    => l_comment_id, 
                                p_name_combination_warning      => l_name_combination_warning, 
                                p_assign_payroll_warning        => l_assign_payroll_warning, 
                                p_orig_hire_warning             => l_orig_hire_warning, 
                                p_title                         => title, 
                                p_email_address                 => email_address, 
                                p_marital_status                => marital_status, 
                                p_nationality                   => nationality, 
                                p_national_identifier           => national_identifier, 
                                p_date_of_birth                 => date_of_birth, 
                                p_town_of_birth                 => town_of_birth, 
                                p_region_of_birth               => region_of_birth, 
                                p_country_of_birth              => country_of_birth);
         
    EXCEPTION
     WHEN OTHERS THEN
          dbms_output.put_line(SUBSTR(SQLERRM,1,200));
          raise;
END update_person_api ;


-------Procedure for deleting an employee record--------
procedure delete_person_api(person_id                IN number)
is
    -- Declare cursors and local variables
    l_validate                     boolean;
    l_effective_date               date;
    l_perform_predel_validation    boolean;
    l_person_org_manager_warning   varchar2(10);
BEGIN
    ---Initialise local variables before call to hr_person_api.delete_person
    l_validate := FALSE;
    l_effective_date := TRUNC(sysdate);
    l_perform_predel_validation := FALSE;

    -- Start of API
    HR_PERSON_API.delete_person(p_validate                          => l_validate,
                                p_effective_date                    => l_effective_date,
                                p_person_id                         => person_id,
                                p_perform_predel_validation         => l_perform_predel_validation,
                                p_person_org_manager_warning        => l_person_org_manager_warning
                                );

    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SUBSTR(SQLERRM,1,200));
            raise;
END delete_person_api ;

-------Procedure for terminating an employee --------
------ Private method to terminate contingent worker. This has to be defined before caller method
procedure terminate_cwk_api (person_id IN number)
is
   l_terminate_cwk_flag          varchar2(1) := 'N';
   l_terminate_msg               varchar2(600);
   l_le_terminate_cwk_exception  exception;
   l_effective_date              date := trunc(sysdate);
   l_termination_reason          per_periods_of_placement.termination_reason%type;
   l_person_type_id              per_person_types.person_type_id%type;
   l_period_of_service_id        per_periods_of_placement.period_of_placement_id%type;
   l_actual_termination_date     per_periods_of_placement.actual_termination_date%type :=trunc(sysdate);
   l_last_standard_process_date  per_periods_of_placement.last_standard_process_date%type := trunc(sysdate);
   l_object_version_number       per_periods_of_placement.object_version_number%type;
   l_start_date                  per_periods_of_placement.date_start%type;
   l_notif_term_date             date;
   l_final_process_date          per_periods_of_service.final_process_date%type;
   l_supervisor_warning          boolean := false;
   l_event_warning               boolean := false;
   l_interview_warning           boolean := false;
   l_review_warning              boolean := false;
   l_recruiter_warning           boolean := false;
   l_asg_future_changes_warning  boolean := false;
   l_entries_changed_warning     varchar2(300);
   l_pay_proposal_warning        boolean := false;
   l_dod_warning                 boolean := false;
   l_org_now_no_manager_warning  boolean := false;
begin
   begin
       select pos.period_of_placement_id, pos.object_version_number, date_start into l_period_of_service_id, l_object_version_number, l_start_date
       from per_periods_of_placement pos
       where pos.person_id = terminate_cwk_api.person_id;
     
       exception                                                        
          when others then
             l_terminate_msg  := 'Error while selecting cwk details : '||substr(sqlerrm,1,150);
             raise l_le_terminate_cwk_exception;
   end;
   
   begin
        HR_CONTINGENT_WORKER_API.actual_termination_placement(p_validate                      => false, 
                                                              p_effective_date                => l_effective_date, 
                                                              p_person_id                     => person_id, 
                                                              p_date_start                    => l_start_date, 
                                                              p_person_type_id                => l_person_type_id, 
                                                              p_actual_termination_date       => l_actual_termination_date, 
                                                              p_termination_reason            => l_termination_reason, 
                                                              p_object_version_number         => l_object_version_number, 
                                                              p_last_standard_process_date    => l_last_standard_process_date, 
                                                              p_supervisor_warning            => l_supervisor_warning, 
                                                              p_event_warning                 => l_event_warning, 
                                                              p_interview_warning             => l_interview_warning, 
                                                              p_review_warning                => l_review_warning, 
                                                              p_recruiter_warning             => l_recruiter_warning, 
                                                              p_asg_future_changes_warning    => l_asg_future_changes_warning, 
                                                              p_entries_changed_warning       => l_entries_changed_warning, 
                                                              p_pay_proposal_warning          => l_pay_proposal_warning, 
                                                              p_dod_warning                   => l_dod_warning
                                                              );

        if l_object_version_number is null then
             l_terminate_cwk_flag := 'N';
             l_terminate_msg      := 'Warning validating API: hr_contingent_worker_api.actual_termination_placement';
             raise l_le_terminate_cwk_exception;
        end if;

        l_terminate_cwk_flag := 'Y';
        exception
             when others then
             l_terminate_msg  := 'Error validating API: hr_contingent_worker_api.actual_termination_placement : '||substr(sqlerrm,1,150);
             raise l_le_terminate_cwk_exception;
    end;

    if l_terminate_cwk_flag = 'Y' then
    begin
         HR_CONTINGENT_WORKER_API.final_process_placement (p_validate                    => false,
                                                           p_person_id                   => person_id,
                                                           p_date_start                  => l_start_date,
                                                           p_object_version_number       => l_object_version_number,
                                                           p_final_process_date          => l_final_process_date,
                                                           p_org_now_no_manager_warning  => l_org_now_no_manager_warning,
                                                           p_asg_future_changes_warning  => l_asg_future_changes_warning,
                                                           p_entries_changed_warning     => l_entries_changed_warning );
        exception
        when others then
            l_terminate_msg := 'Error validating API: hr_contingent_worker_api.final_process_placement : '||substr(sqlerrm,1,150);
            raise l_le_terminate_cwk_exception;
    end;
    end if;   
        
end terminate_cwk_api;


-------Procedure for terminating an employee --------
procedure terminate_person_api (person_id IN number)
is
    -- Declare cursors and local variables
    l_object_version_number      number;
    l_period_of_service_id       number;
    l_validate                   boolean;
    l_supervisor_warning         boolean;
    l_event_warning              boolean;
    l_interview_warning          boolean;
    l_review_warning             boolean;
    l_recruiter_warning          boolean;
    l_asg_future_changes_warning boolean;
    l_entries_changed_warning    varchar2(30);
    l_leaving_reasons            varchar2(30);
    l_org_now_no_manager_warning boolean;
    l_pay_proposal_warning       boolean;
    l_dod_warning                boolean;
    l_last_working_date          date;
    l_actual_notice_period_date  date;
    l_effective_date             date;
    l_person_type_id             number;
    l_assignment_status_type_id  number;
    sys_person_type              per_person_types.system_person_type%type;
    
BEGIN
    
    select system_person_type  into sys_person_type from per_person_types where person_type_id = (select person_type_id from PER_PERSON_TYPE_USAGES_F where person_id=terminate_person_api.person_id);
    if sys_person_type = 'EMP' then
    
        ---Initialise local variables before call to hr_ex_employee_api.actual_termination_emp
        l_last_working_date := TRUNC(sysdate);
        l_actual_notice_period_date := TRUNC(sysdate);
        l_effective_date := TRUNC(sysdate);
        l_validate := FALSE;
        
        SELECT pps.period_of_service_id, pps.object_version_number  INTO l_period_of_service_id,l_object_version_number
        FROM per_periods_of_service pps WHERE pps.person_id = terminate_person_api.person_id AND pps.actual_termination_date is NULL;
        
        HR_EX_EMPLOYEE_API.actual_termination_emp( p_validate             => l_validate, 
                                           p_effective_date               => l_effective_date, 
                                           p_period_of_service_id         => l_period_of_service_id, 
                                           p_object_version_number        => l_object_version_number, 
                                           p_actual_termination_date      => l_actual_notice_period_date, 
                                           p_last_standard_process_date   => l_last_working_date, 
                                           p_person_type_id               => l_person_type_id, 
                                           p_assignment_status_type_id    => l_assignment_status_type_id, 
                                           p_leaving_reason               => l_leaving_reasons, 
                                           p_supervisor_warning           => l_supervisor_warning, 
                                           p_event_warning                => l_event_warning, 
                                           p_interview_warning            => l_interview_warning, 
                                           p_review_warning               => l_review_warning, 
                                           p_recruiter_warning            => l_recruiter_warning, 
                                           p_asg_future_changes_warning   => l_asg_future_changes_warning, 
                                           p_entries_changed_warning      => l_entries_changed_warning, 
                                           p_pay_proposal_warning         => l_pay_proposal_warning, 
                                           p_dod_warning                  => l_dod_warning);

        HR_EX_EMPLOYEE_API.final_process_emp( p_validate                     => l_validate, 
                                              p_period_of_service_id         => l_period_of_service_id, 
                                              p_object_version_number        => l_object_version_number, 
                                              p_final_process_date           => l_last_working_date, 
                                              p_org_now_no_manager_warning   => l_org_now_no_manager_warning, 
                                              p_asg_future_changes_warning   => l_asg_future_changes_warning, 
                                              p_entries_changed_warning      => l_entries_changed_warning);
        
        elsif sys_person_type = 'CWK' then
            terminate_cwk_api(person_id);
    end if;  

    EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line(SUBSTR(SQLERRM,1,200));
        raise;
END terminate_person_api;

-------Procedure for re-hiring an ex-employee --------
procedure rehire_ex_emp_api(person_id                IN number,
                            hire_date                IN date)
is
    -- Declare cursors and local variables
    l_validate                     boolean;
    l_per_object_version_number    number;
    l_person_type_id               number;
    l_rehire_reason                varchar2(10);
    l_assignment_id                number;
    l_asg_object_version_number    number;
    l_hire_date                    date;
    l_per_effective_start_date     date;
    l_per_effective_end_date       date;
    l_assignment_sequence          number;
    l_assignment_number            varchar2(10);
    l_assign_payroll_warning       boolean;
BEGIN
    ---Initialise local variables before call to hr_employee_api.re_hire_ex_employee
    l_validate := FALSE;
    SELECT MAX(object_version_number) into l_per_object_version_number FROM per_all_people_f WHERE person_id = rehire_ex_emp_api.person_id;
    -- Start of API
    HR_EMPLOYEE_API.re_hire_ex_employee( p_validate                          => l_validate, 
                                         p_hire_date                         => hire_date, 
                                         p_person_id                         => person_id, 
                                         p_per_object_version_number         => l_per_object_version_number, 
                                         p_person_type_id                    => l_person_type_id, 
                                         p_rehire_reason                     => l_rehire_reason, 
                                         p_assignment_id                     => l_assignment_id, 
                                         p_asg_object_version_number         => l_asg_object_version_number, 
                                         p_per_effective_start_date          => l_per_effective_start_date, 
                                         p_per_effective_end_date            => l_per_effective_end_date, 
                                         p_assignment_sequence               => l_assignment_sequence, 
                                         p_assignment_number                 => l_assignment_number, 
                                         p_assign_payroll_warning            => l_assign_payroll_warning);

    EXCEPTION 
    WHEN OTHERS THEN
          dbms_output.put_line(SUBSTR(SQLERRM,1,200));
          raise;
END rehire_ex_emp_api;

procedure create_cwk_assignment( asg_effective_start_date      in date,
                                 person_id           in number,
                                 organization_id     in number,
                                 supervisor_id       in number,
                                 change_reason       in varchar2,
                                 job_id              in number,
                                 grade_id            in number,
                                 assignment_id       out  number) 
IS
     l_assignment_number             varchar2(2000);
     l_assignment_category           varchar2(2000);
     l_assignment_status_type_id     number;
     l_comments                      varchar2(2000);
     l_default_code_comb_id          number;
     l_establishment_id              number;
     l_frequency                     varchar2(2000);
     l_internal_address_line         varchar2(2000);
     l_labour_union_member_flag      varchar2(2000);
     l_location_id                   number;
     l_manager_flag                  varchar2(2000);
     l_normal_hours                  number;
     l_position_id                   number;
     l_project_title                 varchar2(2000);
     l_set_of_books_id               number;
     l_source_type                   varchar2(2000);
     l_time_normal_finish            varchar2(2000);
     l_time_normal_start             varchar2(2000);
     l_title                         varchar2(2000);
     l_vendor_assignment_number      varchar2(2000);
     l_vendor_employee_number        varchar2(2000);
     l_vendor_id                     number;
     l_vendor_site_id                number;
     l_po_header_id                  number;
     l_po_line_id                    number;
     l_projected_assignment_end      date;
     l_attribute_category            varchar2(2000);
     l_scl_concat_segments           varchar2(2000);
     l_pgp_concat_segments           varchar2(2000);
     l_supervisor_assignment_id      number;
     -- output variables
     l_object_version_number         number;
     l_effective_start_date          date;
     l_effective_end_date            date;
     l_assignment_sequence           number;
     l_comment_id                    number;
     l_people_group_id               number;
     l_people_group_name             varchar2(2000);
     l_other_manager_warning         boolean;
     l_hourly_salaried_warning       boolean;
     l_soft_coding_keyflex_id        number;
BEGIN
     --  Calling API HR_ASSIGNMENT_API.create_secondary_cwk_asg
     HR_ASSIGNMENT_API.create_secondary_cwk_asg(p_validate                     => false
                                               ,p_effective_date               => asg_effective_start_date
                                               ,p_business_group_id            => organization_id
                                               ,p_person_id                    => person_id
                                               ,p_organization_id              => organization_id
                                               ,p_assignment_number            => l_assignment_number
                                               ,p_assignment_category          => l_assignment_category
                                               ,p_assignment_status_type_id    => l_assignment_status_type_id
                                               ,p_change_reason                => change_reason
                                               ,p_comments                     => l_comments
                                               ,p_default_code_comb_id         => l_default_code_comb_id
                                               ,p_establishment_id             => l_establishment_id
                                               ,p_frequency                    => l_frequency
                                               ,p_internal_address_line        => l_internal_address_line
                                               ,p_job_id                       => job_id
                                               ,p_labour_union_member_flag     => l_labour_union_member_flag
                                               ,p_location_id                  => l_location_id
                                               ,p_manager_flag                 => l_manager_flag
                                               ,p_normal_hours                 => l_normal_hours
                                               ,p_position_id                  => l_position_id
                                               ,p_grade_id                     => grade_id
                                               ,p_project_title                => l_project_title
                                               ,p_set_of_books_id              => l_set_of_books_id
                                               ,p_source_type                  => l_source_type
                                               ,p_supervisor_id                => supervisor_id
                                               ,p_time_normal_finish           => l_time_normal_finish
                                               ,p_time_normal_start            => l_time_normal_start
                                               ,p_title                        => l_title
                                               ,p_vendor_assignment_number     => l_vendor_assignment_number
                                               ,p_vendor_employee_number       => l_vendor_employee_number
                                               ,p_vendor_id                    => l_vendor_id
                                               ,p_vendor_site_id               => l_vendor_site_id
                                               ,p_po_header_id                 => l_po_header_id
                                               ,p_po_line_id                   => l_po_line_id
                                               ,p_projected_assignment_end     => l_projected_assignment_end
                                               ,p_attribute_category           => l_attribute_category
                                               ,p_attribute1                   => null
                                               ,p_attribute2                   => null
                                               ,p_attribute3                   => null
                                               ,p_attribute4                   => null
                                               ,p_attribute5                   => null
                                               ,p_attribute6                   => null
                                               ,p_attribute7                   => null
                                               ,p_attribute8                   => null
                                               ,p_attribute9                   => null
                                               ,p_attribute10                  => null
                                               ,p_attribute11                  => null
                                               ,p_attribute12                  => null
                                               ,p_attribute13                  => null
                                               ,p_attribute14                  => null
                                               ,p_attribute15                  => null
                                               ,p_attribute16                  => null
                                               ,p_attribute17                  => null
                                               ,p_attribute18                  => null
                                               ,p_attribute19                  => null
                                               ,p_attribute20                  => null
                                               ,p_attribute21                  => null
                                               ,p_attribute22                  => null
                                               ,p_attribute23                  => null
                                               ,p_attribute24                  => null
                                               ,p_attribute25                  => null
                                               ,p_attribute26                  => null
                                               ,p_attribute27                  => null
                                               ,p_attribute28                  => null
                                               ,p_attribute29                  => null
                                               ,p_attribute30                  => null
                                               ,p_pgp_segment1                 => null
                                               ,p_pgp_segment2                 => null
                                               ,p_pgp_segment3                 => null
                                               ,p_pgp_segment4                 => null
                                               ,p_pgp_segment5                 => null
                                               ,p_pgp_segment6                 => null
                                               ,p_pgp_segment7                 => null
                                               ,p_pgp_segment8                 => null
                                               ,p_pgp_segment9                 => null
                                               ,p_pgp_segment10                => null
                                               ,p_pgp_segment11                => null
                                               ,p_pgp_segment12                => null
                                               ,p_pgp_segment13                => null
                                               ,p_pgp_segment14                => null
                                               ,p_pgp_segment15                => null
                                               ,p_pgp_segment16                => null
                                               ,p_pgp_segment17                => null
                                               ,p_pgp_segment18                => null
                                               ,p_pgp_segment19                => null
                                               ,p_pgp_segment20                => null
                                               ,p_pgp_segment21                => null
                                               ,p_pgp_segment22                => null
                                               ,p_pgp_segment23                => null
                                               ,p_pgp_segment24                => null
                                               ,p_pgp_segment25                => null
                                               ,p_pgp_segment26                => null
                                               ,p_pgp_segment27                => null
                                               ,p_pgp_segment28                => null
                                               ,p_pgp_segment29                => null
                                               ,p_pgp_segment30                => null
                                               ,p_scl_segment1                 => null
                                               ,p_scl_segment2                 => null
                                               ,p_scl_segment3                 => null
                                               ,p_scl_segment4                 => null
                                               ,p_scl_segment5                 => null
                                               ,p_scl_segment6                 => null
                                               ,p_scl_segment7                 => null
                                               ,p_scl_segment8                 => null
                                               ,p_scl_segment9                 => null
                                               ,p_scl_segment10                => null
                                               ,p_scl_segment11                => null
                                               ,p_scl_segment12                => null
                                               ,p_scl_segment13                => null
                                               ,p_scl_segment14                => null
                                               ,p_scl_segment15                => null
                                               ,p_scl_segment16                => null
                                               ,p_scl_segment17                => null
                                               ,p_scl_segment18                => null
                                               ,p_scl_segment19                => null
                                               ,p_scl_segment20                => null
                                               ,p_scl_segment21                => null
                                               ,p_scl_segment22                => null
                                               ,p_scl_segment23                => null
                                               ,p_scl_segment24                => null
                                               ,p_scl_segment25                => null
                                               ,p_scl_segment26                => null
                                               ,p_scl_segment27                => null
                                               ,p_scl_segment28                => null
                                               ,p_scl_segment29                => null
                                               ,p_scl_segment30                => null
                                               ,p_scl_concat_segments          => l_scl_concat_segments
                                               ,p_pgp_concat_segments          => l_pgp_concat_segments
                                               ,p_supervisor_assignment_id     => l_supervisor_assignment_id
                                               ,p_assignment_id                => assignment_id
                                               ,p_object_version_number        => l_object_version_number
                                               ,p_effective_start_date         => l_effective_start_date
                                               ,p_effective_end_date           => l_effective_end_date
                                               ,p_assignment_sequence          => l_assignment_sequence
                                               ,p_comment_id                   => l_comment_id
                                               ,p_people_group_id              => l_people_group_id
                                               ,p_people_group_name            => l_people_group_name
                                               ,p_other_manager_warning        => l_other_manager_warning
                                               ,p_hourly_salaried_warning      => l_hourly_salaried_warning
                                               ,p_soft_coding_keyflex_id       => l_soft_coding_keyflex_id);
    exception when others then
        dbms_output.put_line('error : ' || sqlerrm);
        raise;
END create_cwk_assignment;


-------Procedure for assign an assignment to employee --------
PROCEDURE create_person_assignment_api( person_id                IN number,
                                        asg_effective_start_date IN date,
                                        organization_id          IN number,
                                        supervisor_id            IN number,
                                        change_reason            IN varchar2,
                                        job_id                   IN number,
                                        grade_id                 IN number,
                                        assignment_id            OUT  number)
IS
      l_concatenated_segments            hr_soft_coding_keyflex.concatenated_segments%type;
      l_cagr_con_segments                varchar2(2000);
      l_group_name                       pay_people_groups.group_name%type;
      l_object_version_number            per_all_assignments_f.object_version_number%type;
      l_assignment_number                per_all_assignments_f.assignment_number%TYPE;
      l_effective_start_date             per_all_assignments_f.effective_start_date%type;
      l_effective_end_date               per_all_assignments_f.effective_end_date%type;
      l_assignment_sequence              per_all_assignments_f.assignment_sequence%type;
      l_comment_id                       per_all_assignments_f.comment_id%type;
      l_other_manager_warning            boolean;
      l_hourly_salaried_warning          boolean;
      l_gsp_post_process_warning         varchar2(2000);
      l_validate                         boolean;
      l_cagr_grade_def_id                per_cagr_grades_def.cagr_grade_def_id%type;
      l_soft_coding_keyflex_id           per_all_assignments_f.soft_coding_keyflex_id%type;
      l_people_group_id                  number;
      l_location_id                      number;
      l_asg_primary_eff_start_date       date;
      l_asg_primary_eff_end_date         date;
      l_asg_primary_obj_version          number;
      l_asg_primary_id                   number;
      validcount                         number;
      valid_job_count                    number;
      sys_person_type                    per_person_types.system_person_type%type;
BEGIN

      select location_id into l_location_id from HR_ALL_ORGANIZATION_UNITS where location_id is not null and organization_id = create_person_assignment_api.organization_id;
    
      IF create_person_assignment_api.grade_id IS NOT NULL THEN
          select count(*) into validcount from PER_VALID_GRADES where business_group_id =create_person_assignment_api.organization_id 
          and job_id=create_person_assignment_api.job_id and grade_id=create_person_assignment_api.grade_id;
          if validcount = 0 then
            raise_application_error (-20001, 'Invalid combination of organization, job and grade');
          end if;
      ELSE
          select count(*) into valid_job_count from PER_JOBS where job_id = create_person_assignment_api.job_id;
          if valid_job_count = 0 then
             raise_application_error (-20001, 'Invalid combination of organization, job and grade');
            end if;
      END IF;
      
      select system_person_type  into sys_person_type from per_person_types where person_type_id = (select person_type_id from PER_PERSON_TYPE_USAGES_F where person_id=create_person_assignment_api.person_id);
      if sys_person_type = 'EMP' then
      -- Start of API
      -- CREATING SECONDARY ASSIGNMENT WHICH IS NOT A PRIMARY YET
      HR_ASSIGNMENT_API.create_secondary_emp_asg(p_effective_date             => asg_effective_start_date, 
                                                p_person_id                   => person_id, 
                                                p_organization_id             => organization_id, 
                                                p_supervisor_id               => supervisor_id, 
                                                p_assignment_number           => l_assignment_number, 
                                                p_change_reason               => change_reason, 
                                                p_location_id                 => l_location_id, 
                                                p_group_name                  => l_group_name, 
                                                p_job_id                      => job_id, 
                                                p_grade_id                    => grade_id, 
                                                p_concatenated_segments       => l_concatenated_segments, 
                                                p_cagr_grade_def_id           => l_cagr_grade_def_id, 
                                                p_cagr_concatenated_segments  => l_cagr_con_segments, 
                                                p_assignment_id               => assignment_id, 
                                                p_soft_coding_keyflex_id      => l_soft_coding_keyflex_id, 
                                                p_object_version_number       => l_object_version_number, 
                                                p_effective_start_date        => l_effective_start_date, 
                                                p_effective_end_date          => l_effective_end_date, 
                                                p_assignment_sequence         => l_assignment_sequence, 
                                                p_comment_id                  => l_comment_id, 
                                                p_other_manager_warning       => l_other_manager_warning, 
                                                p_hourly_salaried_warning     => l_hourly_salaried_warning, 
                                                p_gsp_post_process_warning    => l_gsp_post_process_warning, 
                                                p_people_group_id             => l_people_group_id);
       
      elsif sys_person_type = 'CWK' then
            if grade_id is not null then
                raise_application_error (-20001, 'Grade Id is can not be assigned to Contingent Worker');
            end if;
            create_cwk_assignment(asg_effective_start_date,person_id,organization_id,supervisor_id,change_reason,job_id,grade_id,assignment_id);
      end if;

      EXCEPTION
      WHEN OTHERS THEN
          dbms_output.put_line(SUBSTR(SQLERRM,1,200));
          raise;
END create_person_assignment_api ;

-------Procedure for delete assignment of employee --------
procedure delete_person_assignment_api(assignment_id              IN number,
                                       asg_effective_start_date   IN date)
is
    l_validate                        boolean;
    l_datetrack_mode                  VARCHAR2(100);
    l_effective_date                  date;
    l_object_version_number           number;
    l_effective_start_date            per_all_assignments_f.effective_start_date%type;
    l_effective_end_date              per_all_assignments_f.effective_end_date%type;
    l_loc_change_tax_issues           boolean;
    l_delete_asg_budgets              boolean;
    l_org_now_no_manager_warning      boolean;
    l_element_salary_warning          boolean;
    l_element_entries_warning         boolean;
    l_spp_warning                     boolean;
    l_cost_warning                    boolean;
    l_life_events_exists              boolean;
    l_cobra_coverage_elements         boolean;
    l_assgt_term_elements             boolean;

begin

    l_validate := false;
    l_datetrack_mode := 'ZAP';
    l_effective_date := asg_effective_start_date;

    SELECT MAX(object_version_number) into l_object_version_number FROM PER_ALL_ASSIGNMENTS_F WHERE assignment_id = delete_person_assignment_api.assignment_id;
    if l_effective_date is null then
        select EFFECTIVE_START_DATE into l_effective_date from PER_ALL_ASSIGNMENTS_F where assignment_id = delete_person_assignment_api.assignment_id and job_id is not null AND ((EFFECTIVE_START_DATE >= TRUNC(sysdate)) OR (TRUNC(sysdate) BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE) );
    end if;
    -- start of api
    HR_ASSIGNMENT_API.delete_assignment( p_validate                => l_validate, 
                                      p_effective_date             => l_effective_date, 
                                      p_datetrack_mode             => l_datetrack_mode, 
                                      p_assignment_id              => assignment_id, 
                                      p_object_version_number      => l_object_version_number, 
                                      p_effective_start_date       => l_effective_start_date, 
                                      p_effective_end_date         => l_effective_end_date, 
                                      p_loc_change_tax_issues      => l_loc_change_tax_issues, 
                                      p_delete_asg_budgets         => l_delete_asg_budgets, 
                                      p_org_now_no_manager_warning => l_org_now_no_manager_warning, 
                                      p_element_salary_warning     => l_element_salary_warning, 
                                      p_element_entries_warning    => l_element_entries_warning, 
                                      p_spp_warning                => l_spp_warning, 
                                      p_cost_warning               => l_cost_warning, 
                                      p_life_events_exists         => l_life_events_exists, 
                                      p_cobra_coverage_elements    => l_cobra_coverage_elements, 
                                      p_assgt_term_elements        => l_assgt_term_elements);

exception
 when others then
      dbms_output.put_line(substr(sqlerrm,1,200));
      raise;
end delete_person_assignment_api ;

procedure update_cwk_assignment( assignment_id            IN number,
                                 organization_id          IN number,
                                 job_id                   IN number,
                                 grade_id                 IN number,
                                 supervisor_id            IN number,
                                 change_reason            IN varchar2,
                                 asg_effective_start_date IN date) 
IS
     l_position_id                   number;
     l_special_ceiling_step_id       number;
     l_group_name                    varchar2(1000);
     l_effective_start_date          date;
     l_effective_end_date            date;
     l_org_now_no_manager_warning    boolean;
     l_people_group_id               number;
     l_obj_version                   number;
     l_assignment_category           varchar2(2000);
     l_assignment_number             varchar2(2000);
     l_change_reason                 varchar2(2000);
     l_comments                      varchar2(2000);
     l_default_code_comb_id          number;
     l_establishment_id              number;
     l_frequency                     varchar2(2000);
     l_internal_address_line         varchar2(2000);
     l_labour_union_member_flag      varchar2(2000);
     l_manager_flag                  varchar2(2000);
     l_normal_hours                  number;
     l_project_title                 varchar2(2000);
     l_set_of_books_id               number;
     l_source_type                   varchar2(2000);
     l_supervisor_id                 number;
     l_time_normal_finish            varchar2(2000);
     l_time_normal_start             varchar2(2000);
     l_title                         varchar2(2000);
     l_vendor_assignment_number      varchar2(2000);
     l_vendor_employee_number        varchar2(2000);
     l_vendor_id                     number;
     l_vendor_site_id                number;
     l_po_header_id                  number;
     l_po_line_id                    number;
     l_projected_assignment_end      date;
     l_assignment_status_type_id     number;
     l_concat_segments               varchar2(2000);
     l_attribute_category            varchar2(2000);
     l_supervisor_assignment_id      number;
     l_comment_id                    number;
     l_no_managers_warning           boolean;
     l_other_manager_warning         boolean;
     l_soft_coding_keyflex_id        number;
     l_concatenated_segments         varchar2(2000);
     l_hourly_salaried_warning       boolean;
     l_called_from_mass_update       boolean;
     l_pay_basis_id                  number;
     l_people_group_name             varchar2(2000);
     l_spp_delete_warning            boolean;
     l_entries_changed_warning       varchar2(2000);
     l_tax_district_changed_warning  boolean;
     l_location_id                   number;
     l_datetrack_update_mode         varchar2(100);
     
BEGIN
     l_datetrack_update_mode := 'CORRECTION';
 
     --  Calling API HR_ASSIGNMENT_API.CREATE_SECONDARY_CWK_ASG
     SELECT MAX(object_version_number) into l_obj_version FROM PER_ALL_ASSIGNMENTS_F WHERE ASSIGNMENT_ID = update_cwk_assignment.assignment_id;
      
     select location_id into l_location_id  from HR_ALL_ORGANIZATION_UNITS where location_id is not null and organization_id = update_cwk_assignment.organization_id;
     HR_ASSIGNMENT_API.update_cwk_asg_criteria(p_validate                    => FALSE,
                                              p_effective_date               => asg_effective_start_date,
                                              p_datetrack_update_mode        => l_datetrack_update_mode,
                                              p_assignment_id                => assignment_id,
                                              p_called_from_mass_update      => l_called_from_mass_update,
                                              p_object_version_number        => l_obj_version,
                                              p_grade_id                     => grade_id,
                                              p_position_id                  => l_position_id,
                                              p_job_id                       => job_id,
                                              p_location_id                  => l_location_id,
                                              p_organization_id              => organization_id,
                                              p_pay_basis_id                 => l_pay_basis_id,
                                              p_segment1                     => null,
                                              p_segment2                     => null,
                                              p_segment3                     => null,
                                              p_segment4                     => null,
                                              p_segment5                     => null,
                                              p_segment6                     => null,
                                              p_segment7                     => null,
                                              p_segment8                     => null,
                                              p_segment9                     => null,
                                              p_segment10                    => null,
                                              p_segment11                    => null,
                                              p_segment12                    => null,
                                              p_segment13                    => null,
                                              p_segment14                    => null,
                                              p_segment15                    => null,
                                              p_segment16                    => null,
                                              p_segment17                    => null,
                                              p_segment18                    => null,
                                              p_segment19                    => null,
                                              p_segment20                    => null,
                                              p_segment21                    => null,
                                              p_segment22                    => null,
                                              p_segment23                    => null,
                                              p_segment24                    => null,
                                              p_segment25                    => null,
                                              p_segment26                    => null,
                                              p_segment27                    => null,
                                              p_segment28                    => null,
                                              p_segment29                    => null,
                                              p_segment30                    => null,
                                              p_concat_segments              => l_concat_segments,
                                              p_people_group_name            => l_people_group_name,
                                              p_effective_start_date         => l_effective_start_date,
                                              p_effective_end_date           => l_effective_end_date,
                                              p_people_group_id              => l_people_group_id,
                                              p_org_now_no_manager_warning   => l_org_now_no_manager_warning,
                                              p_other_manager_warning        => l_other_manager_warning,
                                              p_spp_delete_warning           => l_spp_delete_warning,
                                              p_entries_changed_warning      => l_entries_changed_warning,
                                              p_tax_district_changed_warning => l_tax_district_changed_warning);                                          
     
     HR_ASSIGNMENT_API.UPDATE_CWK_ASG( p_validate                    => false,
                                      p_effective_date               => asg_effective_start_date,
                                      p_datetrack_update_mode        => l_datetrack_update_mode,
                                      p_assignment_id                => assignment_id,
                                      p_object_version_number        => l_obj_version,
                                      p_assignment_category          => l_assignment_category,
                                      p_assignment_number            => l_assignment_number,
                                      p_change_reason                => change_reason,
                                      p_comments                     => l_comments,
                                      p_default_code_comb_id         => l_default_code_comb_id,
                                      p_establishment_id             => l_establishment_id,
                                      p_frequency                    => l_frequency,
                                      p_internal_address_line        => l_internal_address_line,
                                      p_labour_union_member_flag     => l_labour_union_member_flag,
                                      p_manager_flag                 => l_manager_flag,
                                      p_normal_hours                 => l_normal_hours,
                                      p_project_title                => l_project_title,
                                      p_set_of_books_id              => l_set_of_books_id,
                                      p_source_type                  => l_source_type,
                                      p_supervisor_id                => supervisor_id,
                                      p_time_normal_finish           => l_time_normal_finish,
                                      p_time_normal_start            => l_time_normal_start,
                                      p_title                        => l_title,
                                      p_vendor_assignment_number     => l_vendor_assignment_number,
                                      p_vendor_employee_number       => l_vendor_employee_number,
                                      p_vendor_id                    => l_vendor_id,
                                      p_vendor_site_id               => l_vendor_site_id,
                                      p_po_header_id                 => l_po_header_id,
                                      p_po_line_id                   => l_po_line_id,
                                      p_projected_assignment_end     => l_projected_assignment_end,
                                      p_assignment_status_type_id    => hr_api.g_number,
                                      p_concat_segments              => l_concat_segments,
                                      p_attribute_category           => l_attribute_category,
                                      p_attribute1                   => null,
                                      p_attribute2                   => null,
                                      p_attribute3                   => null,
                                      p_attribute4                   => null,
                                      p_attribute5                   => null,
                                      p_attribute6                   => null,
                                      p_attribute7                   => null,
                                      p_attribute8                   => null,
                                      p_attribute9                   => null,
                                      p_attribute10                  => null,
                                      p_attribute11                  => null,
                                      p_attribute12                  => null,
                                      p_attribute13                  => null,
                                      p_attribute14                  => null,
                                      p_attribute15                  => null,
                                      p_attribute16                  => null,
                                      p_attribute17                  => null,
                                      p_attribute18                  => null,
                                      p_attribute19                  => null,
                                      p_attribute20                  => null,
                                      p_attribute21                  => null,
                                      p_attribute22                  => null,
                                      p_attribute23                  => null,
                                      p_attribute24                  => null,
                                      p_attribute25                  => null,
                                      p_attribute26                  => null,
                                      p_attribute27                  => null,
                                      p_attribute28                  => null,
                                      p_attribute29                  => null,
                                      p_attribute30                  => null,
                                      p_scl_segment1                 => null,
                                      p_scl_segment2                 => null,
                                      p_scl_segment3                 => null,
                                      p_scl_segment4                 => null,
                                      p_scl_segment5                 => null,
                                      p_scl_segment6                 => null,
                                      p_scl_segment7                 => null,
                                      p_scl_segment8                 => null,
                                      p_scl_segment9                 => null,
                                      p_scl_segment10                => null,
                                      p_scl_segment11                => null,
                                      p_scl_segment12                => null,
                                      p_scl_segment13                => null,
                                      p_scl_segment14                => null,
                                      p_scl_segment15                => null,
                                      p_scl_segment16                => null,
                                      p_scl_segment17                => null,
                                      p_scl_segment18                => null,
                                      p_scl_segment19                => null,
                                      p_scl_segment20                => null,
                                      p_scl_segment21                => null,
                                      p_scl_segment22                => null,
                                      p_scl_segment23                => null,
                                      p_scl_segment24                => null,
                                      p_scl_segment25                => null,
                                      p_scl_segment26                => null,
                                      p_scl_segment27                => null,
                                      p_scl_segment28                => null,
                                      p_scl_segment29                => null,
                                      p_scl_segment30                => null,
                                      p_supervisor_assignment_id     => l_supervisor_assignment_id,
                                      p_org_now_no_manager_warning   => l_org_now_no_manager_warning,
                                      p_effective_start_date         => l_effective_start_date,
                                      p_effective_end_date           => l_effective_end_date,
                                      p_comment_id                   => l_comment_id,
                                      p_no_managers_warning          => l_no_managers_warning,
                                      p_other_manager_warning        => l_other_manager_warning,
                                      p_soft_coding_keyflex_id       => l_soft_coding_keyflex_id,
                                      p_concatenated_segments        => l_concatenated_segments,
                                      p_hourly_salaried_warning      => l_hourly_salaried_warning);                                       
exception when others then
     dbms_output.put_line('error : ' || sqlerrm);
     raise;
END update_cwk_assignment;


PROCEDURE update_person_assignment_api( person_id                IN number,
                                        assignment_id            IN number,
                                        organization_id          IN number,
                                        job_id                   IN number,
                                        grade_id                 IN number,
                                        supervisor_id            IN number,
                                        change_reason            IN varchar2,
                                        asg_effective_start_date IN date
)
IS
     l_validate                             boolean;
     l_datetrack_update_mode                VARCHAR2(100);
     l_obj_version                          number;
     l_assignment_number                    VARCHAR2(100);
     l_concatenated_segments                VARCHAR2(100);
     l_cagr_concatenated_segments           varchar2(2000);
     l_comment_id                           number;
     l_effective_start_date                 date;
     l_effective_end_date                   date;
     l_other_manager_warning                boolean;
     l_hourly_salaried_warning              boolean;
     l_no_managers_warning                  boolean;
     l_gsp_post_process_warning             varchar2(100);
     l_assignment_status_type_id            per_assignment_status_types.assignment_status_type_id%TYPE;
     l_soft_coding_keyflex_id               number;
     l_cagr_grade_def_id                    number;
     l_default_code_comb_id                 number;
     l_set_of_books_id                      number;
     l_normal_hours                         number;
     l_probation_period                     number;
     l_date_probation_end                   date;
     l_probation_unit                       varchar2(100);
     l_frequency                            varchar2(4);
     l_bargaining_unit_code                 varchar2(4);
     l_contract_id                          number;
     l_special_ceiling_step_id              number;
     l_people_group_id                      number;
     l_soft_coding_keyflex_cri_id           number;
     l_group_name                           varchar2(100);
     l_cri_effective_start_date             date;
     l_cri_effective_end_date               date;
     l_org_now_no_manager_warning           boolean;
     l_cri_other_manager_warning            boolean;
     l_spp_delete_warning                   boolean;
     l_entries_changed_warning              varchar2(100);
     l_tax_district_changed_warning         boolean;
     l_cri_concatenated_segments            varchar2(100);
     l_cri_gsp_post_process_warning         varchar2(100);
     l_location_id                          number;
     sys_person_type                        per_person_types.system_person_type%type;
     effective_date_to_compare              date;
BEGIN
      l_validate := false;
      l_datetrack_update_mode := 'CORRECTION';
      
      select EFFECTIVE_START_DATE into effective_date_to_compare from PER_ALL_ASSIGNMENTS_F where assignment_id = update_person_assignment_api.assignment_id and job_id is not null AND ((EFFECTIVE_START_DATE >= TRUNC(sysdate)) OR (TRUNC(SYSDATE) BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE) );

      if TRUNC(asg_effective_start_date) <> TRUNC (effective_date_to_compare) then
          raise_application_error (-20001, 'Can not update assignment start date');
      end if;
 
      SELECT MAX(object_version_number) into l_obj_version FROM PER_ALL_ASSIGNMENTS_F WHERE ASSIGNMENT_ID = update_person_assignment_api.assignment_id;
      
      select location_id into l_location_id  from HR_ALL_ORGANIZATION_UNITS where location_id is not null and organization_id = update_person_assignment_api.organization_id;
      select system_person_type  into sys_person_type from per_person_types where person_type_id = (select person_type_id from PER_PERSON_TYPE_USAGES_F where person_id=update_person_assignment_api.person_id);
      if sys_person_type ='EMP' then
     
      HR_ASSIGNMENT_API.update_emp_asg_criteria (p_effective_date               => asg_effective_start_date,
                                                 p_datetrack_update_mode        => l_datetrack_update_mode,
                                                 p_assignment_id                => assignment_id,
                                                 p_validate                     => l_validate,
                                                 p_grade_id                     => grade_id,
                                                 p_job_id                       => job_id,
                                                 p_organization_id              => organization_id,
                                                 p_location_id                  => l_location_id,
                                                 p_object_version_number        => l_obj_version,
                                                 p_special_ceiling_step_id      => l_special_ceiling_step_id,
                                                 p_people_group_id              => l_people_group_id,
                                                 p_soft_coding_keyflex_id       => l_soft_coding_keyflex_cri_id,
                                                 p_group_name                   => l_group_name,
                                                 p_effective_start_date         => l_cri_effective_start_date,
                                                 p_effective_end_date           => l_cri_effective_end_date,
                                                 p_org_now_no_manager_warning   => l_org_now_no_manager_warning,
                                                 p_other_manager_warning        => l_cri_other_manager_warning,
                                                 p_spp_delete_warning           => l_spp_delete_warning,
                                                 p_entries_changed_warning      => l_entries_changed_warning,
                                                 p_tax_district_changed_warning => l_tax_district_changed_warning,
                                                 p_concatenated_segments        => l_cri_concatenated_segments,
                                                 p_gsp_post_process_warning     => l_cri_gsp_post_process_warning);
  
      
        HR_ASSIGNMENT_API.update_emp_asg ( p_validate                     => l_validate,
                                           p_effective_date               => asg_effective_start_date,
                                           p_datetrack_update_mode        => l_datetrack_update_mode,
                                           p_assignment_id                => assignment_id,
                                           p_object_version_number        => l_obj_version,
                                           p_supervisor_id                => supervisor_id,
                                           p_assignment_number            => l_assignment_number,
                                           p_change_reason                => change_reason,
                                           p_comments                     => NULL,
                                           p_date_probation_end           => l_date_probation_end,
                                           p_default_code_comb_id         => l_default_code_comb_id,
                                           p_frequency                    => l_frequency,
                                           p_internal_address_line        => NULL,
                                           p_manager_flag                 => NULL,
                                           p_normal_hours                 => l_normal_hours,
                                           p_perf_review_period           => NULL,
                                           p_perf_review_period_frequency => NULL,
                                           p_probation_period             => l_probation_period,
                                           p_probation_unit               => l_probation_unit,
                                           p_projected_assignment_end     => NULL,
                                           p_sal_review_period            => NULL,
                                           p_sal_review_period_frequency  => NULL,
                                           p_set_of_books_id              => l_set_of_books_id,
                                           p_source_type                  => NULL,
                                           p_time_normal_finish           => NULL,
                                           p_time_normal_start            => NULL,
                                           p_bargaining_unit_code         => l_bargaining_unit_code,
                                           p_cagr_grade_def_id            => l_cagr_grade_def_id,
                                           p_soft_coding_keyflex_id       => l_soft_coding_keyflex_id,
                                           p_cagr_concatenated_segments   => l_cagr_concatenated_segments,
                                           p_concatenated_segments        => l_concatenated_segments,
                                           p_comment_id                   => l_comment_id,
                                           p_effective_start_date         => l_effective_start_date,
                                           p_effective_end_date           => l_effective_end_date,
                                           p_no_managers_warning          => l_no_managers_warning,
                                           p_other_manager_warning        => l_other_manager_warning,
                                           p_hourly_salaried_warning      => l_hourly_salaried_warning,
                                           p_gsp_post_process_warning     => l_gsp_post_process_warning);
      elsif sys_person_type = 'CWK' then
        update_cwk_assignment(assignment_id,organization_id,job_id,grade_id,supervisor_id,change_reason,asg_effective_start_date );
      end if;
  
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SUBSTR(SQLERRM,1,200));
            raise;
END update_person_assignment_api;

END OIM_EMPLOYEE_WRAPPER;
/
