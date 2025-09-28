create database Bank_Management_System;

use Bank_Management_System;


-------------------------------------BANK MANAGEMENT PROJECT-------------------------------------
/*

		-----------BACKEND BANKING SYSTEM PROJECT (DATA ANALYST)--------------

		1. REAL LIFE EXAMPLE INVOLVING TRIGGERS, STORED PROCEDURES AND FUNCTIONS.
		2. IN TOTAL WE WILL BE HAVING 4 TABLES

		TABLES:		
			1. Account_opening_form
			   (
			   ID : PK (TO TRACK RECORDS) 

			   DATE: BY DEFAULT IT SHOULD BE THE CURRENT DATE OF ACC OPENING 

			   ACCOUNT_TYPE: (SAVINGS - DEFAULT, CURRENT) 

			   ACCOUNT_HOLDER_NAME: NAME OF ACCOUNT HOLDER 

			   DOB: DATE OF BIRTH 

			   AADHAR_NUMBER: (CANNOT BE REPEATED) - CAN HOLD MAX 12 NUMBERS 

			   MOBILE_NUMBER: CAN HOLD MAX 15 NUMBERS 

			   ACCOUNT_OPENING_BALANCE: DECIMAL DATA TYPE SHOULD BE ALLOWED ONLY - MINIMUM AMOUNT SHOULD BE 1000

			   ADDRESS: ADDRESS OF ACCOUNT HOLDER 

			   KYC_STATUS: APPROVED, PENDING (BY DEFAULT), REJECTED
			   )


			
			2. BANK
			   (
			   ACCOUNT_NUMBER: GENERATED AUTOMATICALLY AFTER KYC_STATUS IN Account_opening_form TABLE IS SET TO 'APPROVED'

			   ACCOUNT_TYPE: AUTOMATICALLY INSERTED AFTER ONLY KYC_STATUS IS APPROVED

			   ACCOUNT_OPENING_DATE: AUTOMATICALLY INSERTED AFTER ONLY KYC_STATUS IS APPROVED

			   CURRENT_BALANCE: AUTOMATICALLY INSERTED AFTER ONLY KYC_STATUS IS APPROVED + IT WILL BE UPDATED BASED UPON THE 
								TRANSACTION_DETAILS TABLE.
			   )



			3. ACCOUNT_HOLDER_DETAILS
			   ( 
			   ACCOUNT_NUMBER: GENERATED AUTOMATICALLY AFTER KYC_STATUS IN Account_opening_form TABLE IS 'APPROVED'

			   ACCOUNT_HOLDER_NAME: AUTOMATICALLY INSERTED FROM Account_opening_form TABLE AFTER ONLY KYC_STATUS IS APPROVED

			   DOB: AUTOMATICALLY INSERTED FROM Account_opening_form TABLE AFTER ONLY KYC_STATUS IS APPROVED 

			   AADHAR_NUMBER: AUTOMATICALLY INSERTED FROM Account_opening_form TABLE AFTER ONLY KYC_STATUS IS APPROVED 

			   MOBILE_NUMBER: AUTOMATICALLY INSERTED FROM Account_opening_form TABLE AFTER ONLY KYC_STATUS IS APPROVED
			   )

			4. TRANSACTION_DETAILS
			   (
			   ACCOUNT_NUMBER:
			   
			   PAYMENT_TYPE, 

			   TRANSACTION_AMOUNT,
			   
			   DATE_OF_TRANSACTION
			   )

			   */


create table TBL_Account_opening (
	ID int primary key identity(1,1),
	"DATE" datetime default getdate(),
	ACCOUNT_TYPE varchar(20) default 'Savings',
	ACCOUNT_HOLDER_NAME varchar(50),
	DOB date,
	AADHAR_NUMBER varchar(12) unique,
	MOBILE varchar(15), 
	OPENING_BALANCE decimal(10, 2) check (OPENING_BALANCE>=1000),
	"ADDRESS" varchar(100),
	KYC_STATUS varchar(20) default 'PENDING'
);

select * from TBL_Account_opening;

create table TBL_Bank(
	Acc_num bigint primary key identity(1000001, 1), 
	Tyoe varchar(20),
	Opening_date date,
	Curr_Balance decimal(10, 2)
);

select * from TBL_Bank;

