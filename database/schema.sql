-- SQL DDL for Hierarchical Referral System (TiDB / MySQL Compatible)
CREATE DATABASE IF NOT EXISTS referral_system;
USE referral_system;

-- Table: User
CREATE TABLE IF NOT EXISTS `User` (
  `id` VARCHAR(36) NOT NULL,
  `email` VARCHAR(191) NOT NULL,
  `password` VARCHAR(191) NOT NULL,
  `role` VARCHAR(191) NOT NULL DEFAULT 'USER',
  `referralCode` VARCHAR(191) NOT NULL,
  `referralUrl` VARCHAR(255) NULL,
  `qrCode` TEXT NULL,
  `referrerId` VARCHAR(36) NULL,
  `points` INT NOT NULL DEFAULT 0,
  `isApproved` BOOLEAN NOT NULL DEFAULT TRUE,
  `isActive` BOOLEAN NOT NULL DEFAULT TRUE,
  `isDeleted` BOOLEAN NOT NULL DEFAULT FALSE,
  `deletedAt` DATETIME(3) NULL,
  `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `User_email_key` (`email`),
  UNIQUE KEY `User_referralCode_key` (`referralCode`),
  KEY `User_referrerId_idx` (`referrerId`),
  FOREIGN KEY (`referrerId`) REFERENCES `User`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Profile
CREATE TABLE IF NOT EXISTS `Profile` (
  `id` VARCHAR(36) NOT NULL,
  `userId` VARCHAR(36) NOT NULL,
  `firstName` VARCHAR(191) NULL,
  `lastName` VARCHAR(191) NULL,
  `phoneNumber` VARCHAR(191) NULL,
  `avatarUrl` VARCHAR(191) NULL,
  `bio` TEXT NULL,
  `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `Profile_userId_key` (`userId`),
  KEY `Profile_phoneNumber_idx` (`phoneNumber`),
  FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Referral
CREATE TABLE IF NOT EXISTS `Referral` (
  `id` VARCHAR(36) NOT NULL,
  `referrerId` VARCHAR(36) NOT NULL,
  `refereeId` VARCHAR(36) NOT NULL,
  `status` VARCHAR(191) NOT NULL DEFAULT 'PENDING',
  `points` INT NOT NULL DEFAULT 0,
  `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `Referral_refereeId_key` (`refereeId`),
  KEY `Referral_referrerId_idx` (`referrerId`),
  KEY `Referral_status_idx` (`status`),
  KEY `Referral_referrer_status_idx` (`referrerId`, `status`),
  FOREIGN KEY (`referrerId`) REFERENCES `User`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`refereeId`) REFERENCES `User`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: HierarchyNode
CREATE TABLE IF NOT EXISTS `HierarchyNode` (
  `id` VARCHAR(36) NOT NULL,
  `userId` VARCHAR(36) NOT NULL,
  `parentId` VARCHAR(36) NULL,
  `path` VARCHAR(511) NOT NULL,
  `level` INT NOT NULL,
  `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `HierarchyNode_userId_key` (`userId`),
  KEY `HierarchyNode_path_idx` (`path`),
  KEY `HierarchyNode_parentId_idx` (`parentId`),
  FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Notification
CREATE TABLE IF NOT EXISTS `Notification` (
  `id` VARCHAR(36) NOT NULL,
  `userId` VARCHAR(36) NOT NULL,
  `title` VARCHAR(191) NOT NULL,
  `message` TEXT NOT NULL,
  `isRead` BOOLEAN NOT NULL DEFAULT FALSE,
  `type` VARCHAR(191) NOT NULL DEFAULT 'SYSTEM',
  `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `Notification_userId_idx` (`userId`),
  KEY `Notification_userId_isRead_idx` (`userId`, `isRead`),
  KEY `Notification_userId_createdAt_idx` (`userId`, `createdAt`),
  FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: SystemSettings
CREATE TABLE IF NOT EXISTS `SystemSettings` (
  `id` VARCHAR(36) NOT NULL,
  `key` VARCHAR(191) NOT NULL,
  `value` TEXT NOT NULL,
  `description` TEXT NULL,
  `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `SystemSettings_key_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: AuditLog
CREATE TABLE IF NOT EXISTS `AuditLog` (
  `id` VARCHAR(36) NOT NULL,
  `userId` VARCHAR(36) NULL,
  `action` VARCHAR(191) NOT NULL,
  `ipAddress` VARCHAR(191) NULL,
  `userAgent` VARCHAR(191) NULL,
  `details` TEXT NULL,
  `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `AuditLog_userId_idx` (`userId`),
  KEY `AuditLog_action_idx` (`action`),
  KEY `AuditLog_createdAt_idx` (`createdAt`),
  FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
