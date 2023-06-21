-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for EBS UM 
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

create or replace package OIM_FND_USER_TCA_PKG is
    ----------------------------------------------------------------------
    --
    -- CreateUser (PUBLIC)
    --   Insert new user record into FND_USER table.
    --   If that user exists already, exception raised with the error message.
    --   There are three input arguments must be provided. All the other columns
    --   in FND_USER table can take the default value.
    --
    --   *** NOTE: This version accepts the old customer_id/employee_id
    --   keys foreign keys to the "person".  Use CreateUserParty to create
    --   a user with the new person_party_id key.
    --
    -- Input (Mandatory)
    --  user_name:            The name of the new user
    --  owner:                'SEED' or 'CUST'(customer)
    --  password: The password for this new user
    --
    procedure CreateUser (
      user_name                  in varchar2,
      owner                      in varchar2,
      password       in varchar2 default null,
      session_number             in number default 0,
      start_date                 in date default sysdate,
      end_date                   in date default null,
      last_logon_date            in date default null,
      description                in varchar2 default null,
      password_date              in date default null,
      password_accesses_left     in number default null,
      password_lifespan_accesses in number default null,
      password_lifespan_days     in number default null,
      employee_id                in number default null,
      email_address              in varchar2 default null,
      fax                        in varchar2 default null,
      customer_id                in number default null,
      supplier_id                in number default null,
      user_guid                  in raw,
      user_id out NUMBER);

    ----------------------------------------------------------------------
    --
    -- CreateUserParty (PUBLIC)
    --   Insert new user record into FND_USER table.
    --   If that user exists already, exception raised with the error message.
    --   There are three input arguments must be provided. All the other columns
    --   in FND_USER table can take the default value.
    --
    --   *** NOTE: This version accepts the new person_party_id foreign key
    --   to the "person".  Use CreateUser to create a user with the old
    --   customer_id/employee_id keys.
    --
    -- Input (Mandatory)
    --  x_user_name:            The name of the new user
    --  x_owner:                'SEED' or 'CUST'(customer)
    --  x_unencrypted_password: The password for this new user
    --


    procedure CreateUserParty (
      user_name                  in varchar2,
      owner                      in varchar2,
      password       in varchar2 default null,
      session_number             in number default 0,
      start_date                 in date default sysdate,
      end_date                   in date default null,
      last_logon_date            in date default null,
      description                in varchar2 default null,
      password_date              in date default null,
      password_accesses_left     in number default null,
      password_lifespan_accesses in number default null,
      password_lifespan_days     in number default null,
      email_address              in varchar2 default null,
      fax                        in varchar2 default null,
      party_id            in number default null,
      user_guid                  in raw,
      user_id out NUMBER
    );

    ----------------------------------------------------------------------
    --
    -- UpdateUser (Public)
    --   Update any column for a particular user record. If that user does
    --   not exist, exception raised with error message.
    --   You can use this procedure to update a user's password for example.
    --
    --   *** NOTE: This version accepts the old customer_id/employee_id
    --   keys foreign keys to the "person".  Use UpdateUserParty to update
    --   a user with the new person_party_id key.
    --
    -- Usage Example in pl/sql
    --   begin fnd_user_pkg.updateuser('SCOTT', 'SEED', 'DRAGON'); end;
    --
    -- Mandatory Input Arguments
    --   user_name: An existing user name
    --   wner:     'SEED' or 'CUST'(customer)
    --
    procedure UpdateUser (
      user_name                  in varchar2,
      owner                      in varchar2,
      password       in varchar2 default null,
      session_number             in number default null,
      start_date                 in date default null,
      end_date                   in date default null,
      last_logon_date            in date default null,
      description                in varchar2 default null,
      password_date              in date default null,
      password_accesses_left     in number default null,
      password_lifespan_accesses in number default null,
      password_lifespan_days     in number default null,
      employee_id                  in number default null,
      email_address              in varchar2 default null,
      fax                          in varchar2 default null,
      customer_id                  in number default null,
      supplier_id                  in number default null,
      old_password               in varchar2 default null,
      user_guid                  in raw);

    ----------------------------------------------------------------------
    --
    -- UpdateUserParty (Public)
    --   Update any column for a particular user record. If that user does
    --   not exist, exception raised with error message.
    --   You can use this procedure to update a user's password for example.
    --
    --   *** NOTE: This version accepts the new person_party_id foreign key
    --   to the "person".  Use UpdateUser to update a user with the old
    --   customer_id/employee_id keys.
    --
    -- Usage Example in pl/sql
    --   begin fnd_user_pkg.updateuser('SCOTT', 'SEED', 'DRAGON'); end;
    --
    -- Mandatory Input Arguments
    --   x_user_name: An existing user name
    --   x_owner:     'SEED' or 'CUST'(customer)
    --
    
    procedure UpdateUserParty (
      user_name                  in varchar2,
      owner                      in varchar2,
      password       in varchar2 default null,
      session_number             in number default null,
      start_date                 in date default null,
      end_date                   in date default null,
      last_logon_date            in date default null,
      description                in varchar2 default null,
      password_date              in date default null,
      password_accesses_left     in number default null,
      password_lifespan_accesses in number default null,
      password_lifespan_days     in number default null,
      email_address              in varchar2 default null,
      fax                        in varchar2 default null,
      party_id            in number,
      old_password               in varchar2 default null,
      user_guid                  in raw
    );


    ----------------------------------------------------------------------------
    --
    -- DisableUser (PUBLIC)
    --   Sets end_date to sysdate for a given user. This is to terminate that user.
    --   You longer can log in as this user anymore. If username is not valid,
    --   exception raised with error message.
    --
    -- Usage example in pl/sql
    --   begin fnd_user_pkg.disableuser('SCOTT'); end;
    --
    -- Input (Mandatory)
    --  username:       User Name
    --
    procedure DisableUser(user_name varchar2);


    ----------------------------------------------------------------------------
    --
    -- EnableUser (PUBLIC)
    --   Sets the start_date and end_date as requested. By default, the
    --   start_date will be set to sysdate and end_date to null.
    --   This is to enable that user.
    --   You can log in as this user from now.
    --   If username is not valid, exception raised with error message.
    --
    -- Usage example in pl/sql
    --   begin fnd_user_pkg.enableuser('SCOTT'); end;
    --   begin fnd_user_pkg.enableuser('SCOTT', sysdate+1, sysdate+30); end;
    --
    -- Input (Mandatory)
    --  username:       User Name
    -- Input (Non-Mandatory)
    --  start_date:     Start Date
    --  end_date:       End Date
    --
    procedure EnableUser(user_name varchar2,
                         start_date date default sysdate,
                         end_date date default FND_USER_PKG.null_date);


    --------------------------------------------------------------------------
    --
    -- DelResp (PUBLIC)
    --   Detach a responsibility which is currently attached to this given user.
    --   If any of the username or application short name or responsibility key or
    --   security group is not valid, exception raised with error message.
    --
    -- Usage example in pl/sql
    --   begin fnd_user_pkg.delresp('SCOTT', '0', '123',
    --                              '0'); end;
    -- Input (Mandatory)
    --  username:       User Name
    --  responsibility_app_id :       Application Id
    --  responsibility_id     :       Responsibility Id
    --  security_group_id : Security Group Id
    --
    procedure DelResp(user_name       varchar2,
                      responsibility_app_id       varchar2,
                      responsibility_id       varchar2,
                      security_group_id varchar2);

    --------------------------------------------------------------------------
    --
    -- AddResp (PUBLIC)
    --   For a given user, attach a valid responsibility.
    --   If user name or application short name or responsbility key name
    --   or security group key is not valid, exception raised with error message.
    --
    -- Usage example in pl/sql
    --   begin fnd_user_pkg.addresp('SCOTT', '0', '234',
    --                              '0', 'DESCRIPTION', sysdate, null); end;
    -- Input (Mandatory)
    --  username:       User Name
    --  responsibility_app_id :       Application Id
    --  responsibility_id     :       Responsibility Id
    --  security_group_id : Security Group Id
    --  resp_description:    Description
    --  resp_start_date:     Start Date
    --  resp_end_date:       End Date
    --
    procedure AddResp(user_name       varchar2,
                      responsibility_app_id       varchar2,
                      responsibility_id       varchar2,
                      security_group_id varchar2,
                      resp_description    varchar2,
                      resp_start_date     date default sysdate,
                      resp_end_date       date);

    -----------------------------------------------------------------------------
    --
    -- change_user_name (PUBLIC)
    --   This api changes username, deals with encryption changes and will
    --   eventually at some point in time in the future, update foreign keys
    --   that were using the old username.  For now it will just do a handoff
    --   of old username and new username to WF so that they can update their
    --   foreign keys.
    --
    -- Usage example in pl/sql
    --   begin fnd_user_pkg.change_user_name('SOCTT', 'SCOTT'); end;
    --
    -- Input (Mandantory)
    --   user_name_old:     Old User Name
    --   user_name_new:     New User Name
    --

    procedure change_user_name( user_name_old in varchar2,
                                user_name_new in varchar2);



    -----------------------------------------------------------------------------
    --
    -- propagateUserRole (PUBLIC)
    --   This api to add role to user
    
    PROCEDURE propagateUserRole(user_name in varchar2,
                                role_id in varchar2,
                                role_start_date  in date default sysdate,
                                expiration_date  in date default null);

    -----------------------------------------------------------------------------
    --
    -- change_user_name (PUBLIC)
    --   This api to revoke user role
    
    PROCEDURE revokeUserRole(user_name in varchar2,
                             role_id in varchar2);
                           
    -----------------------------------------------------------------------------
    -- Procedure to change the password for a user 
    -- Input (Mandantory)
    --   user_name:      User Name
    --   password:     New password for a user
    
    PROCEDURE ChangePassword(user_name      varchar2,
                             password   varchar2);
    
    ----------------------------------------------------------------------
    --
    -- Create Supplier organization 
    -- Input (Mandatory)
    --  supplier_name:            The name of the Supplier organization
    
    PROCEDURE create_supplier( supplier_name IN VARCHAR2,
                               supplier_party_id    out number);
    
    ----------------------------------------------------------------------
    --
    -- Create Supplier contact for supplier
    -- Input (Mandatory)
    --  supplier_name:            The name of the Supplier organization
    --  party_first_name:         Supplier contact first name
    --  party_last_name:         Supplier contact last name
    
    PROCEDURE create_supplier_contact(supplier_name IN VARCHAR2,
                                      party_first_name IN VARCHAR2,
                                      party_last_name IN VARCHAR2,
                                      party_id    out number);
    ----------------------------------------------------------------------
    --
    -- Link Supplier contact party with the user
    -- Input (Mandatory)
    -- user_name:            The name of the Supplier organization
    -- party_id:             Party id
    
    procedure link_user_party(user_name varchar2,party_id number);
    
    -------Procedure for creating party--------

    procedure create_party( party_last_name   in varchar2,
      party_first_name  in varchar2,
      user_name   in varchar2,
      user_guid        in varchar2 default null,
      party_id    out number
    );
    -------Procedure for updating  party--------
    
    procedure update_party( party_last_name   in varchar2,
      party_first_name  in varchar2,
      user_name     in varchar2 ,
      user_guid        in varchar2  default null
    );
    
    PROCEDURE validatePartyAndPerson( party_id  in number,
                            employee_id in number default null); 
    
    procedure revokeUser(user_id in number); 
    
    procedure create_supplier_security_attrs(user_name  in varchar2, supplier_party_id in number);
    