create table TBL_ACCOUNT_HOLDER_DETAILS (
	Acc_num bigint primary key ,
	ACCOUNT_HOLDER_NAME varchar(20),
	DOB date,
	AADHAR varchar(12),
	Mobile varchar(15)
	foreign key (Acc_num) references TBL_Bank (Acc_num)
);

alter table TBL_ACCOUNT_HOLDER_DETAILS
add Address_Holder varchar(100);

Drop table TBL_ACCOUNT_HOLDER_DETAILS;
select * from TBL_ACCOUNT_HOLDER_DETAILS;

create table TBL_Transactions(
	Sr int primary key Identity(1, 1),
	Acc_num bigint, -- it will not give the error since it is a foreign key
	Payment_type varchar(20),
	Amount decimal(10, 2),
	Date_of_t date
	-- foreign key is been made through ER- DIAGRAM ;)
);

drop table TBL_Transactions;

--select dateadd(month, 4, getdate()) : gives the data of past 4 months

-----------------------------TRIGGER TO AUTOMATE THE INDERTION OF BANK TABLE AND DETAILS TABLE ----------------------------------------

alter trigger TR_Bank1 
on TBL_Account_opening 
after update
as 
begin
	declare 
	@Acname varchar(20),
	@Balance decimal(10, 2),
	@dob date,
	@adha varchar(12),
	@mb varchar(15),
	@Type varchar(20),
	@odate date,
	@addr varchar(100),
	@kyc varchar(20),
	@acnum bigint

	select @Acname=ACCOUNT_HOLDER_NAME, @Balance=OPENING_BALANCE, @dob=DOB, @adha=AADHAR_NUMBER, @mb=MOBILE, @Type = ACCOUNT_TYPE, @odate="DATE", @addr="ADDRESS", @kyc=KYC_STATUS from inserted;

	if @kyc = 'APPROVED'
		begin
			insert into TBL_Bank values (@Type, @odate, @Balance)
			select @acnum=Acc_num from TBL_Bank;
			insert into TBL_ACCOUNT_HOLDER_DETAILS (Acc_num ,ACCOUNT_HOLDER_NAME, DOB, AADHAR, Mobile, Address_Holder) values (@acnum, @Acname, @dob, @adha, @mb, @addr);
		end
end


insert into TBL_Account_opening (ACCOUNT_HOLDER_NAME,DOB, AADHAR_NUMBER, MOBILE, OPENING_BALANCE, "ADDRESS") values ('Shubham', '2003-10-30', '123456789', '7061162454', 1000.50, 'Kharar');


update TBL_Account_opening 
set KYC_STATUS='APPROVED'
where ACCOUNT_HOLDER_NAME='Gaurav';


--------------------------TRIGGER TO UPDATE THE BANK TABLE ON THE BASIS OF TRANSACTION-----------------------------------------

alter trigger TR_transact
on TBL_Transactions
after insert 
as
begin
	declare
		@acnum bigint,
		@ptype varchar(20),
		@Amou decimal(10,2),
		@curr decimal(10, 2)
		select @acnum=Acc_num, @ptype=Payment_type, @Amou=Amount from inserted;
		select @curr=Curr_Balance from TBL_Bank where Acc_num=@acnum;
		if @ptype='CREDIT'
			begin
				update TBL_Bank
				set Curr_Balance=(@curr+@Amou)
				where Acc_num=@acnum;
			end

		if @ptype='DEBIT'
			begin
				begin try
					begin transaction
					save transaction sv9;
					update TBL_Bank
					Set Curr_Balance=@curr-@Amou
					where Acc_num=@acnum

					select @curr=Curr_Balance from TBL_Bank where @acnum=Acc_num
					if @curr< 0
						begin
							throw 51000,'error', 1
						end
					commit transaction
				end try

				begin catch 
					print 'You are Trying Something not possible Buddy'
					rollback transaction sv9;
				end catch
			end
end				

