-- Core database schema (MySQL 5.7+ / 8.0)
-- Reference: CORE-DATABASE-TABLES.md
-- Naming: singular snake_case; FKs = referenced_table_id

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. range_server
CREATE TABLE IF NOT EXISTS range_server (
  id BIGINT NOT NULL AUTO_INCREMENT,
  range_key VARCHAR(32) NOT NULL,
  value INT NOT NULL,
  description VARCHAR(256) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_range_server_range_key (range_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. server
CREATE TABLE IF NOT EXISTS server (
  id BIGINT NOT NULL AUTO_INCREMENT,
  server_number VARCHAR(8) NOT NULL,
  range_server_id BIGINT NOT NULL,
  image_path VARCHAR(512) NOT NULL,
  name VARCHAR(64) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_server_number (server_number),
  KEY idx_server_range (range_server_id),
  CONSTRAINT fk_server_range FOREIGN KEY (range_server_id) REFERENCES range_server (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. flow (collection de fluxo)
CREATE TABLE IF NOT EXISTS flow (
  id BIGINT NOT NULL AUTO_INCREMENT,
  flow_key VARCHAR(64) NOT NULL,
  name_collection VARCHAR(128) NOT NULL,
  is_original TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. flow_step (etapa dentro de um flow; flow_id opcional para compatibilidade)
CREATE TABLE IF NOT EXISTS flow_step (
  id BIGINT NOT NULL AUTO_INCREMENT,
  flow_id BIGINT NULL,
  flow_key VARCHAR(64) NULL,
  step_number INT NOT NULL,
  name VARCHAR(128) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_flow_step_flow_step (flow_id, step_number),
  UNIQUE KEY uq_flow_step_key_step (flow_key, step_number),
  KEY idx_flow_step_flow (flow_id),
  CONSTRAINT fk_flow_step_flow FOREIGN KEY (flow_id) REFERENCES flow (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. flow_step_image (step_img_number = ordem da imagem na etapa)
CREATE TABLE IF NOT EXISTS flow_step_image (
  id BIGINT NOT NULL AUTO_INCREMENT,
  flow_step_id BIGINT NOT NULL,
  step_img_number INT NOT NULL,
  image_path VARCHAR(512) NULL,
  name_image VARCHAR(255) NULL,
  image_data BLOB NULL,
  coordinates TEXT NULL,
  worker_action VARCHAR(64) NOT NULL DEFAULT 'CLICK',
  width INT NULL,
  height INT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_flow_step_image_step_num (flow_step_id, step_img_number),
  KEY idx_flow_step_image_step (flow_step_id),
  CONSTRAINT fk_flow_step_image_step FOREIGN KEY (flow_step_id) REFERENCES flow_step (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. game_account (uma conta pode ter vários game_details_account)
CREATE TABLE IF NOT EXISTS game_account (
  id BIGINT NOT NULL AUTO_INCREMENT,
  login VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_game_account_login (login)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. game_details_account (pertence a um game_account; UNIQUE por conta + server)
CREATE TABLE IF NOT EXISTS game_details_account (
  id BIGINT NOT NULL AUTO_INCREMENT,
  nick VARCHAR(255) NOT NULL,
  server VARCHAR(32) NOT NULL,
  xp INT NULL,
  level INT NULL,
  game_account_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_game_details_account_account_server (game_account_id, server),
  KEY idx_game_details_account_game_account (game_account_id),
  CONSTRAINT fk_game_details_account_game_account FOREIGN KEY (game_account_id) REFERENCES game_account (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. customer
CREATE TABLE IF NOT EXISTS customer (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  contact_number VARCHAR(20) NULL,
  pix_key VARCHAR(255) NULL,
  profile VARCHAR(32) NOT NULL,
  total_purchases INT NOT NULL DEFAULT 0,
  closed_purchases INT NOT NULL DEFAULT 0,
  open_purchases INT NOT NULL DEFAULT 0,
  cancelled_purchases INT NOT NULL DEFAULT 0,
  description TEXT NULL,
  deleted_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_customer_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. sales_order
CREATE TABLE IF NOT EXISTS sales_order (
  id BIGINT NOT NULL AUTO_INCREMENT,
  customer_id BIGINT NOT NULL,
  range_server_id BIGINT NOT NULL,
  description VARCHAR(512) NULL,
  status_order VARCHAR(20) NOT NULL,
  active_flag TINYINT NOT NULL DEFAULT 0,
  priority VARCHAR(20) NOT NULL,
  order_type VARCHAR(10) NOT NULL,
  accounts_count INT NOT NULL,
  server_scope VARCHAR(32) NULL,
  tasks_total INT NOT NULL,
  tasks_completed INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_sales_order_customer (customer_id),
  KEY idx_sales_order_range (range_server_id),
  KEY idx_sales_order_status (status_order),
  CONSTRAINT fk_sales_order_customer FOREIGN KEY (customer_id) REFERENCES customer (id),
  CONSTRAINT fk_sales_order_range FOREIGN KEY (range_server_id) REFERENCES range_server (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. device
CREATE TABLE IF NOT EXISTS device (
  id BIGINT NOT NULL AUTO_INCREMENT,
  identifier VARCHAR(64) NOT NULL,
  name VARCHAR(128) NULL,
  api_key_hash VARCHAR(255) NULL,
  status VARCHAR(20) NOT NULL,
  deleted_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_device_identifier (identifier),
  KEY idx_device_status (status),
  KEY idx_device_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. task (depends on sales_order, game_account, device, flow_step)
CREATE TABLE IF NOT EXISTS task (
  id BIGINT NOT NULL AUTO_INCREMENT,
  sales_order_id BIGINT NOT NULL,
  game_account_id BIGINT NOT NULL,
  server_value VARCHAR(32) NOT NULL,
  flow_step_id BIGINT NULL,
  status_task VARCHAR(20) NOT NULL,
  device_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_task_order_account_server (sales_order_id, game_account_id, server_value),
  KEY idx_task_sales_order (sales_order_id),
  KEY idx_task_device_status (device_id, status_task),
  KEY idx_task_status_updated (status_task, updated_at),
  CONSTRAINT fk_task_sales_order FOREIGN KEY (sales_order_id) REFERENCES sales_order (id),
  CONSTRAINT fk_task_game_account FOREIGN KEY (game_account_id) REFERENCES game_account (id),
  CONSTRAINT fk_task_flow_step FOREIGN KEY (flow_step_id) REFERENCES flow_step (id),
  CONSTRAINT fk_task_device FOREIGN KEY (device_id) REFERENCES device (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11. debug_image
CREATE TABLE IF NOT EXISTS debug_image (
  id BIGINT NOT NULL AUTO_INCREMENT,
  task_id BIGINT NOT NULL,
  image_path VARCHAR(512) NOT NULL,
  detection_context JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_debug_image_task_created (task_id, created_at),
  CONSTRAINT fk_debug_image_task FOREIGN KEY (task_id) REFERENCES task (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 12. order_task_log
CREATE TABLE IF NOT EXISTS order_task_log (
  id BIGINT NOT NULL AUTO_INCREMENT,
  task_id BIGINT NOT NULL,
  log_level VARCHAR(20) NOT NULL,
  message TEXT NULL,
  last_click JSON NULL,
  log_file_path VARCHAR(512) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_order_task_log_task (task_id),
  KEY idx_order_task_log_task_created (task_id, created_at),
  CONSTRAINT fk_order_task_log_task FOREIGN KEY (task_id) REFERENCES task (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- Optional: seed range_server (adjust values per CORE-DATABASE-TABLES.md)
-- INSERT INTO range_server (range_key, value) VALUES ('ALL', 65), ('range_1', 9), ('range_2', 8), ('range_3', 16), ('range_4', 18), ('range_5', 9), ('range_6', 5);
-- range_3 = 18-28 + 56-60 (composto); range_6 = 61-65
