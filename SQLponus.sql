if db_id('student_attendance_system') is not null
drop database student_attendance_system;
go

create database student_attendance_system;
go

use student_attendance_system;
go

create table departments (
    dept_id     int primary key identity(1,1),
    dept_name   varchar(100) not null unique,
    location    varchar(100)
);
go

create table instructors (
    instructor_id   int primary key identity(1,1),
    full_name       varchar(100) not null,
    email           varchar(100) not null unique,
    dept_id         int not null,

    foreign key (dept_id)
    references departments(dept_id)
);
go

create table courses (
    course_id       int primary key identity(1,1),
    course_code     varchar(20) not null unique,
    title           varchar(100) not null,
    credits         int not null,
    dept_id         int not null,

    foreign key (dept_id)
    references departments(dept_id)
);
go

create table students (
    student_id      int primary key identity(1,1),
    full_name       varchar(100) not null,
    email           varchar(100) not null unique,
    dob             date not null,
    dept_id         int not null,

    foreign key (dept_id)
    references departments(dept_id)
);
go

create table enrollment (
    enrollment_id   int primary key identity(1,1),
    student_id      int not null,
    course_id       int not null,
    enroll_date     date not null,

    unique(student_id, course_id),

    foreign key (student_id)
    references students(student_id),

    foreign key (course_id)
    references courses(course_id)
);
go

create table sessions (
    session_id      int primary key identity(1,1),
    course_id       int not null,
    instructor_id   int not null,
    session_date    date not null,
    start_time      time not null,

    foreign key (course_id)
    references courses(course_id),

    foreign key (instructor_id)
    references instructors(instructor_id)
);
go

create table attendance (
    attendance_id   int primary key identity(1,1),
    session_id      int not null,
    student_id      int not null,
    status          varchar(10) not null
                    check (status in ('present','absent','late')),

    unique(session_id, student_id),

    foreign key (session_id)
    references sessions(session_id),

    foreign key (student_id)
    references students(student_id)
);
go

-- indexes
create index idx_students_email
on students(email);

create index idx_attendance_student
on attendance(student_id);

create index idx_sessions_course
on sessions(course_id);
go

insert into departments (dept_name, location)
values
('computer science', 'block a'),
('mathematics', 'block b'),
('physics', 'block c');
go

insert into instructors (full_name, email, dept_id)
values
('dr. sara ahmed', 'sara.ahmed@uni.edu', 1),
('dr. omar hassan', 'omar.hassan@uni.edu', 2),
('dr. lena malik', 'lena.malik@uni.edu', 1);
go

insert into courses (course_code, title, credits, dept_id)
values
('cs101', 'intro to programming', 3, 1),
('cs201', 'database systems', 3, 1),
('ma101', 'calculus i', 3, 2),
('ph101', 'general physics', 3, 3);
go

insert into students (full_name, email, dob, dept_id)
values
('ali hassan', 'ali.hassan@student.edu', '2003-05-10', 1),
('nour salem', 'nour.salem@student.edu', '2002-11-22', 1),
('rami khalil', 'rami.khalil@student.edu', '2003-08-15', 2),
('sara youssef', 'sara.youssef@student.edu', '2004-01-30', 1),
('layla nasser', 'layla.nasser@student.edu', '2002-07-05', 3);
go

insert into enrollment (student_id, course_id, enroll_date)
values
(1,1,'2024-09-01'),
(1,2,'2024-09-01'),
(2,1,'2024-09-01'),
(2,2,'2024-09-01'),
(3,3,'2024-09-01'),
(4,1,'2024-09-01'),
(4,2,'2024-09-01'),
(5,4,'2024-09-01');
go

insert into sessions (course_id, instructor_id, session_date, start_time)
values
(1,1,'2024-09-10','09:00:00'),
(1,1,'2024-09-12','09:00:00'),
(2,3,'2024-09-11','11:00:00'),
(3,2,'2024-09-10','10:00:00');
go