/*
alter trigger TR_transact
on TBL_Transactions
after insert 
as
begin
	declare
		@acnum bigint,
		@ptype varchar(20),
		@Amou decimal(10,2),
		@curr decimal(10, 2)
		select @acnum=Acc_num, @ptype=Payment_type, @Amou=Amount from inserted;
		select @curr=Curr_Balance from TBL_Bank;
		if @ptype='CREDIT'
			begin
				update TBL_Bank
				set Curr_Balance=(@curr+@Amou)
				where Acc_num=@acnum;
			end

		if @ptype='DEBIT'
			begin
				update TBL_Bank
					Set Curr_Balance=@curr-@Amou
					where Acc_num=@acnum

					select @curr=Curr_Balance from TBL_Bank where @acnum=Acc_num

					if @curr < 0
						begin
						print 'You are Trying Something not possible Buddy'
							update TBL_Bank
							Set Curr_Balance=@curr+@Amou
							where Acc_num=@acnum
						end
			end
end			

*/

select * from TBL_Transactions;

select * from TBL_BAnk;

insert into TBL_Transactions values (1000006, 'CREDIT', 10065,getdate());

insert into TBL_Transactions values (1000006, 'DEBIT', 12065.00,getdate());

---------------------------------TRIGGER TO DELETE THE FORM IF AN USER'S KYC GET REJECTED--------------------------------------

alter trigger TR_Reject
on TBL_Account_opening
after update 
as
begin 
	declare @idis int,
	@status varchar(20)

	select @idis=ID, @status=KYC_STATUS from inserted

	if @status='REJECTED'
		begin
			delete from TBL_Account_opening where ID=@idis
		end
end


insert into TBL_Account_opening (ACCOUNT_HOLDER_NAME,DOB, AADHAR_NUMBER, MOBILE, OPENING_BALANCE, "ADDRESS") values ('Bhumika', '2005-03-05', '123836789', '7098162454', 1000.50, 'Kharar');
insert into TBL_Account_opening (ACCOUNT_HOLDER_NAME,DOB, AADHAR_NUMBER, MOBILE, OPENING_BALANCE, "ADDRESS") values ('Ratnesh', '2003-10-30', '12340986789', '7261162454', 1000.50, 'Kharar');
insert into TBL_Account_opening (ACCOUNT_HOLDER_NAME,DOB, AADHAR_NUMBER, MOBILE, OPENING_BALANCE, "ADDRESS") values ('Gaurav', '2003-10-30', '12345689', '7061162454', 1000.50, 'Kharar');


select * from TBL_Account_opening ;

update TBL_Account_opening 
set KYC_STATUS='APPROVED'
where ACCOUNT_HOLDER_NAME='Bhumika'

select * from TBL_BAnk
select * from TBL_ACCOUNT_HOLDER_DETAILS

update TBL_Account_opening 
set KYC_STATUS='REJECTED'
where ACCOUNT_HOLDER_NAME='Ratnesh'


-------------------PROCEDURE------------------------

-- Procedure which retrieve logs of a particular account number like a PASSBOOK

create procedure FN_PASSBOOK
@acnum bigint
as 
begin
	select * from TBL_Transactions
	where Acc_num = @acnum
end 


execute FN_PASSBOOK 1000004;


--------------------------------FUNCTION THAT WILL GIVE THE LOG OF ALL THE TRANSACTION THAT HAPPENED IN LAST FIXED MONTHS FROM A PARTICULAR ACCOUNT----------------------------------

create function FN_LOG(@months int)
returns table
as 
return( select * from TBL_Transactions
		where Date_of_t >= dateadd(month, @months, getdate()) 
		);


select * from dbo.FN_LOG(-1);


-----------------------------PROCEDURE FOR SAME ^_| AS ABOVE BUT RETURN IN DAYS AND ACCORDING TO THE ACC NUM------------------------------------

alter procedure PR_LOG
@months int , 
@acnum bigint
as 
begin
	select * from TBL_Transactions
		where Date_of_t >= dateadd(DAY, @months, getdate())  and Acc_num=@acnum
end

execute PR_LOG -8, 1000005;

insert into TBL_Transactions values (1000006, 'CREDIT', 12065,getdate());
insert into TBL_Transactions values (1000006, 'CREDIT', 12065,dateadd(DAY, -4, getdate()));
insert into TBL_Transactions values (1000006, 'CREDIT', 12065,dateadd(DAY, -6, getdate()));
insert into TBL_Transactions values (1000006, 'CREDIT', 12065,dateadd(DAY, -8, getdate()));

delete from TBL_Transactions where Acc_num=1000005



-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
----------------------------------------------           --------------------------------------------------
---------------------------------------------- COMPLETED --------------------------------------------------
----------------------------------------------           --------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
