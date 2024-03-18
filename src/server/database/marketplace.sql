-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 18, 2024 at 05:39 PM
-- Server version: 10.4.27-MariaDB
-- PHP Version: 8.2.0

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `marketplace`
--

-- --------------------------------------------------------

--
-- Table structure for table `accounts`
--

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL,
  `ProfilePicture` varchar(255) NOT NULL,
  `first_name` varchar(255) NOT NULL,
  `last_name` varchar(255) NOT NULL,
  `username` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone_number` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `token` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `accounts`
--

INSERT INTO `accounts` (`id`, `ProfilePicture`, `first_name`, `last_name`, `username`, `email`, `phone_number`, `password`, `token`) VALUES
(2, '2024-02-29-20-57-01-c6ccfdb0-9533-4426-a525-c7dfbf965887.jpg', 'Jun Kit', 'Chee', 'ambatukam', 'chee.jk@gmail.com', '0172335460', '$2b$10$KlvybXG4Nhnpjk.hdVlRKuW2mB2sWinZIyxgjfCWFX/IQyjx5NB/C', ''),
(6, '2024-02-29-20-39-35-49d1b46d-6611-4366-bb41-3cd96916e7c1.jpg', 'test', 'test', 'test', 'test@gmail.com', '0172335460', '$2b$10$2ldFdPN9WOYxwMN/lHGnKuR3VqGWimjdGKx8PbOYMMLdJJTYG2PLe', ''),
(7, '2024-02-28-20-15-58-135ac730-60d4-459e-94f2-2788cc87da4e.jpg', 'test', 'test', 'test1', 'test@test.com', '0123456789', '$2b$10$.U6LUcQH7qbKWRz592s51Ocla4tF.HvaZlvIa6rTSiMPZdQYb4lcG', ''),
(8, '', 'John', 'Doe', 'John Doe', 'abc123@gmail.com', '0135679875', '$2b$10$lUnTF5mXqI7KfZs9Et/qtuuVAvNGllynJyH9wBe3nWK7wM5vN5FqO', ''),
(16, '', 'a', 'bc', 'abc', 'a@gmail.com', '123', '$2b$10$D1ZyFBsNODDqjn4dArbDs.wvEUIinvr1fASYRkd1Pphcr5BWj09zK', ''),
(17, '', 'Gary', 'Chong', 'GaryChong', 'GaryChong123@gmail.com', '5838752832', '$2b$10$qSyeTsQ0Y470Q4ngmfI6Mu/x5AowwOke3bbatszeJbSTGGvWVLDXG', ''),
(18, '', 'agfdgkgk', 'kfgkfgk', 'fgkgrytiyu', 'fdgjyuiyukm@gmail.com', '76734726785', '$2b$10$ISyxGHot/mI.5sqDCTM2huSO2CapCwTZFy/LMhWHEzJXZpUMirAb2', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZmdrZ3J5dGl5dSJ9.s_bXhCe-gr0o2gi6Pg8WkCQ9fiXStxrRLenxxdQK_3Y');

-- --------------------------------------------------------

--
-- Table structure for table `listing`
--

CREATE TABLE `listing` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `ImageID` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `ContactDescription` varchar(255) NOT NULL,
  `postedDate` timestamp NOT NULL DEFAULT current_timestamp(),
  `PostedBy` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `listing`
--

INSERT INTO `listing` (`id`, `title`, `ImageID`, `description`, `price`, `category`, `ContactDescription`, `postedDate`, `PostedBy`) VALUES
(71, 'Trek Slash 8', '2024-02-20-10-17-33-9d76f785-6da4-48e9-862b-222cd68fc611.jpg', 'Slash 8 is an enduro mountain bike that rolls on fast 29er wheels and floats on plush RockShox suspension with SRAM\'s newest GX Eagle handling drivetrain duties. An aluminum frame with fresh new tech and tough alloy wheels push this bike into the sweet spot for all-around rippers.', '14000.00', 'Sports equipment', '', '2024-02-20 02:17:33', 'ambatukam'),
(72, 'Toyota Camry', '2024-02-20-10-20-43-60876b07-1ee5-4b1d-af5b-f3c817223097.jpg', 'The New Camry is powered by a new 2.5 L engine with higher engine output and combustion effciency to exude absolute power on the road.', '190000.00', 'Vehicles', '', '2024-02-20 02:20:43', 'ambatukam'),
(73, 'Basketball for sale', '2024-02-20-10-21-35-be52859e-9e4a-48cf-a291-efc2ffbd619e.jpg', 'Basketball is a team sport in which two teams, most commonly of five players each, opposing one another on a rectangular court, compete with the primary objective of shooting a basketball (approximately 9.4 inches (24 cm) in diameter) through the defender\'s hoop (a basket 18 inches (46 cm) in diameter mounted 10 feet (3.048 m) high to a backboard at each end of the court), while preventing the opposing team from shooting through their own hoop. A field goal is worth two points, unless made from behind the three-point line, when it is worth three. After a foul, timed play stops and the player fouled or designated to shoot a technical foul is given one, two or three one-point free throws. The team with the most points at the end of the game wins, but if regulation play expires with the score tied, an additional period of play (overtime) is mandated.', '50.00', 'Sports equipment', '', '2024-02-20 02:21:34', 'ambatukam'),
(81, 'test', '2024-02-27-22-23-29-1d1b8404-fee5-4b75-a93c-a44a37f2d871.jpg', 'test', '0.00', 'Books', '', '2024-02-27 14:23:12', 'test'),
(82, 'Ipad For Sale', '2024-03-03-13-50-02-63e61922-e14b-45cc-bb57-26c9bceaa812.jpg', 'Ipad for sale to students in need as I will be Graduating', '2500.00', 'Electronics', '', '2024-03-03 05:50:02', 'test1'),
(83, 'qwdqwdqdwqdqwdqwd', '2024-03-03-14-15-16-b7a7c1de-63f2-4123-abe7-fc1ec7971bf2.jpg', 'qdqqwdqwdqwdqwdqwdq', '12312312.00', 'Vehicles', 'Call eqwhfwehfoiu', '2024-03-03 06:06:41', 'ambatukam');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `listing`
--
ALTER TABLE `listing`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `listing`
--
ALTER TABLE `listing`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=84;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
