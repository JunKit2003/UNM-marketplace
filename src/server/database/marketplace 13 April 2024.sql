-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 13, 2024 at 10:35 AM
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
(16, '1712192759687.jpg', 'test', 'test', 'test', 'test@test', '07421908370', '$2b$10$y1ZXbgsxyYzw4g8fGdzXPO8Yh9ujbEiaOGbodavjjWcdWEkoZjGua', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidGVzdCJ9.fEphzGSvIaHPFvC8xyqTxs93fEuiOv7di5BYPOkuvvc'),
(17, '1712192715645.jpg', 'test3', 'test3', 'test3', 'test3@test', '07421908371', '$2b$10$eR4AJGWqb0OeRcgiA2Njc.LBFCiE7lRk1.L9cGxNsd7deRC3UuWxW', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidGVzdDMifQ.lrraqM7l8QhSCTEj3Iqounipi5KrAUSlFg6glp_9U9M'),
(18, '1712134118555.jpg', 'test2', 'test2', 'test2', 'test2@test', '07221908371', '$2b$10$Oxc3AeWZbqRjlqL3b959XOr9l6UEVtANpM28CkNVKKFMya5EwdOeq', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidGVzdDIifQ.QeOUJoUHXtiZD3pIbiDLx-ZggeD6qQkvrJFDAhhO8Y4');

-- --------------------------------------------------------

--
-- Table structure for table `listing`
--

CREATE TABLE `listing` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `ImageID` varchar(255) NOT NULL,
  `condition` varchar(255) NOT NULL,
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

INSERT INTO `listing` (`id`, `title`, `ImageID`, `condition`, `description`, `price`, `category`, `ContactDescription`, `postedDate`, `PostedBy`) VALUES
(103, 'Trek Slash 8', '1712199180840.jpg', 'Brand new', 'You want an enduro bike that keeps pedalling efficient on the ups and slays on the downs. The added traction from a high-pivot bike is appealing, but the stability on descents is really what takes the cake. Versatility is up your alley, and you love being able to walk the line between fast-rolling 29ers and nimble 27.5 wheels.', 18000.00, 'Sports equipment', 'Contact Faction Bikeworks ', '2024-04-03 08:44:32', 'test'),
(105, 'NBA OFFICIAL GAME BASKETBALL', '1712134215088.jpg', 'Brand new', 'Basketball players around the world are unified by their love of the NBA game. The NBA inspired to play through competitive action, powerful camaraderie, and incredible athleticism, and it begins with the game ball. The Wilson Official NBA Game Ball is built with genuine leather and constructed to meet the world-class standards of the NBA. This is the basketball used by every team and every player, in every game.\n\nPro Tip: The Official NBA Game Ball is built with a genuine leather cover that will initially feel slick and rough to the touch. Playing with the basketball will loosen up the leather, giving the ball more grip. Dribbling drills will also help speed up the break in process. The ball will darken as it becomes ready for game play. The more you play, the better it feels.', 100.00, 'Hobbies', 'Contact Royal Sporting Goods', '2024-04-03 08:50:15', 'test2'),
(106, 'Ipad', '1712134296826.jpg', 'Brand new', '◊ Legal Disclaimers\nDisplay: The displays have rounded corners. When measured as a rectangle, the 12.9-inch iPad Pro screen is 12.9 inches diagonally, the 11-inch iPad Pro screen is 11 inches diagonally, the iPad Air and iPad (10th generation) screens are 10.86 inches diagonally and the iPad mini screen is 8.3 inches diagonally. Actual viewable area is less. Liquid Retina XDR display is available only on the 12.9-inch model.\n\nAccessories: Accessories are sold separately and are subject to availability. Compatibility varies by generation. Apple Pencil (1st generation) requires USB-C to Apple Pencil Adapter to work with iPad (10th generation); subject to availability.\n\nPower and Battery: Battery life varies by use and configuration. See apple.com/my/batteries for more information.\n\nFaceTime: FaceTime calling requires a FaceTime-enabled device for the caller and recipient, and a Wi‑Fi connection. Availability over a mobile network depends on carrier policies; data charges may apply.\n\nMobile and Wireless: Data plan is required. 5G and 4G LTE are available in selected markets and through selected carriers. Speeds vary based on site conditions and carrier. For details on 5G and LTE support, contact your carrier and see apple.com/my/ipad/cellular.\n\nApp Store: Apps are available on the App Store. Title availability is subject to change.\n\nCapacity: Available space is less and varies due to many factors. Storage capacity is subject to change based on software version, settings and iPad model. 1GB = 1 billion bytes and 1TB = 1 trillion bytes; actual formatted capacity less.\n\nFeature Availability: Some features may not be available for all countries or all areas. See apple.com/my/ios/feature‑availability for the complete list.\n\nApple Arcade: Apple Arcade requires a subscription.\n\nApple TV: Apple TV+ requires a subscription.', 5000.00, 'Electronics', 'Contact Machines ', '2024-04-03 08:51:36', 'test2'),
(108, 'Toyota Camry ', '1712211554296.jpg', 'Brand new', 'Spacious and smarter, with a more sporty aesthetic. Our iconic sedan continues to lead the pack with sharp styling and a host of sophisticated technologies for excellent performance on every drive.', 200000.00, 'Vehicles', 'Contact UMW Toyota Motors', '2024-04-04 06:19:14', 'test3'),
(109, 'Knippex Pliers', '1712413088234.jpg', 'Brand new', ' Easy cutting thanks to the high leverage joint\n For all common installation and repair work.\n Handy use when working in confined areas thanks to slim head design and pointed jaws (anti-twist)\n Milled groove in the gripping area permits small parts such as nails, pins and bolts to be held and pulled\n The reliable and diverse combination pliers when out and about\n With cutting edges for soft, medium-hard and hard wire\n Long service life and stable tips\n Cutting edges additionally induction-hardened, cutting edge hardness approx. 61 HRC', 400.00, 'Home & Garden', 'Contact Ace Hardware', '2024-04-06 14:18:08', 'test');

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=110;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
