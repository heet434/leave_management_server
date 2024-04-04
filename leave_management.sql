-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Apr 04, 2024 at 03:54 PM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `leave_management`
--

DELIMITER $$
--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `calculate_leave_percentage` (`student_id` INT) RETURNS DECIMAL(5,2)  BEGIN
    DECLARE total_leaves INT;
    DECLARE total_student_leaves INT;
    DECLARE total_working_days INT;
    DECLARE leave_percent DECIMAL(5,2);  
    SELECT COUNT(*) INTO total_leaves FROM leaves;
    SELECT COUNT(*) INTO total_student_leaves FROM leaves WHERE user_id = student_id AND user_role = 'student';
    SELECT working_days INTO total_working_days FROM semesters;   
    IF total_working_days > 0 THEN
        SET leave_percent = (total_student_leaves / total_working_days) * 100;
    ELSE
        SET leave_percent = 0;
    END IF;  
    RETURN leave_percent;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `attendance`
--

CREATE TABLE `attendance` (
  `attendance_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `course_code` varchar(50) DEFAULT NULL,
  `attendance_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `auth`
--

CREATE TABLE `auth` (
  `user_id` int(11) NOT NULL,
  `passwd` varchar(255) NOT NULL,
  `role` enum('student','course instructor','admin') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `auth`
--

INSERT INTO `auth` (`user_id`, `passwd`, `role`) VALUES
(0, '12345678', 'student'),
(0, '12345678', 'course instructor'),
(0, 'abcd1234', 'admin');

--
-- Triggers `auth`
--
DELIMITER $$
CREATE TRIGGER `delete_course_instructor_on_auth_delete` AFTER DELETE ON `auth` FOR EACH ROW BEGIN
    IF OLD.role = 'course instructor' THEN
        DELETE FROM course_instructors WHERE rg_no = OLD.user_id;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `delete_student_on_auth_delete` AFTER DELETE ON `auth` FOR EACH ROW BEGIN
    IF OLD.role = 'student' THEN
        DELETE FROM students WHERE roll_no = OLD.user_id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `courses`
--

CREATE TABLE `courses` (
  `course_code` varchar(50) NOT NULL,
  `course_title` varchar(255) DEFAULT NULL,
  `semester_type` enum('winter','monsoon') NOT NULL,
  `semester_year` year(4) NOT NULL,
  `instructor_rg_no` int(11) NOT NULL,
  `total_students` int(11) DEFAULT NULL,
  `total_lectures` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `courses`
--

INSERT INTO `courses` (`course_code`, `course_title`, `semester_type`, `semester_year`, `instructor_rg_no`, `total_students`, `total_lectures`) VALUES
('DA214', 'DBMS', 'winter', '2024', 0, 30, 42);

-- --------------------------------------------------------

--
-- Table structure for table `course_instructors`
--

CREATE TABLE `course_instructors` (
  `rg_no` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `dept` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `course_instructors`
--

INSERT INTO `course_instructors` (`rg_no`, `name`, `dept`) VALUES
(0, 'Course Instructor 0', 'DSAI');

-- --------------------------------------------------------

--
-- Table structure for table `holidays`
--

CREATE TABLE `holidays` (
  `holiday_id` int(11) NOT NULL,
  `holiday_date` date DEFAULT NULL,
  `reason` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `leaves`
--

CREATE TABLE `leaves` (
  `leave_id` int(11) NOT NULL,
  `leave_date` date NOT NULL,
  `reason` text NOT NULL,
  `user_id` int(11) NOT NULL,
  `user_role` enum('student','course_instructor') NOT NULL,
  `status` enum('accepted','pending','rejected') NOT NULL DEFAULT 'pending',
  `course_code` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `leaves`
--

INSERT INTO `leaves` (`leave_id`, `leave_date`, `reason`, `user_id`, `user_role`, `status`, `course_code`) VALUES
(2, '2024-03-31', 'bla', 0, 'student', 'accepted', 'DA214'),
(3, '2024-03-30', 'bla', 0, 'student', 'accepted', 'DA214'),
(4, '2024-03-27', 'nn', 0, 'student', 'accepted', 'DA214'),
(5, '2024-03-04', 'bitty', 0, 'student', 'pending', 'DA214'),
(6, '2024-03-05', 'nitty', 0, 'student', 'pending', 'DA214');

--
-- Triggers `leaves`
--
DELIMITER $$
CREATE TRIGGER `update_leave_percent_upon_deletion` AFTER DELETE ON `leaves` FOR EACH ROW BEGIN
    DECLARE total_leave_days INT;
    DECLARE total_lectures INT;
    DECLARE leave_percent DECIMAL(5, 2);
    
    -- Calculate total leave days for the student in the course
    SELECT COUNT(*) INTO total_leave_days
    FROM leaves
    WHERE leaves.user_id = OLD.user_id AND leaves.user_role = 'student' AND leaves.course_code = OLD.course_code;
    
    -- Calculate total lectures for the course
    SELECT courses.total_lectures INTO total_lectures
    FROM courses
    WHERE courses.course_code = OLD.course_code;
    
    -- Calculate leave percentage
    IF total_lectures > 0 THEN
        SET leave_percent = (total_leave_days / total_lectures) * 100;
    ELSE
        SET leave_percent = 0;
    END IF;
    
    -- Update leave_percentage column in the student_enrollment table
    UPDATE student_enrollment
    SET student_enrollment.leave_percentage = leave_percent
    WHERE student_enrollment.roll_no = OLD.user_id AND student_enrollment.course_code = OLD.course_code;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_leave_percentage_after_leave_insert` AFTER INSERT ON `leaves` FOR EACH ROW BEGIN
    DECLARE total_leave_days INT;
    DECLARE total_lectures INT;
    DECLARE leave_percent DECIMAL(5, 2);
    
    -- Calculate total leave days for the student in the course
    SELECT COUNT(*) INTO total_leave_days
    FROM leaves
    WHERE leaves.user_id = NEW.user_id AND leaves.user_role = 'student' AND leaves.course_code = NEW.course_code;
    
    -- Calculate total lectures for the course
    SELECT courses.total_lectures INTO total_lectures
    FROM courses
    WHERE courses.course_code = NEW.course_code;
    
    -- Calculate leave percentage
    IF total_lectures > 0 THEN
        SET leave_percent = (total_leave_days / total_lectures) * 100;
    ELSE
        SET leave_percent = 0;
    END IF;
    
    -- Update leave_percentage column in the student_enrollment table
    UPDATE student_enrollment
    SET student_enrollment.leave_percentage = leave_percent
    WHERE student_enrollment.roll_no = NEW.user_id AND student_enrollment.course_code = NEW.course_code;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `semesters`
--

CREATE TABLE `semesters` (
  `semester_type` enum('winter','monsoon') NOT NULL,
  `year` year(4) NOT NULL,
  `total_working_days` int(11) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `semesters`
--

INSERT INTO `semesters` (`semester_type`, `year`, `total_working_days`, `start_date`, `end_date`) VALUES
('winter', '2024', 100, '2024-01-01', '2024-05-06');

-- --------------------------------------------------------

--
-- Table structure for table `students`
--

CREATE TABLE `students` (
  `roll_no` int(9) NOT NULL,
  `name` varchar(255) NOT NULL,
  `branch` varchar(255) DEFAULT NULL,
  `stream` varchar(255) DEFAULT NULL,
  `joining_year` year(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`roll_no`, `name`, `branch`, `stream`, `joining_year`) VALUES
(0, 'Student 0', 'DSAI', 'BTech', '2022');

-- --------------------------------------------------------

--
-- Table structure for table `student_enrollment`
--

CREATE TABLE `student_enrollment` (
  `roll_no` int(11) DEFAULT NULL,
  `course_code` varchar(50) DEFAULT NULL,
  `leave_percentage` decimal(5,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `student_enrollment`
--

INSERT INTO `student_enrollment` (`roll_no`, `course_code`, `leave_percentage`) VALUES
(0, 'DA214', 11.90);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `attendance`
--
ALTER TABLE `attendance`
  ADD PRIMARY KEY (`attendance_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `course_code` (`course_code`);

--
-- Indexes for table `auth`
--
ALTER TABLE `auth`
  ADD PRIMARY KEY (`user_id`,`role`) USING BTREE;

--
-- Indexes for table `courses`
--
ALTER TABLE `courses`
  ADD PRIMARY KEY (`course_code`),
  ADD KEY `instructor_rg_no` (`instructor_rg_no`);

--
-- Indexes for table `course_instructors`
--
ALTER TABLE `course_instructors`
  ADD PRIMARY KEY (`rg_no`);

--
-- Indexes for table `holidays`
--
ALTER TABLE `holidays`
  ADD PRIMARY KEY (`holiday_id`);

--
-- Indexes for table `leaves`
--
ALTER TABLE `leaves`
  ADD PRIMARY KEY (`leave_id`),
  ADD KEY `user_id` (`user_id`,`user_role`),
  ADD KEY `fk_course_code` (`course_code`);

--
-- Indexes for table `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`roll_no`);

--
-- Indexes for table `student_enrollment`
--
ALTER TABLE `student_enrollment`
  ADD KEY `roll_no` (`roll_no`),
  ADD KEY `course_code` (`course_code`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `attendance`
--
ALTER TABLE `attendance`
  MODIFY `attendance_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `holidays`
--
ALTER TABLE `holidays`
  MODIFY `holiday_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `leaves`
--
ALTER TABLE `leaves`
  MODIFY `leave_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `attendance`
--
ALTER TABLE `attendance`
  ADD CONSTRAINT `attendance_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `students` (`roll_no`),
  ADD CONSTRAINT `attendance_ibfk_2` FOREIGN KEY (`course_code`) REFERENCES `courses` (`course_code`);

--
-- Constraints for table `courses`
--
ALTER TABLE `courses`
  ADD CONSTRAINT `courses_ibfk_1` FOREIGN KEY (`instructor_rg_no`) REFERENCES `course_instructors` (`rg_no`);

--
-- Constraints for table `leaves`
--
ALTER TABLE `leaves`
  ADD CONSTRAINT `fk_course_code` FOREIGN KEY (`course_code`) REFERENCES `courses` (`course_code`),
  ADD CONSTRAINT `leaves_ibfk_1` FOREIGN KEY (`user_id`,`user_role`) REFERENCES `auth` (`user_id`, `role`);

--
-- Constraints for table `student_enrollment`
--
ALTER TABLE `student_enrollment`
  ADD CONSTRAINT `student_enrollment_ibfk_1` FOREIGN KEY (`roll_no`) REFERENCES `students` (`roll_no`),
  ADD CONSTRAINT `student_enrollment_ibfk_2` FOREIGN KEY (`course_code`) REFERENCES `courses` (`course_code`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