insert into attendance (session_id, student_id, status)
values
(1,1,'present'),
(1,2,'absent'),
(1,4,'present'),
(2,1,'late'),
(2,2,'present'),
(2,4,'absent'),
(3,1,'present'),
(3,2,'present'),
(3,4,'late'),
(4,3,'present');
go

-- trigger
create trigger trg_prevent_duplicate_attendance
on attendance
instead of insert
as
begin

    if exists (
        select 1
        from attendance a
        join inserted i
        on a.session_id = i.session_id
        and a.student_id = i.student_id
    )
    begin
        print 'duplicate attendance is not allowed';
    end

    else
    begin
        insert into attendance(session_id, student_id, status)
        select
            session_id,
            student_id,
            status
        from inserted;
    end

end;
go

--  stored procedure
create procedure sp_calculate_attendance_percentage
@student_id int
as
begin

    select
        s.full_name,
        count(a.attendance_id) as total_sessions,

        sum(
            case
                when a.status = 'present'
                then 1
                else 0
            end
        ) as present_count,
--%
        round(
            sum(
                case
                    when a.status = 'present'
                    then 1
                    else 0
                end
            ) * 100.0 / count(a.attendance_id),
            2
        ) as attendance_percentage

    from students s
    join attendance a
    on s.student_id = a.student_id

    where s.student_id = @student_id

    group by s.full_name;

end;
go
--view
create view vw_student_attendance_report as
select
    s.student_id,
    s.full_name,
    c.title as course,
    ss.session_date,
    a.status
from students s
join attendance a
on s.student_id = a.student_id
join sessions ss
on a.session_id = ss.session_id
join courses c
on ss.course_id = c.course_id;
go
--viewww
create view vw_student_basic_info as
select
    student_id,
    full_name,
    dept_id
from students;
go

update students
set email = 'ali.h.new@student.edu'
where student_id = 1;
go

update attendance
set status = 'present'
where session_id = 1
and student_id = 2;
go

--             transaction


begin transaction;

begin try

    insert into enrollment(student_id, course_id, enroll_date)
    values (3,2,'2024-09-15');

    insert into attendance(session_id, student_id, status)
    values (3,3,'present');

    commit transaction;

    print 'transaction completed successfully';

end try

begin catch

    rollback transaction;

    print 'transaction failed';

end catch;
go

delete from attendance
where session_id in (
    select session_id
    from sessions
    where course_id = 4
)
and student_id = 5;
go

delete from enrollment
where student_id = 5
and course_id = 4;
go

select
    s.full_name as student,
    c.title as course,
    ss.session_date,
    a.status
from attendance a
join students s
on a.student_id = s.student_id
join sessions ss
on a.session_id = ss.session_id
join courses c
on ss.course_id = c.course_id
order by ss.session_date;
go

select
    s.full_name,
    count(a.attendance_id) as total_records
from students s
left join attendance a
on s.student_id = a.student_id
group by s.student_id, s.full_name;
go

select
    c.title,
    count(e.student_id) as enrolled
from courses c
join enrollment e
on c.course_id = e.course_id
group by c.course_id, c.title
having count(e.student_id) > 2;
go

select
    s.full_name,
    count(a.attendance_id) as total_sessions,
    sum(case when a.status = 'present' then 1 else 0 end) as present_count,
    round(
        sum(case when a.status = 'present' then 1 else 0 end) * 100.0
        / count(a.attendance_id),
        2
    ) as attendance_percentage
from students s
join attendance a
on s.student_id = a.student_id
group by s.student_id, s.full_name;
go

select
    max(cnt) as max_attendees,
    min(cnt) as min_attendees
from (
    select
        session_id,
        count(*) as cnt
    from attendance
    where status = 'present'
    group by session_id
) sub;
go

select avg(credits) as average_credits
from courses;
go

select full_name, email
from students
where student_id in (
    select a.student_id
    from attendance a
    group by a.student_id
    having
    sum(case when a.status = 'present' then 1 else 0 end) * 100.0
    / count(*) < 60
);
go

exec sp_calculate_attendance_percentage 1;
go

select *
from vw_student_attendance_report;
go

select *
from vw_student_basic_info;
go