end OIM_FND_USER_TCA_PKG;

/

create or replace PACKAGE BODY OIM_FND_USER_TCA_PKG AS
   error_message  VARCHAR2(70) := 'Invalid End date. End date cannot be less than start date.';
   -----------------------------------------------------------------------
    --
    -- CreateUser (PUBLIC)
    --   Insert new user record into FND_USER table.
    --   If that user exists already, exception raised with the error message.
    --   There are three input arguments must be provided. All the other columns
    --   in FND_USER table can take the default value.
    --
    --   *** NOTE: This version accepts the old customer_id/employee_id
    --   keys foreign keys to the "person".  Use CreateUserParty to create
    --   a user with the new person_party_id key.
    --
    -- Input (Mandatory)
    --  x_user_name:            The name of the new user
    --  x_owner:                'SEED' or 'CUST'(customer)
    --  x_unencrypted_password: The password for this new user
    --
    procedure CreateUser( user_name                  in varchar2,
                          owner                      in varchar2,
                          password       in varchar2 default null,
                          session_number             in number default 0,
                          start_date                 in date default sysdate,
                          end_date                   in date default null,
                          last_logon_date            in date default null,
                          description                in varchar2 default null,
                          password_date              in date default null,
                          password_accesses_left     in number default null,
                          password_lifespan_accesses in number default null,
                          password_lifespan_days     in number default null,
                          employee_id                in number default null,
                          email_address              in varchar2 default null,
                          fax                        in varchar2 default null,
                          customer_id                in number default null,
                          supplier_id                in number default null,
                          user_guid                  in raw,
                          user_id out NUMBER)
    is
      x_user_name                 fnd_user.user_name%type;
      x_owner                     varchar2(200);
      x_unencrypted_password      varchar2(200);
      x_session_number            number default 0;
      x_start_date                date;
      x_end_date                  date;
      x_last_logon_date           date;
      x_description               varchar2(200);
      x_password_date             date;
      x_password_accesses_left    number;
      x_password_lifespan_accesses number;
      x_password_lifespan_days    number;
      x_employee_id               number;
      x_email_address             fnd_user.email_address%type;
      x_fax                       fnd_user.fax%type;
      x_customer_id               number;
      x_supplier_id               number;
      x_user_id                   number;
      x_user_guid                 fnd_user.user_guid%type;
    begin
      if password_lifespan_accesses is null then
        x_password_lifespan_accesses := FND_USER_PKG.null_number;
      else
        x_password_lifespan_accesses := password_lifespan_accesses;
      end if;
      
      if password_lifespan_days is null then
        x_password_lifespan_days := FND_USER_PKG.null_number;
      else
        x_password_lifespan_days := password_lifespan_days;
      end if;
      x_user_name               := user_name;
      x_owner                   := owner;
      x_unencrypted_password    := password;
      x_session_number          := session_number;
      x_start_date              := start_date;
      x_end_date                := end_date;
      x_last_logon_date         := last_logon_date;
      x_description             := description;
      x_password_date           := sysdate;
      x_password_accesses_left  := password_accesses_left;
      x_employee_id             := employee_id;
      x_email_address           := email_address;
      x_fax                     := fax;
      x_customer_id             := customer_id;
      x_supplier_id             := supplier_id;
      x_user_guid               := user_guid;
      if x_start_date > x_end_date then
           raise_application_error (-20001, error_message);
      end if;
      FND_USER_PKG.CreateUser(x_user_name,
                            x_owner,
                            x_unencrypted_password,
                            x_session_number,
                            x_start_date,
                            x_end_date,
                            x_last_logon_date,
                            x_description,
                            x_password_date,
                            x_password_accesses_left,
                            x_password_lifespan_accesses,
                            x_password_lifespan_days,
                            x_employee_id,
                            x_email_address,
                            x_fax,
                            x_customer_id,
                            x_supplier_id);
     if x_user_guid is not null then
        update fnd_user set user_guid = x_user_guid  where user_name = x_user_name;
     end if;
     SELECT USER_ID into x_user_id FROM FND_USER WHERE USER_NAME=x_user_name;
     user_id := x_user_id;
    end CreateUser;
   
    ----------------------------------------------------------------------
    --
    -- CreateUserParty (PUBLIC)
    --   Insert new user record into FND_USER table.
    --   If that user exists already, exception raised with the error message.
    --   There are three input arguments must be provided. All the other columns
    --   in FND_USER table can take the default value.
    --
    --   *** NOTE: This version accepts the new person_party_id foreign key
    --   to the "person".  Use CreateUser to create a user with the old
    --   customer_id/employee_id keys.
    --
    -- Input (Mandatory)
    --  x_user_name:            The name of the new user
    --  x_owner:                'SEED' or 'CUST'(customer)
    --  x_unencrypted_password: The password for this new user
    --

    procedure CreateUserParty(user_name                  in varchar2,
                              owner                      in varchar2,
                              password       in varchar2 default null,
                              session_number             in number default 0,
                              start_date                 in date default sysdate,
                              end_date                   in date default null,
                              last_logon_date            in date default null,
                              description                in varchar2 default null,
                              password_date              in date default null,
                              password_accesses_left     in number default null,
                              password_lifespan_accesses in number default null,
                              password_lifespan_days     in number default null,
                              email_address              in varchar2 default null,
                              fax                        in varchar2 default null,
                              party_id            in number default null,
                              user_guid                  in raw,
                              user_id out NUMBER)
    is
    
      x_user_name                 fnd_user.user_name%type;
      x_owner                     varchar2(200);
      x_unencrypted_password      varchar2(200);
      x_session_number            number default 0;
      x_start_date                date;
      x_end_date                  date;
      x_last_logon_date           date;
      x_description               varchar2(200);
      x_password_date             date;
      x_password_accesses_left    number;
      x_password_lifespan_accesses number;
      x_password_lifespan_days    number;
      x_email_address             fnd_user.email_address%type;
      x_fax                       fnd_user.fax%type;
      x_user_id                   number;
      x_party_id                  number;
      x_user_guid                 fnd_user.user_guid%type;
    begin
      if password_lifespan_accesses is null then
        x_password_lifespan_accesses := FND_USER_PKG.null_number;
      else
        x_password_lifespan_accesses := password_lifespan_accesses;
      end if;
      if password_lifespan_days is null then
        x_password_lifespan_days := FND_USER_PKG.null_number;
      else
        x_password_lifespan_days := password_lifespan_days;
      end if;
      x_user_name               := user_name;
      x_owner                   := owner;
      x_unencrypted_password    := password;
      x_session_number          := session_number;
      x_start_date              := start_date;
      x_end_date                := end_date;
      x_last_logon_date         := last_logon_date;
      x_description             := description;
      x_password_date           := sysdate;
      x_user_guid               := user_guid;
      x_password_accesses_left  := password_accesses_left;
      x_email_address           := email_address;
      x_fax                     := fax;
      x_party_id                := party_id;
      
      if x_start_date > x_end_date then
           raise_application_error (-20001, error_message);
      end if;
      
      FND_USER_PKG.CreateUserParty( x_user_name,
                                    x_owner,
                                    x_unencrypted_password,
                                    x_session_number,
                                    x_start_date,
                                    x_end_date,
                                    x_last_logon_date,
                                    x_description,
                                    x_password_date,
                                    x_password_accesses_left,
                                    x_password_lifespan_accesses,
                                    x_password_lifespan_days,
                                    x_email_address,
                                    x_fax,
                                    x_party_id);
        if x_user_guid is not null then
        update fnd_user set user_guid = x_user_guid  where user_name = x_user_name;
        end if;
        SELECT USER_ID into x_user_id FROM FND_USER WHERE USER_NAME=x_user_name;
        user_id := x_user_id;
    end CreateUserParty;
    ----------------------------------------------------------------------
    --
    -- UpdateUser (Public)
    --   Update any column for a particular user record. If that user does
    --   not exist, exception raised with error message.
    --   You can use this procedure to update a user's password for example.
    --
    --   *** NOTE: This version accepts the old customer_id/employee_id
    --   keys foreign keys to the "person".  Use UpdateUserParty to update
    --   a user with the new person_party_id key.
    --
    -- Usage Example in pl/sql
    --   begin fnd_user_pkg.updateuser('SCOTT', 'SEED', 'DRAGON'); end;
    --
    -- Mandatory Input Arguments
    --   x_user_name: An existing user name
    --   x_owner:     'SEED' or 'CUST'(customer)
    --
    procedure UpdateUser (user_name  in varchar2,
                          owner                      in varchar2,
                          password                   in varchar2 default null,
                          session_number             in number default null,
                          start_date                 in date default null,
                          end_date                   in date default null,
                          last_logon_date            in date default null,
                          description                in varchar2 default null,
                          password_date              in date default null,
                          password_accesses_left     in number default null,
                          password_lifespan_accesses in number default null,
                          password_lifespan_days     in number default null,
                          employee_id                in number default null,
                          email_address              in varchar2 default null,
                          fax                        in varchar2 default null,
                          customer_id                in number default null,
                          supplier_id                in number default null,
                          old_password               in varchar2 default null,
                          user_guid                  in raw)
  is
      x_user_name                 fnd_user.user_name%type;
      x_owner                     varchar2(200);
      x_unencrypted_password      varchar2(200);
      x_session_number            number default 0;
      x_start_date                date;
      x_end_date                  date;
      x_last_logon_date           date;
      x_description               varchar2(200);
      x_password_date             date;
      x_password_accesses_left    number;
      x_password_lifespan_accesses number;
      x_password_lifespan_days    number;
      x_employee_id               number;
      x_email_address             fnd_user.email_address%type;
      x_fax                       fnd_user.fax%type;
      x_customer_id               number;
      x_supplier_id               number;
      x_old_password              varchar2(200);
      x_user_guid fnd_user.user_guid%type;
   begin
      x_password_accesses_left := password_accesses_left;
      if password_lifespan_accesses is null then
        x_password_lifespan_accesses := FND_USER_PKG.null_number;
      else
        x_password_lifespan_accesses := password_lifespan_accesses;
      end if;
      if password_lifespan_days is null then
        x_password_lifespan_days := FND_USER_PKG.null_number;
      else
        x_password_lifespan_days := password_lifespan_days;
      end if;
      x_user_name               := user_name;
      select start_date into x_start_date from fnd_user where user_name=x_user_name;
      if x_start_date <> start_date then
        x_password_date           := sysdate;
      end if;
          
      x_owner                   := owner;
      x_unencrypted_password    := password;
      x_session_number          := session_number;
      x_start_date              := start_date;
      x_end_date                := end_date;
      x_last_logon_date         := last_logon_date;
      x_description             := description;
      x_employee_id             := employee_id;
      x_email_address           := email_address;
      x_fax                     := fax;
      x_customer_id             := customer_id;
      x_supplier_id             := supplier_id;
      x_old_password            := old_password;
      x_user_guid               := user_guid;

      if (x_end_date != FND_USER_PKG.null_date) AND (x_start_date > x_end_date) then
           raise_application_error (-20001, error_message);
      end if;
      FND_USER_PKG.UpdateUser(x_user_name,
                              x_owner,
                              x_unencrypted_password,
                              x_session_number,
                              x_start_date,
                              x_end_date,
                              x_last_logon_date,
                              x_description,
                              x_password_date,
                              x_password_accesses_left,
                              x_password_lifespan_accesses,
                              x_password_lifespan_days,
                              x_employee_id,
                              x_email_address,
                              x_fax,
                              x_customer_id,
                              x_supplier_id,
                              x_old_password);
      if x_user_guid is not null then
          update fnd_user set user_guid = x_user_guid  where user_name = x_user_name;
      end if;
    end UpdateUser;

    procedure UpdateUserParty(user_name                  in varchar2,
                              owner                      in varchar2,
                              password                   in varchar2 default null,
                              session_number             in number default null,
                              start_date                 in date default null,
                              end_date                   in date default null,
                              last_logon_date            in date default null,
                              description                in varchar2 default null,
                              password_date              in date default null,
                              password_accesses_left     in number default null,
                              password_lifespan_accesses in number default null,
                              password_lifespan_days     in number default null,
                              email_address              in varchar2 default null,
                              fax                        in varchar2 default null,
                              party_id                   in number,
                              old_password               in varchar2 default null,
                              user_guid                  in raw)
     is
          x_user_name                 fnd_user.user_name%type;
          x_owner                     varchar2(200);
          x_unencrypted_password      varchar2(200);
          x_session_number            number default 0;
          x_start_date                date;
          x_end_date                  date;
          x_last_logon_date           date;
          x_description               varchar2(200);
          x_password_date             date;
          x_password_accesses_left    number;
          x_password_lifespan_accesses number;
          x_password_lifespan_days    number;
          x_employee_id               number;
          x_email_address             fnd_user.email_address%type;
          x_fax                       fnd_user.fax%type;
          x_party_id                  number;
          x_old_password              varchar2(200);
          x_user_guid                 fnd_user.user_guid%type;
    begin
          if password_lifespan_accesses is null then
            x_password_lifespan_accesses := FND_USER_PKG.null_number;
          else
            x_password_lifespan_accesses := password_lifespan_accesses;
          end if;
          if password_lifespan_days is null then
            x_password_lifespan_days := FND_USER_PKG.null_number;
          else
            x_password_lifespan_days := password_lifespan_days;
          end if;
          x_user_name               := user_name;
          
          select start_date into x_start_date from fnd_user where user_name=x_user_name;
          if x_start_date <> start_date then
            x_password_date           := sysdate;
          end if;
          
          x_owner                   := owner;
          x_unencrypted_password    := password;
          x_session_number          := session_number;
          x_start_date              := start_date;
          x_end_date                := end_date;
          x_last_logon_date         := last_logon_date;
          x_description             := description;
          x_password_accesses_left  := password_accesses_left;
          x_email_address           := email_address;
          x_fax                     := fax;
          x_party_id                := party_id;
          x_old_password            := old_password;
          x_user_guid               :=user_guid;

          if (x_end_date != FND_USER_PKG.null_date) AND (x_start_date > x_end_date) then
            raise_application_error (-20001, error_message);
          end if;
      
          FND_USER_PKG.UpdateUserParty(x_user_name,
                                      x_owner,
                                      x_unencrypted_password,
                                      x_session_number,
                                      x_start_date,
                                      x_end_date,
                                      x_last_logon_date,
                                      x_description,
                                      x_password_date,
                                      x_password_accesses_left,
                                      x_password_lifespan_accesses,
                                      x_password_lifespan_days,
                                      x_email_address,
                                      x_fax,
                                      x_party_id,
                                      x_old_password);
          if x_user_guid is not null then
            update fnd_user set user_guid = x_user_guid  where user_name = x_user_name;
          end if;
    end UpdateUserParty;


    ----------------------------------------------------------------------------
    --
    -- DisableUser (PUBLIC)
    --   Sets end_date to sysdate for a given user. This is to terminate that user.
    --   You longer can log in as this user anymore. If username is not valid,
    --   exception raised with error message.
    --
    -- Usage example in pl/sql
    --   begin fnd_user_pkg.disableuser('SCOTT'); end;
    --
    -- Input (Mandatory)
    --  username:       User Name
    --
    procedure DisableUser(user_name varchar2) 
    is
        x_user_name                 varchar2(200);
    begin
        x_user_name := user_name;
        FND_USER_PKG.DisableUser(x_user_name);
    end DisableUser;

    ----------------------------------------------------------------------------
    --
    -- EnableUser (PUBLIC)
    --   Sets the start_date and end_date as requested. By default, the
    --   start_date will be set to sysdate and end_date to null.
    --   This is to enable that user.
    --   You can log in as this user from now.
    --   If username is not valid, exception raised with error message.
    --
    -- Usage example in pl/sql
    --   begin fnd_user_pkg.enableuser('SCOTT'); end;
    --   begin fnd_user_pkg.enableuser('SCOTT', sysdate+1, sysdate+30); end;
    --
    -- Input (Mandatory)
    --  username:       User Name
    -- Input (Non-Mandatory)
    --  start_date:     Start Date
    --  end_date:       End Date
    --
    procedure EnableUser(user_name varchar2,
                         start_date date default sysdate,
                         end_date date )  
    is
        x_user_name  varchar2(200);
        x_start_date date;
        x_end_date   date;
    begin
        x_user_name := user_name;
        x_start_date := start_date;
        if end_date is null then
            x_end_date := FND_USER_PKG.null_date;
        else
            x_end_date := end_date;
        end if;
        FND_USER_PKG.EnableUser(x_user_name,
                              x_start_date,
                              x_end_date);
    end EnableUser;
    
    --------------------------------------------------------------------------
    --
    -- DelResp (PUBLIC)
    --   Detach a responsibility which is currently attached to this given user.
    --   If any of the username or application short name or responsibility key or
    --   security group is not valid, exception raised with error message.
    --
    -- Usage example in pl/sql
    --   begin fnd_user_pkg.delresp('SCOTT', 'FND', 'APPLICATION_DEVELOPER',
    --                              'STANDARD'); end;
    -- Input (Mandatory)
    --  username                :       User Name
    --  responsibility_app_id :       Application Short Id
    --  responsibility_id     :       Responsibility Id
    --  security_group_id : Security Group Id
    --
    procedure DelResp(user_name       varchar2,
                  responsibility_app_id       varchar2,
                  responsibility_id       varchar2,
                  security_group_id varchar2)
    is
        responsibility_short_name       varchar2(1000);
        app_short_name          varchar2(1000);
        sec_group_key      varchar2(1000);
    begin
        SELECT responsibility_key into responsibility_short_name FROM fnd_responsibility WHERE responsibility_id = DelResp.responsibility_id AND application_id = responsibility_app_id;
        SELECT application_short_name into app_short_name FROM fnd_application WHERE application_id = responsibility_app_id;
        SELECT security_group_key into sec_group_key  FROM fnd_security_groups  WHERE security_group_id = DelResp.security_group_id;
        FND_USER_PKG.DelResp(user_name,
                  app_short_name,
                  responsibility_short_name,
                  sec_group_key);
    end DelResp;

    --------------------------------------------------------------------------
    --
    -- AddResp (PUBLIC)
    --   For a given user, attach a valid responsibility.
    --   If user name or application short name or responsbility key name
    --   or security group key is not valid, exception raised with error message.
    --
    -- Usage example in pl/sql
    --   begin fnd_user_pkg.addresp('SCOTT', '0', '123',
    --                              '0', 'DESCRIPTION', sysdate, null); end;
    -- Input (Mandatory)
    --  username:       User Name
    --  responsibility_app_id :       Application Short Id
    --  responsibility_id     :       Responsibility Id
    --  security_group_id : Security Group Id
    --  resp_description:    Description
    --  resp_start_date:     Start Date
    --  resp_end_date:       End Date
    --
    procedure AddResp(user_name              varchar2,
                      responsibility_app_id  varchar2,
                      responsibility_id      varchar2,
                      security_group_id      varchar2,
                      resp_description       varchar2,
                      resp_start_date        date default sysdate,
                      resp_end_date          date)
    is
        responsibility_short_name       varchar2(1000);
        app_short_name          varchar2(1000);
        sec_group_key      varchar2(1000);
        x_resp_start_date date;
        
    begin

        if resp_start_date is null then
          x_resp_start_date := sysdate;
        else 
          x_resp_start_date := resp_start_date;
        end if;

        SELECT responsibility_key into responsibility_short_name FROM fnd_responsibility WHERE responsibility_id = AddResp.responsibility_id AND application_id = responsibility_app_id;
        SELECT application_short_name into app_short_name FROM fnd_application WHERE application_id = responsibility_app_id;
        SELECT security_group_key into sec_group_key  FROM fnd_security_groups  WHERE security_group_id = AddResp.security_group_id;
        if x_resp_start_date > resp_end_date then
           raise_application_error (-20001, error_message);
        end if;
        
        FND_USER_PKG.AddResp( user_name,
                              app_short_name,
                              responsibility_short_name,
                              sec_group_key,
                              resp_description,
                              x_resp_start_date,
                              resp_end_date);
    end AddResp;

    --------------------------------------------------------------------------
    --
    -- change_user_name (PUBLIC)
    --   This api changes username, deals with encryption changes and will
    --   eventually at some point in time in the future, update foreign keys
    --   that were using the old username.  For now it will just do a handoff
    --   of old username and new username to WF so that they can update their
    --   foreign keys.
    --
    -- Usage example in pl/sql
    --   begin fnd_user_pkg.change_user_name('SOCTT', 'SCOTT'); end;
    --
    -- Input (Mandantory)
    --   user_name_old:     Old User Name
    --   user_name_new:     New User Name
    
    procedure change_user_name(user_name_old  in varchar2,
                               user_name_new  in varchar2)
    is
    begin
         FND_USER_PKG.change_user_name(user_name_old, user_name_new );
    end change_user_name;

    
    -------Procedure for propagateUserRole--------
    PROCEDURE propagateUserRole(user_name             in varchar2,
                                role_id             in varchar2,
                                role_start_date       in date default sysdate,
                                expiration_date       in date default null)
    IS
      x_role_start_date date;

    begin
        if role_start_date is null then
          x_role_start_date := sysdate;
        else
          x_role_start_date := role_start_date;
        end if;

        if x_role_start_date > expiration_date then
           raise_application_error (-20001, error_message);
        end if;
        
        UMX_ACCESS_ROLES_PVT.propagateUserRole( p_user_name    => user_name,
                                                p_role_name       => role_id,
                                                p_start_date      => x_role_start_date,
                                                p_expiration_date => expiration_date);

    end propagateUserRole;

    -------Procedure for revokeUserRole--------
    PROCEDURE revokeUserRole(user_name           in varchar2,
                             role_id             in varchar2)
    IS
          l_start_date date;
          x_user_name varchar2(500);
          l_expiration_date date := sysdate;
    begin
        x_user_name := user_name;
        select min(start_date) into l_start_date from WF_USER_ROLE_ASSIGNMENTS where user_name=x_user_name and role_name=role_id;
        WF_LOCAL_SYNCH.PropagateUserRole(p_user_name       => x_user_name,
                                         p_role_name       => role_id,
                                         p_start_date      => l_start_date,
                                         p_expiration_date => l_expiration_date);

    end revokeUserRole;

    procedure  ChangePassword(user_name      varchar2,
                              password   varchar2)
    is
    
    begin
      if FND_USER_PKG.changepassword(username=>user_name,newpassword =>password) then
      dbms_output.put_line('Password updated successfully' );
      ELSE
        raise_application_error (-20001, 'Error while updating the password');
      end if;
      EXCEPTION
        WHEN OTHERS THEN
        raise;
    end;

    PROCEDURE create_supplier(supplier_name IN VARCHAR2,
                              supplier_party_id out number) 
    is
        l_vendor_rec ap_vendor_pub_pkg.r_vendor_rec_type;
        l_return_status VARCHAR2(10);
        l_msg_count NUMBER;
        l_msg_data VARCHAR2(1000);
        l_vendor_id NUMBER;
    
    BEGIN
        l_vendor_rec.vendor_name := supplier_name;
        l_vendor_rec.start_date_active := sysdate ;
    
        POS_VENDOR_PUB_PKG.create_vendor(p_vendor_rec    => l_vendor_rec,
                                         x_return_status => l_return_status,
                                         x_msg_count     => l_msg_count,
                                         x_msg_data      => l_msg_data,
                                         x_vendor_id     => l_vendor_id,
                                         x_party_id      => supplier_party_id);
    
    end create_supplier;

     ----------------------------------------------------------------------
    --
    -- Create Supplier contact for supplier
    -- Input (Mandatory)
    --  supplier_name:            The name of the Supplier organization
    --  party_first_name:         Supplier contact first name
    --  party_last_name:         Supplier contact last name
   
   PROCEDURE create_supplier_contact( supplier_name    IN VARCHAR2,
                                      party_first_name IN VARCHAR2,
                                      party_last_name  IN VARCHAR2,
                                      party_id         OUT number) 
    is
        l_vendor_contact_rec ap_vendor_pub_pkg.r_vendor_contact_rec_type;
        l_return_status VARCHAR2(10);
        l_msg_count NUMBER;
        l_msg_data VARCHAR2(1000);
        l_vendor_contact_id NUMBER;
        l_per_party_id NUMBER;
        l_rel_party_id NUMBER;
        l_rel_id NUMBER;
        l_org_contact_id NUMBER;
        l_party_site_id NUMBER;
    
    BEGIN
        SELECT vendor_id INTO   l_vendor_contact_rec.vendor_id
        FROM   pos_po_vendors_v
        WHERE  vendor_name = supplier_name;
    
        l_vendor_contact_rec.person_first_name := party_first_name;
        l_vendor_contact_rec.person_last_name := party_last_name;
    
    
        POS_VENDOR_PUB_PKG.create_vendor_contact(p_vendor_contact_rec => l_vendor_contact_rec,
                                                 x_return_status      => l_return_status,
                                                 x_msg_count          => l_msg_count,
                                                 x_msg_data           => l_msg_data,
                                                 x_vendor_contact_id  => l_vendor_contact_id,
                                                 x_per_party_id       => party_id,
                                                 x_rel_party_id       => l_rel_party_id,
                                                 x_rel_id             => l_rel_id,
                                                 x_org_contact_id     => l_org_contact_id,
                                                 x_party_site_id      => l_party_site_id);
    
    
    end create_supplier_contact;

    ----------------------------------------------------------------------
    --
    -- Link Supplier contact party with the user
    -- Input (Mandatory)
    -- user_name:            The name of the Supplier organization
    -- party_id:             Party id
    
    procedure link_user_party(user_name varchar2,
                              party_id number) 
    is
    begin
        FND_USER_PKG.UpdateUserParty (user_name,null, null,null,null,null,null,
                                      null,null,null,null,null,null,null,
                                      party_id,null);
    end link_user_party;

    procedure create_party( party_last_name   IN varchar2,
                            party_first_name  IN varchar2,
                            user_name         IN varchar2,
                            user_guid         IN varchar2  default null,
                            party_id          OUT number)
    is
        -- Declare cursors and local variables
        p_oid_rec       fnd_oid_util.ldap_message_type;
        x_ret_status    varchar2(1000);
    BEGIN
      
      IF party_last_name is NULL THEN
         p_oid_rec.sn := fnd_API.G_MISS_CHAR;
      ELSE
         p_oid_rec.sn := party_last_name;
      END IF;
      
      IF party_first_name is NULL THEN
         p_oid_rec.givenName := fnd_API.G_MISS_CHAR;
      ELSE
         p_oid_rec.givenName := party_first_name;
      END IF;
      
      
      p_oid_rec.object_name    := user_name;
      p_oid_rec.orclGUID       := user_guid;
    
    
      -- Start of API
      FND_OID_USERS.hz_create(p_oid_rec,x_ret_status);
     
      if (x_ret_status = fnd_Api.G_RET_STS_SUCCESS) then
        select person_party_id into   party_id from  fnd_user where user_name = p_oid_rec.object_name;
      end if;
     
      EXCEPTION
        WHEN OTHERS THEN
          dbms_output.put_line(SUBSTR(SQLERRM,1,100));
    END create_party;

    -------Procedure for updating a person party--------
    procedure update_party( party_last_name   IN varchar2,
                            party_first_name  IN varchar2,
                            user_name         IN varchar2 ,
                            user_guid         IN varchar2  default null)
    IS 
    
         -- Declare cursors and local variables
         p_oid_rec       fnd_oid_util.ldap_message_type;
         x_ret_status    varchar2(1000);
         p_person_rec HZ_PARTY_V2PUB.PERSON_REC_TYPE;
         x_profile_id  varchar2(1000);
         x_msg_data varchar2(1000);
         l_party_object_version_number number;
         x_msg_count number;
         l_init_msg_list varchar2(1000);
         p_party_id number;
         x_user_name varchar2(1000);
    BEGIN
    
        IF party_last_name is NULL THEN
            p_oid_rec.sn := fnd_API.G_MISS_CHAR;
        ELSE
            p_oid_rec.sn := party_last_name;
        END IF;
      
        IF party_first_name is NULL THEN
            p_oid_rec.givenName := fnd_API.G_MISS_CHAR;
        ELSE
            p_oid_rec.givenName := party_first_name;
        END IF;
      
        p_oid_rec.object_name    := user_name;
        p_oid_rec.orclGUID       := user_guid;
     
        -- Start of API
        fnd_oid_users.hz_update(p_oid_rec,x_ret_status);
        if (x_ret_status <> fnd_api.G_RET_STS_SUCCESS)
        then
             if party_first_name is NULL THEN
                p_person_rec.person_first_name := fnd_API.G_MISS_CHAR;
             else
                p_person_rec.person_first_name := party_first_name;
             end if;
             p_person_rec.person_last_name  := party_last_name;
             x_user_name := user_name;
             select person_party_id into p_party_id from fnd_user where user_name=x_user_name;
             p_person_rec.party_rec.party_id := p_party_id;
             SELECT object_version_number into l_party_object_version_number FROM hz_parties WHERE party_id=p_party_id;
             HZ_PARTY_V2PUB.update_person ( p_init_msg_list               => l_init_msg_list,
                                            p_person_rec                  => p_person_rec,
                                            p_party_object_version_number => l_party_object_version_number,
                                            x_profile_id                  => x_profile_id,
                                            x_return_status               => x_ret_status,
                                            x_msg_count                   => x_msg_count,
                                            x_msg_data                    => x_msg_data);
         end if;
     EXCEPTION
     WHEN OTHERS THEN
          dbms_output.put_line(SUBSTR(SQLERRM,1,100));
    END update_party;

    
    PROCEDURE validatePartyAndPerson( party_id    IN number,
                                      employee_id IN number default null) 
    IS
        x_person_party_id number;
    begin
        if employee_id is not null then
            select party_id into x_person_party_id from per_all_people_f where person_id = employee_id and rownum=1;
            if x_person_party_id <> party_id then
                raise_application_error(-20101, 'Input party_id and person party id are different');
            end if;
         end if;
    end validatePartyAndPerson;
    
    procedure revokeUser(user_id in number)
    IS
        x_user_name fnd_user.user_name%type;
        x_party_id number;
        begin
           select user_name into x_user_name from fnd_user where user_id=revokeUser.user_id;
           disableuser(x_user_name);
    end revokeUser;

    procedure addSecurityAttribute(user_id            IN number, 
                                   security_attribute IN varchar2, 
                                   app_id             IN varchar2,
                                   security_value     IN varchar2)
    IS
          x_return_status VARCHAR2(2000);
          x_msg_count NUMBER;
          x_msg_data VARCHAR2(2000);
    begin
        ICX_USER_SEC_ATTR_PUB.create_user_sec_attr(p_api_version_number   => 1,
                                                   p_return_status        => x_return_status,
                                                   p_msg_count            => x_msg_count,
                                                   p_msg_data             => x_msg_data,
                                                   p_web_user_id          => user_id,
                                                   p_attribute_code       => security_attribute,
                                                   p_attribute_appl_id    => app_id, 
                                                   p_varchar2_value       => '',
                                                   p_date_value           => '',
                                                   p_number_value         => security_value, 
                                                   p_created_by           => -1,
                                                   p_creation_date        => sysdate,
                                                   p_last_updated_by      => -1,
                                                   p_last_update_date     => sysdate,
                                                   p_last_update_login    => -1);
    end addSecurityAttribute;
        
    procedure create_supplier_security_attrs(user_name         IN varchar2, 
                                             supplier_party_id IN number)
    IS
          l_user_id          number;
          x_user_name        fnd_user.user_name%type;
          l_vendor_id        number;
    begin
        x_user_name               := user_name;
        select user_id into l_user_id from fnd_user where user_name=upper(x_user_name);
        select vendor_id into l_vendor_id from ap_suppliers where party_id=supplier_party_id;
        
        addSecurityAttribute(l_user_id,'ICX_SUPPLIER_ORG_ID',177,l_vendor_id);
    
    end create_supplier_security_attrs;

    
end OIM_FND_USER_TCA_PKG;

/
