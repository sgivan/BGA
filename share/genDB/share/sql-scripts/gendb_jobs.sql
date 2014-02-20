-- phpMyAdmin SQL Dump
-- version 3.3.7
-- http://www.phpmyadmin.net
--
-- Host: lewis2.rnet.missouri.edu:53307
-- Generation Time: Jul 18, 2013 at 02:43 PM
-- Server version: 5.1.47
-- PHP Version: 5.3.3

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `gendb_jobs`
--
-- CREATE DATABASE `gendb_jobs` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
CREATE DATABASE IF NOT EXISTS `gendb_jobs` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `gendb_jobs`;

-- --------------------------------------------------------

--
-- Table structure for table `JOB_counters`
--

CREATE TABLE IF NOT EXISTS `JOB_counters` (
  `object` char(20) DEFAULT NULL,
  `val` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `JOB_counters`
--

INSERT INTO `JOB_counters` (`object`, `val`) VALUES
('job', 48157);

-- --------------------------------------------------------

--
-- Table structure for table `job`
--

CREATE TABLE IF NOT EXISTS `job` (
  `project_name` char(20) DEFAULT NULL,
  `job_info` int(11) DEFAULT NULL,
  `lock_state` int(11) DEFAULT NULL,
  `id` int(11) NOT NULL DEFAULT '0',
  `locked_by` char(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `job`
--

