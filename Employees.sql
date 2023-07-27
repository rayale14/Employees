
--Select the employee numbers of all individuals who have signed more than 1 contract after the 1st of January 2000.
```sql
use employees;
Select emp_no
from dept_emp
where from_date >'2000-01-01'
group by 1
having count(from_date) > 1
order by emp_no;
```

--Select the first and last name, the hire date, and the job title of all employees whose first name is “Margareta” and have the last name “Markovitch”.

Select e.first_name, e.last_name, e.hire_date, t.titles
from employees e 
join titles t on e.emp_no = t.emp_no
where first_name = 'Margareta' and last_name = 'Markovitch'
order by e.emp_no;


--Select all manager's infomation (name,hiredate,titlejob,dept,contractdate)

Select e.first_name, e.last_name, e.hire_date, t.title, t.from_date,d.dept_name
from
    employees e
        join
    dept_manager dm ON e.emp_no = dm.emp_no
        join
    titles t ON dm.emp_no = t.emp_no
        join
    departments d ON d.dept_no = dm.dept_no
    where title="manager"
order by dm.emp_no;


--Avg salary for each dept_manager

Select d.dept_name,avg(salary) as avg_dept
from dept_manager dm join salaries s on dm.emp_no=s.emp_no
join departments d on d.dept_no=dm.dept_no
group by 1;


--Extract the information about all department managers who were hired between the 1st of January 1990 and the 1st of January 1995.

Select e.*
from employees e
where e.emp_no in
    (Select m.emp_no
        from dept_manager m
        where m.from_date >= 1990 - 01 - 01 and m.to_date <= 1995 - 01 - 01);


--Extract a dataset containing infor about the managers: employee number, first name, and last name. Add two columns, one showing the difference between the maximum and minimum salary of that employee, another one saying whether this salary raise was higher than $30,000 or NOT.

select e.emp_no, e.first_name, e.last_name, max(s.salary)-min(s.salary) as salary_difference,
    case when max(s.salary)-min(s.salary)>30000 then "YES" else "NO"
    end as "Difference_higher_than_30000"
    from employees e join dept_manager dm on e.emp_no=dm.emp_no
    join salaries s on dm.emp_no=s.emp_no
    group by dm.emp_no;

--Extract the employee number, first name, and last name of the 1st 100 employees, and add a 4th column which called “current_employee” saying their working status.

select e.emp_no, e.first_name, e.last_name,
    case when max(d.to_date)>sysdate() then "Is still employed" else "Not an employee anymore"
    end as "current_employee"
    from employees e join dept_emp d on e.emp_no=d.emp_no
    group by 1
    limit 100;


--Find out the second-lowest salary value each employee has ever signed a contract for.

select a.emp_no, a.salary as min_salary from
(select emp_no, salary, row_number() over w as row_num
from employees.salaries
window w as (partition by emp_no order by salary asc)) a
where a.row_num=2;


--Consider the employees' contracts that have been signed after the 1st of January 2000 and terminated before the 1st of January 2002 (as registered in the "dept_emp" table).
--Query contains employee number, the salary values of the latest contracts they have signed during the suggested time period,the department they have been working in,the average salary paid in the department the employee was last working in during the suggested time period.

Select de2.emp_no, d.dept_name, s2.salary, avg(s2.salary) over w as average_salary_per_department
from 
(select de.emp_no, de.dept_no, de.from_date, de.to_date from dept_emp de join
(select emp_no, max(from_date) as from_date from dept_emp group by emp_no) de1
on de.emp_no=de1.emp_no
where de.from_date>"2000-01-01" and de.to_date<"2002-01-01" and de1.from_date=de.from_date) de2

join 
(select s1.emp_no, s.salary, s.from_date, s.to_date from salaries s join
(select emp_no, max(from_date) as from_date from salaries group by emp_no) s1
on s.emp_no=s1.emp_no
where s.from_date>"2000-01-01" and s.to_date<"2002-01-01" and s1.from_date=s.from_date) s2
on s2.emp_no=de2.emp_no

join 
departments d on d.dept_no=de2.dept_no
group by de2.emp_no, d.dept_name
window w as(partition by de2.dept_no)
order by de2.emp_no, salary;


--obtain the number of male employees whose highest salaries have been below the all-time average.

with 
cte1 as(select avg(salary) as avg_salary from salaries),
cte2 as(select e.emp_no, max(s.salary) as m_highest_salary from employees e 
join salaries s on e.emp_no=s.emp_no
and e.gender="M" 
group by e.emp_no)

select 
count(case when cte1.avg_salary>cte2.m_highest_salary then cte2.m_highest_salary else NULL end) as no_m_salaries_below_avg
from cte2 
join cte1;
