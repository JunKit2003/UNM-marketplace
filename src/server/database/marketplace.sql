-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Feb 02, 2024 at 07:39 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

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
-- Table structure for table `listing`
--

CREATE TABLE `listing` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `ImageID` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `postedDate` timestamp NOT NULL DEFAULT current_timestamp(),
  `PostedBy` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `listing`
--

INSERT INTO `listing` (`id`, `title`, `ImageID`, `description`, `price`, `category`, `postedDate`, `PostedBy`) VALUES
(46, 'YC', '2024-02-02-11-29-30-692a01ef-f43c-4638-a4fd-22d7f65848b3.jpg', 'diewoahfowef', 12.00, 'bear', '2024-02-02 03:29:30', 'ambatukam'),
(47, 'A Bear', '2024-02-02-11-54-13-c8ae5676-8aa7-47b3-a05e-acdd99736825.jpg', 'A literal bear', 10.00, 'BEAR', '2024-02-02 03:54:12', 'ambatukam'),
(48, 'qdwdqw', '2024-02-02-12-37-50-71552bd3-a313-4282-a05a-02d7291451a4.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:50', 'ambatukam'),
(49, 'qdwdqw', '2024-02-02-12-37-53-21f74471-b499-438e-89ee-1393b05f6008.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:53', 'ambatukam'),
(50, 'qdwdqw', '2024-02-02-12-37-53-edc75308-558a-4c1f-be0a-587f695d22c0.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:53', 'ambatukam'),
(51, 'qdwdqw', '2024-02-02-12-37-53-1be1e07c-8c30-4422-9aae-e6935bc08852.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:53', 'ambatukam'),
(52, 'qdwdqw', '2024-02-02-12-37-53-b4d93a76-4de5-44e0-a5fb-bf999cf1e465.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:53', 'ambatukam'),
(53, 'qdwdqw', '2024-02-02-12-37-54-c8ca9313-3037-4a66-9afa-756ffe6b6a18.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:54', 'ambatukam'),
(54, 'qdwdqw', '2024-02-02-12-37-54-19d80bf7-b31c-43c2-a3ca-951efa23d9e2.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:54', 'ambatukam'),
(55, 'qdwdqw', '2024-02-02-12-37-54-bb8d95b9-6a43-4dc3-8979-27659541b71a.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:54', 'ambatukam'),
(56, 'qdwdqw', '2024-02-02-12-37-54-4d74561b-afef-469b-9a3f-baa06d09dd81.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:54', 'ambatukam'),
(57, 'qdwdqw', '2024-02-02-12-37-54-2cad7ffb-c197-4ddc-8711-2b1744ac1d1b.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:54', 'ambatukam'),
(58, 'qdwdqw', '2024-02-02-12-37-54-96572319-0a12-42e8-b040-a4ba00032c4b.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:54', 'ambatukam'),
(59, 'qdwdqw', '2024-02-02-12-37-55-f9ca801c-680d-449f-86ee-82ed51975771.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:55', 'ambatukam'),
(60, 'qdwdqw', '2024-02-02-12-37-55-e9246633-83fa-4772-866f-75a1d1321158.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:55', 'ambatukam'),
(61, 'qdwdqw', '2024-02-02-12-37-55-8cde86a8-b52f-4944-b91f-f36db9b145b2.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:55', 'ambatukam'),
(62, 'qdwdqw', '2024-02-02-12-37-55-4b978277-e6ca-440f-87a2-ba895ed5878c.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:55', 'ambatukam'),
(63, 'qdwdqw', '2024-02-02-12-37-55-504f14c8-7a8f-4c19-b091-5911f3ce71f8.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:55', 'ambatukam'),
(64, 'qdwdqw', '2024-02-02-12-37-55-ab89c9ec-5fb2-4ad2-bcfc-4fa57048aad2.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:55', 'ambatukam'),
(65, 'qdwdqw', '2024-02-02-12-37-56-d7d98f62-61e2-4c33-ad8a-cfae81f806a8.jpg', 'dqwdqw', 1312.00, 'dqwd', '2024-02-02 04:37:56', 'ambatukam'),
(66, 'cecwef', '2024-02-02-12-46-54-eae03efe-0996-42a1-a424-d31a8ea37a57.jpg', 'ewfwe', 21423.00, 'fwef', '2024-02-02 04:46:54', 'test'),
(67, '', '2024-02-02-12-47-13-de595017-fa26-4281-b9ac-b796df9eac0c.jpg', '', 0.00, '', '2024-02-02 04:47:13', 'test'),
(68, 'ger', '2024-02-02-12-49-05-b4de38b4-77b5-4e2b-bd6f-aa934b5f83ea.jpg', 'gerg', 234234.00, 'geg', '2024-02-02 04:49:05', 'test'),
(69, 'uwegfiuwe', '2024-02-02-14-04-30-c27c2782-6cc9-4769-9d83-6e80b402a69c.jpg', 'ewfwef', 1312.00, 'fewf', '2024-02-02 06:04:30', 'ambatukam');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `listing`
--
ALTER TABLE `listing`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `listing`
--
ALTER TABLE `listing`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=70;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
