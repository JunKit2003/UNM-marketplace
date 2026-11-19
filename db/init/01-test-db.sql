-- Extra database used only by the api test suite.
CREATE DATABASE IF NOT EXISTS unm_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON unm_test.* TO 'unm'@'%';
FLUSH PRIVILEGES;
