/*
Navicat MySQL Data Transfer

Source Server         : localhost_3306
Source Server Version : 50527
Source Host           : localhost:3306
Source Database       : testdb

Target Server Type    : MYSQL
Target Server Version : 50527
File Encoding         : 65001

Date: 2012-11-12 14:07:39

$ mysql -u USERNAME -p PASSWORD database_name < filename.sql

*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `persons`
-- ----------------------------
DROP TABLE IF EXISTS `persons`;
CREATE TABLE `persons` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Email` varchar(32) UNIQUE NOT NULL,
  `Password` varchar(32) NOT NULL,
  `Firstname` varchar(32) DEFAULT NULL,
  `Lastname` varchar(32) DEFAULT NULL,
  `Sex` char(1) DEFAULT NULL,
  `Age` tinyint(3) DEFAULT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of persons
-- ----------------------------
INSERT INTO `persons` VALUES ('1', 'aa1@bb1.com', 'aa1@bb1.com', 'John', 'Doe', 'M', '19');
INSERT INTO `persons` VALUES ('2', 'aa2@bb2.com', 'aa1@bb1.com', 'Bob', 'Black', 'M', '40');
INSERT INTO `persons` VALUES ('3', 'aa3@bb3.com', 'aa1@bb1.com', 'Zoe', 'Chan', 'F', '21');
INSERT INTO `persons` VALUES ('4', 'aa4@bb4.com', 'aa1@bb1.com', 'Sekito', 'Khan', 'M', '19');
INSERT INTO `persons` VALUES ('5', 'aa5@bb5.com', 'aa1@bb1.com', 'Kader', 'Khan', 'M', '56');
INSERT INTO `persons` VALUES ('6', 'gg6@bb5.com', 'gg1@bb1.com', 'Gao', 'Jing', 'M', '56');

-- ----------------------------
-- Table structure for `interestings`
-- ----------------------------
DROP TABLE IF EXISTS `interestings`;
CREATE TABLE `interestings` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `PersonId` int(11) NOT NULL,
  `Code` int(11) DEFAULT NULL,
  `Keyword` varchar(32) DEFAULT NULL,
  FOREIGN KEY (`PersonId`) REFERENCES `persons` (`Id`),
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of interestings
-- ----------------------------
INSERT INTO `interestings` VALUES ('1', '1', '111', 'AA');
INSERT INTO `interestings` VALUES ('2', '1', '222', 'BB');
INSERT INTO `interestings` VALUES ('3', '2', '333', 'CC');
INSERT INTO `interestings` VALUES ('4', '2', '444', 'DD');
INSERT INTO `interestings` VALUES ('5', '3', '555', 'EE');
INSERT INTO `interestings` VALUES ('6', '3', '666', 'MM');
INSERT INTO `interestings` VALUES ('7', '4', '777', 'FF');
INSERT INTO `interestings` VALUES ('8', '4', '888', 'GG');
INSERT INTO `interestings` VALUES ('9', '5', '999', 'HH');
INSERT INTO `interestings` VALUES ('10', '5', '000', 'II');
INSERT INTO `interestings` VALUES ('11', '6', '123', 'JJ');







