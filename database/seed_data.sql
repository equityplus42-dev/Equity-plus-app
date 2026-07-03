-- SQL Seed Data for TiDB / MySQL
USE referral_system;

-- Insert Admin User (password is 'Admin123!' hashed with bcrypt)
-- ID: 00000000-0000-0000-0000-000000000000
-- Referral Code: ADMINREF
INSERT INTO `User` (`id`, `email`, `password`, `role`, `referralCode`, `referrerId`, `isApproved`, `createdAt`, `updatedAt`)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  'admin@referral.com',
  '$2b$10$P5i/U8u/wA1Bf5m0eU7mHe2pWnE75P4m3aGv8.U2q163c4.1H0.yS',
  'ADMIN',
  'ADMINREF',
  NULL,
  TRUE,
  NOW(3),
  NOW(3)
) ON DUPLICATE KEY UPDATE `id`=`id`;

-- Insert Admin Profile
INSERT INTO `Profile` (`id`, `userId`, `firstName`, `lastName`, `phoneNumber`, `avatarUrl`, `bio`, `createdAt`, `updatedAt`)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'System',
  'Administrator',
  '+1234567890',
  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&h=150',
  'Primary Administrator for the Hierarchical Referral System.',
  NOW(3),
  NOW(3)
) ON DUPLICATE KEY UPDATE `id`=`id`;

-- Insert Default System Settings
INSERT INTO `SystemSettings` (`id`, `key`, `value`, `description`, `createdAt`, `updatedAt`) VALUES
(UUID(), 'points_level_1', '100', 'Points awarded to the direct referrer (Level 1)', NOW(3), NOW(3)),
(UUID(), 'points_level_2', '50', 'Points awarded to the level 2 indirect referrer', NOW(3), NOW(3)),
(UUID(), 'points_level_3', '25', 'Points awarded to the level 3 indirect referrer', NOW(3), NOW(3)),
(UUID(), 'max_hierarchy_depth', '3', 'Maximum depth level for awarding referral rewards', NOW(3), NOW(3)),
(UUID(), 'require_admin_approval', 'false', 'If true, new referrals must be manually approved by admin before points are paid out', NOW(3), NOW(3))
ON DUPLICATE KEY UPDATE `key`=`key`;
